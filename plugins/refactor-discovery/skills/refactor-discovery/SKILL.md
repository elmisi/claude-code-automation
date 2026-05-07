---
name: refactor-discovery
description: Research methodology to surface non-obvious structural smell leads before promoting refactor candidates. Discovers project areas, investigates with parallel subagents when available, synthesizes cross-cutting tensions, and produces a prioritized discovery document with stable IDs and dependency edges.
disable-model-invocation: true
argument-hint: [optional: subdirectory, class, module, or concern to focus on — omit for full project]
allowed-tools: [Agent, Bash, Read, Write, Glob, Grep, TodoWrite]
effort: max
---

# Refactor Discovery — Smell-Led Pass

You are a refactor discovery coordinator. Your job is to run a systematic investigation of the codebase and produce a discovery document that surfaces structural smells worth human attention. You promote only mature findings to refactor candidates. You do NOT implement any item; execution belongs to a separate phase.

The user's request: **$ARGUMENTS**

---

## How this works

1. Pin the codebase snapshot and load the methodology.
2. Resolve scope and identify investigation areas.
3. Spawn parallel area investigators when the runtime supports it, or run area investigations serially.
4. Synthesize smell leads, promoted candidates, research tasks, and document-intent items.
5. Assemble the discovery document and run coherence checks.
6. Update the registry and report to the user.

**Critical rules:**
- NEVER implement code changes. Only investigate and document.
- NEVER assign stable `SL<N>` / `R<N>` / `RT<N>` / `DI<N>` IDs until synthesis.
- A smell lead may carry partial or unknown intent if it says so explicitly.
- A promoted refactor candidate must pass the "why" gate and cite at least one principle.
- Do not flatten uncertainty into advice. Preserve it as `SL` or `RT`.

---

## Step 0: Setup

1. **Pin the commit SHA:**
   ```bash
   git rev-parse HEAD
   ```
   Record this SHA. Line evidence in the pass is anchored to it.

2. **Determine the pass ID:** use today's date as `YYYY-MM-DD`. If `docs/refactor-discovery/<date>/` exists, append `-2`, `-3`, etc.

3. **Create the output directory:**
   ```bash
   mkdir -p docs/refactor-discovery/<pass-id>
   ```

4. **Load the methodology:** read `../../docs/methodology.md` relative to this `SKILL.md`. In Claude Code this resolves as `${CLAUDE_SKILL_DIR}/../../docs/methodology.md`. It defines lenses, triage, synthesis, output shape, and self-checks.

5. **Check prior passes:** if `docs/refactor-discovery/registry.md` exists, read it. New IDs must start after the highest existing ID in each namespace: `SL`, `R`, `RT`, `DI`.

---

## Step 1: Scope Resolution and Area Discovery

Determine whether `$ARGUMENTS` describes a broad pass or a specific target.

- **Full-project mode:** empty or generic input such as "find refactor opportunities".
- **Scoped mode:** a directory, file pattern, class, module, symbol, or concern such as "error handling in checkout".

### Full-project mode

Map the project:

1. List source files:
   ```bash
   find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.svelte' -o -name '*.astro' -o -name '*.vue' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.java' -o -name '*.kt' -o -name '*.swift' -o -name '*.cs' \) | grep -v node_modules | grep -v dist | grep -v build | grep -v '.git/' | grep -v vendor
   ```

2. List directories:
   ```bash
   find . -maxdepth 3 -type d | grep -v node_modules | grep -v dist | grep -v build | grep -v '.git/' | grep -v vendor
   ```

3. Count LOC by top-level source directory.
4. Read key config files (`package.json`, `tsconfig.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, etc.).

Identify 3-8 areas using cohesion, independence, balanced effort, and natural architecture layers.

### Scoped mode

Resolve the target:

1. For a path, verify it exists, list contents, and count LOC.
2. For a class/module/symbol, grep to locate definitions and main callers.
3. For a concern, grep related terms and group involved files by directory proximity.

If the target cannot be resolved, ask the user to clarify before proceeding.

Discover adjacent areas:

- Outbound imports from the primary area.
- Inbound consumers of primary exports.
- Shared types, schemas, contracts, and fixtures.
- Tests exercising the primary area.
- Temporal neighbours: files that repeatedly co-change with the primary area.

Include an adjacent when it has direct consumers with >= 3 call sites, owns contracts likely to change, shares a domain data path, or repeatedly co-changes with the primary area for the same reason. Exclude generated and third-party layers.

### Record areas

For each area record:

- Name and filename slug.
- Paths.
- Estimated file count and LOC.
- Layer classification: presentation, business, data, infrastructure, cross-cutting, tests, docs.
- Placeholder prefix, such as `API`, `COMP`, `SVC`.
- Scope role: `primary` or `adjacent`.

---

## Step 2: Parallel Investigation

For each area, spawn an **area-investigator** subagent when the runtime supports plugin agents. Use the `area-investigator` agent defined in this plugin. If the runtime does not support subagents, run the same investigation cycle yourself for each area and write the same per-area notes.

Include in each prompt:

- Area name, paths, and scope role.
- Commit SHA and pass ID.
- Output path: `docs/refactor-discovery/<pass-id>/area-<slug>.md`.
- Methodology path: `../../docs/methodology.md` relative to this skill file. In Claude Code use `${CLAUDE_SKILL_DIR}/../../docs/methodology.md`.
- User's original focus, if scoped.

When subagents are available, spawn ALL area subagents in one message so they run in parallel.

Example prompt:

```text
Investigate the "<area-name>" area for structural smell leads and promoted refactor candidates.

Area paths: <paths>
Scope role: primary | adjacent
Commit SHA: <sha>
Pass ID: <pass-id>
Output: docs/refactor-discovery/<pass-id>/area-<slug>.md
Methodology: <methodology-path> (read this first; use a runtime-relative equivalent if needed)
User focus: <original arguments, if any>

Run the full cycle: Enumerate -> Read-for-Intent -> Lens-and-Smell-Scan -> Evidence -> Triage -> Write per-area note. Use placeholder IDs with prefix "<PREFIX>".

Use smell leads for suspicious tensions that are not yet executable. Promote only when the why gate passes and remediation shape is clear. If this is an adjacent area, focus on interfaces, contracts, temporal coupling, and data paths connected to the primary area.

Do not assign stable SL/R/RT/DI IDs.
```

After subagents complete, read every per-area note. Note malformed or incomplete sections, but proceed to synthesis unless the missing content blocks all useful output.

---

## Step 3: Verify Per-area Notes

For each `docs/refactor-discovery/<pass-id>/area-*.md`, verify:

1. Commit SHA matches the pinned SHA.
2. Evidence lines use canonical file evidence or temporal-coupling evidence.
3. Placeholder IDs use the correct area prefix.
4. `Smell Leads` include lens, why-status, suspicion, and inspect-next.
5. `Promoted Refactor Candidates` cite principles and intent evidence.
6. Research tasks state what live/external evidence is needed.
7. Acceptable and leave-alone entries have one-line reasons.
8. Lens scan states signal, none, or not checked for each lens.

Build a consolidated list of all items across areas.

---

## Step 4: Synthesis

This is where you prevent local findings from contradicting each other.

### 4.1 Assign stable IDs

Walk through all per-area items:

- **Smell lead** -> assign `SL<N>`.
- **Promoted refactor candidate** -> assign `R<N>`.
- **Research task** -> assign `RT<N>`.
- **Leave-alone with `+ document-intent`** -> assign `DI<N>`.

Start after the highest existing ID in each namespace, or at 1. Record the mapping from placeholders to stable IDs.

### 4.2 Run synthesis checks

1. **Lead clustering:** merge only when lens, underlying tension, and evidence shape match. Otherwise keep separate and link via thematic group.
2. **Promotion check:** promote `SL` to `R` only if the why gate passes, payoff is real, risk is manageable, and remediation shape is clear.
3. **Temporal coupling escalation:** repeated co-change across >= 3 commits or >= 3 files becomes a high-signal lead. Promote only if the shared reason is current and refactorable.
4. **Change-amplification check:** if one conceptual change touches many layers, ask whether a hidden policy lacks a name or owner.
5. **Ceremony-counting escalation:** the same >= 2-concept ceremony across >= 5 sites becomes an architectural lead or candidate.
6. **Semantic drift check:** terms in docs, tests, names, comments, and implementation must tell the same story before promotion.
7. **Layering consistency:** items touching the same data path must agree in direction.
8. **Principle conflicts:** state trade-offs explicitly; higher-priority principle wins.
9. **Dependency edges:** use stable IDs only. Do not include implementation sequencing.
10. **Coverage:** every area must have a one-line verdict.

### 4.3 Assign buckets

For each stable item:

- **Do next** — high signal and low investigation/execution risk.
- **Do later** — real signal but blocked by dependencies, risk, or lower urgency.
- **Do not do now** — speculative, high risk, or low payoff.

`SL` items can be Do next when the next action is investigation, not implementation.

---

## Step 5: Assemble the Discovery Document

Write `docs/refactor-discovery/<pass-id>/discovery.md`:

```markdown
# Refactor Discovery — Pass <pass-id>

**Commit:** <full SHA>
**Date:** <YYYY-MM-DD>
**Scope:** <"full project" or user's original argument>
**Primary areas:** <list>
**Adjacent areas:** <list or "none">
**Methodology:** smell-led refactor-discovery methodology

---

## 1. Executive Summary

<5-10 bullets, highest-signal SL/R/RT/DI items>

---

## 2. Investigation Leads

#### SL<N>: <Title>
- **Area:** <area name>
- **Files:** <paths>
- **Lens:** <temporal coupling | change amplification | shotgun ceremony | semantic drift | asymmetric abstractions | hidden policy | test gravity | negative space | cross-cutting signal>
- **Why it is suspicious:** <one sentence>
- **Evidence:** <canonical evidence lines>
- **Why-status:** recovered | partial | unknown-assumption
- **Inspect next:** <specific next investigation>
- **Promotion condition:** <what would turn this into R or RT>
- **Risk:** low | medium | high
- **Bucket:** Do next | Do later | Do not do now
- **Depends on:** <stable IDs or "none">

---

## 3. Promoted Refactor Candidates

#### R<N>: <Title>
- **Area:** <area name>
- **Files:** <paths>
- **Why it matters now:** <one sentence>
- **Principles:** <cite methodology principle numbers>
- **Evidence:** <canonical evidence lines>
- **Intent recovered:** <one line + source(s)>
- **Recommended shape:** <rename/extract/split/collapse/architectural — not implementation>
- **Cognitive-load delta:** lower | same | higher
- **Expected benefit:** <one sentence>
- **Risk:** low | medium | high
- **Scope:** small | medium | large
- **Bucket:** Do next | Do later | Do not do now
- **Depends on:** <stable IDs or "none">

---

## 4. Research Tasks

#### RT<N>: <Title>
- **Area:** <area name>
- **Files:** <paths>
- **Why it matters now:** <one sentence>
- **Evidence:** <canonical evidence lines>
- **Blocked on:** <live/external evidence required>
- **Expected promotion path:** <what R or SL it could become>
- **Risk:** low | medium | high
- **Bucket:** Do next | Do later | Do not do now
- **Depends on:** <stable IDs or "none">

---

## 5. Document-Intent Items

#### DI<N>: <Title>
- **Area:** <area name>
- **File:** <path + line range>
- **Proposed comment:** `<verbatim wording>`
- **Why:** <what future maintainer might break>
- **Principles:** <cite methodology principle numbers>
- **Bucket:** Do next | Do later | Do not do now

---

## 6. Prioritized Roadmap

### Do next
- <ID>: <one-line rationale>

### Do later
- <ID>: <one-line rationale>

### Do not do now
- <ID>: <one-line rationale>

---

## 7. Lens Coverage

- Temporal coupling: <signal summary | none>
- Change amplification: <signal summary | none>
- Shotgun ceremony: <signal summary | none>
- Semantic drift: <signal summary | none>
- Asymmetric abstractions: <signal summary | none>
- Hidden policy: <signal summary | none>
- Test gravity: <signal summary | none>
- Negative space: <signal summary | none>

---

## 8. Areas With No Findings

- <area>: <one-line verdict>

---

## 9. Thematic Groups

<Related SL/R/RT/DI clusters, if any>

---

## 10. Open Questions and Assumptions

<Unresolvable items lifted from per-area notes>
```

---

## Step 6: Self-checks

Run every coherence gate from methodology section 9:

1. Every `R<N>` cites principles and passes the why gate.
2. Every `SL<N>` states lens, suspicion, why-status, and promotion condition.
3. Every `RT<N>` states missing evidence and why local reading is insufficient.
4. Every duplication claim includes behaviour comparison or a byte-by-byte diff.
5. Every universal claim has an enumeration.
6. Every temporal-coupling claim cites commit evidence.
7. Every area has a one-line verdict.
8. Every stable item is anchored to the pinned commit or explicit history evidence.
9. Dependency edges reference existing stable IDs only.
10. Namespace discipline is correct.
11. No `SL<N>` is described as directly executable.

If any gate fails, fix the discovery document before proceeding.

---

## Step 7: Registry

If `docs/refactor-discovery/registry.md` exists, append a new entry. Otherwise create it.

```markdown
## <pass-id> — <full | scoped: "user's argument"> @<SHA-short>
- Scope: <full project | user's argument verbatim>
- Primary areas: <list>
- Adjacent areas: <list or "none">
- Opened: <all new SL/R/RT/DI IDs>
- Promoted refactors: <new R IDs or "none">
- Notes: <relevant context>
```

---

## Step 8: Report

Tell the user:

```text
Discovery pass complete: docs/refactor-discovery/<pass-id>/discovery.md

<N> findings across <M> areas:
- <SL count> smell leads (SLx-SLy)
- <R count> promoted refactor candidates (Rx-Ry)
- <RT count> research tasks (RTx-RTy)
- <DI count> document-intent items (DIx-DIy)

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

1. Read the discovery document.
2. Find all lines matching `> **NOTE**:`.
3. For each annotation, understand it, update the document, and remove the resolved note.
4. Re-run affected self-checks.
5. Report how many notes were processed and what changed.

---

## Repeat Until Approved

The annotation cycle continues until the user approves.

When approved:

```text
Discovery pass approved: docs/refactor-discovery/<pass-id>/discovery.md

Use R<N> items as inputs to execution planning.
Use SL<N> items as investigation prompts.
Use RT<N> items to gather missing evidence.
The discovery document is the reference — do not modify it during execution.
```

Do NOT start implementing. The user decides when and how to execute or investigate findings.
