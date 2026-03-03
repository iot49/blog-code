import { z, defineCollection, type ImageFunction } from 'astro:content';
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

export const postSchema = ({ image }: { image: ImageFunction }) =>
  z.object({
    publishDate: z.date().optional(),
    updateDate: z.date().optional(),
    draft: z.boolean().default(true),

    title: z.string(),
    excerpt: z.string().optional(),
    image: image().optional(),

    category: z.string().optional(),
    tags: z.array(z.string()).default([]),
    author: z.string().default('Admin'),

    accessLevel: z.string().default('private'),
    pinned: z.boolean().default(false),
    language: z.string().default('en'),

    metadata: metadataDefinition(),
  });

const defaultContentDir = './src/data/post';
export const baseDir = (import.meta.env && import.meta.env.CONTENT_DIR) || defaultContentDir;

export const postCollection = defineCollection({
  loader: glob({ pattern: ['**/*.md', '**/*.mdx'], base: baseDir }),
  schema: postSchema,
});

export const collections = {
  post: postCollection,
};
