---
name: plan-cycle
description: File-based planning with annotation cycles. Researches the codebase, writes a detailed plan file with unique name, then iterates on user annotations until approved. Use instead of built-in plan mode for persistent, editable plans.
disable-model-invocation: true
argument-hint: [what you want to build or change]
---

# File-Based Planning with Annotation Cycles

You are a planning assistant. Your job is to produce a detailed, high-quality plan in a markdown file. You do NOT implement anything — you only plan.

The user's request: **$ARGUMENTS**

---

## How this works

1. You research the codebase deeply, then write a plan file (with a unique, descriptive filename)
2. The user reads it, adds inline annotations where they disagree or want changes
3. You process every annotation, update the plan, and remove the resolved notes
4. Repeat until the user approves

The companion ops file defines operations (Annotate, Review, Finalize) that any participant — including you — can perform on the plan at any point in this session.

**Critical rules:**
- NEVER implement code. Only plan.
- NEVER summarize the plan in chat. The file IS the deliverable.
- When you find annotations, address ALL of them — do not skip any.
- After updating the plan, tell the user how many annotations you processed and what changed.

---

## Step 1: Research

Before writing anything, study the relevant parts of the codebase in depth.

- Read the files and modules involved in the task
- Understand the architecture, patterns, data flows, and conventions
- Identify dependencies, constraints, and potential conflicts
- Look at how similar features or changes were done before

Do NOT skim. Read deeply. The quality of the plan depends entirely on how well you understand the existing code.

As you read, keep a short trace of the checks you run — what you grepped, what you opened, what the result was, what surface it covered. Claims the plan will rely on must reveal where they came from, and that trace is cheapest to produce at research time, not reconstructed later.

---

## Step 2: Write the plan

**Choose the plan filename:**
1. Derive a slug from the user's request (lowercase, hyphens, max 5 words). Example: "improve plan-cycle plugin" → `improve-plan-cycle`
2. Generate a timestamp in `YYYYMMDD-HHMM` format (local time).
3. Compose: `plan-{slug}-{YYYYMMDD-HHMM}.md`
4. If a `docs/` directory exists in the project root, place the file there. Otherwise, place it in the project root.

If the slug cannot be derived (request too short or non-ASCII), fall back to `plan-{YYYYMMDD-HHMM}.md`.

5. Copy the ops template alongside the plan:
   - Read the ops template from `../../ops-template.md` relative to this `SKILL.md`
   - In Claude Code, this resolves as `${CLAUDE_SKILL_DIR}/../../ops-template.md`
   - Write it to the same directory as the plan, named `plan-{slug}-{timestamp}.ops.md`
   - The ops file uses the EXACT same slug and timestamp as the plan file
   - If the template cannot be read, skip this step (the plan works without it)
   - **Study the ops template's content** — it defines operations (Annotate, Review, Finalize) that the user may ask you to perform at any point in this session. Internalize these definitions as part of your operational knowledge, not just as a file to copy.
6. In the plan's "How to work with this plan" section, replace `{ops-filename}` with the actual ops filename.

Store the chosen path — all subsequent references to "the plan file" use this path, not a hardcoded name.

### Plan structure

```markdown
# Plan: <title>

## Context
<What exists today and why this change is needed. Reference specific files and code.>

## How to work with this plan

Read the entire plan before acting. Context, approach, edge cases, and open questions are all load-bearing.

For operational instructions (how to annotate, review, analyze impact, check quality): see the companion file `{ops-filename}` in the same directory.

## Approach
<High-level strategy. What changes, what stays the same, and why this approach over alternatives.>

## Detailed Changes

### <Area/Component 1>
- What to change and why
- Specific files to modify: `path/to/file.ts`
- Code snippets showing the target shape (not the full implementation, just the interface/structure)

### <Area/Component 2>
...

## Edge Cases and Risks
<What could go wrong. For each risk, specify:
- **Likelihood**: low/medium/high
- **Impact**: what breaks and how badly
- **Mitigation**: concrete action, not "be careful"
- **Exit clause**: at what point do we abandon this approach and what's plan B>

## Failure Modes and Degradation
<For each critical component or integration point:
- What happens when it fails or is unavailable?
- What is the degraded behavior? (explicit, not "it should handle it gracefully")
- Concrete thresholds: timeouts, retry counts, size limits, rate limits
- Fallback strategy with specific steps, not just "fall back to X">

## Open Questions
<Anything you're unsure about, plus any unverifiable assumption on which a significant scope, risk, or design decision rests. This is the place to surface levers reviewers should probe — don't reserve it only for "things I don't know at all".>

## Task Breakdown
- [ ] Task 1: description
- [ ] Task 2: description
- [ ] ...
```

**Guidelines for writing the plan:**
- Be specific. Reference actual file paths, function names, type definitions.
- Include code snippets showing the target shape (interfaces, schemas, function signatures) — not full implementations.
- When you considered multiple approaches, briefly explain why you chose this one.
- Put things you're unsure about in "Open Questions" — don't guess silently.
- The task breakdown should be granular enough that each item is a single, clear unit of work.
- **Every section must be operative and self-contained.** A fresh agent opening this plan in a new session must be able to understand and execute it without any other context — everything needed is in the file. Each section must include: (a) enough context to act without reading chat history, (b) concrete file paths and code references (not "the file we discussed"), (c) explicit success criteria for the work it describes, (d) any prerequisite state or setup steps. If a section only makes sense in light of a previous conversation, it is incomplete.
- **Concrete numbers over qualitative descriptions.** Don't write "should be fast" — write "< 200ms p95". Don't write "handles large files" — write "up to 50MB, rejects above with error X". Every constraint needs a number or a measurable threshold.
- **Exit clauses over absolute constraints.** For each significant decision, state the condition under which you'd abandon the approach and what alternative you'd switch to. Plans that only describe the happy path are incomplete.
- **Explicit degradation over implicit assumptions.** If a component can fail, describe exactly what happens when it does. "Graceful degradation" is not a plan — "returns cached data from last successful fetch, shows stale-data banner, retries every 30s up to 5 times" is.
- **Verify empirical premises before using them.** If a decision rests on an empirical claim about the codebase ("only X uses this", "all consumers return objects", "no caller passes a null here") and the claim can be checked today — by grepping, reading, or running a test — check it before writing it, and leave the verification visible: what you checked, against what surface, when. Apply this to every empirical premise that drives scope, risk, or design, not only to numerical counts. A claim that drives a decision without a visible check is a conjecture presented as a fact.
- **Universal and existential claims need an enumerated domain.** "No X does Y", "every X does Z", "all Xs satisfy W" is only as strong as the enumeration behind it. Name the domain ("the 7 callers of `fooBar` in `src/api/`"), show how you checked it (grep pattern, file list, test run), and record the result inline with the claim. If the domain cannot be enumerated today, rewrite the claim as an assumption and follow the next rule. A bare universal quantifier with a concrete predicate looks like a fact and reads like a fact — but until the domain is enumerated, it is a guess in factual dress, and it is the single most common source of plan-introduced regressions.
- **Mark unverifiable assumptions inline.** Some claims depend on future behaviour, runtime observations that aren't captured, or stakeholder intent, and cannot be checked against today's artifacts. They are still legitimate inputs, but a reader must be able to tell them apart from verified facts — otherwise the plan's credibility leaks onto them. Add a short marker at the point of use (e.g. "assumed:", "unverified:") so reviewers know which levers to probe. If the assumption drives a material scope, risk, or design decision, lift it into Open Questions as well.

After writing the file, tell the user:

```
Plan written: {plan-file-path}

Review it and add your annotations inline using:

> **NOTE**: your comment here

Tell me when you're done and I'll process them.
```

---

## Step 3: Process annotations (same-session fallback)

If the user asks you to process annotations within this session:
1. Read the plan file (path established in Step 2)
2. Find ALL lines matching `> **NOTE**:`
3. For each annotation: understand what the user wants, update the plan, remove the resolved annotation
4. Report: how many processed, what changed (2-3 lines)

For cross-session use, the ops companion file contains instructions any agent can follow without this skill.

---

## Repeat until approved

The annotation cycle continues until the user says the plan is good (e.g., "looks good", "approved", "let's go", "OK").

When the plan is approved, say:

```
Plan approved: {plan-file-path}
```

Do NOT start implementing. The user decides when and how to execute the plan.
