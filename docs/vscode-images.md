# VSCode Image Paste Support

This blog supports a seamless workflow for adding images to your posts using VSCode's built-in image paste functionality.

## Workflow

1.  **Open a Markdown file**: Open any post in the `src/data/post/` directory.
2.  **Paste an image**: Copy an image to your clipboard and paste it directly into the Markdown editor (`Cmd+V` or `Ctrl+V`).
3.  **Automatic placement**: VSCode will automatically:
    - Save the image into a subfolder: `images/<post-name>/<image-name>.png`.
    - Insert a relative link in your Markdown: `![Description](images/<post-name>/<image-name>.png)`.

## How it works (Deployment)

When you run `bin/deploy`, the following happens automatically:

1.  **Sync**: All files from your content repository are synced to the local build environment.
2.  **Consolidation**: Any images found in `src/data/post/images/` are moved to `src/assets/images/`.
3.  **Path Rewriting**: The relative paths in your Markdown files are rewritten from `images/...` to `../../assets/images/...`.
4.  **Optimization**: Astro's image service picks up the images from the `assets` folder and optimizes them (compression, WebP conversion, etc.) for the final build.

## Configuration

The behavior is controlled by the following setting in `.vscode/settings.json`:

```json
"markdown.copyFiles.destination": {
  "**/*.md": "images/${documentBaseName}/"
}
```

## Benefits

- **Clean Repo**: Images for a specific post are neatly grouped in a folder named after the post.
- **VSCode Preview**: Images display correctly in the VSCode Markdown preview.
- **Astro Optimization**: Images are automatically processed by Astro for maximum performance.
- **Source Integrity**: Original files in your `blog-content` repository remain untouched; path rewriting only happens in the temporary build copy.
