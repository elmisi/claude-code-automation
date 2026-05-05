# Operations Guide

This file describes all available operations on the accompanying plan.
Any coding agent can follow these instructions — no plugin required.

## Annotate

Add inline annotations to signal improvements, gaps, or errors:

> **NOTE**: your comment here

Place each annotation directly below the section or task it refers to.
Do not modify the plan content — only add annotations.

## Review (process annotations)

1. Read the entire plan
2. Find all lines matching `> **NOTE**:`
3. For each annotation: understand the request, update the plan, remove the annotation
4. If an annotation is unclear, keep it in place and ask for clarification

Goal: make the plan operative, self-contained, coherent, and robust.

## Impact Analysis

Examine each proposed change against the broader codebase:

- **Overlap**: does a function, utility, or pattern already exist that covers this need (fully or partially)?
- **Obsolescence**: does this change make existing code dead or redundant? If so, the plan should include its removal.
- **Conventions**: does the proposed approach follow the project's established patterns (naming, structure, error handling, module boundaries)?
- **Ripple effects**: what other modules consume or depend on the code being changed? Are they accounted for?
- **Infrastructure**: is there shared infrastructure (helpers, base classes, config systems) the plan should leverage instead of building from scratch?
- **Symmetry**: if the codebase treats similar concerns uniformly, does this change maintain or break that uniformity?

Produce `> **NOTE**: ...` annotations where issues are found.

## Code Quality

Review proposed changes against the project's code quality criteria.
Criteria are defined in a separate file maintained by the project owner.

For each criterion violated by the plan's proposed approach, add:

> **NOTE**: [quality: criterion-name] — explanation of how it's violated and suggested fix

## General Principles

- Operations may only add `> **NOTE**:` annotations — they must not rewrite existing plan content
- Annotations are processed in a separate review pass
- Multiple operations can run in sequence before a single review pass
- The plan is approved only when the owner explicitly says so
