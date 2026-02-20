---
title: 'Technical Documentation Overview'
publishDate: 2026-02-19
excerpt: 'An overview of the technical architecture and features of this blog.'
image: https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
pinned: true
tags: ['doc', 'architecture']
---

Welcome to the technical documentation for this blog. This series of posts covers how the blog is built, deployed, and the various features it supports.

## Documentation Posts

- [**Installation & Setup**](/public/docs/installation) - How to get the blog running locally and configure the environment.
- [**Deployment**](/public/docs/deployment) - How the blog is built and deployed to Cloudflare Pages.
- [**Authentication**](/public/docs/authentication) - Hierarchical access control with Cloudflare Access.
- [**Comments**](/public/docs/comments) - Integrating Giscus comments via GitHub Discussions.
- [**Search**](/public/docs/search) - Privacy-preserving static search.
- [**Client-Side Translation**](/public/docs/translation) - On-demand translation with Google Translate.
- [**VSCode Image Paste**](/public/docs/vscode-images) - Seamless image workflow for authors.
- [**Jupyter Notebooks**](/public/docs/jupyter-notebooks) - Writing posts using Jupyter Notebooks.

## Architecture

This blog is built with **Astro 5.0**, leveraging its static site generation (SSG) capabilities for extreme performance and security. Content is separate from code, allowing for private draft management and hierarchical access control.
