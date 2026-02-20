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
        const pagesDir = path.join(_dirname, 'pages');

        // Only inject routes if this theme is being used as a dependency, not when running directly
        if (config.root.pathname === fileURLToPath(new URL('..', import.meta.url))) {
          return;
        }

        // Helper to recursively find all Astro/TS/JS pages and inject them
        const injectPages = (dir: string) => {
          const entries = fs.readdirSync(dir, { withFileTypes: true });
          for (const entry of entries) {
            const res = path.resolve(dir, entry.name);
            if (entry.isDirectory()) {
              injectPages(res);
            } else if (entry.name.endsWith('.astro') || entry.name.endsWith('.ts') || entry.name.endsWith('.js')) {
              // Convert absolute path to route pattern string
              let routePattern = res.replace(pagesDir, '').replace(/\\/g, '/');
              // Remove file extension
              routePattern = routePattern.replace(/\.(astro|ts|js)$/, '');
              // Map index -> / or /something/index -> /something
              if (routePattern.endsWith('/index')) {
                routePattern = routePattern.replace('/index', '/') || '/';
              }
              // Map [slug] to /[...slug] or similar based on filename if needed
              // Astro's injectRoute pattern accepts standard Astro routing syntax directly:

              injectRoute({
                pattern: routePattern,
                entrypoint: res,
              });
            }
          }
        };

        injectPages(pagesDir);
      },
    },
  };
}
