# claude-code-automation

> Agent automation plugins for Claude Code, with shared Codex support for portable planning and discovery workflows.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/elmisi/claude-code-automation/actions/workflows/ci.yml/badge.svg)](https://github.com/elmisi/claude-code-automation/actions/workflows/ci.yml)

This repository contains four Claude Code plugins. `plan-cycle` and `refactor-discovery` are also packaged for Codex from shared source trees.

| Plugin | Claude Code | Codex | Description |
|--------|-------------|-------|-------------|
| **automate** | `/automate` | - | Expert advisor that helps you decide and create the right Claude Code automation (skills, hooks, subagents, permissions, etc.) |
| **plan-cycle** | `/plan-cycle` | `plan-cycle` skill | File-based planning with annotation cycles. Persistent markdown plans you can edit and refine iteratively |
| **takeaway** | `/takeaway` | - | Structured feedback extraction. Interviews the user, distills observations into portable principles for continuous improvement |
| **refactor-discovery** | `/refactor-discovery` | `refactor-discovery` skill | Research methodology for surfacing non-obvious structural smell leads before promoting refactor candidates |

---

## Claude Code Installation

```bash
# Add the marketplace (once)
/plugin marketplace add elmisi/claude-code-automation

# Install the plugin(s) you want
/plugin install automate
/plugin install plan-cycle
/plugin install takeaway
/plugin install refactor-discovery
```

Restart Claude Code after installation to activate.

## Codex Installation

This repository exposes a Codex marketplace at `.agents/plugins/marketplace.json`.

Add `elmisi/claude-code-automation` as a Codex marketplace, then install `plan-cycle` or `refactor-discovery`. Codex reads the plugins from:

```text
plugins/plan-cycle/.codex-plugin/plugin.json
plugins/refactor-discovery/.codex-plugin/plugin.json
```

The Claude Code and Codex manifests point to the same plugin skill directories, so workflow updates are shared by both tools.

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
# For automate: clean up all created automations first (optional but recommended)
/automate-cleanup

# Uninstall any plugin
/plugin uninstall <plugin-name>
```

Automations created by `/automate` continue to work independently after uninstallation. If you reinstall the plugin later, it will automatically detect and re-register existing automations.

---

## automate

> An expert advisor that helps you decide and create the right automation for your needs.

**Schemas updated: June 2026** — 30 hook events, 4 hook handler types, MCP/LSP Servers, Agent Teams, full model IDs.

### Why this plugin?

[Claude Code](https://claude.ai/code) offers multiple automation mechanisms: **skills**, **hooks**, **subagents**, **permissions**, **CLAUDE.md**, **custom commands**, **MCP servers**, **LSP servers**, and **agent teams**. Each serves a different purpose, but choosing the right one isn't always obvious.

**Common questions:**
- Should I use a hook or a skill?
- When do I need a subagent vs a regular skill?
- How do I enforce a rule that Claude MUST follow, not just "should" follow?
- What if I use `--dangerously-skip-permissions`?
- When should I set up an MCP server vs a hook?
- Do I need an agent team or just a subagent?

This plugin acts as an expert advisor. You describe what you want to automate, it interviews you to understand your exact needs, then creates the right files in the right places.

### Usage

```bash
/automate <your topic>
```

```bash
/automate semantic versioning on every commit
/automate block push without explicit approval
/automate TUI project conventions
/automate security review for all PRs
/automate API design guidelines
/automate integrate GitHub tools via MCP
/automate set up TypeScript language server
```

### See it in action

> `/automate run tests before every commit`

The plugin interviews you to understand exactly what you need:

**Q: When should this happen?**
&rarr; *Always, on every commit*

**Q: Must it be guaranteed, or just a guideline?**
&rarr; *Guaranteed — block the commit if tests fail*

**Q: Should Claude decide which tests to run?**
&rarr; *Yes, based on the changed files*

#### Decision: Hook + Skill

> *"A Skill alone won't work — Claude can skip skills. You need a **Hook** to guarantee tests run on every commit. But since Claude should intelligently pick which tests based on changed files, you also need a **Skill** for the logic. I'll create both."*

**Files created:**

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | Hook: blocks `git commit` unless tests pass |
| `~/.claude/skills/test-runner/SKILL.md` | Skill: analyzes changes, picks relevant tests |

Both files are validated against schemas and registered for easy management (`/automate-list`).

**The twist:** had you answered *"just a guideline"* instead, the plugin would create a single `CLAUDE.md` rule — no hooks, no skills. Same topic, different needs, completely different automation.

### How it works

1. **Auto-updates**: Fetches the latest Claude Code documentation to stay current with new features
2. **Interviews you**: Asks specific questions about timing, scope, and requirements
3. **Decides**: Uses a decision matrix to pick the right automation type
4. **Explains**: Tells you what it chose and why, with alternatives considered
5. **Creates**: Generates the necessary files in the correct locations
6. **Validates**: Checks all files against schemas before writing
7. **Verifies**: Ensures all components of a combination are complete
8. **Tests**: Shows you how to test and use your new automation

### Decision matrix

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

### Common combinations

- **Hook + Skill**: Guaranteed execution (hook) with complex logic (skill)
- **Permissions + CLAUDE.md**: Technical block + explanation of why
- **Skill + Subagent**: Workflow definition + isolated deep analysis
- **MCP Server + Skill**: External tool access + workflow orchestration
- **Agent Team + Skill**: Multi-agent orchestration + domain knowledge

### Managing automations

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

### Key insights

**Hooks vs Skills**
- **Hooks** are scripts that run automatically at specific events. They're deterministic and guaranteed.
- **Skills** are knowledge/workflows that Claude applies with intelligence. They're advisory.
- Use hooks when something MUST happen. Use skills when Claude needs to think.

**Permissions caveat** — If you use `--dangerously-skip-permissions`, permission rules won't work. The plugin will suggest using hooks as an alternative for guaranteed blocks.

**MCP Servers** — Expose external tools to Claude via the Model Context Protocol. Tools appear as `mcp__<server>__<tool>` and can be matched in hook matchers. Supports `stdio`, `http`, `sse`, and `ws` transports.

**LSP Servers** — Provide code intelligence features (diagnostics, hover, completions) via the Language Server Protocol. The language server binary must be installed separately.

**Agent Teams** (experimental) — Enable parallel multi-agent orchestration. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

**Subagents for clean context** — Run in isolated context windows. Use them for code review (unbiased, separate from the code that was just written), deep investigation (reads many files without polluting your main context), or specialized analysis (security, performance, etc.).

---

## plan-cycle

> File-based planning with annotation pipeline. Creates persistent markdown plans with composable analysis skills.

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
/plan-cycle <request>           → writes plan + ops companion file
/plan-cycle:plan-impact <plan>  → annotates codebase-level issues
/plan-cycle:plan-quality <plan> → annotates quality violations
"plan-cycle-annotate"           → adds only new > **NOTE**: lines
"plan-cycle-review"             → processes all annotations, updates plan
"plan-cycle-finalize"           → verifies the 11 writing rules, surfaces unresolved-items inventory
... repeat until approved ...
"approved"                      → plan is ready for execution (gated on inventory being surfaced)
```

> **v3.0.0 breaking change:** plan template restructured around the reviewer's actual attention surface. Every section is now labeled *(Reviewer surface)* or *(Executor surface)*. The old single `Open Questions` is split into two named top-level sections — `Interpretation Log` (interpretive choices on the request) and `Decisions I Need From You` (planner uncertainty) — both reviewer-surface. `plan-cycle-finalize` gained an `Unresolved Items Inventory` step that auto-lists every TODO / `assumed:` / `unverified:` and forces a per-item *resolve / proceed-knowingly* choice; approval cannot be signaled until this inventory has been surfaced. Existing plans keep working because their `.ops.md` companion is authoritative for that plan. See [CHANGELOG](CHANGELOG.md#plan-cycle-300---2026-05-24).
>
> **v2.0.0 breaking change** (prior): operation names changed from bare `annotate`/`review`/`finalize` to `plan-cycle-annotate`/`plan-cycle-review`/`plan-cycle-finalize`. **No aliases.** See [CHANGELOG](CHANGELOG.md#plan-cycle-200---2026-05-23) for the migration `sed` one-liner for existing `.ops.md` files.

### How it works

1. **Research** — Claude reads the relevant codebase deeply before writing anything
2. **Write plan** — A detailed markdown plan with context, approach, code snippets, edge cases, and a task breakdown. A companion ops file is written alongside with operational instructions.
3. **Analyze** — Run `/plan-cycle:plan-impact` and/or `/plan-cycle:plan-quality` to get automated annotations
4. **Review** — `plan-cycle-review` processes all `> **NOTE**:` annotations, integrates them into the plan, removes resolved ones
5. **Finalize** — `plan-cycle-finalize` verifies the 11 unified writing rules (Self-contained, Operative, Outcome-layer success, Numbers, Exit clauses, Explicit degradation, Verify, Enumerate universals, Mark unverifiable, Coherent, Robust). Rewrites sections directly where gaps are found, then surfaces an `Unresolved Items Inventory` (every TODO / `assumed:` / `unverified:`) for per-item *resolve / proceed-knowingly* choice.
6. **Approve** — Iterate until the plan is right; approval cannot be signaled until the inventory has been surfaced.

The ops companion file describes the three core operations so any coding agent can work with the plan — the plugin skills handle the analysis passes (impact and quality). Annotations support optional source-tags: `[impact]` from plan-impact, `[quality: <criterion>]` from plan-quality, none from user — `plan-cycle-review` processes all uniformly.

### Project-level quality criteria (opt-in)

To customize `plan-quality` for your project, create `<project-root>/code-quality.md` with your own `### N. Name` criteria (start by copying `${CLAUDE_SKILL_DIR}/code-quality.md` from the plugin). The skill **never** writes to your project root — if the file exists it uses it, otherwise it falls back to the plugin default with a reminder. Commit / gitignore the file as you prefer (it's yours).

The key insight: a markdown file is **shared mutable state** between you and any number of agents. You can think at your own pace, point at the exact spot where something is wrong, and write the correction right there.

Inspired by [Boris Tane's annotation cycle workflow](https://boristane.com/blog/how-i-use-claude-code/).

---

## takeaway

> Structured feedback extraction for continuous improvement. Interviews the user, distills observations into portable principles.

### Usage

```bash
/takeaway plan-cycle
/takeaway automate
/takeaway <any skill, tool, or workflow>
```

### How it works

1. **Identify** — Classifies the target (skill, tool, plugin, workflow) and its scope (universal or project-specific)
2. **Interview** — Extracts observations from the user with concrete examples
3. **Evidence file** — Writes `takeaway-<target>-evidence.md`, the session retrospective with project-specific detail
4. **Distillation** — Collapses patterns by root theme and strips project-specific vocabulary
5. **Lessons file** — Writes `takeaway-<target>-lessons.md`, tool-agnostic principles an improving agent can consume
6. **Iterate** — The user reviews and annotates both files until approved

The two-file split is deliberate: evidence is traceable and project-bound, lessons are portable across projects and tools.

---

## refactor-discovery

> Research methodology to surface non-obvious structural smell leads, preserve uncertainty, and promote only mature findings into refactor candidates.

### Usage

```bash
# Full project — discover all areas, investigate everything
/refactor-discovery

# Scoped — focus on a specific part, auto-extend to adjacent areas
/refactor-discovery src/services/payment
/refactor-discovery the UserService class
/refactor-discovery error handling in the checkout flow
```

### How it works

1. **Pin snapshot** — Anchors the entire pass to a commit SHA for reproducible evidence
2. **Discover areas** — Analyzes the project structure and identifies 3-8 investigation areas optimized for parallel execution. When given a specific target, resolves it and discovers adjacent areas (inbound/outbound imports, shared types, tests) that must be investigated to avoid blind spots.
3. **Area investigation** — Spawns one subagent per area when available, with a serial fallback for runtimes that do not support plugin agents. Each area runs the full cycle: enumerate files, read for intent, scan with structural lenses, capture commit-anchored evidence, and triage into smell leads, promoted candidates, research tasks, or leave-alone verdicts.
4. **Synthesis** — Reads all per-area notes, clusters leads, resolves layering conflicts, assigns stable IDs (`SL<N>` smell lead, `R<N>` refactor, `RT<N>` research task, `DI<N>` document-intent), and builds dependency edges.
5. **Discovery document** — Produces `docs/refactor-discovery/<date>/discovery.md` with executive summary, investigation leads, promoted candidates, research tasks, prioritized roadmap (Do next / Do later / Do not do now), lens coverage, and open questions.
6. **Self-checks** — Runs coherence gates before reporting: promoted candidates pass the why gate, leads state lens and promotion condition, temporal claims cite commit evidence, and dependency references resolve.

### Methodology

The investigation is governed by 9 prioritized principles (readability > essentiality > cognitive load > abstraction via naming > tell-don't-ask > fail fast > CQS > least surprise > comments for "why") plus eight discovery lenses: temporal coupling, change amplification, shotgun ceremony, semantic drift, asymmetric abstractions, hidden policy, test gravity, and negative space.

Smells do not need to become advice immediately. The plugin records them as `SL<N>` leads until the "why" gate is strong enough to promote them to `R<N>` refactor candidates, or until missing runtime/domain evidence makes them `RT<N>` research tasks.

The methodology reference (`docs/methodology.md` inside the plugin) defines the complete framework: principles, investigation discipline, scoring rules, cross-cutting signals, synthesis checks, anti-patterns to avoid, and output templates.

### Output structure

```
docs/refactor-discovery/
  registry.md                    # Index of all passes
  2026-05-07/
    discovery.md                 # The deliverable — leads, candidates, research tasks
    area-api.md                  # Per-area investigation note
    area-components.md
    area-services.md
    ...
```

---

## Testing

| Type | Command | Tests | Description |
|------|---------|-------|-------------|
| Structure | `./tests/scripts/run-tests.sh structure` | 175 | File structure, JSON validity, marketplace manifests, fixture validation, version sync, negative validation, JSON guard, plan-cycle plugin (STRUCT-PC-01..28) |
| Fixture | `./tests/scripts/run-tests.sh e2e` | 20 | Creates expected outputs in sandbox and validates their structure |
| Interactive | `./tests/scripts/run-tests.sh interactive` | 8 | Runs actual Claude commands to test the skill end-to-end (consumes tokens) — includes INTERACTIVE-PC-A/B/C for plan-cycle |

Structure and fixture tests are deterministic and run in CI. Interactive tests are qualitative smoke tests that verify skills produce reasonable output with a real Claude instance — local only.

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, architecture overview, and how to add new automation types.

## License

MIT
