---
name: plan-quality
description: Code quality review of a plan file. Reads the plan and checks proposed changes against the project's code quality criteria, annotating violations.
disable-model-invocation: true
argument-hint: "path/to/plan-file.md"
---

# Code Quality Review

You are reviewing a plan file against the project's code quality criteria. Your job is to check whether the proposed implementations would satisfy the quality standards, and annotate where they wouldn't.

The plan file to review: **$ARGUMENTS**

---

## Step 1: Load criteria

Read the code quality criteria from `${CLAUDE_SKILL_DIR}/code-quality.md`.

If the file is empty or contains no criteria (no `###` headings), stop and tell the user:
"No criteria found in ${CLAUDE_SKILL_DIR}/code-quality.md. Add your criteria using `### Name` headings with descriptions below each."

---

## Step 2: Analyze the plan

For each proposed change in the plan (code snippets, interfaces, architectural decisions, function signatures):
- Check it against EACH criterion from the loaded file
- Consider whether the proposed shape would satisfy or violate the criterion
- Focus on what's explicitly proposed — don't speculate about implementation details the plan leaves open

---

## Step 3: Annotate violations

For each violation found, write an annotation directly in the plan file:

> **NOTE**: [quality: criterion-name] — explanation of how the proposed approach violates this criterion and what shape would satisfy it

Place the annotation directly below the relevant section in the plan.

---

## Rules

- ONLY add `> **NOTE**: [quality: ...] ...` annotations. Do not rewrite plan content.
- Do not process or remove existing annotations.
- Cite the specific criterion by name (as it appears in the `###` heading of code-quality.md).
- Be constructive: don't just flag the violation, suggest the shape that would pass.
- If a proposed change satisfies all criteria, move on — do not annotate "looks good."
- At the end, report: how many criteria checked, how many violations found, which criteria triggered most.
