#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Access Configuration Sync
# This script syncs access-list.yaml to Cloudflare Access Policies.

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
MISSING_VARS=0
for var in CF_API_TOKEN CF_ACCOUNT_ID DOMAIN; do
  if [[ -z "${!var:-}" ]]; then
    warn "Missing $var"
    MISSING_VARS=1
  fi
done

if [[ $MISSING_VARS -eq 1 ]]; then
  fail "Required environment variables are missing. Please set them in .env or your shell."
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    exit 1
  fi
fi

CF_API_BASE="https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/access"

# Helper for API calls
cf_api() {
  local method=$1
  local path=$2
  shift 2
  local data=${1:-}

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    info "[DRY RUN] $method $CF_API_BASE$path ${data:+-d '$data'}"
    # Return dummy successful response for dry run
    echo '{"success": true, "result": []}'
    return
  fi

  if [[ -n "$data" ]]; then
    curl -s -X "$method" "$CF_API_BASE$path" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "$CF_API_BASE$path" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json"
  fi
}

# 2. Find Access Application
info "Locating Access Application for $DOMAIN..."
APPS_JSON=$(cf_api GET "/apps")
APP_ID=$(echo "$APPS_JSON" | node -e "
  const input = require('fs').readFileSync(0, 'utf8');
  const data = JSON.parse(input);
  if (!data.result) { console.log(''); process.exit(0); }
  const app = data.result.find(a => a.domain === '$DOMAIN' || a.self_hosted_domains?.includes('$DOMAIN'));
  console.log(app ? app.id : '');
")

if [[ -z "$APP_ID" ]]; then
  fail "Could not find an Access Application for $DOMAIN on Cloudflare."
  exit 1
fi
pass "Found Application ID: $APP_ID"

# 3. Parse Access List
info "Parsing access-list.yaml..."
ACCESS_DATA=$(node "$(dirname "$0")/parse-access-list.js")

# 4. Sync Access Lists and Policies
# Categories: friends, family, personal, etc.
CATEGORIES=$(echo "$ACCESS_DATA" | node -e "const d = JSON.parse(require('fs').readFileSync(0, 'utf8')); console.log(Object.keys(d).join(' '))")

for CATEGORY in $CATEGORIES; do
  info "Syncing category: $CATEGORY..."
  
  EMAILS=$(echo "$ACCESS_DATA" | node -e "
    const d = JSON.parse(require('fs').readFileSync(0, 'utf8'));
    console.log(d['$CATEGORY'].join(','));
  ")

  # 4a. Find or Create Access List
  LISTS_JSON=$(cf_api GET "/lists")
  LIST_ID=$(echo "$LISTS_JSON" | node -e "
    const input = require('fs').readFileSync(0, 'utf8');
    const data = JSON.parse(input);
    if (!data.result) { console.log(''); process.exit(0); }
    const list = data.result.find(l => l.name === 'Blog - $CATEGORY');
    console.log(list ? list.id : '');
  ")

  if [[ -z "$LIST_ID" ]]; then
    info "Creating new Access List for $CATEGORY..."
    LIST_PAYLOAD=$(printf '{"name":"Blog - %s","description":"Email list for %s access","emails":[%s]}' \
      "$CATEGORY" "$CATEGORY" "$(echo "$EMAILS" | sed 's/[^, ]*/"&"/g')")
    LIST_RES=$(cf_api POST "/lists" "$LIST_PAYLOAD")
    LIST_ID=$(echo "$LIST_RES" | node -e "console.log(JSON.parse(require('fs').readFileSync(0, 'utf8')).result?.id || '')")
  else
    info "Updating existing Access List for $CATEGORY..."
    LIST_PAYLOAD=$(printf '{"name":"Blog - %s","description":"Email list for %s access","emails":[%s]}' \
      "$CATEGORY" "$CATEGORY" "$(echo "$EMAILS" | sed 's/[^, ]*/"&"/g')")
    cf_api PUT "/lists/$LIST_ID" "$LIST_PAYLOAD" > /dev/null
  fi
  
  if [[ -z "$LIST_ID" ]]; then
    fail "Failed to manage Access List for $CATEGORY"
    continue
  fi
  pass "Access List ready: $LIST_ID"

  # 4b. Find or Create Access Policy
  POLICIES_JSON=$(cf_api GET "/apps/$APP_ID/policies")
  POLICY_ID=$(echo "$POLICIES_JSON" | node -e "
    const input = require('fs').readFileSync(0, 'utf8');
    const data = JSON.parse(input);
    if (!data.result) { console.log(''); process.exit(0); }
    const policy = data.result.find(p => p.name === '$CATEGORY Access');
    console.log(policy ? policy.id : '');
  ")

  POLICY_PAYLOAD=$(printf '{"name":"%s Access","decision":"allow","precedence":10,"include":[{"group":{"id":"%s"}}]}' \
    "$CATEGORY" "$LIST_ID")

  if [[ -z "$POLICY_ID" ]]; then
      info "Creating new Access Policy for $CATEGORY..."
      cf_api POST "/apps/$APP_ID/policies" "$POLICY_PAYLOAD" > /dev/null
  else
      info "Updating existing Access Policy for $CATEGORY..."
      cf_api PUT "/apps/$APP_ID/policies/$POLICY_ID" "$POLICY_PAYLOAD" > /dev/null
  fi
  pass "Access Policy synced for $CATEGORY"
done

# 5. Handle built-in paths
# /public/* -> Bypass (or no policy)
# /auth/* -> Any authenticated user

info "Syncing special policies..."
# Any Authenticated User policy for /auth/*
POLICY_ID=$(echo "$POLICIES_JSON" | node -e "
  const input = require('fs').readFileSync(0, 'utf8');
  const data = JSON.parse(input);
  if (!data.result) { console.log(''); process.exit(0); }
  const policy = data.result.find(p => p.name === 'Any Authenticated User');
  console.log(policy ? policy.id : '');
")

AUTH_PAYLOAD='{"name":"Any Authenticated User","decision":"allow","precedence":5,"include":[{"everyone":{}}]}'
if [[ -z "$POLICY_ID" ]]; then
    cf_api POST "/apps/$APP_ID/policies" "$AUTH_PAYLOAD" > /dev/null
fi
pass "Authenticated User policy synced"

# Bypass for /public/*
POLICY_ID=$(echo "$POLICIES_JSON" | node -e "
  const input = require('fs').readFileSync(0, 'utf8');
  const data = JSON.parse(input);
  if (!data.result) { console.log(''); process.exit(0); }
  const policy = data.result.find(p => p.name === 'Public Bypass');
  console.log(policy ? policy.id : '');
")

BYPASS_PAYLOAD='{"name":"Public Bypass","decision":"bypass","precedence":1,"include":[{"everyone":{}}]}'
if [[ -z "$POLICY_ID" ]]; then
    cf_api POST "/apps/$APP_ID/policies" "$BYPASS_PAYLOAD" > /dev/null
fi
pass "Public Bypass policy synced"

echo -e "\n${GREEN}${BOLD}✓ Cloudflare Access configuration synced successfully!${RESET}"
