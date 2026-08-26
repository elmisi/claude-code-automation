---
name: review-cycle-risk
description: Price what it costs if a change is wrong: probability, impact, blast radius, detectability and reversibility — plus rollback plan, negative tests and threat modelling in the strict lane. Invoke it alone to assess a branch before merging.
disable-model-invocation: true
argument-hint: "<pass-directory>  (e.g. docs/review-cycle/2026-08-27/)"
allowed-tools: [Read, Write, Glob, Grep]
effort: high
---

# review-cycle-risk

Pass directory: **$ARGUMENTS**

Read, in this order, `methodology-core.md` and `methodology-risk.md`, both in this
skill's own directory. They define what an outcome is and what this lens judges.

## Inputs — exactly two files

`change-brief.md` and `intent.md`, both in the pass directory. Nothing else
from this conversation is input. If `change-brief.md` is missing, stop and say
so rather than reconstructing it yourself: its absence means the protocol order
was not respected.

You may read the repository's source to substantiate a judgement. You may not
read the pull request description or the ticket: the intent you are given has
already been validated by the user, and re-deriving it discards that.

## Address all five dimensions

Probability, impact, blast radius, detectability, reversibility. Silence on one
of them is itself a finding.

The strict-lane section of `methodology-risk.md` applies only when the
orchestrator passed you an intent gate of `required-strict`. Read that section
then, and not otherwise.

## Output

Write `review-risk.md` in the pass directory, in the shape defined by
`methodology-core.md`: a `## Findings` section, a `## Open questions` section,
and a final `## Out of scope` section stating what you did not look at and why.

Every outcome states what happens if it is ignored. One that cannot is not an
outcome — drop it before writing. There is no cap on how many you may produce,
because that filter has already done the selecting.

Do not modify any code. Do not run git commands that write.
