#!/usr/bin/env bash
# Rojo first: copy the Blender models from a saved place into the repo with `rojo syncback` (models.project.json:
# ServerStorage.LobbyModels, ServerStorage.LevelModels, ReplicatedStorage.ClientModels -> assets/rbxm/, one .rbxm per
# model). Never touches src/. The place must be a local file: in Studio, File > Save to File As.
#
# Refuses to delete a model file unless asked: a stale or partial save would otherwise erase models from the repo
# without a word (measured on a test place, 11 Nov: one missing model = one "Removing" line, nothing else).
#
#     ./scripts/sync-models.sh [place.rbxl] [--allow-remove]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1

PLACE="$USERPROFILE/Documents/Roblox/BlindSpot.rbxl"
ALLOW_REMOVE=0
for arg in "$@"; do
	case "$arg" in
	--allow-remove) ALLOW_REMOVE=1 ;;
	*) PLACE="$arg" ;;
	esac
done

if [ ! -f "$PLACE" ]; then
	echo "No place file at $PLACE (in Studio: File > Save to File As)"
	exit 1
fi
echo "Place: $PLACE (saved $(date -r "$PLACE" '+%Y-%m-%d %H:%M'))"

# syncback writes into each root's folder, and refuses a root whose folder does not exist yet
mkdir -p assets/rbxm/LobbyModels assets/rbxm/LevelModels assets/rbxm/ClientModels

if ! plan=$(rojo syncback models.project.json --input "$PLACE" --dry-run --list --color never 2>&1) ||
	echo "$plan" | grep -q "ERROR"; then
	echo "$plan" | grep -v DEBUG
	echo
	echo "SYNC FAILED (dry run): is every root (LobbyModels, LevelModels, ClientModels) in the place?"
	exit 1
fi
echo "$plan" | grep -E "^(Writing|Removing|Would)"

removals=$(echo "$plan" | grep -c "^Removing")
if [ "$removals" -gt 0 ] && [ "$ALLOW_REMOVE" -ne 1 ]; then
	echo
	echo "SYNC REFUSED: $removals model file(s) would be deleted. Was the place saved after the last model change?"
	echo "If these models are really gone from the game, rerun with --allow-remove."
	exit 1
fi

if ! rojo syncback models.project.json --input "$PLACE" -y --color never 2>&1 | grep -v DEBUG | tail -1; then
	echo "SYNC FAILED"
	exit 1
fi
echo
echo "SYNC OK: run ./scripts/check.sh, then commit assets/rbxm/"
