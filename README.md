# claude-code-automation

> Claude Code plugins for automation and structured development workflows.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/elmisi/claude-code-automation/actions/workflows/ci.yml/badge.svg)](https://github.com/elmisi/claude-code-automation/actions/workflows/ci.yml)

This repository contains two plugins:

| Plugin | Command | Description |
|--------|---------|-------------|
| **automate** | `/automate` | Expert advisor that helps you decide and create the right Claude Code automation (skills, hooks, subagents, permissions, etc.) |
| **develop-cycle** | `/develop-cycle` | Structured development workflow with analysis, implementation, validation, and mandatory checkpoint before commit/push |
| **plan-cycle** | `/plan-cycle` | File-based planning with annotation cycles. Persistent markdown plans you can edit and refine iteratively |

---

## /automate plugin

> An expert advisor that helps you decide and create the right automation for your needs.

**Schemas updated: Mar 2026** — 25 hook events, MCP Servers, LSP Servers, Agent Teams, PowerShell tool, effort/paths/shell fields.

### Why this plugin?

[Claude Code](https://claude.ai/code) is Anthropic's AI coding agent for the terminal. It offers multiple automation mechanisms: **skills**, **hooks**, **subagents**, **permissions**, **CLAUDE.md**, **custom commands**, **MCP servers**, **LSP servers**, and **agent teams**. Each serves a different purpose, but choosing the right one isn't always obvious.

**Common questions:**
- Should I use a hook or a skill?
- When do I need a subagent vs a regular skill?
- How do I enforce a rule that Claude MUST follow, not just "should" follow?
- What if I use `--dangerously-skip-permissions`?
- When should I set up an MCP server vs a hook?
- Do I need an agent team or just a subagent?

This plugin acts as an expert advisor. You describe what you want to automate, it interviews you to understand your exact needs, then creates the right files in the right places.

## Installation

```bash
/plugin marketplace add elmisi/claude-code-automation
/plugin install automate
```

Then restart Claude Code to activate the plugin.

## Updating

Auto-update is **disabled by default** for third-party plugins. To enable automatic updates:

```
/plugin → Marketplaces tab → elmisi → Enable auto-update
```

Or update manually anytime:

```bash
/plugin marketplace update elmisi
/reload-plugins
```

## Uninstallation

```bash
# 1. Clean up all automations created by the plugin (optional but recommended)
/automate-cleanup

# 2. Uninstall the plugin
/plugin uninstall automate
```

If you skip the cleanup step, your automations (skills, hooks, subagents, etc.) will continue to work independently — they don't depend on the plugin at runtime. If you reinstall the plugin later, it will automatically detect and re-register existing automations.

## Usage

```bash
/automate <your topic>
```

### Examples

```bash
/automate semantic versioning on every commit
/automate block push without explicit approval
/automate TUI project conventions
/automate security review for all PRs
/automate API design guidelines
/automate integrate GitHub tools via MCP
/automate set up TypeScript language server
```

## See it in action

> `/automate run tests before every commit`

The plugin interviews you to understand exactly what you need:

**Q: When should this happen?**
&rarr; *Always, on every commit*

**Q: Must it be guaranteed, or just a guideline?**
&rarr; *Guaranteed — block the commit if tests fail*

**Q: Should Claude decide which tests to run?**
&rarr; *Yes, based on the changed files*

### Decision: Hook + Skill

> *"A Skill alone won't work — Claude can skip skills. You need a **Hook** to guarantee tests run on every commit. But since Claude should intelligently pick which tests based on changed files, you also need a **Skill** for the logic. I'll create both."*

**Files created:**

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | Hook: blocks `git commit` unless tests pass |
| `~/.claude/skills/test-runner/SKILL.md` | Skill: analyzes changes, picks relevant tests |

Both files are validated against schemas and registered for easy management (`/automate-list`).

**The twist:** had you answered *"just a guideline"* instead, the plugin would create a single `CLAUDE.md` rule — no hooks, no skills. Same topic, different needs, completely different automation.

---

## Managing Automations

All automations created by this plugin are tracked in a registry (`~/.claude/automations-registry.json`). Each management command is a separate skill for instant tab-completion and faster execution:

| Command | Description |
|---------|-------------|
| `/automate-list` | List all tracked automations with options to view, edit, delete, or export |
| `/automate-edit <name>` | Modify an existing automation (name, description, behavior, scope) |
| `/automate-delete <name>` | Remove an automation with confirmation |
| `/automate-export [file]` | Export all automations to a portable JSON file |
| `/automate-import <file>` | Import automations from another machine with conflict resolution |
| `/automate-verify` | Health-check all registered automations — detects missing files or hook entries and offers to repair them |
| `/automate-cleanup` | Pre-uninstall: remove all automations created by this plugin (with option to keep selected ones) |
| `/automate-help` | Show full command reference |

### Export/Import Example

```bash
# On machine A: export your automations
/automate-export ~/my-automations.json

# Copy the file to machine B, then import
/automate-import ~/my-automations.json
```

When importing, you'll be asked how to handle conflicts if an automation with the same name already exists.

## How it works

1. **Auto-updates**: Fetches the latest Claude Code documentation to stay current with new features
2. **Interviews you**: Asks specific questions about timing, scope, and requirements
3. **Decides**: Uses a decision matrix to pick the right automation type
4. **Explains**: Tells you what it chose and why, with alternatives considered
5. **Creates**: Generates the necessary files in the correct locations
6. **Validates**: Checks all files against schemas before writing
7. **Verifies**: Ensures all components of a combination are complete
8. **Tests**: Shows you how to test and use your new automation

## Decision Matrix

| Need | Solution |
|------|----------|
| Must happen EVERY time, no exceptions | Hook |
| Control what Claude can/cannot do | Permissions |
| Domain knowledge applied automatically | Skill |
| Complex workflow invoked manually | Skill (with `disable-model-invocation: true`) |
| Separate context for analysis/review | Subagent |
| Simple global rule | CLAUDE.md |
| Shortcut for frequent prompt | Custom Command |
| External tool/service integration | MCP Server |
| Code intelligence (diagnostics, hover) | LSP Server |
| Parallel multi-agent orchestration | Agent Team (experimental) |

## Common Combinations

- **Hook + Skill**: Guaranteed execution (hook) with complex logic (skill)
- **Permissions + CLAUDE.md**: Technical block + explanation of why
- **Skill + Subagent**: Workflow definition + isolated deep analysis
- **MCP Server + Skill**: External tool access + workflow orchestration
- **Agent Team + Skill**: Multi-agent orchestration + domain knowledge

## Key Insights

### Hooks vs Skills
- **Hooks** are scripts that run automatically at specific events. They're deterministic and guaranteed.
- **Skills** are knowledge/workflows that Claude applies with intelligence. They're advisory.
- Use hooks when something MUST happen. Use skills when Claude needs to think.

### Permissions Caveat
If you use `--dangerously-skip-permissions`, permission rules won't work. The plugin will suggest using hooks as an alternative for guaranteed blocks.

### MCP Servers
MCP servers expose external tools to Claude via the Model Context Protocol. Tools appear as `mcp__<server>__<tool>` and can be matched in hook matchers. Supports `stdio` (local processes) and `sse` (remote HTTP) transports.

### LSP Servers
LSP servers provide code intelligence features (diagnostics, hover, completions) via the Language Server Protocol. The language server binary must be installed separately.

### Agent Teams (Experimental)
Agent teams enable parallel multi-agent orchestration. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. The feature is experimental and may change.

### Subagents for Clean Context
Subagents run in isolated context windows. Use them for:
- Code review (unbiased, separate from the code that was just written)
- Deep investigation (reads many files without polluting your main context)
- Specialized analysis (security, performance, etc.)

## Testing

Tests are split into three categories:

| Type | Command | Tests | Description |
|------|---------|-------|-------------|
| Structure | `./tests/scripts/run-tests.sh structure` | 97 | File structure, JSON validity, fixture validation, version sync, negative validation, JSON guard |
| Fixture | `./tests/scripts/run-tests.sh e2e` | 20 | Creates expected outputs in sandbox and validates their structure |
| Interactive | `./tests/scripts/run-tests.sh interactive` | 5 | Runs actual Claude commands to test the skill end-to-end (consumes tokens) |

**Note**: Structure and fixture tests are deterministic and run in CI. Interactive tests are qualitative smoke tests that verify the skill produces reasonable output with a real Claude instance. They are not CI-grade deterministic tests.

## Roadmap

### Planned: Interactive decision tree (v3.0)

The current interview flow uses adaptive questions with category-based shortcuts. A future version will implement a full interactive decision tree with:
- Visual flowchart-style navigation
- Weighted scoring when multiple automation types partially match
- Side-by-side comparison of alternatives with pros/cons
- "Did you mean..." suggestions for ambiguous descriptions
- Learning from previous automations to suggest patterns

### Schema auto-update

A daily GitHub Action checks the official Claude Code documentation for changes and opens issues when schemas need updating. Contributors can then update schemas without manually diffing docs.

---

## /develop-cycle plugin

> A structured development workflow that guides Claude through analysis, implementation, validation, and a mandatory checkpoint before commit/push.

### Installation

```bash
/plugin marketplace add elmisi/claude-code-automation
/plugin install develop-cycle
```

### Usage

```bash
/develop-cycle add user authentication with JWT tokens
/develop-cycle fix the race condition in the payment queue
/develop-cycle refactor the API layer to use dependency injection
```

### How it works

The workflow has 6 phases:

1. **Analysis and Planning** — Understand the task, study the codebase, clarify ambiguities, propose an approach, define the plan
2. **Setup** — Create a working branch from the main branch
3. **Implementation** — Write code and tests following the approved plan
4. **Validation** — Run pre-commit/lint and tests. **Mandatory checkpoint**: Claude stops and waits for your explicit OK before committing
5. **Iteration** — If you request changes, Claude applies them and re-validates
6. **Finalization** — Commit, push, and update docs if needed (only after your approval)

The key feature is the **mandatory checkpoint** after validation passes. Claude will never commit or push autonomously — it always stops to show you the results and waits for your explicit approval.

Pre-commit commands, test commands, and the main branch name are read from your project's `CLAUDE.md` file, so the workflow adapts to any project.

---

## /plan-cycle plugin 

> File-based planning with annotation pipeline. Creates persistent markdown plans with composable analysis skills.

### Installation

```bash
/plugin marketplace add elmisi/claude-code-automation
/plugin install plan-cycle
```

### Commands

| Command | Description |
|---------|-------------|
| `/plan-cycle <request>` | Research codebase and write a detailed plan file |
| `/plan-cycle:plan-impact <plan-path>` | Codebase impact analysis — finds overlaps, obsolescence, broken conventions, ripple effects |
| `/plan-cycle:plan-quality <plan-path>` | Code quality review — checks plan against configurable quality criteria |

### Usage

```bash
/plan-cycle add cursor-based pagination to the list endpoint
/plan-cycle refactor the auth module to use JWT tokens
/plan-cycle migrate the database from MongoDB to PostgreSQL
```

### Pipeline workflow

```
/plan-cycle <request>          → writes plan + ops companion file
/plan-cycle:plan-impact <plan> → annotates codebase-level issues
/plan-cycle:plan-quality <plan> → annotates quality violations
"review the plan"              → processes all annotations, updates plan
... repeat until approved ...
"approved"                     → plan is ready
```

### How it works

1. **Research** — Claude reads the relevant codebase deeply before writing anything
2. **Write plan** — A detailed markdown plan with context, approach, code snippets, edge cases, and a task breakdown. A companion ops file is written alongside with operational instructions.
3. **Analyze** — Run `/plan-cycle:plan-impact` and/or `/plan-cycle:plan-quality` to get automated annotations
4. **Review** — Process all `> **NOTE**:` annotations, integrate them into the plan, remove resolved ones
5. **Approve** — Iterate until the plan is right, then approve it

The ops companion file describes all operations (annotate, review, impact analysis, quality check) so any coding agent can work with the plan without the plugin installed.

The key insight: a markdown file is **shared mutable state** between you and any number of agents. You can think at your own pace, point at the exact spot where something is wrong, and write the correction right there. This is fundamentally better than steering through chat messages.

Inspired by [Boris Tane's annotation cycle workflow](https://boristane.com/blog/how-i-use-claude-code/).

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, architecture overview, and how to add new automation types.

## License

MIT
