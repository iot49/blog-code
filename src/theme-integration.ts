import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
import type { AstroIntegration } from 'astro';

export default function blogThemeCore(): AstroIntegration {
  return {
    name: 'blog-theme-core',
    hooks: {
      'astro:config:setup': ({ injectRoute, config }) => {
        const _dirname = path.dirname(fileURLToPath(import.meta.url));
        const themePagesDir = path.join(_dirname, 'pages');
        const consumerPagesDir = path.join(fileURLToPath(config.root), 'src', 'pages');

        // Only inject routes if this theme is being used as a dependency, not when running directly
        if (config.root.pathname === fileURLToPath(new URL('..', import.meta.url))) {
          return;
        }

        // Helper to recursively find all Astro/TS/JS pages in the theme and selectively inject them
        const injectPages = (dir: string) => {
          if (!fs.existsSync(dir)) return;

          const entries = fs.readdirSync(dir, { withFileTypes: true });
          for (const entry of entries) {
            const res = path.resolve(dir, entry.name);
            if (entry.isDirectory()) {
              injectPages(res);
            } else if (entry.name.endsWith('.astro') || entry.name.endsWith('.ts') || entry.name.endsWith('.js')) {
              // Convert absolute path to route pattern string
              let routePattern = res.replace(themePagesDir, '').replace(/\\/g, '/');
              // Remove file extension
              routePattern = routePattern.replace(/\.(astro|ts|js)$/, '');
              // Map index -> / or /something/index -> /something
              if (routePattern.endsWith('/index')) {
                routePattern = routePattern.replace('/index', '/') || '/';
              }

              // OPTION 1 MAGIC: Check if the consumer already has this physical file overriding the theme.
              // e.g. If the theme is trying to inject `/about.astro`, check if `blog-content/src/pages/about.astro` exists.
              const relativeFilePath = res.replace(themePagesDir, '');
              const consumerOverridePath = path.join(consumerPagesDir, relativeFilePath);

              if (fs.existsSync(consumerOverridePath)) {
                console.log(
                  `[blog-theme-core] Skipping injection for ${routePattern} because a local override exists at ${relativeFilePath}`
                );
                continue; // Skip injecting because the consumer owns this route
              }

              injectRoute({
                pattern: routePattern,
                entrypoint: res,
              });
            }
          }
        };

        injectPages(themePagesDir);
      },
    },
  };
}
