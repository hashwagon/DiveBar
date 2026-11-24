#!/usr/bin/env bash
# Sync the addon into a WoW client's AddOns folder. Pass --dry-run to preview.
# The destination comes from $DIVEBAR_DEST, or from the first line of .deploy-dest.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${DIVEBAR_DEST:-}"
if [[ -z "$DEST" && -f "$SRC/.deploy-dest" ]]; then
	DEST="$(head -n 1 "$SRC/.deploy-dest")"
	DEST="${DEST%$'\r'}"
	DEST="${DEST/#\~/$HOME}"
fi
if [[ -z "$DEST" ]]; then
	echo "Set DIVEBAR_DEST or write the path to .deploy-dest, e.g." >&2
	echo "  .../World of Warcraft/_forever_/Interface/AddOns/DiveBar" >&2
	exit 1
fi

rsync -av --delete "$@" \
	--include='*.lua' --include='*.toc' --include='*.tga' --include='*.blp' \
	--exclude='*' \
	"$SRC/" "$DEST/"

echo "Deployed to: $DEST"
echo "Run /reload in game to load the changes."
