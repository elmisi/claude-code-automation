---
name: review-cycle
description: Verify a change rather than audit a diff. Reconstructs what the change does before reading any declared intent, computes a deterministic risk floor, runs the intent, drift, architecture and risk skills the floor selects, and hands deterministic fixes to the hygiene lane. Use for reviewing a branch, a pull request, or your own work before opening one.
disable-model-invocation: true
argument-hint: "<base>...<head>  (e.g. main...HEAD)"
allowed-tools: [Agent, Bash, Read, Write, Skill, Glob, Grep, TodoWrite]
effort: high
---

# review-cycle — orchestrator

You verify a change. You do not audit a diff line by line, and you do not write
code: only `review-cycle-hygiene` writes.

The user's range: **$ARGUMENTS**

Read `methodology-core.md` in this skill's directory before starting.

**Paths.** Everything below is relative to this skill's own directory. Set `RC`
once: in Claude Code it is `${CLAUDE_SKILL_DIR}`; in Codex and OpenCode it is the
directory containing this file.

**The order is the protocol.** You reconstruct behaviour from the diff *before*
any declared intent enters this conversation. Do not open the pull request
description, the ticket, or the commit messages until step 5.

---

## Step 1 — Recognition

```bash
"$RC/scripts/rc-recognize.sh" <base> <head>
```

Costs nothing and runs first, so that nothing expensive is spent on a repository
the catalogue cannot place. On a non-zero exit, print the `unknown` list, ask the
user how those paths should be classified, store the answer with
`"$RC/scripts/rc-registry.sh" set-area-mapping '<json>'`, and stop, telling the
user to re-run. Do not proceed on a mapping written a moment ago.

Report any `INERT:` line to the user verbatim at the end: it names a safety
mechanism that will not fire.

## Step 2 — Inventory and pass directory

```bash
"$RC/scripts/rc-registry.sh" init
"$RC/scripts/rc-inventory.sh" <base> <head> > docs/review-cycle/<pass-id>/inventory.json
```

`<pass-id>` is today's date, `YYYY-MM-DD`; if that directory exists append `-2`,
`-3`. Create it before writing.

## Step 3 — Change brief

Write `docs/review-cycle/<pass-id>/change-brief.md` from the diff and the
inventory alone: what the change *does*, in behaviour, not in files. Include the
inventory's areas, dispersion, churn and the sensitive-area map.

This file is the evidence that the order was respected. If it cites a pull
request description or a ticket, the protocol was broken.

## Step 4 — Routing

```bash
"$RC/scripts/rc-registry.sh" promote-check docs/review-cycle/<pass-id>/inventory.json
"$RC/scripts/rc-floor.sh" docs/review-cycle/<pass-id>/inventory.json <lane-from-promote-check> \
  > docs/review-cycle/<pass-id>/routing.json
```

Pass the `lane` from `promote-check` verbatim as the second argument; pass
nothing when it is `null`.

You may raise the resulting `lane` to a more severe one, and you must write the
reason into `change-brief.md` when you do. You may never lower it: the script
already refuses, and attempting it is a protocol error.

## Step 5 — Run what the routing selected

`routing.json` contains `invoke`: the ordered list of skills to run. Invoke each
one, in that order, passing the pass directory as its argument. Do not add,
remove, or reorder them, and do not reason about which ones ought to run — that
decision is already made and is a safety property.

Pass each skill the value of `intent_gate` from `routing.json`.

**Lenses in parallel.** The entries named `review-cycle-drift`,
`review-cycle-architecture` and `review-cycle-risk` are independent by
construction: their input is exactly `change-brief.md` plus `intent.md`. When the
runtime supports plugin agents, spawn one `lens-runner` agent per lens in a
single message so they run concurrently. Probe for that support rather than
assuming it; where it is absent, run them yourself in order and say nothing about
it. The result must not differ between the two modes — if it does, a lens was
reading this conversation instead of its two files.

## Step 6 — Assemble and validate

Merge `review-drift.md`, `review-architecture.md` and `review-risk.md` into
`docs/review-cycle/<pass-id>/review.md`, following the shape in
`methodology-core.md`. Number findings `F1..Fn` and open questions `Q1..Qn`
across the whole file.

```bash
"$RC/scripts/rc-validate.sh" docs/review-cycle/<pass-id>/review.md
```

On a non-zero exit, send each named outcome back to the lens that produced it,
**once**. If it is still incomplete, drop it and record in `review.md` which
outcomes were dropped and why.

## Step 7 — Close the pass

Open every `needs-human` outcome as debt, then log the pass:

```bash
"$RC/scripts/rc-registry.sh" debt-add "<area>" "<lens>" "<summary>"
"$RC/scripts/rc-registry.sh" append-pass <pass-id> <lane> docs/review-cycle/<pass-id>/inventory.json <open-count>
```

Read `docs/review-cycle/debt.md` and re-present any judgement still open from an
earlier pass that touches an area this change also touches.

## Step 8 — Report

Tell the user: the lane and why, the counts of findings and open questions, the
hygiene commits produced, every `INERT:` mechanism, and anything declared as
missing coverage. Then give them the paste-ready block from `review.md` for the
pull request — you do not post it yourself, and you never push.
