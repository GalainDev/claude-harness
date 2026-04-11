#!/usr/bin/env bash
# install.sh — install the claude harness to ~/.claude
#
# Usage:
#   ./install.sh                  # merge hooks into existing settings.json
#   ./install.sh --overwrite      # replace settings.json entirely from harness
#   ./install.sh --dry-run        # preview changes without applying
#   ./install.sh --overwrite --dry-run

set -euo pipefail

DRY_RUN=false
SETTINGS_MODE="merge"   # merge | overwrite

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --overwrite) SETTINGS_MODE="overwrite" ;;
    --merge)     SETTINGS_MODE="merge" ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

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

echo ""
echo "Installing claude harness from: $HARNESS_DIR"
echo "Target: $CLAUDE_DIR"
echo "Settings mode: $SETTINGS_MODE"
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

# ── settings.json ─────────────────────────────────────────────────────────────
SETTINGS="$CLAUDE_DIR/settings.json"
HARNESS_SETTINGS="$HARNESS_DIR/settings.json"

if $DRY_RUN; then
  echo "  [dry-run] $SETTINGS_MODE settings: $HARNESS_SETTINGS → $SETTINGS"
elif [[ "$SETTINGS_MODE" == "overwrite" ]]; then
  # Overwrite: harness settings.json becomes the source of truth.
  # Non-hook keys from the existing file (enabledPlugins, effortLevel, etc.)
  # are preserved — only the hooks block is replaced.
  if [[ ! -f "$SETTINGS" ]]; then
    cp "$HARNESS_SETTINGS" "$SETTINGS"
    info "Created: $SETTINGS"
  elif command -v jq &>/dev/null; then
    # Keep non-hooks keys from existing, take hooks entirely from harness
    MERGED=$(jq -s '
      .[0] as $existing | .[1] as $harness |
      $existing | .hooks = $harness.hooks
    ' "$SETTINGS" "$HARNESS_SETTINGS")
    echo "$MERGED" > "$SETTINGS"
    info "Overwrote hooks in: $SETTINGS (non-hook settings preserved)"
  else
    cp "$HARNESS_SETTINGS" "$SETTINGS"
    info "Overwrote: $SETTINGS (jq not found — full replace)"
  fi
else
  # Merge (default): add harness hooks on top of existing, dedup by content
  if [[ ! -f "$SETTINGS" ]]; then
    cp "$HARNESS_SETTINGS" "$SETTINGS"
    info "Created: $SETTINGS"
  elif command -v jq &>/dev/null; then
    MERGED=$(jq -s '
      .[0] as $e | .[1] as $h |
      ($e * $h) |
      .hooks.PreToolUse = (
        (($e.hooks.PreToolUse // []) + ($h.hooks.PreToolUse // []))
        | unique
      ) |
      .hooks.PostToolUse = (
        (($e.hooks.PostToolUse // []) + ($h.hooks.PostToolUse // []))
        | unique
      )
    ' "$SETTINGS" "$HARNESS_SETTINGS")
    echo "$MERGED" > "$SETTINGS"
    info "Merged hooks into: $SETTINGS"
  else
    warning "jq not found — please manually merge hooks from $HARNESS_SETTINGS into $SETTINGS"
    echo ""
    echo "Add this to your ~/.claude/settings.json:"
    cat "$HARNESS_SETTINGS"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  Harness installed successfully."
echo ""
echo "  Skills:"
for skill_dir in "$HARNESS_DIR/skills"/*/; do
  echo "    • $(basename "$skill_dir")"
done
echo ""
echo "  Hooks:"
for hook in "$HARNESS_DIR/hooks"/*.sh; do
  echo "    • $(basename "$hook")"
done
echo ""
echo "  Settings mode: $SETTINGS_MODE"
echo ""
echo "  To revert to a previous release:"
echo "    git checkout v<tag>"
echo "    ./install.sh --overwrite"
echo "════════════════════════════════════════"
echo ""
