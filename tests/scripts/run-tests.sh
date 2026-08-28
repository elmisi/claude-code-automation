#!/bin/bash
# Main test runner for claude-code-automation
#
# Usage:
#   ./run-tests.sh              # Run all tests (structure + fixture)
#   ./run-tests.sh structure    # Run only structure tests (fast, no Claude)
#   ./run-tests.sh e2e          # Run only fixture tests (fast, no Claude)
#   ./run-tests.sh fixture      # Same as e2e
#   ./run-tests.sh interactive  # Run interactive tests (slow, uses Claude, costs tokens)
#   ./run-tests.sh full         # Run all tests including interactive
#   ./run-tests.sh TEST-01      # Run specific test

# Don't exit on error - we want to continue running tests
# set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load helpers
source "$SCRIPT_DIR/helpers.sh"

# Parse arguments
TEST_TYPE="${1:-all}"

log_section "claude-code-automation Test Suite"
log_info "Project root: $PROJECT_ROOT"
log_info "Test type: $TEST_TYPE"

# ============================================
# STRUCTURE TESTS (Fast, no Claude needed)
# ============================================
run_structure_tests() {
    log_section "Structure Tests"

    # Test: Plugin structure is valid
    log_info "Testing plugin structure..."

    # Check for marketplace.json (required for plugin marketplace)
    assert_file_exists "$PROJECT_ROOT/.claude-plugin/marketplace.json" \
        "STRUCT-01: marketplace.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/automate/.claude-plugin/plugin.json" \
        "STRUCT-02: plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "STRUCT-03: SKILL.md exists"

    assert_file_exists "$PROJECT_ROOT/.agents/plugins/marketplace.json" \
        "STRUCT-109: Codex marketplace.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/plan-cycle/.codex-plugin/plugin.json" \
        "STRUCT-110: plan-cycle Codex plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/plan-cycle/.claude-plugin/plugin.json" \
        "STRUCT-111: plan-cycle Claude plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/refactor-discovery/.codex-plugin/plugin.json" \
        "STRUCT-118: refactor-discovery Codex plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/refactor-discovery/.claude-plugin/plugin.json" \
        "STRUCT-119: refactor-discovery Claude plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/takeaway/.codex-plugin/plugin.json" \
        "STRUCT-126: takeaway Codex plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/qa-architect/.claude-plugin/plugin.json" \
        "STRUCT-QA-01: qa-architect Claude plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/qa-architect/.codex-plugin/plugin.json" \
        "STRUCT-QA-02: qa-architect Codex plugin.json exists"

    assert_file_exists "$PROJECT_ROOT/plugins/qa-architect/skills/qa-architect/SKILL.md" \
        "STRUCT-QA-03: qa-architect SKILL.md exists"

    assert_file_exists "$PROJECT_ROOT/.agents/skills/qa-architect/SKILL.md" \
        "STRUCT-QA-04: OpenCode-compatible qa-architect SKILL.md exists"

    # The skill link must expose the WHOLE skill directory, not just SKILL.md:
    # OpenCode (verified on 1.18.18) resolves a skill's relative references
    # against the link path without following it, so a link to the bare
    # SKILL.md leaves references/ and assets/ unreachable.
    assert_file_exists "$PROJECT_ROOT/.agents/skills/qa-architect/references/qa-contract-template.yaml" \
        "STRUCT-QA-15: qa-architect references/ reachable through the skill link"

    assert_file_exists "$PROJECT_ROOT/.agents/skills/qa-architect/assets/synthetic-markdown-editor-pilot.md" \
        "STRUCT-QA-16: qa-architect assets/ reachable through the skill link"

    # Test: JSON files are valid
    log_info "Testing JSON validity..."

    assert_valid_json "$PROJECT_ROOT/.claude-plugin/marketplace.json" \
        "STRUCT-04: marketplace.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/automate/.claude-plugin/plugin.json" \
        "STRUCT-05: plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/.agents/plugins/marketplace.json" \
        "STRUCT-112: Codex marketplace.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/plan-cycle/.codex-plugin/plugin.json" \
        "STRUCT-113: plan-cycle Codex plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/plan-cycle/.claude-plugin/plugin.json" \
        "STRUCT-114: plan-cycle Claude plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/refactor-discovery/.codex-plugin/plugin.json" \
        "STRUCT-120: refactor-discovery Codex plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/refactor-discovery/.claude-plugin/plugin.json" \
        "STRUCT-121: refactor-discovery Claude plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/takeaway/.codex-plugin/plugin.json" \
        "STRUCT-127: takeaway Codex plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/qa-architect/.claude-plugin/plugin.json" \
        "STRUCT-QA-05: qa-architect Claude plugin.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/qa-architect/.codex-plugin/plugin.json" \
        "STRUCT-QA-06: qa-architect Codex plugin.json is valid JSON"

    # Test: SKILL.md has valid frontmatter
    log_info "Testing SKILL.md frontmatter..."

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "STRUCT-06: SKILL.md has valid frontmatter"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/qa-architect/skills/qa-architect/SKILL.md" \
        "STRUCT-QA-07: qa-architect SKILL.md frontmatter is valid"

    # Test: Required fields in plugin.json
    log_info "Testing required fields..."

    assert_json_has_key "$PROJECT_ROOT/plugins/automate/.claude-plugin/plugin.json" \
        ".name" "STRUCT-07: plugin.json has name"

    assert_json_has_key "$PROJECT_ROOT/plugins/automate/.claude-plugin/plugin.json" \
        ".version" "STRUCT-08: plugin.json has version"

    assert_json_has_key "$PROJECT_ROOT/plugins/automate/.claude-plugin/plugin.json" \
        ".description" "STRUCT-09: plugin.json has description"

    # Test: SKILL.md contains required sections
    log_info "Testing SKILL.md content..."

    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "disable-model-invocation" "STRUCT-10: SKILL.md has disable-model-invocation"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "AskUserQuestion" "STRUCT-11: SKILL.md references AskUserQuestion"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        '\$ARGUMENTS' "STRUCT-12: SKILL.md uses \$ARGUMENTS"

    # Test: Decision matrix is present
    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "Hook.*Skill.*Subagent" "STRUCT-13: SKILL.md has decision matrix"

    # Test: All automation types are documented
    for type in "Hook" "Skill" "Subagent" "Permissions" "CLAUDE.md" "Custom"; do
        assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
            "$type" "STRUCT-14: SKILL.md documents $type"
    done

    # Test: New schema files exist
    log_info "Testing new schema files..."

    assert_file_exists "$PROJECT_ROOT/plugins/automate/schemas/mcp-servers.json" \
        "STRUCT-15: mcp-servers.json schema exists"

    assert_file_exists "$PROJECT_ROOT/plugins/automate/schemas/lsp-servers.json" \
        "STRUCT-16: lsp-servers.json schema exists"

    assert_file_exists "$PROJECT_ROOT/plugins/automate/schemas/agent-teams.json" \
        "STRUCT-17: agent-teams.json schema exists"

    # Test: New schema files are valid JSON
    log_info "Testing new schema JSON validity..."

    assert_valid_json "$PROJECT_ROOT/plugins/automate/schemas/mcp-servers.json" \
        "STRUCT-18: mcp-servers.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/automate/schemas/lsp-servers.json" \
        "STRUCT-19: lsp-servers.json is valid JSON"

    assert_valid_json "$PROJECT_ROOT/plugins/automate/schemas/agent-teams.json" \
        "STRUCT-20: agent-teams.json is valid JSON"

    # Test: SKILL.md documents new automation types
    log_info "Testing SKILL.md documents new types..."

    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "MCP Server" "STRUCT-21: SKILL.md documents MCP Server"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "LSP Server" "STRUCT-22: SKILL.md documents LSP Server"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "Agent Team" "STRUCT-23: SKILL.md documents Agent Team"

    # ============================================
    # FIXTURE VALIDATION (validate-config.sh)
    # ============================================
    log_info "Validating fixtures against schemas..."

    local VALIDATE="$PROJECT_ROOT/plugins/automate/scripts/validate-config.sh"
    chmod +x "$VALIDATE"

    assert_validation_passes "$VALIDATE" hooks \
        "$PROJECT_ROOT/tests/fixtures/hook-only.json" \
        "STRUCT-24: hook fixture passes validation"

    assert_validation_passes "$VALIDATE" skill \
        "$PROJECT_ROOT/tests/fixtures/skill-auto.md" \
        "STRUCT-25: skill-auto fixture passes validation"

    assert_validation_passes "$VALIDATE" skill \
        "$PROJECT_ROOT/tests/fixtures/skill-manual.md" \
        "STRUCT-26: skill-manual fixture passes validation"

    assert_validation_passes "$VALIDATE" subagent \
        "$PROJECT_ROOT/tests/fixtures/subagent.md" \
        "STRUCT-27: subagent fixture passes validation"

    assert_validation_passes "$VALIDATE" permissions \
        "$PROJECT_ROOT/tests/fixtures/permissions.json" \
        "STRUCT-28: permissions fixture passes validation"

    assert_validation_passes "$VALIDATE" custom-commands \
        "$PROJECT_ROOT/tests/fixtures/custom-command.json" \
        "STRUCT-29: custom-command fixture passes validation"

    assert_validation_passes "$VALIDATE" mcp-servers \
        "$PROJECT_ROOT/tests/fixtures/mcp-server.json" \
        "STRUCT-30: mcp-server fixture passes validation"

    assert_validation_passes "$VALIDATE" lsp-servers \
        "$PROJECT_ROOT/tests/fixtures/lsp-server.json" \
        "STRUCT-31: lsp-server fixture passes validation"

    assert_validation_passes "$VALIDATE" agent-team \
        "$PROJECT_ROOT/tests/fixtures/agent-team.json" \
        "STRUCT-32: agent-team fixture passes validation"

    # ============================================
    # VERSION SYNC
    # ============================================
    log_info "Testing version sync..."

    local ver_file=$(cat "$PROJECT_ROOT/VERSION" | tr -d '[:space:]')
    local ver_plugin=$(jq -r '.version' "$PROJECT_ROOT/plugins/automate/.claude-plugin/plugin.json")
    local ver_market=$(jq -r '.plugins[0].version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")

    if [ "$ver_file" == "$ver_plugin" ] && [ "$ver_file" == "$ver_market" ]; then
        log_success "STRUCT-33: version sync — all files show $ver_file"
    else
        log_fail "STRUCT-33: version mismatch — VERSION=$ver_file, plugin.json=$ver_plugin, marketplace.json=$ver_market"
    fi

    local plan_ver_claude=$(jq -r '.version' "$PROJECT_ROOT/plugins/plan-cycle/.claude-plugin/plugin.json")
    local plan_ver_codex=$(jq -r '.version' "$PROJECT_ROOT/plugins/plan-cycle/.codex-plugin/plugin.json")
    local plan_ver_market=$(jq -r '.plugins[] | select(.name == "plan-cycle") | .version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")
    local plan_codex_source=$(jq -r '.plugins[] | select(.name == "plan-cycle") | .source.path' "$PROJECT_ROOT/.agents/plugins/marketplace.json")
    local refactor_ver_claude=$(jq -r '.version' "$PROJECT_ROOT/plugins/refactor-discovery/.claude-plugin/plugin.json")
    local refactor_ver_codex=$(jq -r '.version' "$PROJECT_ROOT/plugins/refactor-discovery/.codex-plugin/plugin.json")
    local refactor_ver_market=$(jq -r '.plugins[] | select(.name == "refactor-discovery") | .version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")
    local refactor_codex_source=$(jq -r '.plugins[] | select(.name == "refactor-discovery") | .source.path' "$PROJECT_ROOT/.agents/plugins/marketplace.json")

    if [ "$plan_ver_claude" == "$plan_ver_codex" ] && [ "$plan_ver_claude" == "$plan_ver_market" ]; then
        log_success "STRUCT-115: plan-cycle version sync — all manifests show $plan_ver_claude"
    else
        log_fail "STRUCT-115: plan-cycle version mismatch — Claude=$plan_ver_claude, Codex=$plan_ver_codex, marketplace=$plan_ver_market"
    fi

    if [ "$plan_codex_source" == "./plugins/plan-cycle" ]; then
        log_success "STRUCT-116: Codex marketplace points to plugins/plan-cycle"
    else
        log_fail "STRUCT-116: Codex marketplace source mismatch — $plan_codex_source"
    fi

    assert_file_contains "$PROJECT_ROOT/plugins/plan-cycle/skills/plan-cycle/templates/plan-template.md" \
        "## Operations Guide" "STRUCT-117: plan template embeds the Operations Guide appendix"

    if [ "$refactor_ver_claude" == "$refactor_ver_codex" ] && [ "$refactor_ver_claude" == "$refactor_ver_market" ]; then
        log_success "STRUCT-122: refactor-discovery version sync — all manifests show $refactor_ver_claude"
    else
        log_fail "STRUCT-122: refactor-discovery version mismatch — Claude=$refactor_ver_claude, Codex=$refactor_ver_codex, marketplace=$refactor_ver_market"
    fi

    if [ "$refactor_codex_source" == "./plugins/refactor-discovery" ]; then
        log_success "STRUCT-123: Codex marketplace points to plugins/refactor-discovery"
    else
        log_fail "STRUCT-123: refactor-discovery Codex marketplace source mismatch — $refactor_codex_source"
    fi

    assert_file_contains "$PROJECT_ROOT/plugins/refactor-discovery/skills/refactor-discovery/SKILL.md" \
        "../../docs/methodology.md" "STRUCT-124: refactor-discovery uses portable methodology path"

    local takeaway_ver_claude=$(jq -r '.version' "$PROJECT_ROOT/plugins/takeaway/.claude-plugin/plugin.json")
    local takeaway_ver_codex=$(jq -r '.version' "$PROJECT_ROOT/plugins/takeaway/.codex-plugin/plugin.json")
    local takeaway_ver_market=$(jq -r '.plugins[] | select(.name == "takeaway") | .version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")
    local takeaway_codex_source=$(jq -r '.plugins[] | select(.name == "takeaway") | .source.path' "$PROJECT_ROOT/.agents/plugins/marketplace.json")
    local takeaway_codex_has_version=$(jq -r '.plugins[] | select(.name == "takeaway") | has("version")' "$PROJECT_ROOT/.agents/plugins/marketplace.json")
    local qa_ver_claude=$(jq -r '.version' "$PROJECT_ROOT/plugins/qa-architect/.claude-plugin/plugin.json")
    local qa_ver_codex=$(jq -r '.version' "$PROJECT_ROOT/plugins/qa-architect/.codex-plugin/plugin.json")
    local qa_ver_market=$(jq -r '.plugins[] | select(.name == "qa-architect") | .version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")
    local qa_codex_source=$(jq -r '.plugins[] | select(.name == "qa-architect") | .source.path' "$PROJECT_ROOT/.agents/plugins/marketplace.json")
    local qa_codex_has_version=$(jq -r '.plugins[] | select(.name == "qa-architect") | has("version")' "$PROJECT_ROOT/.agents/plugins/marketplace.json")

    if [ "$takeaway_ver_claude" == "$takeaway_ver_codex" ] && [ "$takeaway_ver_claude" == "$takeaway_ver_market" ]; then
        log_success "STRUCT-128: takeaway version sync — all manifests show $takeaway_ver_claude"
    else
        log_fail "STRUCT-128: takeaway version mismatch — Claude=$takeaway_ver_claude, Codex=$takeaway_ver_codex, marketplace=$takeaway_ver_market"
    fi

    if [ "$takeaway_codex_source" == "./plugins/takeaway" ]; then
        log_success "STRUCT-129: Codex marketplace points to plugins/takeaway"
    else
        log_fail "STRUCT-129: takeaway Codex marketplace source mismatch — $takeaway_codex_source"
    fi

    if [ "$takeaway_codex_has_version" == "false" ]; then
        log_success "STRUCT-130: Codex marketplace takeaway entry has no version field"
    else
        log_fail "STRUCT-130: Codex marketplace takeaway entry should not have a version field (got: $takeaway_codex_has_version)"
    fi

    if [ "$qa_ver_claude" == "$qa_ver_codex" ] && [ "$qa_ver_claude" == "$qa_ver_market" ]; then
        log_success "STRUCT-QA-08: qa-architect version sync — all manifests show $qa_ver_claude"
    else
        log_fail "STRUCT-QA-08: qa-architect version mismatch — Claude=$qa_ver_claude, Codex=$qa_ver_codex, marketplace=$qa_ver_market"
    fi

    if [ "$qa_codex_source" == "./plugins/qa-architect" ]; then
        log_success "STRUCT-QA-09: Codex marketplace points to plugins/qa-architect"
    else
        log_fail "STRUCT-QA-09: Codex marketplace source mismatch — $qa_codex_source"
    fi

    if [ "$qa_codex_has_version" == "false" ]; then
        log_success "STRUCT-QA-10: Codex marketplace qa-architect entry has no version field"
    else
        log_fail "STRUCT-QA-10: Codex marketplace qa-architect entry should not have a version field (got: $qa_codex_has_version)"
    fi

    assert_file_contains "$PROJECT_ROOT/plugins/qa-architect/skills/qa-architect/SKILL.md" \
        "Never enter QA Build" "STRUCT-QA-11: qa-architect keeps the contract approval gate"

    assert_file_contains "$PROJECT_ROOT/plugins/qa-architect/skills/qa-architect/SKILL.md" \
        "one high-information question at a time" "STRUCT-QA-12: qa-architect uses adaptive grilling"

    assert_file_contains "$PROJECT_ROOT/plugins/qa-architect/skills/qa-architect/references/mutation-catalog.md" \
        "Controlled mutation" "STRUCT-QA-13: qa-architect includes mutation guidance"

    assert_file_exists "$PROJECT_ROOT/tests/fixtures/qa-architect/markdown-editor-pilot.md" \
        "STRUCT-QA-14: qa-architect synthetic pilot fixture exists"

    # ============================================
    # NEGATIVE VALIDATION (invalid configs must fail)
    # ============================================
    log_info "Testing negative validation (invalid configs rejected)..."

    assert_validation_fails "$VALIDATE" hooks \
        '{"hooks":{"PreBash":[{"hooks":[{"type":"command","command":"echo test"}]}]}}' \
        "STRUCT-34: reject invalid hook event (PreBash)"

    assert_validation_fails "$VALIDATE" hooks \
        '{"hooks":{"PreToolUse":[{"command":"echo test"}]}}' \
        "STRUCT-35: reject hook missing nested hooks array"

    assert_validation_fails "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nmodel: gpt4\n---\nContent')" \
        "STRUCT-36: reject subagent with invalid model"

    assert_validation_fails "$VALIDATE" mcp-servers \
        '{"mcpServers":{"test":{"type":"websocket","command":"test"}}}' \
        "STRUCT-37: reject MCP server with invalid type"

    assert_validation_fails "$VALIDATE" lsp-servers \
        '{"typescript":{"command":"tsc"}}' \
        "STRUCT-38: reject LSP server missing languages"

    assert_validation_fails "$VALIDATE" agent-team \
        '{"name":"test","description":"test"}' \
        "STRUCT-39: reject agent team missing agents array"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"TeammateIdle":[{"hooks":[{"type":"command","command":"exit 2"}]}]}}' \
        "STRUCT-40: accept TeammateIdle hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"TaskCompleted":[{"hooks":[{"type":"command","command":"exit 2"}]}]}}' \
        "STRUCT-41: accept TaskCompleted hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"ConfigChange":[{"matcher":"user_settings","hooks":[{"type":"command","command":"echo changed"}]}]}}' \
        "STRUCT-42: accept ConfigChange hook event"

    # ============================================
    # NEW EVENT TESTS (v2.2+)
    # ============================================
    log_info "Testing new hook events..."

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"PostCompact":[{"hooks":[{"type":"command","command":"echo compacted"}]}]}}' \
        "STRUCT-43: accept PostCompact hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"InstructionsLoaded":[{"hooks":[{"type":"command","command":"echo loaded"}]}]}}' \
        "STRUCT-44: accept InstructionsLoaded hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"WorktreeCreate":[{"hooks":[{"type":"command","command":"echo /tmp/wt"}]}]}}' \
        "STRUCT-45: accept WorktreeCreate hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"WorktreeRemove":[{"hooks":[{"type":"command","command":"echo cleanup"}]}]}}' \
        "STRUCT-46: accept WorktreeRemove hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"Elicitation":[{"matcher":"myserver","hooks":[{"type":"command","command":"exit 0"}]}]}}' \
        "STRUCT-47: accept Elicitation hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"ElicitationResult":[{"hooks":[{"type":"command","command":"exit 0"}]}]}}' \
        "STRUCT-48: accept ElicitationResult hook event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"MessageDisplay":[{"hooks":[{"type":"command","command":"cat >> /tmp/messages.log"}]}]}}' \
        "STRUCT-125: accept MessageDisplay hook event"

    # ============================================
    # HTTP HOOK TYPE TESTS
    # ============================================
    log_info "Testing http hook type..."

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"http","url":"https://example.com/hook"}]}]}}' \
        "STRUCT-49: accept http hook type"

    assert_validation_fails "$VALIDATE" hooks \
        '{"hooks":{"PreToolUse":[{"hooks":[{"type":"http"}]}]}}' \
        "STRUCT-50: reject http hook missing url"

    # ============================================
    # NEW TOOL VALIDATION TESTS
    # ============================================
    log_info "Testing new subagent tools..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: Agent, Read, Glob\n---\nContent')" \
        "STRUCT-51: accept Agent tool in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: TaskCreate, TaskUpdate, ToolSearch\n---\nContent')" \
        "STRUCT-52: accept new task/search tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: CronCreate, CronList, CronDelete\n---\nContent')" \
        "STRUCT-53: accept Cron tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: EnterWorktree, ExitWorktree, EnterPlanMode\n---\nContent')" \
        "STRUCT-54: accept Worktree and PlanMode tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: LSP, ListMcpResourcesTool, ReadMcpResourceTool\n---\nContent')" \
        "STRUCT-55: accept LSP and MCP resource tools in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: Agent(worker, researcher), Read\n---\nContent')" \
        "STRUCT-56: accept Agent(type) syntax in subagent tools"

    # ============================================
    # NEW SUBAGENT FIELD VALIDATION TESTS
    # ============================================
    log_info "Testing new subagent frontmatter fields..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nbackground: true\n---\nContent')" \
        "STRUCT-57: accept background field in subagent"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nisolation: worktree\n---\nContent')" \
        "STRUCT-58: accept isolation: worktree in subagent"

    assert_validation_fails "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nisolation: docker\n---\nContent')" \
        "STRUCT-59: reject invalid isolation value"

    # ============================================
    # NEW MCP SERVER TYPE TESTS
    # ============================================
    log_info "Testing http MCP server type..."

    assert_validation_passes "$VALIDATE" mcp-servers \
        '{"mcpServers":{"remote":{"type":"http","url":"https://mcp.example.com/mcp"}}}' \
        "STRUCT-60: accept http MCP server type"

    assert_validation_fails "$VALIDATE" mcp-servers \
        '{"mcpServers":{"remote":{"type":"http"}}}' \
        "STRUCT-61: reject http MCP server missing url"

    # ============================================
    # SKILL VALIDATION TESTS
    # ============================================
    log_info "Testing new skill frontmatter fields..."

    assert_validation_passes "$VALIDATE" skill \
        "$(printf -- '---\nname: test\ndescription: test\nuser-invocable: false\n---\nContent')" \
        "STRUCT-62: accept user-invocable field in skill"

    assert_validation_fails "$VALIDATE" skill \
        "$(printf -- '---\nname: test\ndescription: test\nuser-invocable: maybe\n---\nContent')" \
        "STRUCT-63: reject invalid user-invocable value"

    # ============================================
    # SCHEMA CONTENT TESTS
    # ============================================
    log_info "Testing schema contents are up-to-date..."

    # Verify hooks schema has all 30 events
    local hook_events=$(jq '.validEvents | length' "$PROJECT_ROOT/plugins/automate/schemas/hooks.json")
    if [ "$hook_events" -eq 30 ]; then
        log_success "STRUCT-64: hooks schema has 30 events"
    else
        log_fail "STRUCT-64: hooks schema has $hook_events events (expected 30)"
    fi

    # Verify hooks schema has http type
    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/hooks.json" \
        '"http"' "STRUCT-65: hooks schema includes http type"

    # Verify subagent schema has Agent tool
    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"Agent"' "STRUCT-66: subagent schema includes Agent tool"

    # Verify subagent schema has new fields
    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"maxTurns"' "STRUCT-67: subagent schema has maxTurns field"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"isolation"' "STRUCT-68: subagent schema has isolation field"

    # Verify MCP schema has http type
    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/mcp-servers.json" \
        '"http"' "STRUCT-69: MCP schema includes http type"

    # Verify skills schema has new fields
    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/skills.json" \
        '"user-invocable"' "STRUCT-70: skills schema has user-invocable field"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/skills.json" \
        '"allowed-tools"' "STRUCT-71: skills schema has allowed-tools field"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/skills.json" \
        '"agent"' "STRUCT-72: skills schema has agent field"

    # ============================================
    # JSON GUARD SCRIPT TESTS
    # ============================================
    log_info "Testing JSON config guard script..."

    local GUARD="$PROJECT_ROOT/plugins/automate/scripts/guard-json-config.sh"
    chmod +x "$GUARD"

    # Test: valid JSON Write to settings.json → allow
    local result
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/.claude/settings.json","content":"{\"hooks\":{}}"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 0 ]; then
        log_success "STRUCT-73: guard allows valid JSON write to settings.json"
    else
        log_fail "STRUCT-73: guard should allow valid JSON write (got exit $guard_exit)"
    fi

    # Test: invalid JSON Write to settings.json → block
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/.claude/settings.json","content":"{\"hooks\":{},}"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 2 ]; then
        log_success "STRUCT-74: guard blocks invalid JSON write to settings.json"
    else
        log_fail "STRUCT-74: guard should block invalid JSON write (got exit $guard_exit)"
    fi

    # Test: any file Write that is NOT a config file → allow silently
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/random.json","content":"not json"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 0 ]; then
        log_success "STRUCT-75: guard ignores non-config files"
    else
        log_fail "STRUCT-75: guard should ignore non-config files (got exit $guard_exit)"
    fi

    # Test: invalid JSON Write to .mcp.json → block
    result=$(echo '{"hook_event_name":"PreToolUse","tool_input":{"file_path":"/tmp/project/.mcp.json","content":"{\"mcpServers\":{\"x\":{\"type\":\"stdio\"}},,}"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    if [ "$guard_exit" -eq 2 ]; then
        log_success "STRUCT-76: guard blocks invalid JSON write to .mcp.json"
    else
        log_fail "STRUCT-76: guard should block invalid .mcp.json write (got exit $guard_exit)"
    fi

    # Test: invalid JSON Edit on settings.json → catch
    mkdir -p /tmp/guard-test/.claude
    echo '{"broken":}' > /tmp/guard-test/.claude/settings.json
    result=$(echo '{"hook_event_name":"PostToolUse","tool_input":{"file_path":"/tmp/guard-test/.claude/settings.json"}}' | "$GUARD" 2>&1) && guard_exit=$? || guard_exit=$?
    rm -rf /tmp/guard-test
    if [ "$guard_exit" -eq 2 ]; then
        log_success "STRUCT-77: guard catches invalid JSON after edit on settings.json"
    else
        log_fail "STRUCT-77: guard should catch invalid JSON after edit (got exit $guard_exit)"
    fi

    # Test: SKILL.md has guard hooks in frontmatter
    assert_file_contains "$PROJECT_ROOT/plugins/automate/skills/automate/SKILL.md" \
        "guard-json-config.sh" "STRUCT-78: SKILL.md has JSON guard hooks"

    # ============================================
    # MANAGEMENT SKILL TESTS (automate-* skills)
    # ============================================
    log_info "Testing management skill structure..."

    # automate-help
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-help/SKILL.md" \
        "STRUCT-82: automate-help SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-help/SKILL.md" \
        "STRUCT-83: automate-help has valid frontmatter"

    # automate-list
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-list/SKILL.md" \
        "STRUCT-84: automate-list SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-list/SKILL.md" \
        "STRUCT-85: automate-list has valid frontmatter"

    # automate-verify
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-verify/SKILL.md" \
        "STRUCT-86: automate-verify SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-verify/SKILL.md" \
        "STRUCT-87: automate-verify has valid frontmatter"

    # automate-export
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-export/SKILL.md" \
        "STRUCT-88: automate-export SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-export/SKILL.md" \
        "STRUCT-89: automate-export has valid frontmatter"

    # automate-import
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-import/SKILL.md" \
        "STRUCT-90: automate-import SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-import/SKILL.md" \
        "STRUCT-91: automate-import has valid frontmatter"

    # automate-delete
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-delete/SKILL.md" \
        "STRUCT-92: automate-delete SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-delete/SKILL.md" \
        "STRUCT-93: automate-delete has valid frontmatter"

    # automate-edit
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-edit/SKILL.md" \
        "STRUCT-94: automate-edit SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-edit/SKILL.md" \
        "STRUCT-95: automate-edit has valid frontmatter"

    # automate-cleanup
    assert_file_exists "$PROJECT_ROOT/plugins/automate/skills/automate-cleanup/SKILL.md" \
        "STRUCT-96: automate-cleanup SKILL.md exists"

    assert_valid_frontmatter "$PROJECT_ROOT/plugins/automate/skills/automate-cleanup/SKILL.md" \
        "STRUCT-97: automate-cleanup has valid frontmatter"

    # ============================================
    # NEW EVENTS AND TOOLS TESTS (2026-04-04)
    # ============================================
    log_info "Testing new hook events and subagent tools..."

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"PermissionDenied":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo denied"}]}]}}' \
        "STRUCT-98: accept PermissionDenied hook event"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/hooks.json" \
        '"PermissionDenied"' "STRUCT-99: hooks schema includes PermissionDenied event"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: SendMessage, TeamCreate, TeamDelete\n---\nContent')" \
        "STRUCT-100: accept SendMessage, TeamCreate, TeamDelete tools in subagent"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"SendMessage"' "STRUCT-101: subagent schema includes SendMessage tool"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"TeamCreate"' "STRUCT-102: subagent schema includes TeamCreate tool"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"TeamDelete"' "STRUCT-103: subagent schema includes TeamDelete tool"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: Monitor\n---\nContent')" \
        "STRUCT-104: accept Monitor tool in subagent"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"Monitor"' "STRUCT-105: subagent schema includes Monitor tool"

    # ============================================
    # ARTIFACT AND WORKFLOW TOOLS TESTS (2026-06-27)
    # ============================================
    log_info "Testing Artifact and Workflow subagent tools..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: Artifact, Workflow\n---\nContent')" \
        "STRUCT-131: accept Artifact and Workflow tools in subagent"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"Artifact"' "STRUCT-132: subagent schema includes Artifact tool"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"Workflow"' "STRUCT-133: subagent schema includes Workflow tool"

    # ============================================
    # REPORTFINDINGS AND SENDUSERFILE TOOLS TESTS (2026-07-14)
    # ============================================
    log_info "Testing ReportFindings and SendUserFile subagent tools..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: ReportFindings, SendUserFile\n---\nContent')" \
        "STRUCT-134: accept ReportFindings and SendUserFile tools in subagent"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"ReportFindings"' "STRUCT-135: subagent schema includes ReportFindings tool"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"SendUserFile"' "STRUCT-136: subagent schema includes SendUserFile tool"

    # ============================================
    # LISTAGENTS TOOL / ENDCONVERSATION EXCLUSION (2026-08-13)
    # ============================================
    log_info "Testing ListAgents tool and EndConversation exclusion..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: ListAgents, SendMessage\n---\nContent')" \
        "STRUCT-137: accept ListAgents tool in subagent"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        '"ListAgents"' "STRUCT-138: subagent schema includes ListAgents tool"

    # EndConversation is in the tools reference but subagents never receive it,
    # so it must stay out of the subagent tools list (issue #23 false positive).
    assert_validation_fails "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\ntools: EndConversation\n---\nContent')" \
        "STRUCT-139: reject EndConversation as a subagent tool"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/subagents.json" \
        'endConversationToolExcluded' "STRUCT-140: subagent schema documents the EndConversation exclusion"

    # ============================================
    # SETUP EVENT TESTS (2026-05-01)
    # ============================================
    log_info "Testing Setup hook event..."

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"Setup":[{"matcher":"init","hooks":[{"type":"command","command":"npm install"}]}]}}' \
        "STRUCT-106: accept Setup hook event"

    assert_file_contains "$PROJECT_ROOT/plugins/automate/schemas/hooks.json" \
        '"Setup"' "STRUCT-107: hooks schema includes Setup event"

    assert_validation_passes "$VALIDATE" hooks \
        '{"hooks":{"Setup":[{"matcher":"maintenance","hooks":[{"type":"command","command":"cleanup.sh"}]}]}}' \
        "STRUCT-108: accept Setup hook with maintenance matcher"

    # ============================================
    # FULL MODEL ID TESTS
    # ============================================
    log_info "Testing full model ID validation..."

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nmodel: claude-sonnet-4-6\n---\nContent')" \
        "STRUCT-79: accept full model ID claude-sonnet-4-6"

    assert_validation_passes "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nmodel: claude-opus-4-6\n---\nContent')" \
        "STRUCT-80: accept full model ID claude-opus-4-6"

    assert_validation_fails "$VALIDATE" subagent \
        "$(printf -- '---\nname: test\ndescription: test\nmodel: gpt-4o\n---\nContent')" \
        "STRUCT-81: reject non-Claude model ID"

    # Run plan-cycle plugin tests as part of structure tier
    run_plan_cycle_tests
}

# ============================================
# plan-cycle PLUGIN TESTS (STRUCT-PC-01..28)
# ============================================
run_plan_cycle_tests() {
    log_section "plan-cycle Plugin Tests (STRUCT-PC-01..28)"

    local plugin_dir="$PROJECT_ROOT/plugins/plan-cycle"
    local skills_dir="$plugin_dir/skills"
    # Operations guide now lives as an appendix inside the plan template (was a
    # standalone ops-template.md companion before v4.0.0). Validate it there.
    local ops="$skills_dir/plan-cycle/templates/plan-template.md"

    # STRUCT-PC-01: Frontmatter of the 3 SKILL.md files is valid and has required fields
    for skill in plan-cycle plan-impact plan-quality; do
        assert_valid_frontmatter "$skills_dir/$skill/SKILL.md" \
            "STRUCT-PC-01: $skill SKILL.md frontmatter valid"
        assert_file_contains "$skills_dir/$skill/SKILL.md" "disable-model-invocation: true" \
            "STRUCT-PC-01b: $skill has disable-model-invocation: true"
    done

    # STRUCT-PC-02: argument-hint uses quoted "..." syntax in all 3 skills
    for skill in plan-cycle plan-impact plan-quality; do
        if grep -qE '^argument-hint:[[:space:]]+"[^"]+"[[:space:]]*$' "$skills_dir/$skill/SKILL.md"; then
            log_success "STRUCT-PC-02: $skill argument-hint uses quoted syntax"
        else
            log_fail "STRUCT-PC-02: $skill argument-hint not quoted"
        fi
    done

    # STRUCT-PC-03: ops-template.md has the 3 plan-cycle-* sections (no more, no less)
    assert_file_contains "$ops" "^## plan-cycle-annotate" "STRUCT-PC-03a: plan-cycle-annotate section present"
    assert_file_contains "$ops" "^## plan-cycle-review" "STRUCT-PC-03b: plan-cycle-review section present"
    assert_file_contains "$ops" "^## plan-cycle-finalize" "STRUCT-PC-03c: plan-cycle-finalize section present"
    local extra_pc_sections
    extra_pc_sections=$(grep -cE "^## plan-cycle-(annotate|review|finalize)$" "$ops")
    if [ "$extra_pc_sections" -eq 3 ]; then
        log_success "STRUCT-PC-03d: exactly 3 plan-cycle-* sections in plan template appendix"
    else
        log_fail "STRUCT-PC-03d: expected 3 plan-cycle-* sections, found $extra_pc_sections"
    fi

    # STRUCT-PC-04: Dispatch rule does NOT contain legacy labels as dispatch targets
    local dispatch_section
    dispatch_section=$(awk '/^## Operation Dispatch Rule/,/^## plan-cycle-annotate/' "$ops")
    if echo "$dispatch_section" | grep -qE '^- \*\*?(Annotate|Review|Finalize)\*\*?'; then
        log_fail "STRUCT-PC-04: dispatch rule contains legacy labels"
    else
        log_success "STRUCT-PC-04: dispatch rule has no legacy labels"
    fi

    # STRUCT-PC-05: Version sync across 3 plan-cycle version files
    local v_claude v_codex v_market
    v_claude=$(jq -r '.version' "$plugin_dir/.claude-plugin/plugin.json")
    v_codex=$(jq -r '.version' "$plugin_dir/.codex-plugin/plugin.json")
    v_market=$(jq -r '.plugins[] | select(.name=="plan-cycle") | .version' "$PROJECT_ROOT/.claude-plugin/marketplace.json")
    if [ "$v_claude" = "$v_codex" ] && [ "$v_codex" = "$v_market" ] && [ -n "$v_claude" ]; then
        log_success "STRUCT-PC-05: version sync across 3 files ($v_claude)"
    else
        log_fail "STRUCT-PC-05: version mismatch (claude=$v_claude codex=$v_codex market=$v_market)"
    fi
    # Negative: Codex marketplace entry has NO version field
    local codex_pc_has_version
    codex_pc_has_version=$(jq -r '.plugins[] | select(.name=="plan-cycle") | has("version")' "$PROJECT_ROOT/.agents/plugins/marketplace.json" 2>/dev/null || echo "missing")
    if [ "$codex_pc_has_version" = "false" ]; then
        log_success "STRUCT-PC-05b: Codex marketplace plan-cycle entry has no version field"
    else
        log_fail "STRUCT-PC-05b: Codex marketplace plan-cycle entry should not have version field (got: $codex_pc_has_version)"
    fi

    # STRUCT-PC-06: code-quality.md has at least 9 numbered criteria
    local crit_count
    crit_count=$(grep -cE "^### [0-9]+\." "$skills_dir/plan-quality/code-quality.md")
    if [ "$crit_count" -ge 9 ]; then
        log_success "STRUCT-PC-06: code-quality.md has $crit_count numbered criteria (>=9)"
    else
        log_fail "STRUCT-PC-06: code-quality.md has $crit_count criteria, expected >=9"
    fi

    # STRUCT-PC-07: plan-quality references <project-root>/code-quality.md (opt-in pattern)
    assert_file_contains "$skills_dir/plan-quality/SKILL.md" "<project-root>/code-quality.md" \
        "STRUCT-PC-07: plan-quality uses opt-in <project-root>/code-quality.md"

    # STRUCT-PC-08: plan-cycle references the plan-template + template file exists
    assert_file_contains "$skills_dir/plan-cycle/SKILL.md" "templates/plan-template.md" \
        "STRUCT-PC-08a: SKILL.md references templates/plan-template.md"
    assert_file_exists "$skills_dir/plan-cycle/templates/plan-template.md" \
        "STRUCT-PC-08b: templates/plan-template.md exists"

    # STRUCT-PC-09: ops-template documents the annotation format with the 3 tag forms
    assert_file_contains "$ops" "\[impact\]" "STRUCT-PC-09a: ops has [impact] tag"
    assert_file_contains "$ops" "\[quality:" "STRUCT-PC-09b: ops has [quality:...] tag"
    assert_file_contains "$ops" "^\*\*Format:" "STRUCT-PC-09c: ops has Format: line"

    # STRUCT-PC-10: plan-cycle/SKILL.md line target (<=90)
    local lines_skill
    lines_skill=$(wc -l < "$skills_dir/plan-cycle/SKILL.md")
    if [ "$lines_skill" -le 90 ]; then
        log_success "STRUCT-PC-10: plan-cycle/SKILL.md is $lines_skill lines (<=90)"
    else
        log_fail "STRUCT-PC-10: plan-cycle/SKILL.md is $lines_skill lines, exceeds 90"
    fi

    # STRUCT-PC-11: ops-template.md folded into the plan template (no separate companion file)
    if [ ! -f "$plugin_dir/ops-template.md" ]; then
        log_success "STRUCT-PC-11: ops-template.md removed (operations folded into plan template appendix)"
    else
        log_fail "STRUCT-PC-11: ops-template.md still exists — should be folded into the plan template appendix"
    fi

    # STRUCT-PC-12: plan-impact + plan-quality point at the appendix format, don't re-implement
    assert_file_contains "$skills_dir/plan-impact/SKILL.md" "Operations Guide appendix" \
        "STRUCT-PC-12a: plan-impact references Operations Guide appendix"
    assert_file_contains "$skills_dir/plan-quality/SKILL.md" "Operations Guide appendix" \
        "STRUCT-PC-12b: plan-quality references Operations Guide appendix"
    # Negative: should NOT contain the old "ONLY add" rule
    if grep -q "ONLY add" "$skills_dir/plan-impact/SKILL.md"; then
        log_fail "STRUCT-PC-12c: plan-impact still has 'ONLY add' rule"
    else
        log_success "STRUCT-PC-12c: plan-impact has no 'ONLY add' rule"
    fi
    if grep -q "ONLY add" "$skills_dir/plan-quality/SKILL.md"; then
        log_fail "STRUCT-PC-12d: plan-quality still has 'ONLY add' rule"
    else
        log_success "STRUCT-PC-12d: plan-quality has no 'ONLY add' rule"
    fi

    # STRUCT-PC-13: Migration sed one-liner on v1.6.1 fixture produces compliant headers
    local fixture="$PROJECT_ROOT/tests/fixtures/plan-cycle/ops-template-v1.6.1.md"
    if [ -f "$fixture" ]; then
        local tmpfile
        tmpfile=$(mktemp)
        cp "$fixture" "$tmpfile"
        sed -i.bak -E 's/^## Annotate/## plan-cycle-annotate/; s/^## Review.*/## plan-cycle-review/; s/^## Finalize/## plan-cycle-finalize/; s/Annotate safety check/plan-cycle-annotate safety check/' "$tmpfile"
        local has_all=true
        grep -q "^## plan-cycle-annotate$" "$tmpfile" || has_all=false
        grep -q "^## plan-cycle-review$" "$tmpfile" || has_all=false
        grep -q "^## plan-cycle-finalize$" "$tmpfile" || has_all=false
        if [ "$has_all" = "true" ]; then
            log_success "STRUCT-PC-13: migration sed produces all 3 plan-cycle-* headers"
        else
            log_fail "STRUCT-PC-13: migration sed did not produce expected headers"
        fi
        rm -f "$tmpfile" "$tmpfile.bak"
    else
        log_fail "STRUCT-PC-13: fixture missing at $fixture"
    fi

    # STRUCT-PC-14: argument-hint exact value in plan-impact and plan-quality
    assert_file_contains "$skills_dir/plan-impact/SKILL.md" 'argument-hint: "path/to/plan-file.md"' \
        "STRUCT-PC-14a: plan-impact argument-hint exact value"
    assert_file_contains "$skills_dir/plan-quality/SKILL.md" 'argument-hint: "path/to/plan-file.md"' \
        "STRUCT-PC-14b: plan-quality argument-hint exact value"

    # STRUCT-PC-15: plan-cycle/SKILL.md byte target (<=5000)
    local bytes_skill
    bytes_skill=$(wc -c < "$skills_dir/plan-cycle/SKILL.md")
    if [ "$bytes_skill" -le 5000 ]; then
        log_success "STRUCT-PC-15: plan-cycle/SKILL.md is $bytes_skill bytes (<=5000)"
    else
        log_fail "STRUCT-PC-15: plan-cycle/SKILL.md is $bytes_skill bytes, exceeds 5000"
    fi

    # STRUCT-PC-16: All 10 writing rules present in plan-cycle/SKILL.md
    local missing=()
    for rule in "Self-contained" "Operative" "Numbers" "Exit clauses" "Explicit degradation" "Verify" "Enumerate" "Mark unverifiable" "Coherent" "Robust"; do
        if ! grep -q "$rule" "$skills_dir/plan-cycle/SKILL.md"; then
            missing+=("$rule")
        fi
    done
    if [ ${#missing[@]} -eq 0 ]; then
        log_success "STRUCT-PC-16: all 10 writing rules present in plan-cycle/SKILL.md"
    else
        log_fail "STRUCT-PC-16: missing rules: ${missing[*]}"
    fi

    # STRUCT-PC-17: plan-cycle-finalize cites the same 10 rules (no drift)
    local finalize_section
    finalize_section=$(awk '/^## plan-cycle-finalize/,/^## General/' "$ops")
    local missing_finalize=()
    for rule in "Self-contained" "Operative" "Numbers" "Exit clauses" "Explicit degradation" "Verify" "Enumerate" "Mark" "Coherent" "Robust"; do
        if ! echo "$finalize_section" | grep -q "$rule"; then
            missing_finalize+=("$rule")
        fi
    done
    if [ ${#missing_finalize[@]} -eq 0 ]; then
        log_success "STRUCT-PC-17: plan-cycle-finalize cites all 10 rules"
    else
        log_fail "STRUCT-PC-17: finalize missing rules: ${missing_finalize[*]}"
    fi

    # STRUCT-PC-18: README plan-cycle section uses new names
    local readme_pc
    readme_pc=$(awk '/^## plan-cycle$/,/^## takeaway$/' "$PROJECT_ROOT/README.md")
    if echo "$readme_pc" | grep -q 'plan-cycle-annotate' && \
       echo "$readme_pc" | grep -q 'plan-cycle-review' && \
       echo "$readme_pc" | grep -q 'plan-cycle-finalize'; then
        log_success "STRUCT-PC-18: README plan-cycle section uses new operation names"
    else
        log_fail "STRUCT-PC-18: README plan-cycle section missing one or more new names"
    fi

    # STRUCT-PC-19: plan-quality documents the no-side-effect contract
    if grep -qiE "never.*creates|never.*scriv|does not.*(create|write)" "$skills_dir/plan-quality/SKILL.md"; then
        log_success "STRUCT-PC-19: plan-quality documents the no-side-effect contract"
    else
        log_fail "STRUCT-PC-19: plan-quality missing 'never creates/writes' assertion"
    fi

    # STRUCT-PC-20: template has top-level Interpretation Log reviewer-surface section
    local tmpl="$skills_dir/plan-cycle/templates/plan-template.md"
    if grep -qE "^## Interpretation Log \*\(Reviewer surface\)\*" "$tmpl"; then
        log_success "STRUCT-PC-20: template has Interpretation Log (Reviewer surface)"
    else
        log_fail "STRUCT-PC-20: template missing '## Interpretation Log *(Reviewer surface)*' section"
    fi

    # STRUCT-PC-21: template has top-level Decisions I Need From You reviewer-surface section
    if grep -qE "^## Decisions I Need From You \*\(Reviewer surface\)\*" "$tmpl"; then
        log_success "STRUCT-PC-21: template has Decisions I Need From You (Reviewer surface)"
    else
        log_fail "STRUCT-PC-21: template missing '## Decisions I Need From You *(Reviewer surface)*' section"
    fi

    # STRUCT-PC-22: template uses audience labels (at least 2 Reviewer, 2 Executor)
    local reviewer_count exec_count
    reviewer_count=$(grep -cE "^## .+\*\(Reviewer surface\)\*" "$tmpl")
    exec_count=$(grep -cE "^## .+\*\(Executor surface\)\*" "$tmpl")
    if [ "$reviewer_count" -ge 2 ] && [ "$exec_count" -ge 2 ]; then
        log_success "STRUCT-PC-22: template has audience labels (Reviewer=$reviewer_count, Executor=$exec_count)"
    else
        log_fail "STRUCT-PC-22: template needs >=2 Reviewer + >=2 Executor labels (got R=$reviewer_count E=$exec_count)"
    fi

    # STRUCT-PC-23: template no longer has the old single '## Open Questions' section (split into two)
    if grep -qE "^## Open Questions" "$tmpl"; then
        log_fail "STRUCT-PC-23: template still has '## Open Questions' — split into Interpretation Log + Decisions I Need From You"
    else
        log_success "STRUCT-PC-23: template no longer has '## Open Questions' (correctly split)"
    fi

    # STRUCT-PC-24: SKILL.md cites the new 'Outcome-layer success' writing rule (Lesson 6)
    if grep -q "Outcome-layer success" "$skills_dir/plan-cycle/SKILL.md"; then
        log_success "STRUCT-PC-24: SKILL.md has Outcome-layer success rule"
    else
        log_fail "STRUCT-PC-24: SKILL.md missing Outcome-layer success rule (Lesson 6)"
    fi

    # STRUCT-PC-25: SKILL.md has Approval gate referencing unresolved-items inventory (Lesson 4)
    if grep -qE "[Aa]pproval gate" "$skills_dir/plan-cycle/SKILL.md" && \
       grep -qE "unresolved.items.*inventory|inventory.*unresolved" "$skills_dir/plan-cycle/SKILL.md"; then
        log_success "STRUCT-PC-25: SKILL.md has Approval gate + unresolved-items inventory reference"
    else
        log_fail "STRUCT-PC-25: SKILL.md missing Approval gate or unresolved-items inventory reference"
    fi

    # STRUCT-PC-26: SKILL.md 'Verify before claim' extension covers tool persistence / config knobs (Lesson 5)
    if grep -qE "persist|persists" "$skills_dir/plan-cycle/SKILL.md" && \
       grep -qE "config knob|controls behaviour|controls behavior" "$skills_dir/plan-cycle/SKILL.md"; then
        log_success "STRUCT-PC-26: SKILL.md Verify rule covers tool persistence + config knobs"
    else
        log_fail "STRUCT-PC-26: SKILL.md Verify rule missing tool persistence / config knob extension"
    fi

    # STRUCT-PC-27: ops plan-cycle-finalize has the Unresolved Items Inventory step
    local finalize_block
    finalize_block=$(awk '/^## plan-cycle-finalize/,/^## General/' "$ops")
    if echo "$finalize_block" | grep -q "Unresolved Items Inventory"; then
        log_success "STRUCT-PC-27: plan-cycle-finalize has Unresolved Items Inventory step"
    else
        log_fail "STRUCT-PC-27: plan-cycle-finalize missing Unresolved Items Inventory step"
    fi

    # STRUCT-PC-28: ops finalize cites the 11th rule (Outcome-layer success) for parity with SKILL.md
    if echo "$finalize_block" | grep -q "Outcome-layer success"; then
        log_success "STRUCT-PC-28: plan-cycle-finalize cites Outcome-layer success (11-rule parity)"
    else
        log_fail "STRUCT-PC-28: plan-cycle-finalize missing Outcome-layer success rule"
    fi

    # STRUCT-PC-29: appendix defines the Grilling discipline with both renditions
    if grep -qE "^## Grilling discipline" "$tmpl" && \
       grep -q "Interactive rendition" "$tmpl" && \
       grep -q "Document rendition" "$tmpl"; then
        log_success "STRUCT-PC-29: plan template appendix has the Grilling discipline with both renditions"
    else
        log_fail "STRUCT-PC-29: plan template appendix missing '## Grilling discipline' section or one of its two renditions"
    fi

    # STRUCT-PC-30: review (if-unclear) and finalize (inventory) both route through the Grilling discipline
    local review_block_g
    review_block_g=$(awk '/^## plan-cycle-review/,/^## plan-cycle-finalize/' "$tmpl")
    if echo "$review_block_g" | grep -q "Grilling discipline" && echo "$finalize_block" | grep -q "Grilling discipline"; then
        log_success "STRUCT-PC-30: plan-cycle-review and plan-cycle-finalize reference the Grilling discipline"
    else
        log_fail "STRUCT-PC-30: review/finalize do not both reference the Grilling discipline"
    fi

    # STRUCT-PC-31: the transposition rule lives in docs/ + CLAUDE.md, and NOT in the template.
    # SKILL.md copies the template's appendix verbatim into every produced plan, in any repo,
    # where a docs/plan-cycle/ reference is a dead path and maintainer notes are noise.
    local decisions_doc="$PROJECT_ROOT/docs/plan-cycle/decisions.md"
    if [ -f "$decisions_doc" ] && \
       grep -q "Permanent rules" "$decisions_doc" && \
       grep -qi "transposition" "$decisions_doc" && \
       grep -q "docs/plan-cycle/decisions.md" "$PROJECT_ROOT/CLAUDE.md" && \
       grep -qi "transposition rule" "$PROJECT_ROOT/CLAUDE.md" && \
       ! grep -qE '(^|[^[:alnum:]_/-])(docs|plugins|tests|scripts)/' "$tmpl" && \
       ! grep -q "CLAUDE.md" "$tmpl"; then
        log_success "STRUCT-PC-31: transposition rule recorded in docs/ + CLAUDE.md; shipped template references no repo-internal path"
    else
        log_fail "STRUCT-PC-31: transposition rule missing from docs//CLAUDE.md, or the shipped template references a repo-internal path (docs/, plugins/, tests/, scripts/, CLAUDE.md) that is a dead link for end users"
    fi

    # STRUCT-PC-32: the Decision question format declares all five mandatory fields.
    # Scoped to the Decision question sub-block: 'Recommendation' also appears in the
    # Unresolved item format, so a whole-block grep would not catch its removal here.
    local qfields=("Context" "Why it matters" "Options" "Trade-offs" "Recommendation")
    local missing_q=""
    local disc_block dq_block
    disc_block=$(awk '/^## Grilling discipline/,/^## plan-cycle-annotate/' "$tmpl")
    dq_block=$(echo "$disc_block" | awk '/^\*\*Decision question\*\*/,/^\*\*Unresolved item\*\*/')
    local f
    for f in "${qfields[@]}"; do
        echo "$dq_block" | grep -q "$f" || missing_q="$missing_q $f"
    done
    if [ -n "$dq_block" ] && [ -z "$missing_q" ]; then
        log_success "STRUCT-PC-32: Decision question format declares all five fields"
    else
        log_fail "STRUCT-PC-32: Decision question format missing field(s):$missing_q"
    fi

    # STRUCT-PC-33: the Unresolved item format is distinct, and the inventory uses the document rendition
    if echo "$disc_block" | grep -q "Unresolved item" && \
       echo "$disc_block" | grep -q "What is unresolved" && \
       echo "$disc_block" | grep -q "Why it cannot be settled now" && \
       echo "$disc_block" | grep -q "Consequence of proceeding as-is" && \
       echo "$finalize_block" | grep -qE "one single list|single list in one pass" && \
       echo "$finalize_block" | grep -q "Unresolved item"; then
        log_success "STRUCT-PC-33: Unresolved item format is distinct and used as one list by the finalize inventory"
    else
        log_fail "STRUCT-PC-33: Unresolved item format missing, or finalize inventory not presented as a single list"
    fi

    # STRUCT-PC-34: the discipline declares the two reviewer sections as the first wave
    if echo "$disc_block" | grep -q "First wave" && \
       echo "$disc_block" | grep -q "Interpretation Log" && \
       echo "$disc_block" | grep -q "Decisions I Need From You" && \
       grep -q "first wave" "$skills_dir/plan-cycle/SKILL.md"; then
        log_success "STRUCT-PC-34: first wave declared in the appendix and in SKILL.md"
    else
        log_fail "STRUCT-PC-34: first-wave parentage not declared in the appendix or in SKILL.md"
    fi

    # STRUCT-PC-35: the Humanized context rule exists and is scoped to where the document asks
    if echo "$disc_block" | grep -q "Humanized context" && \
       echo "$disc_block" | grep -qE "asks instead of describing" && \
       grep -q "Humanized context" "$skills_dir/plan-cycle/SKILL.md"; then
        log_success "STRUCT-PC-35: Humanized context rule present and scoped to asking sections"
    else
        log_fail "STRUCT-PC-35: Humanized context rule missing or not scoped to asking sections"
    fi

    # STRUCT-PC-36: plan-cycle-annotate states its purpose and lists the annotation intents
    local annotate_block
    annotate_block=$(awk '/^## plan-cycle-annotate/,/^## plan-cycle-review/' "$tmpl")
    if echo "$annotate_block" | grep -q "\*\*Purpose\.\*\*" && \
       echo "$annotate_block" | grep -q "What to annotate" && \
       echo "$annotate_block" | grep -q "Factual error" && \
       echo "$annotate_block" | grep -q "Assumption sold as certainty" && \
       echo "$annotate_block" | grep -q "Unclear question" && \
       echo "$annotate_block" | grep -q "Improvement proposal" && \
       echo "$annotate_block" | grep -q "no new tags"; then
        log_success "STRUCT-PC-36: plan-cycle-annotate states purpose + intent checklist, without new tags"
    else
        log_fail "STRUCT-PC-36: plan-cycle-annotate missing purpose statement, intent checklist, or the no-new-tags guarantee"
    fi

    # STRUCT-PC-37: parity — both reviewer question sections use the discipline's five field names
    local interp_block dec_block missing_parity=""
    interp_block=$(awk '/^## Interpretation Log/,/^## Approach/' "$tmpl")
    dec_block=$(awk '/^## Decisions I Need From You/,/^## Detailed Changes/' "$tmpl")
    for f in "${qfields[@]}"; do
        echo "$interp_block" | grep -q "$f" || missing_parity="$missing_parity Interpretation-Log:$f"
        echo "$dec_block" | grep -q "$f" || missing_parity="$missing_parity Decisions:$f"
    done
    if [ -z "$missing_parity" ]; then
        log_success "STRUCT-PC-37: reviewer question sections match the Decision question field list (parity)"
    else
        log_fail "STRUCT-PC-37: field-list parity broken —$missing_parity"
    fi

    # STRUCT-PC-38: the deferral is declared, templated, ASKED by review, and swept by finalize.
    # The review step is the load-bearing one: without it a deferred question is never posed
    # and only resurfaces in the closing inventory, turning deferral into postponement.
    local review_block_w
    review_block_w=$(awk '/^## plan-cycle-review/,/^## plan-cycle-finalize/' "$tmpl")
    if echo "$disc_block" | grep -q "Dependencies inside the first wave" && \
       echo "$disc_block" | grep -q "Waiting on:" && \
       echo "$dec_block" | grep -q "Waiting on:" && \
       echo "$review_block_w" | grep -q "Waiting on:" && \
       echo "$finalize_block" | grep -q "Waiting on:"; then
        log_success "STRUCT-PC-38: deferral declared, templated, asked by plan-cycle-review, swept by the finalize inventory"
    else
        log_fail "STRUCT-PC-38: deferral chain broken — missing from the discipline, the Decisions section, plan-cycle-review, or the finalize inventory"
    fi

    # STRUCT-PC-39: a deferred entry still carries plain-language Context (Humanized context binds).
    # Scoped to the deferred entry itself, so deleting its Context line fails the check.
    local deferred_entry
    deferred_entry=$(echo "$dec_block" | awk '/Waiting on:/{print prev; print} {prev=$0}')
    if echo "$deferred_entry" | grep -q "\*\*Context:\*\*" && \
       echo "$deferred_entry" | grep -q "\*\*Waiting on:\*\*" && \
       echo "$dec_block" | grep -q "deferred" && \
       echo "$disc_block" | grep -q "bare cross-reference is not enough"; then
        log_success "STRUCT-PC-39: deferred entries carry a plain-language Context, not a bare pointer"
    else
        log_fail "STRUCT-PC-39: deferred entry shape allows a bare cross-reference — Humanized context rule not carved out"
    fi
}

# ============================================
# FIXTURE TESTS (no Claude needed)
# ============================================
run_fixture_tests() {
    log_section "Fixture Tests"

    # Setup
    setup_sandbox
    backup_global_config

    # Trap to ensure cleanup on exit
    trap restore_global_config EXIT

    # Run individual fixture tests
    run_fixture_test_01
    run_fixture_test_02
    run_fixture_test_03
    run_fixture_test_04
    run_fixture_test_05
    run_fixture_test_06

    # Cleanup
    cleanup_sandbox
    restore_global_config
    trap - EXIT
}

# Fixture TEST-01: Hook creation
run_fixture_test_01() {
    log_info "Fixture TEST-01: Hook creation"

    local settings_file="$SANDBOX_DIR/.claude/settings.json"

    # Create expected output for verification
    mkdir -p "$SANDBOX_DIR/.claude"
    cat > "$settings_file" << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if cat | jq -r '.tool_input.command' | grep -q 'git push'; then echo 'Push blocked' >&2; exit 2; fi"
          }
        ]
      }
    ]
  }
}
EOF

    # Verify structure
    assert_valid_json "$settings_file" "FIX-01a: settings.json is valid"
    assert_json_has_key "$settings_file" ".hooks" "FIX-01b: has hooks key"
    assert_json_has_key "$settings_file" ".hooks.PreToolUse" "FIX-01c: has PreToolUse hook"
}

# Fixture TEST-02: Skill creation
run_fixture_test_02() {
    log_info "Fixture TEST-02: Skill creation"

    local skill_dir="$SANDBOX_DIR/.claude/skills/api-conventions"
    local skill_file="$skill_dir/SKILL.md"

    # Create expected output
    mkdir -p "$skill_dir"
    cat > "$skill_file" << 'EOF'
---
name: api-conventions
description: REST API naming conventions
disable-model-invocation: false
---

# API Conventions

Apply these conventions when working with API code:

- Use kebab-case for URL paths
- Use camelCase for JSON properties
- Always include pagination for list endpoints
EOF

    # Verify structure
    assert_file_exists "$skill_file" "FIX-02a: SKILL.md created"
    assert_valid_frontmatter "$skill_file" "FIX-02b: valid frontmatter"
    assert_file_contains "$skill_file" "disable-model-invocation: false" "FIX-02c: auto-invocation enabled"
}

# Fixture TEST-03: Subagent creation
run_fixture_test_03() {
    log_info "Fixture TEST-03: Subagent creation"

    local agent_file="$SANDBOX_DIR/.claude/agents/code-reviewer.md"

    # Create expected output
    mkdir -p "$SANDBOX_DIR/.claude/agents"
    cat > "$agent_file" << 'EOF'
---
name: code-reviewer
description: Independent code review with clean context
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are an independent code reviewer. Review code for:
- Logic errors
- Security issues
- Performance problems
- Code style violations

Provide specific line references and suggested fixes.
EOF

    # Verify structure
    assert_file_exists "$agent_file" "FIX-03a: agent file created"
    assert_valid_frontmatter "$agent_file" "FIX-03b: valid frontmatter"
    assert_file_contains "$agent_file" "tools:" "FIX-03c: has tools definition"
    assert_file_contains "$agent_file" "model:" "FIX-03d: has model definition"
}

# Fixture TEST-04: MCP server creation
run_fixture_test_04() {
    log_info "Fixture TEST-04: MCP server creation"

    local mcp_file="$SANDBOX_DIR/.mcp.json"

    # Create expected output
    cat > "$mcp_file" << 'EOF'
{
  "mcpServers": {
    "my-tools": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@my-org/my-mcp-server"],
      "env": {
        "API_KEY": "test-key"
      }
    }
  }
}
EOF

    # Verify structure
    assert_valid_json "$mcp_file" "FIX-04a: .mcp.json is valid JSON"
    assert_json_has_key "$mcp_file" ".mcpServers" "FIX-04b: has mcpServers key"
    assert_json_has_key "$mcp_file" '.mcpServers."my-tools".type' "FIX-04c: server has type field"
}

# Fixture TEST-05: LSP server creation
run_fixture_test_05() {
    log_info "Fixture TEST-05: LSP server creation"

    local lsp_file="$SANDBOX_DIR/.lsp.json"

    # Create expected output (flat format — server name as root key)
    cat > "$lsp_file" << 'EOF'
{
  "typescript": {
    "command": "typescript-language-server",
    "args": ["--stdio"],
    "languages": ["typescript", "javascript"]
  }
}
EOF

    # Verify structure
    assert_valid_json "$lsp_file" "FIX-05a: .lsp.json is valid JSON"
    assert_json_has_key "$lsp_file" ".typescript.command" "FIX-05b: server has command field"
    assert_json_has_key "$lsp_file" ".typescript.languages" "FIX-05c: server has languages field"
}

# Fixture TEST-06: Agent team creation
run_fixture_test_06() {
    log_info "Fixture TEST-06: Agent team creation"

    local team_dir="$SANDBOX_DIR/.claude/teams/dev-team"
    local team_file="$team_dir/config.json"

    # Create expected output (agents use "role" field)
    mkdir -p "$team_dir"
    cat > "$team_file" << 'EOF'
{
  "name": "dev-team",
  "description": "Development team for parallel feature work",
  "agents": [
    {
      "name": "frontend",
      "role": "Handles UI components",
      "tools": ["Read", "Edit", "Write", "Bash"],
      "model": "sonnet"
    },
    {
      "name": "backend",
      "role": "Handles API endpoints",
      "tools": ["Read", "Edit", "Write", "Bash"],
      "model": "sonnet"
    }
  ],
  "settings": {
    "displayMode": "in-process",
    "delegateMode": false,
    "requirePlanApproval": true
  }
}
EOF

    # Verify structure
    assert_valid_json "$team_file" "FIX-06a: team config.json is valid JSON"
    assert_json_has_key "$team_file" ".name" "FIX-06b: has name field"
    assert_json_has_key "$team_file" ".description" "FIX-06c: has description field"
    assert_json_has_key "$team_file" ".agents" "FIX-06d: has agents array"
}

# ============================================
# SPECIFIC TEST RUNNER
# ============================================
run_specific_test() {
    local test_id="$1"
    log_section "Running specific test: $test_id"

    case "$test_id" in
        TEST-01) run_fixture_test_01 ;;
        TEST-02) run_fixture_test_02 ;;
        TEST-03) run_fixture_test_03 ;;
        TEST-04) run_fixture_test_04 ;;
        TEST-05) run_fixture_test_05 ;;
        TEST-06) run_fixture_test_06 ;;
        STRUCT-*) run_structure_tests ;;
        *)
            log_fail "Unknown test: $test_id"
            echo "Available tests: TEST-01..06, STRUCT-*"
            exit 1
            ;;
    esac
}

# ============================================
# INTERACTIVE TESTS (runs actual Claude)
# ============================================
run_interactive_tests() {
    log_section "Interactive Tests (uses Claude, costs tokens)"
    log_info "Running tests that use actual Claude commands..."
    log_info "This will consume tokens and may take several minutes."

    if [ -x "$SCRIPT_DIR/e2e-interactive.sh" ]; then
        "$SCRIPT_DIR/e2e-interactive.sh" all
    else
        log_fail "e2e-interactive.sh not found or not executable"
    fi
}

# ============================================
# MAIN
# ============================================
main() {
    case "$TEST_TYPE" in
        all)
            run_structure_tests
            run_fixture_tests
            ;;
        structure)
            run_structure_tests
            ;;
        e2e|fixture)
            run_fixture_tests
            ;;
        interactive)
            run_interactive_tests
            ;;
        full)
            run_structure_tests
            run_fixture_tests
            run_interactive_tests
            ;;
        TEST-*|STRUCT-*)
            run_specific_test "$TEST_TYPE"
            ;;
        *)
            echo "Usage: $0 [all|structure|e2e|fixture|interactive|full|TEST-XX|STRUCT-XX]"
            exit 1
            ;;
    esac

    print_summary
}

main "$@"
