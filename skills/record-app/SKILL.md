---
name: record-app
description: Capture screenshots, GIFs, and videos of any application — web, iOS, Android, macOS, Windows, or Linux. Automatically applies smooth animations and transitions, then stitches all captures into a single polished demo video. Use when asked to record an app, capture screenshots, create a demo video, or document a UI visually.
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
  output: "docs/media/demo-{platform}.webm",
  viewport: "desktop"  // or "mobile" for web
}
```

3. **Ask about creative direction** (optional):
   - "I can make this feel **professional** (clean fades, slow zooms) or **energetic** (quick cuts, dynamic pans). Which vibe?"
   - If user doesn't respond → default to **professional**

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
4. **Delete raw clips** — only the final animated video is kept
5. **Output** — single `.webm` file in `docs/media/`

### Phase 5: Report

Return a manifest of captured files:

```json
{
  "platform": "web",
  "output": "docs/media/demo-web.webm",
  "scenes": ["landing", "dashboard", "signup"],
  "duration": "45s",
  "viewport": "desktop"
}
```

## Naming Convention

All media saved to `docs/media/`:

```
docs/media/
├── demo-web.webm              # Web (desktop viewport, stitched video)
├── demo-web-mobile.webm       # Web (mobile viewport, stitched video)
├── demo-ios.webm              # iOS
├── demo-android.webm          # Android
├── demo-macos.webm            # macOS
├── demo-windows.webm          # Windows
└── demo-linux.webm            # Linux
```

## Gallery Output

In addition to the demo video, individual screenshots are saved and resized for gallery embedding:

```
docs/media/
├── landing-desktop-web.png    # Resized to 400px width
├── dashboard-desktop-web.png  # Resized to 400px width
├── settings-desktop-web.png   # Resized to 400px width
├── home-screen-ios.png        # Resized to 400px width
└── ...
```

**Resize rules:**
- Max width: 400px (maintains aspect ratio)
- Format: PNG (lossless)
- Quality: optimized for web (strip metadata, compress)
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

If a dependency is missing, the skill should inform the user and offer installation instructions.
