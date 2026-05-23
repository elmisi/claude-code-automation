# Plan: <title>

## How to work with this plan

Sections labeled *(Reviewer surface)* require user input before approval — read them in full.
Sections labeled *(Executor surface)* are the implementer's baseline — reviewers may skip.

For operations (annotate / review / finalize): see companion `{ops-filename}` in this directory.

**Invariant:** keep this `.md` and its `.ops.md` companion in the same directory.

## Context *(Reviewer surface)*
<What exists today, why this change is needed. Cite specific files and code.>

## Interpretation Log *(Reviewer surface)*

Every interpretive choice the planner made on the user's request. One entry per choice:

- **Read "<phrase from request>" as <chosen reading>.**
  - Alternatives considered: <Y>, <Z>.
  - Consequence of each: <chosen → ...>; <Y → ...>; <Z → ...>.
  - **Confirm or correct.**

If no ambiguities detected, write `None detected.` — never leave the section empty.

## Approach *(Reviewer surface)*
<High-level strategy. What changes, what stays the same, and why this approach over alternatives.>

## Decisions I Need From You *(Reviewer surface)*

Planner uncertainty requiring user input. Each entry MUST be self-contained — no `see section X` references.

- **Q1: <situation in plain language>**
  - Options: <A> / <B>
  - Trade-offs: <A → consequence>; <B → consequence>
  - Default if no answer: <choice>

If no open decisions, write `None.` — never leave the section empty.

## Detailed Changes *(Executor surface)*

### <Area/Component>
- What to change and why.
- Files: `path/to/file.ts`.
- Target shape snippet (interface, signature) — not full implementation.
- **User-visible success criterion:** user does X, observes Y. Infrastructure checks ("binary responds", "endpoint returns 200", "service starts") are pre-conditions, not completion evidence.

## Edge Cases and Risks *(Executor surface)*
<Per risk: **Likelihood**, **Impact**, **Mitigation** (concrete), **Exit clause** (when to abandon and switch to what).>

## Failure Modes and Degradation *(Executor surface)*
<Per critical component: failure mode → degraded behaviour (explicit) → thresholds (timeouts, retries, limits) → fallback steps.>

## Task Breakdown *(Executor surface)*
- [ ] Task 1: description + inline outcome criterion.
- [ ] Task 2: ...
