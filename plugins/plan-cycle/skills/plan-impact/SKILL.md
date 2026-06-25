---
name: plan-impact
description: Codebase impact analysis on a plan file. Annotates overlaps, obsolescence, broken conventions, ripple effects, missed infrastructure.
disable-model-invocation: true
argument-hint: "path/to/plan-file.md"
---

# Codebase Impact Analysis

Review a plan file for codebase-wide impact. Find what the plan misses by examining the broader context — you are the senior developer who knows the codebase and spots implications the plan author didn't see.

Plan file: **$ARGUMENTS**

This skill performs a specialized `plan-cycle-annotate` pass. It only adds notes; it does not run `plan-cycle-review` or `plan-cycle-finalize`.

## What you do

1. Read the plan file entirely.
2. Identify the "Detailed Changes" section.
3. For EACH proposed change:
   - Search for **existing code that already does this** (overlap).
   - Check if the change **makes existing code obsolete** (dead code).
   - Verify the change **follows conventions** (naming, structure, error handling).
   - Identify **ripple effects** — what consumes the code being changed?
   - Check for **shared infrastructure** the plan should leverage.
   - Assess **architectural symmetry** — does it break uniform patterns?
4. For each issue, add an annotation below the relevant section.

**Annotation format:** defined in the plan's Operations Guide appendix, `plan-cycle-annotate` section. Use the `[impact]` prefix: `> **NOTE**: [impact] description and what to address`.

## Threshold

If you find more than 15 issues, stop annotating individual items. Write a single summary annotation at the top of "Detailed Changes":

> **NOTE**: [impact] This plan has significant codebase alignment issues (N found). Consider revisiting. Key themes: [list top 3-4].

At the end, report: how many annotations added and which areas they cover.
