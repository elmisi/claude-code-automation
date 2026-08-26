#!/bin/bash
#
# rc-validate.sh - Enforces the shape of review.md.
#
# "Every outcome declares what happens if you ignore it" filters nothing unless
# something checks it, and "an open question names a concrete alternative and
# its cost" is otherwise an aspiration. This is where those two rules acquire
# teeth.
#
# Usage: rc-validate.sh <review.md>
# Exit:  0 valid; 1 invalid (violations, with line numbers, on stderr); 2 usage.

set -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-lib.sh"

[ $# -eq 1 ] || rc_usage "rc-validate.sh <review.md>"
[ -f "$1" ] || rc_die "file not found: $1" 2

awk '
function flush(   missing) {
    if (block == "") return
    missing = ""
    if (kind == "finding") {
        if (!("lens" in k))           missing = missing " Lens"
        if (!("severity" in k))       missing = missing " Severity"
        if (!("classification" in k)) missing = missing " Classification"
        else if (k["classification"] != "auto-fixable" && k["classification"] != "needs-human") {
            printf "%s:%d: %s: Classification must be auto-fixable or needs-human, found \"%s\"\n",
                   FILENAME, start, block, k["classification"] > "/dev/stderr"
            bad++
        }
        if (!("evidence" in k))       missing = missing " Evidence"
        # Evidence must contain at least one concrete anchor. A finding often
        # legitimately spans a range or cites two files, so require an anchor to
        # be present rather than forbidding everything around it.
        else if (k["evidence"] !~ /[^ \t:;,]+:[0-9]+(-[0-9]+)?/) {
            printf "%s:%d: %s: Evidence must contain at least one path:line or path:line-line anchor, found \"%s\"\n",
                   FILENAME, start, block, k["evidence"] > "/dev/stderr"
            bad++
        }
        if (!("consequence" in k))    missing = missing " Consequence"
    } else if (kind == "question") {
        if (!("lens" in k))         missing = missing " Lens"
        if (!("consequence" in k))  missing = missing " Consequence"
        if (!("alternative" in k))  missing = missing " Alternative"
        if (!("cost" in k))         missing = missing " Cost"
        if ("severity" in k) {
            printf "%s:%d: %s: an open question is a decision, not a defect — it must not carry Severity\n",
                   FILENAME, start, block > "/dev/stderr"; bad++
        }
    }
    if (missing != "") {
        printf "%s:%d: %s: missing or empty:%s\n", FILENAME, start, block, missing > "/dev/stderr"
        bad++
    }
    delete k; block = ""
}
/^##[ \t]+/ {
    flush()
    low = tolower($0)
    if (low ~ /finding/)        section = "finding"
    else if (low ~ /question/)  section = "question"
    else                        section = ""
    next
}
/^###[ \t]+/ {
    flush()
    if (section == "") next
    block = $0; sub(/^###[ \t]+/, "", block)
    kind = section; start = FNR
    next
}
/^[-*][ \t]+[A-Za-z]+:/ {
    if (block == "") next
    line = $0
    sub(/^[-*][ \t]+/, "", line)
    key = tolower(substr(line, 1, index(line, ":") - 1))
    val = substr(line, index(line, ":") + 1)
    gsub(/^[ \t]+|[ \t]+$/, "", val)
    if (val != "") k[key] = val
    next
}
END {
    flush()
    if (bad > 0) {
        printf "rc-validate: %d outcome(s) do not satisfy the shape rules\n", bad > "/dev/stderr"
        exit 1
    }
}
' "$1"
