#!/usr/bin/env bash
# Launch the native Factorio GUI client and connect it to the local FLE server as a spectator.
# This is the window you render/stream. Uses the SAME isolated mod dir as launch_server.sh so
# mods match exactly (no desync).
set -euo pipefail

FACTORIO_DATA_DIR="${FACTORIO_DATA_DIR:-$HOME/Library/Application Support/factorio}"
FLE_MODS_DIR="${FLE_MODS_DIR:-$FACTORIO_DATA_DIR/fle_mods}"
GAME_PORT="${FLE_GAME_PORT:-34197}"
FACTORIO_BIN="${FACTORIO_BIN:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"

if [[ ! -x "$FACTORIO_BIN" ]]; then
  echo "Factorio binary not found at: $FACTORIO_BIN (set FACTORIO_BIN)" >&2
  exit 1
fi

echo "→ connecting spectator client to localhost:$GAME_PORT (mods: $FLE_MODS_DIR)"
exec "$FACTORIO_BIN" --mp-connect "localhost:$GAME_PORT" --mod-directory "$FLE_MODS_DIR"
