# Plan: <title>

## How to work with this plan

Sections labeled *(Reviewer surface)* require user input before approval — read them in full.
Sections labeled *(Executor surface)* are the implementer's baseline — reviewers may skip.

For operations (annotate / review / finalize): see the **Operations Guide** appendix at the bottom of this file.

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

---

## Operations Guide *(Appendix — instructions for any agent operating on this plan)*

Operations available on this plan. Any coding agent can follow these instructions.

## Operation Dispatch Rule

Identify the requested operation by the user's **exact** wording:

- `plan-cycle-annotate` → run section `## plan-cycle-annotate`.
- `plan-cycle-review` → run section `## plan-cycle-review`.
- `plan-cycle-finalize` → run section `## plan-cycle-finalize`.

**No aliases.** If wording doesn't exactly match one of the three, do NOT execute: reply

> Operazione non riconosciuta. Le operazioni valide su questo piano sono: `plan-cycle-annotate`, `plan-cycle-review`, `plan-cycle-finalize`.

Existing `> **NOTE**:` lines don't change the requested operation. For `plan-cycle-annotate`, never edit/remove/resolve/rewrite existing plan content.

## plan-cycle-annotate

Add inline annotations below the section/task they refer to. Do NOT modify plan content — only add notes.

**Format:** `> **NOTE**: [tag?] comment`. Tags: `[impact]` (plan-impact skill), `[quality: <criterion>]` (plan-quality skill), none (user). `plan-cycle-review` processes all uniformly.

**Safety check:** before editing, state "plan-cycle-annotate mode: I will only add `> **NOTE**:` lines." After editing, verify the diff only adds notes + blank spacing; if it removes/modifies non-note text, revert and redo.

## plan-cycle-review

1. Read the entire plan.
2. Find all `> **NOTE**:` lines.
3. For each: understand, update plan, remove annotation.
4. If unclear, keep it and ask for clarification.

## plan-cycle-finalize

Make the plan operative, self-contained, coherent, robust — a fresh agent must execute it without prior context.

1. Read the entire plan.
2. For each section, check ALL 11 rules: Self-contained, Operative, Outcome-layer success, Numbers-not-adjectives, Exit clauses, Explicit degradation, Verify-before-claim, Enumerate-universals, Mark-unverifiable, Coherent, Robust.
3. Rewrite every failing section — do not annotate.
4. Report: sections updated count + one-line summary per section.
5. **Unresolved Items Inventory** — list every remaining TODO, `assumed:`, `unverified:`. For each, prompt the user per item: *resolve before execution* or *proceed knowingly with consequence stated*. Approval is invalid without this step.

## General Principles

- `plan-cycle-annotate` may only add `> **NOTE**:` annotations — never rewrites.
- `plan-cycle-review` and `plan-cycle-finalize` rewrite plan content directly.
- Multiple annotate passes can run before a single review pass.
- The plan is approved only when the owner explicitly says so.
