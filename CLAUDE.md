# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A multi-plugin repository for Claude Code automation:

| Plugin | Directory | Command | Description |
|--------|-----------|---------|-------------|
| **automate** | `plugin/` | `/automate` | Expert advisor: interviews user, applies decision matrix, creates the right automation type |
| **develop-cycle** | `plugin-develop-cycle/` | `/develop-cycle` | Structured dev workflow with mandatory checkpoint before commit/push |
| **plan-cycle** | `plugin-plan/` | `/plan-cycle`, `/plan-cycle:plan-impact`, `/plan-cycle:plan-quality` | File-based planning with annotation pipeline |
| **takeaway** | `plugin-takeaway/` | `/takeaway` | Structured feedback extraction — interviews user, identifies patterns, produces agent-ready improvements |

The automate plugin is the core of this repo. develop-cycle, plan-cycle, and takeaway are self-contained single-skill plugins in their own directories.

## Architecture

The plugin is built on a **schema / template / SKILL.md triangle**:

```
  SKILL.md (orchestrator)
    /            \
schemas/        templates/
(source of       (starting
 truth)           points)
```

- **Schemas** define what's valid. SKILL.md loads them at Step 0 and validates against them at Step 5.
- **Templates** are working baselines that SKILL.md customizes during creation.
- **SKILL.md** orchestrates everything: loads schemas, interviews user, applies decision matrix, creates files, validates.

When Claude Code changes (new hook events, new tools, etc.), update the **schema first**, then adjust templates and SKILL.md to match.

### SKILL.md Internals

The core creation workflow is in `plugin/skills/automate/SKILL.md`. Management commands are separate skills under `plugin/skills/automate-*/SKILL.md` for faster execution (each loads only its own content instead of the full 800+ line creation workflow).

**Main skill (`/automate`):**
1. **Registry Bootstrap**: Checks if the registry exists. If not, scans for files with `created-by: automate` markers and rebuilds the registry (handles reinstallation after uninstall).
2. **Backwards Compat Router**: If `$ARGUMENTS` matches an old sub-command name, suggests the new `/automate-*` skill.
3. **8-Step Creation Workflow**: Load schemas → Interview → Decide → Explain → Create → Validate → Verify completeness → Test → Report.

**Management skills (`/automate-*`):**
| Skill | Type | Description |
|-------|------|-------------|
| `/automate-help` | Script-only | Runs `automate-help.sh`, zero AI |
| `/automate-list` | Script-only | Runs `automate-list.sh`, zero AI |
| `/automate-verify` | Light AI | Reads registry, checks files, offers repair |
| `/automate-export` | Light AI | Reads registry, bundles content to JSON |
| `/automate-delete` | Light AI | Finds automation, confirms, removes |
| `/automate-edit` | Medium AI | Finds automation, asks changes, validates, saves |
| `/automate-import` | Medium AI | Reads file, resolves conflicts, creates, registers |
| `/automate-cleanup` | Medium AI | Lists all, options keep/remove, cleans up |

**Shared context**: `plugin/docs/shared-context.md` contains registry bootstrap, merge algorithm, schema refs, file markers, and deletion procedures. Skills that need shared procedures reference this file.

**Two-Level Validation**: SKILL.md loads schemas at Step 0, validates against them at Step 5, and `plugin/scripts/validate-config.sh` provides external validation.

**Registry System**: All automations tracked in `~/.claude/automations-registry.json` with metadata (id, name, type, scope, path, timestamps).

### Key Directories

- `plugin/skills/automate/` — Main creation workflow skill
- `plugin/skills/automate-*/` — Management command skills (list, edit, delete, export, import, verify, cleanup, help)
- `plugin/schemas/` — Source of truth for valid configurations (hooks events, skill frontmatter, subagent tools/models, permission patterns, custom command limits, MCP servers, LSP servers, agent teams)
- `plugin/templates/` — Ready-to-use templates (hook variants, skill, subagent, permissions, custom command, MCP server, LSP server, agent team)
- `plugin/docs/shared-context.md` — Shared procedures for management skills (registry bootstrap, merge algorithm, deletion procedures)
- `plugin/docs/claude-code-reference.md` — Reference copy; Step 0 fetches live docs from code.claude.com and diffs against this
- `tests/fixtures/` — Expected-output examples used by fixture tests
- `plugin/scripts/validate-config.sh` — External validation script (also used in CI)
- `plugin/scripts/guard-json-config.sh` — Hook handler that validates JSON config files before/after writes (prevents malformed JSON from breaking Claude Code settings, `.mcp.json`, etc.)

## Plugin Packaging

Two `.claude-plugin/` directories serve different purposes:
- **`.claude-plugin/marketplace.json`** (repo root) — Marketplace registry entry, used by the plugin update system. Contains the `plugins[]` array with version and `"source": "./plugin"`.
- **`plugin/.claude-plugin/plugin.json`** (inside `plugin/`) — Plugin metadata (name, version, description). This is the entry point Claude Code reads when the plugin is installed.

## Version Files (IMPORTANT)

When bumping version, update ALL these files:
- `VERSION` — main version file
- `CHANGELOG.md` — add entry at top
- `plugin/.claude-plugin/plugin.json` — `"version"` field
- `.claude-plugin/marketplace.json` — `"version"` field in `plugins[]` array

The marketplace.json version is used by Claude Code's plugin update system. If out of sync, updates won't work.

A GitHub Action (`auto-tag.yml`) automatically creates a git tag `v{VERSION}` when the VERSION file changes on main. **Do not create tags manually.**

## Running Tests

```bash
# Structure tests — fast, no Claude needed (97 tests, IDs: STRUCT-01..STRUCT-97)
./tests/scripts/run-tests.sh structure

# Fixture tests — validates expected output structures, no Claude needed (20 tests, IDs: TEST-02..TEST-06 with sub-tests)
./tests/scripts/run-tests.sh e2e

# Interactive tests — runs actual Claude, consumes tokens
./tests/scripts/run-tests.sh interactive

# Run a specific test by ID
./tests/scripts/run-tests.sh STRUCT-07
./tests/scripts/run-tests.sh TEST-01

# Full suite (structure + e2e + interactive)
./tests/scripts/run-tests.sh full
```

CI runs structure + e2e tests only (no API key needed). Interactive tests are local-only.

**Prerequisites**: Tests require `bash` and `jq`. CI installs `jq` explicitly.

Test helpers are in `tests/scripts/helpers.sh` (assertions, sandbox management, `run_claude_headless()`).

### Validation Script

```bash
plugin/scripts/validate-config.sh <type> <content>
# <type>: hooks, skill, subagent, permissions, custom-commands, mcp-servers, lsp-servers, agent-team
# <content>: JSON/YAML string, file path, or '-' for stdin
# Exit codes: 0=valid, 1=invalid config, 2=usage error
```

## Schemas — Critical Constraints

Schemas in `plugin/schemas/` define what's valid. Key gotchas:

- **Hook events**: 29 valid events (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `UserPromptExpansion`, `PermissionRequest`, `PermissionDenied`, `Notification`, `Stop`, `StopFailure`, `PreCompact`, `PostCompact`, `SubagentStart`, `SubagentStop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `ConfigChange`, `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`, `Elicitation`, `ElicitationResult`, `CwdChanged`, `FileChanged`, `Setup`). NEVER use `PreCommit`, `PostCommit`, `PreBash`, `PostBash`, `BeforeToolUse`, `AfterToolUse` — they don't exist.
- **Hook exit codes**: `0` = allow, `2` = block (stderr becomes feedback), anything else = allow but log error. Exit code 1 does NOT block.
- **Hook structure**: Nested — `hooks.EventName[].hooks[]` (array inside array), not flat.
- **Hook handler types**: `command` (shell script), `http` (POST to URL), `prompt` (single-turn LLM), `agent` (multi-turn LLM). All events support all 4 types. Fields: `if` (permission rule syntax filter), `async`, `timeout`, `statusMessage`, `model`, `once`, `shell` (`bash`/`powershell`). HTTP type adds: `url`, `headers`, `allowedEnvVars`.
- **Hook input**: Tool input is passed via **stdin** as JSON (NOT via environment variables). Read with `cat | jq -r '.tool_input.file_path'`. Available env vars (without tool input): `CLAUDE_PROJECT_DIR`, `CLAUDE_SESSION_ID`, `CLAUDE_ENV_FILE`, `CLAUDE_PLUGIN_ROOT`, `CLAUDE_CODE_REMOTE`.
- **Hook special outputs**: `PreToolUse` hooks can modify tool inputs via `hookSpecificOutput.updatedInput`, add context via `additionalContext`, and control permissions via `permissionDecision`. `PermissionRequest` hooks control decisions via `hookSpecificOutput.decision.behavior` (allow/deny). `PostToolUse` hooks can replace MCP tool output via `updatedMCPToolOutput`.
- **Permissions**: Don't work with `--dangerously-skip-permissions`. Use hooks (exit 2) as a guaranteed alternative. Permission patterns support `Agent(name)`, `Skill(name)`, and `MCPSearch`.
- **Skills**: `disable-model-invocation: true` = manual only (invoked via `/skill-name`); `false` = Claude auto-applies when relevant. Optional: `context: fork`, `agent`, `hooks`, `allowed-tools`, `model`, `user-invocable`, `argument-hint`, `effort` (`low`/`medium`/`high`/`max`), `paths` (glob patterns), `shell` (`bash`/`powershell`). Variables: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`. Supports `!`command`` for dynamic context injection. Including "ultrathink" in content enables extended thinking.
- **Subagent tools**: `Agent`, `AskUserQuestion`, `Bash`, `CronCreate`, `CronDelete`, `CronList`, `Edit`, `EnterPlanMode`, `EnterWorktree`, `ExitPlanMode`, `ExitWorktree`, `Glob`, `Grep`, `ListMcpResourcesTool`, `LSP`, `Monitor`, `NotebookEdit`, `PowerShell`, `Read`, `ReadMcpResourceTool`, `SendMessage`, `Skill`, `TaskCreate`, `TaskGet`, `TaskList`, `TaskOutput`, `TaskStop`, `TaskUpdate`, `TeamCreate`, `TeamDelete`, `TodoWrite`, `ToolSearch`, `WebFetch`, `WebSearch`, `Write`. Plus MCP tools as `mcp__<server>__<tool>`. Use `Agent(type1, type2)` to restrict which subagent types can be spawned. `TaskOutput` is deprecated — use `Read` on the task's output file path instead.
- **Subagent models**: `opus`, `sonnet`, `haiku`, `inherit` (default: `inherit`).
- **Subagent memory field**: Optional `memory` in frontmatter — values `user`, `project`, `local` give the subagent a persistent directory across conversations.
- **Subagent new fields**: `maxTurns` (max agentic turns), `mcpServers` (scoped MCP servers), `background` (always run in background), `isolation: worktree` (isolated git worktree), `effort` (`low`/`medium`/`high`/`max`, Opus 4.6 only), `initialPrompt` (auto-submitted first turn with `--agent`).
- **MCP servers**: Types: `stdio` (requires `command`), `http` (requires `url`, recommended for remote), `sse` (deprecated, requires `url`), `ws` (requires `url`, WebSocket). HTTP supports `headers` (with env var interpolation), `headersHelper` (dynamic shell command), and `oauth` (with `authServerMetadataUrl` override, v2.1.64+). Tools named `mcp__<server>__<tool>`. Supports env var expansion in `.mcp.json` (`${VAR}`, `${VAR:-default}`). Features: resources (@ mentions), prompts (as commands), tool search, elicitation, channels (push messages via `claude/channel` capability).
- **LSP servers**: Requires `command` and `languages` array.
- **Agent teams**: Experimental (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, v2.1.32+). Teams are orchestrated via natural language, not declarative JSON. Display mode configured via `teammateMode` setting (`in-process`, `tmux`, `auto`).

## Automation Decision Matrix

| Need | Solution |
|------|----------|
| MUST happen every time | Hook |
| Claude needs to think | Skill |
| Isolated context needed | Subagent |
| Block specific actions | Permissions (or Hook if using --dangerously-skip-permissions) |
| Advisory rule | CLAUDE.md |
| Shortcut for a frequent prompt | Custom Command |
| External tool/service integration | MCP Server |
| Code intelligence | LSP Server |
| Parallel multi-agent orchestration | Agent Team (experimental) |

## Combination Rules

When the skill decides a combination is needed (e.g., "Hook + Skill"):
1. ALL components must be created — never partial implementations
2. ALL components must be validated against schemas and tested
3. ALL components must be registered in `~/.claude/automations-registry.json`
4. Related components must have `relatedHook`/`relatedSkill` links in the registry
5. Missing components must be fixed, not removed

## Registry Type Values

Valid values for the `type` field in automations-registry.json:
`skill`, `hook`, `subagent`, `permission`, `custom-command`, `claude-md`, `mcp-server`, `lsp-server`, `agent-team`

## File Markers

All auto-created files include origin markers:
- Markdown: `created-by: automate` in YAML frontmatter
- JSON: `_meta.createdBy` and `_meta.createdAt` fields

## Adding a New Automation Type

1. Create schema in `plugin/schemas/[type].json`
2. Create template in `plugin/templates/[type].json` (or `.md`)
3. Add `validate_[type]()` function in `validate-config.sh` and wire it into the `case` statement
4. Create fixture files in `tests/fixtures/`
5. Add structure + E2E test assertions in `run-tests.sh`
6. Update SKILL.md: decision matrix, Step 0 schema loading, Step 4 creation, combinations
7. Update `plugin/docs/claude-code-reference.md`

## Updating Schemas (When Claude Code Changes)

When Anthropic adds new hook events, tools, etc.: update the **schema** → update `validate-config.sh` → update SKILL.md inline lists → update `plugin/docs/claude-code-reference.md` → add structure tests if needed.

## GitHub Actions

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR to main | Runs structure + e2e tests + fixture validation |
| `auto-tag.yml` | VERSION file changes on main | Creates `v{VERSION}` git tag automatically |
| `check-docs-updates.yml` | Daily cron | Fetches docs from code.claude.com, compares against schemas, opens `schema-update` issue if discrepancies found |
