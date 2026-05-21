---
name: record-app
description: Capture screenshots, GIFs, and videos of any application — web, iOS, Android, macOS, Windows, or Linux. Automatically applies smooth animations and transitions, then stitches into a polished demo video with optional jazz background music. Use when asked to record an app, capture screenshots, create a demo video, or document a UI visually.
license: MIT
---

# Record App

Capture visual media of any application across all platforms, with smooth animations and transitions, outputting a single polished demo video.

## Workflow

### Phase 1: Detect Platform & App Type

Identify the project type by scanning the codebase:

| Platform | Detection Signals | Capture Script |
|----------|-------------------|----------------|
| **Web** | `package.json`, `app/`, `pages/`, `src/` with React/Vue/Svelte | `capture-web.js` |
| **iOS** | `.xcodeproj`, `.swift`, `Info.plist`, `Podfile` | `capture-ios.sh` |
| **Android** | `build.gradle`, `AndroidManifest.xml`, `app/src/main` | `capture-android.sh` |
| **macOS** | `.xcodeproj` (macOS target), `.app`, `Info.plist` | `capture-macos.sh` |
| **Windows** | `.sln`, `.csproj`, `.exe`, `package.json` (Electron) | `capture-windows.ps1` |
| **Linux** | `Makefile`, `CMakeLists.txt`, `.deb`, ELF binary, `package.json` (Electron) | `capture-linux.sh` |

For multi-platform projects (e.g., React Native + web admin, Electron cross-platform), run all applicable capture scripts.

### Phase 2: Analyze & Plan

1. **Scan for key screens** — identify the 3-5 most important screens/flows:
   - Web: route definitions (`app/`, `pages/`, router config)
   - iOS: SwiftUI `View` structs, UIKit view controllers
   - Android: `@Composable` functions, XML layouts, Activities
   - macOS: SwiftUI views, NSViewControllers
   - Windows: XAML views, WinUI components
   - Linux: GTK/Qt widgets, Electron renderer pages

2. **Define capture config** — generate a structured plan:

```js
{
  platform: "web",
  url: "http://localhost:3000",
  scenes: [
    { path: "/", name: "landing", effects: ["zoom-in", "pan-down"] },
    { path: "/dashboard", name: "dashboard", effects: ["pan-across"] },
    { path: "/signup", name: "signup", effects: ["ease-in-out"] }
  ],
  transitions: ["fade", "zoom", "fade"],
  output: "docs/media/demo-{platform}.mp4",
  viewport: "desktop"  // or "mobile" for web
}
```

3. **Ask about creative direction** (optional):
   - "I can make this feel **professional** (clean fades, slow zooms) or **energetic** (quick cuts, dynamic pans). Which vibe?"
   - If user doesn't respond → default to **professional**

4. **Ask about background music** (optional):
   - "Want background music? I can add **Beethoven** (default), **jazz**, **lo-fi**, **ambient**, or **none**."
   - If user doesn't respond → default to **Beethoven** (Sonata No. 32 at 15% volume)
   - Music is looped/cropped to match video duration, fades in/out over 2s

### Phase 3: Capture

Run the platform-specific capture script with the generated config.

**Web** (`capture-web.js`):
- Start dev server in background
- Launch Playwright Chromium
- Navigate to each scene, capture raw clips
- Apply interaction steps (clicks, fills, navigations)

**iOS** (`capture-ios.sh`):
- Launch app in Simulator or on connected device
- Use `xcrun simctl io` for screen recording
- Automate taps/fills via `xcrun simctl` or accessibility

**Android** (`capture-android.sh`):
- Launch app in emulator or on connected device
- Use `adb shell screenrecord` for video
- Automate taps/fills via `adb shell input`

**macOS** (`capture-macos.sh`):
- Launch app via `open` or `xcodebuild`
- Use QuickTime/AppleScript for screen recording
- Automate clicks via `cliclick` or AppleScript

**Windows** (`capture-windows.ps1`):
- Launch app via PowerShell
- Use ffmpeg gdigrab for screen recording
- Automate clicks via PowerShell `SendKeys`

**Linux** (`capture-linux.sh`):
- Launch app via shell
- Use ffmpeg x11grab (X11) or wf-recorder (Wayland)
- Automate clicks via `xdotool`

### Phase 4: Animate & Stitch

Run `animate.js` to post-process all captured clips:

1. **Apply per-scene effects**:
   - `zoom-in` — gradual zoom to focus on key element
   - `zoom-out` — zoom out to show full context
   - `pan-down` — vertical pan (scrolling lists, dashboards)
   - `pan-across` — horizontal pan (wide content, tables)
   - `ken-burns` — slow pan + zoom combo for static scenes
   - `ease-in-out` — smoothed interaction timing

2. **Add transitions between scenes**:
   - `fade` — soft crossfade (default for professional)
   - `slide` — directional slide (energetic)
   - `zoom` — zoom transition between scenes

3. **Stitch into single video** — concatenate all processed scenes with transitions
4. **Add background music** — overlay smooth jazz track at 15% volume (ask user for genre preference; default: jazz)
5. **Delete raw clips** — only the final animated video is kept
6. **Output** — single `.mp4` file (H.264, high quality, original aspect ratio preserved) in `docs/media/`

**Encoding rules:**
- Format: MP4 (H.264 codec, compatible with GitHub)
- CRF: 18 (high quality)
- Aspect ratio: preserve original — use `scale=-2:height` or `scale=width:-2` to maintain even dimensions
- Audio: AAC, 192kbps
- Never stretch or squash — always pad with black bars if needed

### Phase 5: Publish

Run `publish-media.sh` from the `media-publisher` skill to upload all media to GitHub:

1. Check `gh` CLI is available and authenticated
2. Run `./skills/media-publisher/scripts/publish-media.sh docs/media`
3. The script auto-detects the best upload method:
   - **gh-image** → `user-attachments` URLs (inline video playback in README)
   - **gh-attach** → `user-attachments` URLs (inline video playback)
   - **gitshot** → Release assets (clickable thumbnails)
   - **gh release** → Release assets (clickable thumbnails, fallback)
4. Saves `docs/media/media-manifest.json` with asset URLs
5. Ask user: "Publish media to GitHub for inline embedding?" (default: yes if `gh` available)

If `gh` is not available, skip this phase and inform the user.
If no `gh-image` or `gh-attach` is installed, inform the user that inline video requires one of these:
```bash
gh extension install drogers0/gh-image
```

### Phase 6: Report

Return a manifest of captured files with embeddable URLs (if published):

```json
{
  "platform": "web",
  "output": "docs/media/demo-web.mp4",
  "scenes": ["landing", "dashboard", "signup"],
  "duration": "45s",
  "viewport": "desktop",
  "music": "beethoven",
  "published": true,
  "upload_method": "gh-image",
  "embed_urls": {
    "demo-web.mp4": "https://github.com/user-attachments/assets/UUID",
    "landing-desktop-web.png": "https://github.com/user-attachments/assets/UUID"
  }
}
```

## Naming Convention

All media saved to `docs/media/`:

```
docs/media/
├── demo-web.mp4               # Web (desktop viewport, stitched video)
├── demo-web-mobile.mp4        # Web (mobile viewport, stitched video)
├── demo-ios.mp4               # iOS
├── demo-android.mp4           # Android
├── demo-macos.mp4             # macOS
├── demo-windows.mp4           # Windows
└── demo-linux.mp4             # Linux
```

## Gallery Output

In addition to the demo video, individual screenshots are saved and resized for gallery embedding:

```
docs/media/
├── landing-desktop-web.png    # Resized to 1200px width
├── dashboard-desktop-web.png  # Resized to 1200px width
├── settings-desktop-web.png   # Resized to 1200px width
├── home-screen-ios.png        # Resized to 1200px width
└── ...
```

**Resize rules:**
- Max width: 1200px (maintains aspect ratio)
- Format: PNG (lossless)
- Quality: high quality, minimal compression
- If resize tool unavailable, save original with warning

## Auto-Assigned Effects

The agent automatically assigns effects based on content type:

| Content Type | Default Effects |
|--------------|-----------------|
| Landing / hero section | `zoom-in` → `pan-down` |
| Dashboard / data view | `pan-across` → `zoom-in` on key metric |
| Form / signup flow | `ease-in-out` on each interaction |
| List / feed | `pan-down` (scrolling effect) |
| Settings / config | `zoom-in` on key toggle |
| Ending / CTA | `zoom-out` → `fade` |

## Guidelines

- **One video per platform** — all scenes stitched together with smooth transitions
- **Only the final animated version** — raw clips are deleted after processing
- **Ask about creative direction** — professional vs energetic, but default to professional if user doesn't respond
- **Keep it concise** — target 30-60 seconds total
- **Respect the app** — don't modify app state permanently (use demo/test accounts)
- **Handle errors gracefully** — if a scene fails to capture, skip it and continue

## Dependencies

| Platform | Required Tools |
|----------|---------------|
| Web | Playwright (chromium) |
| iOS | Xcode CLI tools (`xcrun`) |
| Android | `adb` (Android SDK) |
| macOS | Built-in (`screencapture`, AppleScript) |
| Windows | ffmpeg |
| Linux | ffmpeg |
| Animations | ffmpeg (all platforms) |
| Music | ffmpeg (audio overlay) |
| Publish | `gh` CLI + `gh-image` (for inline video) |

If a dependency is missing, the skill should inform the user and offer installation instructions.

## Background Music

**Always ask the user before adding music:**
- "Want background music? I can add **Beethoven** (default), **jazz**, **lo-fi**, **ambient**, or **none**."
- If user doesn't respond → default to **Beethoven** (Sonata No. 32 at 15% volume)
- Music is looped/cropped to match video duration
- Volume: 15% of original audio (ducked so UI sounds remain audible)
- Fades in over first 2s, fades out over last 2s

### Available Tracks

| File | Track | Duration |
|------|-------|----------|
| `beethoven-sonata-32.mp3` | Sonata No. 32 in C Minor, Op. 111 — I. Maestoso | ~12 min |
| `beethoven-sonata-1.mp3` | Sonata No. 1 in F Minor, Op. 2 No. 1 — IV. Prestissimo | ~4 min |
| `beethoven-sonata-15.mp3` | Sonata No. 15 in D Major, Op. 28 "Pastoral" — IV. Rondo | ~6 min |
| `beethoven-sonata-22.mp3` | Sonata No. 22 in F Major, Op. 54 — II. Allegretto | ~8 min |
