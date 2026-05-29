# File tree tiers and dreadREPO mapping

## Tier A (minimal)

- [ ] `AGENTS.md`
- [ ] `docs/agents/README.md`
- [ ] `docs/agents/orchestration.md`
- [ ] Pointer from `.cursor/rules` or `CLAUDE.md` to `AGENTS.md` (if those exist)

## Tier B (standard)

All Tier A, plus:

- [ ] `CONTEXT.md`
- [ ] `CONTRIBUTING.md`
- [ ] `docs/agents/issue-tracker.md`
- [ ] `docs/agents/triage-labels.md`
- [ ] `docs/agents/domain.md`
- [ ] `docs/ROADMAP.md`
- [ ] `docs/agents/guides/README.md` (index only)

## Tier C (full autonomous)

All Tier B, plus:

- [ ] `docs/agents/verify-{{PROJECT_SLUG}}.md`
- [ ] `scripts/verify-{{PROJECT_SLUG}}.ps1` or `.sh`
- [ ] `.claude/implementer-prompt.md`
- [ ] `.claude/spec-reviewer-prompt.md`
- [ ] `.claude/code-quality-reviewer-prompt.md`
- [ ] `.cursor/mcp.json` (if MCP)
- [ ] MCP server package (project-specific, not copied from dreadREPO)

## dreadREPO → generic rename

| dreadREPO | Generic |
|-----------|---------|
| `verify-dread.md` | `verify-<slug>.md` |
| `verify-dread.ps1` | `verify-<slug>.ps1` |
| `verify-dread-checklist.json` | optional machine-readable checklist |
| `dread-mcp-server/` | `<project>-mcp-server/` or skip |
| Thunderstore / BepInEx blocks in AGENTS.md | replace with stack-specific packaging |

## Empty repo notes

- `AGENTS.md`: mark build/test as TBD with "first implementation PR must define commands"
- `CONTEXT.md`: 3–5 terms from intake only
- `ROADMAP.md`: single "Phase 0: bootstrap" row
- Skip MCP and verify scripts until something exists to verify
