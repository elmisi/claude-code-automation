---
name: automate-edit
description: Edit an existing automation (name, description, behavior, scope)
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

# Edit Automation

Arguments: $ARGUMENTS

Read `${CLAUDE_SKILL_DIR}/../../docs/shared-context.md` for registry format, merge algorithm, and validation procedures.

## Step 1: Find Automation

Parse `$ARGUMENTS` for the automation name.

If no name given, read the registry and show the list, then ask which one to edit.

Read `~/.claude/automations-registry.json` and find the automation by name.

If not found, show error and list available automations.

## Step 2: Show Current State

Read the actual file from the path in the registry. Show its current content to the user.

## Step 3: Ask What to Change

Use AskUserQuestion to ask what to change:
- Name
- Description
- Behavior/content
- Scope (move from project to global or vice versa)

## Step 4: Validate Changes

Before applying changes, validate against schemas:
- Read the relevant schema from `${CLAUDE_SKILL_DIR}/../../schemas/`
- For hooks: verify event name, structure, exit codes
- For skills/subagents: verify frontmatter fields
- For JSON configs: verify structure

If validation fails, show the error and ask the user to adjust.

## Step 5: Apply Changes

Make the changes to the file. For scope changes:
- Move file to new location (global ↔ project)
- For hooks: update settings.json entry using merge algorithm (remove old, add new)

Validate any modified JSON files with `jq` after writing.

## Step 6: Update Registry

Update the registry entry with:
- New `modified` timestamp
- Any changed fields (name, description, scope, path)

## Step 7: Confirm

Show the diff of what changed and confirm success.
