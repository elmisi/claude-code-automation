---
name: review-cycle-hygiene
description: Apply the deterministic fixes a review labelled auto-fixable as themed local commits, gated on a green test suite before and after, and never touching test files or pushing. Invoke it alone to clean up the nits on a branch without opening a single comment thread.
disable-model-invocation: true
argument-hint: "<pass-directory>  (e.g. docs/review-cycle/2026-08-27/)"
allowed-tools: [Bash, Read, Edit, Write, Glob, Grep]
---

# review-cycle-hygiene — the fix lane

This is not a review. It produces no opinions. It exists so that what a machine
can fix deterministically stops being a conversation.

Pass directory: **$ARGUMENTS**

Read `methodology-core.md` and `methodology-hygiene.md` in this skill's own
directory. `methodology-hygiene.md` is the protocol; follow it step by step.

**Paths.** Set `RC` to this skill's own directory: `${CLAUDE_SKILL_DIR}` in Claude
Code, the directory containing this file in Codex and OpenCode.

## The scripts you run

```bash
"$RC/scripts/rc-suites.sh" discover
"$RC/scripts/rc-suites.sh" enumerate
"$RC/scripts/rc-suites.sh" run "<command>"
"$RC/scripts/rc-suites.sh" collect "<runner-key>"
"$RC/scripts/rc-guard.sh" <base> <head>
"$RC/scripts/rc-registry.sh" set-test-command "<command>"
```

When `discover` reports `needs_model_extraction`, read the CI files it names,
extract the command that runs the test suite, and store it with
`set-test-command`. That is semantic work, it happens once per repository, and
it is the only place in this lane where judgement is involved.

## The three rules that do not bend

1. **Test files are outside the perimeter, without exception.** Not carefully —
   at all. `rc-guard.sh` checks it by intersecting the files you changed with the
   test patterns; run it before you commit, and revert anything it names.
2. **The authoritative suite must be green before you start.** If it is red, the
   lane does not run. Say which suite and stop.
3. **Never `git push`, never open a pull request, never post a comment.** Local
   commits only. The outward gesture belongs to the user.

## Take only what the review already labelled

Read `review.md` in the pass directory and act **only** on findings classified
`auto-fixable`. Do not re-triage, do not widen the perimeter, do not fix things
you notice along the way. Something you spot that is not in that list is a
finding for the next pass, not a commit in this one.

If `review.md` does not exist — the fast and skip lanes produce none — apply only
the categories `methodology-hygiene.md` allows, still inside the change's
perimeter.

## Close with `hygiene.md`

Write it in the pass directory, stating everything `methodology-hygiene.md`
requires: files touched, categories, which suites entered the gate and which did
not with the reason, suite result before and after, commits produced, and what
you deliberately left open.

A pass with nothing to fix is a valid outcome. Say so plainly.
