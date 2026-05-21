---
name: media-publisher
description: Publish media assets (images, videos, GIFs) to GitHub for inline embedding in README. Uploads to user-attachments for inline video playback, or falls back to GitHub Releases. Reuses the latest media release tag for cumulative uploads. Use when asked to publish media, upload assets to GitHub, generate embeddable URLs, or embed videos/images in README.
license: MIT
---

# Media Publisher

Publish captured media to GitHub for inline playback and clickable enlargement in README files.

## How It Works

GitHub README supports inline video playback **only** with `user-attachments` URLs:

```html
<video src="https://github.com/user-attachments/assets/UUID" controls width="640"></video>
```

These URLs come from GitHub's internal upload endpoint — the same one used by drag-and-drop in the web UI. GitHub Releases URLs do **not** render inline video in READMEs.

## Upload Methods

The skill auto-detects the best available upload method:

| Method | CLI Tool | Inline Video | Setup |
|--------|----------|--------------|-------|
| **user-attachments** | `gh-image` | Yes | `gh extension install drogers0/gh-image` |
| **user-attachments** | `gh-attach` | Yes | `gh extension install Addono/gh-attach` |
| **Release assets** | `gitshot` via `gh shot` | No (clickable) | `gh extension install vipulgupta2048/gitshot` |
| **Release assets** | `gh release` | No (clickable) | Built-in, no install needed |

**Recommended:** Install `gh-image` for inline video support:
```bash
gh extension install drogers0/gh-image
```

## Workflow

### Phase 1: Prepare

1. Verify `docs/media/` exists and contains files
2. Check `gh` CLI is installed and authenticated
3. Detect best upload method (gh-image → gh-attach → gitshot → releases)
4. Count files to publish

### Phase 2: Upload

Upload all files using the detected method:

- **gh-image**: Reads browser cookies, uploads to `user-attachments` endpoint
- **gh-attach**: Browser automation via playwright, uploads to `user-attachments`
- **gitshot**: Creates dedicated public repo, uploads as Release assets
- **releases**: Creates `media-vN` release, uploads as Release assets

### Phase 3: Manifest

Save `docs/media/media-manifest.json`:
```json
{
  "upload_method": "gh-image",
  "repo": "owner/repo",
  "assets": {
    "demo-web.mp4": "https://github.com/user-attachments/assets/UUID",
    "landing-desktop-web.png": "https://github.com/user-attachments/assets/UUID"
  }
}
```

### Phase 4: Report

Print embeddable snippets:
- **user-attachments URLs**: `<video src="..." controls width="640"></video>` (inline playback)
- **Release URLs**: `[![Play](badge)](URL)` (clickable link)
- **Images**: `[![Name](URL)](URL)` (clickable, opens full res)

## Usage

```bash
./scripts/publish-media.sh [media-dir]
```

Default media-dir: `docs/media`

## Embedding Guide

### Video with user-attachments URL (inline playback)

```html
<video src="https://github.com/user-attachments/assets/UUID" controls width="640"></video>
```

### Video with Release URL (clickable badge)

```markdown
[![Play Video](https://img.shields.io/badge/▶-Play-blue?style=for-the-badge)](https://github.com/owner/repo/releases/download/media-v1/demo.mp4)
```

### Image (inline + clickable)

```markdown
[![Landing Page](https://github.com/user-attachments/assets/UUID)](https://github.com/user-attachments/assets/UUID)
```

### Gallery Grid

```markdown
| | |
|---|---|
| [![Landing](URL1)](URL1) | [![Dashboard](URL2)](URL2) |
| *Landing page* | *Dashboard view* |
```

2-column table with captions below each image. For 3+ images per row, adjust column count accordingly.

## Install Upload Tools

### gh-image (recommended — inline video)

```bash
gh extension install drogers0/gh-image
```

Reads browser cookies, uploads to `user-attachments` endpoint. Requires active browser session with GitHub.

### gh-attach (alternative — inline video)

```bash
gh extension install Addono/gh-attach
```

Uses browser automation (playwright). More reliable but slower.

### gitshot (zero-config — clickable only)

```bash
gh extension install vipulgupta2048/gitshot
```

Auto-creates a public `gitshot-images` repo. No browser needed. When installed as a gh extension, invoke via `gh shot`. When installed globally via npm, invoke via `gitshot`.

## Dependencies

| Tool | Required | Install |
|------|----------|---------|
| `gh` CLI | Yes | `brew install gh` |
| GitHub auth | Yes | `gh auth login` |
| `gh-image` | Recommended | `gh extension install drogers0/gh-image` |
| `docs/media/` | Yes | Created by `record-app` |

## Edge Cases

- **No upload tool available**: Falls back to GitHub Releases (official API)
- **Not authenticated**: Run `gh auth login`
- **Empty media dir**: Warn, skip
- **Upload fails for one file**: Continue with others, report failures
- **Private repos**: user-attachments URLs inherit repo visibility (stay private)
- **Undocumented endpoint**: `gh-image` and `gh-attach` use GitHub's internal user-attachments API which may break without notice. Release fallback always works.
