# Cloudflare Access Authentication Setup

This guide covers setting up Cloudflare Access for hierarchical authentication on your blog using CLI tools.

## Overview

Cloudflare Access provides Zero Trust authentication for your blog, allowing you to:

- Protect content by access level (`public`, `friends`, `family`, `private`)
- Use email-based authentication
- Manage access policies via CLI
- No authentication required for `public` content

## Architecture

```
┌─────────────────────────────────────────┐
│  blog.boser-guyon.org                   │
├─────────────────────────────────────────┤
│  /public/*     → No auth required       │
│  /friends/*    → Friends policy         │
│  /family/*     → Family policy          │
│  /private/*    → Private policy         │
└─────────────────────────────────────────┘
```

## Prerequisites

1. Cloudflare account with active zone
2. Domain configured on Cloudflare
3. Wrangler CLI installed
4. Cloudflare API token with Access permissions

## Setup

### 1. Enable Cloudflare Access

```bash
# Check if Access is enabled
wrangler access application list

# If not enabled, enable it via:
# https://dash.cloudflare.com/profile/api-tokens
```

### 2. Create Access Application

```bash
wrangler access application create \
  --name "Blog - Boser Guyon" \
  --domain "blog.boser-guyon.org" \
  --session-duration "24h"
```

### 3. Configure Authentication Method

Use one-time email codes for simplicity:

```bash
wrangler access identity-provider add \
  --type "onetimepin" \
  --name "Email OTP"
```

## Access Policies

### Policy Structure

Each access level has a corresponding policy:

1. **Public** - No authentication
2. **Friends** - Email list (friends)
3. **Family** - Email list (family)
4. **Private** - Specific email (your email only)

### Creating Policies via CLI

#### Public Content (No Auth)

Public content doesn't need Cloudflare Access. Serve it directly.

#### Friends Policy

```bash
wrangler access policy create \
  --application-id "<app-id>" \
  --name "Friends Access" \
  --path "/friends/*" \
  --decision "allow" \
  --  include-email "friend1@example.com" \
  --include-email "friend2@example.com" \
  --include-email "yourpersonal@gmail.com"
```

#### Family Policy

```bash
wrangler access policy create \
  --application-id "<app-id>" \
  --name "Family Access" \
  --path "/family/*" \
  --decision "allow" \
  --include-email "family1@example.com" \
  --include-email "family2@example.com" \
  --include-email "yourpersonal@gmail.com"
```

#### Private Policy

```bash
wrangler access policy create \
  --application-id "<app-id>" \
  --name "Private Access" \
  --path "/private/*" \
  --decision "allow" \
  --include-email "yourpersonal@gmail.com"
```

### Using Email Lists

Instead of individual emails, create email lists for easier management:

```bash
# Create email list for friends
wrangler access list create \
  --name "Friends" \
  --emails "friend1@example.com,friend2@example.com"

# Use in policy
wrangler access policy create \
  --application-id "<app-id>" \
  --name "Friends Access" \
  --path "/friends/*" \
  --decision "allow" \
  --include-list "<list-id>"
```

## Content Organization

### Folder Structure

Organize posts by access level:

```
src/data/post/
├── public/
│   ├── welcome-latex-test.md
│   └── getting-started-model-railroading.md
├── friends/
│   └── personal-updates.md
├── family/
│   └── family-photos.md
└── private/
    └── draft-ideas.md
```

### Build-time Path Mapping

Update Astro build to organize output by access level:

```javascript
// astro.config.ts
export default defineConfig({
  // ... other config
  build: {
    format: 'directory', // Creates clean URLs
  },
});
```

## Testing Access Policies

### Using Gmail Aliases

Test multiple access levels with Gmail aliases:

```
yourpersonal@gmail.com
yourpersonal+friend1@gmail.com
yourpersonal+family1@gmail.com
```

All aliases deliver to the same inbox, but Cloudflare treats them as different emails.

### Test Flow

1. **Create test policies** with your Gmail aliases
2. **Open incognito window**
3. **Navigate to protected path** (e.g., `/friends/some-post`)
4. **Enter email** for authentication
5. **Check Gmail** for OTP code
6. **Enter OTP** to access content

### Example Test

```bash
# Add test emails to friends policy
wrangler access policy update <policy-id> \
  --include-email "yourpersonal@gmail.com" \
  --include-email "yourpersonal+friend1@gmail.com"
```

## Dynamic Access Control

### Option 1: Static Build with Separate Folders

Simplest approach - organize by folder and protect with Access policies.

**Pros:**

- Simple setup
- Works with static hosting
- Clear separation

**Cons:**

- URL structure reveals access level
- Can't dynamically change accessLevel

### Option 2: Edge Function with JWT

For more dynamic control, use Cloudflare Workers to check JWT:

```javascript
// functions/[[path]].js
export async function onRequest(context) {
  const { request, env } = context;

  // Get JWT from Cloudflare Access
  const jwt = request.headers.get('cf-access-jwt-assertion');

  if (!jwt) {
    // Public content - serve normally
    return context.next();
  }

  // Decode JWT to get user email
  const payload = JSON.parse(atob(jwt.split('.')[1]));
  const userEmail = payload.email;

  // Check if user has access to requested content
  // (implement your logic here)

  return context.next();
}
```

## Hierarchical Access

Ensure higher levels include lower levels:

- **Friends** can access: `friends` + `public`
- **Family** can access: `family` + `friends` + `public`
- **Private** (you) can access: everything

Implement in policies:

```bash
# Friends policy includes public content
wrangler access policy create \
  --path "/friends/*" \
  --decision "allow" \
  --include-list "<friends-list>"

# Update public paths to not require auth
# (done by not adding Access policy to /public/*)
```

## Monitoring

### View Access Logs

```bash
wrangler access logs application <app-id>
```

### Check Active Sessions

```bash
wrangler access application revoke-session --user <email>
```

## Maintenance

### Update Email Lists

```bash
# Add email to list
wrangler access list add <list-id> --email "newemail@example.com"

# Remove email from list
wrangler access list remove <list-id> --email "oldemail@example.com"

# View list members
wrangler access list get <list-id>
```

### Update Policies

```bash
# List all policies
wrangler access policy list --application-id "<app-id>"

# Update policy
wrangler access policy update <policy-id> \
  --include-email "newemail@example.com"
```

## Configuration File

Store Access configuration in `wrangler.toml`:

```toml
[access]
application_id = "your-app-id"

[[access.policies]]
name = "Friends Access"
path = "/friends/*"
decision = "allow"
include = [
  { email = ["friend1@example.com", "friend2@example.com"] }
]

[[access.policies]]
name = "Family Access"
path = "/family/*"
decision = "allow"
include = [
  { email = ["family1@example.com", "family2@example.com"] }
]
```

## Next Steps

1. Create email lists for each access level
2. Set up test policies with Gmail aliases
3. Organize posts by access level
4. Test authentication flow
5. Deploy to production

## Resources

- [Cloudflare Access Docs](https://developers.cloudflare.com/cloudflare-one/identity/access/)
- [Wrangler Access Commands](https://developers.cloudflare.com/workers/wrangler/commands/#access)
- [JWT Verification](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/)
