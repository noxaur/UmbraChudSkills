---
name: media-publisher
description: Publish media assets (images, videos) to GitHub for embedding in README. Guides the user through manual upload for videos (required for inline playback) and offers optional gh release upload for images. Use when asked to publish media, upload assets to GitHub, generate embeddable URLs, or embed videos/images in README.
license: MIT
---

# Media Publisher

Guide the user through publishing captured media to GitHub for README embedding.

## How GitHub Media Works

GitHub READMEs support two kinds of media URLs:

| URL Type | Inline Video | Images | How to get it |
|----------|-------------|--------|---------------|
| `user-attachments` | ✅ Yes | ✅ Clickable | Drag & drop into a GitHub issue/PR comment via browser |
| Release asset | ❌ No (badge link) | ✅ Clickable | `gh release upload` (automatic, CLI-only) |

**Videos require `user-attachments` URLs for inline playback.** There is no automated CLI tool for this on the current machine. The user must upload videos manually via browser.

Images work fine with Release URLs (clickable thumbnails). Use `gh release upload` for those.

## Workflow

### Phase 1: Prepare

1. Verify `docs/media/` exists and contains the files
2. Check `gh` CLI is installed and authenticated
3. Separate files by type: videos (.mp4, .webm, .mov) vs images (.png, .jpg, .gif)

### Phase 2: Upload Images (Optional — Release URLs)

Images can be auto-uploaded as Release assets. This is optional — the user can also upload images manually alongside videos.

```bash
# Find/create latest media-vN release tag
LATEST_TAG=$(gh release list --limit 30 --json tagName -q '.[].tagName' 2>/dev/null | grep '^media-v' | sort -V | tail -1 || echo "media-v1")

if ! gh release view "$LATEST_TAG" --json tagName &>/dev/null; then
  gh release create "$LATEST_TAG" \
    --title "Media Assets" \
    --notes "Cumulative media assets"
fi

# Upload each image
for file in docs/media/*.png docs/media/*.jpg docs/media/*.gif; do
  [ -f "$file" ] || continue
  gh release upload "$LATEST_TAG" "$file" --clobber
done
```

Each image gets a URL like:
```
https://github.com/owner/repo/releases/download/media-v1/filename.png
```

### Phase 3: Upload Videos (Manual — Required for Inline Playback)

The user must upload videos via the GitHub web UI:

1. Open a browser, go to any GitHub issue or PR in the target repo
2. Drag the video file(s) into the comment box
3. Wait for the upload to complete — GitHub generates a URL like:
   `https://github.com/user-attachments/assets/<uuid>`
4. Copy each URL

Collect the URLs in a table:

| File | URL |
|------|-----|
| `demo-web.mp4` | `https://github.com/user-attachments/assets/<uuid1>` |
| `demo-ios.mp4` | `https://github.com/user-attachments/assets/<uuid2>` |

### Phase 4: Build Manifest

Save `docs/media/media-manifest.json`:

```json
{
  "assets": {
    "demo-web.mp4": "https://github.com/user-attachments/assets/<uuid1>",
    "demo-ios.mp4": "https://github.com/user-attachments/assets/<uuid2>",
    "landing-desktop-web.png": "https://github.com/owner/repo/releases/download/media-v1/landing-desktop-web.png",
    "dashboard-desktop-web.png": "https://github.com/owner/repo/releases/download/media-v1/dashboard-desktop-web.png"
  }
}
```

Videos use `user-attachments` URLs; images can use either.

### Phase 5: Print Embeddable Snippets

```markdown
# Video (inline playback — user-attachments URL)
<video src="https://github.com/user-attachments/assets/<uuid>" controls width="640"></video>

# Video (clickable badge — Release URL)
[![Play Video](https://img.shields.io/badge/▶-Play-blue?style=for-the-badge)](URL)

# Image (inline + clickable)
[![Landing Page](URL)](URL)
```

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
[![Landing Page](URL)](URL)
```

### Gallery Grid (2-column)

```markdown
| | |
|---|---|
| [![Landing](URL1)](URL1) | [![Dashboard](URL2)](URL2) |
| *Landing page* | *Dashboard view* |
```

## Dependencies

| Tool | Required | Install |
|------|----------|---------|
| `gh` CLI | Yes | `brew install gh` |
| GitHub auth | Yes | `gh auth login` |
| `docs/media/` | Yes | Created by `record-app` |
| Browser | For videos | Open GitHub issue/PR in browser |

## Edge Cases

- **No videos in media directory** → can use `gh release upload` for images only
- **Private repos** → `user-attachments` URLs inherit repo visibility (stay private)
- **Instructions unclear** → "Open any issue in the repo, drag the video into the comment box, copy the URL that appears"
