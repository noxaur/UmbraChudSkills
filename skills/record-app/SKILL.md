---
name: record-app
description: Capture screenshots and videos of any application — web, iOS, Android, macOS, Windows, or Linux. Stitches captured clips into a polished demo video with optional background music (default: Beethoven). Use when asked to record an app, capture screenshots, create a demo video, or document a UI visually.
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
    { path: "/", name: "landing", interactions: [
        { type: "wait", duration: 2000 },
        { type: "scroll", delta: 300 }
      ]},
    { path: "/dashboard", name: "dashboard", interactions: [
        { type: "click", selector: "[data-testid='chart']" },
        { type: "wait", duration: 1000 }
      ]},
    { path: "/signup", name: "signup", interactions: [
        { type: "fill", selector: "#email", value: "demo@example.com" },
        { type: "click", selector: "button[type='submit']" }
      ]}
  ],
  output: "docs/media/demo-{platform}.mp4",
  viewport: "desktop",  // or "mobile" for web
  music: "jazz"         // beethoven, jazz, lofi, ambient, none, or direct file path
}
```

3. **Ask about creative direction** (optional):
   - "I can make this feel **professional** (clean fades, slow zooms) or **energetic** (quick cuts, dynamic pans). Which vibe?"
   - If user doesn't respond → default to **professional**

4. **Ask about background music** (required):
   - "Want background music for the demo video? I can add **Beethoven** (default), **jazz**, **lo-fi**, **ambient**, or **none**."
   - If user doesn't respond → default to **Beethoven** (Sonata No. 32 at 15% volume)
   - Music is looped/cropped to match video duration, fades in/out over 2s

### Phase 3: Capture

Run the platform-specific capture script with the generated config.

**Web** (`capture-web.js`):
- Start dev server in background
- Launch Playwright Chromium
- For each scene: create a new browser context with `recordVideo` enabled
- Navigate to each scene, perform interactions, record the actual browser viewport
- Video size is explicitly set to match viewport (H.264 even dimensions enforced: 1280x720 desktop, 376x812 mobile)
- Capture screenshots alongside for gallery/README embedding
- All clips are stitched with ffmpeg concat demuxer (preserves native resolution, no zoompan distortion)

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

Post-process all captured clips:

1. **Stitch recorded clips** — concatenate all scene videos using ffmpeg concat demuxer
   - Native resolution preserved (no zoompan distortion from still images)
   - Each scene's actual browser viewport is recorded as video
   - Transitions are direct cuts (smooth crossfades can be added via ffmpeg if needed)

2. **Add background music** — overlay music track at 15% volume
   - Music file search: checks local `music/` dir first, then global `~/.config/opencode/skills/record-app/music/`
   - If music file not found, skip audio with warning
   - Music is looped/cropped to match video duration, fades in/out over 2s

3. **Re-encode to H.264** — final output as MP4 with:
   - CRF 18 (high quality)
   - `yuv420p` pixel format (maximum compatibility)
   - `movflags +faststart` (web-friendly)
   - **H.264 even dimensions enforced**: desktop 1280x720, mobile 376x812

4. **Create gallery images** — resize screenshots to 1200px width for README embedding

5. **Clean up** — delete raw `.webm` clips, remove `.concat-list.txt`, keep only final `.mp4` and gallery `.png` files

### Phase 5: Report

Return a manifest of captured files:

```json
{
  "platform": "web",
  "output": "docs/media/demo-web.mp4",
  "scenes": ["landing", "dashboard", "signup"],
  "duration": "45s",
  "viewport": "desktop",
  "music": "beethoven",
  "files": {
    "demo-web.mp4": "docs/media/demo-web.mp4",
    "landing-desktop-web.png": "docs/media/landing-desktop-web.png"
  }
}
```

**Note:** Publishing to GitHub is handled by the `media-publisher` skill, invoked by the orchestrator (e.g., `create-project-readme`). This skill only captures and returns file paths.

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

## Auto-Assigned Interactions

The agent automatically assigns interactions based on content type:

| Content Type | Default Interactions |
|--------------|---------------------|
| Landing / hero section | `wait` (2s) → `scroll` (show below fold) |
| Dashboard / data view | `click` (key metric) → `wait` (1s) |
| Form / signup flow | `fill` (email) → `fill` (password) → `click` (submit) |
| List / feed | `scroll` (multiple times) |
| Settings / config | `click` (key toggle) → `wait` (1s) |
| Ending / CTA | `wait` (3s, let viewer absorb) |

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
| Web | Playwright (chromium), ffmpeg (for stitching) |
| iOS | Xcode CLI tools (`xcrun`) |
| Android | `adb` (Android SDK) |
| macOS | Built-in (`screencapture`, AppleScript) |
| Windows | ffmpeg |
| Linux | ffmpeg |
| Stitching | ffmpeg (concat demuxer, H.264 encoding, audio overlay) |

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
| `smooth-jazz.mp3` | Smooth jazz background track | varies |
| `lofi-beat.mp3` | Lo-fi hip hop beat | varies |
| `ambient.mp3` | Ambient soundscape | varies |

### Music File Resolution

The script searches for music files in this order:
1. Local: `<skill-dir>/music/<filename>`
2. Global: `~/.config/opencode/skills/record-app/music/<filename>`
3. If a direct file path is provided in config, uses that directly

If no music file is found, audio is skipped with a warning.
