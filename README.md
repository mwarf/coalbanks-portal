# Coalbanks Creative — Client Portal

Private, per-client project portal built with [Astro](https://astro.build/) and deployed to [Cloudflare Pages](https://pages.cloudflare.com/). Authentication is handled by Cloudflare Access — email magic link only, no accounts, no passwords.

## Local Development

```bash
npm install
npm run dev          # local dev server at localhost:4321
npm run build        # static build to dist/
npm run preview      # preview the built site locally
```

## Project Structure

```
src/
├── content.config.ts          # Content collection schema
├── content/portal/            # Markdown content (synced from Obsidian)
│   └── stranville-living/     # One folder per client
│       ├── index.md           # Project overview
│       └── production-update.md
├── pages/
│   ├── index.astro            # Root — returns 404 (no public index)
│   └── [client]/
│       ├── index.astro        # Client overview page
│       └── [...slug].astro    # Individual note pages
├── layouts/
│   └── PortalLayout.astro     # Shared shell: header, nav, footer
├── components/
│   ├── StatusBadge.astro      # Status pill (draft/in-review/delivered/approved)
│   ├── DeliverableCard.astro  # Card with title, status, optional link
│   └── AssetLink.astro        # External asset link list
└── styles/
    └── global.css             # Prairie Cinematic design tokens
```

## Content Authoring

Content is authored in Obsidian as Markdown. Each note requires this frontmatter:

```yaml
---
title: "Note Title"
client: client-slug          # must match the folder name and URL path
publish: true                # false = excluded from build
status: draft                # draft | in-review | delivered | approved
date: 2026-06-05
type: update                 # update | deliverable | feedback | brief
asset_links:                 # optional
  - label: "Link Label"
    url: "https://..."
---
```

### Content Rules
- Notes with `publish: false` are excluded at build time
- Files beginning with `_` (underscore) should not be committed to the repo
- Each client gets their own subfolder under `src/content/portal/`

---

## Deployment: Cloudflare Pages (Phase 2)

### Option A: GitHub Integration (recommended)

1. Log into the [Cloudflare dashboard](https://dash.cloudflare.com/)
2. Go to **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
3. Select this GitHub repository
4. Configure build settings:
   - **Build command:** `npm run build`
   - **Build output directory:** `dist`
   - **Node version:** Add environment variable `NODE_VERSION` = `22`
5. Deploy

### Option B: GitHub Actions (already configured)

1. In your Cloudflare dashboard, create an API token with **Cloudflare Pages** permissions
2. In this GitHub repo, add these secrets under **Settings → Secrets → Actions**:
   - `CLOUDFLARE_API_TOKEN` — your API token
   - `CLOUDFLARE_ACCOUNT_ID` — your Cloudflare account ID
3. Push to `main` — the workflow in `.github/workflows/deploy.yml` will build and deploy automatically

### Custom Domain Setup

1. In Cloudflare Pages project settings → **Custom domains**
2. Add `portal.coalbanks.com`
3. Cloudflare will handle DNS and SSL automatically if the domain is already on Cloudflare

---

## Authentication: Cloudflare Access (Phase 3)

Cloudflare Access provides the login screen — no auth code in this repo.

### First-Time Zero Trust Setup

1. Log into [Cloudflare dashboard](https://dash.cloudflare.com/) → **Zero Trust** (sidebar)
2. Create a Zero Trust organization if one does not exist (team name: `coalbanks`)
3. Confirm Free plan is active (50 users included)

### Per-Client Access Policy

Repeat for each client:

1. **Access** → **Applications** → **Add Application** → **Self-hosted**
2. Application name: `[Client Name] Portal`
3. Application URL: `portal.coalbanks.com/[client-slug]/*`
4. Session duration: **7 days**
5. **Authentication** → **Policies** → **Add policy**:
   - Rule: **Include** → **Emails** → `client@email.com`
6. Login methods: **One-time PIN** only
7. Save

### Current Client Slugs

| Client | Slug | URL Path |
|--------|------|----------|
| Stranville Living | `stranville-living` | `portal.coalbanks.com/stranville-living/*` |

---

## Obsidian Integration (Phase 5)

### Vault Setup with Symlink

1. Create a new Obsidian vault (e.g. `Coalbanks Portal`)

2. Create a symlink from the vault into this repo:
   ```bash
   # From this repo's root:
   # First, move or remove the existing content/portal directory if needed
   # Then create the symlink:
   ln -s /path/to/your/obsidian-vault/portal src/content/portal
   ```
   Or symlink in the other direction — from the vault to the repo:
   ```bash
   # From your Obsidian vault:
   ln -s /path/to/coalbanks-portal/src/content/portal portal
   ```

3. Choose the approach that fits your workflow best. The key is that `src/content/portal/` contains the Markdown files.

### Obsidian Git Plugin

1. Install the **Obsidian Git** community plugin
2. Configure:
   - **Vault backup interval:** 5 minutes (or manual)
   - **Auto pull interval:** 5 minutes
   - **Commit message:** `content: {{date}}`
3. The plugin will auto-commit and push changes, triggering a Cloudflare Pages rebuild

### Content Workflow

1. Create/edit a note in Obsidian under the client folder
2. Add the required frontmatter (see Content Authoring above)
3. Set `publish: true` when ready
4. Obsidian Git commits and pushes → Cloudflare Pages rebuilds → live in ~2 minutes

---

## Design System

The portal uses the **Prairie Cinematic** design system — warm, editorial, and minimal. Key tokens:

- **Background:** `#F9F8F5` (warm off-white)
- **Text:** `#1A1A1A` (near-black)
- **Accent:** `#2D2D2D` (headings, borders)
- **Rule:** `#D4C9B0` (warm parchment)
- **Headings:** Space Grotesk
- **Body:** Inter

---

*Coalbanks Creative Inc. — Lethbridge, Alberta — coalbanks.ca*
