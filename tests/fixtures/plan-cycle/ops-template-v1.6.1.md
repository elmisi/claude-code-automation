# Operations Guide

This file describes all available operations on the accompanying plan.
Any coding agent can follow these instructions.

## Operation Dispatch Rule

Before touching the plan, identify the requested operation by exact user wording:

- If the user says "annotate": perform only Annotate.
- If the user says "review", "process annotations", "resolve notes", or "apply notes": perform Review.
- If the user says "finalize": perform Finalize.

Existing `> **NOTE**:` lines in the plan do not change the requested operation.
For Annotate, never edit, remove, resolve, or rewrite existing plan content.
Only insert new `> **NOTE**:` lines.

## Annotate

Add inline annotations to signal improvements, gaps, or errors:

> **NOTE**: your comment here

Place each annotation directly below the section or task it refers to.
Do not modify the plan content — only add annotations.

Annotate safety check:

1. Read the plan.
2. Decide where to add notes.
3. Before editing, state: "Annotate mode: I will only add `> **NOTE**:` lines."
4. After editing, verify the diff only adds `> **NOTE**:` lines and blank spacing needed for those notes.
5. If the diff removes lines or modifies non-note text, revert and redo the Annotate operation.

## Review (process annotations)

1. Read the entire plan
2. Find all lines matching `> **NOTE**:`
3. For each annotation: understand the request, update the plan, remove the annotation
4. If an annotation is unclear, keep it in place and ask for clarification

## Finalize

Make the plan operative, self-contained, coherent, and robust.

1. Read the entire plan
2. Check every section against criteria
3. Fix every gap found — rewrite the section, don't annotate it
4. Report: how many sections were updated and a one-line summary
