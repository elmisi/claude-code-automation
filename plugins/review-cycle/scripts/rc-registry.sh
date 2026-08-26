#!/bin/bash
#
# rc-registry.sh - Pass log, operational state and accumulated debt.
#
# Two files, on purpose. registry.md is a human log and every pass is a pure
# append, which cannot corrupt anything. state.json is the machine side, read
# with jq instead of parsed out of Markdown. debt.md is a rendered view of the
# debt held in state.json.
#
# Usage:
#   rc-registry.sh init
#   rc-registry.sh set-test-command <command>
#   rc-registry.sh set-area-mapping <json-object>
#   rc-registry.sh set-area-depth <n>
#   rc-registry.sh promote-check <inventory.json>
#   rc-registry.sh append-pass <pass-id> <lane> <inventory.json> <open-count>
#   rc-registry.sh debt-add <area> <lens> <summary>
#   rc-registry.sh debt-list
#   rc-registry.sh debt-close <id>
#
# Exit: 0 ok; 1 blocked or invalid; 2 usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"
rc_need jq

OUT="$(rc_out_dir)"; STATE="$OUT/state.json"
REG="$OUT/registry.md"; DEBT="$OUT/debt.md"

state_read() {
    [ -f "$STATE" ] || rc_die "state.json not found — run 'rc-registry.sh init' first"
    jq -e . "$STATE" >/dev/null 2>&1 || rc_die "state.json is corrupt: $STATE. Operational state is not guessed; fix or delete the file."
    cat "$STATE"
}
state_write() { jq . > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"; }

render_debt() {
    {
        echo "# Open judgements"
        echo
        echo "Judgements that were raised and never closed. Every pass re-reads and"
        echo "re-presents them. Closing one is a deliberate act: \`rc-registry.sh debt-close <id>\`."
        echo
        if [ "$(jq '.debt | length' "$STATE")" -eq 0 ]; then
            echo "None open."
        else
            echo "| ID | Area | Lens | Opened | Summary |"
            echo "| --- | --- | --- | --- | --- |"
            jq -r '.debt[] | "| \(.id) | \(.area) | \(.lens) | \(.opened) | \(.summary) |"' "$STATE"
        fi
    } > "$DEBT"
}

cmd="${1:-}"; shift || true
case "$cmd" in

init)
    mkdir -p "$OUT"
    if [ ! -f "$STATE" ]; then
        jq -n --argjson depth "$(rc_compute_area_depth)" \
          '{area_depth:$depth, test_command:null, area_mapping:{}, volume:{}, debt:[], debt_next_id:1}' \
          > "$STATE"
    fi
    [ -f "$REG" ] || {
        echo "# review-cycle pass registry"
        echo
        echo "One row per pass, append-only. Operational state lives beside it in"
        echo "\`state.json\`; open judgements in \`debt.md\`."
        echo
        echo "| Pass | Range | Lane | Areas | Open judgements |"
        echo "| --- | --- | --- | --- | --- |"
    } > "$REG"
    render_debt
    echo "$OUT"
    ;;

set-test-command)
    [ $# -eq 1 ] || rc_usage "rc-registry.sh set-test-command <command>"
    state_read | jq --arg c "$1" '.test_command = $c' | state_write
    ;;

set-area-mapping)
    [ $# -eq 1 ] || rc_usage "rc-registry.sh set-area-mapping <json-object>"
    echo "$1" | jq -e 'type == "object"' >/dev/null || rc_die "area mapping must be a JSON object" 2
    state_read | jq --argjson m "$1" '.area_mapping = (.area_mapping + $m)' | state_write
    ;;

set-area-depth)
    [ $# -eq 1 ] || rc_usage "rc-registry.sh set-area-depth <n>"
    state_read | jq --argjson d "$1" '.area_depth = $d' | state_write
    ;;

promote-check)
    # Emits the lane the accumulated history demands, or null. It can only ever
    # be used to raise the floor: rc-floor.sh takes the maximum.
    [ $# -eq 1 ] || rc_usage "rc-registry.sh promote-check <inventory.json>"
    [ -f "$1" ] || rc_die "inventory file not found: $1" 2
    vol_t="$(rc_threshold uncumulated_volume_lines)"
    jud_t="$(rc_threshold open_judgements_max)"
    lane=null; reasons="[]"
    [ "$vol_t" = "null" ] && rc_inert uncumulated_volume_lines "promotion by accumulated volume"
    [ "$jud_t" = "null" ] && rc_inert open_judgements_max "promotion by open judgements"
    if [ -f "$STATE" ]; then
        while IFS= read -r area; do
            [ -n "$area" ] || continue
            if [ "$vol_t" != "null" ]; then
                v=$(jq -r --arg a "$area" '.volume[$a].uncumulated_lines // 0' "$STATE")
                if [ "$v" -ge "$vol_t" ]; then
                    lane=normal
                    reasons=$(jq -c --arg a "$area" --argjson v "$v" \
                      '. + [{area:$a, reason:"uncumulated volume", value:$v}]' <<<"$reasons")
                fi
            fi
            if [ "$jud_t" != "null" ]; then
                o=$(jq -r --arg a "$area" '[.debt[] | select(.area==$a)] | length' "$STATE")
                if [ "$o" -ge "$jud_t" ]; then
                    lane=normal
                    reasons=$(jq -c --arg a "$area" --argjson v "$o" \
                      '. + [{area:$a, reason:"open judgements", value:$v}]' <<<"$reasons")
                fi
            fi
        done < <(jq -r '.areas[]' "$1")
    fi
    if [ "$lane" = "null" ]; then
        jq -n --argjson r "$reasons" '{lane:null, reasons:$r}'
    else
        jq -n --arg l "$lane" --argjson r "$reasons" '{lane:$l, reasons:$r}'
    fi
    ;;

append-pass)
    [ $# -eq 4 ] || rc_usage "rc-registry.sh append-pass <pass-id> <lane> <inventory.json> <open-count>"
    pass="$1"; lane="$2"; inv="$3"; open_n="$4"
    [ -f "$inv" ] || rc_die "inventory file not found: $inv" 2
    areas=$(jq -r '.areas | join(", ")' "$inv")
    range=$(jq -r '"\(.base)...\(.head)"' "$inv")
    printf '| %s | `%s` | %s | %s | %s |\n' "$pass" "$range" "$lane" "$areas" "$open_n" >> "$REG"

    # A light lane accumulates unreviewed volume; a real review clears it.
    case "$lane" in
        skip|fast)
            state_read | jq --argjson f "$(jq -c '[.files[] | {area, churn: (.added + .removed)}]' "$inv")" '
                reduce $f[] as $x (.; .volume[$x.area].uncumulated_lines =
                    ((.volume[$x.area].uncumulated_lines // 0) + $x.churn))' | state_write ;;
        normal|strict)
            state_read | jq --argjson a "$(jq -c '.areas' "$inv")" '
                reduce $a[] as $x (.; .volume[$x].uncumulated_lines = 0)' | state_write ;;
        *) rc_die "unknown lane '$lane'" 2 ;;
    esac
    ;;

debt-add)
    [ $# -eq 3 ] || rc_usage "rc-registry.sh debt-add <area> <lens> <summary>"
    id=$(jq -r '.debt_next_id' "$STATE")
    state_read | jq --argjson id "$id" --arg a "$1" --arg l "$2" --arg s "$3" \
        --arg d "$(date +%Y-%m-%d)" \
        '.debt += [{id:$id, area:$a, lens:$l, summary:$s, opened:$d}] | .debt_next_id = ($id + 1)' \
        | state_write
    render_debt
    echo "$id"
    ;;

debt-list)
    state_read | jq '.debt'
    ;;

debt-close)
    [ $# -eq 1 ] || rc_usage "rc-registry.sh debt-close <id>"
    jq -e --argjson id "$1" 'any(.debt[]; .id == $id)' "$STATE" >/dev/null \
        || rc_die "no open judgement with id $1"
    state_read | jq --argjson id "$1" '.debt |= map(select(.id != $id))' | state_write
    render_debt
    ;;

*)
    rc_usage "rc-registry.sh init|set-test-command|set-area-mapping|set-area-depth|promote-check|append-pass|debt-add|debt-list|debt-close"
    ;;
esac
