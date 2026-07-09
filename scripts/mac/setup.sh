#!/usr/bin/env bash
# Build + install everything the native macOS Factorio needs to host an FLE game that a
# spectator client can join (and that the agent drives over RCON):
#   1. build the `fle_tools` mod (control.lua) and zip it
#   2. install it into an ISOLATED mod dir (base + fle_tools only, DLC disabled) — NOT the
#      default mods dir, so the user's own mods (which can crash a headless server) are excluded
#      and the server + spectator load an identical, minimal mod set (no desync)
#   3. install FLE's scenarios into the Factorio user scenarios dir
#
# One-time (re-run after changing FLE Lua). Then use launch_server.sh / launch_spectator.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPECTATOR_DIR="$REPO_ROOT/fle/cluster/spectator"
FACTORIO_DATA_DIR="${FACTORIO_DATA_DIR:-$HOME/Library/Application Support/factorio}"
FLE_MODS_DIR="${FLE_MODS_DIR:-$FACTORIO_DATA_DIR/fle_mods}"

echo "→ building fle_tools mod"
python "$SPECTATOR_DIR/build_mod.py"

VERSION="$(python -c "import json; print(json.load(open('$SPECTATOR_DIR/fle_tools/info.json'))['version'])")"
ZIP_NAME="fle_tools_${VERSION}.zip"

echo "→ zipping $ZIP_NAME (mods must be zipped — unzipped get checksum 0 and fail MP matching)"
( cd "$SPECTATOR_DIR" && rm -f "$ZIP_NAME" && zip -q -r "$ZIP_NAME" fle_tools )

echo "→ installing isolated mod dir → $FLE_MODS_DIR"
mkdir -p "$FLE_MODS_DIR"
rm -f "$FLE_MODS_DIR"/fle_tools_*.zip
cp "$SPECTATOR_DIR/$ZIP_NAME" "$FLE_MODS_DIR/"
# base + fle_tools enabled; DLC disabled (server is DLC-stripped; both sides must match). We can't
# delete the Steam install's DLC like the Docker image does, so disable it here instead.
cat > "$FLE_MODS_DIR/mod-list.json" <<'JSON'
{
  "mods": [
    { "name": "base", "enabled": true },
    { "name": "elevated-rails", "enabled": false },
    { "name": "quality", "enabled": false },
    { "name": "space-age", "enabled": false },
    { "name": "fle_tools", "enabled": true }
  ]
}
JSON

SCEN_DIR="$FACTORIO_DATA_DIR/scenarios"
echo "→ installing scenarios → $SCEN_DIR"
mkdir -p "$SCEN_DIR"
for scen in default_lab_scenario open_world; do
  rm -rf "${SCEN_DIR:?}/$scen"
  cp -R "$REPO_ROOT/fle/cluster/scenarios/$scen" "$SCEN_DIR/"
done

# Tidy up: drop any fle_tools accidentally left in the DEFAULT mods dir by an older setup.
rm -f "$FACTORIO_DATA_DIR/mods"/fle_tools_*.zip 2>/dev/null || true

cat <<EOF

✓ setup complete
  mod dir:   $FLE_MODS_DIR  (base + fle_tools, DLC off — used by BOTH server and spectator)
  scenarios: $SCEN_DIR/{default_lab_scenario,open_world}

Next:
  bash scripts/mac/launch_server.sh        # terminal 1: headless RCON host
  bash scripts/mac/launch_spectator.sh     # GUI: joins + renders the game (stream this window)
EOF
