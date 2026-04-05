#!/usr/bin/env bash
# install.sh — install the claude harness to ~/.claude
# Safe to re-run; uses symlinks so the git repo stays the source of truth.
#
# Usage: ./install.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[install]${NC} $1"; }
warning() { echo -e "${YELLOW}[warning]${NC} $1"; }

link() {
  local src="$1"
  local dst="$2"
  if $DRY_RUN; then
    echo "  [dry-run] symlink $src → $dst"
    return
  fi
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warning "Backing up existing $dst → ${dst}.backup"
    mv "$dst" "${dst}.backup"
  fi
  ln -sfn "$src" "$dst"
  info "Linked: $dst → $src"
}

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if $DRY_RUN; then
    echo "  [dry-run] copy $src → $dst (if missing)"
    return
  fi
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    info "Installed: $dst"
  else
    warning "Skipping $dst (already exists — merge manually if needed)"
  fi
}

echo ""
echo "Installing claude harness from: $HARNESS_DIR"
echo "Target: $CLAUDE_DIR"
[[ $DRY_RUN == true ]] && echo "(dry run — no changes will be made)"
echo ""

# ── Skills ────────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/skills"
for skill_dir in "$HARNESS_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  link "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
done

# ── Hooks ─────────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/hooks"
for hook in "$HARNESS_DIR/hooks"/*.sh; do
  hook_name=$(basename "$hook")
  link "$hook" "$CLAUDE_DIR/hooks/$hook_name"
  [[ $DRY_RUN == false ]] && chmod +x "$CLAUDE_DIR/hooks/$hook_name"
done

# ── CLAUDE.md (global) ────────────────────────────────────────────────────────
link "$HARNESS_DIR/CLAUDE.md" "$HOME/CLAUDE.md"

# ── .mcp.json (user-level MCP servers) ───────────────────────────────────────
link "$HARNESS_DIR/.mcp.json" "$HOME/.mcp.json"

# ── settings.json — merge hooks into existing settings ────────────────────────
SETTINGS="$CLAUDE_DIR/settings.json"
HARNESS_SETTINGS="$HARNESS_DIR/settings.json"

if $DRY_RUN; then
  echo "  [dry-run] merge hooks from $HARNESS_SETTINGS → $SETTINGS"
elif [[ ! -f "$SETTINGS" ]]; then
  cp "$HARNESS_SETTINGS" "$SETTINGS"
  info "Created: $SETTINGS"
else
  # Merge hooks key using jq if available
  if command -v jq &>/dev/null; then
    MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS" "$HARNESS_SETTINGS")
    echo "$MERGED" > "$SETTINGS"
    info "Merged hooks into: $SETTINGS"
  else
    warning "jq not found — please manually merge hooks from $HARNESS_SETTINGS into $SETTINGS"
    echo ""
    echo "Add this to your ~/.claude/settings.json:"
    cat "$HARNESS_SETTINGS"
  fi
fi

echo ""
echo "════════════════════════════════════════"
echo "  Harness installed successfully."
echo ""
echo "  Skills available:"
for skill_dir in "$HARNESS_DIR/skills"/*/; do
  echo "    • $(basename "$skill_dir")"
done
echo ""
echo "  Hook: block-destructive.sh active on all Bash tool calls"
echo "  CLAUDE.md: installed at ~/CLAUDE.md (global context)"
echo "════════════════════════════════════════"
echo ""
