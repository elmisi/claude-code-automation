---
name: plan-quality
description: Code quality review of a plan file. Checks proposed changes against project code-quality criteria; annotates violations.
disable-model-invocation: true
argument-hint: "path/to/plan-file.md"
---

# Code Quality Review

Review a plan file against code-quality criteria. Annotate where proposed implementations would violate them.

Plan file: **$ARGUMENTS**

This skill performs a specialized `plan-cycle-annotate` pass. It only adds notes; it does not run `plan-cycle-review` or `plan-cycle-finalize`.

## Step 1: Load criteria

Project root = `${CLAUDE_PROJECT_DIR}` if set, else `git rev-parse --show-toplevel`, else cwd (warn `"Using cwd as project root: <path>"`).

If `<project-root>/code-quality.md` exists: load it, print `"Using project criteria from <path>."` Otherwise load `${CLAUDE_SKILL_DIR}/code-quality.md` (default, 9 shipped criteria) and print:

> Using default code-quality criteria (9 shipped rules). To customize, create `<project-root>/code-quality.md` (start by copying `${CLAUDE_SKILL_DIR}/code-quality.md`).

The skill **never** creates, copies, or modifies files in the project root. If the loaded file is empty or has no `###` headings, stop and tell the user to add criteria using `### N. Name` headings.

## Step 2: Analyze and annotate

For each proposed change (code snippets, interfaces, signatures), check against EACH criterion. Focus on what's explicit — don't speculate about details left open.

For each violation, add an annotation below the relevant section. **Format:** defined in ops file `plan-cycle-annotate` section. Use `[quality: <criterion>]` prefix: `> **NOTE**: [quality: criterion-name] explanation + shape that would pass`. Cite criterion by name as in `###` heading. Be constructive.

## Threshold

If you find more than 15 violations, stop annotating individual items. Write a summary at the top of "Detailed Changes":

> **NOTE**: [quality] This plan has significant quality issues (N found across M criteria). Consider revisiting. Top criteria: [list top 3-4].

At the end, report: criteria checked, violations found, criteria triggered most.
