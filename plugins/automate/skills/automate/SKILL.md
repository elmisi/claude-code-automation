---
name: automate
description: Expert advisor that helps decide and create the right Claude Code automation
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "\"${CLAUDE_PLUGIN_ROOT}/scripts/guard-json-config.sh\""
          statusMessage: "Validating JSON before write..."
  PostToolUse:
    - matcher: "Edit"
      hooks:
        - type: command
          command: "\"${CLAUDE_PLUGIN_ROOT}/scripts/guard-json-config.sh\""
          statusMessage: "Validating JSON after edit..."
---

# Claude Code Automation

Arguments: $ARGUMENTS

---

## Registry Bootstrap

Before routing commands, ensure the registry is available.

**If `~/.claude/automations-registry.json` does NOT exist:**

Scan for existing automations created by this plugin (they have `created-by: automate` markers). This handles reinstallation after uninstall.

1. Scan `~/.claude/skills/*/SKILL.md` and `.claude/skills/*/SKILL.md` for frontmatter containing `created-by: automate`
2. Scan `~/.claude/agents/*.md` and `.claude/agents/*.md` for frontmatter containing `created-by: automate`
3. Scan `~/.claude/settings.json` for hook entries with `"_meta": {"createdBy": "automate"}`
4. Scan `.claude/settings.json` for the same
5. Scan `.mcp.json` and `~/.claude.json` for MCP entries with `"_meta": {"createdBy": "automate"}`
6. Scan `.lsp.json` and `~/.claude/lsp.json` for LSP entries with `"_meta": {"createdBy": "automate"}`

For each found automation, reconstruct a registry entry:
```json
{
  "id": "recovered-<type>-<name>",
  "name": "<extracted from frontmatter or key name>",
  "type": "<skill|hook|subagent|permission|custom-command|mcp-server|lsp-server>",
  "scope": "<global if in ~/.claude/, project if in .claude/>",
  "path": "<absolute path to the file>",
  "created": "<file modification time>",
  "modified": "<file modification time>",
  "description": "<extracted from frontmatter or empty>",
  "recovered": true
}
```

Write the rebuilt registry and report:
> "Found N existing automations created by this plugin. Registry rebuilt."

If nothing found → proceed normally (clean start).

---

## Command Router

Parse `$ARGUMENTS` to check for sub-commands:

**If `$ARGUMENTS` is `list`, `help`, `verify`, `edit`, `delete`, `export`, `import`, or `cleanup`:**

Tell the user:
> "Management commands are now separate skills for faster execution. Use `/automate-{command}` instead. For example: `/automate-list`, `/automate-edit <name>`, etc. Run `/automate-help` for the full reference."

Then STOP. Do not proceed to the creation workflow.

**Otherwise:** Proceed to **Create New Automation** below.

---

# Create New Automation

---

## CRITICAL RULE: COMPLETE ALL COMPONENTS

**This skill MUST create EVERYTHING it promises. Partial implementations are FORBIDDEN.**

If you decide "Hook + Skill is needed":
- You MUST create the hook AND the skill
- You MUST test that both work
- You MUST NOT finish until both are verified

If ANY component fails:
- FIX IT before proceeding
- DO NOT remove it and continue
- DO NOT leave it for "later"

**An incomplete automation is worse than no automation.**

---

## Step 0: Load validation schemas

Read the schema files from this plugin to know what values are valid:
- `plugins/automate/schemas/hooks.json` - Valid hook events, types, matchers
- `plugins/automate/schemas/skills.json` - Skill frontmatter requirements
- `plugins/automate/schemas/subagents.json` - Subagent configuration
- `plugins/automate/schemas/permissions.json` - Permission patterns
- `plugins/automate/schemas/custom-commands.json` - Custom command format
- `plugins/automate/schemas/mcp-servers.json` - MCP server configuration
- `plugins/automate/schemas/lsp-servers.json` - LSP server configuration
- `plugins/automate/schemas/agent-teams.json` - Agent team configuration

**CRITICAL: Only use values listed in these schemas. Never invent event names or fields.**

---

## Step 1: Adaptive interview

Use AskUserQuestion for each phase. The interview adapts based on answers to minimize questions.

### Phase 1: Quick classification (1 question)

Ask the user to pick the closest category:

```
What best describes what you want to create?
1. Something that must happen automatically every time (e.g., check before every commit)
2. Knowledge or rules Claude should follow (e.g., coding standards, project conventions)
3. A workflow I'll trigger manually (e.g., generate boilerplate, run analysis)
4. Integration with external tools/services (e.g., database, API, GitHub)
5. Multiple agents working in parallel on different aspects
6. I'm not sure, help me decide
```

### Phase 2: Refinement (1-2 questions, based on Phase 1)

**If answer is 1 (automatic/every time) → Hook path:**
Ask: "Does it need Claude's intelligence to decide, or is a simple script enough?"
- Simple script → Hook only
- Needs intelligence → Hook + Skill combination

**If answer is 2 (knowledge/rules) → Skill or CLAUDE.md path:**
Ask: "Must this rule be GUARANTEED (can never be skipped), or is it advisory (Claude should follow it but it's not critical)?"
- Guaranteed → Hook (not CLAUDE.md, which is advisory)
- Advisory → ask: "Should Claude apply this automatically when relevant, or only when you invoke it?"
  - Automatically → Skill with `disable-model-invocation: false`
  - Only on invocation → Skill with `disable-model-invocation: true`
  - Simple one-liner rule → CLAUDE.md

**If answer is 3 (manual workflow) → Skill (manual) path:**
Ask: "Does this workflow need a separate, isolated context (e.g., deep analysis that shouldn't pollute your main conversation)?"
- Yes → Skill + Subagent
- No → Skill with `disable-model-invocation: true`

**If answer is 4 (external integration) → MCP/LSP path:**
Ask: "What kind of integration do you need?"
- External tool/service/API → MCP Server (ask: "What service/tool do you want to integrate?")
- Code intelligence (diagnostics, hover, go-to-definition) → LSP Server

**If answer is 5 (parallel agents) → Agent Team path:**
Proceed directly. Warn about experimental status.

**If answer is 6 (not sure) → Full interview:**
Ask ALL of these questions (one AskUserQuestion with numbered items):
1. When should this happen? (always/on specific action/on request/in certain contexts)
2. Must it be guaranteed or is it advisory?
3. Does it need Claude's intelligence or can a script handle it?
4. Should it apply to all projects or just this one?
5. Does it involve external tools/services?
6. Does it need multiple agents working in parallel?

### Phase 3: Conflict check (automatic, no user question needed)

Before proceeding, read `~/.claude/automations-registry.json` and check for conflicts:
- Any existing automation with the same name or similar description
- Any hook on the same event + matcher combination

If conflicts are found, use AskUserQuestion to show them:
```
Found existing automation that may conflict:
  - "pre-commit-check" (hook, PreToolUse → Bash) — "Blocks pushes to main"

What would you like to do?
1. Overwrite the existing automation
2. Rename the new automation
3. Cancel
```

### Phase 4: Name proposal (1 question)

Propose 3 name options based on the automation's purpose:

```
Suggested names:
1. pre-commit-tests
2. test-runner-hook
3. commit-guard
Which do you prefer? (or type your own)
```

Also ask about scope if not yet determined:
- Global (all projects): `~/.claude/...`
- Project-only: `.claude/...`

---

## Step 2: Analysis and decision

Based on the answers, use this decision matrix:

| Criterion | Hook | Skill | Skill (manual) | Subagent | Permissions | CLAUDE.md | Custom Cmd | MCP Server | LSP Server | Agent Team |
|-----------|------|-------|----------------|----------|-------------|-----------|------------|------------|------------|------------|
| Must happen ALWAYS without exceptions | YES | no | no | no | no | no | no | no | no | no |
| Rule about what Claude can/cannot do | no | no | no | no | YES | maybe | no | no | no | no |
| Domain knowledge applied automatically | no | YES | no | no | no | maybe | no | no | no | no |
| Complex workflow invoked manually | no | no | YES | no | no | no | no | no | no | no |
| Needs separate/isolated context | no | no | no | YES | no | no | no | no | no | no |
| Independent review/analysis | no | no | no | YES | no | no | no | no | no | no |
| Simple global rule | no | no | no | no | no | YES | no | no | no | no |
| Shortcut for frequent prompt | no | no | no | no | no | no | YES | no | no | no |
| External tool/service integration | no | no | no | no | no | no | no | YES | no | no |
| Code intelligence/language analysis | no | no | no | no | no | no | no | no | YES | no |
| Parallel multi-agent orchestration | no | no | no | no | no | no | no | no | no | YES |

### Common combinations (MUST create ALL components)

**Hook + Skill** - When it must always happen (hook) but requires complex logic (skill)
- REQUIRED: Hook script in `~/.claude/scripts/`
- REQUIRED: Hook entry in `settings.json` with VALID event (PreToolUse, PostToolUse, etc.)
- REQUIRED: Skill file in `~/.claude/skills/[name]/SKILL.md`
- REQUIRED: Both registered with `relatedHook`/`relatedSkill` links

**Skill + Subagent** - When the skill defines the workflow but needs a subagent for deep analysis
- REQUIRED: Skill file
- REQUIRED: Subagent file in `~/.claude/agents/[name].md`
- REQUIRED: Both registered with links

**Permissions + CLAUDE.md** - Permissions for technical block, CLAUDE.md to explain why
- REQUIRED: Permission rule in `settings.json`
- REQUIRED: Rule explanation in `CLAUDE.md`
- REQUIRED: Both registered

**MCP Server + Skill** - External tool access + workflow orchestration
- REQUIRED: MCP server config in `.mcp.json`
- REQUIRED: Skill file with workflow using MCP tools
- REQUIRED: Both registered with links

**Agent Team + Skill** - Multi-agent orchestration + domain knowledge
- REQUIRED: Team config in `~/.claude/teams/{name}/config.json`
- REQUIRED: Skill defining when/how to invoke the team
- REQUIRED: Both registered with links

---

## Step 2.5: Show example before proceeding

After the decision and before explaining, show the user a concrete preview of what will be created. This helps the user confirm the approach is correct before any files are written.

**For a Hook:**
```
Here's what will be created:

~/.claude/settings.json (hook entry):
{
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "~/.claude/scripts/your-hook.sh"}]}]
  }
}

~/.claude/scripts/your-hook.sh (executable script):
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
# ... your logic here ...
```

**For a Skill:**
```
Here's what will be created:

~/.claude/skills/skill-name/SKILL.md:
---
name: skill-name
description: What this skill does
disable-model-invocation: true
created-by: automate
---
# Skill Title
...
```

**For a Subagent:**
```
Here's what will be created:

~/.claude/agents/agent-name.md:
---
name: agent-name
description: What this agent does
tools: Read, Grep, Glob, Bash
model: inherit
created-by: automate
---
...
```

**For MCP Server:**
```
Here's what will be created:

.mcp.json (or ~/.claude.json for global):
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": []
    }
  }
}
```

**For combinations**, show all components that will be created.

Adapt the example to use the actual names, events, and logic discussed during the interview. Use AskUserQuestion to confirm: "Does this look right? (Yes / Adjust / Cancel)"

---

## Step 3: Explain the decision

Before creating, explain to the user:
1. What you decided to create and why
2. Alternatives considered and why they were discarded
3. How it will work in practice
4. Any limitations or considerations

**If the decision involves a COMBINATION (e.g., Hook + Skill), explicitly list ALL components:**

```
CREATION PLAN:
[ ] Component 1: Hook (PreToolUse → Bash) - enforces the rule
[ ] Component 2: Skill (semver) - provides the logic
```

**CRITICAL: You MUST create ALL components. Do NOT proceed to Step 6 until all boxes are checked.**

Ask for confirmation before proceeding.

---

## Step 4: Create the files with VALIDATION

**CRITICAL: Before creating any file, validate against the schemas.**

### Registry tracking

**Every automation created MUST be registered.**

After creating the files, add to `~/.claude/automations-registry.json`:

```json
{
  "id": "unique-id",
  "name": "automation-name",
  "type": "skill|hook|subagent|permission|custom-command|claude-md|mcp-server|lsp-server|agent-team",
  "scope": "global|project",
  "path": "path/to/main/file",
  "created": "ISO-timestamp",
  "modified": "ISO-timestamp",
  "description": "what it does"
}
```

### File markers

Add `created-by: automate` marker to files:

**For Skills/Subagents (markdown frontmatter):**
```yaml
---
name: skill-name
description: ...
created-by: automate
---
```

**For JSON configs (hooks, permissions, custom-commands):**
Add to the specific entry:
```json
{
  "_meta": {
    "createdBy": "automate",
    "createdAt": "ISO-timestamp"
  }
}
```

**For MCP/LSP configs (JSON):**
Same pattern as hooks:
```json
{
  "_meta": {
    "createdBy": "automate",
    "createdAt": "ISO-timestamp"
  }
}
```

**For Agent Teams (JSON):**
Same pattern:
```json
{
  "_meta": {
    "createdBy": "automate",
    "createdAt": "ISO-timestamp"
  }
}
```

### For Hook

**ONLY use these valid events** (from `schemas/hooks.json`):
- `SessionStart` - Session begins (matchers: startup, resume, clear, compact)
- `SessionEnd` - Session ends (matchers: clear, resume, logout, prompt_input_exit, other, bypass_permissions_disabled)
- `UserPromptSubmit` - When user submits a prompt (no matcher)
- `PreToolUse` - Before a tool executes (matchers: Bash, Edit, Write, Edit|Write, mcp__.*)
- `PostToolUse` - After a tool succeeds (same matchers as PreToolUse)
- `PostToolUseFailure` - After a tool fails
- `PermissionRequest` - When permission dialog appears
- `Notification` - When Claude needs attention (matchers: permission_prompt, idle_prompt)
- `MessageDisplay` - While assistant text streams to the user (no matcher; non-blocking; replace shown text via hookSpecificOutput.displayContent — display only; 10s timeout)
- `Stop` - When Claude finishes responding (no matcher)
- `StopFailure` - When turn ends due to API error (matchers: rate_limit, authentication_failed, billing_error, invalid_request, server_error, max_output_tokens, unknown; output ignored)
- `PreCompact` - Before context compaction (matchers: manual, auto)
- `PostCompact` - After context compaction completes (matchers: manual, auto)
- `SubagentStart`, `SubagentStop` - Subagent lifecycle
- `TeammateIdle` - Agent team teammate about to go idle (matchers: agent name; exit 2 only)
- `TaskCreated` - Task being created via TaskCreate (no matcher; exit 2 prevents creation)
- `TaskCompleted` - Task being marked completed (no matcher; exit 2 only)
- `ConfigChange` - Config file changed during session (matchers: user_settings, project_settings, local_settings, policy_settings, skills)
- `InstructionsLoaded` - When CLAUDE.md or .claude/rules/*.md loaded (matchers: session_start, nested_traversal, path_glob_match, include, compact; exit code ignored)
- `WorktreeCreate` - When a worktree is being created (no matcher; any non-zero exit fails creation)
- `WorktreeRemove` - When a worktree is being removed (no matcher)
- `Elicitation` - When MCP server requests user input (matchers: MCP server name regex)
- `ElicitationResult` - After user responds to MCP elicitation (matchers: MCP server name regex)
- `CwdChanged` - When working directory changes, e.g. cd (no matcher; useful for direnv)
- `FileChanged` - When a watched file changes on disk (matchers: filename basename, e.g. .envrc, .env)
- `PermissionDenied` - When user denies a permission request (matchers: tool name; non-blocking, informational)
- `PostToolBatch` - After a full batch of parallel tool calls resolves (no matcher; can block next model call or add context)
- `UserPromptExpansion` - When a user-typed slash command expands into a prompt (matchers: command name; can block expansion or add context)
- `Setup` - Fires with `--init-only`, or `--init`/`--maintenance` in `-p` mode (matchers: init, maintenance; command type only, cannot block)

**NEVER use these (they don't exist):**
- PreCommit, PostCommit, PreBash, PostBash, PreEdit, PostEdit, BeforeToolUse, AfterToolUse

**Correct structure:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here"
          }
        ]
      }
    ]
  }
}
```

#### REQUIRED: settings.json merge algorithm

NEVER overwrite settings.json. Always merge.

**Adding a hook:**
1. Read entire `~/.claude/settings.json` (use `{}` if it doesn't exist)
2. Append new matcher object to `.hooks["EventName"][]`
   - If `.hooks` doesn't exist → set to `{}`
   - If `.hooks["EventName"]` doesn't exist → set to `[]`
   - Append, never replace
3. Write complete merged JSON back
4. Read back and confirm the entry is present

**Removing a hook:**
1. Read entire settings.json
2. Remove ONLY the specific array element whose inner `hooks[].command` matches
   (or match via `_meta.createdBy: "automate"` + automation name)
3. If the event array becomes empty → remove the event key
4. Write back

**Never write a partial `hooks` object — always include all existing events.**

**Hook handler fields:**
- `type` (string, required): `command`, `http`, `prompt`, or `agent`. All events support all 4 types.
- `if` (string, optional): Permission rule syntax filter — only runs hook when tool/event matches (e.g. `Bash(git *)`)
- `command` (string): Shell command to run (command type)
- `prompt` (string): Prompt text (prompt/agent type)
- `url` (string): URL endpoint (http type, required)
- `headers` (object): HTTP headers (http type, optional; supports `$VAR` interpolation from environment)
- `allowedEnvVars` (array): Environment variables to include in http request (http type, optional)
- `async` (boolean): Run hook in background without blocking Claude (command type only)
- `shell` (string): Shell to use — `bash` (default) or `powershell` (Windows). Requires CLAUDE_CODE_USE_POWERSHELL_TOOL=1
- `timeout` (integer): Timeout in seconds. Defaults: command=600, prompt=30, agent=60
- `statusMessage` (string): Custom spinner message while hook runs
- `model` (string): Model for prompt/agent hooks (default: haiku)
- `once` (boolean): Run hook only once per session

**Exit codes:**
- Exit 0 = allow the action
- Exit 2 = block the action (stderr becomes Claude's feedback)

**Input modification (PreToolUse only):**
PreToolUse hooks can modify tool inputs via `hookSpecificOutput.updatedInput`. When a hook returns JSON with an `updatedInput` field, Claude will use the modified input instead of the original.

**Hook input (stdin):**
Hook commands receive a JSON object via **stdin** with the full context. Read it with `cat` or `jq`:
- `cat | jq -r '.tool_name'` - Name of the tool
- `cat | jq -r '.tool_input.file_path'` - Tool input fields
- `cat | jq -r '.tool_input.command'` - Bash command (for Bash tool)

**Note:** `TOOL_INPUT` and `CLAUDE_TOOL_INPUT` env vars are NOT set. Always read from stdin.

**Environment variables available to hooks (no tool input):**
- `CLAUDE_PROJECT_DIR` - Project directory path
- `CLAUDE_SESSION_ID` - Current session identifier
- `CLAUDE_ENV_FILE` - File path for persisting environment variables (SessionStart hooks)
- `CLAUDE_PLUGIN_ROOT` - Root directory of the plugin
- `CLAUDE_PLUGIN_DATA` - Directory for plugin persistent data (survives plugin updates)
- `CLAUDE_CODE_REMOTE` - Set to 'true' in remote/web environments

**Use templates from `${CLAUDE_SKILL_DIR}/../../templates/hook-*.json` as a base.**

### For Skill

Location: `.claude/skills/[name]/SKILL.md` (project) or `~/.claude/skills/[name]/SKILL.md` (global)

Required frontmatter:
```yaml
---
name: skill-name
description: What this skill does
disable-model-invocation: true|false
created-by: automate
---
```

Use template from `${CLAUDE_SKILL_DIR}/../../templates/skill.md`.

### For Subagent

Location: `.claude/agents/[name].md` (project) or `~/.claude/agents/[name].md` (global)

Required frontmatter:
```yaml
---
name: agent-name
description: What this agent does
tools: Read, Grep, Glob, Bash
model: inherit
created-by: automate
---
```

Valid tools: Agent, Artifact, AskUserQuestion, Bash, CronCreate, CronDelete, CronList, Edit, EnterPlanMode, EnterWorktree, ExitPlanMode, ExitWorktree, Glob, Grep, ListAgents, ListMcpResourcesTool, LSP, Monitor, NotebookEdit, PowerShell, PushNotification, Read, ReadMcpResourceTool, RemoteTrigger, ReportFindings, ScheduleWakeup, SendMessage, SendUserFile, ShareOnboardingGuide, Skill, TaskCreate, TaskGet, TaskList, TaskOutput, TaskStop, TaskUpdate, TeamCreate, TeamDelete, TodoWrite, ToolSearch, WaitForMcpServers, WebFetch, WebSearch, Workflow, Write
MCP tools can also be used as `mcp__<server>__<tool>`

Valid models: opus, sonnet, haiku, inherit

Optional frontmatter fields:
- `disallowedTools` - Tools the subagent cannot use
- `permissionMode` - Permission handling mode (default, acceptEdits, dontAsk, bypassPermissions, plan)
- `skills` - Skills to preload into subagent context at startup
- `hooks` - Hooks specific to the subagent
- `memory` - Persistent memory scope (user, project, local)
- `maxTurns` - Maximum number of agentic turns
- `mcpServers` - MCP servers scoped to this subagent
- `background` - Always run as background task (boolean)
- `isolation` - Set to 'worktree' for isolated git worktree
- `effort` - Effort level: low, medium, high, max (Opus 4.6 only)
- `initialPrompt` - Auto-submitted as first user turn when running as main session agent (via --agent)

Use template from `${CLAUDE_SKILL_DIR}/../../templates/subagent.md`.

### For Permissions

Location: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": ["Bash(git commit *)"],
    "deny": ["Bash(git push *)"]
  }
}
```

**Warning:** Does NOT work with `--dangerously-skip-permissions`. Use Hooks instead for guaranteed blocks.

### For Custom Command

Location: `.claude/settings.json`

```json
{
  "customCommands": {
    "name": "prompt text"
  }
}
```

### For CLAUDE.md

Add the rule to `./CLAUDE.md` (project) or `~/.claude/CLAUDE.md` (global).

### For MCP Server

Location: `.mcp.json` (project) or `~/.claude.json` (global, under `mcpServers` key)

Structure:
```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": ["--flag"],
      "env": {"KEY": "value"}
    }
  }
}
```

Valid types: stdio, http, sse (deprecated), ws
- stdio: requires `command` field
- http: requires `url` field, optional `headers` and `oauth` (recommended for remote)
- sse: requires `url` field (deprecated, use http instead)
- ws: requires `url` field, WebSocket transport
- Tools appear as `mcp__<server>__<tool>` in Claude
- Can be used in hook matchers: `"matcher": "mcp__servername__.*"`

Use template from `${CLAUDE_SKILL_DIR}/../../templates/mcp-server.json`.

### For LSP Server

Location: `.lsp.json` (project) or `~/.claude/lsp.json` (global)

Structure:
```json
{
  "server-name": {
    "command": "path/to/lsp-server",
    "args": ["--stdio"],
    "languages": ["typescript", "javascript"]
  }
}
```

Required: command, languages array
Optional: args, initializationOptions

Use template from `${CLAUDE_SKILL_DIR}/../../templates/lsp-server.json`.

### For Agent Team

Location: `~/.claude/teams/{team-name}/config.json`

Structure:
```json
{
  "name": "team-name",
  "description": "What the team does",
  "agents": [
    {
      "name": "agent-name",
      "role": "What this agent does",
      "tools": ["Read", "Grep", "Glob", "Bash"],
      "model": "inherit"
    }
  ]
}
```

Teams are orchestrated via natural language, not declarative config. The team config defines agents and their capabilities; coordination happens through Claude's reasoning.

**Warning**: Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. Agent Teams are experimental and may change.

Valid teammateMode (configured in settings.json as `teammateMode`): in-process, tmux, auto
Valid models: opus, sonnet, haiku, inherit

Use template from `${CLAUDE_SKILL_DIR}/../../templates/agent-team.json`.

---

## Step 5: Validate before AND after writing

### 5.1 Pre-write validation (automatic)

This skill has built-in PreToolUse/PostToolUse hooks that automatically validate JSON before Write and after Edit operations on config files (settings.json, .mcp.json, .lsp.json, etc.). If the JSON is malformed, the write is **blocked** and you will see the jq error — fix the JSON and retry.

### 5.2 Schema validation (manual)

Before creating any configuration file, verify against schemas:

1. **For hooks**: Verify event name is in the valid list
2. **For hooks**: Verify structure has nested `hooks` array with `type` and `command`
3. **For skills/subagents**: Verify required frontmatter fields
4. **For subagents**: Verify tools and model are valid
5. **For MCP servers**: Verify valid JSON, `mcpServers` key exists, each server has `type` and either `command` (stdio) or `url` (http/sse/ws)
6. **For LSP servers**: Verify valid JSON, each server has `command` and `languages` array
7. **For Agent Teams**: Verify valid JSON, `name`/`description`/`agents` exist, each agent has `name`

If validation fails, show the error and do NOT create the file.

### 5.3 Post-write confirmation (MANDATORY for JSON files)

**After writing ANY JSON config file, ALWAYS run:**
```bash
jq . <file-path> > /dev/null
```
If this fails, the file is broken. Read it back, fix the JSON, and rewrite.

**CRITICAL: A malformed JSON config file will silently break Claude Code — it won't start and gives no error. This is the single most important validation step.**

---

## Step 6: Verify COMPLETENESS

**BEFORE showing results to user, verify ALL planned components were created:**

1. Check your CREATION PLAN from Step 3
2. For each component:
   - [ ] File exists at the specified path
   - [ ] Content is valid (matches schema)
   - [ ] Registered in automations-registry.json

**If ANY component is missing or invalid:**
- DO NOT proceed to Step 7
- GO BACK and create/fix the missing component
- You have a maximum of **2 repair attempts** per component
- This is NON-NEGOTIABLE

### Rollback on failure

If any component fails validation and cannot be fixed after 2 attempts, **roll back ALL created components**:

1. **Delete created files** (hook scripts, skill directories, subagent files, team configs)
2. **Remove registry entries** from `~/.claude/automations-registry.json`
3. **Revert settings.json changes** (remove hook entries, permission rules, custom commands added in this session)
4. **Revert .mcp.json / .lsp.json changes** if applicable

After rollback, show the user exactly what was rolled back and why:
```
ROLLBACK — could not complete automation after 2 attempts:

Rolled back:
  - Deleted ~/.claude/scripts/check-semver.sh
  - Removed hook entry from ~/.claude/settings.json (PreToolUse → Bash)
  - Removed registry entry "semver-hook"

Reason: Hook script failed validation — invalid jq syntax on line 12

Please fix the issue and try again with /automate <description>.
```

**An incomplete automation is worse than no automation — always roll back rather than leave broken components.**

### Verification checklist for combinations:

**Hook + Skill:**
- [ ] Skill file exists and has valid frontmatter
- [ ] Hook script exists and is executable
- [ ] Hook is registered in settings.json with VALID event (PreToolUse, NOT PreCommit)
- [ ] Both are in automations-registry.json with `relatedHook`/`relatedSkill` links

**Skill + Subagent:**
- [ ] Skill file exists
- [ ] Subagent file exists with valid tools/model
- [ ] Both registered with links

**Permissions + CLAUDE.md:**
- [ ] Permission rule in settings.json
- [ ] Explanation in CLAUDE.md
- [ ] Both registered

**MCP Server + Skill:**
- [ ] MCP config in .mcp.json with valid server entry
- [ ] Skill file exists with valid frontmatter
- [ ] Both registered with links

**Agent Team + Skill:**
- [ ] Team config exists with valid agents
- [ ] Skill file exists
- [ ] Both registered with links

---

## Step 7: Test the automation

**MANDATORY: Test that the automation actually works before finishing.**

### For Hooks:
```bash
# Test the hook script by sending JSON via stdin (how hooks actually receive input)
echo '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | ~/.claude/scripts/your-hook.sh
echo $?  # Should be 0 (allow) or 2 (block)
```

If the test fails:
1. Fix the script
2. Re-test
3. DO NOT finish until the test passes

### For Skills:
- Verify the skill appears in `/skills` list
- If `disable-model-invocation: false`, verify Claude recognizes when to use it

### For Permissions:
- Verify the rule appears in settings
- Test with a matching command

---

## Step 8: Final report

Only after ALL verifications pass:

1. Show the CREATION PLAN with all boxes checked:
   ```
   CREATION COMPLETE:
   [x] Component 1: Hook - ~/.claude/scripts/check-semver.sh
   [x] Component 2: Skill - ~/.claude/skills/semver/SKILL.md
   ```

2. Show test results:
   ```
   TESTS PASSED:
   [x] Hook blocks when VERSION not staged (exit 2)
   [x] Hook allows when VERSION is staged (exit 0)
   [x] Skill registered and visible
   ```

3. Explain how to use the automation
4. Confirm all components are in the registry

**If you cannot complete all steps, explicitly tell the user what failed and why.**

---

## Important notes

### NEVER do these things:
- Create a hook with invalid event (PreCommit, PostCommit, PreBash, etc.)
- Promise "Hook + Skill" but only create the skill
- Remove a broken component instead of fixing it
- Skip testing and verification
- Finish with unchecked items in the CREATION PLAN
- Create Agent Team config without warning about experimental status

### ALWAYS do these things:
- Validate against schemas BEFORE creating
- Create ALL components of a combination
- Test each component works
- Register everything in automations-registry.json
- Link related components (relatedHook/relatedSkill)

### Technical notes:
- If the user uses `--dangerously-skip-permissions`, Permissions won't work. Suggest Hook as an alternative for blocks.
- CLAUDE.md instructions are advisory, not guaranteed. If certainty is needed, use Hook.
- Hooks are scripts, they don't have access to Claude's intelligence. For complex logic, combine Hook + Skill.
- Subagents consume extra tokens but preserve the main context.
- Valid hook events: SessionStart, SessionEnd, UserPromptSubmit, UserPromptExpansion, PreToolUse, PostToolUse, PostToolUseFailure, PostToolBatch, PermissionRequest, PermissionDenied, Notification, Stop, StopFailure, PreCompact, PostCompact, SubagentStart, SubagentStop, TeammateIdle, TaskCreated, TaskCompleted, ConfigChange, InstructionsLoaded, WorktreeCreate, WorktreeRemove, Elicitation, ElicitationResult, CwdChanged, FileChanged, Setup
- All automations are tracked in `~/.claude/automations-registry.json` for management with list/edit/delete/export/import.
- Agent Teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and are experimental. The feature may change or be removed.
- MCP tools appear as `mcp__<server>__<tool>` in Claude and can be matched in hooks using `"matcher": "mcp__servername__.*"`.
- LSP servers must be installed separately; the config only points to them. Claude Code does not install language servers.
- Background subagents cannot use MCP tools.
- Hook handler type `http` sends requests to a URL endpoint; use `headers` for auth with `$VAR` interpolation and `allowedEnvVars` to expose env vars.
