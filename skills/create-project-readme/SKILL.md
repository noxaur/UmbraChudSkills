---
name: create-project-readme
description: Analyze a codebase and generate a comprehensive README.md with embedded screenshots, GIFs, and demo videos. Automatically captures visual media via the record-app skill for any platform (web, iOS, Android, macOS, Windows, Linux). Uses user-attachments URLs for inline video playback when available, falling back to Release URLs for clickable media. Use when asked to create a readme, document a project, generate project documentation, or write a README.md.
license: MIT
---

# Create Project README

Analyze a codebase, capture visual media, publish to GitHub via media-publisher, and generate a comprehensive README.md with inline video playback and clickable images.

## Workflow

### Phase 0: Ask User About Media Preferences

Before capturing anything, ask the user:

```
I can create a README with visual media. What would you like?

1. **Demo video** — A polished demo video with smooth animations and transitions
2. **Screenshot gallery** — A grid of screenshots (no video)
3. **Both** — Demo video + screenshot gallery
4. **No media** — Text-only README

Which would you prefer?
```

**If the user chooses 1 or 3 (video):** Ask follow-up options:

```
Great! A few options:

- **Animation style:**
  - Professional (clean fades, slow zooms)
  - Energetic (quick cuts, dynamic pans)
  - Minimal (no effects, straight cuts)

- **Video length target:** 30s, 45s, or 60s

- **Background music:**
  - Want background music for the demo video? I can add **Beethoven**, **smooth-jazz**, **lofi-beat**, **ambient**, or **none**.
```

**If the user doesn't respond to any question** — use these defaults:
- Video: yes
- Animation style: professional
- Length: 30s
- Music: none (conservative fallback when user doesn't respond)

**After Phase 1 (Analyze Codebase) completes**, present the auto-detected platforms and scenes for confirmation:

```
I detected these platforms: [list]
Key screens/routes: [list]
Include all, or select which to record?
```

### Phase 1: Analyze Codebase

1. **Read project structure** — `ls`, `package.json`, `pyproject.toml`, `Cargo.toml`, `build.gradle`, etc.
2. **Detect tech stack** — framework, language, dependencies, build tools.
3. **Identify entry points** — main files, routes, screens, views.
4. **Read existing docs** — if a README already exists, note what's there and what's missing.

### Phase 2: Detect Project Type & Capture Media

**Detection priority** (check in order, first match wins):
1. Multiple distinct platforms (e.g., `react-native` + `next.js`, Electron + web) → multi-platform
2. Desktop-only indicators → native (desktop)
   - **Electron**: `electron-builder.yml`, `electron` in devDependencies
   - **Tauri**: `tauri.conf.json`
   - **Flutter Desktop**: `pubspec.yaml` + `macos/` or `windows/` or `linux/` directory
3. Mobile/shared frameworks → native
   - **React Native**: `react-native` in dependencies
   - **Flutter (mobile)**: `pubspec.yaml` without desktop platform directories
   - **SwiftUI**, **Kotlin**, **Android XML**: platform-specific files
4. Web frameworks (React, Next.js, Vue, Svelte, Express, Django, Rails) → web
5. No UI framework found → no-UI (CLI/library/API)

**If the project is web-based** (React, Next.js, Vue, Svelte, Express, Django, etc.):
- Invoke the `record-app` skill to capture media.
- The `record-app` skill will:
  - Start the dev server
  - Navigate to key pages
  - Capture screenshots and record demo video
  - Save to `docs/media/demo-web.mp4` (and `demo-web-mobile.mp4` for mobile viewport)
- Invoke the `media-publisher` skill to guide the user through publishing media to GitHub.
  - Images can be auto-uploaded via `gh release upload`
  - Videos require manual drag-and-drop into a GitHub issue (browser) to get `user-attachments` URLs for inline playback
- If `record-app` fails (dev server won't start, pages error), fall back to static screenshots. If those also fail, proceed with text-only README.

**If the project is a native application** (iOS, Android, macOS, Windows, Linux):
- Invoke the `record-app` skill to capture media.
- The `record-app` skill will:
  - Detect the platform and launch the app
  - Capture key screens and record demo video
  - Save to `docs/media/demo-{platform}.mp4`
- Invoke the `media-publisher` skill to guide the user through publishing media to GitHub.
  - Images can be auto-uploaded via `gh release upload`
  - Videos require manual drag-and-drop into a GitHub issue (browser) to get `user-attachments` URLs for inline playback
- If `record-app` fails (app won't launch, simulator unavailable), proceed with text-only README.

**If the project has no UI** (CLI tool, library, API-only):
- Skip media capture.
- Use code examples, terminal output, and ASCII diagrams instead.

**If the project is multi-platform** (e.g., React Native + web admin, Electron):
- Run `record-app` for each selected platform.
- Embed all demo videos in the README, grouped by platform.

**If README.md already exists:**
- Ask: overwrite, merge into existing, or create as `README.generated.md`?
- Default: create `README.generated.md` to avoid data loss.

### Phase 3: Resolve Media URLs

Check for `docs/media/media-manifest.json` (created manually or via `media-publisher`):

**If manifest exists:**
- Read all asset URLs from the manifest
- Validate manifest structure (must have `assets` map with at least one entry)
- Check URL type for each asset:
  - **user-attachments URLs** → Use `<video>` tags for inline playback
  - **Release URLs** → Use clickable badges (no inline video)
- Images always use `[![Name](URL)](URL)` format (clickable, full resolution)
- If >50% of URLs are valid (return 200) → use manifest
- If <50% valid → fall back to local paths with warning

**If manifest does NOT exist:**
- Show the user the captured files and explain:
  - Videos need `user-attachments` URLs for inline playback
  - Ask the user to drag videos into a GitHub issue/PR comment and provide the generated URLs
  - For images, offer to run `gh release upload` for clickable Release URLs
- Once URLs are collected, construct the manifest manually
- If the user declines or can't provide URLs, fall back to local paths (`docs/media/...`)
- Note in README: "Upload videos to a GitHub issue comment and paste the URLs to enable inline playback"

**If `gh` CLI is not available:**
- Skip image upload entirely
- Use local paths in the generated README

### Phase 4: Generate Media Gallery

Use asset URLs for clickable images that open at full resolution:

```markdown
## Screenshots

| | |
|---|---|
| <a href="URL/landing-desktop-web.png"><img src="URL/landing-desktop-web.png" width="400" alt="Landing"></a> | <a href="URL/dashboard-desktop-web.png"><img src="URL/dashboard-desktop-web.png" width="400" alt="Dashboard"></a> |
| *Landing page* | *Dashboard view* |
| <a href="URL/settings-desktop-web.png"><img src="URL/settings-desktop-web.png" width="400" alt="Settings"></a> | <a href="URL/landing-mobile-web.png"><img src="URL/landing-mobile-web.png" width="400" alt="Mobile View"></a> |
| *Settings panel* | *Mobile landing* |
```

**Rules for the gallery:**
- Maximum 6 images per platform (pick the most important screens)
- Prefer user-attachments URLs when available; fall back to Release URLs
- Each image has a one-line caption below it (italic)
- Group galleries by platform for multi-platform projects
- If only 1-2 images, skip the table and embed directly
- Images are clickable — opens full resolution in new tab

### Phase 5: Generate README.md

Create a structured README with these sections. Include sections only if applicable to the project. After generating, load the `humanize-writing` skill and run all 8 editing passes on the generated content to remove AI writing patterns before writing the final file.

```markdown
# Project Name

> Short tagline describing what the project does.

[Optional: Badges — build status, version, license, coverage if CI/CD config exists]

[Optional: Table of Contents — if README > 80 lines after generation]

## Demo

<video src="URL/demo-web.mp4" controls width="640"></video>

## Screenshots

[Media gallery table from Phase 4]

## Getting Started

### Prerequisites

- [List required software, versions]

### Installation

\`\`\`bash
[Install commands]
\`\`\`

### Usage

\`\`\`bash
[Run commands]
\`\`\`

[Optional: Testing — if test files or test scripts exist]
\`\`\`bash
[Test commands]
\`\`\`

## Features

- Feature 1 with brief description
- Feature 2 with brief description
- Feature 3 with brief description

## About

[Optional: Brief explanation of the project's motivation and why it exists.]

## Project Structure

\`\`\`
[src/ tree visualization]
\`\`\`

[Optional: Available Scripts — only if npm/yarn/pnpm/bun detected]

| Command | Description |
|---------|-------------|
| \`npm run dev\` | Start development server |
| \`npm run build\` | Build for production |

[Optional: Configuration — if .env.example or config files exist]

| Variable | Description | Default |
|----------|-------------|---------|
| \`DATABASE_URL\` | Connection string | - |

## Tech Stack

- **Framework:** [name + version]
- **Language:** [name]
- **Database:** [name]
- **Deployment:** [platform]

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
```

## Guidelines

- **Use GFM** (GitHub Flavored Markdown) — tables, code blocks, admonitions.
- **Keep it concise** — no section should exceed what's necessary.
- **No emojis overload** — max 3 per section, use sparingly for visual breaks.
- **No LICENSE/CONTRIBUTING/CHANGELOG sections** — reference the separate files.
- **Always prefer URLs** from `media-manifest.json` over local paths.
- **If logo/icon exists** — use it in the header.
- **Match project tone** — formal for enterprise (strict types, CI/CD), casual for open source (MIT, informal commits).
- **Always ask about media preferences** before capturing.
- **Include descriptive alt text** on images — not just file names.
- **Auto-detect package manager** — use `npm`, `yarn`, `pnpm`, or `bun` based on lockfile.

## Media Embedding

### Video with user-attachments URL (inline playback in README)

```html
<video src="https://github.com/user-attachments/assets/UUID" controls width="640"></video>
```

### Video with Release URL (clickable badge — no inline playback)

```markdown
[![Play Video](https://img.shields.io/badge/▶-Play-blue?style=for-the-badge)](https://github.com/owner/repo/releases/download/media-v2/demo-web.mp4)
```

**Important:** GitHub README only renders `<video>` tags with `user-attachments` URLs. Release URLs show as clickable links only.

### Image (clickable, opens full resolution)

```markdown
[![Landing Page](https://github.com/user-attachments/assets/UUID)](https://github.com/user-attachments/assets/UUID)
```

### Gallery (2-column table with clickable images)

```markdown
| | |
|---|---|
| [![Scene 1](URL/scene1.png)](URL/scene1.png) | [![Scene 2](URL/scene2.png)](URL/scene2.png) |
| *Caption 1* | *Caption 2* |
```

### Multi-platform (grouped by platform)

```markdown
## Demo

### Web
<video src="URL/demo-web.mp4" controls width="640"></video>

### iOS
<video src="URL/demo-ios.mp4" controls width="640"></video>

### Android
<video src="URL/demo-android.mp4" controls width="640"></video>
```

### Fallback (no published URLs available)

If `media-manifest.json` doesn't exist, use local paths with a note:

```markdown
> 📹 Run `record-app` and publish media to enable inline video playback.
```
