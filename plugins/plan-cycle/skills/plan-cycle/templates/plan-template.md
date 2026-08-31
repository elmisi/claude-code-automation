# Plan: <title>

## How to work with this plan

Sections labeled *(Reviewer surface)* require user input before approval — read them in full.
Sections labeled *(Executor surface)* are the implementer's baseline — reviewers may skip.

For operations (annotate / review / finalize): see the **Operations Guide** appendix at the bottom of this file.

## Context *(Reviewer surface)*
<What exists today, why this change is needed. Cite specific files and code.>

## Interpretation Log *(Reviewer surface)*

Every interpretive choice the planner made on the user's request. This section is part of the **first wave** of the Grilling discipline (see appendix): each entry uses the five-field **Decision question** format and obeys the **Humanized context** rule.

- **Read "<phrase from request>" as <chosen reading>.**
  - **Context:** <what the phrase referred to, in plain language — restate the substance, do not merely cite it>.
  - **Why it matters:** <what part of the plan depends on this reading>.
  - **Options:** <chosen reading> / <alternative Y> / <alternative Z>.
  - **Trade-offs:** <chosen → ...>; <Y → ...>; <Z → ...>.
  - **Recommendation:** <chosen reading>, because <one line>. This stands if you do not answer.
  - **Status:** `Confirm or correct.`

The **Status** line is the entry's state, and it is the only record of it — do not drop it. `plan-cycle-review` sets it to `Confirmed.` when you confirm the reading, or rewrites the entry when you correct it. A deferred question in `Decisions I Need From You` is asked only once the entry it waits on reads `Confirmed.`, so without this line a fresh agent cannot tell which readings are settled.

If no ambiguities detected, write `None detected.` — never leave the section empty.

## Approach *(Reviewer surface)*
<High-level strategy. What changes, what stays the same, and why this approach over alternatives.>

## Decisions I Need From You *(Reviewer surface)*

Planner uncertainty requiring user input. This section is part of the **first wave** of the Grilling discipline (see appendix): each entry uses the five-field **Decision question** format and obeys the **Humanized context** rule. The single exception is a **deferred** entry — one that depends on an `Interpretation Log` reading and is therefore not being asked yet: it carries a plain-language **Context** and a **Waiting on:** pointer, and nothing else. Every entry MUST be self-contained — no `see section X` references, and a deferred entry must still say in plain words what is being deferred.

- **Q1 — <one-line title naming the decision>**
  - **Context:** <the situation in plain language; restate the substance of anything the question depends on, then cite the reference next to it>.
  - **Why it matters:** <what changes depending on the answer>.
  - **Options:** <A> / <B>.
  - **Trade-offs:** <A → concrete consequence>; <B → concrete consequence>.
  - **Recommendation:** <choice>, because <one line>. This is also what the planner assumes if you do not answer.

- **Q2 — <one-line title naming the decision>**
  - **Context:** <what this decision is about, in plain words — enough to know what is being deferred without going to look it up>.
  - **Waiting on:** <the Interpretation Log entry whose confirmation decides this, restated in a few words>. Not asked in this wave — `plan-cycle-review` asks it in full once that reading is settled.

If no open decisions, write `None.` — never leave the section empty.

## Detailed Changes *(Executor surface)*

### <Area/Component>
- What to change and why.
- Files: `path/to/file.ts`.
- Target shape snippet (interface, signature) — not full implementation.
- **User-visible success criterion:** user does X, observes Y. Infrastructure checks ("binary responds", "endpoint returns 200", "service starts") are pre-conditions, not completion evidence.

## Edge Cases and Risks *(Executor surface)*
<Per risk: **Likelihood**, **Impact**, **Mitigation** (concrete), **Exit clause** (when to abandon and switch to what).>

## Failure Modes and Degradation *(Executor surface)*
<Per critical component: failure mode → degraded behaviour (explicit) → thresholds (timeouts, retries, limits) → fallback steps.>

## Task Breakdown *(Executor surface)*
- [ ] Task 1: description + inline outcome criterion.
- [ ] Task 2: ...

---

## Operations Guide *(Appendix — instructions for any agent operating on this plan)*

Operations available on this plan. Any coding agent can follow these instructions.

## Operation Dispatch Rule

Identify the requested operation by the user's **exact** wording:

- `plan-cycle-annotate` → run section `## plan-cycle-annotate`.
- `plan-cycle-review` → run section `## plan-cycle-review`.
- `plan-cycle-finalize` → run section `## plan-cycle-finalize`.

**No aliases.** If wording doesn't exactly match one of the three, do NOT execute: reply

> Operazione non riconosciuta. Le operazioni valide su questo piano sono: `plan-cycle-annotate`, `plan-cycle-review`, `plan-cycle-finalize`.

Existing `> **NOTE**:` lines don't change the requested operation. For `plan-cycle-annotate`, never edit/remove/resolve/rewrite existing plan content.

## Grilling discipline

When an operation needs decisions from you, it grills. The discipline has **two renditions of one criterion**. Which rendition applies is decided by where the questions are delivered — never by the agent's judgement of the moment.

- **Interactive rendition** — live conversation, no document in front of the reader: **one question at a time**, wait for the answer before asking the next.
- **Document rendition** — this plan, reviewed over multiple passes. This is the default here. The first pass carries **every question that has no dependency on another**. When answers open new branches, the next pass carries every newly-unblocked question that has no dependency on another. Repeat until no branch is left open.

Two questions are dependent — and MUST NOT share a pass — if the answer to one would change the answer to the other, or change whether the other still needs asking.

**Ordering.** Within a pass, most critical first — the questions whose answers change the most other answers — then the marginal ones.

**Scope fence.** Only the request under discussion. Do not drift into adjacent topics, however tempting.

**Explore before asking.** If the codebase or the plan can answer it, investigate and state the finding instead of asking.

**Termination.** Continue until shared understanding is reached and no branch is left open.

### Question format, by kind of request

There are two kinds. The **operation that produces the request** decides which — not the agent's assessment of length or importance.

**Decision question** — produced by a freshly written plan, by `plan-cycle-review` when an annotation is unclear, or whenever the planner is uncertain. Five fields, all mandatory:

- **Context** — the situation in plain language.
- **Why it matters** — what changes depending on the answer.
- **Options** — the possible choices, named.
- **Trade-offs** — the concrete consequence of each option.
- **Recommendation** — the suggested answer with a one-line reason; it is also what the planner assumes if you do not answer.

**Unresolved item** — produced only by the closing inventory of `plan-cycle-finalize`. Not an open question but a known gap with a binary choice, so it carries a shorter format. Four fields:

- **What is unresolved** — the item, quoted or cited.
- **Why it cannot be settled now** — the verification that is missing.
- **Consequence of proceeding as-is** — concrete, never "may cause issues".
- **Recommendation** — resolve before execution, or proceed knowingly.

### Humanized context

The plan stays rigorous: paths, signatures, thresholds and markers are mandatory wherever they belong. But **wherever the document asks instead of describing** — the Interpretation Log, Decisions I Need From You, the unresolved-items inventory, and any question raised during review — the context must be humanized:

- **A citation is a pointer, not an explanation.** Never rely on naming a thing to make it understood.
- If a question depends on a constraint, a decision or another section, **restate its substance in plain words inside the question**, then put the reference next to it.
- No internal codes, section numbers or question numbers standing in for the thing itself. A sentence such as "constraint A2 conflicts with S3 in the solution to Q1" carries a cognitive load that makes it useless, however accurate it is.

No pass re-checks this automatically. If a question is unclear or badly framed, annotate it — see the **Unclear question** intent below. That annotation is the correction mechanism.

### First wave

The **Interpretation Log** and **Decisions I Need From You** sections of a freshly written plan *are* the first wave of the document rendition; `plan-cycle-review` and `plan-cycle-finalize` carry the waves that follow. All of them use the same Decision question format above — there is one question format across the whole cycle.

**Dependencies inside the first wave.** The two sections share one pass, so the dependency rule binds across them. A `Decisions I Need From You` entry whose answer — or whose very relevance — depends on how an `Interpretation Log` entry is confirmed **MUST NOT** be asked in this wave. Instead, list it with a plain-language **Context** — the Humanized context rule still binds, so a bare cross-reference is not enough — plus `**Waiting on:** <the Interpretation Log entry it depends on>`, and no options and no recommendation. Step 5 of `plan-cycle-review` asks it as a full Decision question once the entry it waits on reads **Status:** `Confirmed.` — the marker in the document, not the agent's memory of the conversation, is what unblocks it. Any question still waiting when `plan-cycle-finalize` runs is released there: an unconfirmed reading stands as written, so it counts as settled and the question is finally asked.

## plan-cycle-annotate

**Purpose.** Annotations are the review channel on this plan. They exist to **find what is wrong with it and to make it better before anyone executes it** — errors, gaps, unstated assumptions, weak criteria, missed improvements. An annotation *marks* the plan; it never changes it. Multiple annotation passes may run before a single review pass, so a pass is worth running even when it finds one thing.

**What to annotate.** Use this as a checklist on every pass — a plan that reads well is not the same as a plan that is right:

- **Factual error** — a claim about the codebase that is wrong. *"This file does not export that symbol."*
- **Gap** — something the plan must cover and does not. *"Nothing says what happens to records that already exist."*
- **Assumption sold as certainty** — a claim stated flatly that was never verified. *"Was this checked, or assumed?"*
- **Disagreement with the approach** — the plan is coherent but the strategy is wrong. *"This should extend the existing pipeline, not add a second one."*
- **Success criterion that is not user-observable** — the criterion checks infrastructure, not outcome. *"'Service starts' does not prove a user can do anything."*
- **Risk without an exit clause** — a risk is named but nothing says when to abandon it. *"When do we give up on this, and switch to what?"*
- **Request for clarification** — something you cannot evaluate because you do not understand it. *"What does 'compatible' mean here, concretely?"*
- **Unclear question** — a question the plan asks *you* that you cannot decide on as written. *"Explain this better."* Nothing re-checks question quality automatically; this annotation is the correction mechanism.
- **Improvement proposal** — the plan is not wrong, but it could be better. *"Doing this in the same pass would halve the work."*

**Format:** `> **NOTE**: [tag?] comment`. Tags: `[impact]` (plan-impact skill), `[quality: <criterion>]` (plan-quality skill), none (user). `plan-cycle-review` processes all uniformly — the list above classifies **intent**, not syntax, and introduces no new tags.

Add annotations below the section/task they refer to. Do NOT modify plan content — only add notes.

**Safety check:** before editing, state "plan-cycle-annotate mode: I will only add `> **NOTE**:` lines." After editing, verify the diff only adds notes + blank spacing; if it removes/modifies non-note text, revert and redo.

## plan-cycle-review

1. Read the entire plan.
2. Find all `> **NOTE**:` lines.
3. For each: understand, update plan, remove annotation. If the annotation confirms an `Interpretation Log` reading, set that entry's **Status** to `Confirmed.` **before** removing the note — step 5 reads that marker, and removing the note destroys the only other evidence that the reading was settled.
4. If unclear, keep the annotation and resolve it via the **Grilling discipline** (above), using the **Decision question** format.
5. **Deferred questions** — scan `Decisions I Need From You` for entries marked `Waiting on:`. Ask, in this pass and as a full **Decision question** (all five fields), every one whose blocking `Interpretation Log` entry now reads **Status:** `Confirmed.`, and drop its `Waiting on:` marker; leave the others waiting. The test is the marker in the document, never your recollection of the conversation — a fresh agent has no recollection, and this step must work for it too. Without this step a deferred question is never posed and merely resurfaces in the closing inventory.

## plan-cycle-finalize

Make the plan operative, self-contained, coherent, robust — a fresh agent must execute it without prior context.

1. Read the entire plan.
2. For each section, check ALL 11 rules: Self-contained, Operative, Outcome-layer success, Numbers-not-adjectives, Exit clauses, Explicit degradation, Verify-before-claim, Enumerate-universals, Mark-unverifiable, Coherent, Robust.
3. Rewrite every failing section — do not annotate.
4. Report: sections updated count + one-line summary per section.
5. **Release the still-waiting questions** — an `Interpretation Log` entry whose **Status** never became `Confirmed.` stands as written; its own Recommendation says so. It is therefore settled now, by default, and nothing is gained by waiting further. Ask every remaining `Waiting on:` question as a full **Decision question**, replacing its `Waiting on:` line with `**Released at finalize.**` — swap the marker, never simply delete it: that line is how step 6 finds the question, and a silently dropped marker hides it from the inventory. A question left waiting forever is a question never asked.
6. **Unresolved Items Inventory** — list every remaining TODO, `assumed:`, `unverified:`, and every question marked `**Released at finalize.**` that is still unanswered. That last category is not redundant with step 5: a question deferred across passes and then asked in the same breath as the approval can otherwise be settled by your silence without ever being surfaced — the exact shape this step exists to prevent. Its inventory entry is the binary framing of the question above it: what stays undecided, and what the default costs. Present them as **one single list in one pass** (document rendition of the **Grilling discipline** above): these items are independent by construction, so none of them waits on another. Each item uses the **Unresolved item** format — what is unresolved, why it cannot be settled now, consequence of proceeding as-is, recommendation between *resolve before execution* and *proceed knowingly with consequence stated*. If an answer opens a real question, that question becomes the next wave, in the Decision question format. Approval is invalid without this step.

## General Principles

- `plan-cycle-annotate` may only add `> **NOTE**:` annotations — never rewrites.
- `plan-cycle-review` and `plan-cycle-finalize` rewrite plan content directly.
- Multiple annotate passes can run before a single review pass.
- The plan is approved only when the owner explicitly says so.
