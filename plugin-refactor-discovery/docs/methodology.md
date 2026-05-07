# Refactor Discovery — Methodology Reference

This document is the canonical reference for the refactor-discovery methodology. It defines principles, investigation discipline, scoring, synthesis rules, anti-patterns, output shape, and self-checks. The SKILL.md orchestrator and the area-investigator subagent both draw from this material.

**Core discipline:** before proposing to change any piece of code, understand **why it is the way it is**. Most bad refactor proposals come from misreading intent — code that looks duplicated is often two divergent solutions to two different problems; a silent `.catch` is sometimes load-bearing degradation; a thick handler is sometimes the correct home for that orchestration.

---

## 1. Guiding Principles (decision criteria)

Every candidate must cite at least one. A candidate that cannot cite one is rejected. Principles are listed in **decreasing priority**: when two conflict on the same candidate, the higher one wins.

1. **Readability for an experienced programmer.** Target reader: a senior developer familiar with the project's language/framework who has **not** seen this file before. If that reader needs to pause, re-read, or open unrelated files to understand what a block does, the block is unclear. Surface signals: deeply nested conditionals, overloaded names, unexplained shortcuts, template expressions that pack three unrelated checks into one branch.

2. **Essentiality.** Prefer code where removing anything breaks real behaviour. Defensive additions that catch nothing in practice, validators wrapping already-typed data, try/catch around calls that cannot reasonably fail, intermediate abstractions with one caller — all are candidates to collapse. **Counterpoint:** input validation at trust boundaries (schema validation on action input, session/auth checks, external data parsing) is essential — removing it would accept invalid input silently. "Essential" is not "minimal in the cosmetic sense"; it is "nothing that doesn't earn its keep."

3. **Cognitive Load Minimization.** The metric is not "fewer lines" but "fewer things the reader must hold in their head." Indicators: nested ternaries (> 1 level), boolean expressions with > 3 terms inline, handler bodies whose core logic lives at indent >= 3 because guard conditions are inverted, single files mixing I/O + business rules + presentation.

4. **Abstraction via Naming.** A complex expression, predicate, or calculation should carry a name that describes its intent.
   - Inline boolean like `isLoading && results.length === 0 && query.length >= MIN` -> extract as `const showLoadingIcon = ...` at the top of the block.
   - Inline predicate reused in >= 2 sites -> extract as helper.
   - **DRY, narrow form:** duplicated *knowledge* — same business rule, mapping rule, or behavioural contract in two places — must converge on one name. Duplicated *code that happens to look similar* is not a target under this principle.

5. **Tell, Don't Ask.** When a block interrogates an object's fields to make a decision *about that object*, the decision belongs near the data. Preferred shapes:
   - a) Named function in a domain module (default).
   - b) Class wrapper when >= 3-4 correlated predicates on the same type earn a single home.

6. **Fail Fast, Fail Loud.** A silent failure is technical debt. Patterns that swallow errors without a *stated* reason are smells. If the swallow is deliberate (graceful degradation, optional enrichment), the code must carry a one-line comment stating *why* the error is acceptable and *what* the caller sees; otherwise replace with a propagating error or a typed `{ data, error }` return.

7. **Command-Query Separation.** A function returns data (query) *or* mutates state (command), not both. When a function must do both (common with external API wrappers that return data + require state updates), the mutation contract must be visible at the call site via naming, typing, or a site-level comment. **Cross-cutting escalation:** when the *same* mutation ceremony recurs across >= 5 call sites with identical intent, the primary remediation escalates from per-site documentation to architectural (move the ceremony into the abstraction).

8. **Principle of Least Surprise.** A name should predict the behaviour. `getX` that mutates is surprising; `createY` that silently reads from storage is surprising; a function that returns `null` on a transient error is surprising. Preferred remediation order: rename > split > document-at-site.

9. **Comments only for the "why" not derivable from code.** A comment that restates the code is noise. A comment that records intent a reader cannot recover from the code is evidence. **Trigger test:** if removing the comment leaves an experienced reader uncertain *why* the code chose this shape, keep it; if it only explains *what*, drop it.

**Explicitly not used as drivers:**
- DRY as a generic "reduce duplication" rule (only duplicated *knowledge* counts — principle 4)
- SRP, Open/Closed, Liskov, abstract SOLID adherence (can justify speculative abstraction)
- Inheritance-based designs
- "Make illegal states unrepresentable" as a standalone driver
- Extract pure functions purely for testability (must earn its keep on principles 3-5)
- Cosmetic consistency with low payoff
- Locality of Behavior (can force arrangements that hurt readability)
- Explicit over Implicit (risks promoting verbose code; hidden magic is caught by principle 8)

---

## 2. Investigation Discipline — the "why" gate

Before any candidate is raised, the investigator must have a defensible answer to **why the code is the way it is**. This section is a gate, not a preamble.

For every smell that looks like a refactor candidate, run these checks:

1. **Read the file end-to-end, not just in grep hits.** A pattern that looks wrong in isolation is often the right answer inside the file's real contract.
2. **Read the behavioural contract encoded in tests.** Prefer direct unit specs when they exist. Escalate: integration specs -> e2e tests -> upstream/downstream specs. Absence of a direct spec is an evidence gap to record, not a process blocker.
3. **Read neighbouring call sites.** Grep every caller and skim their expectations. A weak return type is sometimes deliberate.
4. **Recover history for the specific lines.** Use `git log -L :funcName:path` for named functions. For anonymous blocks, fall back to `git blame -L <start>,<end> <file>` plus `git show <commit>` on each implicated SHA. Commits named `fix(...)`, `refactor(...)`, or referencing a ticket often document the constraint.
5. **Search for adjacent planning / review docs.** Not finding one means the intent is only encoded in the code itself.
6. **Distinguish intent-encoding comments from noise.** `// keep this -- handles quirk where ...` is load-bearing. `// TODO clean up` is not.
7. **Before claiming "this is duplicated," diff the two sites byte-by-byte.** Visual similarity != duplicated knowledge. Only promote when two sites produce the same output from the same input by the same rule.
8. **Before claiming "only X uses this," enumerate.** Grep the export across the entire repo. A universal claim without an enumeration is a conjecture.
9. **Identify load-bearing degradation.** A silent `.catch(() => undefined)` can be a deliberate soft-fail. Confirm against call sites and the product behaviour before classifying.
10. **Flag unverifiable intent explicitly.** If the "why" cannot be recovered, write it down as an assumption. Assumptions are legitimate inputs; undeclared assumptions are not.

**Exit rule:** a smell whose "why" has not been checked does not become a candidate.

---

## 3. Scoring Rule and Verdict

### 3.1 Scoring (implicit priority order, mirrors S1)

1. Improves readability for a senior dev reading the file cold (P1)
2. Adds essential coverage at a trust boundary OR removes non-essential code (P2)
3. Lowers cognitive load at the call / render / read site (P3, P4)
4. Brings domain behaviour closer to domain data (P5)
5. Closes a silent-failure gap, a CQS mismatch, or a name-vs-behaviour mismatch (P6, P7, P8)
6. Reduces real maintenance cost and bug risk
7. Minimizes churn

A candidate citing only criteria 6-7 without any claim on 1-5 is admissible but should carry visible justification.

### 3.2 Three-state verdict

Every piece of code inspected produces exactly one of:

- **Refactor candidate** — evidence sufficient; payoff real; risk manageable.
- **Acceptable as-is** — imperfect but reasonable; leave alone.
- **Looks messy, leave alone** — size or smell is real, but refactor cost exceeds value today.

**Modifier: `+ document-intent`.** Either leave-alone state may carry this modifier when the item's intent is load-bearing and not yet captured in code. Canonical triggers: deliberate silent `.catch` fallbacks, non-null assertions safe only because of a preceding guard, resilient-read return shapes. Rules:
- State the proposed one-line comment wording inline.
- Modified items produce `DI<N>` micro-candidates.
- If > ~30% of an area's "acceptable as-is" entries carry the modifier, the threshold is wrong — tighten.

### 3.3 Candidate tags and stable IDs

Three separate namespaces:
- **`R<N>`** (refactor) — structural code change.
- **`RT<N>`** (research task) — NOT promoted because live evidence is missing (runtime traces, live API responses, production data).
- **`DI<N>`** (document-intent) — micro-candidate, one-line comment edit.

All three namespaces are monotonically increasing, never reused. Assigned by the coordinator during synthesis, never by per-area investigators.

**Placeholder IDs during per-area work.** Each area investigator uses a local prefix (the area's slug, e.g. `API1`, `COMP2`) that synthesis renumbers into `R<N>` / `RT<N>` / `DI<N>`.

---

## 4. Cross-cutting Signals (apply to every area)

- **Nested ternaries / long inline booleans.** Ternary > 1 level; `&&`/`||` chain with > 3 terms. **Principles 3, 4.** Extract as named local or derived value.
- **Core logic at indent >= 3.** Main work starts 3+ levels deep because guards are positive branches. **Principle 3.** Invert to guard clauses.
- **Silent error swallow without stated reason.** `.catch(() => undefined)`, `catch { return [] }`, `.catch(console.error)` with no comment. **Principle 6.** Remediation: propagate > typed `{ data, error }` > document inline.
- **Name that under-describes behaviour.** `getX` that also mutates; `createY` that reads from storage. **Principle 8.** Remediation: rename > split > document-at-site.
- **Ask-instead-of-tell on domain objects.** Blocks pulling fields to compute a predicate about the same object. **Principle 5.**
- **Loose types.** `Record<string, any>`, `any[]`, `unknown`, non-null `!`, `as any`. **Principles 3, 8.** Promote only after reading call sites. Tightening against external shapes is a research task, not a refactor task.

---

## 5. Synthesis Across Areas (anti-divergence)

After per-area notes are produced, run synthesis before writing the discovery document.

1. **Same smell across areas — merge only when remediation matches.** Merge into single cross-cutting candidate only when: (a) same principle violated, (b) same refactor shape, (c) comparable risk surface. When (a) holds but (b) or (c) does not, keep separate and link via "thematic group" note.
2. **Ceremony-counting escalation.** Same >= 2-line pattern across >= 5 sites with identical intent -> primary candidate is architectural, not site-local.
3. **Layering consistency.** Candidates in different layers proposing changes to the same data path must be consistent in direction.
4. **Conflicts between principles.** Make trade-offs explicit. Higher-priority principle wins.
5. **Dependency edges between candidates.** Use stable IDs only. Do NOT attach rollout order or implementation phasing.
6. **Coverage.** Every area must produce at least a one-line verdict. A silent gap means the area wasn't looked at.

---

## 6. Anti-patterns to Avoid During Investigation

1. **Introducing speculative generic frameworks** without an enumeration of concrete sites that would use them today. **Counterpoint:** when enumeration shows >= 5 identical ceremonies, the infrastructure candidate is earned.
2. **Merging files that form useful boundaries** (e.g. components sharing a shell but diverging in event contract).
3. **Deduplicating UI/code that only looks similar** — check behaviour, not syntax.
4. **Tightening types against external data speculatively** — without live evidence. Mark as research task.
5. **Decomposing large files purely to reduce file size** — size is a symptom, not the disease.
6. **Over-extracting helpers from thick handlers** — a few targeted extractions help; fragmenting into many tiny functions usually doesn't.
7. **Combining observability work with policy design** — fix visibility, don't simultaneously introduce severity classification.
8. **Treating consistency between planning documents as evidence** — verify against live code.
9. **Producing candidates from grep hits alone** — grep is a seed, the S2 "why" gate is the filter.
10. **Producing candidates without the "why" check.**
11. **Forcing a class wrapper on plain DTOs when 1-2 named functions would do.** Promote to class only when >= 3-4 correlated predicates earn a single home.
12. **Extracting a name/variable with no cognitive-load payoff.** Trigger is reader load at the call site, not occurrence count.
13. **Adding a comment to document a surprise when rename/split is feasible.** P8 remediation order: rename > split > document-at-site.
14. **Extracting orchestration "for testability" without a readability payoff.**
15. **Classifying SSR/server data plumbing as a component smell** — raise against the correct layer.
16. **Smuggling rollout order into candidate descriptions** — candidates carry dependency edges, not sequences.

---

## 7. Output Shape

### 7.1 Discovery Document sections

1. **Executive Summary** — 5-10 bullets, highest-signal findings by stable ID.
2. **Candidate List (all namespaces).** Every `R<N>`, `RT<N>`, `DI<N>`. Per entry:
   - All: Stable ID, Title, Area, Files, Why it matters now, Principles involved, Evidence (commit SHA + file + lines + verbatim), Intent recovered, Risk, Bucket, Dependency edges.
   - `R<N>` adds: Recommended refactor shape, Cognitive-load delta, Expected benefit, Scope.
   - `RT<N>` adds: Blocked-on, Expected promotion path.
   - `DI<N>` adds: Proposed one-line comment wording.
3. **Prioritized Roadmap** — three buckets: Do next / Do later / Do not do now.
4. **Anti-patterns observed** — repo-specific additions.
5. **Review Heuristics** — compact checklist for PR template.
6. **Areas inspected with no candidates** — one-line verdict per area.
7. **Thematic groups** (optional).
8. **Open questions and assumptions.**

### 7.2 Length guidance

- Executive Summary: 5-10 bullets, each <= 2 lines.
- `R<N>` entries: <= 13 lines. `RT<N>`: <= 10 lines. `DI<N>`: <= 6 lines.
- Roadmap: one line per ID + one-sentence rationale per bucket.
- Total ceiling: ~30 KB.

### 7.3 Per-area note template

```
# Area: <name>   (pass: <pass-id>, commit: <SHA>)

## Enumeration
<file list with: LOC, behavioural coverage marker, intent source>

## Purposes (one-liners)
<per-file purpose + intent source(s) used>

## Findings
- [<PLACEHOLDER-ID>] <title>: evidence / intent / verdict / risk / scope / bucket

## Acceptable as-is
- <file>: one-line reason   [+ document-intent: Y ("...") if load-bearing]

## Looks messy, leave alone
- <file>: one-line reason + why the fix would cascade

## Research tasks
- <item>: why it needs live evidence

## Open questions / assumptions
```

### 7.4 Evidence format

```
path/to/file.ts:<Lstart>[-Lend] @<SHA-short> -- "<verbatim pattern or <= 80-char quote>"
```

---

## 8. Self-checks (coherence gates)

Before declaring a pass done, confirm all gates:

1. Every candidate cites at least one S1 principle.
2. Every candidate has intent evidence (S2: file read + spec/test reference, blame/history, or explicit "no intent recoverable -- assumption" note).
3. Every claimed duplication has a byte-by-byte diff recorded (S2 rule 7).
4. Every universal claim has an enumeration recorded (S2 rule 8).
5. Every area has a one-line verdict in the output (coverage from S5.6).
6. Every candidate is anchored to the pass's pinned commit SHA and carries a stable ID.
7. Every candidate's rollout ordering is expressed as dependency edges only.
8. Namespace discipline: refactor -> `R<N>`; blocked on live evidence -> `RT<N>`; leave-alone with load-bearing intent -> `DI<N>`.
9. Dependency-edge closure: every ID referenced in a dependency edge exists in the same discovery doc or is cited as historical.

A pass that fails any gate is not done.

---

## 9. Cadence (re-run rules)

Re-run **per refactor work-unit** (single merged PR or batch of <= 5 small related PRs within 14 days). Delta re-runs cover touched areas + adjacents. Full re-run when >= 3 work-units have landed or a core abstraction changed.

**Fast-path** for non-structural PRs (copy/i18n, styling, test-only, local renames, dependency bumps): one-line registry entry instead of delta doc.
