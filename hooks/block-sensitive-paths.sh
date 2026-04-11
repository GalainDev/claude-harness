#!/usr/bin/env bash
# block-sensitive-paths.sh — PreToolUse hook for Claude Code
# Blocks Read, Glob, and Grep on sensitive paths.
#
# Sensitive paths are configured in ~/.claude/sensitive-paths.conf
# (one pattern per line, supports glob-style wildcards via grep -E).
# If the config file doesn't exist, built-in defaults apply.
#
# Exit 0 = allow, Exit 2 = block

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only intercept file-reading tools
case "$TOOL" in
  Read|Glob|Grep) ;;
  *) exit 0 ;;
esac

# Extract the path being accessed (field name differs per tool)
PATH_ARG=$(echo "$INPUT" | jq -r '
  .tool_input.file_path //
  .tool_input.path //
  .tool_input.pattern //
  empty
')

[[ -z "$PATH_ARG" ]] && exit 0

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

# ── Built-in sensitive patterns ───────────────────────────────────────────────
BUILTIN_PATTERNS=(
  '(^|/)\.env(\.|$)'           # .env, .env.local, .env.production, etc.
  '(^|/)\.env\b'
  '\bsecrets?\b'               # secrets/, secret.yaml, etc.
  '(^|/)\.ssh/'                # SSH keys
  'id_rsa|id_ed25519|id_ecdsa' # private key files
  '\.pem$'                     # PEM certificates / private keys
  '\.p12$|\.pfx$'              # PKCS12 keystores
  'credentials\.json$'         # GCP / AWS credential files
  '\.aws/credentials'
  'serviceAccountKey'          # Firebase service account keys
  'vault\.hcl$|vault\.json$'   # Vault config
)

for pattern in "${BUILTIN_PATTERNS[@]}"; do
  if echo "$PATH_ARG" | grep -qE "$pattern"; then
    block "Access to sensitive path blocked: $PATH_ARG — matches pattern: $pattern"
  fi
done

# ── Project-level custom blocklist ────────────────────────────────────────────
CONF="${HOME}/.claude/sensitive-paths.conf"
if [[ -f "$CONF" ]]; then
  while IFS= read -r line; do
    # Skip blank lines and comments
    [[ -z "$line" || "$line" == \#* ]] && continue
    if echo "$PATH_ARG" | grep -qE "$line"; then
      block "Access to sensitive path blocked: $PATH_ARG — matches custom rule: $line"
    fi
  done < "$CONF"
fi

exit 0
