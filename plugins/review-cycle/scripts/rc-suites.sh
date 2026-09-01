#!/bin/bash
#
# rc-suites.sh - Test suite discovery and execution for the hygiene lane.
#
# The authoritative command comes from the CI workflow, because that is the
# command the team already agreed on. But CI is not a census: suites exist that
# CI does not run, and they must not break either. `enumerate` therefore lists
# what is present in the repository and marks what CI covers, so `hygiene.md`
# can declare the blind spots instead of hiding them.
#
# Reading the command out of an arbitrary CI YAML is semantic work and belongs
# to the model, once per repository (S-34). `discover` says so rather than
# guessing.
#
# Usage:
#   rc-suites.sh discover
#   rc-suites.sh enumerate
#   rc-suites.sh run <command>
#   rc-suites.sh collect <runner-key>
#
# Exit: 0 ok; 1 the suite failed / collect unavailable; 2 usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"
rc_need jq; rc_need git

SIG="$(rc_data_dir)/signals.json"
ROOT="$(rc_repo_root)"

cmd="${1:-}"; shift || true
case "$cmd" in

discover)
    tc="$(rc_state_get test_command)"
    if [ "$tc" != "null" ] && [ -n "$tc" ]; then
        jq -n --arg c "$tc" '{needs_model_extraction:false, test_command:$c, ci_files:[]}'
        exit 0
    fi
    ci="[]"
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        if [ -d "$ROOT/$p" ]; then
            while IFS= read -r f; do
                [ -n "$f" ] && ci=$(jq -c --arg f "$f" '. + [$f]' <<<"$ci")
            done < <(git -C "$ROOT" ls-files "$p")
        elif [ -f "$ROOT/$p" ]; then
            ci=$(jq -c --arg f "$p" '. + [$f]' <<<"$ci")
        fi
    done < <(jq -r '.ci_files[]' "$SIG")
    jq -n --argjson ci "$ci" \
      '{needs_model_extraction:true, test_command:null, ci_files:$ci,
        instruction:"Read these CI files, extract the command that runs the test suite, then store it with: rc-registry.sh set-test-command \"<command>\". This is done once per repository."}'
    ;;

enumerate)
    tc="$(rc_state_get test_command)"
    suites="[]"
    # Runners declared by a manifest or a runner config file.
    while IFS=$'\t' read -r key whenf command collect; do
        [ -f "$ROOT/$whenf" ] || continue
        suites=$(jq -c --arg id "$key" --arg c "$command" --arg col "$collect" --arg w "$whenf" \
            '. + [{id:$id, command:$c, detected_by:$w, collect_runner:(if $col=="null" then null else $col end)}]' <<<"$suites")
    done < <(jq -r '.runner_detect | to_entries[] | [.key, .value.when_file, .value.command, (.value.collect|tostring)] | @tsv' "$SIG")
    # Ad-hoc shell runners tracked in the repository.
    while IFS= read -r g; do
        [ -n "$g" ] || continue
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            rc_match "$f" "$g" || continue
            suites=$(jq -c --arg id "$f" --arg c "./$f" \
                '. + [{id:$id, command:$c, detected_by:"ad-hoc runner", collect_runner:null}]' <<<"$suites")
        done < <(git -C "$ROOT" ls-files)
    done < <(jq -r '.adhoc_test_runners[]' "$SIG")
    # Mark what the authoritative command covers.
    jq -n --argjson s "$suites" --arg tc "$tc" '
        ($s | unique_by(.id)) as $u |
        (if $tc == "null" or $tc == "" then null else $tc end) as $auth |
        {authoritative: $auth,
         suites: [ $u[] | . as $x | $x + {covered_by_ci:
            (if $auth == null then false
             else ($auth | contains($x.id)) or ($auth | contains($x.command)) end)} ]}'
    ;;

run)
    [ $# -ge 1 ] || rc_usage "rc-suites.sh run <command>"
    start=$(date +%s)
    if (cd "$ROOT" && eval "$*") >/dev/null 2>&1; then status=green; else status=red; fi
    end=$(date +%s)
    jq -n --arg c "$*" --arg s "$status" --argjson d "$((end-start))" \
      '{command:$c, status:$s, duration_s:$d}'
    [ "$status" = green ] || exit 1
    ;;

collect)
    # Additional check, not the primary guarantee (S-35). A failed collect is
    # never read as an empty set: it is reported as unavailable and the lane
    # continues, declaring the gap.
    [ $# -eq 1 ] || rc_usage "rc-suites.sh collect <runner-key>"
    c=$(jq -r --arg k "$1" '.collect_commands[$k] // "null"' "$SIG")
    if [ "$c" = "null" ]; then
        jq -n --arg k "$1" '{available:false, runner:$k, reason:"no collect command known for this runner", tests:null}'
        exit 1
    fi
    if out=$( (cd "$ROOT" && eval "$c") 2>/dev/null ); then
        jq -n --arg k "$1" --arg c "$c" --argjson t "$(printf '%s\n' "$out" | jq -R . | jq -s .)" \
          '{available:true, runner:$k, command:$c, tests:$t, count:($t|length)}'
    else
        jq -n --arg k "$1" --arg c "$c" \
          '{available:false, runner:$k, command:$c, reason:"collect command failed — the collected set is not comparable, this is not an empty set", tests:null}'
        exit 1
    fi
    ;;

*) rc_usage "rc-suites.sh discover|enumerate|run <command>|collect <runner-key>" ;;
esac
