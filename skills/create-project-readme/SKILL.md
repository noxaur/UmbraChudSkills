---
name: create-project-readme
description: Analyze a codebase and generate a comprehensive README.md with embedded screenshots, GIFs, and demo videos. Automatically captures visual media via the record-app skill for any platform (web, iOS, Android, macOS, Windows, Linux). Uses GitHub Releases asset URLs for inline video playback and clickable image enlargement. Use when asked to create a readme, document a project, generate project documentation, or write a README.md.
license: MIT
---

# Create Project README

Analyze a codebase, capture visual media, publish to GitHub Releases, and generate a comprehensive README.md with inline video playback and clickable images.

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

- **Platforms to record:** [auto-detected list, e.g., Web, iOS, Android]
  (Select which to include, or "all")

- **Animation style:**
  - Professional (clean fades, slow zooms)
  - Energetic (quick cuts, dynamic pans)
  - Minimal (no effects, straight cuts)

- **Scenes to include:** [auto-detected list of key screens]
  (Select which to include, or "all")

- **Video length target:** 30s, 45s, or 60s

- **Background music:**
  - Want background music for the demo video? I can add **Beethoven** (default), **jazz**, **lo-fi**, **ambient**, or **none**.
```

**If the user doesn't respond to any question** — use these defaults:
- Video: yes
- Platforms: all detected
- Animation style: professional
- Scenes: all auto-detected key screens
- Length: 45s
- Music: Beethoven (Sonata No. 32 at 15% volume)

### Phase 1: Analyze Codebase

1. **Read project structure** — `ls`, `package.json`, `pyproject.toml`, `Cargo.toml`, `build.gradle`, etc.
2. **Detect tech stack** — framework, language, dependencies, build tools.
3. **Identify entry points** — main files, routes, screens, views.
4. **Read existing docs** — if a README already exists, note what's there and what's missing.

### Phase 2: Detect Project Type & Capture Media

**If the project is web-based** (React, Next.js, Vue, Svelte, Express, Django, etc.):
- Invoke the `record-app` skill to capture media.
- The `record-app` skill will:
  - Start the dev server
  - Navigate to key pages
  - Capture screenshots, apply smooth animations, and stitch into a demo video
  - Save to `docs/media/demo-web.mp4` (and `demo-web-mobile.mp4` for mobile viewport)
  - Publish to GitHub Releases via `media-publisher` skill

**If the project is a native application** (iOS, Android, macOS, Windows, Linux):
- Invoke the `record-app` skill to capture media.
- The `record-app` skill will:
  - Detect the platform and launch the app
  - Capture key screens with smooth animations
  - Stitch into a demo video per platform
  - Save to `docs/media/demo-{platform}.mp4`
  - Publish to GitHub Releases via `media-publisher` skill

**If the project has no UI** (CLI tool, library, API-only):
- Skip media capture.
- Use code examples, terminal output, and ASCII diagrams instead.

**If the project is multi-platform** (e.g., React Native + web admin, Electron):
- Run `record-app` for each selected platform.
- Embed all demo videos in the README, grouped by platform.

### Phase 3: Resolve Media URLs

Check for `docs/media/media-manifest.json` (created by `media-publisher`):

**If manifest exists:**
- Read all asset URLs from the manifest
- Check URL type:
  - **user-attachments URLs** → Use `<video>` tags for inline playback
  - **Release URLs** → Use clickable badges (no inline video)
- Images always use `[![Name](URL)](URL)` format (clickable, full resolution)

**If manifest does NOT exist:**
- Fall back to local paths (`docs/media/...`)
- Note in README: "Run `record-app` and publish to GitHub to enable inline media"

### Phase 4: Generate Media Gallery

Use release asset URLs for clickable images that open at full resolution:

```markdown
## Screenshots

| | |
|---|---|
| [![Landing](RELEASE_URL/landing-desktop-web.png?width=400)](RELEASE_URL/landing-desktop-web.png) | [![Dashboard](RELEASE_URL/dashboard-desktop-web.png?width=400)](RELEASE_URL/dashboard-desktop-web.png) |
| *Landing page* | *Dashboard view* |
| [![Settings](RELEASE_URL/settings-desktop-web.png?width=400)](RELEASE_URL/settings-desktop-web.png) | [![Mobile View](RELEASE_URL/landing-mobile-web.png?width=400)](RELEASE_URL/landing-mobile-web.png) |
| *Settings panel* | *Mobile landing* |
```

**Rules for the gallery:**
- Maximum 6 images per platform (pick the most important screens)
- Use release URLs for full-resolution access
- Each image has a one-line caption below it
- Group galleries by platform for multi-platform projects
- If only 1-2 images, skip the table and embed directly
- Images are clickable — opens full resolution in new tab

### Phase 5: Generate README.md

Create a structured README with these sections:

```markdown
# Project Name

> Short tagline describing what the project does.

## Demo

<video src="RELEASE_URL/demo-web.mp4" controls width="640"></video>

## Screenshots

[Media gallery table from Phase 4]

## Features

- Feature 1 with brief description
- Feature 2 with brief description
- Feature 3 with brief description

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

## Project Structure

\`\`\`
[src/ tree visualization]
\`\`\`

## Available Scripts

| Command | Description |
|---------|-------------|
| \`npm run dev\` | Start development server |
| \`npm run build\` | Build for production |

## Configuration

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

This project is licensed under the [LICENSE] License.
```

## Guidelines

- **Use GFM** (GitHub Flavored Markdown) — tables, code blocks, admonitions.
- **Keep it concise** — no section should exceed what's necessary.
- **No emojis overload** — use sparingly for visual breaks.
- **No LICENSE/CONTRIBUTING/CHANGELOG sections** — reference the separate files.
- **Always prefer URLs** from `media-manifest.json` over local paths.
- **If logo/icon exists** — use it in the header.
- **Match project tone** — formal for enterprise, casual for open source.
- **Always ask about media preferences** before capturing.

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
