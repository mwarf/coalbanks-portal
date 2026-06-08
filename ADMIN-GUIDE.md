# Coalbanks Portal — Admin Guide

How to manage client projects, publish content, and share deliverables through the portal.

---

## How the Portal Works

The portal is a static website built from Markdown files in Obsidian. When you save a file, the Obsidian Git plugin auto-commits and pushes to GitHub. GitHub Actions builds the site and deploys it to Cloudflare Pages. The whole cycle takes about 5–7 minutes from save to live.

```
Obsidian save → auto-commit (5 min) → GitHub push → build (30s) → portal.coalbanks.com
```

You can also force an immediate push from Obsidian: open the command palette (`Cmd+P`) and run **Obsidian Git: Commit all changes and push**.

---

## Folder Structure

All portal content lives in:

```
src/content/portal/
├── kasko-cattle/
│   ├── index.md              ← project overview (landing page)
│   ├── location-scouting.md  ← individual update/deliverable
│   └── _draft-notes.md       ← underscore prefix = never published
├── stranville-living/
│   ├── index.md
│   └── production-update.md
```

**Rules:**
- Each client gets a folder matching their URL slug (e.g., `kasko-cattle` → `portal.coalbanks.com/kasko-cattle/`)
- `index.md` is the project landing page clients see first
- Every other `.md` file becomes a subpage
- Files starting with `_` (underscore) are **never committed or published** — use them for your own notes

---

## Frontmatter Reference

Every content file needs this YAML frontmatter block at the top:

```yaml
---
title: "Location Scouting Gallery"
client: kasko-cattle
publish: true
status: delivered
date: 2026-06-02
type: update
asset_links:
  - label: "Full Resolution Photos (Google Drive)"
    url: "https://drive.google.com/..."
gallery:
  - src: "https://assets.coalbanks.com/kasko-cattle/location-scouting/photo.jpg"
    alt: "Description of the image"
    caption: "Optional caption shown below image"
videos:
  - id: "cloudflare-stream-video-uid"
    title: "Video title shown below player"
    poster: "https://optional-thumbnail-url.jpg"
---
```

### Required Fields

| Field | Values | Notes |
|-------|--------|-------|
| `title` | Any text | Page title and heading |
| `client` | Slug (e.g., `kasko-cattle`) | Must match the folder name exactly |
| `publish` | `true` or `false` | `false` = file exists in repo but is never built or visible |
| `status` | `draft` · `in-review` · `delivered` · `approved` | Shown as a coloured badge on the page |
| `date` | `YYYY-MM-DD` | Displayed on the page, used for ordering |
| `type` | `update` · `deliverable` · `feedback` · `brief` | Shown as a type badge |

### Optional Fields

| Field | Purpose |
|-------|---------|
| `asset_links` | List of labelled external links (Google Drive, Cloudflare Stream, etc.) |
| `gallery` | List of images displayed as a photo gallery with lightbox |
| `videos` | List of Cloudflare Stream videos displayed as branded embedded players |

---

## Content Types — When to Use What

### Brief (`type: brief`)
The project overview page. Usually `index.md`. Contains scope, timeline, key contacts, and links to foundational documents (proposals, SOWs, creative briefs).

**Use for:** Project kickoff, scope summary, production schedule.

### Update (`type: update`)
Progress updates during production. Each significant milestone gets its own page.

**Use for:** Location scouting galleries, production recaps, schedule changes, behind-the-scenes notes.

### Deliverable (`type: deliverable`)
A specific thing being delivered for client review or approval.

**Use for:** Rough cuts, final edits, colour grades, music selects, graphics packages. Link to the actual file via `asset_links`.

### Feedback (`type: feedback`)
A request for client input on something specific.

**Use for:** Edit review requests, script approvals, direction choices, shot selects.

---

## Status Workflow

Move the `status` field as work progresses:

```
draft → in-review → delivered → approved
```

| Status | When to Use | Badge Colour |
|--------|-------------|--------------|
| `draft` | You're still working on it — client can see it but knows it's not final | Grey |
| `in-review` | Waiting for client feedback or approval | Amber |
| `delivered` | Sent to client, no action needed from them | Green |
| `approved` | Client has signed off | Blue |

---

## Asset Links — What Goes Where

### Google Drive (large files, downloads)
Use Google Drive for anything the client needs to download or that's too large for the portal:
- Full-resolution photos
- Raw footage
- PDFs (proposals, contracts, briefs)
- Audio files

Set sharing to **"Anyone with the link can view"**, then add it as an `asset_link`:

```yaml
asset_links:
  - label: "Full Resolution Photos (Google Drive)"
    url: "https://drive.google.com/drive/folders/XXXXX"
  - label: "Signed SOW (PDF)"
    url: "https://drive.google.com/file/d/XXXXX/view"
```

### Cloudflare Stream (video review — embedded player)
For rough cuts, dailies, and edits that need client review, upload to Cloudflare Stream. Videos can be embedded directly in the portal with a branded player, or linked as an asset.

See the **Video Streaming** section below for full details.

### Direct URLs
Any public URL works — Vimeo, YouTube (unlisted), Dropbox share links, Frame.io, etc.

---

## Image Galleries

Galleries display as a masonry grid with a lightbox viewer (click to enlarge, keyboard navigation, touch swipe on mobile).

### Step 1 — Upload images to R2

Use the `upload-gallery.sh` script from the repo root:

```bash
./upload-gallery.sh <client>/<gallery-name> /path/to/source/photos [max-width]
```

**Examples:**

```bash
# Upload drone scouting photos for Kasko, resize to 2400px wide (default)
./upload-gallery.sh kasko-cattle/location-scouting /Volumes/A022/Kasko-Drone-Edits

# Upload BTS photos for Stranville, resize to 1800px wide
./upload-gallery.sh stranville-living/bts ~/Photos/stranville-bts 1800
```

The script will:
1. Resize images (if wider than max-width) using macOS `sips`
2. Upload to the `coalbanks-assets` R2 bucket
3. Print YAML frontmatter — **copy and paste this into your Markdown file**

### Step 2 — Add the gallery YAML to your content file

The script outputs something like:

```yaml
gallery:
  - src: "https://assets.coalbanks.com/kasko-cattle/location-scouting/DJI_001.jpg"
    alt: "DJI_001"
    caption: ""
  - src: "https://assets.coalbanks.com/kasko-cattle/location-scouting/DJI_002.jpg"
    alt: "DJI_002"
    caption: ""
```

Paste it into your frontmatter. Then update the `alt` text with real descriptions and add optional captions:

```yaml
gallery:
  - src: "https://assets.coalbanks.com/kasko-cattle/location-scouting/DJI_001.jpg"
    alt: "Aerial drone view of Kasko Cattle feedlot and surrounding prairie"
    caption: "Feedlot overview — primary establishing shot"
  - src: "https://assets.coalbanks.com/kasko-cattle/location-scouting/DJI_002.jpg"
    alt: "Drone view of north pasture and grazing land"
    caption: "North Pasture — sunrise drone position"
```

### Gallery Tips
- The **first image** in the list is displayed as a large hero image
- JPG and PNG are supported
- Default max width is 2400px — good for detail viewing without huge file sizes
- Use 1800px for BTS/reference photos where detail doesn't matter as much
- Write descriptive `alt` text — it helps with accessibility and shows if images fail to load

---

## Video Streaming

Videos are hosted on Cloudflare Stream and embedded in portal pages with a branded player (dark letterbox, Prairie Cinematic title bar). Clients can play, pause, scrub, and fullscreen directly on the portal — no external links needed.

**Cloudflare Stream costs:** $5/month base (1,000 minutes storage) + $1 per 1,000 minutes viewed. For client review, viewing costs are negligible.

### Step 1 — Upload the video

Use the `upload-video.sh` script from the repo root:

```bash
./upload-video.sh <video-file> "Video Title"
```

**Examples:**

```bash
# Upload scouting dailies
./upload-video.sh /Volumes/A022/kasko-social/kasko-rushes-june-5.mov "Kasko Cattle — Scouting Dailies, June 5"

# Upload a rough cut
./upload-video.sh ~/Desktop/stranville-edit-1.mp4 "Better Everywhere — Rough Cut Edit 1"
```

The script will:
1. Initiate a resumable (tus) upload — handles files up to 30GB
2. Upload in 100MB chunks with a progress bar
3. Wait for Cloudflare to process the video
4. Print YAML frontmatter to paste into your content file

**Requirements:**
- `CLOUDFLARE_API_TOKEN` set in `.env` (or as an env var) — needs Stream:Edit permission
- Cloudflare Stream subscription active on your account

### Step 2 — Add the video to your content file

The script outputs something like:

```yaml
videos:
  - id: "16f3d4237d1e2390c189cdf46ab0c0ed"
    title: "Kasko Cattle — Scouting Dailies, June 5"
    poster: "https://customer-....cloudflarestream.com/.../thumbnails/thumbnail.jpg"
```

Paste the `videos` block into your frontmatter. The `poster` field is optional — if omitted, Stream auto-generates a thumbnail.

### Step 3 — Create the content page

```yaml
---
title: "Scouting Dailies — June 5"
client: kasko-cattle
publish: true
status: delivered
date: 2026-06-05
type: update
videos:
  - id: "16f3d4237d1e2390c189cdf46ab0c0ed"
    title: "Kasko Cattle — Scouting Dailies, June 5"
---

## Scouting Dailies

Description of the video content and what the client should look for.
```

The video player renders automatically above the page body — no extra markup needed.

### Multiple Videos Per Page

You can embed multiple videos on a single page:

```yaml
videos:
  - id: "abc123..."
    title: "Rough Cut — Edit 1"
  - id: "def456..."
    title: "Rough Cut — Edit 2 (revised)"
```

Each gets its own branded player card.

### Video + Asset Link (both)

If you want the embedded player AND a direct link (e.g., for the client to share):

```yaml
videos:
  - id: "16f3d4237d1e2390c189cdf46ab0c0ed"
    title: "Scouting Dailies — June 5"
asset_links:
  - label: "Direct Stream Link — Scouting Dailies"
    url: "https://customer-1nnz6nljigkdvldi.cloudflarestream.com/16f3d4237d1e2390c189cdf46ab0c0ed/watch"
```

### Video Tips
- The player is responsive — works on desktop, tablet, and mobile
- Videos process on Cloudflare's side after upload — allow a few minutes before they're playable
- `.mov` and `.mp4` are both supported (Stream transcodes everything to HLS/DASH)
- For very large files (>5GB), the upload may take a while — the script is resumable so you can retry if it fails
- The branded player matches the portal design — dark `#1A1A1A` letterbox, `#2D2D2D` controls

---

## Adding a New Client

### 1. Create the content folder

In Obsidian, create a new folder under `src/content/portal/`:

```
src/content/portal/new-client-slug/
```

Use lowercase, hyphenated names (e.g., `smith-ranch`, `prairie-homes`).

### 2. Create the project overview

Create `index.md` in that folder:

```yaml
---
title: "Project Name — Overview"
client: new-client-slug
publish: true
status: draft
date: 2026-07-01
type: brief
asset_links:
  - label: "Creative Brief"
    url: "https://drive.google.com/..."
---

## Project Scope

Describe the project here.

## Next Step for You

What the client should do next.
```

### 3. Set up Cloudflare Access

In the Cloudflare Zero Trust dashboard:

1. **Access controls → Applications → Create new application → Self-hosted**
2. Application name: `New Client Portal`
3. Destination: `portal.coalbanks.com/new-client-slug/`
4. Add policy: Allow → Emails → client's email address (and `michael@coalbanks.com`)
5. Save

### 4. Send the client their link

Send them: `https://portal.coalbanks.com/new-client-slug/`

They'll see the branded Cloudflare Access login, enter their email, receive a one-time code, and land on their project page. No account creation needed.

---

## Adding a New Page to an Existing Project

Create a new `.md` file in the client's folder:

```
src/content/portal/kasko-cattle/edit-1-review.md
```

Add frontmatter and content. Set `publish: true` when ready for the client to see it.

The URL will be: `portal.coalbanks.com/kasko-cattle/edit-1-review`

---

## Writing Content in Obsidian

The body of each page is standard Markdown. You can use:

- **Headings** (`## Section`, `### Subsection`)
- **Bold** and *italic*
- Bullet lists and numbered lists
- Tables (see the Kasko overview for an example)
- Links: `[link text](https://url)`
- Checkboxes: `- ✅ Done` / `- ⏳ In progress`
- Horizontal rules: `---`
- Code blocks (for technical specs)
- Block quotes: `> Quote text`

**Avoid:**
- Obsidian-specific features (`[[wiki links]]`, `![[embeds]]`) — these don't render in Astro
- Use standard Markdown links instead: `[Link Text](url)`

---

## Hiding and Unpublishing Content

**To hide a page from clients:** Set `publish: false` in the frontmatter. The file stays in the repo but is never built or accessible.

**To keep personal notes:** Prefix the filename with `_` (underscore), e.g., `_shot-list-ideas.md`. These files are excluded from git entirely — they only exist on your machine.

---

## Manual Deploy (skip the 5-minute wait)

Open the Obsidian command palette (`Cmd+P`) and run:

```
Obsidian Git: Commit all changes and push
```

The site will rebuild and deploy within about 30 seconds of the push.

---

## Quick Reference

| Task | How |
|------|-----|
| New client | Create folder in `src/content/portal/`, add `index.md`, set up Cloudflare Access |
| New update | Create `.md` file in client folder with frontmatter |
| Upload gallery | `./upload-gallery.sh client/gallery /path/to/photos` |
| Upload video | `./upload-video.sh /path/to/video.mov "Video Title"` |
| Embed video | Add `videos` array to frontmatter with Stream ID |
| Link to Google Drive | Add to `asset_links` in frontmatter |
| Hide a page | Set `publish: false` |
| Private notes | Prefix filename with `_` |
| Force deploy now | `Cmd+P` → Obsidian Git: Commit all changes and push |
| Check deploy status | `gh run list --repo mwarf/coalbanks-portal` |
