---
name: golang-backend
description: |
  Expert Go (Golang) backend engineering skill. Use this whenever the user is writing, reading,
  debugging, or designing Go code — including HTTP servers, CLIs, gRPC services, background workers,
  database access, concurrency patterns, or system utilities. Also triggers on: Go module management
  (go.mod, go.sum), error handling patterns, goroutines and channels, context propagation, middleware,
  REST or gRPC API design in Go, testing (table-driven tests, testify, httptest), Go toolchain
  (go build, go test, go generate, go vet, golangci-lint), Dockerfile for Go services,
  and performance profiling (pprof). Triggers even when the user is learning Go idioms or
  asking "how do I do X in Go" — provide idiomatic Go, not just working code.
---

# Go Backend Skill

Opinionated, production-focused Go engineering. Go rewards simplicity and explicitness —
this skill enforces idiomatic patterns and avoids anti-patterns common when coming from
other languages (especially over-engineering or fighting the type system).

## Core Philosophy

- **Errors are values** — handle them at the call site, wrap with context, never ignore
- **Interfaces are discovered, not designed** — define interfaces where they're consumed, keep them small
- **Concurrency is a tool, not a default** — sequential code is easier to reason about
- **The standard library is vast** — reach for it before adding a dependency

---

## Process

### 1. Project structure (standard layout)
```
myservice/
  cmd/
    server/main.go          # entry point — thin, just wires things up
  internal/
    handler/                # HTTP handlers
    service/                # business logic
    repository/             # database access
    model/                  # domain types
  pkg/                      # exported packages (only if truly reusable)
  migrations/
  Makefile
  go.mod
```
> `internal/` is enforced by the compiler — prefer it over `pkg/` unless you're building a library.

### 2. Error handling (canonical pattern)
```go
// Wrap errors with context at every boundary
result, err := repo.FindUser(ctx, id)
if err != nil {
    return fmt.Errorf("handler.GetUser: %w", err)
}

// Sentinel errors for expected conditions
var ErrNotFound = errors.New("not found")
if errors.Is(err, ErrNotFound) { ... }

// Custom error types for structured errors
type ValidationError struct {
    Field   string
    Message string
}
func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s %s", e.Field, e.Message)
}
```
**Never** use `panic` for expected error conditions. Use `log.Fatal` only in `main()`.

### 3. HTTP server (net/http + stdlib)
```go
// Use http.ServeMux (Go 1.22+ supports method+path patterns)
mux := http.NewServeMux()
mux.HandleFunc("GET /users/{id}", h.GetUser)
mux.HandleFunc("POST /users", h.CreateUser)

// Middleware as handler wrappers
func withLogging(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        slog.Info("request", "method", r.Method, "path", r.URL.Path,
            "duration", time.Since(start))
    })
}
```

### 4. Context propagation
```go
// Always accept ctx as first parameter
func (s *UserService) Get(ctx context.Context, id string) (*User, error)

// Set timeouts at the entry point, not deep in the stack
ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
defer cancel()

// Store only request-scoped values in context (request ID, auth info)
// Never store dependencies (DB, logger) in context
```

### 5. Concurrency patterns
```go
// Fan-out with errgroup (golang.org/x/sync/errgroup)
g, ctx := errgroup.WithContext(ctx)
for _, id := range ids {
    id := id // capture loop var (pre-Go 1.22)
    g.Go(func() error {
        return process(ctx, id)
    })
}
if err := g.Wait(); err != nil { ... }

// Worker pool — limit concurrency with a semaphore channel
sem := make(chan struct{}, maxWorkers)
for _, item := range items {
    sem <- struct{}{}
    go func(item Item) {
        defer func() { <-sem }()
        process(item)
    }(item)
}
```

### 6. Database (database/sql + sqlx or pgx)
```go
// Always use parameterized queries — never string-format SQL
row := db.QueryRowContext(ctx,
    "SELECT id, name FROM users WHERE id = $1", id)

// Prefer pgx for Postgres — better performance, native types
// Use sqlc for type-safe query generation from raw SQL

// Always close rows
rows, err := db.QueryContext(ctx, query)
if err != nil { return err }
defer rows.Close()
```

### 7. Testing (table-driven)
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name    string
        a, b    int
        want    int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}

// Use httptest for HTTP handlers
func TestGetUser(t *testing.T) {
    rec := httptest.NewRecorder()
    req := httptest.NewRequest("GET", "/users/1", nil)
    handler.ServeHTTP(rec, req)
    assert.Equal(t, http.StatusOK, rec.Code)
}
```

---

## Current Best Practices (2025)

### Logging
Use `log/slog` (stdlib, Go 1.21+):
```go
slog.Info("user created", "id", user.ID, "email", user.Email)
slog.Error("db query failed", "err", err, "query", q)
```

### Configuration
Use environment variables + a config struct:
```go
type Config struct {
    Port    int    `env:"PORT,default=8080"`
    DBURL   string `env:"DATABASE_URL,required"`
}
// Use github.com/caarlos0/env for parsing
```

### Dependency injection
Wire dependencies in `main()` — no global state, no service locators:
```go
func main() {
    cfg := mustLoadConfig()
    db := mustConnectDB(cfg.DBURL)
    repo := repository.New(db)
    svc := service.New(repo)
    h := handler.New(svc)
    http.ListenAndServe(":"+cfg.Port, h.Routes())
}
```

### Makefile targets (always include these)
```makefile
.PHONY: build test lint vet run

build:
	go build -o bin/server ./cmd/server

test:
	go test -race -count=1 ./...

lint:
	golangci-lint run

vet:
	go vet ./...

run:
	go run ./cmd/server
```

---

## Red Flags

- Goroutine without a clear termination condition — goroutine leak
- Mutex protecting a large chunk of code — narrow the critical section
- `interface{}` / `any` without a clear reason — use generics or concrete types
- Returning a pointer to a local variable to "avoid copying" — Go's escape analysis handles this
- `init()` functions with side effects — use explicit initialization in `main()`
- Global mutable state — pass dependencies explicitly

---

## Verification Checklist

- [ ] `go build ./...` — compiles cleanly
- [ ] `go vet ./...` — no vet issues
- [ ] `go test -race ./...` — all tests pass, no race conditions
- [ ] `golangci-lint run` — no lint errors (or all suppressed with justification)
- [ ] No `err` variables silently discarded (`_ = err` is a red flag)
- [ ] All goroutines have a defined lifecycle (context cancellation or done channel)
- [ ] SQL queries are parameterized — no string formatting
- [ ] `go mod tidy` leaves go.sum unchanged
