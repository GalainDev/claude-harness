#!/usr/bin/env bash
# verify.sh — run all verification layers for the current project
# Detects project type automatically (Go, Node/TS, or both)
# Usage: ./verify.sh [--skip-e2e] [--skip-security]

set -euo pipefail

SKIP_E2E=false
SKIP_SECURITY=false

for arg in "$@"; do
  case $arg in
    --skip-e2e) SKIP_E2E=true ;;
    --skip-security) SKIP_SECURITY=true ;;
  esac
done

PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; ((PASS++)); }
fail() { echo -e "${RED}❌ $1${NC}"; ((FAIL++)); }
skip() { echo -e "${YELLOW}⏭  $1 (skipped)${NC}"; ((SKIP++)); }
header() { echo ""; echo "── $1 ──────────────────────────"; }

run() {
  local label="$1"; shift
  if "$@" > /tmp/verify-out.txt 2>&1; then
    pass "$label"
  else
    fail "$label"
    cat /tmp/verify-out.txt | head -30
  fi
}

# ── Layer 1: Static ───────────────────────────────────────────────────────────
header "Layer 1: Static Analysis"

if [[ -f "tsconfig.json" ]]; then
  run "TypeScript (tsc)" npx tsc --noEmit
fi

if [[ -f ".eslintrc.js" || -f ".eslintrc.json" || -f ".eslintrc.yaml" || -f "eslint.config.js" || -f "eslint.config.mjs" ]]; then
  run "ESLint" npx eslint . --max-warnings 0
fi

if [[ -f ".prettierrc" || -f "prettier.config.js" ]]; then
  run "Prettier (format check)" npx prettier --check .
fi

if [[ -f "go.mod" ]]; then
  run "go build" go build ./...
  run "go vet" go vet ./...
  if command -v golangci-lint &>/dev/null; then
    run "golangci-lint" golangci-lint run --timeout 5m
  else
    skip "golangci-lint (not installed — run: brew install golangci-lint)"
  fi
  UNFORMATTED=$(gofmt -l . 2>/dev/null | grep -v vendor || true)
  if [[ -z "$UNFORMATTED" ]]; then
    pass "gofmt"
  else
    fail "gofmt — unformatted files:"
    echo "$UNFORMATTED"
  fi
fi

# ── Layer 2: Unit Tests ───────────────────────────────────────────────────────
header "Layer 2: Unit Tests"

if [[ -f "go.mod" ]]; then
  run "go test -race" go test -race -count=1 ./...
fi

if [[ -f "package.json" ]]; then
  if grep -q '"vitest"' package.json 2>/dev/null; then
    run "Vitest" npx vitest run
  elif grep -q '"jest"' package.json 2>/dev/null; then
    run "Jest" npx jest --no-coverage
  fi
fi

# ── Layer 3: Integration Tests ────────────────────────────────────────────────
header "Layer 3: Integration Tests"

if [[ -f "go.mod" ]]; then
  if go test -list "Integration" ./... 2>/dev/null | grep -q "Integration"; then
    run "Go integration tests" go test -race -tags integration ./...
  else
    skip "Go integration tests (no tests tagged 'integration' found)"
  fi
fi

# ── Layer 4: E2E ──────────────────────────────────────────────────────────────
header "Layer 4: E2E Tests"

if $SKIP_E2E; then
  skip "E2E (--skip-e2e flag set)"
elif [[ -f "playwright.config.ts" || -f "playwright.config.js" ]]; then
  run "Playwright" npx playwright test
elif [[ -f "cypress.config.ts" || -f "cypress.config.js" ]]; then
  run "Cypress" npx cypress run
else
  skip "E2E (no Playwright or Cypress config found)"
fi

# ── Layer 5: Security ─────────────────────────────────────────────────────────
header "Layer 5: Security"

if $SKIP_SECURITY; then
  skip "Security scan (--skip-security flag set)"
else
  if [[ -f "package.json" ]]; then
    run "npm audit" npm audit --audit-level=high
  fi
  if [[ -f "go.mod" ]]; then
    if command -v govulncheck &>/dev/null; then
      run "govulncheck" govulncheck ./...
    else
      skip "govulncheck (not installed — run: go install golang.org/x/vuln/cmd/govulncheck@latest)"
    fi
  fi
  # Secret scan — check diff for accidentally committed secrets
  if git diff HEAD --name-only &>/dev/null; then
    SECRETS=$(git diff HEAD 2>/dev/null | grep -iE '(api_key|secret|password|private_key)\s*=\s*["\x27][^"\x27]{8,}' || true)
    if [[ -z "$SECRETS" ]]; then
      pass "Secret scan (no obvious secrets in diff)"
    else
      fail "Secret scan — potential secrets found in diff"
      echo "$SECRETS"
    fi
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════"
echo "  Results: ✅ $PASS passed  ❌ $FAIL failed  ⏭  $SKIP skipped"
echo "════════════════════════════════"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo -e "${RED}Not ready to ship — $FAIL check(s) failed.${NC}"
  exit 1
else
  echo -e "${GREEN}All checks passed. Ready to ship.${NC}"
  exit 0
fi
