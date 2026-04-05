#!/usr/bin/env bash
# block-destructive.sh — PreToolUse hook for Claude Code
# Blocks dangerous commands when running in --dangerously-skip-permissions mode.
# Input: JSON via stdin with keys: tool_name, tool_input
# Exit 0 = allow, Exit 2 = block (message printed to stderr shown to Claude)

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only inspect Bash tool calls
if [[ "$TOOL" != "Bash" ]]; then
  exit 0
fi

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

# ── Destructive file operations ──────────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r'; then
  block "rm -rf is not allowed. Use trash or explicit file paths."
fi

if echo "$COMMAND" | grep -qE '^\s*rm\s+(-[^-\s]*\s+)*(/|~|\$HOME)'; then
  block "Deleting from root or home directory directly is not allowed."
fi

# ── Git destructive operations ────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'git\s+(push\s+.*--force|push\s+.*-f\b)'; then
  block "Force push is blocked. Use --force-with-lease or ask the user."
fi

if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  block "git reset --hard is blocked. Stage changes or stash first."
fi

if echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*f'; then
  block "git clean -f is blocked — it permanently deletes untracked files."
fi

if echo "$COMMAND" | grep -qE 'git\s+branch\s+(-D|--delete\s+-f)'; then
  block "Force branch deletion is blocked. Confirm with user first."
fi

# ── Database nukes ────────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  block "Destructive SQL (DROP/TRUNCATE) is blocked. Confirm with user."
fi

# ── Process killing ───────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'kill\s+-9|killall\s+-9|pkill\s+-9'; then
  block "SIGKILL (-9) is blocked. Use SIGTERM first or ask the user."
fi

# ── chmod/chown on system paths ───────────────────────────────────────────────
if echo "$COMMAND" | grep -qE '(chmod|chown).*\s(/etc|/usr|/bin|/sbin|/System|/Library)'; then
  block "chmod/chown on system paths is blocked."
fi

# ── Pipe to shell patterns ────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'curl.*\|\s*(bash|sh|zsh)|wget.*\|\s*(bash|sh|zsh)'; then
  block "curl/wget piped to shell is blocked. Download and inspect the script first."
fi

exit 0
