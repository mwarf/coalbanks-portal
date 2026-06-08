# Portal Content Spec — For Agents

Instructions for generating client-facing content for the Coalbanks Creative portal. Read this file before writing any portal content.

---

## What This Portal Is

A private, read-only project portal for Coalbanks Creative clients. Each client has a password-protected URL (e.g., `portal.coalbanks.com/kasko-cattle/`). Content is Markdown files with YAML frontmatter. The portal is static HTML — no interactivity, no comments, no uploads.

The audience is the client. They are reviewing production progress, not reading internal notes.

---

## Output Location

Write files to:

```
src/content/portal/{client-slug}/{filename}.md
```

- `client-slug` is lowercase, hyphenated (e.g., `kasko-cattle`, `stranville-living`)
- `filename` is lowercase, hyphenated, descriptive (e.g., `edit-1-review.md`, `location-scouting.md`)
- `index.md` is reserved for the project overview — do not overwrite it unless explicitly asked

---

## Frontmatter Schema (strict)

Every file must have this exact YAML frontmatter structure. The build will fail if any required field is missing or uses an invalid value.

```yaml
---
title: "Page Title Here"
client: client-slug
publish: true
status: draft
date: 2026-06-08
type: update
asset_links:
  - label: "Descriptive Label"
    url: "https://full-valid-url.com/path"
gallery:
  - src: "https://assets.coalbanks.com/client/gallery/image.jpg"
    alt: "Description of what the image shows"
    caption: "Optional caption"
---
```

### Required Fields

| Field | Type | Valid Values | Notes |
|-------|------|-------------|-------|
| `title` | string | Any text | Use title case. Include project name for context (e.g., "Better Everywhere — Edit 1 Review") |
| `client` | string | Exact slug | Must match the folder name exactly. Not the display name. |
| `publish` | boolean | `true` / `false` | Set `true` when the content is ready for the client to see. Set `false` to keep it in the repo but hidden. |
| `status` | enum | `draft` · `in-review` · `delivered` · `approved` | See status definitions below. |
| `date` | date | `YYYY-MM-DD` | The date this content is relevant (usually today or the date of the event being described). |
| `type` | enum | `update` · `deliverable` · `feedback` · `brief` | See type definitions below. |

### Optional Fields

| Field | Type | Notes |
|-------|------|-------|
| `asset_links` | array of `{label, url}` | External links to files, videos, documents. Both `label` and `url` are required. `url` must be a valid URL with protocol. |
| `gallery` | array of `{src, alt, caption?}` | Image gallery. `src` must be a full `https://assets.coalbanks.com/...` URL. `alt` is required. `caption` is optional. |

### Validation Rules

- All URLs must include protocol (`https://`)
- `client` must be an exact match to the folder name — not the display name, not capitalized
- `date` must be `YYYY-MM-DD` format, not quoted (YAML parses it as a date)
- `publish` must be bare `true` or `false`, not quoted
- `asset_links` and `gallery` can be omitted entirely, but if present, every entry must have all required subfields

---

## Content Types

### `brief` — Project Overview
The project landing page. Usually `index.md`. Summarizes scope, timeline, and current status.

**When to create:** Project kickoff or when scope changes significantly.
**Typical sections:** Project Scope, Production Schedule, Current Status, Next Step for You.

### `update` — Production Progress
A milestone or progress report during production.

**When to create:** After a shoot day, when a milestone is reached, when the schedule changes, when scouting is complete.
**Typical sections:** What happened, what's next, timeline table, action items for the client.

### `deliverable` — Something to Review
A specific asset being delivered for client review.

**When to create:** When a rough cut, final edit, design comp, or other reviewable asset is ready.
**Typical sections:** What this is, what to focus on during review, how to send feedback, deadline.

### `feedback` — Request for Client Input
A specific question or decision that needs client input.

**When to create:** When you need the client to choose between options, approve a direction, or provide specific information.
**Typical sections:** Context, the specific question or options, deadline for response.

---

## Status Definitions

| Status | Meaning | Use When |
|--------|---------|----------|
| `draft` | Work in progress | Michael is still working on the content or the production item it describes |
| `in-review` | Awaiting client action | The client needs to review, approve, or respond to something |
| `delivered` | Sent, no action needed | An asset or update has been shared — client can view but nothing is expected of them |
| `approved` | Client has signed off | The client confirmed this item is complete |

**Default for new updates:** `in-review` if the client needs to do something, `delivered` if it's informational.

---

## Writing Style

### Voice
- Second person ("you", "your") when addressing the client
- Professional but warm — not corporate, not casual
- Direct and clear — assume the client is busy
- Present tense for current state, past tense for what happened

### Structure
- Lead with what matters most to the client
- Use `##` headings to break up sections (never `#` — the page title is already `<h1>`)
- Use tables for schedules and timelines
- Use bullet lists for status updates and checklists
- Bold key dates and deadlines
- End with a clear "next step" or "action item" section when the client needs to do something

### What to Include
- What happened or what's ready
- What it means for the project timeline
- What the client needs to do (if anything) and by when
- Links to relevant assets (via `asset_links` in frontmatter, not inline links)

### What NOT to Include
- Internal production details the client doesn't need (gear lists, crew logistics, file management)
- Pricing, invoicing, or payment information
- Negative framing ("we had problems with...") — reframe as solutions or adjustments
- Technical jargon (codec, LUT, timecode) unless the client is technical
- Obsidian-specific syntax (`[[wiki links]]`, `![[embeds]]`) — use standard Markdown only

### Formatting
- Use `✅` for completed items and `⏳` for in-progress items in status lists
- Use Markdown tables for schedules (see examples below)
- Use `**bold**` for emphasis, not ALL CAPS
- Horizontal rules (`---`) between major sections are optional
- Keep paragraphs short (2–4 sentences)

---

## Templates

### Update Template

```markdown
---
title: "{Project Name} — {Milestone Description}"
client: {client-slug}
publish: true
status: delivered
date: {YYYY-MM-DD}
type: update
asset_links:
  - label: "{Asset Description}"
    url: "{url}"
---

## {What Happened}

{1-2 paragraphs summarizing the milestone or progress.}

### {Subsection if Needed}

{Details, organized by location/topic/phase.}

## Timeline

| Milestone | Target Date |
|-----------|-------------|
| {milestone} | {date} |
| {milestone} | {date} |

## Next Step for You

{What the client should do, if anything, and by when.}
```

### Deliverable Template

```markdown
---
title: "{Project Name} — {Deliverable Name}"
client: {client-slug}
publish: true
status: in-review
date: {YYYY-MM-DD}
type: deliverable
asset_links:
  - label: "{Deliverable Name} — {Version}"
    url: "{url}"
---

## What You're Reviewing

{1 paragraph describing what this deliverable is and where it fits in the project.}

## What to Look For

{Specific guidance on what feedback is most useful at this stage.}

- {Specific thing to evaluate}
- {Specific thing to evaluate}
- {Specific thing to evaluate}

## How to Send Feedback

Send your notes to michael@coalbanks.com by **{deadline date}**.

{Any specific format preferences for feedback — e.g., timestamps for video, page numbers for documents.}
```

### Feedback Template

```markdown
---
title: "{Project Name} — {Decision Needed}"
client: {client-slug}
publish: true
status: in-review
date: {YYYY-MM-DD}
type: feedback
---

## Context

{1-2 paragraphs of background on why this decision is needed.}

## {The Question or Options}

{Present the options clearly, with enough detail for the client to decide.}

## Timeline

We need your input by **{deadline date}** to stay on schedule for {next milestone}.

Please reply to michael@coalbanks.com with your preference.
```

---

## Examples From Live Content

### Good Update (Stranville — Production Update)

```yaml
title: "Better Everywhere — Production Update"
client: stranville-living
status: in-review
type: update
```

Body opens with what happened ("Principal photography wrapped June 2"), includes a timeline table, and ends with numbered action items and a bold deadline.

### Good Brief (Kasko — Project Overview)

```yaml
title: "Brand Film — Project Overview & Brief"
client: kasko-cattle
status: approved
type: brief
```

Body has Project Scope with key elements as bullets, a schedule table with bold dates, a status checklist using ✅ and ⏳, and ends with a concrete next step.

### Good Gallery Update (Kasko — Location Scouting)

```yaml
title: "Location Scouting Gallery"
client: kasko-cattle
status: delivered
type: update
```

Uses `gallery` frontmatter with descriptive `alt` text and production-relevant `caption` values. Body adds scouting notes organized by location with numbered key findings.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `client: Kasko Cattle` | Use the slug: `client: kasko-cattle` |
| `publish: "true"` | Bare boolean: `publish: true` |
| `date: June 5, 2026` | ISO format: `date: 2026-06-05` |
| `url: drive.google.com/...` | Include protocol: `url: "https://drive.google.com/..."` |
| `status: review` | Exact enum: `status: in-review` |
| `type: note` | Valid types only: `update`, `deliverable`, `feedback`, `brief` |
| `# Heading` | Start at `##` — the `#` heading is generated from `title` |
| `[[Some Link]]` | Standard Markdown: `[Some Link](url)` |
| Inline links to assets | Use `asset_links` in frontmatter — they render as a styled list |
| Missing `alt` on gallery | Every gallery image requires `alt` text |

---

## Filename Conventions

- Lowercase, hyphenated: `edit-1-review.md`, not `Edit 1 Review.md`
- Descriptive but concise: `location-scouting.md`, not `june-4-drone-photos-from-scouting-day.md`
- No spaces, no underscores (underscore prefix means "never publish")
- No date prefixes in filenames — the `date` field in frontmatter handles ordering

---

## Contact Reference

All client-facing content should direct responses to: **michael@coalbanks.com**
