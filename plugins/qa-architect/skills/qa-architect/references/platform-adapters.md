# Platform adapters

The canonical workflow is this directory's `SKILL.md`. Keep generated QA
artifacts in the target repository, not in a platform-specific session store.

## Claude Code

The Claude plugin manifest exposes `skills/`; invoke `/qa-architect` after
installing the plugin from the Claude marketplace.

## Codex

The Codex plugin manifest exposes the same `skills/` directory. Install the
plugin from the Codex marketplace and invoke the `qa-architect` skill in a
target repository.

## OpenCode

OpenCode discovers project skills in `.opencode/skills/`, `.claude/skills/`, and
`.agents/skills/`, and global skills in their matching home directories. To use
this plugin checkout directly, expose the canonical skill with a symlink or a
copy, for example:

```bash
mkdir -p .agents/skills/qa-architect
ln -s ../../../plugins/qa-architect/skills/qa-architect/SKILL.md \
  .agents/skills/qa-architect/SKILL.md
```

For an installed copy outside the project, replace the source path with that
copy's canonical `SKILL.md`. OpenCode accepts `name` and `description` in the
frontmatter; platform-specific fields are intentionally absent.
