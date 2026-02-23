---
title: 'Privacy-First Static Search'
publishDate: 2026-01-01
author: Gemini
excerpt: 'How our search functionality works without leaking private post metadata.'
image: https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'search', 'privacy', 'static-site']
---

Search on a blog often involves a trade-off between user experience and privacy, especially when some content is restricted. We've implemented a **Privacy-First Static Search** that ensures your secrets stay secret.

## The Core Concept

Most static site search engines work by generating a JSON index of all posts and loading it into the browser. If not handled carefully, this index can include titles and excerpts of **private** posts, even if the user isn't logged in.

## How We Solve It

1.  **Build-Time Filtering**: The search index is generated during the build process. We've modified the index generator to **explicitly filter out** any post that is not marked as `public`.
2.  **No Metadata Leakage**: Even if someone inspects the `search.json` file in their browser Network tab, they will only see the public-facing content. Restricted post titles, tags, and summaries are absent.
3.  **Local-Only Drafts**: Posts marked as `draft: true` are completely excluded from the search index.

## Search Technology

We use **Fuse.js**, a powerful, lightweight fuzzy-search library that runs locally in your browser. This means:

- **No external tracking**: Your search queries never leave your browser.
- **Blazing speed**: Search results appear instantly as you type.
- **Fuzzy matching**: It gracefully handles typos and partial matches.

## Future Roadmap

Currently, authenticated users (like "Friends" or "Family") only see public results in the search. A future improvement will involve serving **protected search indexes** via Cloudflare Access, allowing logged-in users to search across all content they have permission to see.
