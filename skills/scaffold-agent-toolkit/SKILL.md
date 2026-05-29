---
name: scaffold-agent-toolkit
description: Use when bootstrapping agent orchestration for a new or empty repo, migrating from dreadREPO-style docs, or the user asks for AGENTS.md, docs/agents, CONTEXT.md, triage labels, verify runbooks, or subagent prompts. Use when the repo lacks docs/agents or agent entry points.
---

# Scaffold agent toolkit

Portable workflow to add **dreadREPO-style** agent infrastructure to any repository, including **empty** repos. Reference implementation: [grompen91-droid/dreadREPO](https://github.com/grompen91-droid/dreadREPO).

**Violating the letter of intake (asking questions before writing) is violating the spirit of this skill.**

## When to use

- New repo with no agent docs
- Existing repo missing `AGENTS.md`, `docs/agents/`, or `CONTEXT.md`
- User says "set up agents like dread", "agent orchestration", "ready-for-agent labels"
- Monorepo needs one hub per package (repeat intake per package)

## When NOT to use

- Repo already has a complete agent hub and user only wants a small doc fix
- User only wants a single Cursor rule (use Settings → Rules instead)

## Phase 0: Intake (mandatory)

**Do not create files until intake is answered.** For empty repos, every unknown becomes a question.

Use the ask-questions tool when available. Otherwise post a numbered questionnaire and wait.

### Minimum questions

| # | Topic | Why |
|---|--------|-----|
| 1 | **Product** | One sentence: what does this repo ship? |
| 2 | **Stack** | Languages, frameworks, runtime (Node, .NET, Python, etc.) |
| 3 | **Build** | Exact commands to build, test, lint (or "none yet") |
| 4 | **Default branch** | `main`, `master`, other |
| 5 | **Issue tracker** | GitHub, GitLab, Linear, none |
| 6 | **Release model** | Semver tags, CD pipeline, manual, N/A |
| 7 | **Agent scope** | Solo only, or multi-subagent (implementer + reviewers) |
| 8 | **Verify tiers** | Static CI only, or live app / MCP debug bridge |
| 9 | **Domain glossary** | Need `CONTEXT.md` now, or defer until terms exist |
| 10 | **MCP** | Need `.cursor/mcp.json` + server package, or skip |

### Optional questions (ask if relevant)

- Monorepo layout and per-package boundaries
- Cloud agent branch naming convention (e.g. `cursor/<task>-<suffix>`)
- Changelog / release notes format
- Backlog source: `ROADMAP.md`, GitHub Projects, issue labels only
- Paths agents must never edit (generated, vendor, secrets)
- Compatibility / ADR folder already exists?

### Infer silently (only when evidence exists)

- `git remote -v` → GitHub org/repo for issue-tracker template
- Existing `package.json`, `*.csproj`, `pyproject.toml` → stack and scripts
- `.github/workflows/*` → verify Tier 0 commands
- Existing `CONTRIBUTING.md` → link, do not duplicate

If inference conflicts with user answers, **user wins**.

Record answers in a short **Intake summary** (bullet list) before Phase 1.

## Phase 1: Choose scaffold tier

| Tier | When | Files |
|------|------|-------|
| **A – Minimal** | Empty repo, docs-only, or "agents later" | `AGENTS.md`, `docs/agents/README.md`, `docs/agents/orchestration.md` |
| **B – Standard** | Active code, GitHub issues, contributors | Tier A + `CONTEXT.md`, `CONTRIBUTING.md`, `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, `docs/agents/domain.md`, `docs/ROADMAP.md` |
| **C – Full** | Autonomous agents, verify, subagents, MCP | Tier B + `docs/agents/verify-<project>.md`, `scripts/verify-<project>.ps1` or `.sh`, `.claude/*-prompt.md`, optional `.cursor/mcp.json` + MCP package stub |

Default: **Tier B** unless intake says otherwise.

## Phase 2: Target layout

Full tree (Tier C). Omit paths not chosen in Phase 1.

```text
repo-root/
├── AGENTS.md
├── CONTEXT.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── docs/
│   ├── ROADMAP.md
│   ├── adr/
│   └── agents/
│       ├── README.md
│       ├── orchestration.md
│       ├── issue-tracker.md
│       ├── triage-labels.md
│       ├── domain.md
│       ├── verify-<name>.md
│       └── guides/
│           └── README.md
├── .claude/
│   ├── implementer-prompt.md
│   ├── spec-reviewer-prompt.md
│   └── code-quality-reviewer-prompt.md
├── .cursor/
│   └── mcp.json
└── scripts/
    └── verify-<name>.ps1
```

**Wire-up rules**

- Root `CLAUDE.md` or `.cursor/rules` should point to `AGENTS.md` (one line is enough).
- `AGENTS.md` must link `docs/agents/README.md` as the agent entry.
- `docs/agents/README.md` tables must link every file you create (no orphan docs).

## Phase 3: Generate content

1. Read templates under `references/templates/` in this skill folder.
2. Replace every `{{PLACEHOLDER}}` from the Intake summary.
3. Use repo-native commands in `AGENTS.md` (from user or discovered scripts).
4. **Never copy dreadREPO-specific** strings (Thunderstore, BepInEx, R.E.P.O.) unless the target project is that mod.
5. For **empty repos**: use `TBD` sections and explicit "fill when first code lands" notes; still create Tier A so agents have a landing zone.

## Phase 4: Validate

Before claiming done:

1. Every created file linked from `docs/agents/README.md` or `CONTRIBUTING.md`
2. `AGENTS.md` build/test commands run clean, or failure documented with reason
3. No dreadREPO-only paths left as placeholders except in comments citing the reference repo
4. No em dash character in any generated markdown (use colon or comma)
5. Commit on a branch; offer PR if user uses git hosting

## Phase 5: Offer follow-ups

After scaffold, ask once:

- Add first `docs/adr/0001-*.md`?
- Seed `docs/ROADMAP.md` from open issues?
- Add project skill under `.cursor/skills/`?
- Import this hub into another repo (re-run intake)?

## Reference files (load on demand)

See `references/file-tree.md` and `references/templates/` in this skill folder.

## dreadREPO file map (reference only)

| dreadREPO path | Generic role |
|----------------|--------------|
| `AGENTS.md` | Agent build/release policy |
| `CONTEXT.md` | Glossary |
| `docs/agents/README.md` | Hub |
| `docs/agents/orchestration.md` | Workflows |
| `docs/agents/issue-tracker.md` | Issues CLI |
| `docs/agents/triage-labels.md` | Labels |
| `docs/agents/domain.md` | ADR consumption |
| `docs/agents/verify-dread.md` | Verify runbook |
| `docs/ROADMAP.md` | Backlog |
| `.claude/*-prompt.md` | Subagent roles |
| `.cursor/mcp.json` | MCP stdio config |
