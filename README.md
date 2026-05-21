# UmbraChud Skills

A curated collection of OpenCode skills for codebase auditing, issue resolution, visual recording, and project documentation.

[![skills.sh](https://skills.sh/b/noxaur/UmbraChudSkills)](https://skills.sh/noxaur/UmbraChudSkills)

## Skills

| Skill | Description |
|-------|-------------|
| [`codebase-auditor`](skills/codebase-auditor/) | Analyze a codebase for bugs, security, performance, and architecture issues. Verifies each issue by reproducing it, creates GitHub issues, then uses the triage skill to review, label, and comment. |
| [`issue-resolver`](skills/issue-resolver/) | Receive, reproduce, fix, and submit PRs for GitHub issues. Uses TDD, verification before completion, and subagent-driven development for large tasks. |
| [`record-app`](skills/record-app/) | Capture screenshots, GIFs, and videos of any application — web, iOS, Android, macOS, Windows, or Linux. Applies smooth animations and stitches into a polished demo video with optional jazz background music. |
| [`create-project-readme`](skills/create-project-readme/) | Analyze a codebase and generate a comprehensive README.md with embedded screenshots, GIFs, and demo videos. Uses `record-app` for media capture. |
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
| [`test-codebase-auditor`](agents/test-codebase-auditor.md) | SQL injection, XSS, hardcoded secrets, N+1 queries, error handling |
| [`test-issue-resolver`](agents/test-issue-resolver.md) | TDD workflow, PR creation, issue linking, acceptance criteria |
| [`test-create-project-readme`](agents/test-create-project-readme.md) | Codebase analysis, README generation, accuracy, media capture |

### Run All Tests

Invoke the orchestrator in OpenCode:

```
@test-orchestrator run all skill tests
```

It will launch 5 parallel test subagents, collect results, and save a `TEST-REPORT.md`.

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
└── record-app/
    ├── SKILL.md
    ├── music/
    │   ├── smooth-jazz.mp3
    │   ├── lofi-beat.mp3
    │   └── ambient.mp3
    └── scripts/
        ├── capture-web.js
        ├── capture-ios.sh
        ├── capture-android.sh
        ├── capture-macos.sh
        ├── capture-windows.ps1
        ├── capture-linux.sh
        └── resize-images.sh

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
