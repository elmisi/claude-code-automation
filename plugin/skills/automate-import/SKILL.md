---
name: automate-import
description: Import automations from a JSON export file
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

# Import Automations

Arguments: $ARGUMENTS

Read `${CLAUDE_SKILL_DIR}/../../docs/shared-context.md` for registry format, merge algorithm, and file markers.

## Step 1: Read Import File

Parse `$ARGUMENTS` for the file path. If missing, show error: "Usage: `/automate-import <file>`"

Read the file and validate format (must have `exportVersion` and `automations` array).

## Step 2: Preview and Resolve Conflicts

For each automation in the import file:

1. Check if it already exists (by name) in `~/.claude/automations-registry.json`
2. If exists, use AskUserQuestion:
   - "Overwrite existing"
   - "Rename to \<name\>-imported"
   - "Skip this automation"
3. If not exists, show preview and ask confirmation

## Step 3: Create Files

For each automation to import:

1. Create the files in appropriate locations based on type and scope
2. Add `created-by: automate` markers (see shared-context.md for format)
3. For hooks/permissions/custom-commands: use the settings.json merge algorithm
4. Validate all JSON files with `jq` after writing

## Step 4: Register

Add each imported automation to `~/.claude/automations-registry.json`.

## Step 5: Summary

Show summary of imported automations:
```
Imported N automations:
  - skill-name (skill, global)
  - hook-name (hook, project)
Skipped: M
```
