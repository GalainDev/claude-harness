---
name: security
description: Deep security review skill covering threat modelling, OWASP top 10, secrets detection, authentication, authorization, injection, API security, dependency vulnerabilities, and secure coding patterns. Use when the user asks to "security review", "audit this", "is this secure", "check for vulnerabilities", or when implementing auth, handling user input, exposing APIs, or storing sensitive data. Goes deeper than verify — this is a dedicated security pass.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: engineering
---

# Security Skill

Security is not a checklist — it's a mindset applied at every layer. This skill runs a structured review from the outside in: what can an attacker reach, what happens when they do, and what's the blast radius.

**Scope:** This skill reviews code and architecture for security issues. It does not perform live exploitation, port scanning, or active testing against running systems.

---

## Process

### Step 1 — Understand the attack surface

Before reviewing any code, map what's exposed:

- What are the entry points? (HTTP endpoints, CLI args, file uploads, webhooks, message queues, env vars)
- What data does it handle? (PII, payment data, credentials, health data, IP)
- Who are the actors? (anonymous users, authenticated users, admins, internal services, third-party integrations)
- What's the trust boundary? (what does the system trust implicitly vs verify)

Document this before reviewing code. Surface area you don't know about is where bugs hide.

### Step 2 — Threat model

For each entry point, ask:

| Question | Why |
|----------|-----|
| What can an attacker send here? | Input validation scope |
| What happens if authentication is bypassed? | Auth criticality |
| What's the worst-case data exposure? | Impact assessment |
| What can be replayed or forged? | Token/session integrity |
| What breaks if this is called 10,000 times? | Rate limiting |

Use STRIDE as a mental checklist: **S**poofing, **T**ampering, **R**epudiation, **I**nformation disclosure, **D**enial of service, **E**levation of privilege.

### Step 3 — Code review by category

Work through the categories in [references/owasp.md](references/owasp.md). At minimum cover:

**Authentication & Session**
- Passwords hashed with bcrypt/argon2/scrypt — never SHA1/MD5, never plaintext
- Sessions use cryptographically random IDs (128+ bits)
- Session invalidated on logout and privilege change
- JWT: algorithm explicitly specified server-side, `none` algorithm rejected, expiry enforced
- MFA available on sensitive operations

**Authorization**
- Every endpoint checks authorization — not just authentication
- Authorization checked server-side, never client-side alone
- Principle of least privilege: each actor gets minimum permissions needed
- IDOR (Insecure Direct Object Reference): loading `GET /orders/123` verifies the order belongs to the requesting user
- Horizontal privilege escalation: user A cannot access user B's resources

**Injection**
- SQL: parameterized queries or ORM — never string concatenation
- NoSQL: input validated before use in queries
- Command injection: `exec`/`shell` calls never include unsanitized user input
- Path traversal: file paths sanitized, validated against allowed directories
- LDAP/XML/XPath injection: inputs escaped for the relevant context

**Input Validation & Output Encoding**
- Inputs validated at system boundaries (API layer) — not just client-side
- File uploads: MIME type validated server-side, not by extension; scanned if executable
- Output HTML-encoded to prevent XSS (React handles this by default; dangerous patterns like `dangerouslySetInnerHTML` need review)
- Redirects: destination validated against allowlist

**Secrets & Sensitive Data**
- No secrets in source code, logs, error messages, or URLs
- Secrets loaded from env vars or a secrets manager
- API keys, tokens, passwords never logged
- Sensitive data encrypted at rest (database-level or field-level for high-value data)
- TLS enforced on all external communication
- PII minimized — only collect what's needed, purge what's not

**API Security**
- Rate limiting on all public endpoints, especially auth
- Authentication on all non-public endpoints
- CORS: `Access-Control-Allow-Origin` not set to `*` for authenticated endpoints
- CSRF protection on state-mutating endpoints (especially cookie-based auth)
- Request size limits to prevent DoS
- Sensitive operations require re-authentication

**Dependency Security**
```bash
# JS
npm audit --audit-level=high

# Go
govulncheck ./...

# Python
pip-audit

# Ruby
bundle audit
```

Flag: any critical/high CVE, any dependency not updated in 2+ years, any unmaintained package with security history.

### Step 4 — Secrets scan

```bash
# Check for secrets in current diff
git diff HEAD | grep -iE '(api_key|secret|password|token|private_key)\s*[:=]\s*["\x27][^"\x27]{8,}'

# Broader scan with gitleaks (if installed)
gitleaks detect --source . --verbose

# Check git history for accidentally committed secrets
git log --all --full-history -- "*.env" "*.key" "*.pem"
```

Check for:
- Hardcoded credentials in any file
- `.env` files committed to git
- Private keys, certificates in the repo
- Internal URLs, IPs, or hostnames hardcoded

### Step 5 — Infrastructure & configuration

- HTTPS enforced, HTTP redirects to HTTPS
- Security headers set: `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`
- Debug mode / verbose errors disabled in production
- Stack traces not exposed to clients
- Default credentials changed
- Unnecessary services/ports not exposed

---

## Severity Classification

| Severity | Definition | Example | Action |
|----------|------------|---------|--------|
| **Critical** | Direct exploit, data breach, full compromise | SQL injection, auth bypass, RCE | Block ship, fix immediately |
| **High** | Significant impact with moderate effort | IDOR, stored XSS, broken access control | Fix before release |
| **Medium** | Real risk but requires specific conditions | CSRF on low-value endpoint, weak hashing | Fix in next sprint |
| **Low** | Defense-in-depth, minor exposure | Missing security header, verbose errors | Fix when convenient |
| **Info** | Best practice, no direct risk | No rate limiting on internal endpoint | Note for improvement |

---

## Report Format

```
## Security Review — [Component/PR]

### Attack Surface
[Entry points, actors, trust boundaries]

### Findings

#### [SEVERITY] Finding title
- **Location:** file.go:42
- **Description:** What the issue is
- **Impact:** What an attacker can do
- **Reproduction:** Minimal steps to demonstrate
- **Fix:** Concrete code change or approach

### No Issues Found In
- [Areas explicitly reviewed and found clean]

### Not Reviewed
- [Areas outside scope or requiring runtime access]

### Summary
[X critical, Y high, Z medium — ship/don't ship recommendation]
```

---

## Quick Wins — Fix These First

If time is limited, prioritize in this order:

1. Any hardcoded secret or credential
2. SQL/command injection from user input
3. Authentication bypass
4. Missing authorization on sensitive endpoints
5. Sensitive data in logs or error responses
6. Critical CVE in a dependency
7. Exposed debug endpoints or verbose errors in production

See [references/owasp.md](references/owasp.md) for the full OWASP Top 10 with code examples.
See [references/secure-patterns.md](references/secure-patterns.md) for language-specific secure coding patterns.
