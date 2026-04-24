# claude-harness

Portable Claude Code setup — skills, hooks, and global config. Clone on any machine and run `./install.sh`.

## Skills

| Skill | Slash command | Triggers on |
|-------|--------------|-------------|
| `git` | `/commit` | Commits, PRs, branching, rebase, history |
| `code-review` | `/review` | "review this", "check before I merge", PR review |
| `verify` | `/verify` | After any implementation; "check", "verify", "test" |
| `security` | `/security` | "security review", "audit this", auth, API exposure |
| `secrets` | `/secrets` | `.env` files, API keys, env vars, project scaffolding |
| `design` | `/design` | Set active design system for the project |
| `frontend-design` | `/frontend-design` | Any new React component, page, or UI work |
| `polish` | `/polish` | "polish this", "finishing touches", pre-ship UI pass |
| `debug` | `/debug` | Bug reports, unexpected errors, wrong output |
| `react-frontend` | — | JSX/TSX, hooks, Tailwind, state, Next.js, Vite, React Query |
| `golang-backend` | — | Go code, APIs, concurrency, error handling, testing |
| `spec-driven` | — | "spec this out", BDD, ATDD, RLAIF loop |
| `domain-driven-design` | — | Bounded contexts, aggregates, domain modelling |
| `software-architecture` | — | System design, layering, API design, events |
| `pebbles` | — | Pebbles repo (pb CLI + Dolt) |

### Design systems

Set via `/design` or by writing `.claude/design.json` to the project root:

```json
{ "system": "ai-saas" }
```

| Key | Aesthetic | Best for |
|-----|-----------|---------|
| `minimal-clean` | Figma, Linear, Raycast | Productivity tools, docs, content-first |
| `brutalist` | Raw, high-contrast, flat color | Editorial, portfolios, strong brand opinions |
| `glassmorphism` | Frosted glass, blurs, depth | Consumer apps, mobile-first |
| `corporate-saas` | Stripe, Notion, Vercel | B2B SaaS, marketing sites, dashboards |
| `dark-modern` | VS Code, Vercel dashboard | Dev tools, internal dashboards |
| `ai-saas` | Cursor, Perplexity, Linear | AI-first products, chat interfaces, agent UIs |

## Hooks

All hooks are purely regex-based — deterministic, zero latency, no API key required.

| Hook | Event | Scope | Blocks |
|------|-------|-------|--------|
| `block-prompt-injection.sh` | PreToolUse | all tools | Instruction override phrases, role hijack, synthetic system turns, exfiltration instructions |
| `block-destructive.sh` | PreToolUse | Bash | `rm -rf` on root/home, pipe-to-shell, data exfiltration, reverse shells, cron/LaunchAgent writes, destructive SQL |
| `block-write-risks.sh` | PreToolUse | Write, Edit | Writes to system paths, LaunchAgents, authorized_keys, private key material, curl\|sh in shell rc files |
| `block-sensitive-paths.sh` | PreToolUse | Read, Glob, Grep | `.env`, private keys, AWS credentials, PEM files, service account keys |
| `block-output-injection.sh` | PostToolUse | WebFetch | Injection phrases in fetched web content |

## Conventions

### Environment variables

Projects use `.env.schema` + `.env` — never `.env.example`:

```bash
# .env.schema — commit this. Keys with comments, no values.
DATABASE_URL=        # PostgreSQL connection string
JWT_SECRET=          # 32+ byte random secret — openssl rand -hex 32

# .env — never commit. Real values only. Gitignored.
DATABASE_URL=postgres://...
JWT_SECRET=abc123...
```

Add `.env` to `.gitignore`, never `.env.schema`. Use `/secrets` for full guidance.

### Git

Use `/commit` for all commits — the `git` skill defines the commit format. Verbose or minimal style, always asks.

## Install

```bash
git clone https://github.com/GalainDev/claude-harness.git ~/claude-harness
cd ~/claude-harness
./install.sh
```

Re-run after pulling updates — symlinks keep skills and hooks in sync automatically.

### Install modes

```bash
./install.sh               # merge hooks into existing ~/.claude/settings.json
./install.sh --overwrite   # replace hooks block entirely from harness (use when reverting)
./install.sh --dry-run     # preview changes without applying
```

**merge** (default) — adds harness hooks on top of whatever is already in `~/.claude/settings.json`. Safe for first install and routine updates.

**overwrite** — replaces the entire `hooks` block with exactly what the harness defines. Non-hook settings (`enabledPlugins`, `effortLevel`, etc.) are preserved. Use this when reverting to a specific version.

## Versions

| Tag | Description |
|-----|-------------|
| `v1.0.0` | Base harness — skills, block-destructive, block-sensitive-paths |
| `v1.1.0` | Comprehensive security hooks — prompt injection, write risks, output injection, versioned install |

### Reverting to a previous version

```bash
git checkout v1.0.0
./install.sh --overwrite
```

To return to latest:

```bash
git checkout main
./install.sh --overwrite
```

## Scripts

```bash
# Start a new spec
./skills/spec-driven/scripts/new-spec.sh "My Feature"

# Run RLAIF evaluation loop against a spec
./skills/spec-driven/scripts/rlaif-loop.sh specs/my-feature.md

# Run full verification
./skills/verify/scripts/verify.sh

# Dry-run install (preview without making changes)
./install.sh --dry-run
```

## Structure

```
claude-harness/
├── install.sh
├── settings.json              # hooks config
├── CLAUDE.md                  # global Claude instructions → ~/CLAUDE.md
├── hooks/
│   ├── block-prompt-injection.sh
│   ├── block-destructive.sh
│   ├── block-write-risks.sh
│   ├── block-sensitive-paths.sh
│   └── block-output-injection.sh
└── skills/
    ├── git/
    ├── code-review/
    ├── verify/
    ├── security/
    ├── secrets/
    ├── design/
    ├── frontend-design/
    ├── polish/
    ├── debug/
    ├── react-frontend/
    │   └── design/
    │       └── systems/
    │           ├── minimal-clean/
    │           ├── brutalist/
    │           ├── glassmorphism/
    │           ├── corporate-saas/
    │           ├── dark-modern/
    │           └── ai-saas/
    ├── golang-backend/
    ├── spec-driven/
    ├── domain-driven-design/
    ├── software-architecture/
    └── pebbles/
```
