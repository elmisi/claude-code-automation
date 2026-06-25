# Shared Context for /automate-* Skills

This file contains shared procedures used by multiple `/automate-*` skills.
Skills reference this file with: `Read ${CLAUDE_SKILL_DIR}/../../docs/shared-context.md`

---

## Registry Bootstrap

If `~/.claude/automations-registry.json` does NOT exist, scan for existing automations created by this plugin (they have `created-by: automate` markers). This handles reinstallation after uninstall.

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

## Registry Format

The registry (`~/.claude/automations-registry.json`) supports two formats:
- **Array**: `[{name, type, scope, path, ...}, ...]`
- **Object**: `{"automations": [{name, type, scope, path, ...}, ...]}`

Always handle both when reading. When creating a new registry, use the array format.

### Registry Entry Fields

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

For combinations, entries include `relatedHook`/`relatedSkill` links.

---

## settings.json Merge Algorithm

NEVER overwrite settings.json. Always merge.

### Adding a hook:
1. Read entire `~/.claude/settings.json` (use `{}` if it doesn't exist)
2. Append new matcher object to `.hooks["EventName"][]`
   - If `.hooks` doesn't exist → set to `{}`
   - If `.hooks["EventName"]` doesn't exist → set to `[]`
   - Append, never replace
3. Write complete merged JSON back
4. Read back and confirm the entry is present

### Removing a hook:
1. Read entire settings.json
2. Remove ONLY the specific array element whose inner `hooks[].command` matches (or match via `_meta.createdBy: "automate"` + automation name)
3. If the event array becomes empty → remove the event key
4. If `.hooks` becomes empty → remove the `.hooks` key
5. Write back

**Never write a partial `hooks` object — always include all existing events.**

### Removing permissions:
1. Read settings.json
2. Remove specific allow/deny rules that were added
3. Write back

### Removing custom commands:
1. Read settings.json
2. Remove the specific command entry
3. Write back

---

## File Markers

All auto-created files include origin markers:

**For Skills/Subagents (markdown frontmatter):**
```yaml
---
name: skill-name
description: ...
created-by: automate
---
```

**For JSON configs (hooks, permissions, custom-commands, MCP, LSP, agent-team):**
```json
{
  "_meta": {
    "createdBy": "automate",
    "createdAt": "ISO-timestamp"
  }
}
```

---

## Schema Reference Paths

From any `/automate-*` skill, schemas are at:
```
${CLAUDE_SKILL_DIR}/../../schemas/hooks.json
${CLAUDE_SKILL_DIR}/../../schemas/skills.json
${CLAUDE_SKILL_DIR}/../../schemas/subagents.json
${CLAUDE_SKILL_DIR}/../../schemas/permissions.json
${CLAUDE_SKILL_DIR}/../../schemas/custom-commands.json
${CLAUDE_SKILL_DIR}/../../schemas/mcp-servers.json
${CLAUDE_SKILL_DIR}/../../schemas/lsp-servers.json
${CLAUDE_SKILL_DIR}/../../schemas/agent-teams.json
```

---

## Validation

After writing ANY JSON config file, ALWAYS run:
```bash
jq . <file-path> > /dev/null
```
If this fails, the file is broken. Read it back, fix the JSON, and rewrite.

**CRITICAL: A malformed JSON config file will silently break Claude Code — it won't start and gives no error.**

The external validation script is at:
```
${CLAUDE_SKILL_DIR}/../../scripts/validate-config.sh <type> <content>
```

---

## Deletion Procedures by Type

**hook**: Remove hook entry from settings.json (using merge algorithm), delete associated script files in `~/.claude/scripts/` that have `# created-by: automate` marker.

**skill**: Delete entire skill directory (`~/.claude/skills/<name>/` or `.claude/skills/<name>/`).

**subagent**: Delete agent file (`~/.claude/agents/<name>.md` or `.claude/agents/<name>.md`).

**permission**: Remove allow/deny rules from settings.json.

**custom-command**: Remove command entry from settings.json.

**claude-md**: Remove the section from CLAUDE.md (identified by `<!-- automate: name -->` markers or content matching).

**mcp-server**: Remove server entry from `.mcp.json` or `~/.claude.json`. If `mcpServers` becomes empty → remove the key.

**lsp-server**: Remove server entry from `.lsp.json` or `~/.claude/lsp.json`.

**agent-team**: Delete team directory (`~/.claude/teams/<name>/`).
