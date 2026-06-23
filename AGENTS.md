# Repository Guidelines

## Project Structure & Module Organization

This repository packages Claude Code automation plugins, plus Codex support for `plan-cycle` and `refactor-discovery`. Core plugin assets live under `plugins/automate/`: `schemas/` are the source of truth, `templates/` provide starting files, `skills/` contains `SKILL.md` workflows, `scripts/` contains validators and helpers, and `docs/` holds reference material. Additional plugins live under `plugins/develop-cycle/`, `plugins/takeaway/`, `plugins/plan-cycle/`, and `plugins/refactor-discovery/`. Tests live in `tests/`, with fixtures in `tests/fixtures/` and runners in `tests/scripts/`.

## Build, Test, and Development Commands

There is no compile step. Install `bash` and `jq`, then use:

```bash
./tests/scripts/run-tests.sh structure
./tests/scripts/run-tests.sh e2e
./tests/scripts/run-tests.sh all
./tests/scripts/run-tests.sh full
./plugins/automate/scripts/validate-config.sh skill ./tests/fixtures/skill-auto.md
```

`structure` checks required files, JSON/frontmatter validity, manifests, version sync, and schema validation. `e2e` runs deterministic fixture tests. `all` runs free CI-equivalent tests. `full` also runs interactive Claude tests and requires an API key.

## Coding Style & Naming Conventions

Use Markdown for skills and docs, JSON for schemas/templates, and Bash for scripts. Keep Bash POSIX-friendly where practical, with `#!/bin/bash`, `set -e` when appropriate, quoted variables, and small validation functions such as `validate_hooks()`. Use lowercase hyphenated filenames for automation types, for example `custom-command.json`, `mcp-server.json`, and `agent-team.json`. When Claude Code capabilities change, update the schema first, then templates, validators, skills, docs, and fixtures.

## Testing Guidelines

Add or update fixtures in `tests/fixtures/` for new output shapes. Add structure assertions or fixture test functions in `tests/scripts/run-tests.sh`; document scenarios in `tests/TEST.md` when behavior changes. Validate new fixture types directly with `plugins/automate/scripts/validate-config.sh`. CI runs `structure`, `e2e`, and explicit fixture validation, so run `./tests/scripts/run-tests.sh all` before opening a PR.

## Commit & Pull Request Guidelines

Recent history uses concise subjects with conventional prefixes where useful, such as `feat:`, `fix(scope):`, and `chore:`; include release versions or issue references when relevant, for example `(2.10.1)` or `(closes #8)`. PRs should use `.github/PULL_REQUEST_TEMPLATE.md`, include a summary, select the change type, report test commands run, and update `CHANGELOG.md`. For releases, keep all version files in sync: `VERSION`, `CHANGELOG.md`, `plugins/automate/.claude-plugin/plugin.json`, and `.claude-plugin/marketplace.json`.

## Security & Configuration Tips

Interactive tests may consume Claude tokens and require credentials; do not commit API keys or generated local sandboxes. Keep user-specific generated automations out of the repository unless they are intentional fixtures or templates.
