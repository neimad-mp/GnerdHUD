
# GnerdHUD

A lightweight, modular, center-screen HUD for TurtleWoW 1.12 (Vanilla), inspired by DHUD/MetaHUD/IceHUD. Keeps your eyes on your character with player/target bars, cast/mirror bars, ToT, pet, druid mana overlay, absorb tracker with optional DB import, range buckets, and class helpers. Requires no dependencies; optionally benefits from SuperWoW.

## Requirements
- TurtleWoW 1.12 client.
- Optional: SuperWoW (feature-probed) to enable file import (ExportFile/ImportFile) and raw combat log hooks.

## Installation
- Folder name must be `GnerdHUD`. Zip root equals this folder.
- Copy to `Interface\AddOns\GnerdHUD`.

## Usage
- `/ghud` or `/gnerdhud` for help.
- `/ghud vis on|off`  
- `/ghud diag` | `/ghud test` | `/ghud rebuild`  
- `/ghud options` opens a simple options panel (lock, alphas, texture, module toggles).
- Drag frames while unlocked (`/ghud unlock`), then `/ghud lock`.

## Reporting Issues
- Include runtime errors via **!GnerdBugCatcher** (`/gbc show N` or attach `imports\GBC_ErrorLog_*.txt`) and steps to reproduce.

## Modules (v0.4.4)
- AbsorbDB: Bridge for importing absorb effect definitions and wiring them to GH.Absorb.effects.
- Core bars: player/target health & power.
- Castbar: Player cast/channel bar with optional lag indicator. (lag overlay).
- ToT: target of target.
- Pet: Pet health/power bars.
- DruidMana: overlay (forms).
- Absorb tracker: (shows lowest absorb across schools); import DB via `/ghud absorb import data/AbsorbDB_Sample.csv`.
- Mirror: Breath/Exhaustion/Feign Death timers.
- Range: Lightweight target range indicator using CheckInteractDistance buckets (no polling timers, event-driven). Range buckets (≤10y/≤28y/>28y).
- ComboPoints: Rogue/Druid (cat) combo points display (0-5).
- SnD: Slice and Dice timer (Rogue).
- Shards: Warlock Soul Shard counter (bag scan, throttled on BAG_UPDATE).
- Crowd Control: Simple CC presence indicators on target (minimal placeholder from v0.4.1).
- ThreatLite: Minimal threat hint that shows "AGGRO" when target's target is you (or your pet).
- EnergyTicker: Rogue/Druid (cat): 2s tick countdown, resets on observed energy gain.
- Options: Small Options frame, not fully functional yet.

## SuperWoW Extras
- If SuperWoW is present, Absorb decrementer uses raw combat log text to reduce absorb pools on “absorbed” hits (heuristic by school keywords).

## Notes (0.4.4)
- `compat.lua` must appear before `Core.lua` in the `.toc`.
- `hardening.lua` adds safe handler wrappers and auto-applies vanilla-safe drag handlers to HUD bars after login.

## Localization
- Baseline `locales/enUS.lua`. Contributions welcome.

## License
- MIT.
