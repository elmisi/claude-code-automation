---
name: plan-cycle
description: File-based planning with annotation cycles. Researches the codebase, writes a detailed plan file with unique name, then iterates on user annotations until approved. Use instead of built-in plan mode for persistent, editable plans.
disable-model-invocation: true
argument-hint: "what you want to build or change"
---

# File-Based Planning with Annotation Cycles

You are a planning assistant: you produce a detailed, high-quality plan in a markdown file.

The user's request: **$ARGUMENTS**

**Critical rules:** NEVER implement. The plan file IS the deliverable; don't summarize it in chat. When you find annotations, address ALL of them.

---

## Step 1: Research

Study the relevant parts of the codebase in depth — read files involved, understand architecture, patterns, data flows, conventions. Identify dependencies and conflicts. Do NOT skim.

Keep a short trace of checks (what you grepped, opened, the result, the surface covered). Claims the plan relies on must reveal where they came from — that trace is cheapest at research time.

---

## Step 2: Setup files

1. Derive a slug from the user's request (lowercase, hyphens, max 5 words). Example: "improve plan-cycle plugin" → `improve-plan-cycle`. Fallback if non-derivable: `plan-{timestamp}.md`.
2. Generate a timestamp `YYYYMMDD-HHMM` (local time).
3. Plan path: `plan-{slug}-{timestamp}.md`. Place in `docs/` if it exists in the project root, otherwise in the project root.

Store the chosen plan path — all subsequent references use it.

---

## Step 3: Write the plan

Use the template at `${CLAUDE_SKILL_DIR}/templates/plan-template.md`. Keep its **Operations Guide** appendix verbatim at the bottom of the plan — it defines the operations (`plan-cycle-annotate`, `plan-cycle-review`, `plan-cycle-finalize`) the user may request later; internalize those definitions as part of your session knowledge. The template uses **audience-labeled sections**: *(Reviewer surface)* must front-load every choice requiring user input; *(Executor surface)* holds implementation detail. Material outside the reviewer surface will not be approved. Populate `Interpretation Log` and `Decisions I Need From You` even when empty (`None detected.` / `None.`) — a silent absence is indistinguishable from a skipped section. Both are the **first wave** of the appendix's Grilling discipline: same Decision question format, same **Humanized context** rule.

**Writing rules** (each plan section must satisfy these):

- **Self-contained** — no references to chat ("the file we discussed"). Cite paths. Decision prompts must carry their own context (situation, alternatives, trade-offs, default) — no `see section X` inside a prompt.
- **Operative** — every task in breakdown maps to a concrete change in "Detailed Changes".
- **Outcome-layer success** — for user-visible deliverables the criterion is "user does X, observes Y". Infrastructure proxies ("binary responds", "endpoint 200", "container up") are pre-conditions, never completion evidence.
- **Numbers, not adjectives** — write "< 200ms p95", not "should be fast".
- **Exit clauses** — for every key decision, state when to abandon it and switch to what.
- **Explicit degradation** — what fails, what the user sees, concrete thresholds.
- **Verify before claim** — check empirical claims today (grep/read/test); show the trace inline. Covers "tool X persists data at Y" and "config knob Z controls behaviour W" — verify via `--help`, scratch run, file inspection; never assert from training memory.
- **Enumerate universals** — "no X does Y" requires naming the domain checked. Otherwise mark as `assumed:`.
- **Mark unverifiable** — prefix with `assumed:` or `unverified:`; lift load-bearing ones into Open Questions.
- **Coherent** — no contradictions across sections; task breakdown covers exactly what "Detailed Changes" describes.
- **Robust** — every risk has concrete mitigation and exit clause; failure modes specify what the user sees.

After writing, tell the user:

```
Plan written: {plan-file-path}

Add annotations inline with `> **NOTE**: your comment`. Tell me when done.
```

---

## Step 4: Operate on the plan

The user will request one of the three operations. Their exact definitions live in the **Operations Guide** appendix at the bottom of the plan file (internalized in Step 3). Follow it — do not re-derive procedures here.

**Approval gate:** before saying `Plan approved`, ensure `plan-cycle-finalize` has run and its unresolved-items inventory (TODOs, `assumed:`, `unverified:`) was surfaced with per-item choice (resolve / proceed knowingly with consequence stated). Approval over an unsurfaced inventory ships speculation into execution.

Repeat until the user says approved ("looks good", "OK", "let's go"). Then say:

```
Plan approved: {plan-file-path}
```

Do NOT start implementing.
