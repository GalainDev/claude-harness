#!/usr/bin/env bash
# block-write-risks.sh — PreToolUse hook for Claude Code
#
# Guards Write and Edit tool calls against:
#   - Writing to system / OS paths
#   - Writing to persistence / startup paths (LaunchAgents, cron, shell hooks)
#   - Writing to SSH authorized_keys
#   - Writing private key material into files
#   - Embedding curl|sh or wget|sh patterns in shell rc files
#
# Exit 0 = allow, Exit 2 = block

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

block() {
  echo "BLOCKED (write-risks): $1" >&2
  exit 2
}

# File path being written to
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Content being written (Write = "content", Edit = "new_string")
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# ── Dangerous destination paths ───────────────────────────────────────────────
if [[ -n "$FILE_PATH" ]]; then
  DANGEROUS_PATH_PATTERNS=(
    # macOS / Unix system directories
    '^/System/'
    '^/usr/(bin|sbin|lib)/'
    '^/bin/'
    '^/sbin/'
    '^/etc/'
    '^/Library/LaunchDaemons/'
    '^/Library/LaunchAgents/'

    # User persistence paths
    "$HOME/Library/LaunchAgents/"
    '\.plist$.*LaunchAgent'

    # Cron
    '^/etc/cron'
    '^/var/spool/cron'

    # SSH
    '\.ssh/authorized_keys$'
    '\.ssh/config$'

    # Shell startup files — allow normal edits but flag if content is suspicious
    # (handled in content check below, not here)
  )

  for pattern in "${DANGEROUS_PATH_PATTERNS[@]}"; do
    # Expand $HOME in pattern
    expanded="${pattern/\$HOME/$HOME}"
    if echo "$FILE_PATH" | grep -qE "$expanded"; then
      block "Write to protected path blocked: $FILE_PATH"
    fi
  done
fi

# ── Dangerous content patterns ────────────────────────────────────────────────
if [[ -n "$CONTENT" ]]; then
  DANGEROUS_CONTENT_PATTERNS=(
    # Private key material
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'

    # Pipe-to-shell download stagers
    '(curl|wget)\s+.*\|\s*(bash|sh|zsh|fish)'
    '(curl|wget)\s+.*-[a-zA-Z]*o[a-zA-Z]*\s+.*\|\s*(bash|sh)'

    # Base64-encoded payload execution
    'base64\s+(-d|--decode)\s*\|?\s*(bash|sh|eval)'
    'echo\s+[A-Za-z0-9+/=]{20,}\s*\|\s*base64.*\|\s*(bash|sh)'

    # Reverse shell one-liners
    'bash\s+-i\s+>&\s*/dev/tcp/'
    '/dev/tcp/[0-9]'
    'nc\s+-[a-zA-Z]*e\s+(bash|sh|/bin)'
  )

  # Only check content if writing to a shell rc / profile file
  IS_SHELL_RC=false
  if echo "$FILE_PATH" | grep -qE '\.(bash_profile|bashrc|zshrc|zprofile|profile|bash_login)$'; then
    IS_SHELL_RC=true
  fi

  for pattern in "${DANGEROUS_CONTENT_PATTERNS[@]}"; do
    # Private key and reverse shell patterns apply everywhere
    if echo "$CONTENT" | grep -qE -- "$pattern"; then
      block "Dangerous content in write blocked (pattern: $pattern)"
    fi
  done

  # Pipe-to-shell in shell rc files is especially dangerous
  if $IS_SHELL_RC; then
    if echo "$CONTENT" | grep -qE -- '(curl|wget).*\|.*(bash|sh|zsh)'; then
      block "curl|sh stager in shell rc file blocked: $FILE_PATH"
    fi
  fi
fi

exit 0
