# Takeaway Evidence: /plan-cycle

**Date:** 2026-04-16
**Based on:** Phase 3 API Layer Refactor execution session that surfaced ISS-007 (a plan-introduced regression) plus retrospective comparison of `plan-phase-2.md` vs `phase-2-file-organization.md` done during this takeaway.
**Target file(s):** `/home/alessandro/.claude/plugins/cache/elmisi/plan-cycle/1.0.2/skills/plan-cycle/SKILL.md` (and marketplace source under `plugins/marketplaces/elmisi/plugin-plan/skills/plan-cycle/SKILL.md`).
**Target scope:** universal — the plugin `elmisi/plugin-plan` is installed globally and can run in any project, with or without a pre-existing source brief.

---

## Observed Patterns

### Pattern 1 — Universal-quantifier claims accepted without enumeration

- **Candidate principle:** A claim of the form "no X does Y" or "every X does Y", when used as a premise for a scope decision, must carry the enumeration of X's domain and the individual checks. A universal quantifier without an enumeration is a conjecture, not a premise.

- **Observation:** In `plan-phase-3.md` Task 3.6 the scope decision to reject top-level JSON arrays in `parseJSONRequest` was justified by the sentence *"nessun consumer attuale li usa: tutte le response Shopware sono oggetti, gli `EntitySearchResult` espongono `.elements`"*. The quantifier "no consumer" was never checked against all consumers — it was checked against the Shopware core endpoints only. The custom Abas endpoint `/allsafe/order/lines` legitimately returns a top-level empty array `[]` as its empty-result happy path. During execution the new guard wrapped that array into `ResponseNotOkError` → `handleShopwareError` → `ActionError("Get abas orders failed")`, breaking `orderHistory.spec.ts` and any real user with an empty filter.

  The same failure mode is visible in `plan-phase-2.md`. Two factual claims were wrong and were caught later as `[PLANNER-CORRECTION]` in `phase-2-file-organization.md`: (a) the i18n-dir path math (`"../../../i18n"` — three dots — vs the correct `"../../i18n"`); (b) "1 solo consumatore di produzione" for `assertTruthy`, which missed `GetExistingCustomerForm.svelte:5`. In both cases the plan author did not grep the full domain before stating the count.

- **Frequency:** Observed in 2 of 2 plans inspected in this project. In Phase 2 the error was caught by an external planner review before execution; in Phase 3 it escaped to execution. Candidate recurring pattern.

- **Impact (Phase 3 concrete):** A regression that deterministically broke `e2e/orderHistory.spec.ts` and the production empty-result UI. 6 commits landed before the regression was discovered; a 7th fix commit (`fix(api): accept top-level JSON arrays in parseJSONRequest (closes ISS-007)`) was required to realign the implementation to the conservative behaviour specified in the roadmap doc. Plan-level issue raised as ISS-007 in `docs/refactor-codebase/issues.md`. Extra diagnostic cycle during the Task 3.5 e2e gate.

- **Root cause:** The `/plan-cycle` SKILL.md applies its "be specific / concrete numbers / explicit degradation" rules to **metrics** and **failure thresholds**. It does **not** apply the same specificity requirement to **universal premises** about the codebase. A claim that contains a concrete predicate ("no consumer uses top-level arrays") passes the "be specific" check while silently carrying an un-enumerated domain.

---

### Pattern 2 — Empirical claims carry no epistemic status

- **Candidate principle:** Every empirical claim in the plan must be either attached to the verification that established it (command run, file grepped, date) or marked explicitly as an unverified/unverifiable assumption. A claim with no trace is indistinguishable from a hunch.

- **Observation:** `plan-phase-3.md` Task 3.6 presents the array-rejection rationale as factual prose, in the same visual register as any other statement of fact. A reader of the plan cannot tell whether "nessun consumer usa array" is a grep result or an inference. `plan-phase-2.md` has the same shape for the path-math and the `assertTruthy`-consumer claims — both are stated flatly as facts.

  By contrast, both plans **do** treat numeric blast-radius counts as verifiable empirical facts and cite the verification date inline: *"re-verified 2026-04-15"*. The skill is capable of empirical grounding — it just applies that grounding selectively to numerical counts and not to scope/behaviour premises.

- **Frequency:** Structural. Observed in every scope-or-behaviour claim of both plans inspected.

- **Impact:** A reviewer (the user annotating the plan, or the complex-planning drain, or a later reader) cannot distinguish "the planner checked this" from "the planner reasoned about this". Correctable errors slip past review because the reader assumes a planner who states a fact has checked the fact. In Phase 2 the mistakes were caught by an external review step that re-checked from scratch; in Phase 3 that luck ran out.

- **Root cause:** The plan template in `SKILL.md` has sections for *Context*, *Detailed Changes*, *Edge Cases and Risks*, *Failure Modes and Degradation*, *Open Questions*, *Task Breakdown*. None of those sections instructs the plan author to attach a verification trace to each empirical claim, nor to mark claims that were not verified.

---

### Pattern 3 — Asymmetric verification effort across claim types

- **Candidate principle:** The same verification standard must apply to all empirical claims that motivate decisions — not just to the ones that are easy to count. Numerical claims that can be grepped ("113 imports") and existential/universal claims about behaviour ("no consumer uses X") are equally empirical and equally consequential when they drive scope.

- **Observation:** Both `plan-phase-2.md` and `plan-phase-3.md` show the plan author applying maximum rigour to numerical counts (with dated verification) and minimal rigour to existential/universal claims (stated flatly). This is not because the existential claims were actually checked and the trace was omitted — in Phase 3 the e2e run proved the claim was never checked against the full consumer set.

- **Frequency:** Observed in 2 of 2 plans. Candidate recurring pattern.

- **Impact:** The plan conveys an illusion of thoroughness. The thoroughness is real on the parts that are easy to verify (counts) and absent on the parts that are harder to verify (coverage of a domain). The user's mental model — "/plan-cycle does deep work because it focuses on one phase" — is confirmed by the easy parts and silently contradicted by the hard parts.

- **Root cause:** Same as Pattern 2's root cause (no claim-level epistemic status required) compounded by Pattern 1's root cause (no domain-enumeration requirement for universal quantifiers). The asymmetry is the emergent behaviour.

---

## What Works Well

Strengths the user explicitly named and wants preserved. These are the behaviours the improving agent must not trade away.

- Even the **first version** of the plan is usable — it does not require multiple rewrites to become coherent.
- Every decision is **justified**, not just stated.
- **Alternatives considered** are described with the reason they were rejected.
- **Edge cases** are surfaced in their own section, not hidden inside prose.
- **Open Questions** forces genuine uncertainty to be declared rather than papered over.
- The **structure** makes inline annotation easy, which is what keeps the annotation cycle effective.
- **Numerical claims** (blast radius, consumer counts, file counts) are already accompanied by a verification date.
- The plan output reads as a **ragioned, operative** document — it can be handed to an executor and followed.

The verification-hygiene rules introduced by this takeaway must be **additive**, not substitutive. The user's explicit constraint: the plan should not become heavier.

---

## Open Observations

- **External review layer.** Phase 2 benefited from an external planner-review step (the `[PLANNER-CORRECTION]` tags in `phase-2-file-organization.md`) that caught the two plan-introduced errors before execution. Phase 3 did not receive that same catch on the array-rejection scope extension. Whether `/plan-cycle` should internalise a self-review before completion, or whether the external review cycle remains the user's responsibility, is a question for the user. It is logged here because the difference between "error caught pre-execution" and "error caught at e2e" correlates with the presence or absence of that external step.

- **"Verifiable" vs "unverifiable" boundary.** The distinction is fuzzy. A practical criterion that emerged from the session: an assertion is verifiable if it reduces to a query over the current artefacts (code, git history, test suite, configuration, documentation). If it requires future data, runtime observations not currently captured, or user/stakeholder intent, it is unverifiable. This boundary should sit inside Lesson 1 of the lessons file.

- **Sometimes the plan runs cold.** The user confirmed `/plan-cycle` does not always start from a pre-existing roadmap or source brief. A hard "diff against the source document" rule is therefore inapplicable as a universal requirement. The verification-hygiene rules must be stated in a form that works with or without a source brief — they must be internal to the plan, not relational to an external document.

- **User's ceiling on structural additions.** The user explicitly rejected the proposal of a dedicated "Divergenze dal documento sorgente" section and declined the "tag verified/assumed on every claim" proposal as too invasive. The acceptable interface is: the plan stays structurally the same; the rigour is applied **inside** the existing sections, not via new ones.

- **Where to put the enforcement.** The SKILL.md currently has "Guidelines for writing the plan" as a bulleted list at the end of Step 2. The new rules most naturally belong there, as additional bullets framed in the same voice as the existing ones ("Be specific", "Concrete numbers over qualitative descriptions", "Exit clauses over absolute constraints", "Explicit degradation over implicit assumptions"). This is an implementation note for the improving agent, not a lesson.
