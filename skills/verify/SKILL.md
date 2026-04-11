---
name: verify
description: Comprehensive verification and quality gate skill. Triggers when the user asks to "check", "verify", "review", "test", "validate", "make sure this works", or "is this good" — and proactively after finishing a feature, bug fix, or refactor. Covers type checking, linting, unit tests, integration tests, security scanning, and code quality review. Run this before declaring work done.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: engineering
---

# Verify Skill

Structured, layered verification that catches issues at the cheapest possible stage.
Run checks from fastest/cheapest to slowest/most expensive. Fix issues at each layer
before proceeding to the next.

## The Verification Ladder

```
Layer 1 — Static (seconds)     → Types, lint, format
Layer 2 — Unit tests (seconds) → Business logic correctness
Layer 3 — Integration (minutes)→ Component interaction, DB, API
Layer 4 — E2E (minutes)        → User flows, browser
Layer 5 — Security scan        → Vulnerabilities, secrets
Layer 6 — Human review         → Architecture, intent
```

Stop at the first layer that fails. Fix it, re-run that layer, then continue.

---

## Process

### Layer 1: Static Analysis

**TypeScript / JavaScript:**
```bash
tsc --noEmit                        # type errors
npx eslint . --max-warnings 0       # lint (zero tolerance)
npx prettier --check .              # formatting
```

**Go:**
```bash
go build ./...
go vet ./...
golangci-lint run --timeout 5m
gofmt -l .   # should output nothing
```

Fix ALL static errors before proceeding. No `// @ts-ignore` or `//nolint` without a comment explaining why.

### Layer 2: Unit Tests

Run with race detection and verbose output:
```bash
# Go
go test -race -count=1 -v ./...

# JS/TS
vitest run --reporter verbose
# or
jest --no-coverage
```

Check for:
- All tests pass
- No skipped tests that shouldn't be skipped (`t.Skip`, `it.skip`, `xit`)
- Test output has no unexpected warnings

### Layer 3: Integration Tests

```bash
# Go (requires test DB / external services)
go test -race -tags integration ./...

# JS with real DB
TEST_DB_URL=postgres://... vitest run --project integration
```

If integration tests require infrastructure, use Docker Compose:
```bash
docker compose -f docker-compose.test.yml up -d
# run tests
docker compose -f docker-compose.test.yml down
```

### Layer 4: E2E (when applicable)

**Preferred: agent-browser** (install once: `npm install -g agent-browser && agent-browser install`)

```bash
# Open the app and get a snapshot of the accessibility tree
agent-browser open http://localhost:3000
agent-browser snapshot

# Interact using refs from the snapshot (e.g. @e1, @e2)
agent-browser click @e3
agent-browser fill @e1 "test@example.com"
agent-browser screenshot before-submit.png

# Full session example
agent-browser open http://localhost:3000/login
agent-browser snapshot                          # see interactive elements
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3                         # submit button
agent-browser snapshot                          # verify post-login state
```

**Fallback: test runner**
```bash
npx playwright test    # if Playwright is configured
npx cypress run        # if Cypress is configured
```

Check that critical user paths work:
- Happy path (main user journey)
- Error states (invalid input, network failure)
- Auth boundaries (authenticated vs unauthenticated)

### Layer 5: Security Scan

**Secrets:**
```bash
# Check for accidentally committed secrets
git diff HEAD --cached | grep -iE '(api_key|secret|password|token)\s*=\s*["\x27][^"\x27]{8,}'
# or use trufflehog / gitleaks
```

**Dependencies:**
```bash
# JS
npm audit --audit-level=high

# Go
govulncheck ./...
```

**OWASP checklist for web endpoints:**
- [ ] No SQL injection (parameterized queries only)
- [ ] No XSS (output is escaped / React handles this by default)
- [ ] CSRF protection on state-mutating endpoints
- [ ] Auth/authz on all protected routes
- [ ] Rate limiting on auth endpoints
- [ ] No sensitive data in logs or error responses

### Layer 6: Code Quality Review

Before marking anything done, ask these questions:

**Correctness:**
- Does the code do what was asked?
- Are edge cases handled (empty list, zero, nil/undefined, concurrent access)?
- Are error paths tested?

**Clarity:**
- Would a new team member understand this in 5 minutes?
- Are variable and function names precise?
- Is there code that's commented out or clearly dead?

**Scope:**
- Did we add anything not asked for?
- Did we leave any TODOs that need to be resolved before shipping?

---

## Coverage Targets

| Type | Minimum | Target |
|------|---------|--------|
| Unit (business logic) | 70% | 90% |
| Integration (API routes) | 50% | 80% |
| E2E (critical paths) | Top 3–5 flows | All flows |

Don't chase 100% — test behavior, not lines.

---

## Verification Report Template

After running verification, report results in this format:

```
## Verification Results

### Layer 1 — Static: ✅ / ❌
- TypeScript: [pass / N errors]
- ESLint: [pass / N warnings]
- Format: [pass / needs formatting]

### Layer 2 — Unit Tests: ✅ / ❌
- [X] tests passed, [Y] failed, [Z] skipped
- Coverage: [N]%

### Layer 3 — Integration: ✅ / ❌ / ⏭ skipped
- [details]

### Layer 4 — E2E: ✅ / ❌ / ⏭ skipped
- [details]

### Layer 5 — Security: ✅ / ❌ / ⚠ warnings
- [details]

### Layer 6 — Code Review: ✅ / ⚠ notes
- [any issues or notes]

### Summary
[Ready to ship / Blocked on: X]
```

---

## Red Flags — Stop Immediately

- Tests are passing but coverage dropped significantly — tests may have been deleted
- `// TODO: add tests` comments in new code — add them now, not later
- A test that always passes regardless of input — the assertion is wrong
- No error case tests for a function that can fail
- Integration tests hitting production APIs or services
