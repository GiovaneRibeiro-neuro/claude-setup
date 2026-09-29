#!/usr/bin/env bash
# install.sh — symlink tracked claude-setup files into ~/.claude/
#
# Usage: bash install.sh [--claude-dir <path>]
#   --claude-dir  Target directory (default: ~/.claude)
#
# Each tracked item is symlinked from the repo into the target dir.
# Anything already there that is NOT already our symlink gets backed up
# to ~/.claude-setup-backup/<timestamp>/ before being replaced.
#
# "Merge dirs" (e.g. skills/) are handled entry-by-entry so that
# pre-existing content in the target directory (e.g. Pocock skills)
# is preserved alongside repo content.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude-dir) CLAUDE_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

BACKUP_DIR="${HOME}/.claude-setup-backup/$(date +%Y%m%d-%H%M%S)"

# Items symlinked directly into $CLAUDE_DIR.
# Keep in sync with what git tracks.
DIRECT_LINKS=(
    CLAUDE.md
    README.md
    agents
    commands
    contexts
    rules
    scripts
    settings.json
    notes
)

# Directories whose *contents* are symlinked individually into $CLAUDE_DIR/<dir>/.
# This preserves any pre-existing entries (e.g. Pocock skills installed by Claude Code)
# alongside repo-tracked entries.
MERGE_DIRS=(
    skills
)

echo "Repo:   $REPO_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

mkdir -p "$CLAUDE_DIR"

# Link one item (source path -> target path), backing up any conflicting entry.
link_item() {
    local source="$1"
    local target="$2"
    local label="$3"

    # Already the correct symlink — nothing to do.
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        echo "  ok    $label"
        return
    fi

    # Exists but is not our symlink — back up before replacing.
    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
        echo "  bkp   $label  → $BACKUP_DIR/$(basename "$target")"
    fi

    ln -s "$source" "$target"
    echo "  link  $label"
}

# --- Direct symlinks ---
for item in "${DIRECT_LINKS[@]}"; do
    source="$REPO_DIR/$item"
    target="$CLAUDE_DIR/$item"

    if [[ ! -e "$source" ]]; then
        echo "  skip  $item  (not found in repo)"
        continue
    fi

    link_item "$source" "$target" "$item"
done

# --- Merge-dir symlinks (entry-by-entry) ---
for dir in "${MERGE_DIRS[@]}"; do
    source_dir="$REPO_DIR/$dir"

    if [[ ! -d "$source_dir" ]]; then
        echo "  skip  $dir/  (not found in repo)"
        continue
    fi

    target_dir="$CLAUDE_DIR/$dir"

    # If the target is currently a whole-directory symlink (legacy install),
    # back it up and replace with a real directory so we can merge into it.
    if [[ -L "$target_dir" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target_dir" "$BACKUP_DIR/$dir"
        echo "  bkp   $dir  → $BACKUP_DIR/$dir  (symlink -> merge-dir)"
        mkdir -p "$target_dir"
    elif [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    # Symlink each entry in the repo dir individually.
    for entry in "$source_dir"/*; do
        [[ -e "$entry" ]] || continue  # glob matched nothing
        entry_name="$(basename "$entry")"
        link_item "$source_dir/$entry_name" "$target_dir/$entry_name" "$dir/$entry_name"
    done
done

echo ""
echo "Done."
[[ -d "$BACKUP_DIR" ]] && echo "Backups: $BACKUP_DIR"
echo ""
echo "Git workflow: cd $REPO_DIR  (not ~/.claude)"
