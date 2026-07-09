#!/usr/bin/env bash
# Launch the native macOS Factorio as a headless RCON host for FLE — rendered by a spectator
# client that joins it (Multiplayer → Connect → localhost). RCON is bound to localhost only.
#
# Prereqs: run scripts/mac/setup.sh once (installs the fle_tools mod + scenarios).
# Drive it from research-environments with:
#   FACTORIO_SERVER_ADDRESS=127.0.0.1 FACTORIO_SERVER_PORT=27015 FLE_USE_MOD=1 \
#     uv run eval factorio-v1 --harness.id rlm -m <model> -n 1 -r 1
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="$REPO_ROOT/fle/cluster/config"
FACTORIO_DATA_DIR="${FACTORIO_DATA_DIR:-$HOME/Library/Application Support/factorio}"
FLE_MODS_DIR="${FLE_MODS_DIR:-$FACTORIO_DATA_DIR/fle_mods}"

SCENARIO="${FLE_SCENARIO:-default_lab_scenario}"
GAME_PORT="${FLE_GAME_PORT:-34197}"
RCON_PORT="${FLE_RCON_PORT:-27015}"
RCON_PASSWORD="${FLE_RCON_PASSWORD:-factorio}"

# Default Steam install on Apple Silicon; override with FACTORIO_BIN.
FACTORIO_BIN="${FACTORIO_BIN:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
if [[ ! -x "$FACTORIO_BIN" ]]; then
  echo "Factorio binary not found at: $FACTORIO_BIN" >&2
  echo "Set FACTORIO_BIN to your factorio.app .../Contents/MacOS/factorio" >&2
  exit 1
fi
if [[ ! -f "$FLE_MODS_DIR/mod-list.json" ]]; then
  echo "Isolated mod dir not found: $FLE_MODS_DIR — run scripts/mac/setup.sh first." >&2
  exit 1
fi

echo "→ launching Factorio server"
echo "  binary:   $FACTORIO_BIN"
echo "  version:  $("$FACTORIO_BIN" --version | head -1)"
echo "  scenario: $SCENARIO   game udp:$GAME_PORT   rcon:127.0.0.1:$RCON_PORT"
echo "  spectate: open Factorio → Multiplayer → Connect to address → localhost:$GAME_PORT"
echo

# No --use-server-whitelist: a local spectator has no factorio.com account (server-settings sets
# require_user_verification=false). RCON is localhost-bound so it isn't exposed.
exec "$FACTORIO_BIN" \
  --start-server-load-scenario "$SCENARIO" \
  --port "$GAME_PORT" \
  --rcon-bind "127.0.0.1:$RCON_PORT" \
  --rcon-password "$RCON_PASSWORD" \
  --server-settings "$CONFIG_DIR/server-settings.json" \
  --map-gen-settings "$CONFIG_DIR/map-gen-settings.json" \
  --map-settings "$CONFIG_DIR/map-settings.json" \
  --server-adminlist "$CONFIG_DIR/server-adminlist.json" \
  --mod-directory "$FLE_MODS_DIR"
