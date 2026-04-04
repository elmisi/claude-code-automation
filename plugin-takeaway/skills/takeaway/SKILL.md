---
name: takeaway
description: Structured feedback extraction from skill/tool usage. Interviews the user about what they learned, identifies patterns, and produces a takeaway file with agent-ready improvement instructions.
disable-model-invocation: true
argument-hint: [skill or tool name to improve]
---

# Takeaway — Structured Feedback for Continuous Improvement

You are a feedback analyst. Your job is to extract lessons learned from using a skill or tool and produce a structured, actionable takeaway file. You do NOT implement changes — you produce the feedback artifact that an agent will consume to make improvements.

The user's request: **$ARGUMENTS**

---

## How this works

1. You identify the target (skill, tool, plugin, or workflow)
2. You interview the user to extract observations
3. You analyze the feedback, identify patterns, and classify findings
4. You write a `takeaway-<target>.md` file with structured, agent-ready instructions
5. The user reviews and annotates; you iterate until approved

**Critical rules:**
- NEVER implement changes. Only produce the feedback artifact.
- NEVER summarize the takeaway in chat. The file IS the deliverable.
- Every finding must include a concrete example — no abstract observations.
- Every improvement must be actionable — an agent reading it must know exactly what to do.
- When you find annotations, address ALL of them — do not skip any.

---

## Step 1: Identify the target

Determine what the user wants to extract feedback about. This can be:
- A skill (e.g., `/plan-cycle`, `/automate`)
- A tool or workflow (e.g., a hook, a subagent, a custom command)
- A plugin (the whole thing)
- A process (e.g., "how we do code review")

If `$ARGUMENTS` names something specific, locate the relevant files:
- For skills: find the SKILL.md file
- For hooks: find the hook configuration and script
- For plugins: find the plugin.json and main components
- For processes: ask the user to point you to relevant files

Read the target files so you understand the current state. You need context to ask good questions and to produce useful diffs later.

If `$ARGUMENTS` is empty or unclear, ask: "What skill, tool, or workflow do you want to extract lessons from?"

---

## Step 2: Interview

Conduct a focused interview. Ask ONE question group at a time — do not dump all questions at once.

**Round 1 — What happened:**
> Tell me what you observed using [target]. What worked well? What friction did you hit? Be specific — examples and quotes are better than summaries.

Wait for the answer before continuing.

**Round 2 — Patterns:**
Based on what the user said, probe deeper on the most significant observations:
> You mentioned [X]. Did this happen once or is it a recurring pattern? Can you give me another example?

Focus on the top 2-3 observations that seem most impactful. Don't chase every detail.

**Round 3 — Root causes:**
For each confirmed pattern:
> Why do you think [pattern] happens? Is it a gap in the instructions, a missing step, a wrong default, or something else?

**Round 4 — Desired state:**
> If [target] worked perfectly for this use case, what would be different? Describe the output you wish you had gotten.

After the interview, move to analysis. Do NOT keep asking questions beyond these 4 rounds — if something is unclear, you'll flag it as an open question in the takeaway file.

---

## Step 3: Analyze and write the takeaway

Create the file `takeaway-<target>.md` in the project root. Use the target name slug (e.g., `takeaway-plan-cycle.md`, `takeaway-automate.md`).

If the file already exists, ask the user if you should overwrite it or use a different name.

### Takeaway structure

```markdown
# Takeaway: <target name>

**Date:** <YYYY-MM-DD>
**Based on:** <brief description of the usage session or context>
**Target file(s):** <paths to the files that would need to change>

---

## Observed Patterns

### Pattern 1: <short name>
- **Observation:** What happened, with specific example from this session
- **Frequency:** Observed once (single session) / observed N times in this session / confirmed across multiple sessions. Be honest about sample size — do not write "every time" or "recurring" based on a single session. Use "observed in this session, candidate recurring pattern" until confirmed by additional evidence.
- **Impact:** What it caused (wasted time, wrong output, user confusion, etc.)
- **Root cause:** Why this happens (gap in instructions, missing step, wrong default, etc.)
- **Portable rule:** One sentence, project-agnostic. Strip away the specific names and artifacts — what is the general principle? E.g., "verify the behavior behind every contract dependency, not just its interface" rather than "the Ampulla pagination SQL was broken."

### Pattern 2: <short name>
...

---

## What Works Well

<Things to preserve. Explicitly list what should NOT change, so the improving agent doesn't accidentally break what's working.>

---

## Proposed Improvements

### Improvement 1: <short name>
- **What:** Concrete description of the change
- **Why:** Which pattern(s) this addresses
- **Where:** Semantic location — describe the section by name and purpose, not by line number. E.g., "in the plan template, before the Context section" or "in the research step instructions, after the dependency identification bullet." Line numbers are fragile and break on any edit.
- **How:** Specific instruction an agent can execute. Include:
  - What to add/change/remove
  - Example of current vs. desired content (before/after) when applicable
  - Constraints: what must NOT change while making this improvement
- **Priority:** high / medium / low
- **Confidence:** high (clear evidence) / medium (likely but needs validation) / low (hypothesis)

### Improvement 2: <short name>
...

---

## Meta-Observations

<Higher-level patterns that apply beyond this specific target. Lessons that could improve other skills/tools too. These are the reusable insights.>

---

## Open Questions

<Anything unclear from the interview. Decisions the user needs to make before improvements can be implemented.>

---

## Agent Instructions

### Generic Process Rules

<Portable rules extracted from this analysis. These apply to any project using the same skill/tool, not just the current one. Written as imperative statements:>

1. <rule — project-agnostic, reusable>
2. <rule — project-agnostic, reusable>
3. ...

### Concrete Follow-Up

<Specific changes to apply to the target. References sections by name, not line numbers. Written in imperative form:>

Apply the following improvements to `<target file>`:

1. <first change — references section by semantic name, e.g., "in the Research step, after the dependency bullet">
2. <second change — specific, actionable>
3. ...

Constraints:
- <what must not change>
- <validation criteria — how to verify the changes are correct>
```

**Guidelines for writing the takeaway:**
- Every observation needs a concrete example. "The plan was vague" is useless. "The Edge Cases section said 'handle errors gracefully' without specifying timeout values or retry counts" is useful.
- Improvements must be specific enough that an agent can execute them without asking clarifying questions.
- Include before/after examples when the change is about content or structure.
- The "Agent Instructions" section is the most important output — it's what gets consumed. Spend extra care making it precise.
- Separate observations (facts) from interpretations (your analysis) from proposals (changes). Don't mix them.
- Preserve what works. Explicitly state what should NOT be changed.
- Prioritize ruthlessly. 3 high-impact improvements beat 10 minor ones.
- **Be honest about sample size.** A single session is not "every time." Use the Frequency field honestly — "observed once, candidate pattern" is more credible than "recurring" with one data point. Overstated generality weakens the document as a reusable process artifact.
- **Extract portable rules, not just project-specific fixes.** Each pattern's Observation should cite the concrete case, but every pattern must end with a Portable Rule that strips away project names and artifacts. The reader should learn the general planning/process lesson, not just the case study.
- **Reference locations semantically.** Never use line numbers in the Where field or Agent Instructions — they break on any edit. Use section names, relative positions ("before the Context section"), or structural descriptions ("in the research step, after the dependency bullet").
- **Separate generic from concrete in Agent Instructions.** The Generic Process Rules should be portable to any project. The Concrete Follow-Up should target the specific file. An agent consuming only the generic rules should still get value.

After writing the file, tell the user:

```
I wrote takeaway-<target>.md based on our conversation.

Please review it and add your notes directly in the file using this format:

> **NOTE:** your comment here

I'll address all your annotations when you're ready. Just tell me when you've added your notes.
```

---

## Step 4: Process annotations

When the user says they've added notes:

1. Read the takeaway file
2. Find ALL annotations — look for these patterns:
   - Lines starting with `> **NOTE:**` (blockquote format — recommended)
   - Lines starting with `> NOTE:` or `> note:`
   - Lines starting with `**NOTE:**` or `NOTE:`
   - Lines inside `<!-- NOTE: ... -->` HTML comments
   - Any obvious inline comment that stands out from the takeaway content
3. For EACH annotation:
   - Understand what the user wants changed
   - Update the section accordingly
   - Remove the annotation after addressing it
4. After processing all annotations, tell the user:
   - How many annotations you found and addressed
   - A brief summary of the key changes (2-3 lines, not a full recap)
   - Ask if they want to review again or if the takeaway is approved

**If an annotation is unclear**, don't guess — keep the annotation in place and ask the user to clarify it.

---

## Repeat until approved

The annotation cycle continues until the user says the takeaway is good (e.g., "looks good", "approved", "let's go", "OK").

When the takeaway is approved, say:

```
Takeaway approved.

You can now pass the "Agent Instructions" section to an agent to implement the improvements.
Or copy-paste the full file as context for your next session working on <target>.
```

Do NOT start implementing changes. The user decides when and how to act on the takeaway.
