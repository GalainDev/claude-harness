---
name: code-review
description: |
  Structured code review skill. Triggers when the user asks to "review", "review my code",
  "review this PR", "review the diff", "check this before I merge", "give me feedback on",
  or "what do you think about this code". Also use proactively after completing a feature
  implementation to catch issues before committing. Reviews are actionable — every finding
  includes file, line, severity, and a concrete fix or question.
  User-invocable via /review.
---

# Code Review Skill

Reviews are only useful if they're specific and actionable. Every finding must name the
exact location, explain why it's a problem, and suggest what to do about it.

## Review Scope

Before starting, determine what to review:
- **Staged changes**: `git diff --staged`
- **Recent commit(s)**: `git diff HEAD~N..HEAD`
- **PR / branch**: `git diff main..HEAD`
- **Specific files**: read those files directly

If scope is ambiguous, check `git status` and `git diff` and infer from context.

---

## Process

### Phase 1 — Understand Intent

Read the most recent spec or PR description if available. A good review judges code
against its *intent*, not just abstract best practices. If no spec exists, infer intent
from the diff.

### Phase 2 — Static Pass (automated)

Run whatever is available for this project type:

**TypeScript/JS:**
```bash
npx tsc --noEmit 2>&1 | head -30
npx eslint --format compact <changed files>
```

**Go:**
```bash
go vet ./...
golangci-lint run --new-from-rev=HEAD~1 2>&1 | head -30
```

Note the output — include real compiler/lint findings in the review report.

### Phase 3 — Manual Review

Work through the diff methodically. For each changed area:

**Correctness:**
- Does the code do what it claims?
- Are all code paths handled (null/undefined, empty arrays, network failures)?
- Are error cases tested?
- Any off-by-one, race condition, or mutation bug?

**Security:**
- SQL injection / XSS / path traversal possible?
- Auth/authz applied to all protected routes?
- Secrets or sensitive data in logs/responses?
- User input validated at the boundary?

**Design:**
- Does this fit the existing architecture or introduce inconsistency?
- Is the right abstraction being added (or avoided)?
- Is logic duplicated from elsewhere in the codebase?
- Is the component/function doing one thing?

**Performance:**
- Any N+1 queries or unnecessary re-renders?
- Is expensive work memoized / cached where it should be?
- Any blocking operations on the hot path?

**Tests:**
- Are happy path and at least two edge cases covered?
- Are tests testing behavior or implementation details?
- Would a refactor break these tests without a behavior change? (If yes: too coupled)

**Readability:**
- Would an unfamiliar engineer understand this in 5 minutes?
- Are names precise (not `data`, `result`, `temp`)?
- Is there dead code, commented-out code, or TODO left in?

---

## Review Report Format

```markdown
## Code Review — <scope description>

### Summary
<1–3 sentences: overall quality, main themes in findings>

### Findings

#### 🔴 Critical — must fix before merge
| # | File:Line | Issue | Fix |
|---|-----------|-------|-----|
| 1 | `auth/middleware.go:42` | No auth check on `/admin` route | Add `requireRole(admin)` middleware |

#### 🟡 Important — strongly recommended
| # | File:Line | Issue | Fix |
|---|-----------|-------|-----|
| 1 | `UserCard.tsx:28` | Missing loading state causes layout shift | Add `isLoading` skeleton branch |

#### 🔵 Suggestions — non-blocking improvements
| # | File:Line | Note |
|---|-----------|------|
| 1 | `utils/format.ts:14` | `formatDate` is duplicated in `helpers/date.ts` — consider consolidating |

#### ✅ Well done
- [Specific things done well — required, not just filler]

### Verdict
[ ] Ready to merge
[ ] Ready with minor fixes (🟡 items addressed)
[ ] Needs rework (🔴 items blocking)
```

---

## Severity Guide

| Level | Meaning | Blocks merge? |
|-------|---------|---------------|
| 🔴 Critical | Bug, security issue, data loss risk | Yes |
| 🟡 Important | Correctness concern, missing test, design problem | Recommended fix |
| 🔵 Suggestion | Style, naming, refactor opportunity | No |

---

## Red Flags — Always 🔴 Critical

- SQL built by string concatenation
- `catch (e) {}` swallowing errors silently  
- Auth/session check missing on a route that changes data
- Hardcoded credentials or API keys
- `Promise` returned but not awaited
- Goroutine leak (no termination condition)
- Writing to shared state without a lock in concurrent code

---

## What Good Reviews Are Not

- A style guide lecture — if ESLint/Prettier catches it, let the tool handle it
- A rewrite suggestion — suggest, don't prescribe entire alternative implementations
- A place to demonstrate knowledge — review the code that exists, not the code you'd write
- Vague — "this could be better" without saying how is not a finding
