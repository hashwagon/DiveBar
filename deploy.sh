#!/usr/bin/env bash
# Sync the addon into the live WoW Forever client. Pass --dry-run to preview.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${DIVEBAR_DEST:-$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/DiveBar}"

rsync -av --delete "$@" \
	--include='*.lua' --include='*.toc' --include='*.tga' --include='*.blp' \
	--exclude='*' \
	"$SRC/" "$DEST/"

echo "Deployed to: $DEST"
echo "Run /reload in game to load the changes."
