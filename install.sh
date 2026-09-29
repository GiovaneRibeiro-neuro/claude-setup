#!/usr/bin/env bash
# install.sh — symlink tracked claude-setup files into ~/.claude/
#
# Usage: bash install.sh [--claude-dir <path>]
#   --claude-dir  Target directory (default: ~/.claude)
#
# Each tracked item is symlinked from the repo into the target dir.
# Anything already there that is NOT already our symlink gets backed up
# to ~/.claude-setup-backup/<timestamp>/ before being replaced.

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

# Tracked items to symlink. Keep in sync with what git tracks.
LINKS=(
    CLAUDE.md
    README.md
    agents
    commands
    contexts
    rules
    scripts
    settings.json
    skills
)

echo "Repo:   $REPO_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

mkdir -p "$CLAUDE_DIR"

for item in "${LINKS[@]}"; do
    target="$CLAUDE_DIR/$item"
    source="$REPO_DIR/$item"

    if [[ ! -e "$source" ]]; then
        echo "  skip  $item  (not found in repo)"
        continue
    fi

    # Already the correct symlink — nothing to do
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        echo "  ok    $item"
        continue
    fi

    # Exists but is not our symlink — back up before replacing
    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$item"
        echo "  bkp   $item  → $BACKUP_DIR/$item"
    fi

    ln -s "$source" "$target"
    echo "  link  $item"
done

echo ""
echo "Done."
[[ -d "$BACKUP_DIR" ]] && echo "Backups: $BACKUP_DIR"
echo ""
echo "Git workflow: cd $REPO_DIR  (not ~/.claude)"
