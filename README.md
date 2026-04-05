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

`hooks/block-destructive.sh` — PreToolUse hook that blocks:
- `rm -rf` and root/home directory deletions
- `git push --force`, `git reset --hard`, `git clean -f`, force branch deletion
- Destructive SQL (`DROP TABLE`, `TRUNCATE`)
- `kill -9` / `pkill -9`
- `chmod`/`chown` on system paths
- `curl | bash` patterns

## Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-harness.git ~/claude-harness
cd ~/claude-harness
./install.sh
```

Re-run after pulling updates — symlinks keep skills in sync automatically.

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
├── settings.json         # hooks config
├── CLAUDE.md             # global Claude instructions → ~/CLAUDE.md
├── hooks/
│   └── block-destructive.sh
└── skills/
    ├── react-frontend/
    │   └── SKILL.md
    ├── golang-backend/
    │   └── SKILL.md
    ├── verify/
    │   ├── SKILL.md
    │   └── scripts/verify.sh
    └── spec-driven/
        ├── SKILL.md
        └── scripts/
            ├── new-spec.sh
            └── rlaif-loop.sh
```
