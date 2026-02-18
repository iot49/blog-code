# Jupyter Notebook Integration

This blog supports Jupyter notebooks (`.ipynb` files) by converting them to Markdown.

## Setup

The Python environment is managed with `uv` and `direnv`:

1. **Virtual environment**: Auto-created with `uv venv` in `.venv/`
2. **Auto-activation**: `direnv` automatically activates the venv when you enter the project directory
3. **Dependencies**: Managed in `requirements.txt`

### First Time Setup

```bash
# Create virtual environment (already done)
uv venv

# Install dependencies
uv pip install -r requirements.txt

# Allow direnv
direnv allow .
```

## Converting Notebooks

### 1. Create your Jupyter notebook

Save your `.ipynb` file in the `notebooks/` directory.

### 2. Convert to blog post

```bash
python3 scripts/convert-notebook.py notebooks/your-notebook.ipynb [output-name]
```

This will:

- Convert the notebook to Markdown
- Add proper frontmatter (title, date, tags, topic, accessLevel)
- Save to `src/data/post/your-notebook.md`
- Move any generated images to `public/images/posts/your-notebook/`

### 3. Edit frontmatter (optional)

Open `src/data/post/your-notebook.md` and customize:

- `title`: Post title
- `excerpt`: Brief description
- `topic`: `'blog'`, `'modelrailroad'`, or `'software'`
- `tags`: Array of tags
- `draft`: Set to `false` to publish
- `accessLevel`: `'public'`, `'friends'`, `'family'`, or `'private'`

### 4. Preview

The dev server auto-reloads. Visit `http://localhost:4321/blog` to see your post.

## Features

✅ **Code syntax highlighting** - Automatic for Python, JavaScript, etc.
✅ **LaTeX equations** - Rendered with KaTeX (both inline `$...$` and display `$$...$$`)
✅ **Images** - Automatically copied to public directory
✅ **Markdown cells** - Full markdown support
✅ **Metadata** - Extracted from notebook and frontmatter

## Example

See the test notebook at `notebooks/test-notebook.ipynb` and its converted output at `src/data/post/test-notebook.md`.

## Tips

- **Execute cells**: Run all cells before converting to include outputs in the blog post
- **Image paths**: Images are automatically relinked to `/images/posts/[notebook-name]/`
- **LaTeX**: Use standard LaTeX syntax, it works seamlessly
- **Code blocks**: All code is preserved with proper syntax highlighting
