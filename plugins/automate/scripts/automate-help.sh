#!/bin/bash
#
# automate-help.sh — Print /automate command reference
#
# No AI involved — pure text output.

cat <<'EOF'
/automate — Expert advisor for Claude Code automations

Usage:
  /automate <description>        Create a new automation (interactive)

Management commands:
  /automate-list                 List all automations
  /automate-edit <name>          Edit an existing automation
  /automate-delete <name>        Delete an automation
  /automate-export [file]        Export automations to JSON file
  /automate-import <file>        Import automations from JSON file
  /automate-verify               Health-check all automations
  /automate-cleanup              Remove all automations (pre-uninstall)
  /automate-help                 Show this help

Automation types:
  hook              Deterministic, guaranteed execution on events
  skill             Domain knowledge / workflows (auto or manual)
  subagent          Isolated context for analysis / review
  permissions       Control what Claude can/cannot do
  claude-md         Advisory rules loaded every session
  custom-command    Shortcut for a frequent prompt
  mcp-server        External tool/service integration
  lsp-server        Code intelligence (diagnostics, hover)
  agent-team        Parallel multi-agent orchestration (experimental)

Examples:
  /automate run tests before every commit
  /automate block push without approval
  /automate integrate GitHub tools via MCP
EOF
