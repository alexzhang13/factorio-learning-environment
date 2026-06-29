# Native macOS FLE host (rendered + streamable)

Run FLE against the **native Factorio** on this Mac instead of the headless x86 Docker server.
The native binary hosts the game over RCON; a second native Factorio client **joins as a
spectator and renders it in real time** — that window is what you screen-capture / stream. No
emulation, and server + client are the same Steam build so versions always match.

This is the host side for the `factorio-v1` verifiers environment
(`research-environments/environments/factorio_v1`).

## How it works

FLE connects to *any* Factorio server over RCON via `FACTORIO_SERVER_ADDRESS` / `FACTORIO_SERVER_PORT`.
With `FLE_USE_MOD=1` it uses the `fle_tools` mod's `remote.call('fle', …)` interface instead of
injecting Lua over RCON at runtime — so a spectator client that joins the running game stays in
lockstep (no `script-event-mismatch` desync, no join-save crash). Both server and spectator load the
same `fle_tools` mod from the shared Factorio user-data dir.

## One-time setup

```bash
bash scripts/mac/setup.sh
```
Builds the `fle_tools` mod, zips it, and installs it + the FLE scenarios into
`~/Library/Application Support/factorio/{mods,scenarios}` (override with `FACTORIO_DATA_DIR`).
Re-run after changing FLE's Lua tools.

## The 3-terminal run

1. **Host (terminal 1):**
   ```bash
   bash scripts/mac/launch_server.sh
   ```
   Headless RCON host on `34197` (game, UDP) / `127.0.0.1:27015` (RCON). Override with
   `FLE_GAME_PORT` / `FLE_RCON_PORT` / `FLE_SCENARIO` / `FACTORIO_BIN`.

2. **Spectator / stream window (GUI):** open Factorio → **Multiplayer → Connect to address** →
   `localhost:34197`. This window renders the live game — stream it (OBS, QuickTime, etc.).
   Optional agent-follow camera + HUD: `uv run python -m fle.overlay` (or `fle/overlay.py`).

3. **Agent (terminal 2):** from `research-environments` (after
   `uv pip install --prerelease=allow -e ./environments/factorio_v1`):
   ```bash
   uv run --no-sync eval factorio-v1 --harness.id rlm -m <model> -n 1 -r 1 \
     --taskset.task-keys '["iron_plate_throughput"]' --taskset.num-agents 1 --max-turns 16
   ```
   For multi-agent, add `--taskset.num-agents 4 --harness.max-depth 1`. The taskset connects to
   `127.0.0.1:27015` with `FLE_USE_MOD=1` by default — no env vars needed.

## Notes

- **Single game = single rollout** (`-n 1 -r 1`): there is one native server. For parallel
  rollouts use FLE's Docker cluster instead (`fle cluster start -n N`) and point
  `--taskset.factorio-port` at a container's RCON port.
- **Version match:** server and spectator client must be the exact same Factorio version. Using the
  same Steam install for both (the default here) guarantees it.
- **Security:** RCON is bound to `127.0.0.1`; the game UDP port has no whitelist (so a local
  spectator with no factorio.com account can join). Don't expose `34197` to untrusted networks.
