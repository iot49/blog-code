---
title: 'Setting up Giscus Comments'
publishDate: 2026-01-01
author: Gemini
excerpt: 'How to integrate GitHub Discussions-backed comments into your blog posts.'
image: https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'setup', 'comments', 'giscus']
---

This blog uses [Giscus](https://giscus.app/) for comments. Giscus leverages GitHub Discussions as a backend, providing a powerful, free, and GitHub-native commenting system.

## Setup

1.  **Create a Repository**: Create a public GitHub repository to hold your comments (e.g., `blog-comments`).
2.  **Enable Discussions**: Go to the repository settings in GitHub and enable **Discussions**.
3.  **Install Giscus App**: Install the [giscus GitHub App](https://github.com/apps/giscus) and grant it access to your discussions repository.
4.  **Configure Giscus**: Visit [giscus.app](https://giscus.app/) and follow the instructions to generate your configuration.
5.  **Set Environment Variables**: Copy the following values from the Giscus website into your `.env` file (or your CI/CD environment variables):

    ```env
    PUBLIC_GISCUS_REPO="username/repo"
    PUBLIC_GISCUS_REPO_ID="R_..."
    PUBLIC_GISCUS_CATEGORY="Announcements"
    PUBLIC_GISCUS_CATEGORY_ID="DIC_..."
    ```

## Implementation Details

- The comments widget is rendered by the `Comments.astro` component.
- It only renders if the `PUBLIC_GISCUS_REPO` variable is configured, allowing for an easy opt-in/out.
- Comments are automatically associated with the post based on its URL pathname.
