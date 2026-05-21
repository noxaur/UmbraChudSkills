---
name: media-editor
description: Edit, enhance, and post-process demo videos and images. Use when asked to edit demo videos, add music, trim clips, adjust quality, add watermarks, overlay text, crop videos, resize images, color-correct, or modify any visual media in docs/media/.
license: MIT
---

# Media Editor

Edit and enhance demo videos and images produced by `record-app` or any other source.

## Capabilities

### Video Editing
| Operation | ffmpeg Command Pattern |
|-----------|----------------------|
| Trim/cut | `-ss <start> -to <end> -i input.mp4 -c copy output.mp4` |
| Add/replace music | `-i video.mp4 -i music.mp3 -filter_complex "[1:a]volume=0.15[a];[0:a][a]amix"` |
| Adjust volume | `-filter:a "volume=1.5"` |
| Speed up/slow down | `-filter:v "setpts=0.5*PTS" -filter:a "atempo=2.0"` |
| Add watermark | `-i video.mp4 -i logo.png -filter_complex "overlay=10:10"` |
| Overlay text | `-vf "drawtext=text='Title':fontsize=24:fontcolor=white:x=10:y=10"` |
| Crop | `-vf "crop=w:h:x:y"` |
| Resize (preserve AR) | `-vf "scale=-2:720"` or `-vf "scale=1280:-2"` |
| Concatenate | `-f concat -safe 0 -i list.txt -c copy output.mp4` |
| Change format | `-i input.webm -c:v libx264 -crf 18 output.mp4` |
| Color correct | `-vf "eq=contrast=1.1:brightness=0.05:saturation=1.2"` |
| Add fade in/out | `-vf "fade=t=in:st=0:d=1,fade=t=out:st=<end-1>:d=1"` |
| Add transitions | `xfade=transition=<type>:duration=0.5:offset=<time>` |

### Image Editing
| Operation | Command |
|-----------|---------|
| Resize (preserve AR) | `sips -Z 1200 input.png --out output.png` or `ffmpeg -i input.png -vf "scale=-2:720" output.png` |
| Crop | `sips -c <height> <width> input.png --out output.png` |
| Convert format | `ffmpeg -i input.png output.jpg` |
| Add border | `ffmpeg -i input.png -vf "pad=iw+20:ih+20:10:10:black" output.png` |
| Overlay text | `ffmpeg -i input.png -vf "drawtext=text='Label':fontsize=20:fontcolor=white:x=10:y=10" output.png` |
| Adjust quality | `ffmpeg -i input.png -q:v 2 output.png` |
| Composite | `ffmpeg -i bg.png -i overlay.png -filter_complex "overlay=x:y" output.png` |

## Workflow

### Phase 1: Understand Request

Parse the user's edit request into specific operations:
- What files to edit? (scan `docs/media/` or ask)
- What operations? (trim, add music, resize, watermark, etc.)
- Output format? (default: MP4 for video, PNG for images)
- Quality settings? (default: CRF 18 for video, q:v 2 for images)

**If adding music, ask the user:**
- "Want background music? I can add **Beethoven** (default), **jazz**, **lo-fi**, **ambient**, or **none**."
- If user doesn't respond → default to **Beethoven** (Sonata No. 32 at 15% volume)

### Phase 2: Verify Source Files

Check that source files exist and are valid:
```bash
ffprobe -v error -show_format -show_streams <file>
```

If files are missing or corrupted, inform the user and offer to re-capture via `record-app`.

### Phase 3: Execute Edits

Run ffmpeg/sips commands sequentially. For complex edits, build a single filter_complex chain rather than multiple passes.

**Rules:**
- Always preserve original aspect ratio unless explicitly asked to crop/stretch
- Never overwrite source files — always write to new output
- Keep quality high: CRF 18 (video), q:v 2 (images), AAC 192k (audio)
- Use `-movflags +faststart` for MP4 (web-compatible)
- For music: default 15% volume, 2s fade in/out

### Phase 4: Verify Output

Check output file:
```bash
ffprobe -v error -show_format -show_streams <output>
```

Verify:
- Duration matches expected
- Resolution is correct (aspect ratio preserved)
- Audio track exists if music was added
- File plays without errors

### Phase 5: Publish

After editing, copy edited files into `docs/media/` (alongside originals) and publish to GitHub Releases:

1. Copy edited output to `docs/media/` (preserve originals, use descriptive names like `demo-web-edited.mp4`)
2. Run `./skills/media-publisher/scripts/publish-media.sh docs/media`
3. This creates a new cumulative release (`media-vN+1`) with all files including edits
4. Saves updated `docs/media/media-manifest.json` with new URLs
5. Ask user: "Publish edited media to GitHub Releases?" (default: yes if `gh` available)

If `gh` is not available, skip this phase and inform the user.

### Phase 6: Report

Return summary of edits made with publish status:
```json
{
  "source": "docs/media/demo-web.mp4",
  "output": "docs/media/demo-web-edited.mp4",
  "edits": ["trimmed 0:00-0:30", "added jazz music", "color corrected"],
  "duration": "30s",
  "resolution": "1280x720",
  "music": "smooth-jazz.mp3 (15% volume)",
  "published": true,
  "release_tag": "media-v2",
  "asset_url": "https://github.com/owner/repo/releases/download/media-v2/demo-web-edited.mp4"
}
```

## Music Library

Background music files are stored in `skills/record-app/music/`:

| File | Track | Mood |
|------|-------|------|
| `beethoven-sonata-32.mp3` | Sonata No. 32 in C Minor, Op. 111 — I. Maestoso | Dramatic, classical |
| `beethoven-sonata-1.mp3` | Sonata No. 1 in F Minor, Op. 2 No. 1 — IV. Prestissimo | Energetic, intense |
| `beethoven-sonata-15.mp3` | Sonata No. 15 in D Major, Op. 28 "Pastoral" — IV. Rondo | Light, pastoral |
| `beethoven-sonata-22.mp3` | Sonata No. 22 in F Major, Op. 54 — II. Allegretto | Playful, rhythmic |

Default: `beethoven-sonata-32.mp3` at 15% volume.

## Common Recipes

### Add jazz music to existing video
```bash
ffmpeg -y -i demo.mp4 -stream_loop -1 -i smooth-jazz.mp3 \
  -filter_complex "[1:a]volume=0.15,afade=t=in:st=0:d=2,afade=t=out:st=43:d=2[aout]" \
  -map 0:v -map "[aout]" -c:v copy -c:a aac -b:a 192k -movflags +faststart demo-with-music.mp4
```

### Trim video
```bash
ffmpeg -y -i demo.mp4 -ss 00:00:05 -to 00:00:30 -c copy demo-trimmed.mp4
```

### Add watermark logo
```bash
ffmpeg -y -i demo.mp4 -i logo.png \
  -filter_complex "overlay=10:10" \
  -c:v libx264 -crf 18 -movflags +faststart demo-watermarked.mp4
```

### Convert WebM to MP4 (GitHub compatible)
```bash
ffmpeg -y -i demo.webm -c:v libx264 -crf 18 -pix_fmt yuv420p -movflags +faststart demo.mp4
```

### Resize images for gallery (preserve AR, high quality)
```bash
sips -Z 1200 input.png --out output.png
# or ffmpeg:
ffmpeg -y -i input.png -vf "scale=-2:720" -q:v 2 output.png
```

### Combine multiple videos with transitions
```bash
ffmpeg -y -i v1.mp4 -i v2.mp4 -i v3.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=fade:duration=0.5:offset=3.5[t1];[t1][2:v]xfade=transition=fade:duration=0.5:offset=7[outv]" \
  -map "[outv]" -c:v libx264 -crf 18 -movflags +faststart combined.mp4
```

## Guidelines

- **Preserve originals** — never overwrite source files
- **High quality by default** — CRF 18, q:v 2, AAC 192k
- **Aspect ratio sacred** — use `-2` for automatic dimension calculation
- **GitHub compatible** — MP4 with H.264, yuv420p, faststart
- **Inform user** — if an edit would significantly degrade quality, warn first
