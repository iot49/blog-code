# Missing Features — Implementation Plan

Based on a thorough audit of `ARCHITECTURE.md` and the current codebase, the following features are either entirely missing or only partially implemented.

---

## Gap Summary

| #   | Feature                                                     | Status                                                   |
| --- | ----------------------------------------------------------- | -------------------------------------------------------- |
| F1  | Access-level URL routing (`/public/*`, `/friends/*` …)      | ❌ Missing                                               |
| F2  | Search data privacy (only show posts the viewer can access) | ⚠️ Broken — leaks all metadata                           |
| F3  | Client-side translation                                     | ❌ Missing                                               |
| F4  | Giscus comments                                             | ❌ Missing                                               |
| F5  | VSCode image paste support (`image/` → `assets/` mapping)   | ❌ Missing                                               |
| F6  | Test suite (`bin/test`)                                     | ❌ Missing                                               |
| F7  | `bin/test` script                                           | ❌ Missing                                               |
| F8  | Draft filtering in deploy                                   | ⚠️ Relies on Astro default — needs explicit verification |
| F9  | Cloudflare Access Terraform/CLI setup                       | ❌ Missing (docs only)                                   |
| F10 | Documentation-as-blog posts                                 | ❌ Missing                                               |

---

## Proposed Changes

### F1 — Access-Level URL Routing

> [!IMPORTANT]
> This is the most security-critical feature. Without it, Cloudflare Access policies cannot protect posts by access level.

#### [NEW] access-list.yaml (in blog-content repo or project root)

- Defines supported access levels and the email lists for each, e.g.:
  ```yaml
  friends:
    - friend1@gmail.com
  family:
    - member1@gmail.com
  ```
- This file is the single source of truth. Any `accessLevel` value in a post's frontmatter that does **not** appear as a key in this YAML (and is not `public` or `auth`) makes that post inaccessible.

#### [MODIFY] [src/content/config.ts](file:///Users/boser/Documents/personal/iot/blog-code/src/content/config.ts)

- Keep `accessLevel: z.string().default('private')` (open string, not a fixed enum) so it can accept any key from the YAML config. Posts whose `accessLevel` is not in the YAML and is not `public`/`auth` are treated as inaccessible (no route generated).

#### [MODIFY] [src/utils/blog.ts](file:///Users/boser/Documents/personal/iot/blog-code/src/utils/blog.ts)

- Update `getStaticPathsBlogList` and post permalink generation to embed `accessLevel` in the URL: `/{accessLevel}/{slug}`.

#### [NEW] src/pages/[access]/[...blog]/[slug].astro

- Dynamic route `[access]` captures the access level segment; validates it matches post frontmatter `accessLevel`.
- Replaces or supplements the current `[...blog]/[...page].astro`.

#### [MODIFY] bin/deploy

- After build, verify no `private` or `friends` HTML lands under a `public/` path in `dist/`.

---

### F2 — Search Data Privacy

> [!WARNING]
> Currently `Search.astro` bakes **all** post titles, excerpts, and permalinks into the HTML delivered to every visitor (including unauthenticated users). Private post metadata is leaked. An _excerpt_ is the short summary text from the `excerpt` frontmatter field — its content may reveal private information.
>
> **Images are NOT protected** by this approach: image files are served as static assets without Cloudflare Access policies, so a direct URL to an image in a private post is publicly reachable. Authors should be warned in the documentation to avoid embedding sensitive images in restricted posts.

#### [MODIFY] [src/components/common/Search.astro](file:///Users/boser/Documents/personal/iot/blog-code/src/components/common/Search.astro)

- Filter `fetchPosts()` to only include `public` posts in the static search index.
- **Limitation (document this)**: Authenticated users (friends, family, etc.) will not see their non-public posts in search results. A future improvement could serve per-access-level JSON search indexes protected by Cloudflare Access policies, but this is out of scope for now.

---

### F3 — Client-Side Translation

#### [NEW] src/components/common/Translate.astro

- Embed a "Translate this page" button that loads the [Google Translate](https://translate.google.com/translate_a) widget client-side (no server-side work, privacy-respecting opt-in).
- Alternatively use the browser's built-in translation prompt via `<meta name="google" content="notranslate">` absence.

#### [MODIFY] src/layouts/PageLayout.astro

- Add `<Translate />` component into the page layout.

---

### F4 — Giscus Comments

#### [NEW] src/components/blog/Comments.astro

- Implements [Giscus](https://giscus.app/) via the `<script src="https://giscus.app/client.js" ...>` snippet.
- Props: `repo`, `repoId`, `category`, `categoryId` — all configurable via environment variables.
- Only renders when the post's `accessLevel` is accessible to the current viewer (i.e., always render on public posts; Cloudflare Access protects restricted ones at the network level).

#### [MODIFY] src/layouts/PageLayout.astro (or post detail layout)

- Add `<Comments />` below post content.

#### [MODIFY] astro.config.ts / environment

- Document required env vars: `PUBLIC_GISCUS_REPO`, `PUBLIC_GISCUS_REPO_ID`, `PUBLIC_GISCUS_CATEGORY`, `PUBLIC_GISCUS_CATEGORY_ID`.

---

### F5 — VSCode Image Paste Support

#### [NEW] .vscode/settings.json additions

- Set `"markdown.copyFiles.destination"` to map pastes into `images/` (VSCode default) inside the blog-content repo.

#### [MODIFY] bin/deploy

- Before `npm run build`, run a preprocessing step that:
  1. Copies `images/` → `src/assets/` (or the correct Astro asset path).
  2. Optionally compresses images with `sharp` or `squoosh`.
  3. Rewrites `![...](images/foo.png)` → `![...](../assets/foo.png)` in copied Markdown files, **without modifying blog-content source files**.

---

### F6 & F7 — Test Suite + `bin/test` Script

#### [NEW] bin/test

- Shell script (like `bin/deploy`) that runs:
  1. **Unit/build tests**: `npm run build` passes.
  2. **Access enforcement tests**: After `npm run build`, walk `dist/` and assert:
     - Posts with `accessLevel: private` are not reachable under `dist/public/`.
     - No private post data appears in `dist/public/search-index.json`.
  3. **Link integrity**: Re-use `bin/check-links` logic.
  4. **Draft exclusion**: Assert no post with `draft: true` appears in `dist/`.

#### [NEW] tests/ directory (optional Playwright or Node scripts)

- End-to-end browser tests for:
  - Search returns results only for public posts when not authenticated.
  - Comment widget renders on public posts.
  - Translation button appears and triggers Google Translate.

---

### F8 — Draft Filtering Verification

#### [MODIFY] bin/deploy

- After build, add an explicit assertion: `grep -r 'draft: true' dist/` should return nothing sensitively exposed, or more robustly: check that the number of HTML files in `dist/` matches the number of non-draft posts.

---

### F9 — Cloudflare Access Terraform/CLI Setup

#### [NEW] infra/cloudflare.tf (or infra/cloudflare-access.sh)

- Terraform or `wrangler`/`cf-cli` script to:
  - Create Cloudflare Access Application for the blog.
  - Create one Access Policy per access level:
    - `/auth/*` → any authenticated user
    - `/friends/*` → email list
    - `/family/*` → email list
    - `/personal/*` → owner email
  - Bind the email-to-access-level YAML file as the source of truth.

#### [NEW] infra/access-list.yaml

- The email access list referenced in ARCHITECTURE.md.

---

### F10 — Documentation Blog Posts

#### [NEW] src/data/post/docs/ (in blog-content repo)

- `docs/overview.md` — Overview with links to all other doc posts.
- `docs/installation.md` — Setup and deployment.
- `docs/authentication.md` — Cloudflare Access setup.
- `docs/comments.md` — Giscus setup.
- `docs/search.md` — Search feature.
- `docs/translation.md` — Translation feature.

---

## Verification Plan

### Automated Tests

```bash
# 1. Run the full deploy pre-flight checks (includes build + lint + type-check)
./bin/deploy --dry-run   # (add a --dry-run flag that skips the wrangler upload)

# 2. Run the new test script
./bin/test

# 3. Search data leak check — after npm run build:
grep -r '"accessLevel":"private"' dist/   # should return nothing
grep -r '"accessLevel":"friends"' dist/   # should return nothing

# 4. Draft exclusion check
node -e "
  const {globSync} = require('glob');
  const fs = require('fs');
  const htmlFiles = globSync('dist/**/*.html');
  // Verify count matches non-draft post count from content collection
  console.log('HTML files in dist:', htmlFiles.length);
"
```

### Manual Verification (after Cloudflare deployment)

1. **Access routing**: Open `https://your-blog.com/friends/some-post` → should redirect to Cloudflare Access login if not authenticated with a friends-level email.
2. **Search privacy**: Open browser DevTools → Network → reload any page → inspect the page HTML: search for titles of `private` posts — they should not appear.
3. **Comments**: Open any public post → scroll to the bottom → Giscus widget should load and allow sign-in via GitHub.
4. **Translation**: Click the translate button → page should translate client-side.
5. **Draft exclusion**: Navigate to the slug of a known `draft: true` post → should return 404.
