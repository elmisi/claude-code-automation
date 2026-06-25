---
name: automate-verify
description: Health-check all registered automations and offer repair
disable-model-invocation: true
---

# Verify Automations

Read `${CLAUDE_SKILL_DIR}/../../docs/shared-context.md` for registry and validation procedures.

## Step 1: Load Registry

1. Read `~/.claude/automations-registry.json`
2. If empty/missing: report "No automations registered." and stop.

Handle both registry formats (array and object with `automations` key).

## Step 2: Check Each Automation

For each automation in the registry, check:

- **hook**: (a) script file exists at registry `path`; (b) settings.json contains a matching entry under `.hooks` with `_meta.createdBy: "automate"`
- **skill/subagent/claude-md**: file exists at `path`
- **permission/custom-command**: settings.json contains the entry
- **mcp-server**: `.mcp.json` or `~/.claude.json` contains the server entry at `path`
- **lsp-server**: `.lsp.json` or `~/.claude/lsp.json` contains the entry
- **agent-team**: config file exists at `path`

## Step 3: Show Status Table

```
| Name        | Type  | Status    | Issue               |
|-------------|-------|-----------|---------------------|
| semver-hook | hook  | ✓ healthy |                     |
| semver      | skill | ✗ missing | File not found      |
```

## Step 4: Offer Repair

If any unhealthy → use AskUserQuestion: "Repair missing components?"

- If yes: for each missing component, attempt recreation:
  - For file-based types (skill, subagent, etc.): warn that content is lost and offer to recreate with the same name/description from registry metadata
  - For hooks: re-add to settings.json using the merge algorithm (see shared-context.md)
- Maximum **2 repair attempts** per component

## Step 5: Confirm

After repair, run verify again and confirm all healthy.
