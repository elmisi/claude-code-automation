#!/bin/bash
#
# rc-inventory.sh - Mechanical inventory of a change. Counting only, no judgement.
#
# Usage: rc-inventory.sh <base> <head>
# Emits: {"base","head","files","added","removed","dispersion","area_depth",
#         "areas","tests_touched","source_without_tests"}
# Exit:  0 on success; 2 on usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"
rc_need git; rc_need jq

[ $# -eq 2 ] || rc_usage "rc-inventory.sh <base> <head>"
BASE="$1"; HEAD_REF="$2"
ROOT="$(rc_repo_root)"
DEPTH="$(rc_area_depth)"

files_json="[]"; areas_json="[]"; tests_json="[]"; nosrc_json="[]"
added_tot=0; removed_tot=0

while IFS=$'\t' read -r a d p; do
    [ -n "$p" ] || continue
    [ "$a" = "-" ] && a=0
    [ "$d" = "-" ] && d=0
    role="$(rc_role "$p")"
    gen=false; rc_is_generated "$p" && gen=true
    area="$(rc_area "$p" "$DEPTH")"
    added_tot=$((added_tot+a)); removed_tot=$((removed_tot+d))
    files_json=$(jq -c --arg p "$p" --arg r "$role" --arg ar "$area" \
                       --argjson a "$a" --argjson d "$d" --argjson g "$gen" \
        '. + [{path:$p, role:$r, area:$ar, added:$a, removed:$d, generated:$g}]' <<<"$files_json")
    areas_json=$(jq -c --arg ar "$area" '. + [$ar] | unique' <<<"$areas_json")
    if [ "$role" = test ]; then
        tests_json=$(jq -c --arg p "$p" '. + [$p]' <<<"$tests_json")
    fi
done < <(git -C "$ROOT" diff --numstat "$BASE...$HEAD_REF")

# Source files changed while no test file was touched anywhere in their area:
# a stack-agnostic signal, used by the floor.
while IFS= read -r p; do
    [ -n "$p" ] || continue
    area=$(jq -r --arg p "$p" '.[] | select(.path==$p) | .area' <<<"$files_json")
    if ! jq -e --arg ar "$area" 'any(.[]; .area==$ar and .role=="test")' <<<"$files_json" >/dev/null; then
        nosrc_json=$(jq -c --arg p "$p" '. + [$p]' <<<"$nosrc_json")
    fi
done < <(jq -r '.[] | select(.role=="source" and .generated==false) | .path' <<<"$files_json")

dispersion=$(jq 'length' <<<"$areas_json")

jq -n --arg base "$BASE" --arg head "$HEAD_REF" --argjson files "$files_json" \
      --argjson added "$added_tot" --argjson removed "$removed_tot" \
      --argjson dispersion "$dispersion" --argjson depth "$DEPTH" \
      --argjson areas "$areas_json" --argjson tests "$tests_json" \
      --argjson nosrc "$nosrc_json" \
  '{base:$base,head:$head,files:$files,added:$added,removed:$removed,
    dispersion:$dispersion,area_depth:$depth,areas:$areas,
    tests_touched:$tests,source_without_tests:$nosrc}'
