---
name: automate-export
description: Export all automations to a portable JSON file
disable-model-invocation: true
---

# Export Automations

Arguments: $ARGUMENTS

Read `${CLAUDE_SKILL_DIR}/../../docs/shared-context.md` for registry format.

## Step 1: Determine Output File

Parse `$ARGUMENTS` for a file path. Default: `~/.claude/automations-export.json`

## Step 2: Read Registry

Read `~/.claude/automations-registry.json`. Handle both formats (array and object).

If empty/missing: report "No automations to export." and stop.

## Step 3: Bundle Content

For each automation, read its content from the path in the registry.

Create export file:

```json
{
  "exportVersion": "1.0",
  "exportDate": "YYYY-MM-DD",
  "source": "machine-name or user identifier",
  "automations": [
    {
      "name": "icon-prompt",
      "type": "skill",
      "scope": "global",
      "description": "...",
      "files": [
        {
          "relativePath": "SKILL.md",
          "content": "--- full file content ---"
        }
      ]
    }
  ]
}
```

## Step 4: Write and Confirm

1. Write the file
2. Validate with `jq . <file> > /dev/null`
3. Show summary: "Exported N automations to <file>"
4. Suggest: "You can import this on another machine with `/automate-import <file>`"
