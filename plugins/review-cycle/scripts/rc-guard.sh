#!/bin/bash
#
# rc-guard.sh - The hygiene lane's perimeter check (S-35).
#
# The suite is the instrument that verifies the lane, so the lane may not touch
# it. Verifying that is a set intersection, not an interpretation: no parser,
# no language, no runner, and it holds on stacks the catalogue cannot place.
#
# The exception it replaces — "test files are out of perimeter *except* for
# categories that do not execute" — was the one rule in the protocol that
# required reading a hunk's contents to apply. A typo inside a test comment is
# now a human judgement instead of an automatic fix.
#
# Usage: rc-guard.sh <base> <head>
# Exit:  0 perimeter respected; 1 a test file was touched; 2 usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"
rc_need git

[ $# -eq 2 ] || rc_usage "rc-guard.sh <base> <head>"
ROOT="$(rc_repo_root)"

violations=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    if rc_is_test_file "$f"; then
        [ "$violations" -eq 0 ] && echo "rc-guard: the hygiene lane must not modify test files (S-35):" >&2
        echo "  $f" >&2
        violations=$((violations+1))
    fi
done < <(git -C "$ROOT" diff --name-only "$1...$2")

if [ "$violations" -gt 0 ]; then
    echo "rc-guard: $violations test file(s) touched — revert them and reclassify those fixes as human judgements." >&2
    exit 1
fi
exit 0
