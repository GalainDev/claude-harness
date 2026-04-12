---
name: secrets
description: Secrets management skill covering the .env.schema convention, gitignore rules, secret rotation, CI/CD secret handling, and detecting committed secrets. Triggers when the user scaffolds a project, creates env files, asks about API keys, environment variables, secret storage, or says ".env". Always use .env.schema (not .env.example) — never commit real values. This skill takes precedence over any default .env.example behavior.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: engineering
---

# Secrets Skill

Secrets are the highest-impact attack surface in most apps. A leaked key means full account compromise, data breach, or cloud bill explosion — and rotation is painful. Get the structure right upfront.

**Core rule:** structure is committed, values never are.

---

## The Schema/Secret Split

Two files. Always.

```bash
# .env.schema — COMMIT THIS
# Keys with comments only. No values. Tells Claude and teammates what config exists and why.
STRIPE_SECRET_KEY=        # Stripe secret key — get from dashboard, rotate quarterly
DATABASE_URL=             # PostgreSQL — format: postgres://user:pass@host/db
JWT_SECRET=               # 32+ byte random secret — generate: openssl rand -hex 32
NEXT_PUBLIC_APP_URL=      # Public app URL — no trailing slash
REDIS_URL=                # Redis connection string — format: redis://host:port

# .env — NEVER COMMIT
# Real values only. Gitignored. Local machine only.
STRIPE_SECRET_KEY=sk_live_...
DATABASE_URL=postgres://...
```

**Why schema, not example:**
- `.env.example` implies "copy and fill in" — developers often commit it with real values by mistake
- `.env.schema` is unambiguously documentation — keys with comments, no values, no copy-paste trap
- Claude Code's hook explicitly allows reading `.env.schema` but blocks `.env`
- Inspired by [varlock](https://github.com/galain/varlock) — typed, validated env schema

---

## Process

### When scaffolding a new project

1. Create `.env.schema` with all required keys, each with a comment explaining:
   - What it's for
   - Where to get it
   - Format/constraints
   - Rotation cadence (for secrets)

2. Create `.gitignore` entries:
```bash
# Secrets — never commit
.env
.env.local
.env.production
.env.staging
.env*.local

# .env.schema is committed intentionally — do NOT add it here
```

3. Never create `.env.example`. If you see one in the repo, flag it.

### When adding a new env var

1. Add it to `.env.schema` with a comment before using it in code
2. Add it to `.env` locally with the real value
3. Document it in CI/CD (GitHub Actions secrets, Vercel env, etc.)

### When reviewing code for secret hygiene

Check:
- [ ] `.env.schema` exists and is committed
- [ ] `.env` is in `.gitignore`
- [ ] No hardcoded secrets in source (API keys, passwords, tokens)
- [ ] No secrets in comments or test fixtures
- [ ] CI/CD uses platform secret storage, not plaintext in workflow files

---

## .env.schema Format

```bash
# Group related vars with a comment header

# ── Database ──────────────────────────────────────────────────────────────────
DATABASE_URL=             # PostgreSQL connection — postgres://user:pass@host/db
DATABASE_POOL_SIZE=       # Connection pool size — default: 10

# ── Auth ──────────────────────────────────────────────────────────────────────
JWT_SECRET=               # 32+ byte random secret — openssl rand -hex 32
JWT_EXPIRY=               # Token expiry — default: 7d

# ── External APIs ─────────────────────────────────────────────────────────────
STRIPE_SECRET_KEY=        # Stripe secret key — dashboard > Developers > API keys
STRIPE_WEBHOOK_SECRET=    # Stripe webhook secret — from webhook endpoint setup

# ── App Config ────────────────────────────────────────────────────────────────
NEXT_PUBLIC_APP_URL=      # Public URL — no trailing slash
NODE_ENV=                 # development | staging | production
```

---

## Where Secrets Live Per Environment

| Environment | Storage |
|-------------|---------|
| Local dev | `.env` on your machine, gitignored |
| CI/CD | GitHub Actions secrets / repo environment variables |
| Preview/staging | Vercel env vars, Railway env, Fly secrets |
| Production | Platform env vars or secret manager (AWS Secrets Manager, GCP Secret Manager, Doppler, Infisical) |

Never store secrets in:
- Source code (even commented out)
- `docker-compose.yml` values (use `env_file` pointing to gitignored file)
- Workflow YAML plaintext
- Log output

---

## Detecting Committed Secrets

```bash
# Scan staged changes before committing
git diff --staged | grep -iE \
  '(api_key|apikey|secret|password|passwd|token|private_key|access_key)\s*[:=]\s*[^\s]{8,}'

# Scan full history (run once on new repos)
git log --all -p | grep -iE \
  '(api_key|secret|password|token)\s*[:=]\s*["\x27][^"\x27]{12,}'
```

If a secret is found in history:
1. **Rotate the secret immediately** — assume it's compromised
2. Remove from history with `git filter-repo` (not `filter-branch`)
3. Force-push and notify all forks/mirrors
4. History rewrite does not remove from GitHub's cache — rotation is non-negotiable

---

## Rotation Policy

| Secret type | Rotate when |
|-------------|-------------|
| API keys | On any suspected exposure; quarterly otherwise |
| Database passwords | On team member departure; annually otherwise |
| JWT secrets | On suspected token forgery; annually otherwise |
| Webhook secrets | On suspected replay attack |
| OAuth secrets | On suspected client compromise |

---

## Red Flags — Flag Immediately

- `.env.example` with non-placeholder values (e.g. `sk_live_...`, real URLs with credentials)
- Secrets in `docker-compose.yml` environment block as literals
- `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` anywhere in source
- `password` or `secret` keys in committed JSON/YAML config files
- Secrets passed as CLI args in scripts (appear in `ps aux` and shell history)
- Base64-encoded secrets in source (not actually hidden)
