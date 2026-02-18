#!/usr/bin/env python3
"""
Convert Jupyter notebooks to Markdown for Astro blog posts.

Usage:
    python scripts/convert-notebook.py notebooks/my-notebook.ipynb [output-filename]

This will:
1. Convert the notebook to markdown using nbconvert
2. Add appropriate frontmatter for the blog
3. Save to src/data/post/ directory
"""

import sys
import os
import json
from pathlib import Path
from datetime import datetime
import subprocess

def convert_notebook(notebook_path, output_name=None):
    """Convert a Jupyter notebook to a blog post."""
    
    notebook_path = Path(notebook_path)
    
    if not notebook_path.exists():
        print(f"Error: Notebook '{notebook_path}' not found")
        sys.exit(1)
    
    # Read notebook to extract metadata
    with open(notebook_path, 'r') as f:
        notebook = json.load(f)
    
    # Extract title from first markdown cell (if it's a header)
    title = notebook_path.stem.replace('-', ' ').title()
    first_cell = notebook.get('cells', [{}])[0]
    if first_cell.get('cell_type') == 'markdown':
        first_line = first_cell.get('source', [''])[0]
        if first_line.startswith('# '):
            title = first_line[2:].strip()
    
    # Determine output filename
    if output_name is None:
        output_name = notebook_path.stem
    
    output_path = Path('src/data/post') / f'{output_name}.md'
    
    # Convert using nbconvert
    temp_md = notebook_path.with_suffix('.md')
    
    # Find jupyter-nbconvert in common locations
    jupyter_cmd = None
    possible_paths = [
        '.venv/bin/jupyter',  # Check project venv first
        'jupyter',  # Try system PATH
        str(Path.home() / 'Library/Python/3.9/bin/jupyter'),
        str(Path.home() / '.local/bin/jupyter'),
        '/usr/local/bin/jupyter',
    ]
    
    for cmd in possible_paths:
        try:
            result = subprocess.run([cmd, '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                jupyter_cmd = cmd
                break
        except FileNotFoundError:
            continue
    
    if jupyter_cmd is None:
        print("Error: jupyter nbconvert not found. Please install it:")
        print("  pip3 install nbconvert")
        sys.exit(1)
    
    try:
        subprocess.run([
            jupyter_cmd, 'nbconvert',
            '--to', 'markdown',
            '--output', str(temp_md.absolute()),
            str(notebook_path.absolute())
        ], check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running nbconvert: {e}")
        print(f"stderr: {e.stderr}")
        sys.exit(1)
    
    # Read the converted markdown
    with open(temp_md, 'r') as f:
        content = f.read()
    
    # Create frontmatter
    today = datetime.now().strftime('%Y-%m-%d')
    frontmatter = f"""---
publishDate: {today}
title: '{title}'
excerpt: 'A Jupyter notebook demonstration for the blog'
topic: 'software'
tags: ['python', 'jupyter', 'data-science']
draft: false
accessLevel: 'public'
---

"""
    
    # Combine frontmatter and content
    final_content = frontmatter + content
    
    # Write to output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(final_content)
    
    # Clean up temp file
    temp_md.unlink()
    
    # Move any generated images
    images_dir = notebook_path.parent / f'{notebook_path.stem}_files'
    if images_dir.exists():
        dest_images = Path('public/images/posts') / notebook_path.stem
        dest_images.mkdir(parents=True, exist_ok=True)
        
        for img in images_dir.glob('*'):
            dest_img = dest_images / img.name
            img.rename(dest_img)
            
            # Update image paths in markdown
            with open(output_path, 'r') as f:
                content = f.read()
            
            content = content.replace(
                f'{notebook_path.stem}_files/{img.name}',
                f'/images/posts/{notebook_path.stem}/{img.name}'
            )
            
            with open(output_path, 'w') as f:
                f.write(content)
        
        # Remove empty images directory
        images_dir.rmdir()
    
    print(f"✅ Converted '{notebook_path}' -> '{output_path}'")
    if images_dir.exists():
        print(f"📁 Images saved to: public/images/posts/{notebook_path.stem}/")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python scripts/convert-notebook.py <notebook.ipynb> [output-name]")
        sys.exit(1)
    
    notebook = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else None
    
    convert_notebook(notebook, output)
