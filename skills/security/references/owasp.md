# OWASP Top 10 Reference

## A01 — Broken Access Control

The most common and impactful category. Access control enforces that users can only act within their intended permissions.

**Patterns to look for:**

```typescript
// VULNERABLE — user controls the ID, no ownership check
app.get('/api/invoices/:id', auth, async (req, res) => {
  const invoice = await db.invoices.findById(req.params.id)
  res.json(invoice)
})

// SAFE — always scope to the authenticated user
app.get('/api/invoices/:id', auth, async (req, res) => {
  const invoice = await db.invoices.findOne({
    id: req.params.id,
    userId: req.user.id,  // ownership enforced
  })
  if (!invoice) return res.status(404).json({ error: 'Not found' })
  res.json(invoice)
})
```

```go
// VULNERABLE
func GetOrder(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    order, _ := db.FindOrder(id)
    json.NewEncoder(w).Encode(order)
}

// SAFE
func GetOrder(w http.ResponseWriter, r *http.Request) {
    userID := userFromContext(r.Context()).ID
    id := chi.URLParam(r, "id")
    order, err := db.FindOrderForUser(id, userID)
    if errors.Is(err, ErrNotFound) {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }
    json.NewEncoder(w).Encode(order)
}
```

**Checklist:**
- [ ] All endpoints check authorization, not just authentication
- [ ] Object IDs scoped to the current user/tenant
- [ ] Admin endpoints protected by role check, not just auth
- [ ] Directory listing disabled
- [ ] CORS not set to `*` for authenticated APIs

---

## A02 — Cryptographic Failures

Sensitive data exposed due to weak or missing encryption.

**Password hashing:**
```typescript
// NEVER — reversible or broken
const hash = md5(password)
const hash = sha1(password)
const hash = sha256(password)  // still wrong — no salt, too fast

// CORRECT
import bcrypt from 'bcrypt'
const hash = await bcrypt.hash(password, 12)
const valid = await bcrypt.compare(input, hash)
```

```go
import "golang.org/x/crypto/bcrypt"

hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
err = bcrypt.CompareHashAndPassword(hash, []byte(input))
```

**JWT:**
```typescript
// VULNERABLE — accepts 'none' algorithm
jwt.verify(token, secret)

// SAFE — explicitly specify algorithm
jwt.verify(token, secret, { algorithms: ['HS256'] })
```

**Checklist:**
- [ ] Passwords hashed with bcrypt/argon2/scrypt (cost factor ≥ 12)
- [ ] No MD5/SHA1 for security-sensitive operations
- [ ] Sensitive data encrypted at rest for high-risk fields
- [ ] TLS 1.2+ enforced, HTTP redirects to HTTPS
- [ ] JWT algorithm explicitly allowlisted server-side

---

## A03 — Injection

Untrusted data sent to an interpreter as part of a command or query.

**SQL injection:**
```typescript
// VULNERABLE
const user = await db.query(`SELECT * FROM users WHERE email = '${email}'`)

// SAFE — parameterized
const user = await db.query('SELECT * FROM users WHERE email = $1', [email])
```

```go
// VULNERABLE
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)
db.QueryRow(query)

// SAFE
db.QueryRow("SELECT * FROM users WHERE email = $1", email)
```

**Command injection:**
```typescript
// VULNERABLE
exec(`convert ${filename} output.pdf`)

// SAFE — never pass user input to shell
execFile('convert', [filename, 'output.pdf'])
```

**Path traversal:**
```go
// VULNERABLE
filePath := filepath.Join(baseDir, userInput)

// SAFE — validate the resolved path stays within base
filePath := filepath.Join(baseDir, userInput)
resolved, err := filepath.EvalSymlinks(filePath)
if !strings.HasPrefix(resolved, baseDir) {
    return errors.New("path traversal attempt")
}
```

**Checklist:**
- [ ] All DB queries parameterized — no string concatenation
- [ ] Shell commands never include user input directly
- [ ] File paths validated against allowed directories
- [ ] XML input processed with external entity expansion disabled

---

## A04 — Insecure Design

Security flaws baked into the architecture, not just implementation bugs.

**Common patterns:**
- No rate limiting on auth endpoints → brute force
- Password reset via predictable token → account takeover
- "Security by obscurity" — hiding endpoints instead of protecting them
- Unrestricted file upload with server-side execution

**Rate limiting:**
```typescript
import rateLimit from 'express-rate-limit'

// Auth endpoints — strict
app.use('/api/auth', rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 min
  max: 10,
  message: { error: 'Too many attempts, try again later' }
}))

// API endpoints — generous but bounded
app.use('/api', rateLimit({ windowMs: 60 * 1000, max: 100 }))
```

---

## A05 — Security Misconfiguration

Default configs, verbose errors, unnecessary features left enabled.

**Security headers (Express):**
```typescript
import helmet from 'helmet'
app.use(helmet())  // sets all major security headers

// Or manually:
res.setHeader('X-Content-Type-Options', 'nosniff')
res.setHeader('X-Frame-Options', 'DENY')
res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()')
```

**Never expose stack traces:**
```typescript
// VULNERABLE
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.message, stack: err.stack })
})

// SAFE
app.use((err, req, res, next) => {
  logger.error({ err, requestId: req.id })  // log internally
  res.status(500).json({ error: 'Internal server error' })  // generic to client
})
```

**Checklist:**
- [ ] Debug mode disabled in production
- [ ] Stack traces not returned to clients
- [ ] Default credentials changed
- [ ] Security headers set
- [ ] Unnecessary HTTP methods disabled (TRACE, PUT if not used)
- [ ] Directory listing disabled on static servers

---

## A06 — Vulnerable and Outdated Components

Dependencies with known CVEs.

```bash
# Scan and fail on high/critical
npm audit --audit-level=high
govulncheck ./...
pip-audit --requirement requirements.txt

# Check for severely outdated packages
npx npm-check-updates --filter '/^(?!@types)/'
```

Flag any dependency with a CVE rated CVSS 7.0+. Check the CVE description — some are theoretical, some are directly exploitable in your usage.

---

## A07 — Identification and Authentication Failures

**Checklist:**
- [ ] No credential stuffing protection (rate limiting + lockout)
- [ ] Weak password policy (enforce minimum length ≥ 12, check against breached passwords)
- [ ] Sessions not invalidated on logout
- [ ] Session ID not rotated after privilege escalation
- [ ] "Remember me" tokens have bounded lifetime and can be revoked
- [ ] MFA available for sensitive operations

---

## A08 — Software and Data Integrity Failures

**Checklist:**
- [ ] npm/pip/go packages locked to specific versions in CI
- [ ] Dependency checksums verified (lockfiles committed)
- [ ] No deserialization of untrusted data without validation
- [ ] CI/CD pipeline has restricted write access — only specific roles can deploy

---

## A09 — Security Logging and Monitoring Failures

**What to log:**
- Authentication events (success and failure)
- Authorization failures
- Input validation failures
- High-value transactions (payments, privilege changes)

**What never to log:**
- Passwords (even hashed)
- Full credit card numbers
- Session tokens or API keys
- Sensitive PII beyond what's operationally necessary

```typescript
// VULNERABLE — logs credentials
logger.info(`Login attempt for ${email} with password ${password}`)

// SAFE
logger.info({ event: 'auth.attempt', email, success: false, ip: req.ip })
```

---

## A10 — Server-Side Request Forgery (SSRF)

When the server fetches a URL provided by the user, attackers can make it call internal services.

```typescript
// VULNERABLE
app.post('/fetch', async (req, res) => {
  const data = await fetch(req.body.url)
  res.json(await data.json())
})

// SAFE — validate against allowlist
const ALLOWED_DOMAINS = ['api.partner.com', 'cdn.example.com']

app.post('/fetch', async (req, res) => {
  const url = new URL(req.body.url)
  if (!ALLOWED_DOMAINS.includes(url.hostname)) {
    return res.status(400).json({ error: 'Domain not allowed' })
  }
  // also block private IP ranges
  const ip = await dns.resolve(url.hostname)
  if (isPrivateIP(ip)) return res.status(400).json({ error: 'Private addresses not allowed' })
  const data = await fetch(req.body.url)
  res.json(await data.json())
})
```
