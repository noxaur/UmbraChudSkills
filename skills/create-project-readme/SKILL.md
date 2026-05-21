---
name: create-project-readme
description: Analyze a codebase and generate a comprehensive README.md with embedded screenshots, GIFs, and demo videos. Automatically captures visual media via the record-app skill for any platform (web, iOS, Android, macOS, Windows, Linux). Use when asked to create a readme, document a project, generate project documentation, or write a README.md.
license: MIT
---

# Create Project README

Analyze a codebase, capture visual media, and generate a comprehensive, well-structured README.md.

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
```

**If the user doesn't respond to any question** — use these defaults:
- Video: yes
- Platforms: all detected
- Animation style: professional
- Scenes: all auto-detected key screens
- Length: 45s

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
  - Save to `docs/media/demo-web.webm` (and `demo-web-mobile.webm` for mobile viewport)

**If the project is a native application** (iOS, Android, macOS, Windows, Linux):
- Invoke the `record-app` skill to capture media.
- The `record-app` skill will:
  - Detect the platform and launch the app
  - Capture key screens with smooth animations
  - Stitch into a demo video per platform
  - Save to `docs/media/demo-{platform}.webm`

**If the project has no UI** (CLI tool, library, API-only):
- Skip media capture.
- Use code examples, terminal output, and ASCII diagrams instead.

**If the project is multi-platform** (e.g., React Native + web admin, Electron):
- Run `record-app` for each selected platform.
- Embed all demo videos in the README, grouped by platform.

### Phase 3: Generate Media Gallery

Instead of embedding large images inline, create a compact gallery using a 2-column table layout:

```markdown
## Screenshots

| | |
|---|---|
| ![Landing](docs/media/landing-desktop-web.png) | ![Dashboard](docs/media/dashboard-desktop-web.png) |
| *Landing page* | *Dashboard view* |
| ![Settings](docs/media/settings-desktop-web.png) | ![Mobile View](docs/media/landing-mobile-web.png) |
| *Settings panel* | *Mobile landing* |
```

**Rules for the gallery:**
- Maximum 6 images per platform (pick the most important screens)
- Resize images to max 400px width before embedding (use `sips` on macOS, `convert` on Linux, or skip if not available)
- Each image has a one-line caption below it
- Group galleries by platform for multi-platform projects
- If only 1-2 images, skip the table and embed directly

### Phase 4: Generate README.md

Create a structured README with these sections:

```markdown
# Project Name

> Short tagline describing what the project does.

## Demo

[Embedded video from docs/media/]

## Screenshots

[Media gallery table from Phase 3]

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
- **Embed media with relative paths** — `docs/media/demo-web.webm`.
- **If logo/icon exists** — use it in the header.
- **Match project tone** — formal for enterprise, casual for open source.
- **Always ask about media preferences** before capturing.

## Media Embedding

For webm videos in GitHub markdown:

```markdown
<video src="docs/media/demo-web.webm" controls width="640"></video>
```

For the media gallery (2-column table):

```markdown
| | |
|---|---|
| ![Scene 1](docs/media/scene1.png) | ![Scene 2](docs/media/scene2.png) |
| *Caption 1* | *Caption 2* |
```

For multi-platform projects, group media by platform:

```markdown
## Demo

### Web
<video src="docs/media/demo-web.webm" controls width="640"></video>

### iOS
<video src="docs/media/demo-ios.webm" controls width="640"></video>

### Android
<video src="docs/media/demo-android.webm" controls width="640"></video>
```
