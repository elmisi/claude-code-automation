---
name: review-cycle-drift
description: Compare the reconstructed behaviour of a change against its validated intent contract, and report mismatch, intent drift, undeclared assumptions and uncovered acceptance criteria. Runs on a closed change brief; invoke it alone to check a change against an intent you already wrote.
disable-model-invocation: true
argument-hint: "<pass-directory>  (e.g. docs/review-cycle/2026-08-27/)"
allowed-tools: [Read, Write, Glob, Grep]
effort: high
---

# review-cycle-drift

Pass directory: **$ARGUMENTS**

Read, in this order, `methodology-core.md` and `methodology-drift.md`, both in this
skill's own directory. They define what an outcome is and what this lens judges.

## Inputs — exactly two files

`change-brief.md` and `intent.md`, both in the pass directory. Nothing else
from this conversation is input. If `change-brief.md` is missing, stop and say
so rather than reconstructing it yourself: its absence means the protocol order
was not respected.

You may read the repository's source to substantiate a judgement. You may not
read the pull request description or the ticket: the intent you are given has
already been validated by the user, and re-deriving it discards that.

## Your verdict

State one of **aligned**, **partial**, **not aligned**, **undeterminable** at the
top of your output, and separately the count of acceptance criteria you could
check against the count you could not. A single verdict that hides three
uncheckable criteria is worse than saying so.

## Output

Write `review-drift.md` in the pass directory, in the shape defined by
`methodology-core.md`: a `## Findings` section, a `## Open questions` section, a
`## Perturbation` section stating what you drove or broke and what you did not,
and a final `## Out of scope` section stating what you did not look at and why.

Every outcome states what happens if it is ignored. One that cannot is not an
outcome — drop it before writing. There is no cap on how many you may produce,
because that filter has already done the selecting.

Do not modify any code. Do not run git commands that write.
