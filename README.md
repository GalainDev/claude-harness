# claude-harness

Portable Claude Code setup — skills, hooks, and global config. Clone on any machine and run `./install.sh`.

## Skills

| Skill | Triggers on |
|-------|-------------|
| `react-frontend` | Components, hooks, styling, state, testing, Next.js, Vite, TypeScript in React |
| `golang-backend` | Go code, APIs, concurrency, error handling, testing, toolchain |
| `verify` | After any implementation; "check", "verify", "test", "review" |
| `spec-driven` | "spec this out", BDD, ATDD, spec-first, RLAIF loop, iterative refinement |

## Hooks

All hooks are purely regex-based — deterministic, zero latency, no API key required.

| Hook | Event | Scope | Blocks |
|------|-------|-------|--------|
| `block-prompt-injection.sh` | PreToolUse | all tools | Instruction override phrases, role hijack, synthetic system turns, exfiltration instructions in command/content/url |
| `block-destructive.sh` | PreToolUse | Bash | `rm -rf` on root/home, pipe-to-shell, outbound data exfiltration, reverse shells, cron/LaunchAgent writes, history wipe, destructive SQL |
| `block-write-risks.sh` | PreToolUse | Write, Edit | Writes to system paths, LaunchAgents, authorized_keys, private key material in content, curl\|sh in shell rc files |
| `block-sensitive-paths.sh` | PreToolUse | Read, Glob, Grep | `.env`, private keys, AWS credentials, PEM files, service account keys |
| `block-output-injection.sh` | PostToolUse | WebFetch | Injection phrases in fetched web content before Claude processes it |

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

This replaces the hooks block in `~/.claude/settings.json` with exactly what that version defined, and relinks all hook symlinks to the checked-out version.

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
    ├── react-frontend/
    ├── golang-backend/
    ├── verify/
    └── spec-driven/
```
