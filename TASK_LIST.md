# Blog Implementation — Task List

> Derived from [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md).  
> Each task is **self-contained**: it defines its goal, the exact changes required, how to verify it, and what `bin/test` should assert after it is done.  
> Tasks build on each other — complete them in order.

---

## T0 — `bin/test` Scaffold ✅

**Goal**: Create a runnable `bin/test` script that grows with every subsequent task. At this stage it only verifies the build succeeds and prints a ✓ for each passing assertion.

### Changes

- **[NEW] `bin/test`** — executable shell script (same style as `bin/deploy`).  
  Initial checks:
  1. Prettier passes (`npm run check:prettier`).
  2. ESLint passes (`npm run check:eslint`).
  3. Astro type-check passes (`npm run check:astro`).
  4. `npm run build` succeeds and `dist/` is non-empty.

### Verification

```bash
chmod +x bin/test
./bin/test
# Expected: all checks green, exit 0
```

### `bin/test` state after this task

```
[T0] ✓ Build succeeds
```

---

## T1 — Access-Level URL Routing

**Goal**: Every post is served at `/{accessLevel}/{slug}` (e.g. `/public/hello-world`, `/friends/my-diary`). Cloudflare Access policies can then protect each prefix path.

### Changes

1. **[MODIFY] `src/content/config.ts`**
   - Change `accessLevel` from a fixed `z.enum(['public','friends','family','private'])` to `z.string().default('private')`, so any YAML-defined level is accepted.

2. **[NEW] `access-list.yaml`** (project root)
   - Defines custom access levels and their allowed email lists:
     ```yaml
     friends:
       - friend1@example.com
     family:
       - member1@example.com
     personal:
       - me@example.com
     ```
   - `public` and `auth` are built-in; any other level must appear here.

3. **[MODIFY] `src/utils/blog.ts`** (or wherever `getStaticPaths` / permalink helpers live)
   - Prepend `accessLevel` to post slugs: `/{accessLevel}/{slug}`.
   - Load `access-list.yaml` at build time; skip posts whose `accessLevel` is not `public`, `auth`, or a key in the YAML.

4. **[NEW] `src/pages/[access]/[...slug].astro`**
   - Dynamic route; renders post detail page.
   - At the top of `getStaticPaths`, assert `params.access === post.data.accessLevel`; throw if mismatched (defence-in-depth).
   - Replaces (or supplements) the existing flat post detail page.

5. **[MODIFY] `bin/deploy`**
   - After build, add assertion: no post whose `accessLevel` is **not** `public` appears under `dist/public/`.

### Verification

```bash
npm run build
# 1. Check URL structure
find dist -name '*.html' | grep -v '/public/' | head -20
# Should show paths like dist/friends/…, dist/family/…

# 2. Check no private content under dist/public/
ls dist/public/ 2>/dev/null   # should only contain genuinely public posts
```

### `bin/test` additions (append to script)

```bash
# [T1] Access-level URL structure
assert_no_private_under_public() {
  if grep -rl 'accessLevel.*private\|accessLevel.*friends\|accessLevel.*family' dist/public/ 2>/dev/null; then
    fail "Private/restricted post metadata found under dist/public/"
    exit 1
  fi
  pass "No restricted content under dist/public/"
}
assert_no_private_under_public
```

---

## T2 — Search Data Privacy

**Goal**: The static search index baked into the HTML/JSON must contain **only** metadata for `public` posts. Restricted post titles, excerpts, and slugs must not be visible to unauthenticated visitors.

### Changes

1. **[MODIFY] `src/components/common/Search.astro`**
   - Filter the post list passed to the search index to `accessLevel === 'public'` only.
   - Add a comment documenting the limitation: authenticated users will not find their restricted posts via search (acceptable for now).

2. **[MODIFY] docs** (e.g. `docs/search.md` or inline comment)
   - Document the limitation and the future improvement path (per-access-level JSON index protected by CF Access).
   - Document the **image privacy caveat**: images in `dist/` are served as static assets without CF Access protection; authors should not embed sensitive images in restricted posts.

### Verification

```bash
npm run build

# 1. No restricted-level titles/excerpts in the built search index
grep -r '"accessLevel":"friends"' dist/   # → 0 results
grep -r '"accessLevel":"family"' dist/    # → 0 results
grep -r '"accessLevel":"private"' dist/   # → 0 results
```

### `bin/test` additions

```bash
# [T2] Search data privacy
for level in friends family private personal; do
  if grep -rq "\"accessLevel\":\"$level\"" dist/ 2>/dev/null; then
    fail "Restricted metadata (level=$level) found in dist/ — search data leak!"
    exit 1
  fi
done
pass "Search index contains no restricted-level metadata"
```

---

## T3 — Draft Post Exclusion (Explicit Verification)

**Goal**: Confirm that posts with `draft: true` in frontmatter are **completely absent** from the built output. Currently this relies on Astro's default behaviour; this task makes it an explicit, tested guarantee.

### Changes

1. **[MODIFY] `bin/deploy`**
   - After build, assert the draft-post count: parse `src/data/post/**/*.md` for `draft: true`, then verify none of those slugs appear in `dist/`.

2. **[MODIFY] `bin/test`**
   - Add the same draft-exclusion assertion (extracted as a shared shell function so both scripts can call it).

3. **[NEW] `tests/fixtures/draft-post.md`** (optional test fixture, in `src/data/post/` with a recognisable slug like `_test-draft`)
   - A post with `draft: true` used only for test validation; excluded from real deploys via `.gitignore` or a `draft: true` guard.

### Verification

```bash
./bin/test
# Expected: "Draft posts excluded from dist/ ✓"

# Manual spot-check:
ls dist/ | grep "_test-draft"   # → no output
```

### `bin/test` additions

```bash
# [T3] Draft exclusion
DRAFT_SLUGS=$(grep -rl 'draft: true' src/data/post/ | sed 's|.*/||; s|\.mdx\?||')
for slug in $DRAFT_SLUGS; do
  if find dist -name "${slug}.html" | grep -q .; then
    fail "Draft post '$slug' found in dist/"
    exit 1
  fi
done
pass "All draft posts excluded from dist/"
```

---

## T4 — Giscus Comments

**Goal**: A Giscus comment widget appears at the bottom of every blog post. Configuration is supplied via environment variables.

### Changes

1. **[NEW] `src/components/blog/Comments.astro`**
   - Renders the Giscus `<script>` tag using env vars:  
     `PUBLIC_GISCUS_REPO`, `PUBLIC_GISCUS_REPO_ID`, `PUBLIC_GISCUS_CATEGORY`, `PUBLIC_GISCUS_CATEGORY_ID`.
   - Renders nothing (no `<script>`) if `PUBLIC_GISCUS_REPO` is unset, so the build never breaks in CI.

2. **[MODIFY] post detail layout** (`src/layouts/PageLayout.astro` or `src/pages/[access]/[...slug].astro`)
   - Import and render `<Comments />` below post body.

3. **[MODIFY] `README.md` / `docs/comments.md`**
   - Document the required env vars and how to obtain Giscus IDs from https://giscus.app/.

4. **[MODIFY] `.env.example`** (create if missing)
   - Add `PUBLIC_GISCUS_REPO=`, `PUBLIC_GISCUS_REPO_ID=`, `PUBLIC_GISCUS_CATEGORY=`, `PUBLIC_GISCUS_CATEGORY_ID=`.

### Verification

```bash
npm run build
# Check the script tag is present in a public post's HTML
grep -r 'giscus' dist/public/*/index.html | head -5
# → should show giscus.app script references
```

### `bin/test` additions

```bash
# [T4] Giscus widget present in public posts
if ls dist/public/*/index.html 1>/dev/null 2>&1; then
  SAMPLE=$(ls dist/public/*/index.html | head -1)
  if grep -q 'giscus' "$SAMPLE" 2>/dev/null; then
    pass "Giscus widget present in public post HTML"
  else
    warn "Giscus widget not found in $SAMPLE (env vars may not be set)"
  fi
fi
```

---

## T5 — Client-Side Translation

**Goal**: A "Translate this page" button (opt-in, no tracking by default) appears on every page, enabling browser-side translation.

### Changes

1. **[NEW] `src/components/common/Translate.astro`**
   - Renders a button that, on click, redirects to `https://translate.google.com/translate?u=<currentURL>` in a new tab **or** injects the Google Translate iframe widget client-side.
   - Preferred minimal approach: remove `<meta name="google" content="notranslate">` (if present) and add a `<div id="google_translate_element">` + init script, so the browser's built-in translate bar can trigger automatically. Document both options in a comment.

2. **[MODIFY] `src/layouts/PageLayout.astro`**
   - Add `<Translate />` in the header or footer area.

3. **[NEW/MODIFY] `docs/translation.md`**
   - Explain the implementation choice and privacy implications.

### Verification

```bash
npm run build
grep -r 'translate' dist/public/*/index.html | head -5
# → should show translate element or redirect link
```

### `bin/test` additions

```bash
# [T5] Translation element present
if ls dist/public/*/index.html 1>/dev/null 2>&1; then
  SAMPLE=$(ls dist/public/*/index.html | head -1)
  if grep -qi 'translate' "$SAMPLE"; then
    pass "Translation element present in public post HTML"
  else
    warn "Translation element not found in $SAMPLE"
  fi
fi
```

---

## T6 — VSCode Image Paste Support

**Goal**: Authors can paste images into VSCode while editing Markdown in `blog-content`. The deploy pipeline copies `images/` → Astro `src/assets/`, rewrites Markdown image paths, and optionally compresses images — without modifying source files.

### Changes

1. **[MODIFY] `.vscode/settings.json`**
   - Add `"markdown.copyFiles.destination"` → `{"**/*.md": "images/${documentBaseName}/"}` so pastes land in `images/<post-name>/`.

2. **[MODIFY] `bin/deploy`** (pre-build step)
   - If `BLOG_CONTENT_DIR` is set and contains an `images/` directory:
     1. `rsync -a "$BLOG_CONTENT_DIR/images/" src/assets/images/`
     2. For each copied Markdown file, rewrite `![...]( images/` → `![..](../assets/images/` **in the temporary build copy only**, not in the source.

3. **[NEW] `docs/vscode-images.md`**
   - Step-by-step workflow for pasting images in VSCode.

### Verification

```bash
# Place a test image at images/test-post/sample.png and reference it in a test post
# Then run:
npm run build
ls dist/_astro/ | grep 'sample'   # → Astro-optimised image file should exist
```

### `bin/test` additions

```bash
# [T6] Image asset pipeline (only if images/ directory exists)
if [[ -d images ]]; then
  IMAGE_COUNT=$(find images -name '*.png' -o -name '*.jpg' -o -name '*.webp' | wc -l)
  ASSET_COUNT=$(find dist/_astro -name '*.webp' 2>/dev/null | wc -l)
  if [[ $IMAGE_COUNT -gt 0 && $ASSET_COUNT -eq 0 ]]; then
    fail "images/ directory has files but none appeared in dist/_astro/"
    exit 1
  fi
  pass "Image assets present in dist/_astro/"
fi
```

---

## T7 — Cloudflare Access Infrastructure

**Goal**: CF Access policies can be created and updated via CLI/Terraform — no GUI required. One policy per access level. The email lists come from `access-list.yaml`.

### Changes

1. **[NEW] `infra/access-list.yaml`**
   - Canonical email list (same structure as the root `access-list.yaml` from T1; symlink or copy during build).

2. **[NEW] `infra/cloudflare-access.sh`**
   - Bash script using `wrangler` and/or `curl` against the Cloudflare API to:
     - Create/update CF Access Application bound to the domain.
     - Create/update one Access Policy per level in `access-list.yaml`: `/friends/*` → friends email list, etc.
     - `/auth/*` → "any authenticated user" policy.
     - `/public/*` → bypass policy (no auth required).
   - Reads `CF_API_TOKEN`, `CF_ACCOUNT_ID`, `CF_ZONE_ID` from environment.

3. **[NEW] `docs/cloudflare-access.md`** (update existing)
   - Full CLI setup walkthrough.
   - Note the **BEWARE** from ARCHITECTURE.md: CF only protects paths listed in a policy; verify alternate access paths are blocked.

4. **[MODIFY] `.env.example`**
   - Add `CF_API_TOKEN=`, `CF_ACCOUNT_ID=`, `CF_ZONE_ID=`, `CLOUDFLARE_PROJECT_NAME=`.

### Verification

```bash
# Dry-run (prints API calls without executing):
DRY_RUN=1 ./infra/cloudflare-access.sh

# After real run, verify via CF API:
curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/access/apps" \
  | jq '.result[].name'
```

### `bin/test` additions

```bash
# [T7] Cloudflare infra script syntax check
if [[ -f infra/cloudflare-access.sh ]]; then
  bash -n infra/cloudflare-access.sh && pass "infra/cloudflare-access.sh syntax OK" \
    || { fail "infra/cloudflare-access.sh syntax error"; exit 1; }
fi
```

---

## T8 — Documentation Blog Posts

**Goal**: Setup and feature documentation is published as blog posts (in `blog-content`) so readers can find it directly on the blog, with an overview post linking all others.

### Changes

Create the following posts in `src/data/post/docs/` (or instruct in docs to place them in `blog-content`):

| File                     | Slug                  | Topic |
| ------------------------ | --------------------- | ----- |
| `docs/overview.md`       | `docs-overview`       | blog  |
| `docs/installation.md`   | `docs-installation`   | blog  |
| `docs/authentication.md` | `docs-authentication` | blog  |
| `docs/comments.md`       | `docs-comments`       | blog  |
| `docs/search.md`         | `docs-search`         | blog  |
| `docs/translation.md`    | `docs-translation`    | blog  |
| `docs/vscode-images.md`  | `docs-vscode-images`  | blog  |

All doc posts:

- `accessLevel: public`
- `draft: false`
- `topic: blog`
- Link to each other from `overview.md`.

### Verification

```bash
npm run build
ls dist/public/docs-*/
# → 7 doc post directories
grep 'docs-overview' dist/public/docs-overview/index.html
```

### `bin/test` additions

```bash
# [T8] Documentation posts exist in dist
DOC_SLUGS=("docs-overview" "docs-installation" "docs-authentication" "docs-comments" "docs-search" "docs-translation")
MISSING=0
for slug in "${DOC_SLUGS[@]}"; do
  if [[ ! -f "dist/public/${slug}/index.html" ]]; then
    warn "Doc post missing from dist: $slug"
    MISSING=$((MISSING + 1))
  fi
done
[[ $MISSING -eq 0 ]] && pass "All documentation posts present in dist/" \
  || { fail "$MISSING documentation posts missing"; exit 1; }
```

---

## Summary Table

| Task | Feature                    | `bin/test` assertion added                 |
| ---- | -------------------------- | ------------------------------------------ |
| T0   | `bin/test` scaffold        | Build succeeds                             |
| T1   | Access-level URL routing   | No restricted content under `dist/public/` |
| T2   | Search data privacy        | No restricted metadata in `dist/`          |
| T3   | Draft exclusion (explicit) | Draft slugs absent from `dist/`            |
| T4   | Giscus comments            | Giscus script in public post HTML          |
| T5   | Client-side translation    | Translate element in public post HTML      |
| T6   | VSCode image paste         | Image assets in `dist/_astro/`             |
| T7   | Cloudflare Access infra    | `infra/cloudflare-access.sh` syntax OK     |
| T8   | Documentation blog posts   | All doc slugs in `dist/public/`            |

> **Rule**: `bin/test` must pass (exit 0) at every task boundary before moving to the next task.
