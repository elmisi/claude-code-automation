# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.15.0] - 2026-08-31

Schema sync with the Claude Code documentation, from the weekly docs check (issue #27).

### Added
- **`DirectoryAdded` hook event.** Fires after a working directory is added mid-session with `/add-dir` or the SDK `register_repo_root` control request — not for `--add-dir` at startup (`SessionStart` covers those) and not for the `/permissions` Workspace tab. Matcher is `slash_command` or `register_repo_root`. It has no decision control: the add has already completed and Claude Code doesn't wait for the hook, which runs in the background on the 600-second default. Input carries `directory` and `source`. Useful for preparing a newly added repository, e.g. installing its dependencies.
- **`PreModelSwitch` and `PostModelSwitch` hook events** (v2.1.251+), not named in the issue but present in the same docs table, so leaving them out would have re-opened it on the next run. Both match on the **canonical** name of the target model, ignoring any `[1m]` suffix, so `claude-opus-5` covers every alias, dated ID, and provider-specific ID that resolves to it — and when no canonical name can be derived, every hook runs regardless of matcher, which is why a blocking hook should check `to_model` from the input rather than trust the matcher. `PreModelSwitch` can cancel a switch (exit 2, `decision: "block"`, or `permissionDecision` `allow`/`deny`/`ask`) and **blocks on timeout**, unlike `PreToolUse`; `PostModelSwitch` cannot block and delivers its stdout to Claude with the next request.
- **`mcp_tool` hook handler type** — a fifth handler that calls a tool on an already-connected MCP server and reads its text output like command stdout. Required fields `server` (scoped `plugin:<plugin>:<server>` for plugin-bundled servers) and `tool`, optional `input` whose string values support `${path}` substitution from the hook input. The weekly check could not have found this one: its handler-type probe only tested a fixed candidate list, so `mcp_tool` is now in that list.
- **`SendFeedback` subagent tool** (v2.1.238+) — drafts a feedback report about Claude Code and queues it locally; nothing is sent until the user chooses to send it.
- **Structure tests `STRUCT-141`..`STRUCT-150`**: the three new events accepted, `mcp_tool` accepted with `server`+`tool` and rejected without either, the schema carrying the type, `SendFeedback` accepted and present, and the workflow's ignore list pinned by its literal assignment. `STRUCT-64` now asserts 33 events.

### Changed
- **`eventHandlerSupport` corrected.** The schema claimed every event accepted all four handler types except `Setup`. The docs now state three tiers, and the previous claim was wrong for 16 events: all five types on the 13 tool/prompt/stop events; `command`, `http`, `mcp_tool` on the 18 lifecycle events; `command` and `mcp_tool` only on `SessionStart` and `Setup`. The former `commandOnly` key is replaced by `commandHttpMcpToolOnly` and `commandMcpToolOnly` (nothing in the repo read the old key).
- **`PreCompact` moved from `nonBlocking` to `blocking`** in `exitCode2BehaviorPerEvent` — exit 2 blocks compaction, and the schema said otherwise.
- **Timeout defaults restated**: 600s for `command`/`http`/`mcp_tool`, 30s for `prompt`, 60s for `agent`, lowered to 30s on `UserPromptSubmit`/`PreModelSwitch`/`PostModelSwitch` and 10s on `MessageDisplay`; `SessionEnd` hooks share a 1.5s budget.
- **`check-docs-updates.yml` no longer reports `EndConversation`.** The tool is deliberately excluded from the subagent schema (settled in 2.14.0 for issue #23), so the check reported the same false positive on every run and the issue could never close cleanly. A named `IGNORED_DOCS_TOOLS` list, commented with a pointer to the record that justifies each entry, is subtracted from the diff.

### Not changed
- **`EndConversation` stays out of `plugins/automate/schemas/subagents.json`**, as issue #27 requested it be added. Subagents never receive the tool; it bypasses permissions and `PreToolUse` hooks, and no `tools` list or `--disallowedTools` removes it while another tool remains. Listing it would validate a configuration that cannot work. `STRUCT-139` still asserts it is rejected.
- `TeamCreate`/`TeamDelete` remain in the schema though the tools-reference table does not list them — unchanged from the 2.14.0 note, and still needing its own verification against the agent-teams docs.

### Notes
- MINOR bump (additive): three new events, one new handler type, one new tool value; every previously valid configuration stays valid. `STRUCT-145`/`STRUCT-146` are the only tightening, and they reject `mcp_tool` shapes that were never valid.

## [plan-cycle 4.2.0] - 2026-08-28

### Added
- **`plan-cycle-annotate` now states what annotations are for.** The operation was purely procedural — note syntax, tags, the no-rewrite guardrail — and never said that annotations exist to find what is wrong with a plan and to make it better before anyone executes it. It gains a purpose statement plus a closed checklist of annotation intents, each with a one-line example: factual error, gap, assumption sold as certainty, disagreement with the approach, success criterion that is not user-observable, risk without an exit clause, request for clarification, unclear question, improvement proposal. A reviewer facing a plausible-looking plan now has a list of things to hunt for instead of only a note format. The list classifies **intent, not syntax**: no new tags, and `plan-cycle-review` keeps processing every note uniformly.
- **The Grilling discipline now declares its two renditions.** *Interactive* (a live conversation, no document in front of the reader): one question at a time. *Document* (a plan reviewed over multiple passes, the default in a plan file): the first pass carries every question that has no dependency on another, and each new branch opened by an answer forms the next pass. Also added: ordering by criticality within a pass, a scope fence against drift into adjacent topics, and an explicit termination condition. The **transposition rule** — new versions of the discipline arrive written for interactive use and are transposed by grouping the independent questions, settled and not to be re-litigated — lives in `CLAUDE.md` and the decision record, deliberately **not** in the template: `SKILL.md` copies the template's appendix verbatim into every produced plan, in any repository, where a maintainer-facing clause is noise and a `docs/plan-cycle/` reference is a dead path.
- **The first wave enforces the dependency rule across both of its sections.** The Interpretation Log and Decisions I Need From You share one pass, so a decision whose answer or relevance depends on how an interpretation is confirmed must not be asked in that pass: it is listed with a plain-language `Context` plus `Waiting on:` naming the entry it depends on. **`plan-cycle-review` gains a fifth step** that scans for those entries and asks, as full Decision questions, every one whose blocking interpretation the user has since confirmed — without it the deferral had no actor, the question was never posed, and it merely resurfaced in the closing inventory, turning deferral into postponement. The deferred entry keeps a plain-language `Context` because the Humanized context rule still binds: a bare cross-reference is exactly the cognitive load this release removes.
- **Interpretation Log entries carry a `Status` line**, `Confirm or correct.` until `plan-cycle-review` sets it to `Confirmed.`. That marker is what unblocks a deferred question, and it exists because the trigger otherwise lived only in the agent's session memory: step 3 of review removes the confirming annotation, so within one pass the evidence was destroyed by an earlier step, and across passes the plan carried no record that a reading had ever been settled. A fresh agent opening the plan could not run the step at all — in a plugin whose first writing rule is that a fresh agent must execute the plan without prior context. `plan-cycle-finalize` gains a **release step** before the inventory: an entry never confirmed stands as written, by its own Recommendation, so it counts as settled and every remaining deferred question is finally asked rather than waiting forever. The release step **swaps** the `Waiting on:` marker for `Released at finalize.` rather than deleting it, and the inventory collects those released questions as a fourth category alongside TODO / `assumed:` / `unverified:` — otherwise a question deferred across passes and then asked in the same breath as the approval falls outside every category the approval gate names, and can be settled by silence without ever being surfaced. The gate in `SKILL.md` names the fourth category too. Without this, the discipline's only MUST NOT was unenforced in exactly the wave this release introduces — and the dependent pairing ("read *users* as authenticated accounts" plus "should we add a role column?") is the common case, not a corner one.
- **Question format is now fixed by the kind of request, not by the agent's judgement.** A *decision question* carries five mandatory fields (context, why it matters, options, trade-offs, recommendation with reason). An *unresolved item* from the closing inventory of `plan-cycle-finalize` carries four shorter ones (what is unresolved, why it cannot be settled now, consequence of proceeding as-is, recommendation between resolving and proceeding knowingly) — an inventory item is a known gap with a binary choice, not an open question, and imposing five fields on fifteen of them produced ceremony that gets dropped exactly where discipline matters most.
- **Humanized context rule.** The plan stays rigorous — paths, signatures, thresholds and markers remain mandatory — but wherever the document *asks* rather than *describes*, a question must restate in plain words the substance of whatever it depends on and put the reference next to it. A citation is a pointer, not an explanation. The boundary is functional rather than a list of section names, so it does not go stale when the template changes.
- **`docs/plan-cycle/decisions.md`** — decision record with permanent rules on top and dated session records below, plus a pointer in `CLAUDE.md`. The two-rendition rule had already been proposed for removal twice on the same mistaken grounds; it is now written down once.
- **Structure tests `STRUCT-PC-31`..`STRUCT-PC-39`**, asserting section headings and field names rather than prose, so rewording does not break them. Each was verified by mutation — deleting the thing it guards produces exactly one failure, the right one.
  - `STRUCT-PC-31` asserts both halves of the placement rule: the transposition rule is recorded in `docs/` and `CLAUDE.md`, **and** the shipped template references no repo-internal path at all (`docs/`, `plugins/`, `tests/`, `scripts/`, `CLAUDE.md`). The check is a path family rather than a phrase, because a phrase grep only catches the wording it was written against — a differently-worded maintainer clause slipped past the first version. What a grep cannot catch is maintainer prose carrying no path; that residue is covered by the permanent rule in the decision record, not by a test.
  - `STRUCT-PC-32` is scoped to the Decision question sub-block. A whole-block grep passed with `Recommendation` deleted, because that field name also appears in the Unresolved item format — leaving the one field that makes a question non-blocking as the only one uncovered.
  - `STRUCT-PC-37` is a parity check between the field names declared in the discipline and those used in the two reviewer-facing question sections — the divergence this release removed would otherwise return, since the two texts sit far apart in the same file.
  - `STRUCT-PC-38` covers the whole deferral chain — the discipline, the Decisions section template, the `Status` marker that records the trigger in the document, **the review steps that write and read that marker** (pinned separately: a single grep over the review block passed with the writer deleted, because the reader still mentioned the marker), and the finalize release plus inventory.
  - `STRUCT-PC-39` asserts that a deferred entry carries a plain-language `Context` and not a bare cross-reference, scoped to the entry itself so deleting that line fails. Its original fourth conjunct grepped a sentence verbatim, which broke on any editorial rewording — the same assertion style removed from `STRUCT-PC-31` one commit earlier — and was dropped; the shape is already pinned by the field names.

### Changed
- **`Interpretation Log` and `Decisions I Need From You` are now declared the first wave** of the document rendition, and their entry formats were aligned to the discipline's five fields. Previously the template's section format (situation, options, trade-offs, default) and the discipline's format were similar, different, and unranked, so an agent reading both had no rule for which one wins.
- **The unresolved-items inventory is presented as one list in one pass** instead of item-by-item prompting: the items are independent by construction, so serialising them added exchanges without adding information. Follow-up questions opened by an answer become the next wave.
- **`STRUCT-PC-29`** now asserts that both renditions are present, replacing its check for the word "orthogonal", which the rewrite retired.
- **`plan-cycle/SKILL.md`** gained the first-wave pointer and shed two duplicated passages (the "you only plan" restatement and the second listing of the three operation names) to stay within its 5000-byte budget.

### Not changed
- The eleven writing rules stay eleven, and `plan-cycle-finalize` keeps checking those. Humanized context is deliberately **not** a twelfth rule: by the time finalize runs, the plan is closed for its owner. Question quality has no automatic re-check either — an unclear question is corrected with an annotation, which is why *unclear question* is now a declared intent.

## [review-cycle 0.2.0-beta.1] - 2026-08-28

Everything here comes from fifteen review passes on real pull requests across two
repositories, recorded in `docs/review-cycle/context/field-notes.md`. Each item is
a defect the field produced, not a feature the design wanted.

### Added
- **Capability signals — the catalogue can now see a change that grants a power.** A path glob can only say which files changed, and the change that most often deserves the strict lane says nothing about paths: it is the one that lets the software do something it could not do before. `signals.json` gains a `layer_base.capability` family matched against the **added** lines of the diff, in three forms — runs text as code, declares a wider privilege, removes a guard. In fifteen field passes the floor never once recognised that class on its own and the lane was raised by hand every time; on the change that produced the rule it now lands in `strict` unaided. Removals never fire, and documentation is excluded: describing `sudo` is not acquiring it.
- **Perturbation is a declared step, and `review.md` must account for it.** Reading tells you what an artefact claims; perturbing tells you what it does. Three forms depending on what the artefact is: **execute** it, **mutate** it (break what a check claims to protect and confirm it notices), or **contrast** it (run the scenario with and without the mechanism and compare exactly what the check looks at — a fix can move a test from impossible to tautological without anyone seeing it). A mandatory `## Perturbation` section records what was driven, what was broken, and what was not, because a measurement and a plausible inference are indistinguishable in the finding itself. `rc-validate.sh` rejects a review that omits it or leaves it empty.
- **Corollary: establish the identity of what you are perturbing.** When a change alters an observable default, that default says whether the artefact in front of you is the changed one. A measurement attributed to the wrong version is worse than no measurement.

### Changed
- **`recognition_coverage_min` calibrated to `0.70`**, from `null`. Fifteen passes over two repositories put the observed range at 0.90–1.00, so 0.70 fires only on a stack the catalogue genuinely does not describe. `uncumulated_volume_lines` and `open_judgements_max` stay `null` on purpose: the sample covers one project shape, and a threshold tuned on it would stop announcing itself as uncalibrated while being exactly that.
- **Repo metadata is a role, not an unknown.** `.gitignore`, `.gitattributes`, `.editorconfig` and `.dockerignore` join the `config` role — `.gitignore` was the only path the catalogue never recognised in fifteen passes.

### Tests
- `STRUCT-RC-27` (the capability family exists and is declared as matching added lines), `STRUCT-RC-28` (perturbation is declared in the methodology *and* enforced by the validator — declared alone it is advice, and advice is the first thing a long pass drops), `TEST-RC-09` (a review with no `## Perturbation` is rejected), `TEST-RC-10` (a commit that starts running text as code lands in `strict`). `TEST-RC-06` now pins both halves of the INERT contract: an uncalibrated threshold must declare itself, a calibrated one must stop, or the warning becomes background noise. Every one of them was verified by mutation.

## [review-cycle 0.1.0-beta.1] - 2026-08-27

### Added
- **`review-cycle`** — new dual-packaged beta plugin that verifies a *change* rather than auditing a diff. Six composable skills (`/review-cycle` plus `-intent`, `-drift`, `-architecture`, `-risk`, `-hygiene`), each invocable on its own, backed by an eight-script bash + `jq` layer under `plugins/review-cycle/scripts/`.
- **The order is the protocol.** The orchestrator reconstructs what the change does from the diff alone and closes `change-brief.md` *before* any declared intent enters the conversation; `review-cycle-intent` then deduces a candidate intent from commits and the PR description — the author's declarations, not the code — and the user validates or corrects it. Only that attested contract feeds the lenses, which is what makes intent *drift* detectable instead of assumed away.
- **Deterministic risk floor.** `rc-floor.sh` computes the minimum lane (`skip`/`fast`/`normal`/`strict`) by matching a two-layer signal catalogue against the tree and the diff. The model may raise the lane, in writing; it can never lower it, so "do not review this" is reachable only by rule. The script also emits the ordered `invoke` list of skills, which keeps every prompt free of lane conditionals — enforced by `STRUCT-RC-21`.
- **Two kinds of outcome.** A *finding* is a defect and carries a severity; an *open question* is a decision and is admissible only if it names a concrete alternative and that alternative's cost. Both must state what happens if ignored. `rc-validate.sh` enforces the shape with a non-zero exit and a line number, so the rule filters rather than merely advising.
- **Hygiene lane.** Findings labelled `auto-fixable` never become comment threads: they are applied as themed local commits, gated on a green suite before and after, and **never pushed**. The authoritative test command comes from the CI workflow — extracted once by the model, since reading arbitrary YAML is semantic work — while `rc-suites.sh enumerate` still lists suites CI does not cover so `hygiene.md` can declare the blind spots.
- **Test files are outside the lane's perimeter without exception**, which makes the check a set intersection (`rc-guard.sh`) rather than an interpretation: no parser, no language, no runner, and it holds on stacks the catalogue cannot place. A typo in a test comment is now a human judgement, not an automatic fix.
- 27 structure assertions (`STRUCT-RC-01..26`) and 8 fixture tests (`TEST-RC-01..08`), plus a CI step over the review-cycle fixtures.

### Notes
- **Two safety mechanisms ship inert.** The unrecognised-stack block and the accumulated-debt promotion both read thresholds in `data/thresholds.json` that are `null` until calibrated on real passes. Every script reading a `null` threshold prints an `INERT:` line, so an uncalibrated mechanism cannot be mistaken for a working one. Calibration is stage 3 of the roadmap in `docs/review-cycle/docs/product-spec.md`.
- **Measured against opencode 1.18.23**, extending the `qa-architect 0.1.0-beta.2` finding. Nested symlinks *inside* a skill directory — both directory and file links — resolve correctly through an `.agents/skills/` directory link, so shared `scripts/` and `methodology-core.md` need no duplication. The control case matters more: a `../../` path from a symlinked skill does **not** resolve to the real plugin directory — it leaves the project root and is refused by the `external_directory` permission. `STRUCT-RC-26` therefore forbids parent-relative paths in these prompts, and `STRUCT-RC-24`/`STRUCT-RC-25` verify reachability *through* `.agents/skills/` rather than on the real path, which is the check `STRUCT-QA-04` was missing. `refactor-discovery` and `automate` use `${CLAUDE_SKILL_DIR}/../../` but are not exposed that way and are unaffected.
- No root `VERSION` bump: the `automate` package that `VERSION` tracks is unaffected.
- Design record in `docs/review-cycle/` — the source conversation normalized, 20 conversation decisions kept separate from 36 session decisions, 4 declared debts, and the open questions that remain.

## [qa-architect 0.1.0-beta.2] - 2026-08-13

### Fixed
- **The `.agents/skills/qa-architect` link now exposes the whole skill directory** instead of the bare `SKILL.md`. Verified against `opencode` 1.18.18: a skill's relative references are resolved against the link path *without following the link*, so with a link to the file alone the skill's own base directory contained only `SKILL.md` and every relative reference in it — six `references/` templates and one `assets/` pilot — resolved to a non-existent path. An agent asked to read `references/mutation-catalog.md` failed the read and only recovered by falling back to a repo-wide glob, a workaround that disappears entirely once the skill is installed outside the target project. Replacing the file link with a directory link makes `references/`, `assets/` and `agents/` reachable through the skill path, and the read succeeds on the first attempt. Skill discovery is unchanged. The same link is the one Codex consumes, so the fix applies to both runtimes.
- **Structure tests `STRUCT-QA-15`/`STRUCT-QA-16`** assert that `references/` and `assets/` are reachable *through* `.agents/skills/qa-architect/`. The pre-existing `STRUCT-QA-04` only checked that the `SKILL.md` path resolved, which held in both shapes and so did not catch this.

## [Unreleased]

### Added
- **`qa-architect` 0.1.0-beta.1** — new dual-packaged Claude Code and Codex beta plugin for contract-driven QA. It conducts a one-question-at-a-time discovery interview, proposes an explicit approval-gated QA contract, then guides deterministic-first build and mutation-based audit. It includes portable contract/risk/evaluation templates, a synthetic Markdown-editor pilot, and OpenCode adapter instructions for the same canonical `SKILL.md`.

### Changed
- **`check-docs-updates` workflow now runs weekly** instead of daily — `cron` changed from `0 6 * * *` to `0 6 * * 1` (Mondays 06:00 UTC). The Claude Code docs don't change often enough to warrant a daily fetch; weekly keeps schema drift caught without the noise. Updated the auto-generated issue text ("weekly docs check") and the `CLAUDE.md` workflow table to match. No version bump (CI infra only).

### Removed
- **Committed `.html` renders** (`CLAUDE.html`, `plugins/automate/skills/automate/SKILL.html`, `plugins/automate/docs/claude-code-reference.html`, `tests/TEST.html`) removed. They were one-off `pandoc` renders of their `.md` sources with no generator, no CI check, and no consumer — Claude Code reads the Markdown, and the files were nowhere linked. They had already drifted stale (missing the `Artifact`/`Workflow`/`ReportFindings`/`SendUserFile` tools) and only added maintenance friction. No version bump: the `automate` package that `VERSION` tracks is unaffected. Regenerate on demand with `pandoc -s --metadata title=" " <src>.md -o <src>.html` if ever needed.

## [2.14.0] - 2026-08-13

### Added
- **`ListAgents` subagent tool** — the weekly docs check (issue #23) surfaced a drift between the [Claude Code tools reference](https://code.claude.com/docs/en/tools-reference) and the schema. `ListAgents` (v2.1.224+) lists the agents reachable via `SendMessage` — session subagents, other local sessions, and, while connected to Remote Control, web and remote sessions — excluding agent-team teammates, which Claude reaches through the team roster. It appears only where cross-session messaging is enabled. Added to `plugins/automate/schemas/subagents.json` (`validValues` + note), the `VALID_TOOLS` array in `validate-config.sh`, and the inline tool lists in `SKILL.md`, `docs/claude-code-reference.md`, and `CLAUDE.md`.
- **Structure tests `STRUCT-137`/`STRUCT-138`** (subagent accepts `ListAgents`; schema includes it) and **`STRUCT-139`/`STRUCT-140`** (subagent validation rejects `EndConversation`; schema documents why).

### Changed
- **`EndConversation` documented as deliberately excluded.** Issue #23 also reported `EndConversation` as missing from the subagent schema. It is a **false positive**: the tools reference states that subagents never receive the tool, and that background tasks sharing the main conversation's tool list can see it but calling it there ends nothing. It additionally never prompts for permission, `PreToolUse` hooks do not run for it, and while any other tool remains it cannot be removed by a `tools` list, `--disallowedTools`, or `deny`/`ask` rules. Adding it to `validValues` would have validated a subagent configuration that cannot work. Instead the exclusion is now recorded in the schema (`notes.endConversationToolExcluded`), in `docs/claude-code-reference.md` (new "Tools excluded from the `tools` field" section), and in `CLAUDE.md`, so a future docs diff does not reintroduce it.

### Notes
- MINOR bump (additive): one new recognized tool value, fully backward compatible. `STRUCT-139` is the only behavioral tightening — a subagent declaring `tools: EndConversation` was already invalid, and is now asserted to stay that way.
- The tools-reference table no longer lists `TeamCreate`/`TeamDelete`, which remain in the schema. Left untouched here — agent teams are experimental and the removal needs its own verification against the agent-teams docs.

## [2.13.0] - 2026-07-14

### Added
- **`ReportFindings` and `SendUserFile` subagent tools** (issue #19) — the daily docs check found these two tools in the [Claude Code tools reference](https://code.claude.com/docs/en/tools-reference) but missing from the schema. Added both to `plugins/automate/schemas/subagents.json` (valid tool list + descriptive notes), the `VALID_TOOLS` array in `validate-config.sh`, the inline tool lists in `SKILL.md`, `docs/claude-code-reference.md`, and this repo's `CLAUDE.md`. `ReportFindings` reports code-review findings as a typed list for the host UI; `SendUserFile` surfaces a file to the user as a deliverable.
- **Structure tests STRUCT-134/135/136** covering acceptance of the two new tools in subagent validation and their presence in the schema.

## [2.12.0] - 2026-06-27

### Added
- **`Artifact` and `Workflow` subagent tools.** The Claude Code [tools reference](https://code.claude.com/docs/en/tools-reference) added two tools that were missing from the schema. `Workflow` runs a dynamic workflow that orchestrates many subagents in the background and returns one consolidated result; `Artifact` publishes an HTML/Markdown file as a private, interactive page on claude.ai shareable inside your organization (Team or Enterprise plan, `/login` auth). Added both to `plugins/automate/schemas/subagents.json` (`validValues` + descriptive `notes`), `plugins/automate/scripts/validate-config.sh`, the `automate` `SKILL.md` valid-tools list, `plugins/automate/docs/claude-code-reference.md`, and `CLAUDE.md`. Resolves the `schema-update` issue raised by the daily docs check (#16).
- Structure tests `STRUCT-131` (subagent accepts `Artifact, Workflow`), `STRUCT-132` (schema includes `Artifact`), `STRUCT-133` (schema includes `Workflow`).

### Notes
- MINOR bump (additive): two new recognized tool values, fully backward compatible. No existing configuration changes meaning.

## [plan-cycle 4.1.0] - 2026-06-27

### Added
- **Grilling discipline for the interactive operations.** Added a `## Grilling discipline` block to the plan template's Operations Guide appendix (inspired by Matt Pocock's `grill-me` skill). When `plan-cycle-review` hits an unclear annotation, or `plan-cycle-finalize` works its Unresolved Items Inventory, it now resolves decisions in **waves** instead of dumping a flat question list: each wave asks only mutually independent (orthogonal) questions — dependent questions, whose answers would change another answer or whether it still needs asking, are deferred to a later wave once their prerequisites resolve. Every question carries a recommended answer; the agent explores the codebase/plan to answer a question before asking it.
- Structure tests `STRUCT-PC-29` (appendix defines the Grilling discipline + orthogonality rule) and `STRUCT-PC-30` (both `plan-cycle-review` and `plan-cycle-finalize` route through it).

### Notes
- Always-on, no toggle: the discipline only governs question moments that already existed (review's "if unclear" and finalize's per-item inventory), so a plan with nothing to clarify is unaffected. Users who want the prior, non-grilling behavior can pin plan-cycle 4.0.0.
- New plans (≥ 4.1.0) embed the discipline in their appendix; existing v3.x / 4.0.0 plans are unchanged (their appendix/companion is authoritative). MINOR bump (additive) across both manifests and the Claude marketplace entry.

## [takeaway 1.2.0] - 2026-06-25

### Added
- **Codex packaging for `takeaway`.** Added `plugins/takeaway/.codex-plugin/plugin.json` (with the Codex `interface` block) and a `takeaway` entry in the Codex marketplace `.agents/plugins/marketplace.json` (source `./plugins/takeaway`, no version field — version lives in the manifest). `takeaway` is now dual-packaged for Claude Code and Codex, like `plan-cycle` and `refactor-discovery`.
- Structure tests `STRUCT-126..130` mirroring the refactor-discovery dual-package checks (Codex manifest exists + valid JSON, version sync across the three manifests, Codex marketplace source path, Codex entry has no version field).

### Changed
- **Content audit for portability.** Generalized the skill's Step 1 ("Identify the target") so it no longer assumes a Claude-Code-specific plugin layout (`SKILL.md` / `plugin.json` / hook / `/command` syntax); it now reads naturally on both Claude Code and Codex. The rest of the skill was already tool-agnostic.
- Bumped `takeaway` 1.1.1 → 1.2.0 (MINOR — new packaging) across the Claude manifest, the new Codex manifest, and the Claude marketplace entry. Updated `CLAUDE.md` and `README.md` to list `takeaway` as dual-packaged.

## [plan-cycle 4.0.0] - 2026-06-25

### Changed (BREAKING)
- **Operations guide is now embedded in the plan, not a separate file.** The standalone `ops-template.md` companion (previously copied next to each plan as `plan-{slug}-{timestamp}.ops.md`) is gone. Its content now lives as an **Operations Guide** appendix at the bottom of the plan template, so every generated plan is a single self-contained file. Deleted `plugins/plan-cycle/ops-template.md`; folded the dispatch rule + `plan-cycle-annotate` / `plan-cycle-review` / `plan-cycle-finalize` / general-principles sections into `templates/plan-template.md`.
- **`SKILL.md`**: removed the Step 2 "copy ops template alongside" step and the `{ops-filename}` placeholder; Step 4 now points operations at the in-plan appendix.
- **`plan-impact` / `plan-quality`**: annotation-format references now point to the plan's Operations Guide appendix instead of the "ops file".

### Migration
Existing v3.x plans keep working unchanged — they continue to rely on their already-written `.ops.md` companion, which remains self-contained and authoritative for that plan. Only **new** plans generated by v4.0.0 carry the embedded appendix. To migrate a v3.x plan, paste its `.ops.md` content as an appendix at the bottom of the plan and delete the companion.

### Tests
- Retargeted the plan-cycle structure assertions (STRUCT-PC-03/04/09/17/27/28) to read the operation sections from the plan template appendix; STRUCT-117 now checks the template embeds the appendix; STRUCT-PC-11 now asserts `ops-template.md` no longer exists; STRUCT-PC-12 checks the skills reference the "Operations Guide appendix". Updated interactive tests (PC-A/B/C) and the `plan-with-annotations.md` fixture to the embedded-appendix shape.

## [2.11.0] - 2026-06-25

MINOR bump for `automate` 2.10.3 → 2.11.0 (new hook event support). Closes #10.

### Added
- **`MessageDisplay` hook event** added to the schema (30 valid events, was 29). Fires while assistant message text streams to the user — display-only and observational: no matcher support, non-blocking (exit 2 shows stderr only), supports all four handler types, 10s default timeout. Hooks can replace the shown text via `hookSpecificOutput.displayContent` (display only — does not change the transcript or Claude's context). Added a `displayContent` capability entry. Sourced from the official hooks docs at code.claude.com.
- New structure test `STRUCT-125` (accepts `MessageDisplay`); `STRUCT-64` event-count assertion updated 29 → 30.

### Fixed
- `SKILL.md`'s "ONLY use these valid events" list was missing `PostToolBatch`, `UserPromptExpansion`, and `Setup` (already valid in the schema). Added them alongside `MessageDisplay` so the list is exhaustive again.

### Changed
- Updated schema (`plugins/automate/schemas/hooks.json`), `validate-config.sh`, `SKILL.md`, `plugins/automate/docs/claude-code-reference.md`, `CLAUDE.md`, and `README.md` to reflect the new event.

## [2.10.3] - 2026-06-24

PATCH bumps (packaging/location only, no behavior change): automate 2.10.2 → 2.10.3, develop-cycle 1.0.0 → 1.0.1, takeaway 1.1.0 → 1.1.1. `plan-cycle` and `refactor-discovery` unchanged (not moved).

### Changed
- **Unified plugin directory layout under `plugins/`.** Moved `plugin/` → `plugins/automate/`, `plugin-develop-cycle/` → `plugins/develop-cycle/`, and `plugin-takeaway/` → `plugins/takeaway/` (via `git mv`, history preserved). All five plugins now live under a single `plugins/` root. Updated `source` paths in `.claude-plugin/marketplace.json` and all live path references in `tests/scripts/run-tests.sh`, `CLAUDE.md`, `CONTRIBUTING.md`, `AGENTS.md`, `README.md`, and `.github/` workflows/templates.
- **No Codex impact:** the only Codex-packaged plugins (`plan-cycle`, `refactor-discovery`) were already under `plugins/` and were not moved; `.agents/plugins/marketplace.json` and both `.codex-plugin/` manifests are unchanged.
- Regenerated committed `.html` renders (`CLAUDE.html`, `plugins/automate/skills/automate/SKILL.html`, `plugins/automate/docs/claude-code-reference.html`, `tests/TEST.html`) from their `.md` sources via `pandoc -s --metadata title=" "` — refreshing both the moved paths and long-stale content (e.g. `CLAUDE.html` still described an old single-plugin layout).

## [plan-cycle 3.0.0] - 2026-05-24

Distilled from `takeaway-plan-cycle-lessons.md` — restructures the plan around the reviewer's actual attention surface to catch intent-divergence before code is written.

### Changed (BREAKING)
- **Plan template restructured with audience labels.** Every section is now tagged *(Reviewer surface)* or *(Executor surface)*. Reviewers read the former in full; the latter is baseline for the implementer. Plans generated with v2.x do not carry these labels — they continue to work but won't surface intent ambiguities the new shape catches. (Lesson 2)
- **Open Questions split into two named top-level sections:** `Decisions I Need From You` (planner uncertainty) and `Interpretation Log` (interpretive choices on the user's request). Both reviewer-surface, both must always be populated (`None.` if applicable) — a silent omission is indistinguishable from "planner skipped". (Open Questions Q2)
- **`plan-cycle-finalize` now cites 11 rules instead of 10** (added: Outcome-layer success) and includes a new step 5 — `Unresolved Items Inventory` — that auto-lists every TODO / `assumed:` / `unverified:` and forces a per-item *resolve / proceed-knowingly* prompt before approval is valid. (Lesson 4, Lesson 6)

### Added
- **`Interpretation Log` section** in plan template — dedicated, scannable surface for every interpretive choice the planner made on the request: "Read '<phrase>' as <reading>; alternatives were Y/Z; consequence of each; confirm or correct." Eliminates silent disambiguation buried in Detailed Changes snippets. (Lesson 1)
- **`Decisions I Need From You`** explicit self-containment requirement — each entry carries its own situation, alternatives, trade-offs, and default; cross-references to other sections of the plan are forbidden inside a decision prompt. (Lesson 3)
- **Outcome-layer success writing rule** in `SKILL.md` and per-change criterion in template's `Detailed Changes`: "user does X, observes Y" is the criterion; infrastructure proxies ("binary responds", "endpoint 200", "container up") are pre-conditions, never completion evidence. (Lesson 6)
- **Approval gate** in `SKILL.md` Step 4 — `Plan approved` cannot be signaled without `plan-cycle-finalize` having surfaced the unresolved-items inventory with per-item user choice. (Lesson 4)
- **Verify-before-claim rule extended** to cover the high-yield-failure category "tool X persists data at path Y" / "config knob Z controls behaviour W" — verify with `--help`, scratch run, file inspection; never assert from training memory. (Lesson 5)

### Migration
v2.x plans with their existing `.ops.md` companion keep working — the companion file is authoritative for its plan, and v2.x ops continue to drive v2.x finalize behaviour. Only **new** plans generated by v3.0.0 get the new template + 11-rule finalize. To retrofit a v2.x plan onto the new template, either rewrite it manually or regenerate.

### Reduced / Sized
- `skills/plan-cycle/SKILL.md`: 77 lines / 4990 bytes (limits: ≤90 / ≤5000).
- `ops-template.md`: 49 lines / 2593 bytes (limit: ≤50 lines).
- `templates/plan-template.md`: 56 lines (no enforced limit; grew from 47 to host the 2 new reviewer-surface sections + outcome criterion).

## [plan-cycle 2.0.0] - 2026-05-24

### Changed (BREAKING)
- Renamed operations: `Annotate → plan-cycle-annotate`, `Review → plan-cycle-review`, `Finalize → plan-cycle-finalize`. **Nessun alias**: i vecchi nomi non funzionano più sui nuovi `.ops.md`. Se l'utente usa "annotate"/"review"/"finalize" l'agente risponde con messaggio esplicito che elenca i nomi validi.
- Consolidated operation definitions: `ops-template.md` è ora la single source of truth. `SKILL.md` Step 4 ("Operate on the plan") punta al file ops, non duplica le procedure.
- `plan-quality`: cerca `<project-root>/code-quality.md` opt-in; se non esiste usa il default plugin (9 criteri) e mostra un reminder con istruzioni per crearlo. **La skill non scrive mai nella project root** (no copy-on-first-use, no side effect).
- Unified writing rules e Finalize criteria in un set unico da **10 rules** (era 8 writing + 4 finalize disallineati): Self-contained, Operative, Numbers, Exit clauses, Explicit degradation, Verify, Enumerate universals, Mark unverifiable, Coherent, Robust.
- Plan structure template estratto da `SKILL.md` in `skills/plan-cycle/templates/plan-template.md`. Paragrafi rationale verbose **eliminati** (non spostati: nessun caching automatico dei file referenziati, vedi review note).
- SKILL principale riorganizzata in 4 step (Research → Setup files → Write plan → Operate) invece di 3.

### Added
- `plan-quality` threshold a 15 violazioni (parity con `plan-impact`).
- Annotation sub-types (`[impact]`, `[quality: <criterion>]`) documentati canonicamente in `ops-template.md`.
- Invariant "same-directory" per `.md` + `.ops.md` companion nel `templates/plan-template.md`.
- 19 test strutturali (STRUCT-PC-01..19) in `tests/scripts/run-tests.sh` + 3 test interactive (INTERACTIVE-PC-A/B/C) in `tests/scripts/e2e-interactive.sh` (local-only, non in CI).
- Fixture dir `tests/fixtures/plan-cycle/` per regression test.

### Reduced
- `skills/plan-cycle/SKILL.md`: -56% righe (169 → 74), -62% byte (9987 → 3791).
- `ops-template.md`: -21% righe (61 → 48), -28% byte (3218 → 2328).
- `skills/plan-impact/SKILL.md`: -24% righe (49 → 37), -27% byte (2484 → 1805).
- `skills/plan-quality/SKILL.md`: -27% righe (52 → 38), -2% byte (2188 → 2134; saving limitato perché aggiunti opt-in resolution + threshold).

### Migration
I piani esistenti con `.ops.md` v1.6.x continuano a funzionare con i nomi vecchi (`annotate`/`review`/`finalize`) perché il companion ops resta authoritative per quel piano. Per usare i nomi nuovi su un piano esistente:

```bash
sed -i.bak -E 's/^## Annotate/## plan-cycle-annotate/; s/^## Review.*/## plan-cycle-review/; s/^## Finalize/## plan-cycle-finalize/; s/Annotate safety check/plan-cycle-annotate safety check/' <ops-file>
```

In alternativa: cancella il vecchio `.ops.md` e ricopia il nuovo template dal plugin.

## [plan-cycle 1.6.1] - 2026-05-09

### Fixed
- Ops template now dispatches explicitly by requested operation wording, so `annotate` can only add `> **NOTE**:` lines even when unresolved notes already exist.
- Added an Annotate safety check requiring agents to verify the diff does not rewrite plan content during annotation-only passes.

## [plan-cycle 1.6.0] - 2026-05-07

### Added
- Codex marketplace support via `.agents/plugins/marketplace.json`
- Codex plugin manifest at `plugins/plan-cycle/.codex-plugin/plugin.json`

### Changed
- Moved `plan-cycle` from `plugin-plan/` to `plugins/plan-cycle/` so Claude Code and Codex can share one plugin source tree
- Replaced Claude-specific skill path instructions with portable relative path guidance while keeping Claude Code resolution notes

## [refactor-discovery 1.1.0] - 2026-05-07

### Added
- Codex marketplace support via `.agents/plugins/marketplace.json`
- Codex plugin manifest at `plugins/refactor-discovery/.codex-plugin/plugin.json`
- Stable `SL<N>` namespace for structural smell leads before promotion to refactor candidates
- Discovery lenses for temporal coupling, change amplification, shotgun ceremony, semantic drift, asymmetric abstractions, hidden policy, test gravity, and negative space

### Changed
- Moved `refactor-discovery` from `plugin-refactor-discovery/` to `plugins/refactor-discovery/` so Claude Code and Codex can share one plugin source tree
- Reworked the methodology from candidate-first to smell-led discovery, preserving uncertainty as `SL<N>` leads or `RT<N>` research tasks
- Added a serial investigation fallback for runtimes that do not support plugin subagents

## [plan-cycle 1.5.1] - 2026-05-07

### Fixed
- Skill now instructs agent to internalize ops template content as operational knowledge, not just copy it as cargo
- Workflow overview clarifies that ops-defined operations (Annotate, Review, Finalize) can be performed by any participant, including the agent

## [refactor-discovery 1.0.0] - 2026-05-07

### Added
- New plugin `refactor-discovery` (`/refactor-discovery`) — research methodology for surfacing high-value refactor candidates
- Dynamic area discovery: analyzes project structure and identifies 3-8 areas optimized for parallel investigation
- Scoped mode: accepts optional argument (directory, class, module, or concern) to focus investigation; auto-discovers adjacent areas via import/export analysis
- Parallel investigation via `area-investigator` subagent — one per area, running the full Enumerate-Read-Smell-Evidence-Verdict cycle
- Methodology reference (`docs/methodology.md`): 9 prioritized principles, investigation discipline with 10 "why" checks, scoring rules, cross-cutting signals, 16 anti-patterns, synthesis rules, output templates, 9 coherence gates
- Three candidate namespaces: `R<N>` (refactor), `RT<N>` (research task — blocked on live evidence), `DI<N>` (document-intent — one-line comment micro-edit)
- Synthesis step: cross-area merge, ceremony-counting escalation, layering consistency, dependency-edge graph
- Discovery document output with executive summary, candidate list, prioritized roadmap, review heuristics, and annotation cycle
- Registry tracking across passes for ID continuity

## [2.10.2] - 2026-05-24

### Added
- Subagent schema: `PushNotification`, `RemoteTrigger`, `ScheduleWakeup`, `WaitForMcpServers` tools (closes #9). Updated `validate-config.sh`, `SKILL.md`, `claude-code-reference.md`, and root `CLAUDE.md` to match.

## [2.10.1] - 2026-05-06

### Added
- Subagent schema: `ShareOnboardingGuide` tool (closes #8)

## [plan-cycle 1.5.0] - 2026-05-06

### Added
- Ops template: comando `Finalize` — verifica consistenza del piano (autocontenuto, operativo, coerente, robusto) e riscrive direttamente le sezioni carenti

### Changed
- Ops template: rimossi Impact Analysis e Code Quality (restano come skill del plugin, non operazioni per agenti esterni)
- Ops template: rimosso goal aspirazionale da Review — ora Review processa solo annotazioni, senza pretese di finalizzazione

## [plan-cycle 1.4.0] - 2026-05-05

### Added
- Ops template (`ops-template.md`): companion file copiato accanto ad ogni piano, descrive tutte le operazioni disponibili — usabile da qualunque coding agent senza il plugin
- `/plan-cycle:plan-impact` skill: analisi d'impatto codebase sui piani (overlap, obsolescenza, convenzioni, ripple effects)
- `/plan-cycle:plan-quality` skill: verifica criteri "bel codice" configurabili dall'utente
- `code-quality.md`: 9 principi quality prioritizzati come contenuto iniziale

### Changed
- Plan template: sezione "Rules" rimossa, sostituita da riferimento al file ops companion
- Step 3 (process annotations): semplificato a fallback same-session

## [2.10.0] - 2026-05-01

### Added
- `Setup` hook event added to schema (closes #7)
  - Fires only with `--init-only`, or `--init`/`--maintenance` in `-p` mode. For one-time dependency installation or scheduled cleanup.
  - Matcher values: `init`, `maintenance`
  - Only supports `command` handler type (not prompt/agent/http)
  - Cannot block — exit 2 shows stderr but continues execution
  - Has access to `CLAUDE_ENV_FILE` for persisting environment variables
  - Updated `plugin/schemas/hooks.json`, `plugin/scripts/validate-config.sh`, `plugin/skills/automate/SKILL.md`, `plugin/docs/claude-code-reference.md`, `CLAUDE.md`
  - Added `commandOnly` field to `eventHandlerSupport` in hooks schema for events with restricted handler types
  - Test STRUCT-64 updated: 28 → 29 events; added STRUCT-106, STRUCT-107, STRUCT-108
  - Detected by `check-docs-updates` workflow against the live Claude Code hooks reference

## [2.9.1] - 2026-05-01

### Changed
- **plan-cycle plugin (1.3.0):** simplified plan rules to two actions — annotate and review
  - Replaced 8 execution-oriented rules with 2 clear actions: **Annotate** (insert `> **NOTE**: comment` inline) and **Review** (process all annotations, integrate into plan, remove resolved ones)
  - Removed all execution language — plans describe how to annotate and review, not how to execute
  - Self-contained definition clarified: plan must be executable in a fresh session with no other context — everything needed is in the file
  - Standardized NOTE format to single form `> **NOTE**:` everywhere (skill and templates)
- **takeaway plugin:** aligned NOTE format to `> **NOTE**:` for consistency
- **README:** updated plan-cycle section with new rules, typical cycle diagram, and multi-agent usage

## [2.9.0] - 2026-04-29

### Added
- `PostToolBatch` and `UserPromptExpansion` hook events added to schema (closes #6)
  - `PostToolBatch`: fires after a full batch of parallel tool calls resolves, before the next model call. No matcher. Can block or add context.
  - `UserPromptExpansion`: fires when a user-typed slash command expands into a prompt. Matcher is the command name. Can block expansion or add context.
  - Updated `plugin/schemas/hooks.json`, `plugin/scripts/validate-config.sh`, `plugin/skills/automate/SKILL.md`, `plugin/docs/claude-code-reference.md`, `CLAUDE.md`
  - Test STRUCT-64 updated: 26 → 28 events
  - Detected by `check-docs-updates` workflow against the live Claude Code hooks reference

### Changed
- **plan-cycle plugin (1.2.0):** rules, self-containment, and dynamic filenames
  - New `## Rules` section in generated plans — 8 rules for executor/reviewer agents (source of truth, full-read-first, task marking, ambiguity, executor/planner separation, ordering, completeness, failure documentation)
  - Self-containment guideline: every plan section must be operative and executable in a new session with zero prior context
  - Dynamic filenames: `plan-{slug}-{YYYYMMDD-HHMM}.md` with `docs/` directory preference, replacing hardcoded `plan.md`

## [2.8.0] - 2026-04-16

### Changed
- **plan-cycle plugin (1.1.0):** epistemic-hygiene discipline added to the plan-writing guidelines, derived from a takeaway retrospective on two prior planning sessions:
  - Step 1 (Research): plan author keeps a short trace of the checks run during research, so claims the plan relies on reveal where they came from at write time rather than in reconstruction
  - Step 2 (Open Questions): broadened to host unverifiable assumptions that drive scope/risk/design decisions, not only things the author does not know at all
  - Step 2 (Guidelines): three additive bullets — **Verify empirical premises before using them** (broadens the existing "concrete numbers" discipline to every empirical premise that drives a decision, with the verification visible: what, against what surface, when); **Universal and existential claims need an enumerated domain** (quantifier claims require the domain named and the check shown inline, or the claim is rewritten as an assumption); **Mark unverifiable assumptions inline** (short marker at the point of use, e.g. "assumed:" / "unverified:", with lift into Open Questions when the assumption is material)
  - Additive-only: no new mandatory sections, no per-claim tagging schema, plan structure and annotation-cycle format unchanged, no dependency on an external source brief

## [2.7.1] - 2026-04-14

### Added
- `Monitor` tool added to subagent schema (closes #4)
  - Updated `plugin/schemas/subagents.json`, `plugin/scripts/validate-config.sh`, `plugin/skills/automate/SKILL.md`, `plugin/docs/claude-code-reference.md`, `CLAUDE.md`
  - New tests STRUCT-104, STRUCT-105 verify schema acceptance
  - Detected by `check-docs-updates` workflow against the live Claude Code tools reference

## [2.7.0] - 2026-04-08

### Changed
- **takeaway plugin (1.1.0):** Major workflow rewrite to enforce portable lessons:
  - Output split into two files: `takeaway-<target>-evidence.md` (project-specific retrospective) and `takeaway-<target>-lessons.md` (tool-agnostic principles for an improving agent)
  - New Step 3.5 Distillation pass with 5 sub-steps: root theme grouping, unifying principle detection, vocabulary audit, self-check, discarded-as-too-specific list
  - Candidate principle now written FIRST in each pattern (before Observation), preventing the rule from inheriting the evidence's project-specific vocabulary
  - New Step 1 classification: universal vs project-scoped target shapes how the lessons file's Agent Instructions are written
  - Vocabulary audit teaches the named-artifact vs domain-concept distinction via worked examples (e.g., "the User class" forbidden, "a user" allowed) without hard-coded ban lists
  - Annotation handling: contamination flags on the lessons file trigger re-running of the distillation pass on that lesson, not single-line edits
  - Note: output file naming changes from `takeaway-<target>.md` to a two-file split — downstream consumers that match the old pattern must update

## [2.6.1] - 2026-04-04

### Changed
- **takeaway plugin (1.0.1):** Self-improvement from first usage feedback:
  - Patterns now require honest sample-size labeling (no "every time" from single sessions)
  - Each pattern must end with a portable, project-agnostic rule
  - Improvements reference sections semantically, not by line number
  - Agent Instructions split into "Generic Process Rules" (portable) and "Concrete Follow-Up" (file-specific)
  - 4 new guidelines: sample-size honesty, portable rules, semantic references, generic/concrete split
- **Schema sync**: added `PermissionDenied` hook event, `SendMessage`/`TeamCreate`/`TeamDelete` subagent tools (closes #3)
- **CI fix**: aligned `plugin/.claude-plugin/plugin.json` version

## [2.6.0] - 2026-04-04

### Added
- **takeaway plugin** (`plugin-takeaway/`, `/takeaway`) — structured feedback extraction from skill/tool usage. Interviews the user, identifies patterns, and produces agent-ready improvement instructions in a `takeaway-<target>.md` file with annotation cycles
- **plan-cycle: "Failure Modes and Degradation" section** — new mandatory plan section requiring explicit failure behavior, concrete thresholds (timeouts, retry counts, size limits), and specific fallback strategies

### Changed
- **plan-cycle: Edge Cases and Risks** restructured — now requires likelihood, impact, concrete mitigation, and exit clause for each risk
- **plan-cycle: 3 new writing guidelines** — concrete numbers over qualitative descriptions, exit clauses over absolute constraints, explicit degradation over implicit assumptions
- **marketplace.json** — added takeaway plugin entry

## [2.5.0] - 2026-03-31

### Added
- **`if` field** on all hook handlers — permission rule syntax filter (e.g. `Bash(git *)`)
- **`ws` transport type** for MCP servers — WebSocket support alongside stdio, http, sse
- **`auto` permission mode** added to hook input schema

### Changed
- **All hook events now support all 4 handler types** (command, http, prompt, agent) — removed `commandOnly` restriction from 16 events
- **Skill context budget** corrected to 1% of context window (fallback: 8,000 chars), each entry capped at 250 characters
- **CLAUDE.md** updated with multi-plugin repo overview and GitHub Actions table
- **plan plugin renamed to plan-cycle** (`/plan` → `/plan-cycle`) to avoid collision with Claude Code's built-in `/plan` command

## [2.4.0] - 2026-03-27

### Added
- **4 new hook events**: `TaskCreated`, `StopFailure`, `CwdChanged`, `FileChanged` — synced from live Claude Code docs
- **`shell` field** on command hooks — `bash` (default) or `powershell` for Windows support
- **`PowerShell` tool** added to valid subagent tools list (opt-in preview)
- **`effort` field** for skills and subagents — `low`, `medium`, `high`, `max` (Opus 4.6 only)
- **`initialPrompt` field** for subagents — auto-submitted first turn with `--agent`
- **`paths` field** for skills — glob patterns that limit when a skill is activated
- **`shell` field** for skills — shell for `!`command`` blocks (`bash`/`powershell`)
- **`headersHelper` field** for MCP servers — dynamic header generation via shell command
- **`oauth.authServerMetadataUrl`** for MCP servers — override OAuth metadata discovery (v2.1.64+)
- MCP channels feature, plugin-provided MCP servers, `claude mcp serve`, policy controls (`allowedMcpServers`/`deniedMcpServers`)
- `PostToolUse` hooks can now return `updatedMCPToolOutput` to replace MCP tool output
- `PreToolUse` hooks gain `additionalContext` field
- LSP servers: find references, list symbols, find implementations, trace call hierarchies
- Permission patterns: `Agent(name)`, `Skill(name)`, `MCPSearch`
- `TaskCreated` hook for agent teams
- `CLAUDE_PLUGIN_DATA` environment variable for plugin persistent data
- Effort and shell validation in `validate-config.sh`
- 5 new structure tests (102 total, up from 97)

### Changed
- Hook events count: 21 → 25
- Updated matcher values for `SessionEnd` (+`resume`), `InstructionsLoaded` (now has matchers)
- Subagent `noNesting` note corrected: subagents CAN spawn other subagents via `Agent(type)` syntax
- `TaskOutput` tool marked as deprecated (use `Read` on output file path)
- Plugin subagents note: `hooks`, `mcpServers`, `permissionMode` ignored for security
- MCP scope naming: `local` (was `project`), `user` (was `global`)
- `claude-code-reference.md` updated to 2026-03-27
- "ultrathink" keyword documented for skills (enables extended thinking)

## [2.3.0] - 2026-03-15

### Added
- **Management commands as separate skills**: `/automate list` → `/automate-list`, `/automate edit` → `/automate-edit`, etc. Each command loads only its own SKILL.md (5–90 lines) instead of the full 1100-line creation workflow, reducing latency significantly
- 8 new skills: `automate-help`, `automate-list`, `automate-verify`, `automate-export`, `automate-import`, `automate-delete`, `automate-edit`, `automate-cleanup`
- `plugin/docs/shared-context.md` — shared procedures (registry bootstrap, merge algorithm, file markers, deletion procedures) referenced by management skills
- JSON guard hooks on skills that write config files (`automate-edit`, `automate-import`, `automate-delete`, `automate-cleanup`)
- 16 new structure tests (STRUCT-82..97) for management skill files and frontmatter
- Backwards compatibility: `/automate list` (old format) suggests `/automate-list`

### Changed
- Main `/automate` SKILL.md slimmed from ~1100 to ~865 lines (command router + sub-command sections removed)
- `automate-help.sh` and `automate-list.sh` updated with `/automate-*` command names
- README.md command table uses new `/automate-*` format
- CLAUDE.md architecture section documents new skill-per-command structure

## [2.2.2] - 2026-03-15

### Fixed
- `automate-list.sh` now supports both registry formats: array `[{...}]` and object `{automations: [{...}]}`

## [2.2.1] - 2026-03-15

### Changed
- `/automate list` and `/automate help` now use standalone bash scripts for instant output without AI processing
- Added `automate-list.sh` (dynamic table from registry) and `automate-help.sh` (static command reference)

## [2.2.0] - 2026-03-15

### Added
- **Schema sync with Claude Code March 2026**: 21 hook events (+6 new: PostCompact, InstructionsLoaded, WorktreeCreate, WorktreeRemove, Elicitation, ElicitationResult), 31 subagent tools (+18 new), `http` hook handler type, new skill/subagent frontmatter fields
- **JSON config guard**: PreToolUse/PostToolUse hooks in SKILL.md frontmatter that validate JSON before writing to config files — prevents malformed JSON from silently breaking Claude Code
- **Adaptive interview**: 4-phase decision tree (quick classification → refinement → conflict check → name proposal with 3 suggestions) replaces flat question list
- **`/automate cleanup` command**: pre-uninstall cleanup that removes all automations with option to keep selected ones
- **Registry Bootstrap**: automatic reconstruction of the automations registry from `created-by: automate` file markers — handles seamless reinstallation
- **Daily docs check GitHub Action**: compares live Claude Code documentation against project schemas, opens issues when discrepancies are found
- **Rollback on failure**: if creation of a combination fails after 2 attempts, all components are cleaned up automatically
- 30 new structure tests (STRUCT-43..78) for new events, tools, guard script, model IDs

### Fixed
- Hook test in Step 7 now uses stdin (matching real hook behavior) instead of command-line arguments
- `validate-config.sh` accepts full model IDs (e.g. `claude-sonnet-4-6`) in addition to short names
- `guard-json-config.sh` calls jq once instead of twice per validation
- Template paths use `${CLAUDE_SKILL_DIR}` for reliable resolution across all environments
- Removed dead variable (`has_agent_paren`) from validate-config.sh
- MCP server validation accepts `http` transport type
- Agent team validation no longer requires `role` field (teams use natural language orchestration)

### Changed
- Step 0.2 (live docs fetch on every invocation) removed — replaced by daily GitHub Action
- Agent teams schema reflects natural language orchestration reality (`teammateMode` instead of `displayMode`)
- `sse` MCP transport marked as deprecated in favor of `http`
- Skills schema: `name` field now documented as optional (uses directory name if omitted), added `user-invocable`, `allowed-tools`, `model`, `agent`, `argument-hint` fields

## [2.1.1] - 2026-03-04

### Fixed
- **Hook input method**: documented that tool input is passed via **stdin** (JSON), not via `CLAUDE_TOOL_INPUT` or `TOOL_INPUT` environment variables. Previous documentation was incorrect — hooks using env vars silently failed.
- Updated all hook templates (`hook-block-command.json`, `hook-protect-files.json`, `hook-post-edit-format.json`) to read from stdin with `cat | jq`
- Updated hook examples in `claude-code-reference.md`, `SKILL.md`, `CLAUDE.md`, test fixtures, and test scripts
- Added `hookInput` section to `hooks.json` schema documenting the stdin JSON structure
- Regenerated all HTML documentation

## [2.1.0] - 2026-02-20

### Added
- **3 new hook events**: `TeammateIdle` (agent teammate idle), `TaskCompleted` (task marked done), `ConfigChange` (config file changed during session) — added to schema, validate-config.sh, and SKILL.md
- **`/automate verify` command**: health-check all registered automations, detect missing files/hook entries, and offer to repair them
- **settings.json merge algorithm**: SKILL.md Step 4 now has an explicit deep-merge procedure to prevent clobbering existing hooks when adding or removing entries
- Structure tests STRUCT-40, STRUCT-41, STRUCT-42 for the 3 new hook events

### Changed
- CLAUDE.md: updated hook event count from 12 to 15, added new events to the inline list, noted that `TeammateIdle`/`TaskCompleted` only support exit code 2

## [2.0.1] - 2026-02-20

### Changed
- Expanded CLAUDE.md with hook environment variables, hook special outputs (`updatedInput`, `decision`), and subagent `memory` field documentation

## [2.0.0] - 2026-02-06

### Breaking Changes
- Renamed project from `claude-code-expert` to `claude-code-automation`
- Renamed skill command from `/setup-automation` to `/automate`
- Updated all references, file markers, and GitHub URLs

### Added
- **MCP Servers**: Full support for Model Context Protocol server configuration (schema, template, fixture, validation)
- **LSP Servers**: Full support for Language Server Protocol configuration (schema, template, fixture, validation)
- **Agent Teams**: Full support for experimental multi-agent orchestration (schema, template, fixture, validation)
- New schemas: `mcp-servers.json`, `lsp-servers.json`, `agent-teams.json`
- New templates: `mcp-server.json`, `lsp-server.json`, `agent-team.json`
- New test fixtures: `mcp-server.json`, `lsp-server.json`, `agent-team.json`
- Hook handler fields: `async`, `timeout`, `statusMessage`, `model` for prompt/agent hooks
- Hook capabilities: `updatedInput` (PreToolUse input modification), `permissionDecision` (PermissionRequest control)
- Subagent fields: `disallowedTools`, `permissionMode`, `skills`, `hooks`, `memory`
- Subagent model default changed to `inherit`; new tools: `AskUserQuestion`, `TaskOutput`, `ExitPlanMode`, `MCPSearch`
- Skill fields: `context` (fork mode), `hooks` (scoped hooks)
- Built-in agents documentation (Explore, Plan, general-purpose, Bash)
- New environment variables: `CLAUDE_ENV_FILE`, `CLAUDE_PLUGIN_ROOT`, `CLAUDE_CODE_REMOTE`
- Decision matrix expanded with MCP Server, LSP Server, Agent Team columns
- New combination patterns: MCP Server + Skill, Agent Team + Skill
- Registry type values: `mcp-server`, `lsp-server`, `agent-team`
- CONTRIBUTING.md with development setup, architecture overview, and PR checklist
- GitHub issue templates (bug report, feature request, schema update)
- Pull request template
- GitHub Actions CI workflow (structure tests, E2E tests, fixture validation)
- CI badge in README
- Testing section in README explaining qualitative vs deterministic tests

### Changed
- Updated all schemas to match Claude Code 2026 features
- Reference documentation expanded with MCP, LSP, Agent Teams sections
- SKILL.md interview includes questions about external tools, code intelligence, and parallel agents
- Validation script (`validate-config.sh`) supports new types: `mcp-servers`, `lsp-servers`, `agent-team`
- Structure tests expanded from 14 to 23 (STRUCT-15 through STRUCT-23 for new types)
- E2E tests expanded with TEST-04 (MCP), TEST-05 (LSP), TEST-06 (Agent Team)

### Fixed
- TEST-01 fixture: `PreBash` (invalid) → `PreToolUse` with `Bash` matcher (valid)
- TEST-09 description: `PreWrite` (invalid) → `PreToolUse` with `Edit|Write` matcher (valid)

## [1.5.1] - 2026-02-05

### Added
- CLAUDE.md with project guidance for Claude Code instances

## [1.5.0] - 2026-02-05

### Added
- Mandatory completion verification for combination automations (Hook + Skill, etc.)
- Step 6: Verify COMPLETENESS - ensures all planned components are created
- Step 7: Test the automation - mandatory testing before finishing
- Step 8: Final report - checklist of all completed components
- CRITICAL RULE section emphasizing "complete all or nothing"

### Changed
- Common combinations section now lists REQUIRED components explicitly
- Important notes split into NEVER/ALWAYS rules for clarity
- Combinations must have relatedHook/relatedSkill links in registry

### Fixed
- Prevent incomplete automations (e.g., promising "Hook + Skill" but only creating skill)
- Prevent removing broken components instead of fixing them

## [1.4.1] - 2026-02-05

### Added
- Documentation for automation management sub-commands in README

## [1.4.0] - 2026-02-05

### Added
- Automation registry system (`~/.claude/automations-registry.json`)
- Sub-commands for setup-automation skill: `list`, `edit`, `delete`, `export`, `import`
- File markers (`created-by: setup-automation`) for tracking automation origin
- Export/import functionality for sharing automations between machines

### Changed
- setup-automation skill now includes Command Router for sub-command parsing
- All new automations are automatically tracked in the registry

## [1.3.0] - 2025-02-04

### Added
- Validation schemas in `plugin/schemas/` for hooks, skills, subagents, permissions, custom-commands
- Ready-to-use templates in `plugin/templates/` for all automation types
- Validation script `plugin/scripts/validate-config.sh` to check configurations before creation
- Semi-automatic documentation update workflow with diff preview

### Changed
- SKILL.md now reads schemas to validate configurations before creating files
- Documentation explicitly lists invalid hook events to avoid common mistakes
- Improved error prevention with explicit lists of valid values

### Fixed
- Test fixture `hook-only.json` corrected from invalid `PreBash` to valid `PreToolUse`

## [1.2.2] - 2025-02-04

### Fixed
- Corrected hook event names (PreToolUse, PostToolUse, etc. instead of invalid PreCommit)
- Fixed hook JSON structure (nested `hooks` array with `matcher` and `type`)
- Updated documentation with valid hook events and correct format

## [1.2.1] - 2025-02-04

### Fixed
- Interactive E2E tests now use `--dangerously-skip-permissions` for file creation
- Improved test prompts for more reliable file generation
- Fixed assert_file_contains bug in CLAUDE.md test

## [1.2.0] - 2025-02-04

### Added
- Interactive E2E tests that run actual Claude commands
- `tests/scripts/e2e-interactive.sh` for testing real file creation
- 5 interactive test scenarios (hook, skill, subagent, permissions, CLAUDE.md)
- `./run-tests.sh interactive` command for token-based tests
- `./run-tests.sh full` command for complete test suite

## [1.1.0] - 2025-02-04

### Added
- Test framework with 18 documented test cases
- Structure tests (fast, no Claude needed)
- E2E test scaffolding (requires Claude)
- Test fixtures for all automation types
- `tests/TEST.md` with detailed test documentation
- `tests/scripts/run-tests.sh` main test runner
- `tests/scripts/helpers.sh` test utilities

## [1.0.3] - 2025-02-04

### Changed
- Translated SKILL.md from Italian to English

## [1.0.2] - 2025-02-04

### Changed
- Populated CHANGELOG with proper format and history

## [1.0.1] - 2025-02-04

### Added
- CHANGELOG.md file
- VERSION file for tracking releases

## [1.0.0] - 2025-02-04

### Added
- Initial release
- `setup-automation` skill for deciding and creating Claude Code automations
- Decision matrix for choosing between hooks, skills, subagents, permissions, CLAUDE.md, and custom commands
- Auto-update feature to fetch latest Claude Code documentation
- Interactive interview workflow using AskUserQuestion
- Support for marketplace installation
