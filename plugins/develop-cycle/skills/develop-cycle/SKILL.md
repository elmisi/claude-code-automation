---
name: develop-cycle
description: Structured development workflow with analysis, implementation, validation, and mandatory checkpoint before commit/push. Use when starting a new feature, bug fix, or refactoring task.
disable-model-invocation: true
argument-hint: [task description]
---

# Development Cycle Workflow

You are following a structured development workflow. Execute each phase in order. The user's task is: **$ARGUMENTS**

## Important

- Commands for linting, pre-commit checks, and tests are defined in the project's CLAUDE.md. Read it before starting.
- The main branch name is in CLAUDE.md (usually `main` or `develop`). If not specified, check with `git branch`.
- **Never commit or push without explicit user approval.** There is a mandatory checkpoint at the end of Phase 4.

---

## Phase 1: Analysis and Planning

**Step 1 — Understand the request**
Examine the task critically. Identify explicit and implicit requirements, impacts, and dependencies.

**Step 2 — Study the codebase**
Read the relevant code. Understand the architecture, patterns, and conventions in use. Identify the files and modules to modify.

**Step 3 — Clarify if needed**
If the request is ambiguous or has edge cases that could go either way, ask specific questions. Skip this step if the task is clear.

**Step 4 — Propose an approach**
For non-trivial tasks with meaningful tradeoffs, present alternative approaches with pros, cons, and complexity. For straightforward tasks (obvious bug fix, simple feature), propose a single approach and move on.

**Step 5 — Define the plan**
List the concrete steps you will take, in order. Identify risks and dependencies. Wait for user approval before proceeding.

---

## Phase 2: Setup

**Step 6 — Create a working branch**
```bash
git checkout <main-branch> && git pull
git checkout -b <branch-type>/<descriptive-name>
```
Use conventional branch prefixes: `feature/`, `fix/`, `refactor/`, `chore/`.

---

## Phase 3: Implementation

**Step 7 — Implement the changes**
Follow the approved plan. Stay consistent with existing patterns and conventions. Only comment code where the logic is non-obvious.

**Step 8 — Handle tests**
Write new tests for added functionality. Update existing tests if behavior changed. Do not skip tests.

---

## Phase 4: Validation

**Step 9 — Run pre-commit / linting**
Run the pre-commit or lint command defined in the project's CLAUDE.md. It must pass cleanly. Fix any issues and re-run.

**Step 10 — Run the test suite**
Run the test command defined in the project's CLAUDE.md. All tests must pass. Fix failures and re-run until green.

### MANDATORY CHECKPOINT

After pre-commit and tests pass, **stop and report results to the user**:

```
Implementation complete. Validation results:
- Pre-commit/lint: PASSED
- Tests: PASSED (N tests)

Waiting for your OK before I commit and push.
```

**Do not proceed until the user explicitly approves** (e.g., "OK", "go ahead", "proceed").

---

## Phase 5: Iteration (if requested)

**Step 11 — Handle feedback**
If the user requests changes after the checkpoint:
1. Apply the requested modifications
2. Re-run validation (Steps 9-10)
3. Stop at the checkpoint again

Repeat until the user approves.

---

## Phase 6: Finalization (only after explicit approval)

**Step 12 — Update documentation**
Update docs only if the changes require it (new API, changed behavior, configuration changes). Do not update docs for internal refactors or bug fixes that don't change the interface.

**Step 13 — Final validation**
Run pre-commit and tests one last time if you made changes during finalization.

**Step 14 — Commit**
Write a descriptive commit message following the project's conventions. Reference issues or tickets if mentioned in the task.

**Step 15 — Push**
```bash
git push -u origin <branch-name>
```
Confirm the push succeeded. Never merge into the main branch — the user handles pull requests.

---

## Error handling

- **Pre-commit fails**: fix and re-run.
- **Tests fail**: debug, fix, re-run the full validation cycle.
- **Merge conflicts**: rebase onto the main branch, resolve conflicts, re-run validation.
- **Uncertain about something**: ask the user before guessing.
