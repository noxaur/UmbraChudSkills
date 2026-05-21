# UmbraChud Skills

A curated collection of OpenCode skills for codebase auditing, issue resolution, visual recording, and project documentation.

[![skills.sh](https://skills.sh/b/noxaur/UmbraChudSkills)](https://skills.sh/noxaur/UmbraChudSkills)

## Skills

| Skill | Description |
|-------|-------------|
| [`codebase-auditor`](skills/codebase-auditor/) | Analyze a codebase for bugs, security, performance, and architecture issues. Verifies each issue by reproducing it, creates GitHub issues, then uses the triage skill to review, label, and comment. |
| [`issue-resolver`](skills/issue-resolver/) | Receive, reproduce, fix, and submit PRs for GitHub issues. Uses TDD, verification before completion, and subagent-driven development for large tasks. |
| [`record-app`](skills/record-app/) | Capture screenshots, GIFs, and videos of any application — web, iOS, Android, macOS, Windows, or Linux. Applies smooth animations and stitches into a polished demo video. |
| [`create-project-readme`](skills/create-project-readme/) | Analyze a codebase and generate a comprehensive README.md with embedded screenshots, GIFs, and demo videos. Uses `record-app` for media capture. |
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
└── record-app/
    ├── SKILL.md
    └── scripts/
        ├── capture-web.js
        ├── capture-ios.sh
        ├── capture-android.sh
        ├── capture-macos.sh
        ├── capture-windows.ps1
        ├── capture-linux.sh
        └── resize-images.sh
```

## License

MIT
