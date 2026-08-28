# plan-cycle — decisions

Two parts, deliberately separated by nature.

- **Permanent rules** hold across every future version of the plugin. Read them before changing the thing they govern. They accumulate; they are not rewritten by later sessions.
- **Session records** are dated and specific to one change. They explain *why* a permanent rule exists, and they date quickly.

---

## Permanent rules

### The grilling discipline has two renditions — do not re-litigate the document one

**Rule.** The grilling discipline lives in two renditions of one criterion:

- **Interactive rendition** — a live conversation, no document in front of the reader: **one question at a time**, wait for the answer before asking the next.
- **Document rendition** — a plan reviewed over multiple passes: the first pass carries **every question that has no dependency on another**; when answers open new branches, the next pass carries every newly-unblocked question that has no dependency on another; repeat until no branch is left open.

**Transposition.** New versions of the discipline arrive written for interactive use, because that is where the owner uses them. Transposing one to the document rendition means **grouping the independent questions into one pass**. That is the whole transformation. Everything else in a new interactive version — per-question payload, ordering, scope fence, humanized context — carries over unchanged.

**Do not re-open this.** An agent reading a new interactive version will notice that "one question at a time" contradicts the batching in the plan template, and will propose replacing the batching. That proposal has been raised twice and rejected twice, on the same grounds both times: in a document reviewed over multiple passes, serialising independent questions turns one pass into fifteen exchanges without adding any information, because by definition none of those answers changes another. The contradiction is not a defect — it is the difference between the two renditions.

**Where it is written.** `plugins/plan-cycle/skills/plan-cycle/templates/plan-template.md`, appendix section `## Grilling discipline`, under *Transposition rule*.

---

## Session records

### 2026-08-28 — annotation intent, and the new grilling version

Two requests from the owner: the produced plan never states *what annotations are for*, and a newer version of the grilling discipline (interactive) needed integrating into the document.

**Decisions, in the order they were settled.**

1. **Two renditions, not a replacement.** See the permanent rule above. The mechanism already in the template was correct; the new interactive version supplies additive material, not a different mechanism.
2. **This record exists**, in `docs/plan-cycle/decisions.md`, with a one-line pointer in `CLAUDE.md`. A decision record that is never found fails silently, so discoverability was the only criterion that mattered. Full record here, pointer there — the plan template stays free of maintainer meta-documentation, which would otherwise be copied verbatim into every produced plan.
3. **Question format depends on the kind of request, not on the agent's judgement.** A *decision question* carries five fields (context, why it matters, options, trade-offs, recommendation with reason). An *unresolved item* from the closing inventory carries four shorter ones (what is unresolved, why it cannot be settled now, consequence of proceeding as-is, recommendation). An inventory item is a known gap with a binary choice, not an open question; forcing five fields on ten or fifteen of them produces ceremony, and ceremony is the first thing an agent drops when a document grows. Which kind applies is fixed by the operation that produces the request, so the agent cannot negotiate it.
4. **Scope fence and criticality ordering** adopted without debate: only the request under discussion, most critical questions first.
5. **Humanized context.** The plan stays rigorous — paths, signatures, thresholds, markers are mandatory. But where the document *asks* rather than *describes*, the question must restate in plain words the substance of anything it depends on, and put the reference next to it. A citation is a pointer, not an explanation. The owner's formulation: a sentence like "constraint A2 conflicts with S3 in the solution to Q1" has a cognitive load that makes it useless, because humans do not hold those references in memory.
6. **The boundary is functional, not a list of section names**: wherever the document asks instead of describes. That covers the Interpretation Log, Decisions I Need From You, the unresolved-items inventory, and questions raised during review. A list of names goes stale when the template changes; a functional criterion does not. The Interpretation Log matters most here — it is where a misunderstanding of the request hides best, and it is dense with cross-references by construction.
7. **First wave declared.** The Interpretation Log and Decisions I Need From You sections of a freshly written plan *are* the first wave of the document rendition; review and finalize carry the following waves. Their field lists were aligned to the discipline's, so one question format exists across the whole cycle. Before this, the template's section format and the discipline's format were similar, different, and unranked — the classic way a discipline degrades unnoticed.
8. **Humanized context is not a twelfth writing rule.** The eleven writing rules stay eleven and `plan-cycle-finalize` keeps checking those. Rationale from the owner: by the time finalize runs, the plan is closed for them and they do not read it again, so humanizing it then buys nothing.
9. **No automatic re-check of question quality.** Correction happens through annotation: an unclear question gets a note saying *explain this better*. This is now a declared annotation intent, not a workaround.
10. **The unresolved-items inventory follows the document rendition** — one list, one pass, explicit choice per item, follow-up questions in the next wave. The items are independent by construction. Rejected: presenting recommendations and treating silence as acceptance, which would save time by destroying the only thing that step produces — a knowing yes.
11. **The annotation section gains a purpose statement plus a closed list of intents**, each with a one-line example: factual error, gap, assumption sold as certainty, disagreement with the approach, success criterion that is not user-observable, risk without an exit clause, request for clarification, unclear question, improvement proposal. **No new tags** in the note syntax: `plan-cycle-review` treats all notes uniformly on purpose, and a classification with no downstream consumer adds rigidity for nothing. If review ever needs to behave differently per type, tags get added then, with a real consumer.
12. **Structure tests per invariant, plus one parity check.** Presence assertions target section headings and field names, never prose sentences, so rewording does not break them. The parity check compares the field names declared in the discipline against those used in the two reviewer sections — the divergence decision 7 removed will otherwise return, because the two texts sit far apart in the same file and nobody reads them together.
