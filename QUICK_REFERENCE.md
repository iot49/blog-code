# Quick Reference Guide

## Daily Workflow

### Starting Development
```bash
cd /Users/boser/Documents/personal/iot/blog
# direnv automatically activates Python venv
npm run dev
# Open http://localhost:4321
```

### Creating a New Blog Post

#### Markdown Post
```bash
# Create file in src/data/post/
touch src/data/post/my-new-post.md
```

Add frontmatter:
```yaml
---
publishDate: 2026-02-17
title: 'My Post Title'
excerpt: 'Brief description'
topic: 'blog'  # or 'modelrailroad', 'software'
tags: ['tag1', 'tag2']
draft: false
accessLevel: 'public'  # or 'friends', 'family', 'private'
---
```

#### Jupyter Notebook Post
```bash
# 1. Create notebook in notebooks/
jupyter notebook notebooks/my-analysis.ipynb

# 2. Run all cells, save

# 3. Convert to blog post
python3 scripts/convert-notebook.py notebooks/my-analysis.ipynb

# 4. Edit frontmatter in src/data/post/my-analysis.md if needed
```

### Building for Production
```bash
npm run build
# Output in dist/
```

### Deployment

#### Manual
```bash
npm run build
wrangler pages deploy dist --project-name=blog-boser-guyon
```

#### Automatic (GitHub)
```bash
git add .
git commit -m "New post: my post title"
git push origin main
# GitHub Actions automatically builds and deploys
```

## Common Commands

### Development
```bash
npm run dev          # Start dev server
npm run build        # Build for production
npm run preview      # Preview production build
```

### Python (Notebooks)
```bash
uv pip install <package>        # Add Python dependency
uv pip freeze > requirements.txt  # Update requirements
python3 scripts/convert-notebook.py notebooks/file.ipynb  # Convert notebook
```

### Git
```bash
git status
git add .
git commit -m "message"
git push origin main
```

### Cloudflare (when set up)
```bash
wrangler pages deployment list --project-name=blog-boser-guyon
wrangler pages project list
wrangler access application list
```

## File Structure

```
blog/
├── src/
│   ├── content/
│   │   └── config.ts          # Content schema
│   ├── data/
│   │   └── post/             # Blog posts (*.md)
│   ├── layouts/
│   │   └── Layout.astro      # Main layout (includes KaTeX CSS)
│   └── components/
├── notebooks/                 # Jupyter notebooks
├── scripts/
│   └── convert-notebook.py   # Notebook converter
├── docs/                     # Documentation
│   ├── jupyter-notebooks.md
│   ├── cloudflare-deployment.md
│   └── cloudflare-access.md
├── public/
│   ├── _headers             # Cloudflare headers
│   └── images/
├── .github/
│   └── workflows/
│       └── deploy.yml       # Auto-deployment
├── requirements.txt         # Python deps
├── .envrc                   # Direnv config
└── astro.config.ts          # Astro + plugins

```

## Frontmatter Fields

| Field | Type | Options | Default | Required |
|-------|------|---------|---------|----------|
| `publishDate` | Date | YYYY-MM-DD | - | No |
| `title` | String | - | - | Yes |
| `excerpt` | String | -  | - | No |
| `topic` | Enum | `blog`, `modelrailroad`, `software` | `blog` | No |
| `tags` | Array | - | `[]` | No |
| `draft` | Boolean | `true`, `false` | `true` | No |
| `accessLevel` | Enum | `public`, `friends`, `family`, `private` | `private` | No |

## URLs

- **Dev**: http://localhost:4321
- **Blog List**: http://localhost:4321/blog
- **Single Post**: http://localhost:4321/post-slug
- **Tag Page**: http://localhost:4321/tag/tag-name
- **Production** (when deployed): https://blog.boser-guyon.org

## Troubleshooting

### Dev server won't start
```bash
rm -rf node_modules .astro
npm install
npm run dev
```

### Python venv issues
```bash
rm -rf .venv
uv venv
uv pip install -r requirements.txt
direnv allow .
```

### Build errors
```bash
npm run check  # Check for TypeScript/Astro errors
```

### LaTeX not rendering
- Check KaTeX CSS is in `Layout.astro`
- Verify `remark-math` and `rehype-katex` in `astro.config.ts`
- Use `$...$` for inline, `$$...$$` for display

## Getting Help

- Astro Docs: https://docs.astro.build
- Cloudflare Pages: https://developers.cloudflare.com/pages/
- AstroWind Theme: https://github.com/onwidget/astrowind
- KaTeX: https://katex.org/
