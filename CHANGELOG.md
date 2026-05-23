# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
