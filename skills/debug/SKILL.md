---
name: debug
description: Systematic debugging skill for diagnosing and fixing bugs. Use when the user reports a bug, something isn't working, gets an unexpected error, sees wrong output, or asks "why is this happening". Covers root cause analysis, hypothesis-driven debugging, reading stack traces, common failure patterns in Go and TypeScript/React, and structured escalation when stuck. Triggers on "this is broken", "getting an error", "not working", "why does this", or any runtime failure.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: engineering
---

# Debug Skill

Debugging is hypothesis-driven investigation, not random code changes. The goal is to understand *why* something is wrong before touching the code.

**The cardinal rule: never change code to fix a bug you haven't diagnosed.** Guessing wastes time and introduces new bugs.

---

## Process

### Step 1 — Reproduce it

Before anything else, reproduce the bug reliably:

- What are the exact steps?
- Does it happen every time or intermittently?
- Does it happen in all environments or just one?
- When did it start? What changed before it started?

If you can't reproduce it, you can't verify a fix. Intermittent bugs usually point to: race conditions, network timeouts, memory/disk pressure, or dependency on external state.

### Step 2 — Read the error

Don't skim. Read the full error message and stack trace carefully.

- What is the **error type**? (nil pointer, type error, timeout, permission denied)
- What is the **exact message**? (often tells you what was expected vs actual)
- What is the **stack trace**? Read it bottom-up: the bottom frame is where execution started, the top is where it crashed
- Which frame is **your code** vs library code? The bug is usually at the boundary

See [references/stack-traces.md](references/stack-traces.md) for language-specific trace reading.

### Step 3 — Form hypotheses

Based on the error, generate 2–4 specific hypotheses about root cause. Be specific:

| Vague | Specific |
|-------|---------|
| "Something is wrong with the database" | "The query is returning nil because the user ID doesn't exist in this environment" |
| "The auth is broken" | "The JWT is expired — the clock on the test server is out of sync" |
| "React is re-rendering" | "The parent is passing a new object reference on every render, causing the memo to miss" |

Rank by likelihood. Check the most likely one first.

### Step 4 — Gather evidence

Add targeted instrumentation to test your hypothesis. Don't spray logs everywhere — add exactly what you need to confirm or deny the hypothesis:

```go
// Hypothesis: order.UserID is empty at this point
log.Printf("[debug] order before save: id=%s userID=%q status=%s",
    order.ID, order.UserID, order.Status)
```

```typescript
// Hypothesis: the component is receiving the wrong prop
console.log('[debug] UserCard render:', { userId, isFollowing, user })
```

Read the output. Does it confirm or deny the hypothesis? If deny, move to the next hypothesis.

### Step 5 — Fix at the root cause

Once the root cause is confirmed:

- Fix the cause, not the symptom
- Understand *why* the bug was possible (missing validation? wrong assumption? race condition?)
- Add a test that would have caught this bug
- Consider whether the same bug could exist elsewhere

---

## Debugging by Error Type

### Null / undefined / nil pointer

The error tells you *where* it crashed, not *why* it's null. Work backwards:

1. What should this value have been?
2. Where is it set? Is that code path actually running?
3. Is there an early return or error path that skips the initialization?
4. Is there a race condition where it's read before it's written?

```go
// Add nil guards with logging to find where it breaks down
if order == nil {
    log.Printf("order is nil — orderID=%s callerID=%s", orderID, callerID)
    return nil, ErrOrderNotFound
}
```

### Wrong output / wrong value

Binary search the data flow:

1. Add a log at the entry point — is the input correct?
2. Add a log at the exit point — is the output wrong?
3. Binary search: add a log halfway through the transformation
4. Narrow down to the specific line where the value goes wrong

```typescript
function calculateTotal(items: Item[]): number {
  console.log('[debug] calculateTotal input:', items)          // step 1
  const subtotal = items.reduce((sum, item) => sum + item.price * item.qty, 0)
  console.log('[debug] subtotal:', subtotal)                    // step 2
  const withTax = subtotal * 1.1
  console.log('[debug] withTax:', withTax)                      // step 3
  return Math.round(withTax * 100) / 100
}
```

### Network / API failures

Checklist:
- [ ] Is the request reaching the server? (check server logs)
- [ ] Is the URL correct? (log the full URL + method + headers)
- [ ] Is the auth header correct? (log it — redact after debugging)
- [ ] Is the request body being serialized correctly? (log it)
- [ ] What does the server actually respond with? (log status + body)
- [ ] Is it a CORS issue? (check browser console for CORS errors specifically)
- [ ] Is it a timeout? (what's the timeout configured to?)

```typescript
// Instrument the fetch call
const response = await fetch(url, options)
console.log('[debug] response:', response.status, response.headers.get('content-type'))
const text = await response.text()
console.log('[debug] body:', text)
```

### React rendering issues

Common causes and diagnostics:

| Symptom | Likely cause | Check |
|---------|-------------|-------|
| Infinite re-render loop | Dependency in useEffect that changes every render | Add `console.log` to useEffect body, check deps |
| Stale state in handler | Closure over old state | Use functional update `setState(prev => ...)` |
| Child not updating | Parent memo or wrong key | Log the prop value in the child |
| Component unmounts unexpectedly | Key changes on re-render | Log when key is set |
| useEffect runs too often | Object/array created inline as dep | Memoize the value |

```typescript
// Find what's triggering re-renders
useEffect(() => {
  console.log('[debug] effect ran — deps changed')
}, [dep1, dep2])

// Find stale closure
const handleClick = useCallback(() => {
  console.log('[debug] count at click time:', count)
  setCount(count + 1)
}, [count])
```

### Go concurrency bugs

```go
// Run tests with race detector — catches most race conditions
go test -race ./...

// If you suspect a goroutine leak
import "runtime"
log.Printf("[debug] goroutines: %d", runtime.NumGoroutine())

// Deadlock: add context with timeout to all blocking operations
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
result, err := doBlockingOperation(ctx)
if errors.Is(err, context.DeadlineExceeded) {
    log.Println("[debug] operation timed out — likely deadlock or slow dependency")
}
```

### Database issues

```sql
-- Check if the query returns what you expect
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 'abc' AND status = 'pending';

-- Check if a row actually exists
SELECT COUNT(*) FROM orders WHERE id = 'the-id-in-question';

-- Check for locks
SELECT pid, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle';
```

---

## Intermittent Bugs

The hardest category. Approach:

1. **Characterize the frequency** — does it happen 1 in 100 times? 1 in 10?
2. **Look for patterns** — time of day, load level, specific users, specific data shapes
3. **Add persistent logging** — log enough context that when it happens, you know why
4. **Check for race conditions** — always run `go test -race`, check React for concurrent state updates
5. **Check for resource exhaustion** — memory, file descriptors, DB connection pool, goroutine pool
6. **Check for dependency on external state** — network calls, time, random, external services

---

## When You're Stuck

After 3 hypotheses disproved, step back:

1. **Explain it out loud** (rubber duck) — the act of articulating often surfaces the gap in your mental model
2. **Check what changed** — `git log --since="2 days ago" --oneline`, check dependency updates
3. **Simplify** — can you reproduce it in a minimal isolated case? Stripping away complexity often reveals the cause
4. **Read the source** — if a library is behaving unexpectedly, read its source, not just its docs
5. **Search the error message exactly** — copy the exact error string into the search engine

If still stuck after all of the above, surface to the user with:
- What you've tried
- What each attempt revealed
- Your best remaining hypothesis
- What information would resolve it

See [references/common-failures.md](references/common-failures.md) for a catalogue of common failure patterns by framework.
