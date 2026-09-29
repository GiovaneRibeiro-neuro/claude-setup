#!/usr/bin/env bash
# uninstall.sh — remove symlinks created by install.sh
#
# Usage: bash uninstall.sh [--claude-dir <path>]
#
# Only removes symlinks that point back into this repo.
# Runtime files in ~/.claude/ are never touched.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude-dir) CLAUDE_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

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

echo "Removing symlinks from: $CLAUDE_DIR"
echo ""

for item in "${LINKS[@]}"; do
    target="$CLAUDE_DIR/$item"
    source="$REPO_DIR/$item"

    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        rm "$target"
        echo "  removed  $item"
    else
        echo "  skip     $item  (not our symlink)"
    fi
done

echo ""
echo "Done. Runtime files in $CLAUDE_DIR are untouched."
echo "To restore a backup: cp -r ~/.claude-setup-backup/<timestamp>/* $CLAUDE_DIR/"
