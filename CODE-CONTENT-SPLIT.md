The blog is distributed over 2 folders:
_ blog-code
_ blog-content

The idea is that the first contains the "general setup" with a minimal amount of content as an example and for testing. It should be possible to have 2 unrelated blogs that share the same `blog-code` but with different contents, served at different domains.

The actual content (including blogs with access restrictions) is in blog-content (and also a private github repo).

Presently, some files are shared with symbolic links. Is this a good solution? Possible issues"

1. blog-code should be able to "exist on its own".
2. the content of some files might exist in both folders, but differ. E.g. navigation, about, contact, etc.

Analyze the current setup and propose a better solution.

### Analysis of Current Setup

The current architecture relies on symlinking files and directories from `blog-content` directly into `blog-code/src`.

1. **Fragility & Portability:** The symlinks break if the paths between repos change, or if a user clones `blog-code` without `blog-content`. Git treats replacing a file with a symlink as a modification, constantly dirtying the working tree of `blog-code`.
2. **Lack of True Standalone Capability:** `blog-code` cannot easily provide a "default" file that can be cleanly overridden. If a default `about.astro` exists, overriding it requires deleting it and creating a symlink instead.
3. **Scaling:** Manually managing symlinks for `navigation.ts`, `config.yaml`, `Logo.astro`, `data`, and various `pages` across multiple distinct blogs is tedious and error-prone.

### Proposed Solutions

#### 1. The Theme/Integration Model (Standard Astro Way - Highly Recommended)

In Astro, the best way to share a codebase across multiple independent sites is to package the logic as an **Astro Theme/Integration**, much like [Starlight](https://starlight.astro.build/) does.

- **`blog-code`** serves as a core dependency (e.g. via a PNPM workspace, git submodule, or NPM package). It exports all your UI components, utility scripts, and an `astro.config.ts` preset. It can also use Astro's `injectRoute` API for default pages (like a default `about` page).
- **`blog-content`** serves as the actual root Astro project. It has its own `package.json` and `astro.config.ts` that consume `blog-code`. It only contains the specific config, markdown content, and override pages (e.g., `src/pages/about.astro`).
- **Advantage:** Native Astro behavior. Any page defined in `blog-content/src/pages` naturally overrides an injected route from the theme. No symlinks are needed.

#### 2. Virtual Modules and Vite Fallback (Keep as Monolith)

Stay with your current monolith, but remove symlinks. Tell Astro/Vite to dynamically look in a sibling directory through configuration.

- Set an environment variable: `CONTENT_DIR=../blog-content`
- **For config and data:** Write a Vite plugin in `astro.config.ts` that intercepts imports (e.g., `import config from 'virtual:config'`) and returns the file from `CONTENT_DIR` if it exists, falling back to `blog-code`'s default.
- **For Content Collections:** Utilize the Astro 5+ Loader API to point your `src/content/config.ts` glob paths to `CONTENT_DIR`.
- **For Pages:** Use a catch-all route like `src/pages/[...slug].astro` that reads page layout and content dynamically from `CONTENT_DIR`.

#### 3. Build-time File Sync (The Pragmatic Quick Fix)

Remove all symlinks from Git and restore `blog-code` to its isolated, standalone state with dummy content.

- Create a `bin/sync-content` script that copies everything from `blog-content` into `blog-code/src/`.
- Add paths like `src/navigation.ts`, `src/config.yaml`, and specific `src/pages/*` to your `.gitignore`.
- **Workflow:** When developing or building a specific blog, your script securely overlays the specific content on top of `blog-code`, completing the merge without dirtying the git repo or breaking the standalone state.
