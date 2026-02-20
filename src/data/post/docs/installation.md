---
title: 'Installation & Setup Guide'
publishDate: 2026-02-19
excerpt: 'Get your blog up and running locally for development and content authoring.'
image: https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'setup', 'installation', 'node', 'npm']
---

This guide will help you set up the blog code repository on your local machine for development and writing.

## Prerequisites

- **Node.js**: Version 18.17.1 or higher.
- **npm**: Included with Node.js.
- **Git**: For version control.
- **uv & direnv**: (Optional, but recommended for Jupyter support).

## Getting Started

1.  **Clone the Repository**:

    ```bash
    git clone https://github.com/iot49/blog-code.git
    cd blog-code
    ```

2.  **Install Dependencies**:

    ```bash
    npm install
    ```

3.  **Content Repository**:
    This blog separates code from content. Ensure your `blog-content` repository is located adjacent to the `blog-code` folder:

    ```bash
    # Structure should look like:
    # /parent-dir
    #   ├── blog-code/
    #   └── blog-content/
    ```

4.  **Environment Variables**:
    Configure your `.env` file for local development and deployment. See the [Setting up Environment Variables](/public/docs/setting-up-env) guide for details.

## Development Workflow

### Local Preview

To start the Astro development server and preview your changes in real-time:

```bash
./bin/preview
```

The site will be available at `http://localhost:4321`.

### Running Tests

Before pushing any changes, ensure all tests pass. This script checks linting, types, and verifies that no private content is leaked in the build:

```bash
./bin/test
```

### Build & Deploy

To build the site for production:

```bash
./bin/deploy
```

This script syncs your latest content, builds the static site, and prepares it for Cloudflare Pages.

### Check Links

To check for broken external links:

```bash
./bin/check-links
```

Run this infrequently to avoid rate limiting by some providers.
