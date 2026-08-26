# Review — 2026-08-27

Lane: normal. Lenses: drift, architecture, risk.

## Findings

### F1 — Session lookup runs on every request
- Lens: risk
- Severity: high
- Classification: needs-human
- Evidence: src/middleware/session.ts:48
- Consequence: Under the current traffic the session store is hit once per request; if it degrades, every route fails at once rather than the one that needs the session.
- Question: Is a per-request lookup intended here, or should the session be resolved once and passed down?

### F2 — Stale reference in the module docstring
- Lens: drift
- Severity: low
- Classification: auto-fixable
- Evidence: src/middleware/session.ts:3
- Consequence: The docstring names a function removed in this same change, so the next reader looks for something that no longer exists.

## Open questions

### Q1 — Session resolution sits in middleware rather than in the request context
- Lens: architecture
- Evidence: src/middleware/session.ts:20
- Consequence: Every future route inherits the choice silently; reversing it later means touching every route that reads the session.
- Alternative: Resolve the session in the request context builder and pass it explicitly, as the auth token already is.
- Cost: One refactor of the four existing routes now, against an unknown number later.
