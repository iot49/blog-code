#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Access Configuration Sync
# This script manages Cloudflare Access Applications and Policies for each access level.
# It ensures path-based protection (e.g., domain.com/friends/*) is enforced.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

pass() { echo -e "${GREEN}✓${RESET} $1"; }
fail() { echo -e "${RED}✗${RESET} $1"; }
info() { echo -e "${CYAN}▶${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET} $1"; }

# 1. Check Environment Variables
info "Checking environment variables..."
# Set fallbacks for deprecated names
CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"
CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-${CF_ACCOUNT_ID:-}}"

for var in CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID DOMAIN CLOUDFLARE_PROJECT_NAME; do
  if [[ -z "${!var:-}" ]]; then
    fail "Missing $var. Please set it in your environment or .env file."
    exit 1
  fi
done

# 2. Get the actual Pages domains
info "Fetching Pages project domains for '$CLOUDFLARE_PROJECT_NAME'..."
# Fetch all domains associated with the project
ALL_PROJECT_DOMAINS=$(npx -y wrangler pages project list --json | node -e "
  const input = require('fs').readFileSync(0, 'utf8');
  try {
    const data = JSON.parse(input);
    const proj = data.find(p => p['Project Name'] === '$CLOUDFLARE_PROJECT_NAME');
    if (proj && proj['Project Domains']) {
      // Domains are comma separated, e.g. 'proj-abc.pages.dev, custom.com'
      const domains = proj['Project Domains'].split(',').map(d => d.trim());
      console.log(domains.join(' '));
    } else {
      console.log('');
    }
  } catch (e) {
    console.error(e);
    console.log('');
  }
")

PAGES_DOMAIN=$(echo "$ALL_PROJECT_DOMAINS" | node -e "
  const input = require('fs').readFileSync(0, 'utf8').trim();
  const domains = input ? input.split(/\s+/) : [];
  console.log(domains.find(d => d.endsWith('.pages.dev')) || '');
")

if [[ -z "$PAGES_DOMAIN" ]]; then
  warn "Could not resolve .pages.dev domain from Wrangler. Falling back to internal guess."
  PAGES_DOMAIN="$CLOUDFLARE_PROJECT_NAME.pages.dev"
fi
info "Using Pages domain for wildcard: $PAGES_DOMAIN"
info "Detected domains: $ALL_PROJECT_DOMAINS"

CF_API_BASE="https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/access"

# Helper for API calls
cf_api() {
  local method=$1
  local path=$2
  shift 2
  local data=${1:-}

  local res
  if [[ -n "$data" ]]; then
    res=$(curl -s -X "$method" "$CF_API_BASE$path" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data")
  else
    res=$(curl -s -X "$method" "$CF_API_BASE$path" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json")
  fi
  echo "$res" > /tmp/cf_api_last_res.json
  echo "$res"
}

# 3. Parse Access List
info "Parsing access-list.yaml..."
# The yaml file is in the current directory or parent
ACCESS_LIST_FILE="$(pwd)/access-list.yaml"
if [[ ! -f "$ACCESS_LIST_FILE" && -f "../access-list.yaml" ]]; then
  ACCESS_LIST_FILE="$(pwd)/../access-list.yaml"
fi

if [[ ! -f "$ACCESS_LIST_FILE" ]]; then
  fail "Could not find $ACCESS_LIST_FILE"
  exit 1
fi

# Switch to blog-code to have access to node_modules
INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$INFRA_DIR/.."

# Get categories from YAML
ACCESS_DATA=$(node -e "
  const fs = require('fs');
  // Dynamic import or require with path
  const yaml = require('./node_modules/js-yaml');
  try {
    const data = yaml.load(fs.readFileSync('$ACCESS_LIST_FILE', 'utf8'));
    console.log(JSON.stringify(data));
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
")

CATEGORIES=$(echo "$ACCESS_DATA" | node -e "const d = JSON.parse(require('fs').readFileSync(0, 'utf8')); console.log(Object.keys(d).join(' '))")

# Standard access levels that don't need YAML (public/auth)
SYNC_LEVELS="auth $CATEGORIES"

# 4. Fetch existing apps once to avoid repeat calls
info "Fetching existing Access Applications..."
APPS_JSON=$(cf_api GET "/apps")

sync_app() {
  local LEVEL=$1
  local APP_NAME="Blog - $LEVEL"
  local PATH_PATTERN="$LEVEL/*"
  local PRIMARY_DOMAIN="$DOMAIN/$PATH_PATTERN"
  
  info "Syncing Application for level: $LEVEL ($PRIMARY_DOMAIN)..."

  # Find existing app by name OR domain
  local APP_ID=$(echo "$APPS_JSON" | node -e "
    const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    if (!data.result) process.exit(0);
    const app = data.result.find(a => a.name === '$APP_NAME' || a.domain === '$PRIMARY_DOMAIN');
    console.log(app ? app.id : '');
  ")

  local APP_PAYLOAD=$(node -e "
    const projectDomains = '$ALL_PROJECT_DOMAINS'.split(/\s+/).filter(Boolean);
    const extraDomains = ['$DOMAIN', '*.$PAGES_DOMAIN'].filter(Boolean);
    const allHostnames = [...new Set([...projectDomains, ...extraDomains])];
    const domains = allHostnames.map(d => d + '/$PATH_PATTERN');
    
    const payload = {
      type: 'self_hosted',
      name: '$APP_NAME',
      domain: '$PRIMARY_DOMAIN',
      self_hosted_domains: domains,
      session_duration: '24h',
      app_launcher_visible: false
    };
    console.log(JSON.stringify(payload));
  ")

  if [[ -z "$APP_ID" ]]; then
    info "Creating new Access Application: $APP_NAME..."
    local RES=$(cf_api POST "/apps" "$APP_PAYLOAD")
    APP_ID=$(echo "$RES" | node -e "console.log(JSON.parse(require('fs').readFileSync(0, 'utf8')).result?.id || '')")
  else
    info "Updating existing Access Application: $APP_ID..."
    cf_api PUT "/apps/$APP_ID" "$APP_PAYLOAD" > /dev/null
  fi

  if [[ -z "$APP_ID" ]]; then
    fail "Failed to manage Application for $LEVEL"
    # Check if this was an auth error
    if grep -q "Authentication error" /tmp/cf_api_last_res.json; then
      warn "Tip: Ensure your CF_API_TOKEN has 'Account > Access: Edit' permission."
    fi
    return 1
  fi

  # Sync Policy for this app
  local POLICIES_JSON=$(cf_api GET "/apps/$APP_ID/policies")
  local POLICY_ID=$(echo "$POLICIES_JSON" | node -e "
    const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    if (!data.result) process.exit(0);
    const p = data.result.find(p => p.name === 'Default Access');
    console.log(p ? p.id : '');
  ")

  local POLICY_PAYLOAD
  if [[ "$LEVEL" == "auth" ]]; then
    POLICY_PAYLOAD='{"name":"Default Access","decision":"allow","precedence":1,"include":[{"everyone":{}}]}'
  else
    # Get emails for this category
    local EMAILS=$(echo "$ACCESS_DATA" | node -e "
      const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
      console.log(JSON.stringify(d['$LEVEL']));
    ")
    POLICY_PAYLOAD=$(printf '{"name":"Default Access","decision":"allow","precedence":1,"include":[{"email":{"email":%s}}]}' \
      "$EMAILS")
    # Note: If multiple emails, we should use a group or multiple rules. 
    # For simplicity, if EMAILS is an array, we'll map them.
    POLICY_PAYLOAD=$(echo "$ACCESS_DATA" | node -e "
      const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
      const emails = d['$LEVEL'] || [];
      const include = emails.map(e => ({ email: { email: e } }));
      console.log(JSON.stringify({
        name: 'Default Access',
        decision: 'allow',
        precedence: 1,
        include: include
      }));
    ")
  fi

  if [[ -z "$POLICY_ID" ]]; then
    cf_api POST "/apps/$APP_ID/policies" "$POLICY_PAYLOAD" > /dev/null
  else
    cf_api PUT "/apps/$APP_ID/policies/$POLICY_ID" "$POLICY_PAYLOAD" > /dev/null
  fi
  
  pass "Synchronized access for $LEVEL"
}

for L in $SYNC_LEVELS; do
  sync_app "$L" || warn "Failed to sync $L"
done

# 5. Public Bypass (at the root domain if we want to bypass sub-paths or just for /public/*)
sync_public_bypass() {
  local LEVEL="public"
  local APP_NAME="Blog - Public"
  local PRIMARY_DOMAIN="$DOMAIN/public/*"
  
  info "Syncing Application for level: $LEVEL ($PRIMARY_DOMAIN)..."

  local APP_ID=$(echo "$APPS_JSON" | node -e "
    const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    if (!data.result) process.exit(0);
    const app = data.result.find(a => a.name === '$APP_NAME' || a.domain === '$PRIMARY_DOMAIN');
    console.log(app ? app.id : '');
  ")

  local APP_PAYLOAD=$(node -e "
    const projectDomains = '$ALL_PROJECT_DOMAINS'.split(/\s+/).filter(Boolean);
    const extraDomains = ['$DOMAIN', '*.$PAGES_DOMAIN'].filter(Boolean);
    const allHostnames = [...new Set([...projectDomains, ...extraDomains])];
    const domains = allHostnames.map(d => d + '/public/*');
    
    const payload = {
      type: 'self_hosted',
      name: '$APP_NAME',
      domain: '$PRIMARY_DOMAIN',
      self_hosted_domains: domains,
      session_duration: '24h',
      app_launcher_visible: false
    };
    console.log(JSON.stringify(payload));
  ")

  if [[ -z "$APP_ID" ]]; then
    local RES=$(cf_api POST "/apps" "$APP_PAYLOAD")
    APP_ID=$(echo "$RES" | node -e "console.log(JSON.parse(require('fs').readFileSync(0, 'utf8')).result?.id || '')")
  else
    cf_api PUT "/apps/$APP_ID" "$APP_PAYLOAD" > /dev/null
  fi

  if [[ -n "$APP_ID" ]]; then
    local POLICIES_JSON=$(cf_api GET "/apps/$APP_ID/policies")
    local POLICY_ID=$(echo "$POLICIES_JSON" | node -e "
      const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
      const p = data.result?.find(p => p.name === 'Bypass');
      console.log(p ? p.id : '');
    ")
    local POLICY_PAYLOAD='{"name":"Bypass","decision":"bypass","precedence":1,"include":[{"everyone":{}}]}'
    if [[ -z "$POLICY_ID" ]]; then
      cf_api POST "/apps/$APP_ID/policies" "$POLICY_PAYLOAD" > /dev/null
    else
      cf_api PUT "/apps/$APP_ID/policies/$POLICY_ID" "$POLICY_PAYLOAD" > /dev/null
    fi
    pass "Public path explicitly bypassed"
  fi
}

sync_public_bypass

echo -e "\n${GREEN}${BOLD}✓ Cloudflare Access policies synchronized!${RESET}"
