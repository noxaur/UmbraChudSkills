---
name: codebase-auditor
description: Analyze a codebase for bugs, security vulnerabilities, performance issues, and architecture problems. Verifies each issue by reproducing it, creates GitHub issues, then uses the triage skill with subagents to review, label, and comment on each issue. Use when asked to audit, review, or analyze a codebase for issues, or when user mentions code quality review, finding bugs, security audit, or codebase health check.
license: MIT
---

# Codebase Auditor

Systematically analyze a codebase, verify issues by reproducing them, and create GitHub issues with rich context.

## Workflow

### Phase 1: Reconnaissance

1. Read the project structure: `ls`, `package.json`, `tsconfig.json`, `pyproject.toml`, etc.
2. Identify the tech stack, framework, entry points, and test setup.
3. Run `npm install` / `bun install` / `pip install` etc. to ensure dependencies are available.
4. Run the project's existing test suite, lint, and typecheck to establish a baseline.
5. Note any existing CI/CD configuration for context.

### Phase 2: Systematic Analysis

**For multi-language or large codebases (>50 files), spawn specialized subagents.** See [Specialized Agents](#specialized-agents) below.

Scan the codebase for issues in these categories:

**Bugs & Code Quality**
- Logic errors, off-by-one, null/undefined handling
- Race conditions, unhandled promises, missing error boundaries
- Dead code, unused imports, duplicated logic
- Incorrect API usage, missing validation, type mismatches

**Security Vulnerabilities**
- Injection (SQL, XSS, command), SSRF, path traversal
- Auth bypass, missing CSRF protection, exposed secrets/tokens
- Insecure dependencies (check `package-lock.json` / `requirements.txt`)
- Overly permissive CORS, missing rate limiting, weak crypto

**Performance Issues**
- N+1 queries, missing indexes, unbounded loops
- Memory leaks, unnecessary re-renders, large bundle imports
- Blocking main thread, missing caching, redundant network calls
- Inefficient algorithms, missing pagination, unoptimized assets

**Architecture Problems**
- Tight coupling, circular dependencies, god objects
- Missing abstraction layers, violated separation of concerns
- Hardcoded configuration, missing environment handling
- Anti-patterns specific to the framework in use

For language and framework-specific checklists, see [REFERENCE.md](REFERENCE.md).

### Phase 3: Verify Each Issue

For every potential issue found:

1. **Trace the code path** — follow the execution flow from entry point to the problematic code.
2. **Reproduce the issue** — write a minimal test case or script that demonstrates the bug. Run it.
3. **Confirm it's real** — if the reproduction fails, the issue is a false positive. Discard it.
4. **Assess severity** — classify as `critical`, `high`, `medium`, or `low`.

**Verification rules:**
- Never create an issue you haven't reproduced yourself.
- If reproduction requires specific data/state, document how to set it up.
- If the issue only manifests in production (env-specific), note that clearly.

### Phase 4: Create GitHub Issue

Create one issue at a time. Use this template:

```markdown
## Summary

[One sentence describing the issue]

## Severity

`critical` | `high` | `medium` | `low`

## Location

- **File:** `path/to/file.ts`
- **Line(s):** 42-58
- **Component/Module:** [name if applicable]

## Reproduction

[Step-by-step instructions to reproduce, or a minimal test case]

```bash
# or code snippet that triggers the issue
```

## Evidence

[What you observed: error output, test failure, stack trace, or behavioral description]

## Impact

[What could go wrong in production: data loss, security breach, crash, degraded UX]

## Suggested Fix

[Concrete recommendation with code snippet if applicable]

## Context

[Additional context: related files, similar patterns elsewhere, framework-specific notes, why this pattern is problematic]

## Acceptance Criteria

- [ ] [Criterion 1: e.g., Header fits within mobile viewport without horizontal overflow]
- [ ] [Criterion 2: e.g., Critical metrics remain visible on mobile]
- [ ] [Criterion 3: e.g., Non-critical metrics hidden or simplified on mobile]
- [ ] [Criterion 4: e.g., No horizontal scroll on mobile viewports (<640px)]
- [ ] [Criterion 5: e.g., Desktop layout unchanged]
```

### Phase 5: Summary Report

After all issues are created, post a summary:

```
## Codebase Audit Summary

| Severity | Count |
|----------|-------|
| Critical | X     |
| High     | X     |
| Medium   | X     |
| Low      | X     |
| **Total**| **X** |

**Files analyzed:** X
**False positives discarded:** X
**Issues created:** [links to all created issues]
```

### Phase 6: Triage & Enrichment

After all issues are pushed to GitHub, spawn the **triage skill** with subagents to review and enrich the created issues:

1. **Load the triage skill** — invoke the installed `triage` skill.
2. **Spawn triage subagents** — one per issue category (bugs, security, performance, architecture).
3. **Review each issue** — the triage subagents should:
   - Read the issue body and verify the reproduction steps are clear
   - **Verify the "Acceptance Criteria" checklist is present and actionable** — if missing or vague, add a comment requesting clarification
   - Add appropriate **labels/tags** based on severity and category (e.g., `bug`, `security`, `performance`, `architecture`, `critical`, `high`, `medium`, `low`)
   - Add **comments** with additional context, related issues, or suggested priority
   - Assign **milestones** if the project uses them
   - Flag any issues that need human review or have low confidence
4. **Deduplicate across categories** — if multiple subagents tag the same issue, consolidate labels.
5. **Post a triage summary** — list all issues with their final labels and any comments added.

**Triage label vocabulary:**

| Category | Labels |
|----------|--------|
| Type | `bug`, `security`, `performance`, `architecture`, `code-quality` |
| Severity | `critical`, `high`, `medium`, `low` |
| Status | `needs-human-review`, `verified`, `needs-more-info` |
| Domain | `frontend`, `backend`, `database`, `devops`, `testing` |

**Rules:**
- Do not close or modify issues — only add labels and comments.
- If the project already has a label taxonomy, use those labels instead of creating new ones.
- Security issues should always get `security` + severity label and a comment noting if disclosure should be private.

## Guidelines

- **One issue at a time** — verify and create each issue before moving to the next finding.
- **No duplicates** — check existing GitHub issues before creating a new one.
- **No noise** — if unsure, flag it as "needs human review" instead of creating a low-confidence issue.
- **Respect scope** — if the user specifies a directory or package, only audit that scope.
- **Preserve context** — include file paths, line numbers, and code snippets so a human can find the issue immediately.
- **Use the project's conventions** — match the project's existing issue format, labels, and severity scale if they exist.

## Specialized Agents

For large or multi-language codebases, spawn parallel subagents per language/framework. Each subagent:

1. Receives the relevant section from [REFERENCE.md](REFERENCE.md)
2. Scans only files matching their domain
3. Verifies issues independently
4. Reports findings back for deduplication

### Agent Assignment

**Language auditors** (base layer — always run if files match):

| Subagent | File patterns | Reference section |
|----------|---------------|-------------------|
| Rust auditor | `*.rs`, `Cargo.toml` | Rust |
| C++ auditor | `*.cpp`, `*.hpp`, `*.cc`, `*.h`, `CMakeLists.txt` | C++ |
| C auditor | `*.c`, `*.h`, `Makefile` | C |
| TS/JS auditor | `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `package.json` | TypeScript / JavaScript |
| Python auditor | `*.py`, `pyproject.toml`, `requirements.txt` | Python |
| Go auditor | `*.go`, `go.mod` | Go |
| Java auditor | `*.java`, `pom.xml`, `build.gradle` | Java |
| Ruby auditor | `*.rb`, `Gemfile`, `Rakefile` | Ruby |
| Swift auditor | `*.swift`, `Package.swift`, `*.xcodeproj` | Swift |

**Framework auditors** (spawn in addition to language auditor when framework detected):

| Subagent | Detection signals | Reference section |
|----------|-------------------|-------------------|
| React auditor | `react` in `package.json`, `*.jsx`/`*.tsx` with JSX | React |
| Next.js auditor | `next` in `package.json`, `next.config.*`, `app/` or `pages/` dir | Next.js |
| Vue auditor | `vue` in `package.json`, `*.vue` files | Vue.js |
| Svelte auditor | `svelte` in `package.json`, `*.svelte` files | Svelte / SvelteKit |
| Angular auditor | `@angular/core`, `angular.json`, `*.component.ts` | Angular |
| Express auditor | `express` in `package.json`, `app.js`/`server.js` | Express.js / Node.js |
| NestJS auditor | `@nestjs/core`, `nest-cli.json`, `*.module.ts` | NestJS |
| Django auditor | `django` in `requirements.txt`, `manage.py`, `settings.py` | Django |
| Flask/FastAPI auditor | `flask` or `fastapi` in `requirements.txt` | Flask / FastAPI |
| Spring Boot auditor | `spring-boot` in `pom.xml`/`build.gradle`, `@SpringBootApplication` | Spring Boot |
| Rails auditor | `rails` in `Gemfile`, `config/routes.rb`, `app/controllers` | Ruby on Rails |
| Actix/Axum auditor | `actix-web` or `axum` in `Cargo.toml` | Actix / Axum |
| Gin/Echo auditor | `gin-gonic` or `echo` in `go.mod` | Gin / Echo |

### Spawning Subagents

When the codebase contains multiple languages or frameworks:

```
1. Identify languages present → spawn one language subagent per language
2. Detect frameworks (package.json dependencies, config files) → spawn framework subagents
3. Each subagent runs Phases 1-3 independently on their file set
4. Collect all findings → deduplicate → Phase 4 (create issues) → Phase 5 (summary) → Phase 6 (triage)
```

**Two-layer strategy:**
- **Language auditors** catch generic issues (memory safety, type errors, injection)
- **Framework auditors** catch framework-specific issues (React stale closures, Django N+1, Spring Boot missing `@Transactional`)

**Coordination rules:**
- Subagents should not create issues directly — report to the main auditor.
- The main auditor deduplicates across subagents before creating GitHub issues (Phase 4).
- If a subagent finds cross-language issues (e.g., FFI boundary bugs), flag them for the main auditor to investigate.
- If the same issue is found by both a language and framework auditor, keep the one with more specific context.
- Phase 6 (triage) is run by the main auditor after all issues are pushed to GitHub.
