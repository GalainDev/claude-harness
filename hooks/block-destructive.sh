#!/usr/bin/env bash
# block-destructive.sh — PreToolUse hook for Claude Code
# Targeted safety net for truly catastrophic, non-recoverable operations.
# Does NOT block powerful-but-legitimate git/process operations — those are
# intentional in an autonomous --dangerously-skip-permissions workflow.
#
# Input: JSON via stdin with keys: tool_name, tool_input
# Exit 0 = allow, Exit 2 = block (message shown to Claude)

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ "$TOOL" != "Bash" ]]; then
  exit 0
fi

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

# ── Nuclear file deletions (OS / home root) ───────────────────────────────────
# Block rm targeting /, ~, or $HOME directly — not all rm -rf
if echo "$COMMAND" | grep -qE 'rm\s+.*(-rf|-fr)\s+(\/|~\/?\s|~$|\$HOME\/?\s|\$HOME$)'; then
  block "rm -rf on / or home root is not allowed."
fi

# Block wiping the entire home directory contents
if echo "$COMMAND" | grep -qE 'rm\s+.*(-rf|-fr)\s+~\/\*'; then
  block "rm -rf ~/* would nuke your home directory."
fi

# ── Pipe to shell (code injection risk) ──────────────────────────────────────
if echo "$COMMAND" | grep -qE '(curl|wget)\s+.*\|\s*(bash|sh|zsh|fish)'; then
  block "Piping curl/wget to a shell is blocked — download and inspect first."
fi

# ── chmod/chown on macOS system paths ────────────────────────────────────────
if echo "$COMMAND" | grep -qE '(chmod|chown).*\s+(/System|/Library|/usr/bin|/usr/sbin|/bin|/sbin|/etc)'; then
  block "chmod/chown on system paths is blocked."
fi

# ── Destructive SQL on likely production targets ──────────────────────────────
# Only block if command looks like it's targeting a real DB (not a test/dev one)
if echo "$COMMAND" | grep -qiE '(DROP\s+(DATABASE|SCHEMA))\s+(?!test|dev|local|tmp)'; then
  block "DROP DATABASE/SCHEMA blocked — looks like a non-dev database. Confirm manually."
fi

exit 0
