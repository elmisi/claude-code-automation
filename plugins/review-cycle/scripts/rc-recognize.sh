#!/bin/bash
#
# rc-recognize.sh - Recognition coverage check. Runs before anything else and
# costs nothing: it is path and extension matching only.
#
# Usage: rc-recognize.sh <base> <head>
# Emits: {"coverage", "total", "classified", "unknown", "manifests",
#         "threshold", "blocked"}
# Exit:  0 when coverage is sufficient; 1 when too much is unrecognised to
#        proceed (the payload is still emitted); 2 on usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"
rc_need git; rc_need jq

[ $# -eq 2 ] || rc_usage "rc-recognize.sh <base> <head>"
BASE="$1"; HEAD_REF="$2"
ROOT="$(rc_repo_root)"

mapfile -t FILES < <(git -C "$ROOT" diff --name-only "$BASE...$HEAD_REF")

total=0; classified=0
unknown_json="[]"
for f in "${FILES[@]}"; do
    [ -n "$f" ] || continue
    total=$((total+1))
    if rc_is_generated "$f" || [ "$(rc_role "$f")" != unknown ]; then
        classified=$((classified+1))
    else
        unknown_json=$(jq -c --arg p "$f" '. + [$p]' <<<"$unknown_json")
    fi
done

manifests="[]"
while IFS= read -r m; do
    [ -n "$m" ] || continue
    [ -f "$ROOT/$m" ] && manifests=$(jq -c --arg m "$m" '. + [$m]' <<<"$manifests")
done < <(jq -r '.layer_stack | to_entries[] | .value.manifest' "$(rc_data_dir)/signals.json")

if [ "$total" -eq 0 ]; then coverage=1; else
    coverage=$(awk -v c="$classified" -v t="$total" 'BEGIN{printf "%.4f", c/t}')
fi

threshold="$(rc_threshold recognition_coverage_min)"
blocked=false
if [ "$threshold" = "null" ]; then
    rc_inert recognition_coverage_min "the unknown-stack block"
else
    awk -v c="$coverage" -v t="$threshold" 'BEGIN{exit !(c < t)}' && blocked=true
fi

jq -n --argjson coverage "$coverage" --argjson total "$total" \
      --argjson classified "$classified" --argjson unknown "$unknown_json" \
      --argjson manifests "$manifests" --arg threshold "$threshold" \
      --argjson blocked "$blocked" \
  '{coverage:$coverage,total:$total,classified:$classified,unknown:$unknown,
    manifests:$manifests,threshold:($threshold|if .=="null" then null else tonumber end),
    blocked:$blocked}'

# Blocking is mechanical, so the caller does not have to decide: too much
# unrecognised material is itself anomalous, and everything downstream costs.
[ "$blocked" = true ] && exit 1
exit 0
