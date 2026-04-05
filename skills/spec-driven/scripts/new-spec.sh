#!/usr/bin/env bash
# new-spec.sh — scaffold a new spec document
# Usage: ./new-spec.sh "Feature Name"

set -euo pipefail

FEATURE_NAME="${1:-Untitled Feature}"
SLUG=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
DATE=$(date +%Y-%m-%d)
SPECS_DIR="specs"

mkdir -p "$SPECS_DIR"

SPEC_FILE="$SPECS_DIR/${SLUG}.md"

if [[ -f "$SPEC_FILE" ]]; then
  echo "Spec already exists: $SPEC_FILE"
  exit 1
fi

cat > "$SPEC_FILE" <<EOF
# Spec: ${FEATURE_NAME}

**Date:** ${DATE}
**Status:** Draft

---

## Context

<!-- One paragraph: why does this feature exist, who uses it, what problem does it solve -->

## Acceptance Criteria

- [ ] AC1: Given [precondition], when [action], then [observable outcome]
- [ ] AC2: Given [precondition], when [action], then [observable outcome]
- [ ] AC3: Edge case — [scenario] results in [behavior]

## Out of Scope

- [Things explicitly NOT included in this feature]

## Open Questions

- [ ] [Question that needs to be resolved before implementation can begin]

## Definition of Done

- [ ] All acceptance criteria pass
- [ ] Types check (tsc --noEmit or go build)
- [ ] Tests cover happy path + at least 2 edge cases
- [ ] No regressions in adjacent features
- [ ] Code reviewed

---

## Implementation Notes

<!-- Filled in during/after implementation -->

## Decisions Made

<!-- Decision records for choices made during implementation -->
EOF

echo "Created spec: $SPEC_FILE"
echo ""
echo "Next steps:"
echo "  1. Fill in Context and Acceptance Criteria"
echo "  2. Review with stakeholders if needed"
echo "  3. Start implementation with: spec-driven skill"
