# Blog Codebase (Engine & Theme)

This repository contains the "engine" and UI theme for the blog. It is based on Astro 5.0 and the Astrowind theme.

The blog is designed with a **code/content split architecture**:

- **blog-code** (this repo): Public theme, engine, components, and infrastructure.
- **blog-content** (private): Actual Markdown posts, site configuration, and assets.

## Documentation

Full technical documentation is served as posts by the blog itself. The source files live in `blog-content/src/data/post/docs/`:

- [**Technical Documentation Overview**](../blog-content/src/data/post/docs/overview.md)
- [**Installation & Setup**](../blog-content/src/data/post/docs/installation.md)
- [**Deployment**](../blog-content/src/data/post/docs/deployment.md)

## Development

```bash
# Install dependencies
npm install

# Run local dev server (syncs content from ../blog-content)
bin/preview

# Build for production
npm run build
```

For actual content development, use the scripts provided in the `blog-content` repository.
