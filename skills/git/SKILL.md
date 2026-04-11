---
name: git
description: Git workflow skill covering commits, branching, PRs, and history management. Use when the user runs /commit, asks to commit, create a branch, open a PR, review git history, resolve a merge conflict, cherry-pick, or rebase. Commits are detailed, human-authored-quality messages — always asks verbose or minimal style first. Never adds AI attribution.
user-invocable: true
metadata:
  author: galain
  version: 1.0.0
  category: engineering
---

# Git Skill

Commits are the canonical source of truth for what changed and why. A good commit message
should let any engineer understand the full context of a change without needing to read the diff.

## Process

### Step 1 — Ask for style preference

Use the AskUserQuestion tool to ask:

> "Verbose or minimal commit?
> - **Verbose**: full body with what changed, why, impact, and any caveats
> - **Minimal**: single conventional commit line only"

### Step 2 — Analyze changes

Run these in sequence:
```bash
git status
git diff --staged
git diff HEAD
git log --oneline -5   # understand recent commit style and context
```

If nothing is staged, ask the user which files to include before proceeding.

### Step 3 — Draft the message

#### Verbose format
```
<type>(<scope>): <short imperative summary under 72 chars>

## What changed
<Per-file or per-area breakdown of actual changes. Be specific — name functions,
components, endpoints, tables. Not "updated files" but "replaced useSWR with
React Query in UserList — removes the stale-while-revalidate edge case that was
causing double renders on window focus">

## Why
<The reason for this change. Include the problem it solves, the decision made,
and any alternatives considered and rejected.>

## Impact
<What this affects: downstream components, API consumers, database schema,
performance, bundle size, behavior changes. If none, say "No external impact.">

## Breaking changes
<If any. Otherwise omit this section.>

## Testing
<How this was verified: tests added, manual testing done, edge cases checked.>
```

#### Minimal format
```
<type>(<scope>): <short imperative summary under 72 chars>
```

**Conventional commit types:**
- `feat` — new capability
- `fix` — bug fix
- `refactor` — structural change, no behavior change
- `perf` — performance improvement
- `test` — adding or fixing tests
- `docs` — documentation only
- `chore` — build, deps, config (no production code change)
- `style` — formatting only
- `revert` — reverting a previous commit

### Step 4 — Stage and commit

Stage only relevant files (never `git add -A` blindly):
```bash
git add <specific files>
git commit -m "$(cat <<'EOF'
<message here>
EOF
)"
```

### Step 5 — Verify
```bash
git log --oneline -1   # confirm commit landed
git show --stat HEAD   # confirm right files included
```

---

## Rules

- **No AI attribution** — no "Co-Authored-By", no "Generated with", no tool references
- **Imperative mood** in subject: "add feature" not "added feature" or "adds feature"  
- **Subject line ≤ 72 characters**
- **No period** at end of subject line
- **Blank line** between subject and body in verbose mode
- **Do not commit** unrelated files — if the diff contains unrelated changes, ask the user which to include
- **Do not amend** a previous commit unless the user explicitly asks

---

## Red Flags — Ask Before Proceeding

- Nothing staged and `git status` shows untracked files mixed with modified files — clarify scope
- Changes span multiple unrelated features — suggest splitting into multiple commits
- Staged files include `.env`, secrets, or build artifacts — warn and do not include
- Working on `main` or `master` directly — note this and ask if intentional
