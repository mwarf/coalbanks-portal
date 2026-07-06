import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const portal = defineCollection({
  // Underscore-prefixed notes are Obsidian drafts — excluded here so they never
  // build, even if they slip past .gitignore. (.mdx dropped: no MDX integration.)
  loader: glob({ pattern: ['**/*.md', '!**/_*'], base: './src/content/portal' }),
  schema: z.object({
    title:       z.string(),
    client:      z.string(),                          // matches URL slug
    publish:     z.boolean().default(false),           // false = never built
    status:      z.enum(['draft', 'in-review', 'delivered', 'approved']),
    date:        z.coerce.date(),
    type:        z.enum(['update', 'deliverable', 'feedback', 'brief']),
    asset_links: z.array(z.object({
      label: z.string(),
      url:   z.string().url(),
    })).optional(),
    gallery: z.array(z.object({
      src:     z.string().url(),
      thumb:   z.string().url().optional(),
      alt:     z.string(),
      caption: z.string().optional(),
    })).optional(),
    videos: z.array(z.object({
      id:      z.string(),                              // Cloudflare Stream video UID
      title:   z.string(),
      poster:  z.string().url().optional(),             // custom poster image URL
    })).optional(),
  }),
});

export const collections = { portal };
