# Plan: <title>

## How to work with this plan

Read the entire plan before acting. Context, approach, edge cases, and open questions are all load-bearing.

For operational instructions (how to annotate, review, finalize): see the companion file `{ops-filename}` in the same directory.

**Invariant:** keep this plan file and its `.ops.md` companion in the same directory. Moving one without the other breaks the link.

## Context
<What exists today and why this change is needed. Reference specific files and code.>

## Approach
<High-level strategy. What changes, what stays the same, and why this approach over alternatives.>

## Detailed Changes

### <Area/Component 1>
- What to change and why
- Specific files to modify: `path/to/file.ts`
- Code snippets showing the target shape (interface, signature) — not full implementation

### <Area/Component 2>
...

## Edge Cases and Risks
<For each risk:
- **Likelihood**: low/medium/high
- **Impact**: what breaks and how badly
- **Mitigation**: concrete action, not "be careful"
- **Exit clause**: at what point do we abandon this approach and what's plan B>

## Failure Modes and Degradation
<For each critical component:
- What happens when it fails or is unavailable?
- Degraded behavior (explicit, not "it should handle it gracefully")
- Concrete thresholds: timeouts, retry counts, size limits, rate limits
- Fallback strategy with specific steps>

## Open Questions
<Anything you're unsure about, plus any unverifiable assumption on which a significant scope, risk, or design decision rests. Surface levers reviewers should probe — don't reserve only for "things I don't know at all".>

## Task Breakdown
- [ ] Task 1: description
- [ ] Task 2: description
- [ ] ...
