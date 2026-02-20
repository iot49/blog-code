---
title: 'Cloudflare Access Authentication'
publishDate: 2026-02-19
excerpt: 'Setting up Zero Trust hierarchical access control for your blog content.'
image: https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'setup', 'authentication', 'cloudflare', 'zero-trust']
---

Cloudflare Access provides Zero Trust authentication for your blog, allowing you to protect content based on hierarchical access levels (`public`, `friends`, `family`, `private`) without custom server-side code.

The file `access-list.yaml` is used to configure the access levels for authorized email addresses.

## Architecture

The blog uses a path-based security model:

- `/public/*` → No authentication required (Public Bypass).
- `/friends/*` → Requires authentication (Friends Email List).
- `/family/*` → Requires authentication (Family Email List).
- `/private/*` → Requires authentication (Restricted to Owner).

## Prerequisites

1.  Cloudflare account with an active website (Zone).
2.  Domain already configured on Cloudflare.
3.  [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-setup/) installed.
4.  Cloudflare API token with the following permissions:
    - **Account** > **Access: Organizations and Groups** > **Edit**
    - **Account** > **Access: Apps and Policies** > **Edit**
    - **Zone** > **Access: Apps and Policies** > **Edit**
    - **Zone** > **Zone** > **Read**

## Automated Setup

We provide a script to automatically sync your `access-list.yaml` to Cloudflare Access Policies.

```bash
# 1. Configure environment variables
export CF_API_TOKEN="your-token"
export CF_ACCOUNT_ID="your-account-id"
export DOMAIN="your-blog.com"

# 2. Run the sync script
../blog-code/infra/cloudflare-access.sh
```

## Testing with Gmail Aliases

You can test multiple access levels using a single Gmail account via aliases:

- `yourname@gmail.com`
- `yourname+friend1@gmail.com`
- `yourname+family1@gmail.com`

All aliases deliver to the same inbox, but Cloudflare treats them as distinct identities, allowing you to verify that policies are working as expected.

## Resources

- [Cloudflare Access Documentation](https://developers.cloudflare.com/cloudflare-one/identity/access/)
- [Wrangler Access Commands](https://developers.cloudflare.com/workers/wrangler/commands/#access)
