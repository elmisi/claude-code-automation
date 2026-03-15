---
name: automate-delete
description: Delete an automation with confirmation
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

# Delete Automation

Arguments: $ARGUMENTS

Read `${CLAUDE_SKILL_DIR}/../../docs/shared-context.md` for registry format, merge algorithm, and deletion procedures.

## Step 1: Find Automation

Parse `$ARGUMENTS` for the automation name.

If no name given, read the registry and show the list, then ask which one to delete.

Read `~/.claude/automations-registry.json` and find the automation by name.

If not found, show error and list available automations.

## Step 2: Confirm

Show the automation details (name, type, scope, path, description).

Use AskUserQuestion with options:
- "Yes, delete it"
- "No, keep it"

If not confirmed, cancel and stop.

## Step 3: Delete

Based on the automation type, follow the deletion procedure from shared-context.md:

- **hook**: Remove from settings.json + delete script file
- **skill**: Delete entire skill directory
- **subagent**: Delete agent file
- **permission**: Remove rules from settings.json
- **custom-command**: Remove entry from settings.json
- **claude-md**: Remove section from CLAUDE.md
- **mcp-server**: Remove from .mcp.json or ~/.claude.json
- **lsp-server**: Remove from .lsp.json or ~/.claude/lsp.json
- **agent-team**: Delete team directory

Validate any modified JSON files with `jq` after writing.

## Step 4: Update Registry

Remove the entry from `~/.claude/automations-registry.json`.

If the automation had `relatedHook` or `relatedSkill` links, warn about orphaned related components.

## Step 5: Confirm

Show: "Deleted \<name\> (\<type\>, \<scope\>)."
