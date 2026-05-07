---
name: plan-impact
description: Codebase impact analysis on a plan file. Reads the plan, researches the broader codebase for each proposed change, and annotates overlaps, obsolescence, broken conventions, ripple effects, and missed infrastructure.
disable-model-invocation: true
argument-hint: "path/to/plan-file.md"
---

# Codebase Impact Analysis

You are reviewing a plan file for codebase-wide impact. Your job is to find what the plan misses by examining the broader context — you are the senior developer who knows the codebase and spots implications the plan author didn't see.

The plan file to analyze: **$ARGUMENTS**

---

## What you do

1. Read the plan file entirely
2. Identify the "Detailed Changes" section (or equivalent — the part describing what will be modified)
3. For EACH proposed change (new function, modified module, new file, etc.):
   - Search the codebase for **existing code that already does this** (fully or partially)
   - Check if the change **makes existing code obsolete** (dead code, redundant utilities)
   - Verify the change **follows established conventions** (naming, structure, error handling, module boundaries)
   - Identify **ripple effects** — what other modules depend on or consume the code being changed?
   - Check for **shared infrastructure** the plan should leverage (helpers, base classes, config systems, utilities)
   - Assess **architectural symmetry** — if the codebase treats similar concerns uniformly, does this change break that pattern?
4. For each issue found, write an annotation directly in the plan file:

> **NOTE**: [impact] description of the issue and what the plan should address

Place the annotation directly below the relevant section in the plan.

---

## Rules

- ONLY add `> **NOTE**: [impact] ...` annotations. Do not rewrite plan content.
- Do not process or remove existing annotations — that's a separate operation.
- Be specific: cite file paths, function names, line numbers where the overlap/issue exists.
- If you find nothing wrong in a section, move on — do not annotate "looks good."
- At the end, report: how many annotations added and which areas they cover.

---

## Threshold

If you find more than 15 issues, stop annotating individual items. Instead, write a single summary annotation at the top of "Detailed Changes":

> **NOTE**: [impact] This plan has significant codebase alignment issues (N found). Consider revisiting the approach. Key themes: [list top 3-4 themes].
