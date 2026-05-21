---
name: media-publisher
description: Publish media assets (images, videos, GIFs) to GitHub Releases for inline embedding in README. Creates cumulative versioned releases (media-v1, media-v2, ...) with all files from docs/media/. Use when asked to publish media, upload assets to GitHub, generate embeddable URLs, or embed videos/images in README.
license: MIT
---

# Media Publisher

Publish captured media to GitHub Releases for inline playback and clickable enlargement in README files.

## How It Works

GitHub Releases assets are served with correct `Content-Type` headers, enabling:
- **Video inline playback**: `<video src="..." controls width="640"></video>`
- **Image inline display + click to enlarge**: `[![Name](URL)](URL)`

## Workflow

### Phase 1: Prepare

1. Verify `docs/media/` exists and contains files
2. Check `gh` CLI is installed and authenticated
3. Count files to publish

### Phase 2: Version

1. Find latest `media-vN` release via `gh release list`
2. Increment to `media-v(N+1)` (starts at `media-v1`)
3. Create new release with `gh release create`

### Phase 3: Upload

1. Upload ALL files from `docs/media/` (cumulative)
2. Use `--clobber` to replace assets with same name
3. Track successful and failed uploads
4. Generate direct download URLs: `https://github.com/owner/repo/releases/download/media-vN/filename.ext`

### Phase 4: Manifest

Save `docs/media/media-manifest.json`:
```json
{
  "version": 2,
  "tag": "media-v2",
  "repo": "owner/repo",
  "release_url": "https://github.com/owner/repo/releases/tag/media-v2",
  "assets": {
    "demo-web.mp4": "https://github.com/owner/repo/releases/download/media-v2/demo-web.mp4",
    "landing-desktop-web.png": "https://github.com/owner/repo/releases/download/media-v2/landing-desktop-web.png"
  }
}
```

### Phase 5: Report

Print embeddable snippets:
- Videos: `<video src="URL" controls width="640"></video>`
- Images: `[![Name](URL)](URL)` — thumbnail inline, click opens full res

## Usage

```bash
./scripts/publish-media.sh [media-dir]
```

Default media-dir: `docs/media`

## Embedding Guide

### Video (inline playback)

```html
<video src="https://github.com/owner/repo/releases/download/media-v2/demo-web.mp4" controls width="640"></video>
```

### Image (inline + clickable)

```markdown
[![Landing Page](https://github.com/owner/repo/releases/download/media-v2/landing-desktop-web.png)](https://github.com/owner/repo/releases/download/media-v2/landing-desktop-web.png)
```

### Gallery Grid

```markdown
| Landing | Dashboard | Settings |
|---------|-----------|----------|
| [![Landing](URL1)](URL1) | [![Dashboard](URL2)](URL2) | [![Settings](URL3)](URL3) |
```

## Release Strategy

- **Cumulative**: Each release contains ALL media files, not just new ones
- **Versioned**: `media-v1`, `media-v2`, etc. — history is preserved
- **Per-repo**: Tags are scoped to the repository
- **Idempotent**: `--clobber` replaces assets with same name

## Dependencies

| Tool | Required | Install |
|------|----------|---------|
| `gh` CLI | Yes | `brew install gh` |
| GitHub auth | Yes | `gh auth login` |
| `docs/media/` | Yes | Created by `record-app` |

## Edge Cases

- **No `gh` CLI**: Inform user, skip publish
- **Not authenticated**: Run `gh auth login`
- **Empty media dir**: Warn, skip
- **Upload fails for one file**: Continue with others, report failures
- **Release already exists**: Use `--clobber` to update assets
