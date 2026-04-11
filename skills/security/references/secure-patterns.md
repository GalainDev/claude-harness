# Secure Coding Patterns

## TypeScript / Node.js

### Environment variables
```typescript
// NEVER hardcode secrets
const apiKey = 'sk-abc123...'

// Load from environment, fail fast if missing
const apiKey = process.env.STRIPE_SECRET_KEY
if (!apiKey) throw new Error('STRIPE_SECRET_KEY is required')
```

### Input validation with zod
```typescript
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100).regex(/^[\w\s'-]+$/),
  age: z.number().int().min(0).max(150).optional(),
})

app.post('/users', async (req, res) => {
  const result = CreateUserSchema.safeParse(req.body)
  if (!result.success) {
    return res.status(400).json({ errors: result.error.flatten() })
  }
  // result.data is now typed and validated
  await createUser(result.data)
})
```

### Safe file uploads
```typescript
import { createHash } from 'crypto'
import { extname } from 'path'

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp'])
const MAX_SIZE = 5 * 1024 * 1024  // 5MB

function validateUpload(file: Express.Multer.File) {
  if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
    throw new Error('File type not allowed')
  }
  if (file.size > MAX_SIZE) {
    throw new Error('File too large')
  }
  // Generate safe filename — never use original
  const ext = file.mimetype === 'image/jpeg' ? '.jpg'
    : file.mimetype === 'image/png' ? '.png' : '.webp'
  const safeName = createHash('sha256')
    .update(file.buffer)
    .digest('hex')
    .slice(0, 16) + ext
  return safeName
}
```

### CSRF protection
```typescript
import csrf from 'csurf'

// Cookie-based sessions need CSRF protection
// Token-based (JWT in Authorization header) does NOT need CSRF
app.use(csrf({ cookie: true }))

app.get('/form', (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() })
})
// <input type="hidden" name="_csrf" value="<%= csrfToken %>">
```

### Secure cookie settings
```typescript
app.use(session({
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,    // not accessible via JS
    secure: true,      // HTTPS only
    sameSite: 'strict', // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,  // 24 hours
  },
  name: '__Host-sess',  // __Host- prefix prevents subdomain attacks
}))
```

---

## Go

### Environment variables
```go
func mustEnv(key string) string {
    v := os.Getenv(key)
    if v == "" {
        log.Fatalf("required environment variable %s is not set", key)
    }
    return v
}

var (
    stripeKey = mustEnv("STRIPE_SECRET_KEY")
    dbURL     = mustEnv("DATABASE_URL")
)
```

### Input validation
```go
type CreateUserRequest struct {
    Email string `json:"email" validate:"required,email,max=255"`
    Name  string `json:"name"  validate:"required,min=1,max=100"`
}

func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid request body", http.StatusBadRequest)
        return
    }
    if err := h.validate.Struct(req); err != nil {
        http.Error(w, "validation failed: "+err.Error(), http.StatusBadRequest)
        return
    }
    // req is now validated
}
```

### Safe SQL
```go
// NEVER
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)

// Always parameterize
user := &User{}
err := db.QueryRowContext(ctx,
    "SELECT id, name, email FROM users WHERE email = $1",
    email,
).Scan(&user.ID, &user.Name, &user.Email)
```

### Rate limiting
```go
import "golang.org/x/time/rate"

type IPLimiter struct {
    limiters sync.Map
}

func (l *IPLimiter) Get(ip string) *rate.Limiter {
    val, _ := l.limiters.LoadOrStore(ip, rate.NewLimiter(rate.Every(time.Minute), 10))
    return val.(*rate.Limiter)
}

func RateLimit(l *IPLimiter) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            ip := r.RemoteAddr
            if !l.Get(ip).Allow() {
                http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

### Secure file path handling
```go
func safePath(base, userInput string) (string, error) {
    // Clean and join
    joined := filepath.Join(base, filepath.Clean("/"+userInput))
    // Resolve symlinks and verify prefix
    resolved, err := filepath.EvalSymlinks(joined)
    if err != nil {
        return "", fmt.Errorf("path resolution: %w", err)
    }
    absBase, _ := filepath.Abs(base)
    if !strings.HasPrefix(resolved, absBase+string(os.PathSeparator)) {
        return "", errors.New("path traversal attempt blocked")
    }
    return resolved, nil
}
```

---

## Database

### Row-level security (PostgreSQL)
```sql
-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Users can only see their own orders
CREATE POLICY orders_isolation ON orders
  USING (user_id = current_setting('app.current_user_id')::uuid);

-- Set in application before queries
SET LOCAL app.current_user_id = 'user-uuid-here';
```

### Minimal privilege DB users
```sql
-- App user: only what it needs
CREATE USER app_user WITH PASSWORD '...';
GRANT SELECT, INSERT, UPDATE ON orders, users TO app_user;
GRANT USAGE ON SEQUENCE orders_id_seq TO app_user;
-- No DROP, no TRUNCATE, no schema changes

-- Migration user: separate, more permissive
CREATE USER migrator WITH PASSWORD '...';
GRANT ALL ON SCHEMA public TO migrator;
```

---

## Secrets Management

### The schema/secret split

Keep two files — one for structure (committed), one for values (never committed):

```bash
# .env.schema — commit this. Documents what vars exist, what they're for.
# AI agents read this to understand project config without seeing real values.
STRIPE_SECRET_KEY=        # Stripe secret key — get from dashboard, rotate quarterly
DATABASE_URL=             # PostgreSQL connection string — format: postgres://user:pass@host/db
JWT_SECRET=               # Random 32+ byte secret — generate: openssl rand -hex 32
NEXT_PUBLIC_APP_URL=      # Public app URL — no trailing slash

# .env — never commit. Real values, gitignored, local machine only.
STRIPE_SECRET_KEY=sk_live_...
DATABASE_URL=postgres://...
JWT_SECRET=abc123...
NEXT_PUBLIC_APP_URL=https://myapp.com
```

**Where secrets actually live per environment:**

| Environment | Where |
|-------------|-------|
| Local dev | `.env` on your machine, gitignored |
| CI/CD | GitHub Actions secrets / repo environment variables |
| Production | Platform env vars (Vercel, Railway, Fly.io) or secret manager (AWS Secrets Manager, GCP, Doppler) |

The `.env.schema` is just documentation — it never holds values. It tells teammates (and Claude) what config the project needs and why, without exposing anything sensitive. Claude Code's hook blocks reads on `.env` but allows `.env.schema`.

### .gitignore
```bash
.env
.env.local
.env.production
.env*.local
# Never: .env.schema (that one gets committed)
```

### Detecting committed secrets
```bash
# Before committing
git diff --staged | grep -iE \
  '(api_key|apikey|secret|password|passwd|token|private_key|access_key)\s*[:=]\s*[^\s]{8,}'

# Scan history (run once)
git log --all -p | grep -iE \
  '(api_key|secret|password|token)\s*[:=]\s*["\x27][^"\x27]{12,}'

# If found — rotate the secret immediately, then remove from history
# (git history rewrite does not fully remove from all remotes/forks)
```

### Rotation policy
| Secret type | Rotation |
|-------------|----------|
| API keys | On suspected exposure, quarterly otherwise |
| Session secrets | On breach, yearly otherwise |
| Service account keys | 90 days |
| User passwords | On suspected breach (don't force periodic rotation — NIST guidance) |
| JWT signing keys | On breach, support key rollover (kid header) |
