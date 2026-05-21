---
name: issue-resolver
description: Receive, reproduce, fix, and submit PRs for GitHub issues. Uses test-driven development (write failing test first), verification before completion (run tests/lint/typecheck before claiming done), and subagent-driven development for large tasks. Use when assigned to an issue, when user asks to fix a bug, or when working on any tracked issue.
license: MIT
---

# Issue Resolver

Systematically receive, reproduce, fix, and submit PRs for GitHub issues.

## Workflow

### Phase 1: Receive & Understand

1. **Read the issue** — understand the summary, severity, location, and reproduction steps.
2. **Check labels** — note severity, type, and any domain tags.
3. **Read the evidence** — review error output, test failures, or behavioral descriptions.
4. **Review context** — check related files, similar patterns, and framework-specific notes.
5. **Check for comments** — look for triage comments, additional context, or priority notes.
6. **Acknowledge the issue** — comment on the issue with "Working on this" to signal ownership.

### Phase 2: Reproduce

1. **Set up the environment** — install dependencies, configure env vars, start dev server if needed.
2. **Follow reproduction steps** — execute the exact steps from the issue.
3. **Confirm the issue exists** — observe the same error/behavior described in the issue.
4. **Capture "before" media** — take a screenshot, GIF, or video of the bug/issue in action.
   - Save to `.pr-media/issue-{number}-before.{png|gif|mp4}`
   - For backend issues: capture logs, error output, or API response diffs.
5. **If reproduction fails** — comment on the issue asking for clarification. Do not proceed until confirmed.

### Phase 3: Plan the Fix

1. **Identify root cause** — trace from symptom to source.
2. **Determine scope** — what files need to change? What's the minimal fix?
3. **Check Karpathy Guidelines** — apply the four principles:
   - **Think Before Coding**: State assumptions, surface tradeoffs
   - **Simplicity First**: Minimum code that solves the problem
   - **Surgical Changes**: Only touch what's necessary
   - **Goal-Driven Execution**: Define success criteria
4. **State a brief plan** — comment on the issue with your approach:
   ```
   Plan:
   1. [Step] → verify: [check]
   2. [Step] → verify: [check]
   ```

### Phase 4: Create Branch

1. **Branch off latest main**: `git checkout main && git pull && git checkout -b fix/issue-{number}-{short-description}`
2. **Branch naming**: Use descriptive names:
   - `fix/null-pointer-user-service`
   - `fix/n-plus-one-comments-query`
   - `security/xss-comment-rendering`
   - `perf/optimize-image-loading`

### Phase 5: Implement the Fix

**For large tasks (>400 lines or multi-module changes), use subagent-driven development.** See [Subagent-Driven Development](#subagent-driven-development) below.

**Test-Driven Development (TDD):**
1. **Write the failing test first** — create a test case that reproduces the issue and fails.
2. **Run the test** — confirm it fails with the expected error.
3. **Implement the minimal fix** — write only enough code to make the test pass.
4. **Run the test** — confirm it passes.
5. **Refactor** — clean up the implementation while keeping tests green.

**Surgical changes:**
- Only modify files directly related to the issue.
- Follow project conventions — match existing code style, patterns, and architecture.
- Clean up orphans — remove imports/variables your changes made unused.

**Run existing tests** — ensure no regressions in the test suite.
**Run lint/typecheck** — pass all project quality checks.

### Phase 6: Verify the Fix

**Verification Before Completion — never claim work is done without running verification commands first:**

1. **Run the reproduction steps** — confirm the original issue no longer occurs.
2. **Verify Acceptance Criteria** — explicitly check each item in the issue's "Acceptance Criteria" checklist:
   - Read the checklist from the issue body.
   - For each `[ ]` item, run a test, inspect the UI, or check logs to confirm it's met.
   - **Do not proceed** until every criterion is verified. If one fails, fix it and re-test.
3. **Run the new tests** — all tests added for this fix must pass.
4. **Run the full test suite** — `npm test` / `pytest` / `cargo test` — all must pass.
5. **Run lint** — `npm run lint` / `ruff` / `clippy` — must be clean.
6. **Run typecheck** — `tsc --noEmit` / `mypy` / `cargo check` — must be clean.
7. **Capture "after" media** — take a screenshot, GIF, or video showing the fix.
   - Save to `.pr-media/issue-{number}-after.{png|gif|mp4}`
   - For backend issues: capture logs, successful test output, or API response diffs.

**Verification rules:**
- Evidence before assertions — run the commands, confirm the output, then claim success.
- If any check fails, fix it before proceeding to Phase 7.
- Document the verification output in a comment on the issue.

### Phase 7: Create PR

1. **Commit with semantic message**: `git commit -m "fix: resolve {issue summary}"`
2. **Push the branch**: `git push -u origin fix/issue-{number}-{short-description}`
3. **Create PR** with this template:

```markdown
## Summary

This PR fixes #{issue_number} — [one sentence describing the fix].

## Changes

- [File]: [what changed and why]
- [File]: [what changed and why]

## Verification

- [ ] Reproduced the original issue (see before media)
- [ ] Confirmed the fix resolves the issue (see after media)
- [ ] All existing tests pass
- [ ] Lint and typecheck pass
- [ ] New tests added for regression prevention

## Acceptance Criteria

- [ ] [Criterion 1 from issue]
- [ ] [Criterion 2 from issue]
- [ ] [Criterion 3 from issue]
- [ ] [Criterion 4 from issue]
- [ ] [Criterion 5 from issue]

*(Copy the exact checklist from the issue and check each box as verified)*

## Before / After

| Before | After |
|--------|-------|
| ![before](.pr-media/issue-{number}-before.png) | ![after](.pr-media/issue-{number}-after.png) |

## Related

- Closes #{issue_number}
- [Link to triage comment if applicable]
```

4. **Link the PR to the issue** — use `Closes #N` or `Fixes #N` in the PR body.
5. **Request review** — assign reviewers if the project has a review process.

## Guidelines

- **Never skip reproduction** — if you can't reproduce it, you can't fix it.
- **Always capture before media** — even for small UI fixes, show the delta.
- **One issue per PR** — don't bundle multiple fixes together.
- **Keep PRs focused** — only include changes related to the issue.
- **Follow Karpathy Guidelines** — think before coding, keep it simple, be surgical, define success criteria.
- **Respect the triage** — if the issue has labels or comments from triage, address them in your fix.
- **Update the issue** — comment on the issue when the PR is created, linking to it.
- **Verification before completion** — run tests, lint, typecheck before claiming work is done.
- **Test-driven development** — write the failing test first, then implement the fix.

## Subagent-Driven Development

For large tasks (>400 lines, multi-module changes, or complex refactors), use subagents:

### When to Spawn Subagents

- The fix touches >3 distinct modules or services
- The implementation requires >400 lines of code
- Multiple independent changes can be parallelized (e.g., fix + tests + docs)
- The issue spans frontend and backend changes

### How to Use Subagents

1. **Identify independent tasks** — break the fix into tasks with no shared state or sequential dependencies.
2. **Spawn one subagent per task** — each receives:
   - The issue context (summary, reproduction steps, evidence)
   - Their specific task and scope
   - The branch name to work on
3. **Coordinate results** — collect changes from all subagents, resolve conflicts, commit together.
4. **Verify as a whole** — run the full test suite after all subagent changes are integrated.

### Subagent Task Template

```
Task: [description]
Scope: [files/directories this subagent may modify]
Success criteria: [what must be true when done]
Constraints: [what this subagent must NOT touch]
```

### Rules

- Each subagent works on the same branch.
- Subagents should not overlap in file modifications.
- The main agent resolves any conflicts before committing.
- All subagent work must pass verification before Phase 7 (Create PR).

## Edge Cases

### Issue lacks reproduction steps
- Comment asking for clarification
- Attempt to reproduce based on the summary and evidence
- If you can reproduce, document your steps in a comment before fixing

### Issue is a false positive
- Comment on the issue explaining why it's not a bug
- Provide evidence (test output, code analysis)
- Suggest closing the issue with `needs-human-review` tag

### Fix requires breaking changes
- Flag this in your plan comment before implementing
- Suggest a migration path or deprecation strategy
- Get human approval before proceeding

### Issue spans multiple files/modules
- For small multi-file changes: keep as one PR
- For large multi-file changes (>400 lines): use subagent-driven development
- Document the dependency chain between changes
