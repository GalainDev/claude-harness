# Common Failure Patterns

## Go

### nil pointer dereference
**Symptom:** `panic: runtime error: invalid memory address or nil pointer dereference`
**Cause:** Calling a method or accessing a field on a nil pointer
**Pattern:** Returned `nil, err` from a function but the caller ignored the error and used the nil value

```go
// Classic pattern
user, err := repo.FindUser(id)
if err != nil {
    return err
}
// user could still be nil if repo returns (nil, nil) for "not found"
// Always check:
if user == nil {
    return ErrNotFound
}
```

### interface nil trap
**Symptom:** `if err != nil` is true but `err` appears nil when logged
**Cause:** A nil pointer of a concrete type assigned to an interface is not nil

```go
var p *MyError = nil
var err error = p
fmt.Println(err == nil) // false! interface has type info even if value is nil

// Fix: return untyped nil
func doThing() error {
    var p *MyError = nil
    if somethingFailed {
        return p  // WRONG — non-nil error interface
    }
    return nil    // CORRECT
}
```

### context cancellation ignored
**Symptom:** Operation continues after request is cancelled, goroutines accumulate
**Cause:** Not checking `ctx.Done()` or passing context to DB/HTTP calls

```go
// Always propagate context
rows, err := db.QueryContext(ctx, query, args...)  // not db.Query()
resp, err := http.NewRequestWithContext(ctx, "GET", url, nil)
```

### goroutine leak
**Symptom:** Memory grows over time, `runtime.NumGoroutine()` keeps increasing
**Cause:** Goroutine blocked forever on channel receive/send with no way out

```go
// LEAKS — if the goroutine sends but nobody receives, it's stuck forever
go func() {
    result := doWork()
    ch <- result  // stuck if caller already returned
}()

// SAFE — use context + select
go func() {
    result := doWork()
    select {
    case ch <- result:
    case <-ctx.Done():
    }
}()
```

---

## TypeScript / Node.js

### unhandled promise rejection
**Symptom:** `UnhandledPromiseRejectionWarning` or silent failures in async code
**Cause:** `async` function called without `await` or `.catch()`

```typescript
// WRONG — fire and forget, errors disappear
processOrder(orderId)

// CORRECT
await processOrder(orderId)
// or
processOrder(orderId).catch(err => logger.error(err))
```

### event loop blocking
**Symptom:** Server stops responding intermittently for 100ms–several seconds
**Cause:** Synchronous CPU-heavy work on the main thread

```typescript
// BLOCKS the event loop
const result = JSON.parse(hugeMegabyteString)
const sorted = millionItemArray.sort()
const hash = crypto.pbkdf2Sync(...)  // always use async version

// CORRECT — use async or worker threads for heavy work
const hash = await new Promise((resolve, reject) =>
  crypto.pbkdf2(password, salt, 100000, 64, 'sha512', (err, key) =>
    err ? reject(err) : resolve(key)
  )
)
```

### circular JSON
**Symptom:** `TypeError: Converting circular structure to JSON`
**Cause:** Object references itself, or express `res` object accidentally logged

```typescript
// WRONG
res.json({ req })  // req contains res which contains req...

// Diagnosis
const seen = new WeakSet()
JSON.stringify(obj, (key, val) => {
  if (typeof val === 'object' && val !== null) {
    if (seen.has(val)) return '[Circular]'
    seen.add(val)
  }
  return val
})
```

### memory leak patterns
**Symptom:** Node process memory grows indefinitely
**Common causes:**
```typescript
// 1. Global cache with no eviction
const cache = new Map()  // grows forever
// Fix: use LRU cache with max size

// 2. Event listener accumulation
emitter.on('event', handler)  // added multiple times
// Fix: emitter.removeListener() or use emitter.once()

// 3. Closure holding large objects
function createHandler(largeData: Buffer) {
  return () => process(largeData)  // largeData held in memory as long as handler exists
}

// 4. setTimeout/setInterval never cleared
const interval = setInterval(poll, 1000)
// always clearInterval(interval) on cleanup
```

---

## React

### stale closure in useEffect
**Symptom:** Effect uses outdated state/props values
```typescript
// STALE — count is always 0 inside the effect
useEffect(() => {
  const id = setInterval(() => {
    console.log(count)  // always 0
    setCount(count + 1) // always sets to 1
  }, 1000)
  return () => clearInterval(id)
}, [])  // missing count in deps

// FIX — use functional update, no dep needed
useEffect(() => {
  const id = setInterval(() => {
    setCount(prev => prev + 1)  // always correct
  }, 1000)
  return () => clearInterval(id)
}, [])
```

### infinite render loop
**Symptom:** `Maximum update depth exceeded`
**Common causes:**
```typescript
// 1. setState in render body (no condition)
function Component() {
  const [x, setX] = useState(0)
  setX(1)  // triggers re-render → setX(1) → ...
  return <div>{x}</div>
}

// 2. useEffect dep is object/array created inline
useEffect(() => {
  fetchData(options)
}, [{ page: 1 }])  // new object every render → infinite loop

// FIX: memoize the dep
const options = useMemo(() => ({ page: 1 }), [])
useEffect(() => {
  fetchData(options)
}, [options])

// 3. setState in useEffect with no dep limit
useEffect(() => {
  setData(transform(data))  // data changes → effect runs → setData → data changes
})  // no deps — runs after every render
```

### hydration mismatch
**Symptom:** `Error: Hydration failed because the initial UI does not match`
**Cause:** Server render produces different HTML than client render
```typescript
// WRONG — window doesn't exist on server
function Component() {
  return <div>{window.innerWidth > 768 ? 'desktop' : 'mobile'}</div>
}

// FIX — defer to client
function Component() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])
  if (!mounted) return null  // or a skeleton
  return <div>{window.innerWidth > 768 ? 'desktop' : 'mobile'}</div>
}
```

---

## Next.js

### `useRouter` / `useSearchParams` in Server Components
**Symptom:** `Error: useRouter only works in Client Components`
**Fix:** Add `'use client'` at top of file, or pass the value as a prop from a Server Component

### fetch not caching as expected
**Symptom:** Data is stale or always refetching
**Cause:** `cache` option not set, or revalidation too aggressive
```typescript
// Static — cached indefinitely
const data = await fetch(url, { cache: 'force-cache' })

// Revalidate every 60 seconds
const data = await fetch(url, { next: { revalidate: 60 } })

// Never cache
const data = await fetch(url, { cache: 'no-store' })
```

### `cookies()` / `headers()` in async components
**Symptom:** `Error: cookies was called outside a request scope`
**Fix:** These functions are synchronous in Next.js 14 but must be called inside a Server Component or Route Handler, never in a utility function called from the client.
