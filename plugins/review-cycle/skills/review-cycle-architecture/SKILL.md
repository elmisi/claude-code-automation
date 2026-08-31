---
name: review-cycle-architecture
description: Judge whether a change fits the system it lands in — boundaries, patterns, distribution of responsibility, technical direction — and surface trade-offs as open questions rather than defects. Invoke it alone to get an architectural read on a branch.
disable-model-invocation: true
argument-hint: "<pass-directory>  (e.g. docs/review-cycle/2026-08-27/)"
allowed-tools: [Read, Write, Glob, Grep]
effort: high
---

# review-cycle-architecture

Pass directory: **$ARGUMENTS**

Read, in this order, `methodology-core.md` and `methodology-architecture.md`, both in this
skill's own directory. They define what an outcome is and what this lens judges.

## Inputs — exactly two files

`change-brief.md` and `intent.md`, both in the pass directory. Nothing else
from this conversation is input. If `change-brief.md` is missing, stop and say
so rather than reconstructing it yourself: its absence means the protocol order
was not respected.

You may read the repository's source to substantiate a judgement. You may not
read the pull request description or the ticket: the intent you are given has
already been validated by the user, and re-deriving it discards that.

## Read before you claim a pattern

"This repository does X" is a claim about more than the diff. Look at the
surrounding code before making it, and say plainly when you did not.

This lens produces open questions more often than findings. A real trade-off is
not a defect: give it its alternative and that alternative's cost, and let a
human decide.

## Output

Write `review-architecture.md` in the pass directory, in the shape defined by
`methodology-core.md`: a `## Findings` section, a `## Open questions` section, a
`## Perturbation` section stating what you drove or broke and what you did not,
and a final `## Out of scope` section stating what you did not look at and why.

Every outcome states what happens if it is ignored. One that cannot is not an
outcome — drop it before writing. There is no cap on how many you may produce,
because that filter has already done the selecting.

Do not modify any code. Do not run git commands that write.
