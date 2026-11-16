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

/**
 * Display names for client slugs whose slug is not their name, or whose name
 * cannot be derived from the slug (acronyms, single words). Anything not listed
 * falls back to title-casing the slug, which is what breadcrumbs and footers
 * rendered before this existed.
 */
const CLIENT_NAMES: Record<string, string> = {
  pwc: 'Progressive West Consulting',
};

/** Human-readable client name for breadcrumbs, footers and page chrome. */
export function clientDisplayName(slug: string): string {
  const mapped = CLIENT_NAMES[slug];
  if (mapped) return mapped;
  return slug
    .split('-')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}
