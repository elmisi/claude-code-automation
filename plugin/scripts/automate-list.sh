#!/bin/bash
#
# automate-list.sh — Print automations registry as a formatted table
#
# Reads ~/.claude/automations-registry.json and outputs a table + commands summary.
# No AI involved — pure bash + jq.
#
# Exit codes:
#   0 = success (table printed or "no automations" message)
#   1 = jq not installed

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

REGISTRY="$HOME/.claude/automations-registry.json"

if [ ! -f "$REGISTRY" ]; then
  echo "No automations found. Create one with: /automate <description>"
  exit 0
fi

# Support both formats:
#   Array:  [{name, type, ...}, ...]
#   Object: {automations: [{name, type, ...}, ...], ...}
ROOT_TYPE=$(jq -r 'type' "$REGISTRY" 2>/dev/null)

if [ "$ROOT_TYPE" = "array" ]; then
  ENTRIES=$(jq -r '.[] | [.name, .type, .scope, .description] | @tsv' "$REGISTRY" 2>/dev/null)
elif [ "$ROOT_TYPE" = "object" ]; then
  ENTRIES=$(jq -r '(.automations // [])[] | [.name, .type, .scope, .description] | @tsv' "$REGISTRY" 2>/dev/null)
else
  echo "No automations found. Create one with: /automate <description>"
  exit 0
fi

if [ -z "$ENTRIES" ]; then
  echo "No automations found. Create one with: /automate <description>"
  exit 0
fi

# Calculate column widths
MAX_NAME=4  # "Name"
MAX_TYPE=4  # "Type"
MAX_SCOPE=5 # "Scope"
MAX_DESC=11 # "Description"

while IFS=$'\t' read -r name type scope desc; do
  [ ${#name} -gt $MAX_NAME ] && MAX_NAME=${#name}
  [ ${#type} -gt $MAX_TYPE ] && MAX_TYPE=${#type}
  [ ${#scope} -gt $MAX_SCOPE ] && MAX_SCOPE=${#scope}
  [ ${#desc} -gt $MAX_DESC ] && MAX_DESC=${#desc}
done <<< "$ENTRIES"

# Cap description width
[ $MAX_DESC -gt 60 ] && MAX_DESC=60

# Print table
printf "┌─%-${MAX_NAME}s─┬─%-${MAX_TYPE}s─┬─%-${MAX_SCOPE}s─┬─%-${MAX_DESC}s─┐\n" \
  "$(printf '%*s' $MAX_NAME '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_TYPE '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_SCOPE '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_DESC '' | tr ' ' '─')"

printf "│ %-${MAX_NAME}s │ %-${MAX_TYPE}s │ %-${MAX_SCOPE}s │ %-${MAX_DESC}s │\n" \
  "Name" "Type" "Scope" "Description"

printf "├─%-${MAX_NAME}s─┼─%-${MAX_TYPE}s─┼─%-${MAX_SCOPE}s─┼─%-${MAX_DESC}s─┤\n" \
  "$(printf '%*s' $MAX_NAME '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_TYPE '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_SCOPE '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_DESC '' | tr ' ' '─')"

while IFS=$'\t' read -r name type scope desc; do
  # Truncate description if needed
  if [ ${#desc} -gt $MAX_DESC ]; then
    desc="${desc:0:$((MAX_DESC-3))}..."
  fi
  printf "│ %-${MAX_NAME}s │ %-${MAX_TYPE}s │ %-${MAX_SCOPE}s │ %-${MAX_DESC}s │\n" \
    "$name" "$type" "$scope" "$desc"
done <<< "$ENTRIES"

printf "└─%-${MAX_NAME}s─┴─%-${MAX_TYPE}s─┴─%-${MAX_SCOPE}s─┴─%-${MAX_DESC}s─┘\n" \
  "$(printf '%*s' $MAX_NAME '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_TYPE '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_SCOPE '' | tr ' ' '─')" \
  "$(printf '%*s' $MAX_DESC '' | tr ' ' '─')"

echo ""
echo "Commands:"
echo "  /automate edit <name>        Edit an automation"
echo "  /automate delete <name>      Delete an automation"
echo "  /automate export [file]      Export all to JSON"
echo "  /automate import <file>      Import from JSON"
echo "  /automate verify             Health-check all"
echo "  /automate cleanup            Remove all (pre-uninstall)"
echo "  /automate <description>      Create new automation"
