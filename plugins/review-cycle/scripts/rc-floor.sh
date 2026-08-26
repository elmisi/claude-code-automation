#!/bin/bash
#
# rc-floor.sh - Computes the review floor: the lane a change may never fall
# below, whatever the model thinks. Recognition, not judgement — the same tree
# and the same diff always produce the same floor.
#
# The `invoke` field is why this script exists rather than a paragraph in a
# prompt: which lenses run is a safety property, and in the strict lane a
# missing lens fails invisibly. Emitting the list keeps the orchestrator's
# prompt free of any lane conditional (S-31).
#
# Usage: rc-floor.sh <inventory.json> [promoted-lane-from-registry]
# Emits: {"floor","lane","promoted_from","signals","layer","invoke","intent_gate"}
# Exit:  0 on success; 2 on usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"
rc_need jq

[ $# -ge 1 ] || rc_usage "rc-floor.sh <inventory.json> [promoted-lane]"
INV="$1"
REGISTRY_LANE="${2:-}"
[ -f "$INV" ] || rc_die "inventory file not found: $INV" 2
SIG="$(rc_data_dir)/signals.json"

n_files=$(jq '.files | length' "$INV")
[ "$n_files" -gt 0 ] || rc_die "empty inventory: nothing changed between the two refs"

# --- sensitive-area signals --------------------------------------------------
signals="[]"; layer="base"; floor="$(jq -r '.floor_rules.default' "$SIG")"

while IFS=$'\t' read -r path generated; do
    [ -n "$path" ] || continue
    [ "$generated" = "true" ] && continue
    while IFS=$'\t' read -r pat lane why; do
        [ -n "$pat" ] || continue
        if rc_match "$path" "$pat"; then
            floor="$(rc_lane_max "$floor" "$lane")"
            signals=$(jq -c --arg p "$path" --arg m "$pat" --arg l "$lane" --arg w "$why" \
                '. + [{path:$p, match:$m, floor:$l, why:$w, layer:"base"}] ' <<<"$signals")
        fi
    done < <(jq -r '.layer_base.sensitive[] | [.match, .floor, .why] | @tsv' "$SIG")
done < <(jq -r '.files[] | [.path, (.generated|tostring)] | @tsv' "$INV")

# --- stack-specific layer ----------------------------------------------------
# Fires only where a stack manifest is present. Its absence is not a failure:
# the base layer answers everywhere, just more coarsely.
ROOT="$(rc_repo_root)"
while IFS=$'\t' read -r stack manifest; do
    [ -f "$ROOT/$manifest" ] || continue
    while IFS= read -r tc; do
        [ -n "$tc" ] || continue
        while IFS= read -r path; do
            if rc_match "$path" "**/$tc"; then
                floor="$(rc_lane_max "$floor" normal)"
                layer="stack"
                signals=$(jq -c --arg p "$path" --arg m "$tc" --arg s "$stack" \
                    '. + [{path:$p, match:$m, floor:"normal", why:("test configuration for " + $s), layer:"stack"}]' <<<"$signals")
            fi
        done < <(jq -r '.files[].path' "$INV")
    done < <(jq -r --arg s "$stack" '.layer_stack[$s].test_config[]?' "$SIG")
done < <(jq -r '.layer_stack | to_entries[] | [.key, .value.manifest] | @tsv' "$SIG")

# --- coarse rules ------------------------------------------------------------
only_inert=$(jq '[.files[] | select(.generated == false and .role != "docs")] | length == 0' "$INV")
if [ "$only_inert" = "true" ] && [ "$(jq 'length' <<<"$signals")" -eq 0 ]; then
    floor="$(jq -r '.floor_rules.docs_or_generated_only' "$SIG")"
else
    churn=$(jq '.added + .removed' "$INV")
    dispersion=$(jq '.dispersion' "$INV")
    cfg=$(jq '[.files[] | select(.role == "config" and .generated == false)] | length' "$INV")
    nosrc=$(jq '.source_without_tests | length' "$INV")
    d_min=$(jq -r '.floor_rules.raise_to_normal_when.dispersion_min' "$SIG")
    c_min=$(jq -r '.floor_rules.raise_to_normal_when.churn_lines_min' "$SIG")

    [ "$cfg" -gt 0 ]            && floor="$(rc_lane_max "$floor" normal)"
    [ "$dispersion" -ge "$d_min" ] && floor="$(rc_lane_max "$floor" normal)"
    [ "$churn" -ge "$c_min" ]   && floor="$(rc_lane_max "$floor" normal)"
    [ "$nosrc" -gt 0 ]          && floor="$(rc_lane_max "$floor" normal)"
fi

# --- registry promotion ------------------------------------------------------
# The registry may only raise the floor, never lower it.
lane="$floor"; promoted_from=null
if [ -n "$REGISTRY_LANE" ] && [ "$REGISTRY_LANE" != "null" ]; then
    lane="$(rc_lane_max "$floor" "$REGISTRY_LANE")"
    [ "$lane" != "$floor" ] && promoted_from="\"$floor\""
fi

case "$lane" in
    skip)   invoke='["review-cycle-hygiene"]'; gate='none' ;;
    fast)   invoke='["review-cycle-risk","review-cycle-hygiene"]'; gate='none' ;;
    normal) invoke='["review-cycle-intent","review-cycle-drift","review-cycle-architecture","review-cycle-risk","review-cycle-hygiene"]'; gate='required-unblockable' ;;
    strict) invoke='["review-cycle-intent","review-cycle-drift","review-cycle-architecture","review-cycle-risk","review-cycle-hygiene"]'; gate='required-strict' ;;
    *)      rc_die "internal: unknown lane '$lane'" ;;
esac

jq -n --arg floor "$floor" --arg lane "$lane" --argjson promoted "$promoted_from" \
      --argjson signals "$signals" --arg layer "$layer" \
      --argjson invoke "$invoke" --arg gate "$gate" \
  '{floor:$floor, lane:$lane, promoted_from:$promoted, signals:$signals,
    layer:$layer, invoke:$invoke, intent_gate:$gate}'
