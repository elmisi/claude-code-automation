# Review — 2026-08-27

## Findings

### F1 — Variable name is unclear
- Lens: architecture
- Severity: low
- Classification: needs-human
- Evidence: src/app.ts:12

### F2 — Well-formed finding
- Lens: risk
- Severity: medium
- Classification: needs-human
- Evidence: src/app.ts:30
- Consequence: The retry loop has no ceiling, so a persistent downstream failure turns into an unbounded request amplification.
