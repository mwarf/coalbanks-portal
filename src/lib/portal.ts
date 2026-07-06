import { getCollection } from 'astro:content';
import type { CollectionEntry } from 'astro:content';

/**
 * Published portal entries, validated so a note whose `client` frontmatter
 * doesn't match its folder fails the build instead of publishing under
 * another client's Cloudflare Access path.
 */
export async function getPublishedEntries(): Promise<CollectionEntry<'portal'>[]> {
  const entries = await getCollection('portal', (e) => e.data.publish === true);

  for (const e of entries) {
    if (e.id !== e.data.client && !e.id.startsWith(e.data.client + '/')) {
      throw new Error(
        `Portal entry "${e.id}" declares client "${e.data.client}" but lives outside that client's folder. ` +
        `Fix the frontmatter or move the file — publishing it would expose it under the wrong client's URL.`
      );
    }
  }

  return entries;
}

/** Entry slug relative to its client folder, e.g. "stranville-living/production-update" → "production-update". */
export function entrySlug(entry: { id: string; data: { client: string } }): string {
  return entry.id.replace(entry.data.client + '/', '');
}
