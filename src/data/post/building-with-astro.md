---
publishDate: 2026-02-16
title: 'Building Modern Web Apps with Astro'
excerpt: 'Exploring Astro 5.0, the modern static site generator that ships zero JavaScript by default while supporting your favorite frameworks'
topic: 'software'
tags: ['astro', 'web-development', 'javascript', 'static-sites']
draft: false
accessLevel: 'public'
---

# Building Modern Web Apps with Astro

[Astro](https://astro.build/) is revolutionizing how we build content-focused websites. It's a modern static site generator that delivers fast, SEO-friendly sites with minimal JavaScript.

## Why Astro?

### Zero JavaScript by Default
Astro's core philosophy is **"ship less JavaScript."** Unlike traditional frameworks that hydrate everything client-side, Astro only adds interactivity where you explicitly request it.

```javascript
// Traditional React - Everything hydrates
export default function MyPage() {
  return (
    <div>
      <Header />
      <MainContent />
      <Footer />
    </div>
  );
}

// Astro - Only interactive components hydrate
---
import Header from './Header.astro';
import InteractiveWidget from './InteractiveWidget.jsx';
import Footer from './Footer.astro';
---

<Header />
<InteractiveWidget client:load />
<Footer />
```

### Framework Agnostic
Mix and match frameworks in the same project:
- React for complex interactions
- Vue for specific components
- Svelte for animations
- Vanilla JS for simple stuff

### Content Collections
Astro 5.0 introduces powerful content management:

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  schema: z.object({
    title: z.string(),
    publishDate: z.date(),
    topic: z.enum(['blog', 'modelrailroad', 'software']),
    tags: z.array(z.string()),
  }),
});

export const collections = { blog };
```

## Island Architecture

Astro pioneered the **Islands Architecture** pattern. Think of your page as a sea of static HTML with interactive "islands" of JavaScript:

- **Static by default**: HTML/CSS rendered at build time
- **Interactive islands**: Components that need JavaScript (search, image carousel, etc.)
- **Partial hydration**: Only islands load JavaScript, not the entire page

## Performance Benefits

Real metrics from this blog:

- **Lighthouse Score**: 100/100 across all categories
- **First Contentful Paint**: < 0.5s
- **Total Blocking Time**: 0ms (no JavaScript blocking render)
- **Bundle Size**: ~10KB for most pages (vs 200KB+ for typical SPA)

## Astro + Tailwind CSS

This blog combines Astro with Tailwind CSS for styling:

```astro
---
// Component script
const { title } = Astro.props;
---

<article class="prose lg:prose-xl dark:prose-invert">
  <h1 class="text-4xl font-bold text-gray-900 dark:text-white">
    {title}
  </h1>
  <slot />
</article>
```

## MDX Support

Write Markdown with JSX components:

```mdx
import { Chart } from './Chart.jsx';

# My Article

Here's some regular markdown content.

<Chart data={myData} client:visible />

More markdown here...
```

## When to Use Astro

**Perfect for:**
- Blogs and documentation sites
- Marketing/landing pages
- E-commerce product pages
- Content-heavy sites

**Maybe not ideal for:**
- Highly interactive web apps (use Next.js, SvelteKit)
- Real-time collaborative tools
- Complex admin dashboards

## This Blog's Stack

This very blog you're reading uses:

- **Astro 5.12**: Core framework
- **Tailwind CSS**: Styling
- **KaTeX**: Math equation rendering
- **MDX**: Enhanced markdown
- **TypeScript**: Type safety

Check out the [GitHub repo](https://github.com/yourusername/blog) for the full implementation.

## Conclusion

Astro brings the best of static site generation and modern web development together. If you're building a content-focused site and care about performance, give Astro a try.

*Next up: Deploying Astro sites to Cloudflare Pages with authentication.*
