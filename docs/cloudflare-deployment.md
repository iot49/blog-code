# Cloudflare Deployment Guide

This guide covers deploying the blog to Cloudflare Pages using CLI tools.

## Prerequisites

1. **Cloudflare account** with a configured domain
2. **Cloudflare API token** with Pages permissions
3. **Node.js** and **npm** installed
4. **wrangler** CLI tool

## Installation

### 1. Install Wrangler

```bash
npm install -g wrangler
```

### 2. Authenticate with Cloudflare

```bash
wrangler login
```

This will open a browser window for authentication.

Alternatively, use an API token:

```bash
export CLOUDFLARE_API_TOKEN="your-api-token"
```

## Initial Setup

### 1. Create Cloudflare Pages Project

```bash
wrangler pages project create blog-boser-guyon --production-branch=main
```

### 2. Configure Build Settings

Create `wrangler.toml` in the project root:

```toml
name = "blog-boser-guyon"
compatibility_date = "2024-01-01"

[site]
bucket = "./dist"

[build]
command = "npm run build"
cwd = "."
watch_dirs = ["src"]

[[pages_build_output_dir]]
dir = "dist"
```

## Deployment

### Manual Deployment

Build and deploy manually:

```bash
# Build the site
npm run build

# Deploy to Cloudflare Pages
wrangler pages deploy dist --project-name=blog-boser-guyon
```

### Automated Deployment (GitHub Actions)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: blog-boser-guyon
          directory: dist
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

Add secrets to your GitHub repository:
- `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token
- `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID

## Custom Domain Setup

### 1. Add Custom Domain via CLI

```bash
wrangler pages domain add blog.boser-guyon.org --project-name=blog-boser-guyon
```

### 2. Verify DNS Records

Cloudflare will provide DNS records. Add them to your domain:

```bash
# Check current DNS records
wrangler pages domain list --project-name=blog-boser-guyon
```

## Environment Variables

Set environment variables for your Pages project:

```bash
# For production
wrangler pages secret put VARIABLE_NAME --project-name=blog-boser-guyon

# For preview environments  
wrangler pages secret put VARIABLE_NAME --env=preview --project-name=blog-boser-guyon
```

## Preview Deployments

Preview deployments are automatically created for:
- Pull requests
- Non-main branches

Access them via:
```
https://<commit-hash>.blog-boser-guyon.pages.dev
```

## Build Configuration

The build process:

1. **Install dependencies**: `npm ci`
2. **Build Astro site**: `npm run build`
3. **Output directory**: `dist/`
4. **Deploy**: Upload `dist/` to Cloudflare Pages

### Build Environment

- Node.js version: 20.x (configurable)
- Build timeout: 20 minutes
- Memory: 8GB

## Verify Deployment

After deployment:

```bash
# List deployments
wrangler pages deployment list --project-name=blog-boser-guyon

# Get deployment URL
wrangler pages deployment get <deployment-id> --project-name=blog-boser-guyon
```

## Troubleshooting

### Build Failures

Check build logs:
```bash
wrangler pages deployment tail --project-name=blog-boser-guyon
```

### Clear Cache

Purge Cloudflare cache:
```bash
wrangler pages deployment tail --project-name=blog-boser-guyon
```

### DNS Issues

Verify DNS propagation:
```bash
dig blog.boser-guyon.org
nslookup blog.boser-guyon.org
```

## Performance Optimization

### Headers

Create `public/_headers`:

```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(), microphone=(), camera=()

/*.css
  Cache-Control: public, max-age=31536000, immutable

/*.js
  Cache-Control: public, max-age=31536000, immutable

/*.woff2
  Cache-Control: public, max-age=31536000, immutable
```

### Redirects

Create `public/_redirects`:

```
# Redirect old URLs
/old-path /new-path 301

# SPA fallback (if needed)
/* /index.html 200
```

## Next Steps

1. Set up Cloudflare Access for authentication (see `cloudflare-access.md`)
2. Configure analytics and monitoring
3. Set up preview environments
4. Add build notifications

## Resources

- [Cloudflare Pages Docs](https://developers.cloudflare.com/pages/)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler/)
- [GitHub Actions for Pages](https://github.com/cloudflare/pages-action)
