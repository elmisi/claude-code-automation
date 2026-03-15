---
name: automate-cleanup
description: Remove all automations created by /automate (pre-uninstall)
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

# Cleanup Automations

Read `${CLAUDE_SKILL_DIR}/../../docs/shared-context.md` for registry format, merge algorithm, file markers, and deletion procedures.

## Step 1: Find All Automations

1. Read `~/.claude/automations-registry.json`
2. If empty/missing, scan for `created-by: automate` markers (same logic as Registry Bootstrap in shared-context.md)
3. If no automations found at all:
   > "No automations found. Nothing to clean up. You can safely uninstall the plugin."

   Stop here.

## Step 2: Display

Show all found automations:
```
Automations that will be removed:

| # | Name            | Type   | Scope   | Path                                    |
|---|-----------------|--------|---------|-----------------------------------------|
| 1 | semver-hook     | hook   | global  | ~/.claude/settings.json (hook entry)    |
| 2 | semver          | skill  | global  | ~/.claude/skills/semver/SKILL.md        |
| 3 | code-reviewer   | agent  | project | .claude/agents/code-reviewer.md         |
```

## Step 3: Choose Action

Use AskUserQuestion:
```
What would you like to do?
- Remove ALL automations listed above
- Select which automations to keep
- Cancel (keep everything)
```

## Step 4: Execute Removal

**If "Remove ALL":**
For each automation, in reverse order of creation, follow the deletion procedure for its type (see shared-context.md "Deletion Procedures by Type").

**If "Select which to keep":**
Show a numbered list, ask which to KEEP (all others will be removed).
Remove only the ones NOT selected.

**If "Cancel":** Stop.

**IMPORTANT**: Every JSON file modification during cleanup MUST be validated with `jq` after writing. Use the merge algorithm — never write partial JSON.

## Step 5: Final Cleanup

After removal, delete `~/.claude/automations-registry.json`.

## Step 6: Summary

```
Cleanup complete:
- Removed: 3 automations (semver-hook, semver, code-reviewer)
- Kept: 0
- Registry: deleted

You can now safely uninstall the plugin with:
/plugin uninstall automate
```
