# Refactor Discovery — Methodology Reference

This document is the canonical reference for the refactor-discovery methodology. It defines how to surface structural smells, promote only well-evidenced refactors, and preserve uncertainty without flattening it into premature advice.

**Core discipline:** do not sell a solution before the code has explained itself. The first output is an investigation lead: a tension, anomaly, hidden policy, or repeated ceremony that deserves attention. Only promote it to a refactor candidate after the "why" gate has enough evidence.

---

## 1. Guiding Principles

Every promoted refactor candidate must cite at least one principle. Smell leads should cite the most likely principle pressure, but may mark it as tentative. Principles are listed in decreasing priority; when two conflict, the higher one wins.

1. **Readability for an experienced programmer.** Target reader: a senior developer familiar with the language/framework who has not seen this file before. If they must pause, re-read, or open unrelated files to understand intent, something is unclear.

2. **Essentiality.** Prefer code where removing anything breaks real behaviour. Defensive additions that catch nothing in practice, validators around already-trusted data, try/catch around calls that cannot reasonably fail, and one-caller abstractions are suspects. Counterpoint: validation at trust boundaries is essential.

3. **Cognitive Load Minimization.** The metric is not fewer lines, but fewer concepts a reader must hold at once. Watch for inverted guard structure, logic at indent >= 3, long inline booleans, and files mixing I/O, policy, orchestration, and presentation.

4. **Abstraction via Naming.** Complex predicates, calculations, policies, and duplicated knowledge should carry a name that describes intent. DRY applies only to duplicated knowledge, not visually similar code.

5. **Tell, Don't Ask.** When code interrogates an object's fields to decide something about that object, the decision likely belongs near the data as a named function or, when several correlated predicates exist, a domain wrapper.

6. **Fail Fast, Fail Loud.** Silent failures without a stated reason are debt. If the swallow is deliberate degradation, the code must say what is acceptable and what the caller sees.

7. **Command-Query Separation.** A function should return data or mutate state, not both. When both are necessary, the mutation contract must be visible through naming, typing, or a site-level explanation.

8. **Principle of Least Surprise.** Names should predict behaviour. `getX` that mutates, `createY` that reads from storage, or functions returning `null` on transient errors are surprising. Preferred remediation order: rename, split, then document.

9. **Comments only for the "why" not derivable from code.** Comments that restate code are noise. Comments that capture unrecoverable intent are evidence.

**Explicitly not used as standalone drivers:** generic DRY, cosmetic consistency, file size alone, abstract SOLID adherence, inheritance designs, speculative framework extraction, "make illegal states unrepresentable" without a local payoff, and pure testability extraction without readability payoff.

---

## 2. Discovery Lenses

Use these lenses to find non-obvious smells that a local clean-code scan misses. A lens produces a lead first; it does not automatically produce a refactor.

1. **Temporal coupling.** Files or concepts change together repeatedly without an explicit code relationship. Evidence source: `git log --name-only`, commit clusters, and release notes. Promote only after confirming the shared change reason is still current.

2. **Change amplification.** A small conceptual change requires edits in many places: schema, validator, template, fixture, docs, tests, registry, or UI labels. This can reveal missing policy names or misplaced ownership.

3. **Shotgun ceremony.** The same mental sequence appears across sites even when syntax differs: parse, validate, map, register, test, document. Count concepts, not identical lines.

4. **Semantic drift.** Names, comments, tests, docs, and behaviour tell slightly different stories. Drift is often more useful than a smell in the code body because it reveals decayed intent.

5. **Asymmetric abstractions.** Similar problem shapes are solved with different levels of abstraction in different areas. Do not force uniformity; ask what constraint explains the asymmetry.

6. **Hidden policy.** Business, product, security, or workflow rules are encoded as technical details: default values, ordering, fallbacks, filters, naming conventions, allow-lists, or validation branches.

7. **Test gravity.** A test must build excessive context to assert a small behaviour, or many tests duplicate the same setup ceremony. This suggests responsibility or boundary pressure.

8. **Negative space.** Something expected is absent: no validator near external input, no test for a central policy, no comment on a surprising fallback, no owner for a repeated mapping. Absence is a lead, not proof.

---

## 3. Investigation Discipline — the "why" Gate

Before any lead is promoted to a refactor candidate, the investigator must have a defensible answer to why the code is the way it is.

For every smell that looks promotable:

1. Read the file end-to-end, not just grep hits.
2. Read behavioural contracts in tests, preferring unit specs, then integration/e2e, then upstream/downstream specs.
3. Read neighbouring call sites and consumers.
4. Recover history for implicated lines with `git log -L`, `git blame`, and `git show`.
5. Search nearby planning, review, issue, or changelog docs.
6. Distinguish load-bearing comments from noise.
7. Before claiming duplication, diff the sites and compare behaviour, not appearance.
8. Before claiming "only X uses this", enumerate usages across the repo.
9. For temporal or change-amplification leads, inspect commit clusters and confirm the changes share one reason.
10. Flag unverifiable intent explicitly. Unknown intent can stay a lead or become a research task; it cannot become an unqualified refactor candidate.

**Exit rule:** a smell whose "why" has not been checked may remain an `SL<N>` lead, but does not become an `R<N>` candidate.

---

## 4. Triage and Scoring

### 4.1 Four-state triage

Every inspected smell becomes exactly one of:

- **Smell lead (`SL<N>`).** Interesting structural tension with evidence, but incomplete diagnosis or uncertain remediation. This is the default for non-obvious signals.
- **Refactor candidate (`R<N>`).** Evidence sufficient, why recovered, payoff real, risk manageable.
- **Research task (`RT<N>`).** Needs live evidence, production data, runtime traces, user behaviour, or external API facts before it can be judged.
- **Leave alone.** Imperfect but reasonable, or messy with fix cost exceeding current value.

**Modifier: `+ document-intent`.** A leave-alone item may produce `DI<N>` when the right action is a one-line comment preserving load-bearing intent. If many items need this modifier, the threshold is too loose.

### 4.2 Scoring order

Promote toward `R<N>` when the item:

1. Improves cold-read readability for an experienced developer.
2. Removes non-essential code or protects an essential trust boundary.
3. Lowers cognitive load at the call, render, or review site.
4. Gives an implicit policy, predicate, or ceremony a clear name.
5. Moves behaviour closer to the data it decides about.
6. Closes silent failure, CQS, or name-vs-behaviour mismatch.
7. Reduces real maintenance cost or bug risk.
8. Minimizes churn.

Items citing only 7-8 are allowed, but must carry visible justification.

### 4.3 Stable namespaces

- **`SL<N>`** — structural smell lead; investigate before execution planning.
- **`R<N>`** — promoted refactor candidate; suitable input for a separate execution plan.
- **`RT<N>`** — research task blocked by live or external evidence.
- **`DI<N>`** — document-intent micro-candidate.

IDs are monotonically increasing and never reused. Per-area investigators use local placeholders such as `API1` or `COMP2`; the coordinator assigns stable IDs during synthesis.

---

## 5. Cross-cutting Signals

Apply these across every area:

- Nested ternaries, inline boolean chains with > 3 terms, and core logic at indent >= 3.
- Silent `.catch`, `catch { return [] }`, or `.catch(console.error)` without stated degradation semantics.
- Names that under-describe behaviour.
- Ask-instead-of-tell decisions about domain objects.
- Loose types such as `Record<string, any>`, `any[]`, `unknown as`, non-null `!`, and `as any`; promote only after reading callers.
- Repeated ceremony across >= 5 sites, even when code differs.
- Files that frequently co-change without explicit dependency.
- Tests with heavy setup gravity or duplicated fixtures encoding hidden policy.
- Docs, comments, tests, and implementation disagreeing on terms or behaviour.

---

## 6. Synthesis Across Areas

After per-area notes are produced, run synthesis before writing the discovery document.

1. **Lead clustering.** Merge leads only when the same lens, same underlying policy/tension, and same evidence shape are present. Otherwise keep separate and link via thematic group.
2. **Promotion check.** Promote `SL` to `R` only after the why gate passes and remediation shape is clear.
3. **Temporal coupling escalation.** Repeated co-change across >= 3 commits or >= 3 files becomes a high-signal lead. Promote only if the shared change reason is current and refactorable.
4. **Ceremony-counting escalation.** Same >= 2-concept ceremony across >= 5 sites with identical intent becomes an architectural lead or candidate.
5. **Layering consistency.** Items touching the same data path must agree on direction.
6. **Principle conflicts.** Make trade-offs explicit; higher-priority principle wins.
7. **Dependency edges.** Use stable IDs only. Do not attach rollout order or implementation phasing.
8. **Coverage.** Every area must produce at least a one-line verdict.

---

## 7. Anti-patterns to Avoid

1. Turning every smell lead into a refactor candidate.
2. Introducing speculative generic frameworks without enumerated current sites.
3. Merging files that form useful boundaries.
4. Deduplicating code that only looks similar.
5. Treating temporal co-change as proof without reading the commits.
6. Tightening types against external data speculatively.
7. Decomposing large files purely to reduce file size.
8. Over-extracting helpers from thick handlers.
9. Combining observability work with policy design.
10. Treating docs or plans as evidence without checking live code.
11. Producing findings from grep hits alone.
12. Producing candidates without the why check.
13. Adding a comment when rename or split is feasible.
14. Extracting orchestration only for testability.
15. Raising findings against the wrong layer.
16. Smuggling rollout order into candidate descriptions.
17. Forcing symmetry where asymmetry has a valid domain reason.

---

## 8. Output Shape

### 8.1 Discovery document sections

1. **Executive Summary** — 5-10 bullets, highest-signal `SL`, `R`, `RT`, and `DI` items.
2. **Investigation Leads (`SL<N>`)** — structural smells worth human attention.
3. **Promoted Refactor Candidates (`R<N>`)** — actionable refactor candidates.
4. **Research Tasks (`RT<N>`)** — evidence-gathering work.
5. **Document-Intent Items (`DI<N>`)** — one-line comments preserving intent.
6. **Prioritized Roadmap** — Do next / Do later / Do not do now.
7. **Lens Coverage** — which discovery lenses produced useful signal.
8. **Areas Inspected With No Findings** — one-line verdict per area.
9. **Thematic Groups** — related leads/candidates that should be reviewed together.
10. **Open Questions and Assumptions**.

Per entry:

- All: Stable ID, title, area, files, lens/principles, evidence, why status, risk, bucket, dependency edges.
- `SL<N>` adds: anomaly, why it is suspicious, what to inspect next, promotion condition.
- `R<N>` adds: recommended refactor shape, cognitive-load delta, expected benefit, scope.
- `RT<N>` adds: blocked-on evidence and expected promotion path.
- `DI<N>` adds: proposed one-line comment wording.

### 8.2 Length guidance

- Executive Summary: 5-10 bullets, each <= 2 lines.
- `SL<N>` entries: <= 10 lines. `R<N>` entries: <= 13 lines. `RT<N>`: <= 10 lines. `DI<N>`: <= 6 lines.
- Roadmap: one line per ID plus one-sentence rationale per bucket.
- Total ceiling: ~30 KB.

### 8.3 Per-area note template

```markdown
# Area: <name>   (pass: <pass-id>, commit: <SHA>)

## Enumeration
<file list with: LOC, behavioural coverage marker, intent source>

## Purposes (one-liners)
<per-file purpose + intent source(s) used>

## Lens Scan
- Temporal coupling: <signal | none | not checked>
- Change amplification: <signal | none | not checked>
- Shotgun ceremony: <signal | none | not checked>
- Semantic drift: <signal | none | not checked>
- Asymmetric abstractions: <signal | none | not checked>
- Hidden policy: <signal | none | not checked>
- Test gravity: <signal | none | not checked>
- Negative space: <signal | none | not checked>

## Smell Leads
- [<PLACEHOLDER-ID>] <title>: lens / evidence / why-status / suspicion / inspect-next / risk / bucket

## Promoted Refactor Candidates
- [<PLACEHOLDER-ID>] <title>: evidence / intent / principles / recommended shape / risk / scope / bucket

## Acceptable as-is
- <file>: one-line reason   [+ document-intent: Y ("...") if load-bearing]

## Looks messy, leave alone
- <file>: one-line reason + why the fix would cascade

## Research tasks
- <item>: why it needs live evidence

## Open questions / assumptions
```

### 8.4 Evidence format

```text
path/to/file.ts:<Lstart>[-Lend] @<SHA-short> -- "<verbatim pattern or <= 80-char quote>"
```

For temporal coupling evidence, use:

```text
commit <SHA-short> -- touched <fileA>, <fileB>, <fileC> for "<commit subject>"
```

---

## 9. Self-checks

Before declaring a pass done:

1. Every `R<N>` cites at least one principle and passes the why gate.
2. Every `SL<N>` states its lens, suspicion, why-status, and promotion condition.
3. Every `RT<N>` states what evidence is missing and why local code reading is insufficient.
4. Every claimed duplication has behaviour comparison or a byte-by-byte diff recorded.
5. Every universal claim has an enumeration recorded.
6. Every temporal-coupling claim cites commit evidence.
7. Every area has a one-line verdict.
8. Every stable item is anchored to the pinned commit SHA or explicit commit-history evidence.
9. Dependency edges reference existing stable IDs only.
10. Namespace discipline is correct: `SL`, `R`, `RT`, `DI`.
11. No `SL<N>` is described as directly executable; execution starts from `R<N>` or a separate research task.

A pass that fails any gate is not done.

---

## 10. Cadence

Run full discovery for mature areas, architectural uncertainty, or periodic debt review. Prefer scoped discovery for day-to-day use: a directory, class, module, or concern plus adjacent areas.

Re-run per refactor work-unit (single merged PR or batch of <= 5 related PRs within 14 days). Delta re-runs cover touched areas plus adjacents. Full re-run when >= 3 work-units have landed or a core abstraction changed.

Fast path for non-structural PRs: one-line registry entry instead of a delta document.
