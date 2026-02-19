# Blog Codebase (AstroWind Fork)

This repository contains the **source code** for the blog, based on the [AstroWind](https://github.com/onwidget/astrowind) template.

Crucially, **the content is decoupled from the code**. This repository is public, but the actual blog posts, pages, and configurations (the "content") are expected to reside in a sibling directory named `blog-content` (or configured otherwise).

## 🚀 Key Differences from AstroWind

### 1. Separation of Concerns (Code vs. Content)

- **Stock AstroWind**: Content (e.g., `src/content/post`, `src/pages`) is mixed with the theme code.
- **This Fork**:
  - The `src/content` and `src/pages` directories in this repo act as _fallbacks_ or _templates_.
  - The build scripts are designed to pull content from a sibling directory (`../blog-content` by default).
  - This allows the theme logic and components to be open-sourced while keeping personal writing and drafts private until deployment.

### 2. Custom Scripts (`bin/`)

We include several utility scripts in `bin/` to manage this split workflow:

- `bin/preview`: Runs the local development server, pointing it to the external content directory.
- `bin/deploy`: Builds the site using the external content and deploys it (e.g., to Cloudflare Pages).
- `bin/check-links`: specific utility to validate internal links within the content.

### 3. Jupyter Notebook Support

- **Integration**: Includes tooling to convert Jupyter Notebooks (`.ipynb`) into Markdown posts automatically.
- **Python Environment**: An internal `.venv` (managed by `uv`) is used for the conversion scripts.
- **Workflow**: Drop a notebook into the content folder, and the build process handles the conversion, including LaTeX math rendering.

### 4. Deployment Configuration

- Optimized for **Cloudflare Pages**.
- Includes `wrangler` configuration (if applicable) and scripts to handle direct uploads.

## 🛠️ Setup & Usage

### Prerequisites

- Node.js & npm
- Python (for notebook support)
- `uv` (optional, for managing Python dependencies)

### Installation

1.  **Clone this repository**:

    ```bash
    git clone https://github.com/your-username/blog-code.git
    cd blog-code
    npm install
    ```

2.  **Setup Content Directory**:
    Create a directory named `blog-content` at the same level as `blog-code`:
    ```bash
    cd ..
    mkdir blog-content
    # Populate blog-content with your posts, pages, etc.
    ```

### Running Locally

To start the dev server using your content:

```bash
bin/preview
```

### Deployment

To build and deploy:

```bash
bin/deploy
```

## 📝 License

Based on [AstroWind](https://github.com/onwidget/astrowind), licensed under the MIT License.
