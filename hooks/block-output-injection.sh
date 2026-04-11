#!/usr/bin/env bash
# block-output-injection.sh — PostToolUse hook
# Scans Read/WebFetch/Bash output for injection patterns before Claude sees it.
# Exit 0 = allow, Exit 2 = block
set -euo pipefail
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r ".tool_name // empty")
case "$TOOL" in WebFetch) ;; *) exit 0 ;; esac
block() { echo "BLOCKED (output-injection): $1" >&2; exit 2; }
RESULT=$(echo "$INPUT" | jq -r '
  if (.tool_result | type) == "string" then .tool_result
  elif (.tool_result.content | type) == "string" then .tool_result.content
  elif (.tool_result | type) == "array" then [.tool_result[] | .text // .content // ""] | join("
")
  else (.tool_result | tostring) end
' 2>/dev/null || echo "")
[[ -z "$RESULT" ]] && exit 0
PATTERNS=(
  'ignore (all |your )?(previous|prior|above|earlier) instructions'
  'disregard (all |your )?(previous|prior|above|earlier) instructions'
  'forget (everything|all) (above|prior|previous)'
  'new (task|objective|goal|primary directive)\s*:'
  'your (new|real|actual|true) (instructions?|task|objective|goal)\s*(is|are)?\s*:'
  'from now on (you|act|behave)'
  'act as (a |an )?(different|new|unrestricted|jailbroken)'
  'you are now'
  '^\s*\[SYSTEM\]'
  '^\s*<\s*/?system\s*>'
  '^\s*###\s*System'
  '^\s*SYSTEM\s*PROMPT\s*:'
  'exfiltrate'
  '(send|transmit|upload|post)\s+(the |all |this )?(above|previous|following|content|file|data|secrets?|credentials?|keys?|tokens?)\s+(to|via|using)\s+(http|curl|email|slack|webhook)'
  'leak (the |this )?(following|above|content|data|file)'
  'disable (the |your )?(hook|filter|block|safety|security)'
  'bypass (the |your )?(hook|filter|block|safety|security)'
)
for pattern in "${PATTERNS[@]}"; do
  if echo "$RESULT" | grep -qiE -- "$pattern"; then
    SRC=$(echo "$INPUT" | jq -r ".tool_input.file_path // .tool_input.url // .tool_input.command // "unknown"")
    block "Pattern found in $TOOL output ($SRC): \"$pattern\""
  fi
done
exit 0
