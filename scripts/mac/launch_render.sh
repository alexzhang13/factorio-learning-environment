#!/usr/bin/env bash
# Launch ONE rendered Factorio that hosts the FLE game AND exposes RCON, so the agent drives the
# very window you watch — no separate headless server + spectator (and no data-dir lock clash).
#
# Factorio only exposes RCON for a hosted multiplayer game; `--host` renders (unlike the headless
# `--start-server`), and accepts the same `--rcon-*` server options. `--host` loads a SAVE, so a
# save is generated from the FLE map-gen on first run.
#
# Drive it from research-environments (after install):
#   uv run --no-sync eval factorio-v1 --harness.id rlm -m anthropic/claude-sonnet-4.6 -n 1 -r 1 \
#     --taskset.task-keys '["open_play"]' --max-turns 100
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="$REPO_ROOT/fle/cluster/config"
FACTORIO_DATA_DIR="${FACTORIO_DATA_DIR:-$HOME/Library/Application Support/factorio}"
FLE_MODS_DIR="${FLE_MODS_DIR:-$FACTORIO_DATA_DIR/fle_mods}"
SAVE="${FLE_SAVE:-$FACTORIO_DATA_DIR/saves/fle_world.zip}"
RCON_PORT="${FLE_RCON_PORT:-27015}"
RCON_PASSWORD="${FLE_RCON_PASSWORD:-factorio}"
FLE_CONFIG="${FLE_CONFIG:-$FACTORIO_DATA_DIR/fle_config.ini}"
FACTORIO_BIN="${FACTORIO_BIN:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"

if [[ ! -x "$FACTORIO_BIN" ]]; then
  echo "Factorio binary not found at: $FACTORIO_BIN (set FACTORIO_BIN)" >&2; exit 1
fi
if [[ ! -f "$FLE_MODS_DIR/mod-list.json" ]]; then
  echo "Isolated mod dir not found: $FLE_MODS_DIR — run scripts/mac/setup.sh first." >&2; exit 1
fi

# Generate the host save from the FLE open-world map-gen if it doesn't exist yet.
if [[ ! -f "$SAVE" ]]; then
  echo "→ creating host save: $SAVE"
  mkdir -p "$(dirname "$SAVE")"
  "$FACTORIO_BIN" --create "$SAVE" \
    --map-gen-settings "$CONFIG_DIR/map-gen-settings.json" \
    --map-settings "$CONFIG_DIR/map-settings.json" \
    --mod-directory "$FLE_MODS_DIR"
fi

# --host (the rendered, menu-equivalent host) ignores --rcon-bind; RCON for a menu-hosted game is
# enabled via config.ini's local-rcon-socket/password. Generate a minimal config that keeps the
# default data paths and turns RCON on.
if [[ ! -f "$FLE_CONFIG" ]]; then
  echo "→ writing RCON-enabled config: $FLE_CONFIG"
  cat > "$FLE_CONFIG" <<EOF
[path]
read-data=__PATH__system-read-data__
write-data=__PATH__system-write-data__

[other]
local-rcon-socket=127.0.0.1:$RCON_PORT
local-rcon-password=$RCON_PASSWORD
EOF
fi

echo "→ hosting rendered game + RCON"
echo "  save:  $SAVE"
echo "  rcon:  127.0.0.1:$RCON_PORT   (FLE connects here)"
echo "  This window IS the game — the agent builds in it. No spectator needed."
echo

exec "$FACTORIO_BIN" \
  --host "$SAVE" \
  --config "$FLE_CONFIG" \
  --server-settings "$CONFIG_DIR/server-settings.json" \
  --mod-directory "$FLE_MODS_DIR"
