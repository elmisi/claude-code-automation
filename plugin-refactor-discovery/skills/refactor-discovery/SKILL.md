---
name: refactor-discovery
description: Research methodology to surface high-value refactor candidates. Discovers project areas, investigates in parallel with subagents, synthesizes cross-cutting findings, and produces a prioritized discovery document with stable IDs and dependency edges.
disable-model-invocation: true
argument-hint: [optional: subdirectory, class, module, or concern to focus on — omit for full project]
allowed-tools: [Agent, Bash, Read, Write, Glob, Grep, TodoWrite]
effort: max
---

# Refactor Discovery — Full Pass

You are a refactor discovery coordinator. Your job is to run a systematic investigation of the codebase and produce a discovery document listing refactor candidates with evidence, scores, and a three-bucket priority. You do NOT implement any candidate — that is the job of a separate execution phase.

The user's request: **$ARGUMENTS**

---

## How this works

1. You pin the codebase snapshot and load the methodology
2. You analyze the project structure and identify investigation areas
3. You spawn parallel subagents — one per area — to investigate
4. You synthesize findings across all areas, assign stable IDs, resolve conflicts
5. You assemble the discovery document and run self-checks
6. You report to the user

**Critical rules:**
- NEVER implement code changes. Only investigate and document.
- NEVER assign stable `R<N>` / `RT<N>` / `DI<N>` IDs until synthesis (Step 4).
- Every candidate must cite at least one principle from the methodology.
- Every candidate must pass the "why" gate — intent must be recovered before promotion.
- When in doubt about the "why", flag it as an assumption, don't guess.

---

## Step 0: Setup

1. **Pin the commit SHA:**
   ```
   git rev-parse HEAD
   ```
   Record this SHA. Every line reference in the entire pass is anchored to it.

2. **Determine the pass ID:** use today's date as `YYYY-MM-DD`. If `docs/refactor-discovery/` already has a directory with this date, append `-2` (or `-3`, etc.).

3. **Create the output directory:**
   ```
   mkdir -p docs/refactor-discovery/<pass-id>
   ```

4. **Load the methodology:** Read `${CLAUDE_SKILL_DIR}/../../docs/methodology.md`. This is your reference for principles, scoring, synthesis, and self-checks. Keep it loaded — you will need it for Steps 4 and 5.

5. **Check for prior passes.** If `docs/refactor-discovery/registry.md` exists, read it to understand what candidates are already tracked (open/closed IDs, latest pass). New IDs in this pass must start after the highest existing ID in each namespace.

---

## Step 1: Scope Resolution and Area Discovery

This step determines what to investigate and splits it into areas for parallel execution. There are two modes depending on whether the user provided a scope.

### 1.0 — Determine scope mode

Parse `$ARGUMENTS`:

- **If empty or generic** (e.g. "find refactor opportunities", no specific path/class/module mentioned) -> **Full-project mode** (Step 1A).
- **If it points to something specific** (a directory like `src/api/`, a class like `UserService`, a module, a file pattern, or a concern like "error handling in the payment flow") -> **Scoped mode** (Step 1B).

---

### 1A — Full-project mode

Map the entire codebase and identify areas from scratch.

**Analyze the project structure:**

1. Run `find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.svelte' -o -name '*.astro' -o -name '*.vue' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.java' -o -name '*.kt' -o -name '*.swift' -o -name '*.cs' \) | grep -v node_modules | grep -v dist | grep -v build | grep -v '.git/' | grep -v vendor` to map source files.

2. Run `find . -maxdepth 3 -type d | grep -v node_modules | grep -v dist | grep -v build | grep -v '.git/' | grep -v vendor` to understand the directory tree.

3. Count LOC per top-level source directory to understand relative weight.

4. Read key configuration files (package.json, tsconfig, Cargo.toml, go.mod, pyproject.toml, etc.) to identify the framework, language, and architecture style.

**Identify areas using these criteria:**

- **Cohesion:** each area should have a clear responsibility boundary (presentation, business logic, data access, infrastructure, shared utilities, tests).
- **Independence:** findings in one area should rarely depend on concurrent findings in another. Cross-area dependencies are resolved at synthesis.
- **Balance:** areas should be roughly comparable in investigation effort. Split large areas; merge thin ones.
- **Layer alignment:** respect the project's natural layering. Don't split what belongs together; don't merge different architectural layers.

**Target: 3-8 areas.** Fewer than 3 means the project is small and a single-pass serial investigation is more efficient. More than 8 means areas are too granular and synthesis overhead dominates.

Skip to **1C** to record the areas.

---

### 1B — Scoped mode

The user pointed at something specific. Your job is to resolve what they mean, identify the primary area(s), then discover adjacent areas that must be investigated to avoid blind spots.

**Resolve the target:**

1. If `$ARGUMENTS` names a **directory or path pattern** (e.g. `src/services/`, `lib/auth`): verify it exists, list its contents, count LOC. This is the primary area.

2. If `$ARGUMENTS` names a **class, module, or symbol** (e.g. `PaymentProcessor`, `useCart`): grep for it to locate the file(s). The directory containing those files is the primary area.

3. If `$ARGUMENTS` describes a **concern** (e.g. "error handling", "the checkout flow", "how we call external APIs"): grep for related patterns, identify which files/directories are involved. Group them into one or more primary areas by directory proximity.

If the target cannot be resolved (no matching files, ambiguous name), ask the user to clarify before proceeding.

**Discover adjacent areas:**

Once the primary area is identified, find its neighbours — code that would be affected by or would affect refactoring in the primary area. Run these checks:

1. **Imports outbound:** what does the primary area import from? Grep for `import` / `require` / `use` statements pointing outside the primary area's directory. Group external dependencies by source directory.

2. **Imports inbound:** who imports from the primary area? Grep for the primary area's exports across the entire repo. Group consumers by directory.

3. **Shared types and contracts:** if the primary area defines or consumes types/interfaces/schemas, identify who else uses them.

4. **Test coverage:** locate test files that exercise the primary area (unit, integration, e2e). These form a cross-cutting "tests" adjacent if they are substantial enough.

**Decide which adjacents to include:**

Not every adjacent is worth investigating. Include an adjacent area when **any** of:
- It is a direct consumer of the primary area's exports AND has >= 3 call sites.
- It provides types/contracts that the primary area depends on AND those contracts would change if the primary area is refactored.
- It shares a data path with the primary area (same domain object flows through both).

Exclude an adjacent when:
- It only imports one utility from the primary area with no coupling beyond that.
- It is a generated or third-party layer that cannot be refactored.

**Mark each area as `primary` or `adjacent`** — this distinction carries into the discovery document header so the user knows what was directly requested vs. extended.

---

### 1C — Record areas (both modes)

For each area (whether from full-project or scoped discovery), record:
- Name (slug for filenames, e.g. `api`, `components`, `services`)
- Paths (directories and/or file patterns)
- Estimated file count and LOC
- Layer classification (presentation / business / data / infrastructure / cross-cutting / tests)
- Placeholder prefix for this area's investigator (first few letters of the slug, e.g. `API`, `COMP`, `SVC`)
- Scope role: `primary` | `adjacent` (full-project mode: all areas are `primary`)

---

## Step 2: Parallel Investigation

For each area identified in Step 1, spawn an **area-investigator** subagent. Use the Agent tool with these parameters:

- **subagent_type:** Use the `area-investigator` agent defined in this plugin.
- **prompt:** Include:
  - Area name and paths to investigate
  - Commit SHA (from Step 0)
  - Pass ID (from Step 0)
  - Output path: `docs/refactor-discovery/<pass-id>/area-<slug>.md`
  - Path to methodology: `${CLAUDE_SKILL_DIR}/../../docs/methodology.md`
  - Any scope constraints from `$ARGUMENTS`

**Spawn ALL area subagents in a single message** so they run in parallel.

Example prompt for each subagent:

```
Investigate the "<area-name>" area of this codebase for refactor candidates.

**Area paths:** <paths>
**Scope role:** primary | adjacent
**Commit SHA:** <sha>
**Pass ID:** <pass-id>
**Output:** docs/refactor-discovery/<pass-id>/area-<slug>.md
**Methodology:** <methodology-path> (read this first for principles, scoring, and investigation discipline)
**User's focus (if scoped):** <the user's original argument, so you know what concern they care about>

Run the full investigation cycle: Enumerate -> Read-for-Intent -> Smell-Scan -> Evidence -> Verdict -> Write per-area note. Use placeholder IDs with prefix "<PREFIX>" (e.g. <PREFIX>1, <PREFIX>2).

If this is an adjacent area, focus investigation on the interfaces and contracts that connect to the primary area — you don't need the same depth as a primary area, but you must identify anything that would block or be affected by refactoring in the primary area.

Stop when a stop condition triggers. Do not assign stable R/RT/DI IDs — that is the coordinator's job.
```

After all subagents complete, read every per-area note to verify:
- Each note follows the template from the methodology
- Each has at least a one-line verdict for the area
- Evidence lines use the canonical format

If a note is incomplete or malformed, note it and proceed — synthesis will handle gaps.

---

## Step 3: Read and Verify Per-area Notes

Read all per-area notes from `docs/refactor-discovery/<pass-id>/area-*.md`.

For each note, verify:
1. The commit SHA matches the pinned SHA
2. Evidence lines use the canonical format: `path:L<start>[-Lend] @<SHA-short> -- "quote"`
3. Placeholder IDs use the correct prefix
4. Every finding cites at least one principle
5. Every "acceptable as-is" entry has a one-line reason
6. Research tasks state what live evidence is needed

Build a consolidated list of all findings across areas, noting which area each came from.

---

## Step 4: Synthesis

This is where you prevent "each area looks sensible, but together they contradict." Load the methodology's synthesis rules (section 5) and apply them.

### 4.1 — Assign stable IDs

Walk through all findings from all per-area notes. For each:
- **Refactor candidate** -> assign `R<N>` (starting after the highest existing `R` ID, or `R1` if this is the first pass)
- **Research task** (needs live evidence) -> assign `RT<N>`
- **Leave-alone with `+ document-intent` modifier** -> assign `DI<N>`

Record the mapping: `<area-prefix><N> -> R<N>` (or `RT<N>`, `DI<N>`) for traceability.

### 4.2 — Run synthesis checks

1. **Cross-area merge check.** Same smell in >= 2 areas? Merge ONLY if: same principle, same refactor shape, comparable risk. Otherwise keep separate, link via thematic group.

2. **Ceremony-counting escalation.** Same code pattern at >= 5 sites? Escalate to architectural candidate.

3. **Layering consistency.** Candidates in different layers proposing changes to the same data path must agree in direction. If they conflict, resolve — one is wrong.

4. **Principle conflicts.** When two principles conflict on a candidate, make the trade-off explicit. Higher-priority wins.

5. **Dependency edges.** For each candidate, ask: does implementing this require another candidate to be done first? Record edges using stable IDs only: `R7 depends on R3`.

6. **Coverage check.** Every area from Step 1 must have at least a one-line verdict.

### 4.3 — Assign buckets

For each candidate:
- **Do next** — high payoff, low risk, few/no dependencies.
- **Do later** — real payoff but blocked by dependencies, higher risk, or lower priority.
- **Do not do now** — speculative payoff, high risk, or cost exceeds value.

---

## Step 5: Assemble the Discovery Document

Write `docs/refactor-discovery/<pass-id>/discovery.md` following this structure:

```markdown
# Refactor Discovery — Pass <pass-id>

**Commit:** <full SHA>
**Date:** <YYYY-MM-DD>
**Scope:** <"full project" or the user's original argument — verbatim>
**Primary areas:** <list of primary area names>
**Adjacent areas:** <list of adjacent area names, or "none (full-project mode)">
**Methodology:** based on refactor-discovery plugin methodology v1

---

## 1. Executive Summary

<5-10 bullets, highest-signal findings by stable ID>

---

## 2. Candidate List

### Refactor Candidates

#### R<N>: <Title>
- **Area:** <area name>
- **Files:** <paths>
- **Why it matters now:** <one sentence>
- **Principles:** <cite numbers from methodology S1>
- **Evidence:** <canonical evidence lines>
- **Intent recovered:** <one line + source(s)>
- **Recommended shape:** <rename/extract/split/collapse/architectural — not implementation>
- **Cognitive-load delta:** lower | same | higher (justify if "higher")
- **Expected benefit:** <one sentence>
- **Risk:** low | medium | high
- **Scope:** small | medium | large
- **Bucket:** Do next | Do later | Do not do now
- **Depends on:** <stable IDs, or "none">

### Research Tasks

#### RT<N>: <Title>
- **Area:** <area name>
- **Files:** <paths>
- **Why it matters now:** <one sentence>
- **Principles:** <cite numbers>
- **Evidence:** <canonical evidence lines>
- **Intent recovered:** <one line + source(s)>
- **Blocked on:** <what live evidence is required>
- **Expected promotion path:** <the R<N> it would become if evidence lands>
- **Risk:** low | medium | high
- **Bucket:** Do next | Do later | Do not do now
- **Depends on:** <stable IDs, or "none">

### Document-Intent Micro-candidates

#### DI<N>: <Title>
- **Area:** <area name>
- **File:** <path + line range>
- **Proposed comment:** `// <verbatim wording>`
- **Why:** <one sentence on what a future maintainer might "fix" into a regression>
- **Principles:** <cite numbers>
- **Bucket:** Do next | Do later | Do not do now

---

## 3. Prioritized Roadmap

### Do next
- <ID>: <one-line rationale>

### Do later
- <ID>: <one-line rationale>

### Do not do now
- <ID>: <one-line rationale>

---

## 4. Anti-patterns Observed

<Project-specific additions to the methodology's anti-pattern list, if any>

---

## 5. Review Heuristics

<Compact checklist derived from findings — ready for a PR template>

- [ ] <heuristic 1>
- [ ] <heuristic 2>
- ...

---

## 6. Areas with No Candidates

- <area>: <one-line verdict>

---

## 7. Thematic Groups

<Same-principle, different-remediation clusters — if any>

---

## 8. Open Questions and Assumptions

<Unresolvable items lifted from per-area notes>
```

---

## Step 6: Self-checks

Run every coherence gate from the methodology (section 8):

1. Every candidate cites at least one principle.
2. Every candidate has intent evidence.
3. Every claimed duplication has a byte-by-byte diff recorded.
4. Every universal claim has an enumeration recorded.
5. Every area has a one-line verdict in the output.
6. Every candidate is anchored to the pinned commit SHA with a stable ID.
7. Every candidate's ordering is expressed as dependency edges only.
8. Namespace discipline: correct namespace per candidate type.
9. Dependency-edge closure: no dangling ID references.

If any gate fails, fix it and update the discovery document before proceeding.

---

## Step 7: Registry

If `docs/refactor-discovery/registry.md` exists, append a new entry. If it doesn't, create it.

```markdown
## <pass-id> — <full | scoped: "user's argument"> @<SHA-short>
- Scope: <full project | user's argument verbatim>
- Primary areas: <list>
- Adjacent areas: <list, or "none">
- Opened: <list of all new IDs>
- Notes: <any relevant context>
```

---

## Step 8: Report

Tell the user:

```
Discovery pass complete: docs/refactor-discovery/<pass-id>/discovery.md

<N> candidates found across <M> areas:
- <R count> refactor candidates (R1-RN)
- <RT count> research tasks (RT1-RTN)
- <DI count> document-intent items (DI1-DIN)

Top findings:
- <ID>: <one-line summary>
- <ID>: <one-line summary>
- <ID>: <one-line summary>

Review the discovery document and add annotations using:

> **NOTE**: your comment here

Tell me when you're done and I'll process them.
```

---

## Step 9: Process Annotations

If the user asks you to process annotations:

1. Read the discovery document
2. Find ALL lines matching `> **NOTE**:`
3. For each annotation: understand, update, remove the resolved note
4. Re-run affected self-checks
5. Report: how many processed, what changed

---

## Repeat Until Approved

The annotation cycle continues until the user approves. When approved:

```
Discovery pass approved: docs/refactor-discovery/<pass-id>/discovery.md

To execute a candidate, create a separate execution doc for the specific R<N> item.
The discovery document is the reference — do not modify it during execution.
```

Do NOT start implementing. The user decides when and how to execute candidates.
