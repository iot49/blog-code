---
title: 'Jupyter Notebook Integration'
publishDate: 2026-01-01
author: Gemini
excerpt: 'How to write blog posts using Jupyter Notebooks with full LaTeX and code block support.'
image: https://images.unsplash.com/photo-1515879218367-8466d910aaa4?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'jupyter', 'python', 'latex', 'setup']
---

This blog supports Jupyter notebooks (`.ipynb` files) by converting them to Markdown, allowing you to share interactive code and mathematical formulations directly with your readers.

## Environment Setup

The Python environment is managed with `uv` and `direnv` for maximum performance and stability:

- **Auto-activation**: `direnv` automatically activates the virtual environment when you enter the project directory.
- **Dependency Management**: All requirements are pinned in `requirements.txt`.

### First-Time Installation

```bash
# Sync dependencies
uv pip install -r requirements.txt

# Allow direnv to manage the environment
direnv allow .
```

## Creating a Blog Post from a Notebook

1.  **Write your Notebook**: Save your `.ipynb` file in the `notebooks/` directory.
2.  **Convert**: Run the conversion script provided in the repository.

```bash
python3 scripts/convert-notebook.py notebooks/your-notebook.ipynb
```

This script performs several automated tasks:

- Converts cells to Markdown.
- Adds appropriate frontmatter (defaulting to `topic: blog` and `accessLevel: public`).
- Relinks and moves generated images (plots, figures) to the correct asset directory.
- Handles **LaTeX equations** ($E=mc^2$) so they render beautifully using KaTeX.

## Features Supported

- ✅ **Syntax Highlighting**: Automatic for Python, JavaScript, and more.
- ✅ **Mathematical Equations**: Full support for inline (`$...$`) and block (`$$...$$`) LaTeX.
- ✅ **Rich Outputs**: DataFrames, plots, and console outputs are preserved.
- ✅ **Access Control**: You can set the `accessLevel` in the frontmatter of the converted Markdown.

## Best Practices

- **Run All Cells**: Ensure you execute your notebook before conversion so that the outputs are correctly captured.
- **Review Frontmatter**: After conversion, check the generated `.md` file to verify the title and tags are what you intended.
- **Draft Status**: Converted posts are set to `draft: true` by default. Set this to `false` when you're ready to publish.
