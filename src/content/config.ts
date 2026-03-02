import { z, defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';

const metadataDefinition = () =>
  z
    .object({
      title: z.string().optional(),
      ignoreTitleTemplate: z.boolean().optional(),

      canonical: z.string().url().optional(),

      robots: z
        .object({
          index: z.boolean().optional(),
          follow: z.boolean().optional(),
        })
        .optional(),

      description: z.string().optional(),

      openGraph: z
        .object({
          url: z.string().optional(),
          siteName: z.string().optional(),
          images: z
            .array(
              z.object({
                url: z.string(),
                width: z.number().optional(),
                height: z.number().optional(),
              })
            )
            .optional(),
          locale: z.string().optional(),
          type: z.string().optional(),
        })
        .optional(),

      twitter: z
        .object({
          handle: z.string().optional(),
          site: z.string().optional(),
          cardType: z.string().optional(),
        })
        .optional(),
    })
    .optional();

// Resolve the content directory dynamically. 
// If CONTENT_DIR is provided, use it. Otherwise, assume we're running from the project root (e.g. blog-content or a standalone setup).
const defaultContentDir = './src/data/post';
// Using import.meta.env for Astro environment var access if defined, else fallback to default
const baseDir = (import.meta.env && import.meta.env.CONTENT_DIR) || defaultContentDir;

const postCollection = defineCollection({
  loader: glob({ pattern: ['**/*.md', '**/*.mdx'], base: baseDir }),
  schema: ({ image }) =>
    z.object({
      publishDate: z.date().optional(),
      updateDate: z.date().optional(),
      draft: z.boolean().default(true), // Default to draft for security

      title: z.string(),
      excerpt: z.string().optional(),
      image: image().optional(),

      // Topic organization
      topic: z.enum(['blog', 'modelrailroad', 'software']).default('blog'),

      category: z.string().optional(),
      tags: z.array(z.string()).default([]),
      author: z.string().default('John Dummy'),

      // Access control - default to most restrictive
      accessLevel: z.string().default('private'),

      // Pinned status
      pinned: z.boolean().default(false),

      // Language support
      language: z.string().default('en'),

      metadata: metadataDefinition(),
    }),
});

export const collections = {
  post: postCollection,
};
