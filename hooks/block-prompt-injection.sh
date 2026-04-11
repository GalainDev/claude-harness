#!/usr/bin/env bash
# block-prompt-injection.sh — PreToolUse hook for Claude Code
#
# Scans ALL tool inputs for prompt injection patterns — text embedded in file
# content, command output, or external data that tries to hijack Claude's
# behaviour.  Purely regex-based: deterministic, zero latency, no API needed.
#
# Exit 0 = allow, Exit 2 = block

set -euo pipefail

INPUT=$(cat)

block() {
  echo "BLOCKED (prompt-injection): $1" >&2
  exit 2
}

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only scan the fields that carry user-controlled / external content.
# Scanning the entire JSON would false-positive on script source files that
# happen to contain these phrases as code or comments.
RAW=$(echo "$INPUT" | jq -r '
  [
    .tool_input.command,          # Bash
    .tool_input.content,          # Write (new file content)
    .tool_input.new_string,       # Edit (replacement text only — not old_string, which is repo content)
    .tool_input.prompt,           # Agent / subagent
    .tool_input.url               # WebFetch
  ]
  | map(select(. != null and . != ""))
  | join("\n")
' 2>/dev/null || echo "")

# ── Instruction override patterns ─────────────────────────────────────────────
# These phrases appear in jailbreaks and prompt injection payloads embedded
# in files, web pages, or command output that Claude reads and then acts on.
INJECTION_PATTERNS=(
  # Classic override openers
  'ignore (all |your )?(previous|prior|above|earlier) instructions'
  'disregard (all |your )?(previous|prior|above|earlier) instructions'
  'forget (everything|all) (above|prior|previous)'
  'new (task|objective|goal|primary directive)\s*:'
  'your (new|real|actual|true) (instructions?|task|objective|goal)\s*(is|are)?\s*:'

  # Role / persona hijack
  'you are now\b'
  'from now on (you|act|behave)'
  'act as (a |an )?(different|new|unrestricted|jailbroken|dan\b)'
  '\bDAN\b.*jailbreak'
  'developer mode\s*(enabled|on|activated)'

  # Synthetic system-turn injection
  '^\s*\[SYSTEM\]'
  '^\s*<\s*/?system\s*>'
  '^\s*###\s*System'
  '^\s*SYSTEM\s*PROMPT\s*:'

  # Exfiltration-via-instruction patterns
  'send (the |all )?(above|previous|this|these|following) (to|via)\s+(http|curl|email)'
  'exfiltrate'
  'leak (the |this )?(following|above|content|data|file)'
)

for pattern in "${INJECTION_PATTERNS[@]}"; do
  if echo "$RAW" | grep -qiE "$pattern"; then
    block "Prompt injection pattern detected: \"$pattern\""
  fi
done

exit 0
