---
publishDate: 2026-02-19
title: 'Setting up Environment Variables'
excerpt: 'A guide on configuring the .env file for the blog and defining the necessary Cloudflare API permissions.'
topic: 'blog'
tags:
  - doc
  - env
  - setup
draft: false
accessLevel: 'public'
---

# Setting up Environment Variables

To run and deploy this blog, you need to configure several environment variables. These are stored in a `.env` file at the root of your project.

## The .env File Template

Create a file named `.env` in the root of your `blog-content` directory (it is already in the `.gitignore` to prevent sensitive keys from being committed).

```bash
# Cloudflare Configuration
DOMAIN=your-domain.com
CF_API_TOKEN=your-cloudflare-api-token
CF_ACCOUNT_ID=your-cloudflare-account-id
CF_ZONE_ID=your-cloudflare-zone-id
CLOUDFLARE_PROJECT_NAME=your-project-name

# Giscus Comments Configuration
# Obtain these values from https://giscus.app/
PUBLIC_GISCUS_REPO=your-username/your-repo
PUBLIC_GISCUS_REPO_ID=R_...
PUBLIC_GISCUS_CATEGORY=Announcements
PUBLIC_GISCUS_CATEGORY_ID=DIC_...
```

## Cloudflare Variable Breakdown

- **DOMAIN**: The base domain where your blog is hosted.
- **CF_API_TOKEN**: The token used by `wrangler` to authenticate with Cloudflare during deployment.
- **CF_ACCOUNT_ID**: Found in your Cloudflare dashboard URL (the string after `dash.cloudflare.com/`).
- **CF_ZONE_ID**: Found on the Overview page of your domain in the Cloudflare dashboard.
- **CLOUDFLARE_PROJECT_NAME**: The name you gave to your Cloudflare Pages project.

## Cloudflare API Token Permissions

For the `bin/deploy` script to work correctly, the `CF_API_TOKEN` must have the appropriate permissions to upload files to Cloudflare Pages.

### Required Permissions

When creating a custom token in the [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens), use the following settings:

| Scope       | Resource             | Permission |
| :---------- | :------------------- | :--------- |
| **Account** | **Cloudflare Pages** | **Edit**   |
| **Account** | **Access**           | **Edit**   |
| **Zone**    | **Zone**             | **Read**   |
| **User**    | **User Details**     | **Read**   |

### Steps to Create the Token

1. Log in to your Cloudflare Dashboard.
2. Go to **My Profile** > **API Tokens**.
3. Click **Create Token**.
4. Use the **"Edit Cloudflare Pages"** template if available, or create a **Custom Token**.
5. Add the permissions listed above.
6. Set the **Account Resources** to "All accounts" (or select your specific account).
7. Set the **Zone Resources** to "All zones" (or select your specific domain).
8. Click **Continue to summary** and then **Create Token**.

## Giscus Configuration

Giscus is the comment system used for this blog. To set it up:

1. Go to [giscus.app](https://giscus.app/).
2. Follow the instructions to Choose a repository (must be public and have the Giscus app installed).
3. Copy the generated `REPO_ID` and `CATEGORY_ID` into your `.env` file.

## Loading variables

The `bin/` scripts are designed to work with these variables. If you use `direnv`, you can also create a `.envrc` file with the content `export $(cat .env | xargs)` to have them automatically loaded into your shell when you enter the directory.
