# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.0] - 2026-03-31

### Added
- **`if` field** on all hook handlers — permission rule syntax filter (e.g. `Bash(git *)`)
- **`ws` transport type** for MCP servers — WebSocket support alongside stdio, http, sse
- **`auto` permission mode** added to hook input schema

### Changed
- **All hook events now support all 4 handler types** (command, http, prompt, agent) — removed `commandOnly` restriction from 16 events
- **Skill context budget** corrected to 1% of context window (fallback: 8,000 chars), each entry capped at 250 characters
- **CLAUDE.md** updated with multi-plugin repo overview and GitHub Actions table

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
