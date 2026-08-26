#!/bin/bash
#
# rc-lib.sh - Shared helpers for the review-cycle script layer.
#
# Sourced, never executed directly. Provides path resolution, threshold
# reading, glob matching and JSON emission for the rc-*.sh scripts.
#
# Exit code convention across the layer:
#   0 = ok / valid
#   1 = blocked or invalid (diagnostics on stderr)
#   2 = usage error

RC_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Plugin root. The scripts directory may be reached through a symlink placed
# inside a skill directory, so resolve physically before stepping up.
rc_plugin_root() {
    (cd -P "$RC_LIB_DIR/.." && pwd)
}

rc_data_dir() { echo "$(rc_plugin_root)/data"; }

rc_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || {
        echo "rc: not inside a git repository" >&2
        return 1
    }
}

rc_die()   { echo "rc: $1" >&2; exit "${2:-1}"; }
rc_usage() { echo "usage: $1" >&2; exit 2; }

rc_need() {
    command -v "$1" >/dev/null 2>&1 || rc_die "missing required command: $1" 2
}

# --- thresholds -------------------------------------------------------------

# rc_threshold <key> -> prints the numeric value, or "null" when uncalibrated.
rc_threshold() {
    local key="$1" f
    f="$(rc_data_dir)/thresholds.json"
    [ -f "$f" ] || rc_die "thresholds.json not found at $f"
    jq -r --arg k "$key" '.[$k] // "null" | tostring' "$f"
}

# rc_inert <key> <what-will-not-happen>
# Announces on stderr that a mechanism is present but will never fire.
rc_inert() {
    echo "INERT: threshold '$1' is not calibrated — $2 will not fire" >&2
}

# --- glob matching ----------------------------------------------------------
#
# Translates a glob to an anchored regex. `**` crosses directory separators,
# `*` and `?` do not. This is the single matcher used for sensitive-area
# signals, generated-file exclusion and role classification, so a change here
# changes the review floor: keep it covered by tests.

rc_glob_to_regex() {
    local glob="$1" out="" i=0 c n
    while [ $i -lt ${#glob} ]; do
        c="${glob:$i:1}"
        n="${glob:$((i+1)):1}"
        case "$c" in
            '*')
                if [ "$n" = '*' ]; then
                    if [ "${glob:$((i+2)):1}" = '/' ]; then
                        out+='(.*/)?'; i=$((i+3))
                    else
                        out+='.*'; i=$((i+2))
                    fi
                else
                    out+='[^/]*'; i=$((i+1))
                fi
                ;;
            '?')  out+='[^/]';       i=$((i+1)) ;;
            '.')  out+='\.';         i=$((i+1)) ;;
            '/')  out+='/';          i=$((i+1)) ;;
            '['|']'|'('|')'|'{'|'}'|'+'|'^'|'$'|'|'|'\\')
                  out+="\\$c";       i=$((i+1)) ;;
            *)    out+="$c";         i=$((i+1)) ;;
        esac
    done
    printf '^%s$' "$out"
}

# rc_match <path> <glob> -> exit 0 when the path matches
rc_match() {
    local path="$1" re
    re="$(rc_glob_to_regex "$2")"
    [[ "$path" =~ $re ]]
}

# rc_match_any <path> <glob>... -> exit 0 when any glob matches
rc_match_any() {
    local path="$1"; shift
    local g
    for g in "$@"; do
        rc_match "$path" "$g" && return 0
    done
    return 1
}

# rc_globs <jq-path> -> newline-separated globs read from signals.json
rc_globs() {
    jq -r "$1 // [] | .[]" "$(rc_data_dir)/signals.json"
}

# rc_is_test_file <path>
# The perimeter the hygiene lane may never touch (S-35). Load-bearing: a test
# file that no pattern recognises is treated as an ordinary source file.
rc_is_test_file() {
    local path="$1" g
    while IFS= read -r g; do
        [ -n "$g" ] || continue
        rc_match "$path" "$g" && return 0
    done < <(rc_globs '.layer_base.roles.test')
    return 1
}

# rc_role <path> -> test | docs | config | source | unknown
# Order matters: test wins over source, docs and config win over source.
rc_role() {
    local path="$1" role g
    rc_is_test_file "$path" && { echo test; return; }
    for role in docs config source; do
        while IFS= read -r g; do
            [ -n "$g" ] || continue
            if rc_match "$path" "$g"; then echo "$role"; return; fi
        done < <(rc_globs ".layer_base.roles.$role")
    done
    echo unknown
}

rc_is_generated() {
    local path="$1" g
    while IFS= read -r g; do
        [ -n "$g" ] || continue
        rc_match "$path" "$g" && return 0
    done < <(rc_globs '.layer_base.generated')
    return 1
}

# --- lane ordering ----------------------------------------------------------

rc_lane_rank() {
    case "$1" in
        skip)   echo 0 ;;
        fast)   echo 1 ;;
        normal) echo 2 ;;
        strict) echo 3 ;;
        *)      echo -1 ;;
    esac
}

# rc_lane_max <a> <b> -> the more severe of the two. The floor only ever rises.
rc_lane_max() {
    local ra rb
    ra="$(rc_lane_rank "$1")"; rb="$(rc_lane_rank "$2")"
    if [ "$ra" -ge "$rb" ]; then echo "$1"; else echo "$2"; fi
}

# --- operational state ------------------------------------------------------
#
# Lives in the reviewed repository, not in the plugin. Holds what is discovered
# once per repository: the test command, the area depth, the mapping the user
# supplied for files the catalogue could not place. This is operational state,
# not policy: it never decides whether a change gets reviewed.

rc_out_dir()    { echo "$(rc_repo_root)/docs/review-cycle"; }
rc_state_file() { echo "$(rc_out_dir)/state.json"; }

rc_state_get() {
    local f; f="$(rc_state_file)"
    [ -f "$f" ] || { echo "null"; return; }
    jq -r --arg k "$1" '.[$k] // "null" | if type == "string" then . else tojson end' "$f"
}

# rc_area_depth
# S-36: an area is a top-level directory below the detected source root. When a
# repository has exactly one top-level directory holding source files, descend
# one level so the cumulative volume can still discriminate. Computed once and
# persisted, so the area key stays stable across passes.
rc_compute_area_depth() {
    local root dirs d n=0 last=""
    root="$(rc_repo_root)"
    dirs=$(git -C "$root" ls-files | awk -F/ 'NF>1 {print $1}' | sort -u)
    for d in $dirs; do
        if git -C "$root" ls-files "$d" | while IFS= read -r f; do
                [ "$(rc_role "$f")" = source ] && { echo hit; break; }
            done | grep -q hit; then
            n=$((n+1)); last="$d"
        fi
    done
    if [ "$n" -eq 1 ]; then echo 2; else echo 1; fi
}

rc_area_depth() {
    local v; v="$(rc_state_get area_depth)"
    if [ "$v" != "null" ] && [ -n "$v" ]; then echo "$v"; else rc_compute_area_depth; fi
}

# rc_area <path> <depth>
# A file sitting at the repository root has no directory to belong to; it is
# reported as <root> rather than becoming an area named after itself.
rc_area() {
    echo "$1" | awk -F/ -v d="$2" '
        NF == 1 { print "<root>"; next }
        { n = (NF - 1 < d ? NF - 1 : d); s = $1
          for (i = 2; i <= n; i++) s = s "/" $i
          print s }'
}
