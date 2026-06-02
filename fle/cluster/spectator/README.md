# fle_tools — spectator-safe FLE runtime (mod)

FLE injects its tool functions and event handlers at runtime via RCON. That
makes a live spectator impossible: a joining client never sees the injected
`script.on_event`/`on_nth_tick` registrations (→ `script-event-mismatch`
desync), and the join-save crashes because functions stored in `storage` are
not serializable.

This mod bundles the SAME functions + event handlers so the server and every
client load them identically at startup (deterministic lockstep). Functions
live in `_G` (`fle_actions`/`fle_utils`); `storage` holds only serializable
data. The functions are exposed to RCON via the `fle` remote interface.

## Build & deploy
1. `python build_mod.py` → regenerates `fle_tools/control.lua` from `fle/env`.
2. Zip it: `fle_tools_0.1.0.zip` containing a top-level `fle_tools/` folder with
   `info.json` + `control.lua`. **Must be zipped** — unzipped mods get checksum
   0 and fail multiplayer mod-matching.
3. Put the zip in the server's `--mod-directory` AND the spectator client's mod
   directory. The client (full install) must disable the DLC
   (`elevated-rails`/`quality`/`space-age`) in its `mod-list.json` to match the
   DLC-stripped FLE server.

## Python side
Set `FLE_USE_MOD=1`. FLE then calls tools via `remote.call('fle','action',...)`
instead of injecting `storage.actions.*`, and skips runtime script injection
(`lua_manager` early-returns). With the flag unset, FLE behaves exactly as
before (RCON injection), so existing non-spectator clusters are unaffected.
