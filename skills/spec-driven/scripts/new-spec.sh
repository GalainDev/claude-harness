#!/usr/bin/env bash
# new-spec.sh — scaffold spec documents
# Usage:
#   ./new-spec.sh --overview "Feature Name"   # living overview spec
#   ./new-spec.sh --task "Task Name"           # atomic task spec
#   ./new-spec.sh "Feature Name"              # defaults to --task

set -euo pipefail

MODE="task"
NAME=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --overview) MODE="overview"; shift ;;
    --task)     MODE="task";     shift ;;
    *)          NAME="$1";       shift ;;
  esac
done

NAME="${NAME:-Untitled}"
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
DATE=$(date +%Y-%m-%d)
SPECS_DIR="specs"
mkdir -p "$SPECS_DIR"

write_overview() {
  local file="$SPECS_DIR/overview.md"
  if [[ -f "$file" ]]; then
    echo "Overview already exists: $file (update it in place)"
    exit 0
  fi
  cat > "$file" <<EOF
# Overview: ${NAME}

**Last updated:** ${DATE}
**Status:** Exploring

---

## What we're building

<!-- One paragraph: what is this, who uses it, what problem does it solve -->

## Scope

### In
-

### Out
-

## Requirements emerging from conversation

<!-- Capture requirements as they surface — one bullet per requirement -->
-

## Open questions

- [ ]

## Decisions made

<!-- [date] decision — why -->

## Proposed task breakdown

<!-- Filled in by /decompose — leave blank until ready -->
EOF
  echo "Created: $file"
  echo "Update it continuously as the conversation develops."
  echo "Run --task to create atomic task specs when ready to build."
}

write_task() {
  local file="$SPECS_DIR/task-${SLUG}.md"
  if [[ -f "$file" ]]; then
    echo "Task spec already exists: $file"
    exit 1
  fi
  cat > "$file" <<EOF
# Task: ${NAME}

**Overview:** specs/overview.md
**Date:** ${DATE}
**Status:** Pending

---

## Context

<!-- One sentence: what this task does and why it exists in the broader feature -->

## Acceptance Criteria

- [ ] AC1: Given [precondition], when [action], then [observable outcome]
- [ ] AC2: Given [precondition], when [action], then [observable outcome]
- [ ] AC3: Edge case — [scenario] results in [behavior]

## Out of scope for this task

-

## Definition of done

- [ ] All ACs pass
- [ ] Types check (tsc --noEmit or go build ./...)
- [ ] Tests cover happy path + edge cases above
- [ ] No regressions in adjacent features
EOF
  echo "Created: $file"
  echo ""
  echo "Next: fill in ACs, then run the RLAIF loop:"
  echo "  ./skills/spec-driven/scripts/rlaif-loop.sh $file"
}

case "$MODE" in
  overview) write_overview ;;
  task)     write_task ;;
esac
