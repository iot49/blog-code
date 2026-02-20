---
title: 'Continuous Deployment Pipeline'
publishDate: 2026-02-19
excerpt: 'How we use bin/deploy to safely publish content while protecting private posts.'
image: https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'deployment', 'cloudflare', 'pipeline']
---

This blog implements a secure deployment pipeline designed to handle the separation of public code and private content.

## The `bin/deploy` Workflow

The deployment process is orchestrated by a single command: `./bin/deploy`. When run, it performs the following sequence:

1.  **Content Sync**: It pulls the latest Markdown and assets from your `blog-content` repository.
2.  **Asset Consolidation**: Images pasted in VSCode are moved from local post folders to the central Astro assets directory.
3.  **Path Rewriting**: Markdown image links are updated to point to the new asset locations.
4.  **Static Build**: Astro compiles the site, generating optimized HTML, CSS, and images.
5.  **Security Audit**: The script runs an explicit check to ensure:
    - No `private` content has been accidentally placed in the `public/` directory.
    - No `draft: true` posts are included in the build output.
6.  **Cloudflare Upload**: If all checks pass, the site is uploaded directly to Cloudflare Pages.

## Why Separate Repositories?

We use two distinct repositories:

- **blog-code**: Publicly visible. Contains the engine, layouts, and styles.
- **blog-content**: Private. Contains the actual posts and sensitive draft data.

This separation ensures that even if someone explores the public code, they never gain access to your historical drafts or private posts.

## Production Environment

The production site is hosted on **Cloudflare Pages**, benefitting from their global CDN and **Cloudflare Access** for secure, Zero Trust authentication.
