#!/usr/bin/env bash
# block-destructive.sh — PreToolUse hook for Claude Code
# Targeted safety net for catastrophic or non-recoverable Bash operations.
#
# Input: JSON via stdin with keys: tool_name, tool_input
# Exit 0 = allow, Exit 2 = block

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ "$TOOL" != "Bash" ]]; then
  exit 0
fi

block() {
  echo "BLOCKED (destructive): $1" >&2
  exit 2
}

# ── Nuclear file deletions ────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'rm\s+.*(-rf|-fr)\s+(\/|~\/?\s|~$|\$HOME\/?\s|\$HOME$)'; then
  block "rm -rf on / or home root is not allowed."
fi
if echo "$COMMAND" | grep -qE 'rm\s+.*(-rf|-fr)\s+~\/\*'; then
  block "rm -rf ~/* would nuke your home directory."
fi

# ── Pipe to shell (code injection) ───────────────────────────────────────────
if echo "$COMMAND" | grep -qE '(curl|wget)\s+.*\|\s*(bash|sh|zsh|fish)'; then
  block "Piping curl/wget to a shell is blocked — download and inspect first."
fi
if echo "$COMMAND" | grep -qE 'base64\s+(-d|--decode)\s*\|?\s*(bash|sh|eval)'; then
  block "base64 decode piped to shell is blocked."
fi

# ── Outbound data exfiltration ────────────────────────────────────────────────
# curl/wget posting data that comes from env, files, or subshells
if echo "$COMMAND" | grep -qE '(curl|wget)\s+.+(-d|--data|--data-raw|-F|--form)\s+["\x27]?\$\('; then
  block "curl/wget with subshell expansion in POST data blocked — possible exfiltration."
fi
if echo "$COMMAND" | grep -qE '(curl|wget)\s+.+(-d|--data|--data-raw)\s+@'; then
  block "curl/wget --data @file blocked — possible file exfiltration."
fi
# env/printenv piped out
if echo "$COMMAND" | grep -qE '(env|printenv|export)\s*\|?\s*(curl|wget|nc|ncat|socat)'; then
  block "Piping environment variables to network tool blocked."
fi
# netcat / socat outbound with input redirection
if echo "$COMMAND" | grep -qE '(nc|ncat|netcat)\s+(-[a-zA-Z]*e|-e)\s*(bash|sh|/bin)'; then
  block "Reverse shell via netcat blocked."
fi
if echo "$COMMAND" | grep -qE 'bash\s+-i\s+>&\s*/dev/tcp/'; then
  block "Reverse shell via /dev/tcp blocked."
fi

# ── Persistence / startup modifications ──────────────────────────────────────
if echo "$COMMAND" | grep -qE '(crontab\s+-[re]|>/etc/cron|>/var/spool/cron)'; then
  block "Crontab modification blocked."
fi
if echo "$COMMAND" | grep -qE '(>|>>|tee)\s+.*\.ssh/authorized_keys'; then
  block "Writing to authorized_keys blocked."
fi
if echo "$COMMAND" | grep -qE '(>|>>|tee)\s+.*(LaunchAgents|LaunchDaemons)/.*\.plist'; then
  block "Writing LaunchAgent/Daemon plist blocked."
fi

# ── chmod/chown on macOS system paths ────────────────────────────────────────
if echo "$COMMAND" | grep -qE '(chmod|chown).*\s+(/System|/Library|/usr/bin|/usr/sbin|/bin|/sbin|/etc)'; then
  block "chmod/chown on system paths is blocked."
fi

# ── Destructive SQL on likely production targets ──────────────────────────────
if echo "$COMMAND" | grep -qiE '(DROP\s+(DATABASE|SCHEMA))\s+(?!test|dev|local|tmp)'; then
  block "DROP DATABASE/SCHEMA blocked — looks like a non-dev database."
fi

# ── Covering tracks ───────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'history\s+-[cw]'; then
  block "Clearing shell history blocked."
fi

exit 0
