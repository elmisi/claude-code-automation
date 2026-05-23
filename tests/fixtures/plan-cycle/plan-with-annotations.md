# Plan: Fixture for INTERACTIVE-PC-B

## Context

Fixture plan used by INTERACTIVE-PC-B to verify `plan-cycle-review` processes annotations correctly.

## Detailed Changes

### Module A
- Refactor `foo()` into smaller pieces

> **NOTE**: [impact] This collides with existing `bar()` in `src/legacy.ts`.

### Module B
- Add caching layer

> **NOTE**: [quality: 1. Readability] The proposed switch statement is 8 branches deep — extract to lookup table.

> **NOTE**: User question — should we use Redis or in-memory?

## Task Breakdown

- [ ] Task A: refactor foo()
- [ ] Task B: add cache
