# CLAUDE.md — Coalbanks Creative Client Portal

> Agent instruction file for building the Coalbanks Creative client portal.
> Read this file in full before touching any code, creating any files, or running any commands.

---

## Project Identity

**Product:** Private per-client project portal for Coalbanks Creative Inc.
**Owner:** Michael Warf (Coalbanks Creative Inc.), Lethbridge, Alberta
**Stack:** Astro 5.x · Cloudflare Pages · Cloudflare Access · GitHub · Obsidian (content source)
**Repo type:** Private GitHub repository
**Target domain:** `portal.coalbanks.ca`
**Full spec:** See `coalbanks-client-portal-prd.docx` in this repo

---

## What You Are Building

A statically-generated, per-client portal. Each client gets a private URL path. Authentication is handled entirely by Cloudflare Access — email magic link only, no accounts, no passwords. Content is authored in Obsidian as Markdown/MDX and synced to this repo. Astro reads a content collection, filters by `publish: true`, and generates clean HTML. The portal is read-only in v1.

This is not a CMS, CRM, or file storage system. It is a branded communication surface.

---

## Repository Structure to Build

```
coalbanks-portal/
├── CLAUDE.md                          ← this file
├── README.md                          ← setup and deployment notes
├── astro.config.mjs
├── package.json
├── tsconfig.json
├── public/
│   ├── coalbanks-logo.svg             ← placeholder SVG if asset not provided
│   └── favicon.svg
├── src/
│   ├── content/
│   │   ├── config.ts                  ← content collection schema
│   │   └── portal/                    ← synced from Obsidian vault
│   │       └── _example/
│   │           └── index.md           ← non-publishing example note
│   ├── pages/
│   │   ├── index.astro                ← 404 redirect (no public index)
│   │   └── [client]/
│   │       ├── index.astro            ← project overview page
│   │       └── [...slug].astro        ← all other published notes
│   ├── layouts/
│   │   └── PortalLayout.astro         ← shared shell: header, nav, footer
│   ├── components/
│   │   ├── StatusBadge.astro          ← pill: draft | in-review | delivered | approved
│   │   ├── DeliverableCard.astro      ← card with title, status, optional link
│   │   └── AssetLink.astro            ← external asset link row
│   └── styles/
│       └── global.css                 ← design tokens and base styles
└── .github/
    └── workflows/
        └── deploy.yml                 ← Cloudflare Pages deploy action (if needed)
```

---

## Content Collection Schema

File: `src/content/config.ts`

```typescript
import { defineCollection, z } from 'astro:content';

const portal = defineCollection({
  type: 'content',
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
```

Notes beginning with `_` (underscore) are never committed to the repo. Notes with `publish: false` are excluded at build time via the `getCollection` filter. Both rules must hold.

---

## Frontmatter Example

```markdown
---
title: "Better Everywhere — Production Update"
client: stranville-living
publish: true
status: in-review
date: 2026-06-05
type: update
asset_links:
  - label: "Rough Cut — Edit 1"
    url: "https://stream.cloudflare.com/..."
  - label: "Script Draft"
    url: "https://drive.google.com/..."
---

Update body in Markdown here.
```

---

## Dynamic Route Logic

File: `src/pages/[client]/[...slug].astro`

The `getStaticPaths` function must:

1. Call `getCollection('portal', (e) => e.data.publish === true)` — filter at source, not after
2. Map each entry to `{ params: { client: e.data.client, slug: e.slug.replace(e.data.client + '/', '') }, props: { entry } }`
3. Render via `entry.render()` and pass `entry.data` to the layout

The `src/pages/index.astro` root must return a 404 or redirect — there is no public landing page.

---

## Design System

**Do not invent a new design language.** Implement the Prairie Cinematic system exactly.

### Tokens (set as CSS custom properties in `global.css`)

```css
:root {
  --color-bg:        #F9F8F5;   /* warm off-white page background */
  --color-text:      #1A1A1A;   /* near-black body text */
  --color-mid:       #6B6B6B;   /* secondary text, metadata */
  --color-accent:    #2D2D2D;   /* headings, borders, badges */
  --color-rule:      #D4C9B0;   /* warm parchment horizontal rules */
  --color-surface:   #F5F4F0;   /* card and code block backgrounds */
  --color-white:     #FFFFFF;

  --font-heading:    'Space Grotesk', system-ui, sans-serif;
  --font-body:       'Inter', system-ui, sans-serif;
  --font-mono:       'JetBrains Mono', 'Fira Code', monospace;

  --size-base:       1rem;       /* 16px */
  --size-sm:         0.875rem;
  --size-lg:         1.25rem;
  --size-xl:         1.5rem;
  --size-2xl:        2rem;

  --radius:          4px;
  --max-width:       720px;
  --spacing-section: 3rem;
}
```

Load Space Grotesk and Inter from Google Fonts or Bunny Fonts in `PortalLayout.astro`.

### Status Badge Colours

| Status      | Background | Text     |
|-------------|------------|----------|
| draft       | `#F5F4F0`  | `#6B6B6B`|
| in-review   | `#FFF7E6`  | `#8B5E00`|
| delivered   | `#E8F4E8`  | `#2D6A2D`|
| approved    | `#E8F0FF`  | `#1A3A8B`|

### Layout Rules

- Max content width: `720px`, centred
- Header: Coalbanks Creative wordmark left, `mailto:michael@coalbanks.ca` link right
- Footer: `© Coalbanks Creative Inc.` left, project name right, separated by rule
- Mobile breakpoint: `768px` — single column, full-width cards
- No JavaScript unless strictly necessary. Astro default output is static HTML.

---

## PortalLayout.astro — Required Slots and Props

```typescript
interface Props {
  title:      string;   // used in <title> and <h1>
  client:     string;   // used in breadcrumb and back link
  status?:    string;   // passed to StatusBadge if present
  date?:      Date;
}
```

The layout renders:
1. `<head>` with title, meta charset/viewport, font imports, global.css
2. Header (logo + contact link)
3. Breadcrumb: `Projects / [client display name]` — links back to `/{client}/`
4. `<main>` with `<slot />`
5. Footer

---

## StatusBadge Component

```astro
---
interface Props {
  status: 'draft' | 'in-review' | 'delivered' | 'approved';
}
const { status } = Astro.props;
const labels = {
  'draft':     'Draft',
  'in-review': 'In Review',
  'delivered': 'Delivered',
  'approved':  'Approved',
};
---
<span class={`badge badge--${status}`}>{labels[status]}</span>
```

Styles for `.badge` and `.badge--{status}` variants go in `global.css`.

---

## DeliverableCard Component

Renders a card row for each deliverable. Props: `title` (string), `status` (StatusBadge enum), `url` (optional string). If `url` is present, title is a link that opens in a new tab. If absent, title is plain text.

---

## AssetLink Component

Renders the `asset_links` array from frontmatter as a styled list. Each item: external link icon + label + URL. Opens in new tab. Used on update and deliverable pages.

---

## astro.config.mjs

```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  site:   'https://portal.coalbanks.ca',
});
```

No SSR adapter required. This is a fully static build. Cloudflare Access handles all authentication at the edge before requests reach the HTML.

---

## Example Content Note (for testing)

Create `src/content/portal/stranville-living/index.md` with:

```markdown
---
title: "Better Everywhere — Project Overview"
client: stranville-living
publish: true
status: in-review
date: 2026-06-05
type: brief
asset_links:
  - label: "Creative Brief PDF"
    url: "https://example.com/brief.pdf"
---

## Project Summary

Three-video package documenting Stranville Living's presence across Southern Alberta. Covers the Hemsdale show home match-cut concept, community lifestyle coverage, and a brand overview piece.

## Current Status

- Script approved
- Rough cut Edit 1 complete — awaiting feedback
- Final delivery targeted mid-July 2026

## Next Step for You

Please review Edit 1 using the link above and send feedback to michael@coalbanks.ca by June 20.
```

---

## Cloudflare Access Configuration (not automated — document for Michael)

After the site is deployed, generate a setup checklist in `README.md` with these exact steps:

1. Log into Cloudflare dashboard → Zero Trust (sidebar)
2. Create a Zero Trust organization if one does not exist (team name: `coalbanks`)
3. Confirm Free plan is active (50 users included)
4. Access → Applications → Add Application → Self-hosted
5. Application name: `[Client Name] Portal`
6. Application URL: `portal.coalbanks.ca/[client-slug]/*`
7. Session duration: 7 days
8. Authentication → Policies → Add policy → Include → Emails → `[client@email.com]`
9. Login methods: One-time PIN only
10. Save

Add this checklist for each client slug that exists in `src/content/portal/`.

---

## Build and Validation Commands

```bash
npm install
npm run dev          # local dev server
npm run build        # static build to dist/
npm run preview      # preview dist/ locally
```

Confirm the build succeeds with zero errors before considering any phase complete. If `getStaticPaths` throws, the content collection schema or frontmatter is mismatched — fix the schema first.

---

## What Not to Build

- No authentication UI — Cloudflare Access provides the login screen
- No client-side JavaScript beyond what Astro islands require (none needed in v1)
- No database, no API routes, no server-side rendering
- No public index page at `portal.coalbanks.ca/` — return 404
- No file upload or comment functionality
- No CMS admin panel
- No analytics scripts

---

## Phase Completion Checklist

Work through phases in order. Do not proceed to the next phase until the current one is confirmed.

- [ ] **Phase 1 — Foundation:** Repo scaffolded, schema defined, `npm run build` succeeds with example content
- [ ] **Phase 2 — Hosting:** Connected to Cloudflare Pages, push to `main` triggers auto-build, `portal.coalbanks.ca` resolves
- [ ] **Phase 3 — Auth:** Zero Trust org created, one Access application protecting `/stranville-living/*`, magic link flow tested end-to-end
- [ ] **Phase 4 — Design:** Prairie Cinematic tokens applied, all components built, overview page matches spec on desktop and mobile
- [ ] **Phase 5 — Obsidian Integration:** Obsidian Git plugin configured, auto-commit tested, Stranville Living notes live in under 5 minutes from save

---

## Questions Before Starting

If any of the following are unclear, ask before writing code:

1. Is `portal.coalbanks.ca` already added as a custom domain in Cloudflare, or does that need to be set up?
2. Should the Obsidian vault subfolder be a symlink into this repo, or will Obsidian Git push directly to this repo's `src/content/portal/` path?
3. Is a Cloudflare Zero Trust organization already created, or does this need first-time setup?
4. Are Space Grotesk and Inter already self-hosted, or should they be loaded from a CDN?

Do not assume answers. Ask.

---

*Coalbanks Creative Inc. — Lethbridge, Alberta — coalbanks.ca*
