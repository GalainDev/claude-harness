#!/usr/bin/env bash
# rlaif-loop.sh — run the RLAIF evaluation loop against a spec file
# Usage: ./rlaif-loop.sh specs/my-feature.md [max_iterations]
#
# This script:
# 1. Parses acceptance criteria from the spec markdown
# 2. Runs available test commands
# 3. Produces a structured evaluation report for Claude to act on

set -euo pipefail

SPEC_FILE="${1:-}"
MAX_ITER="${2:-3}"

if [[ -z "$SPEC_FILE" || ! -f "$SPEC_FILE" ]]; then
  echo "Usage: $0 <spec-file.md> [max_iterations]"
  echo "Example: $0 specs/user-auth.md 3"
  exit 1
fi

REPORT_DIR=".rlaif-reports"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT="$REPORT_DIR/${TIMESTAMP}-evaluation.md"

echo "# RLAIF Evaluation Report" > "$REPORT"
echo "" >> "$REPORT"
echo "**Spec:** $SPEC_FILE" >> "$REPORT"
echo "**Date:** $(date)" >> "$REPORT"
echo "" >> "$REPORT"

# ── Extract acceptance criteria from spec ─────────────────────────────────────
echo "## Acceptance Criteria (from spec)" >> "$REPORT"
echo "" >> "$REPORT"
grep -E '^\s*- \[[ x]\]' "$SPEC_FILE" >> "$REPORT" || echo "No ACs found in spec" >> "$REPORT"
echo "" >> "$REPORT"

# ── Run static checks ─────────────────────────────────────────────────────────
echo "## Static Analysis" >> "$REPORT"
echo "" >> "$REPORT"

run_check() {
  local name="$1"
  local cmd="$2"
  echo -n "Running $name... "
  if eval "$cmd" >> "$REPORT" 2>&1; then
    echo "✅ $name: PASS" >> "$REPORT"
    echo "✅"
  else
    echo "❌ $name: FAIL" >> "$REPORT"
    echo "❌"
  fi
  echo "" >> "$REPORT"
}

# TypeScript check
if [[ -f "tsconfig.json" ]]; then
  run_check "TypeScript" "npx tsc --noEmit 2>&1"
fi

# ESLint
if [[ -f ".eslintrc*" || -f "eslint.config*" ]]; then
  run_check "ESLint" "npx eslint . --max-warnings 0 2>&1"
fi

# Go checks
if [[ -f "go.mod" ]]; then
  run_check "go build" "go build ./... 2>&1"
  run_check "go vet" "go vet ./... 2>&1"
fi

# ── Run tests ─────────────────────────────────────────────────────────────────
echo "## Test Results" >> "$REPORT"
echo "" >> "$REPORT"

if [[ -f "go.mod" ]]; then
  echo "### Go Tests" >> "$REPORT"
  run_check "go test" "go test -race -count=1 ./... 2>&1"
fi

if [[ -f "package.json" ]]; then
  if grep -q '"vitest"' package.json 2>/dev/null; then
    echo "### Vitest" >> "$REPORT"
    run_check "vitest" "npx vitest run 2>&1"
  elif grep -q '"jest"' package.json 2>/dev/null; then
    echo "### Jest" >> "$REPORT"
    run_check "jest" "npx jest --no-coverage 2>&1"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo "## Summary" >> "$REPORT"
FAILS=$(grep -c "❌" "$REPORT" 2>/dev/null || echo 0)
PASSES=$(grep -c "✅" "$REPORT" 2>/dev/null || echo 0)
echo "" >> "$REPORT"
echo "- Checks passed: $PASSES" >> "$REPORT"
echo "- Checks failed: $FAILS" >> "$REPORT"
echo "" >> "$REPORT"

if [[ "$FAILS" -eq 0 ]]; then
  echo "**Status: READY** — All checks pass. Review against ACs manually." >> "$REPORT"
  echo ""
  echo "✅ All checks passed. Report: $REPORT"
else
  echo "**Status: NEEDS WORK** — $FAILS check(s) failed. See details above." >> "$REPORT"
  echo ""
  echo "❌ $FAILS check(s) failed. Report: $REPORT"
fi

echo ""
echo "Full report written to: $REPORT"
cat "$REPORT"
