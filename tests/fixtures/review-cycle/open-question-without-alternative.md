# Review — 2026-08-27

## Open questions

### Q1 — The caching layer feels wrong
- Lens: architecture
- Evidence: src/cache.ts:9
- Consequence: Future readers inherit an unexplained choice.

### Q2 — Complete open question
- Lens: architecture
- Evidence: src/cache.ts:40
- Consequence: The cache key omits the tenant, so a future multi-tenant deployment would leak across tenants.
- Alternative: Include the tenant id in the key now, while there is a single tenant and the change is inert.
- Cost: One extra argument threaded through three call sites.
