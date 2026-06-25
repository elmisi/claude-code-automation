# Plan: Fixture for INTERACTIVE-PC-B

## Context

Fixture plan used by INTERACTIVE-PC-B to verify `plan-cycle-review` processes annotations correctly.

## Detailed Changes

### Module A
- Refactor `foo()` into smaller pieces

> **NOTE**: [impact] This collides with existing `bar()` in `src/legacy.ts`.

### Module B
- Add caching layer

> **NOTE**: [quality: 1. Readability] The proposed switch statement is 8 branches deep — extract to lookup table.

> **NOTE**: User question — should we use Redis or in-memory?

## Task Breakdown

- [ ] Task A: refactor foo()
- [ ] Task B: add cache

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

## plan-cycle-annotate

Add inline annotations below the section/task they refer to. Do NOT modify plan content — only add notes. **Format:** `> **NOTE**: [tag?] comment`.

## plan-cycle-review

1. Read the entire plan.
2. Find all `> **NOTE**:` lines.
3. For each: understand, update plan, remove annotation.
4. If unclear, keep it and ask for clarification.

## plan-cycle-finalize

Make the plan operative, self-contained, coherent, robust. Check the 11 writing rules, rewrite failing sections, then surface the Unresolved Items Inventory.
