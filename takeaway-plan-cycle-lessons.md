# Takeaway Lessons: /plan-cycle

**Date:** 2026-04-16
**Evidence:** `takeaway-plan-cycle-evidence.md`
**Target scope:** universal

This file contains portable lessons distilled from a usage session of a file-based planning skill. No project-specific names, paths, tools, or metrics appear here by design. For the concrete incidents these lessons were derived from, see the evidence file.

---

## Founding Principle

**A plan speaks with epistemic honesty about each of its claims.** Every empirical statement the plan uses as a premise for a decision must reveal how it was established: either by being verified against the current system (with the verification itself visible) or by being marked as an assumption. A plan that omits the epistemic status of its claims cannot be reviewed — a reader cannot tell whether a premise was checked or guessed, and correctable errors slip past review camouflaged as facts.

The constraint the user placed on any improvement: this honesty must emerge **inside** the plan's existing structure, not by adding new mandatory sections or heavy per-claim tagging. The plan is valued for being light, justified, and easy to annotate. The fix is discipline at the point of writing, not a new template.

---

## Lessons

### Lesson 1 — Verify the verifiable before using it as a premise

An empirical claim is *verifiable* when it reduces to a query the plan's author can run now against the artefacts that exist today: the code, the version history, the test suite, the configuration, the documentation. If a decision in the plan rests on a verifiable claim, the author must run the query before stating the claim and must leave the verification visible (the query itself, the date it was run, the scope it covered). A verifiable claim that drives a decision without being verified is a conjecture presented as a premise — and the decision inherits the conjecture's uncertainty.

When the plan already shows the discipline for some claim types (for example, attaching a verification date to counts), the same discipline must extend to every other claim type that drives decisions. Selective rigour creates an illusion of thoroughness: the reader assumes the planner checked the hard things because the planner visibly checked the easy ones.

**General principle:** If the author can run the check today, the author must run it before using the result as a premise.
**Covers themes:** Pattern 1 (quantifier claims), Pattern 2 (claim status), Pattern 3 (asymmetric rigour).

---

### Lesson 2 — Mark the unverifiable explicitly

Some claims are not verifiable from the artefacts that exist today. They depend on future behaviour, on runtime observations that have not been captured, on stakeholder intent, on systems outside the planner's reach. These claims are legitimate inputs to a plan when they are needed, but they carry a different epistemic weight than verified claims and the plan must make that weight visible.

A marked assumption is a lever for future reviewers and executors: they know to probe it, to build fallbacks around it, to treat it as a risk. An unmarked assumption looks identical to a verified fact and denies the reader that lever. The mark does not need to be heavy — a short inline note is enough — but it must be present wherever an unverifiable claim drives a decision.

**General principle:** When a claim cannot be verified, say so at the place where it is used.
**Covers themes:** Pattern 2 (claim status).

---

### Lesson 3 — Universal quantifiers require an enumerated domain

Claims of the form "no X does Y" or "every X does Z" are not verified by the fact of being written. A universal quantifier ranges over a domain; verifying the quantifier requires enumerating that domain and checking each element (or running a query that provably covers it). If the domain is small and enumerable, the enumeration must be performed and its result recorded alongside the claim. If the domain is too large or unknown, the claim is an assumption and falls under Lesson 2.

This pattern is especially dangerous because a universal quantifier can pass a shallow "be specific" test — it has a concrete predicate, it reads as a fact — while silently carrying an un-checked domain. The quantifier that most often causes trouble is the one that grounds a scope decision ("we can tighten this because nothing else uses it"), because the consequence of the un-checked domain is the introduction of a regression at the places the domain actually reached.

**General principle:** A universal claim is only as strong as the enumeration of the domain it covers; without the enumeration it is a conjecture in factual dress.
**Covers themes:** Pattern 1 (quantifier claims), Pattern 3 (asymmetric rigour).

---

## Meta-Observations

- **Rigour must be uniform across claim types, not concentrated on the ones that are easy to check.** A plan that verifies counts meticulously and states behavioural universals flatly communicates more thoroughness than it has applied. The unverified claims inherit the credibility of the verified ones, and the reader has no way to separate them. Uniform discipline is cheaper than a caught regression.

- **The cost of verification is paid once; the cost of a regression is paid several times.** Verifying a load-bearing premise before writing it as a premise takes minutes. A regression caused by an unverified premise costs a diagnostic cycle, a fix commit, a second review, and — depending on when it is caught — a real user impact. The planner's time is best spent at the point where the decision is being made, not at the point where the decision is being reversed.

- **Lightness and honesty are not opposites.** The constraint "the plan stays light and easy to annotate" does not conflict with the constraint "every claim reveals its epistemic status". A claim stated as verified needs a short trace; a claim stated as assumed needs a short marker; neither is structurally expensive. The weight comes from adding sections or templates, not from adding a few words per claim where a decision rests on the claim.

---

## Discarded as Too Specific

The following items appeared in the evidence but were rejected as lessons because they would not transfer:

- Specific filenames, ticket identifiers, commit hashes, function names, and endpoint paths from the session — contaminated, replaced by the category each represents.
- Session-specific counts (number of consumers found, number of imports, number of commits landed) — snapshots of one instance; the principle ("count or assume, don't leave a quantifier un-enumerated") survives without them.
- The name of the external review mechanism that caught one plan's errors pre-execution — that mechanism is project-specific; the observation that an external review can catch what the plan did not is captured in Open Questions below rather than as a lesson, because not every project has such a review.
- The specific concrete tag format that was considered (`[verified: <date>]`, `[assumed]`) — the principle is that status must be visible; the exact syntax is a local choice, not a portable rule.
- A proposed "declare all divergences from the source brief" section — the planning skill does not always start from a source brief, so this cannot be a universal rule. The underlying principle (extensions require their own justification and their own verification) is folded into Lesson 1 and Lesson 3.
- Tooling-specific verification commands (grep, ripgrep, etc.) — replaced by "run the query over the current artefacts" as a domain-general activity.

This list is a transparency mechanism. If any rejection feels wrong, the item can be promoted back into the lessons and the distillation re-run.

---

## Open Questions (Architectural)

- **Where should enforcement live?** The skill can enforce epistemic hygiene by: (a) changing the guidelines at the point where the plan is written, so the author adopts the discipline themselves; (b) adding a pre-completion self-review pass that the skill performs before returning the plan to the user; (c) relying entirely on an external review cycle (another agent or the user) to catch missing verifications. Each has a different cost/coverage trade-off. The user's constraint "do not make the plan heavier" leans toward (a), but (a) alone does not catch the author's own blind spots. The choice between (a) and (a)+(b) is an architectural decision.

- **When is a claim "driving a decision"?** The discipline should apply to claims that motivate scope, risk, or design choices, not to every passing sentence in the plan. Defining this boundary precisely matters: too broad and the plan becomes a tagging exercise; too narrow and the critical claims still escape. A practical heuristic needs to be chosen.

- **Does the annotation cycle already handle this?** Part of the skill's value is the user annotating the plan and the skill iterating. In principle an attentive reviewer catches unverified premises. In practice, claims stated flatly do not invite scrutiny — the reader assumes the planner did the work. The question is whether this is a defect of the cycle (readers scan-read facts) or a defect of the plan (facts and assumptions look identical). The lessons above assume the second framing; if the first is correct, the lessons need to route through the reviewer instead of the author.

---

## Agent Instructions

Rules the improving agent should apply to the planning skill. Each rule is stated as a portable imperative derived from one of the Lessons. No specific file names, tool names, or session metrics appear in these rules — they must be added by the improving agent in the concrete target file while preserving the principle.

1. Extend the skill's writing-phase guidelines so that any empirical claim used as a premise for a decision is either accompanied by the verification that established it (what was checked, against what surface, when) or explicitly marked as an unverified assumption. The guidelines already require specificity for metrics and thresholds — apply the same discipline to scope and behaviour premises.

2. Add an explicit rule for universal/existential quantifiers: a claim that ranges over a domain ("no X does Y", "every X does Y", "all Xs satisfy Z") must name the domain and show the enumeration, or be rewritten as an assumption. The skill must treat a bare universal quantifier as a red flag the author is expected to resolve before the plan is written, not after.

3. Do not introduce new mandatory sections or per-claim tagging schemas. The new rules live as additional bullets in the existing writing-phase guidelines and as inline phrasing expectations inside the existing sections (Detailed Changes, Edge Cases, Failure Modes, Open Questions). The plan must remain light and structurally the same.

4. Where the skill's current guidelines already enforce discipline selectively (for example by requiring concrete numbers and verification dates for some claim types but not others), the improvement must broaden the existing rule to cover every empirical claim that drives a decision, not add a new rule parallel to it. Broaden, do not duplicate.

5. Treat Open Questions as the destination for unverifiable claims that directly motivate a decision, not only for things the author does not know at all. A claim the author is assuming (rather than checking) and on which a decision rests belongs there if it cannot be validated in place.

Constraints the improving agent must respect:

- The plan must still be usable on the first version, without requiring multiple iterations before it becomes coherent. Verification discipline cannot be implemented as "produce a draft, then verify" — it must happen at the moment of writing.
- The plan must still justify every decision, compare alternatives, surface edge cases, and end with an actionable task breakdown. These properties are load-bearing and cannot be traded away.
- The annotation cycle must continue to work — the improvements must not push the planner into a format that is harder to mark up inline.
- The rules must apply whether or not the plan has a pre-existing source brief (a roadmap, a ticket, a previous document). They cannot assume an external document to diff against.
- Verify the improvement without re-running the original session: the improved skill, run against a hypothetical scope decision that rests on a universal claim, must produce a plan where the claim is either verified inline or marked as an assumption. This is the acceptance criterion.
