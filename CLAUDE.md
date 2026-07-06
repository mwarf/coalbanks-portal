# CLAUDE.md — Coalbanks Creative Client Portal

> Agent instruction file for maintaining the Coalbanks Creative client portal.
> The portal is **built and live** — this file describes the system as it exists.
> Companion docs: `README.md` (setup/deploy), `ADMIN-GUIDE.md` (publishing workflow),
> `PORTAL-CONTENT-SPEC.md` (rules for writing client-facing content — read it before
> authoring any note in `src/content/portal/`).

---

## Project Identity

**Product:** Private per-client project portal for Coalbanks Creative Inc.
**Owner:** Michael Warf (Coalbanks Creative Inc.), Lethbridge, Alberta
**Stack:** Astro 6.x (static) · Cloudflare Pages · Cloudflare Access · GitHub Actions · Obsidian (content source)
**Live domain:** `portal.coalbanks.com`
**Contact email:** `michael@coalbanks.com` (never `.ca`)

Each client gets a private URL path (`/kasko-cattle/`, `/stranville-living/`, …) protected
by a per-client Cloudflare Access application (email one-time PIN, no accounts). The build
is fully static — Access does all authentication at the edge before HTML is served.
This is a branded communication surface, not a CMS, CRM, or file store. Read-only.

---

## Critical: This Repo Is Also the Obsidian Vault

The repo root doubles as Michael's Obsidian vault. The Obsidian Git plugin **auto-commits
and pushes everything in the working tree to `main` on a timer** (commit messages like
`vault: 2026-07-05 18:59:42`), and every push to `main` deploys to production.

Consequences for agents:

- **Code changes you make will be swept into a vault commit and deployed within minutes.**
  Don't leave the tree in a broken state; run `npm run build` before ending a work session.
- Feature-branch/PR workflows don't survive here — by the time you branch, your changes
  are usually already on `main`. Flag this to Michael rather than fighting it.
- Personal notes saved at the vault root are ignored via `.gitignore` (`/*.md` with a
  whitelist for `README.md`, `CLAUDE.md`, `ADMIN-GUIDE.md`, `PORTAL-CONTENT-SPEC.md`).
  Don't add new root-level `.md` docs without extending the whitelist.

---

## Repository Layout (actual)

```
coalbanks-portal/
├── astro.config.mjs               # static output, site URL, R2/Stream image domains,
│                                  # rehype plugin wrapping tables for mobile scroll
├── public/
│   ├── _headers                   # Cloudflare Pages security headers (noindex, DENY framing…)
│   └── logo-coalbanks*.svg, favicon*
├── src/
│   ├── content.config.ts          # portal collection: glob loader + zod schema
│   ├── content/portal/{client}/   # Markdown notes, one folder per client slug
│   ├── lib/
│   │   ├── portal.ts              # getPublishedEntries() + entrySlug() — SAFETY GUARDS
│   │   └── projectTypes.ts        # type labels/order shared across components
│   ├── layouts/
│   │   ├── BaseLayout.astro       # <head>, fonts, skip link, sets .js class on <html>
│   │   └── PortalLayout.astro     # header / breadcrumb / main / footer shell
│   ├── components/                # StatusBadge, TypeBadge, DateStamp, DeliverableCard,
│   │                              # AssetLink, Gallery (lightbox JS), VideoPlayer (CF Stream),
│   │                              # ProjectSummary
│   ├── pages/
│   │   ├── index.astro            # minimal branded landing — names NO clients, links nothing
│   │   ├── 404.astro              # branded 404, same landing style
│   │   └── [client]/
│   │       ├── index.astro        # project overview + dated timeline of notes
│   │       └── [...slug].astro    # individual note pages
│   └── styles/global.css          # all design tokens + component styles (no CSS framework)
└── .github/workflows/deploy.yml   # npm ci → astro build → wrangler pages deploy
```

---

## Content Safety Guards — never weaken these

Three layers keep unpublished or misfiled content off the internet:

1. **Glob pattern** in `src/content.config.ts` is `['**/*.md', '!**/_*']` — underscore-prefixed
   Obsidian drafts are excluded at build time (the legacy content API did this automatically;
   the glob loader does NOT — the exclusion must stay in the pattern). `.gitignore` also
   blocks `src/content/portal/**/_*` as a second layer.
2. **`publish: true` filter** — `getPublishedEntries()` in `src/lib/portal.ts` is the only
   sanctioned way to query the collection. Pages must not call `getCollection('portal')`
   directly.
3. **Client/folder assertion** — `getPublishedEntries()` throws at build time if an entry's
   `client` frontmatter doesn't match its folder. This prevents a copy-paste mistake in
   Obsidian from publishing one client's note under another client's Access-protected path.

If `getStaticPaths` throws, the schema or frontmatter is mismatched — fix content/schema,
don't loosen the guard.

---

## Content Collection Schema

Defined in `src/content.config.ts` (content-layer API, not the legacy `src/content/config.ts`):

- `title` string · `client` string (must equal folder slug) · `publish` boolean (default false)
- `status`: `draft | in-review | delivered | approved`
- `date` coerced date · `type`: `update | deliverable | feedback | brief`
- `asset_links[]`: `{ label, url }` — external links (Drive, Stream, etc.)
- `gallery[]`: `{ src, thumb?, alt, caption? }` — R2-hosted images; first item becomes the hero
- `videos[]`: `{ id, title, poster? }` — Cloudflare Stream UIDs, rendered as iframes

Full authoring rules, tone, and examples live in `PORTAL-CONTENT-SPEC.md`.
Helper scripts `upload-video.sh` / `upload-gallery.sh` push media to Stream/R2.

---

## Routing

- `/` — branded landing card. Public (Access only protects `/{client}/*`), so it must never
  name clients, link to portals, or leak anything. Same rule for `404.astro`.
- `/{client}/` — overview: ProjectSummary stats, optional index.md body, dated timeline
  of all other published notes (DeliverableCards, newest first).
- `/{client}/{slug}/` — note page: asset links, videos, Markdown body, gallery.
- Both dynamic routes get entries via `getPublishedEntries()` and derive slugs with
  `entrySlug()` (strips the `{client}/` prefix from the entry id).

---

## Design System — Prairie Cinematic

Do not invent a new design language. All tokens and component styles live in
`src/styles/global.css`. Key tokens:

```css
--color-bg: #F9F8F5;  --color-text: #1A1A1A;  --color-mid: #6B6B6B;
--color-accent: #2D2D2D;  --color-rule: #D4C9B0;  --color-surface: #F5F4F0;
--font-heading: 'Space Grotesk', …;  --font-body: 'Inter', …;  --font-mono: 'JetBrains Mono', …;
--radius: 4px;  --max-width: 720px;  --spacing-section: 3rem;
```

Status badge colours — draft `#F5F4F0`/`#6B6B6B`, in-review `#FFF7E6`/`#8B5E00`,
delivered `#E8F4E8`/`#2D6A2D`, approved `#E8F0FF`/`#1A3A8B`.

Layout rules: 720px centred content column; header = wordmark left, mailto right;
footer = © left, client name right; mobile breakpoint 768px, single column.
Fonts load from Google Fonts in `BaseLayout.astro` (preload + noscript fallback).

Conventions that must survive edits:

- **Progressive enhancement:** `BaseLayout` sets a `js` class on `<html>` via inline script.
  Any style that hides content until a script reveals it (e.g. `.gallery__reveal`) must be
  scoped under `.js` so blocked/failed scripts never blank out content.
- **Reduced motion:** the `@media (prefers-reduced-motion: reduce)` block at the end of
  `global.css` zeroes animations/transitions. New animations must respect it.
- Client-side JS is limited to the gallery lightbox/reveal — keep it that way unless
  strictly necessary.

---

## Deployment & Security

- Push to `main` → `.github/workflows/deploy.yml` → `wrangler pages deploy dist/`
  (project `coalbanks-portal`; secrets `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID`).
  Save-to-live is ~5–7 minutes via the Obsidian auto-commit cycle.
- `public/_headers` sets `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy: same-origin`,
  `X-Robots-Tag: noindex`, and a restrictive `Permissions-Policy` on all routes. Pages are
  also `noindex` via meta tag.
- Cloudflare Access: one self-hosted Zero Trust application per client covering
  `portal.coalbanks.com/{client-slug}/*`, policy = client emails, one-time PIN login,
  7-day sessions. Configured manually in the Cloudflare dashboard (see `README.md`);
  adding a new client folder requires adding a matching Access application.

---

## Build & Validation

```bash
npm install
npm run dev          # localhost:4321
npm run build        # static build to dist/ — must pass with zero errors
npm run preview      # serve dist/ locally
```

Node ≥ 22.12. Always confirm `npm run build` succeeds before ending a session —
whatever is in the tree will auto-deploy.

---

## What Not to Build

- No authentication UI (Cloudflare Access owns login)
- No database, API routes, or SSR — output stays `static`
- No file upload, comments, CMS admin, or analytics
- Nothing on `/` or the 404 page that names or links to clients
- No new client-side JS beyond the existing gallery interactions

---

*Coalbanks Creative Inc. — Lethbridge, Alberta — coalbanks.com*
