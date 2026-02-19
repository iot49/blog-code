# Blogging Website

Blogging website based on free AstroWind Lite theme. Static site, served via Cloudflare pages. Code, data, and comments are in separate github repositories:

1. blog-code: the source code
2. blog-content: content, **This repo is private**
3. blog-comments: comments

Setup and configuration on Cloudflare are entirely via CLI/Terraform, no GUI needed (except for getting CF token and ID).

**Features:**

- Served under custom domain, e.g. https://example.com, configurable with environment variable
- Content stored in `blog-content` (private github repo), configurable with environment variable
- File types:
  - .md, .mdx, .ipynb files
  - .ipynb files are converted serverside and show the notebook and output created by the author. Notebooks are not executed during rendering, and live execution in the browser is not supported.
- Translation: support for client-side (in the browser) translation
- Authorizstion:
  - Handled by Cloudflare Application framework
  - Authentication is handled by Cloudflare, OTC and github are supported as providers (others can be added as needed). Authentication is valid for a specified period (e.g. 14 or 30 days) after which re-authentication is required, configurable with an environment variable.
  - Access to blogs is specified in the front-matter of each blog in variable `access`.
  - Supported values for `access`:
    - `public`: post visible without authentication (default)
    - `auth`: visible for all authenticated viewers
    - access to all others is via an access list specified in a yaml file mapping `access` to emails, e.g.

    ```yaml
    friends:
      - friend1@gmail.com
      - friend2@microsoft.com
    personal:
      - me@gmail.com
    family:
      - member1@gmail.com
      - member2@gmail.com
      - member3@hotmail.com
    ```

    - Implementation is based on Cloudflare Access policies:
      - posts are served at URLs containing their `access` level, e.g.
        ```
        /.../public/*
        /.../auth/*
        /.../friends/*
        /.../personal/*
        /.../family/*
        ```
      - Each path is protected by a Cloudflare Access policy.
    - **BEWARE**: CF only protects path listed in an access policy. **Verify** that access is protected also if the site (e.g. for testing) is served under different URLs. If this cannot be ensured, remove such alternate access paths.

  - Vscode: support for pasting images into blogs and automatically creating links.
    - **Note:** Vscode places images into an `image/` subfolder. Astro expects them in the `assets/` folder. Deployment handles the translation (and also image compression) without modifying the source (blog-content).
  - Comments: based on [Giscus](https://giscus.app/). Comments are stored in github repo `blog-comments` (configurable by environment variable).
  - Search:
    - Free for search for tags and text
  - Deployment: scripts in bin/ folder for:
    - `deploy`: build locally, comprehensive error detection and reporting to the user (do not deploy if errors detected), upload to Cloudflare.
      - **Note:** deploying is independend of pushing to github. Specifically, blog content may be stored exclusively locally; the `blog-content` github repo is optional.
      - blogs marked as `draft` in the front-matter are not deployed
    - `preview`: run local preview server
    - `check-link`: checks external links of blogs. Run this sporadically only to avoid rate limits.
    - `test`: run entire test suite
    - For convenience the bin folder is mirrored in `blog-content`
  - Testing: comprehensive testing of
    - no access to posts the user is not authorized for
    - access to all posts the user is authorized for
    - all features including search, translation, comments, etc.
  - Documentation:
    - Formatted as a blog consisting of separates posts including an overview with links to other posts describing the individual features (installation/deployment, authentication, comments, search, translation, etc)
