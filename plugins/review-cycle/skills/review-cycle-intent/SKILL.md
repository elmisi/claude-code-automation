---
name: review-cycle-intent
description: Reconstruct the intent of a change from its commits and pull request description, present it for validation, and write the validated intent contract. Runs after the change brief is closed. Invoke it alone when you want the intent handover without any judgement.
disable-model-invocation: true
argument-hint: "<pass-directory>  (e.g. docs/review-cycle/2026-08-27/)"
allowed-tools: [Bash, Read, Write, Glob, Grep, AskUserQuestion]
---

# review-cycle-intent — the intent contract

Intent must be inspectable, not presumed. You produce a contract the user has
attested; you do not infer one and treat it as true.

Pass directory: **$ARGUMENTS**

Read `methodology-core.md` in this skill's directory first.

**Paths.** Set `RC` to this skill's own directory: `${CLAUDE_SKILL_DIR}` in Claude
Code, the directory containing this file in Codex and OpenCode.

## Step 1 — Refuse to run out of order

Read `change-brief.md` in the pass directory. If it does not exist, stop and say
so: the intent must not enter the conversation before the behaviour has been
reconstructed independently, and that file is the proof it was.

## Step 2 — Deduce a candidate

Sources, in this order: commit messages in the range, then the pull request or
ticket description if an adapter can reach it (`gh pr view`, the Bitbucket or
Jira API). These are the author's *declarations*, not the code — reading them is
not circular. Deducing intent from the changed code itself would be.

Produce a candidate contract: objective, acceptance criteria, constraints, and
what the change explicitly is not meant to do.

## Step 3 — Present it so that it gets read, not stamped

For every element, state where it came from, and mark plainly:

- what you could **not** determine at all;
- what rests on thin evidence — a criterion inferred from one commit subject is
  not worth the same as one written in the description.

A block of plausible prose gets approved without being read. Lead with the gaps.

Ask the user to correct or confirm. When the gate value passed to you is
`required-strict`, an explicit validation is mandatory and there is no way past
it. When it is `required-unblockable`, the user may answer "I don't know" for an
element; record that verbatim as uncovered — never as agreement. When it is
`none`, write the file and do not interrupt them.

## Step 4 — Write the contract

Write `intent.md` in the pass directory:

```markdown
# Intent contract

Status: validated by the user | partially uncovered | not requested (fast lane)

## Objective
<one paragraph>

## Acceptance criteria
| # | Criterion | Source | Confidence | Status |
| --- | --- | --- | --- | --- |
| 1 | ... | PR description / commit abc123 / user | stated / inferred | validated / uncovered |

## Constraints
## Explicitly out of scope
## Could not be determined
## User corrections
```

Every later skill reads this file. Nothing downstream may re-open what the user
settled here.
