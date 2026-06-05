import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const portal = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/portal' }),
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
  }),
});

export const collections = { portal };
