# UmbraChud Skills

A curated collection of OpenCode skills for codebase auditing, issue resolution, visual recording, and project documentation.

[![skills.sh](https://skills.sh/b/noxaur/UmbraChudSkills)](https://skills.sh/noxaur/UmbraChudSkills)

## Skills

| Skill | Description |
|-------|-------------|
| [`codebase-auditor`](skills/codebase-auditor/) | Analyze a codebase for bugs, security, performance, and architecture issues. Verifies each issue by reproducing it, creates GitHub issues, then uses the triage skill to review, label, and comment. |
| [`issue-resolver`](skills/issue-resolver/) | Receive, reproduce, fix, and submit PRs for GitHub issues. Uses TDD, verification before completion, and subagent-driven development for large tasks. |
| [`record-app`](skills/record-app/) | Capture screenshots and videos of any application — web, iOS, Android, macOS, Windows, or Linux. Stitches clips into a polished demo video with optional background music (default: Beethoven). |
| [`media-publisher`](skills/media-publisher/) | Publish media assets to GitHub for inline embedding. Uses user-attachments URLs for inline video playback, falls back to GitHub Releases for clickable links. Creates cumulative versioned releases (media-v1, media-v2, ...). |
| [`create-project-readme`](skills/create-project-readme/) | Analyze a codebase and generate a comprehensive README.md with embedded screenshots, GIFs, and demo videos. Uses user-attachments URLs for inline playback. |
| [`media-editor`](skills/media-editor/) | Edit, enhance, and post-process demo videos and images. Trim, add music, watermark, resize, color-correct, and more. |
| [`karpathy-guidelines`](skills/karpathy-guidelines/) | Behavioral guidelines to reduce common LLM coding mistakes. Think before coding, simplicity first, surgical changes, goal-driven execution. |

## Installation

### Via skills.sh

```bash
npx skills add noxaur/UmbraChudSkills
```

### Global Install (all skills)

Copy the `skills/` directory to your global OpenCode skills path:

```bash
cp -r skills/* ~/.config/opencode/skills/
```

### Individual Install

```bash
cp -r skills/<skill-name> ~/.config/opencode/skills/
```

Restart OpenCode after installing.

## Adding New Skills

To add a new skill to this collection:

1. Create a new directory under `skills/<skill-name>/`
2. Add a `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: Brief description. Use when [specific triggers].
   license: MIT
   ---
   ```
3. Add any supporting files (scripts, reference docs, etc.)
4. Update this README's skills table

## Test Agents

Test agents are OpenCode subagents that verify skills work correctly. Install them to `~/.config/opencode/agents/`:

```bash
cp agents/*.md ~/.config/opencode/agents/
```

| Agent | Tests |
|-------|-------|
| [`test-orchestrator`](agents/test-orchestrator.md) | Runs all test agents in parallel and compiles a master report |
| [`test-record-app`](agents/test-record-app.md) | Screenshots, MP4 output, aspect ratio, gallery images, background music |
| [`test-media-editor`](agents/test-media-editor.md) | Trim, watermark, resize, format conversion, fade effects |
| [`test-media-publisher`](agents/test-media-publisher.md) | GitHub Releases, asset URLs, versioning, cumulative uploads |
| [`test-codebase-auditor`](agents/test-codebase-auditor.md) | SQL injection, XSS, hardcoded secrets, N+1 queries, error handling |
| [`test-issue-resolver`](agents/test-issue-resolver.md) | TDD workflow, PR creation, issue linking, acceptance criteria |
| [`test-create-project-readme`](agents/test-create-project-readme.md) | Codebase analysis, README generation, accuracy, media capture |

### Run All Tests

Invoke the orchestrator in OpenCode:

```
@test-orchestrator run all skill tests
```

It will launch 6 parallel test subagents, collect results, and save a `TEST-REPORT.md`.

## Structure

```
skills/
├── codebase-auditor/
│   ├── SKILL.md
│   └── REFERENCE.md
├── create-project-readme/
│   └── SKILL.md
├── issue-resolver/
│   └── SKILL.md
├── karpathy-guidelines/
│   └── SKILL.md
├── media-editor/
│   └── SKILL.md
├── media-publisher/
│   ├── SKILL.md
│   └── scripts/
│       └── publish-media.sh
└── record-app/
    ├── SKILL.md
    ├── music/
    │   ├── beethoven-sonata-1.mp3
    │   ├── beethoven-sonata-15.mp3
    │   ├── beethoven-sonata-22.mp3
    │   └── beethoven-sonata-32.mp3
    └── scripts/
        ├── capture-web.js
        ├── capture-ios.sh
        ├── capture-android.sh
        ├── capture-macos.sh
        ├── capture-windows.ps1
        ├── capture-linux.sh
        └── resize-images.sh

docs/media/                         # Generated at runtime by record-app + media-publisher
├── demo-web.mp4
├── landing-desktop-web.png
├── dashboard-desktop-web.png
└── media-manifest.json

agents/
├── test-orchestrator.md
├── test-record-app.md
├── test-media-editor.md
├── test-codebase-auditor.md
├── test-issue-resolver.md
└── test-create-project-readme.md
```

## License

MIT
