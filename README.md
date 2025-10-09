# README.md
# GnerdHUD

A lightweight, modular, center-screen HUD for TurtleWoW 1.12 (Vanilla), inspired by DHUD/MetaHUD/IceHUD. Keeps your eyes on your character with player/target bars, cast/mirror bars, ToT, pet, druid mana overlay, absorb tracker with optional DB import, range buckets, and class helpers.

## Requirements
- TurtleWoW 1.12 client.
- Optional: SuperWoW (feature-probed) to enable file import (ExportFile/ImportFile) and raw combat log hooks.

## Installation
- Folder name must be `GnerdHUD`. Zip root equals this folder.
- Copy to `Interface\AddOns\GnerdHUD`.

## Usage
- `/ghud` or `/gnerdhud` for help.
- `/ghud options` opens a simple options panel (lock, alphas, texture, module toggles).
- Drag frames while unlocked (`/ghud unlock`), then `/ghud lock`.

## Reporting Issues
- Include runtime errors via **!GnerdBugCatcher** (`/gbc show N` or attach `imports\GBC_ErrorLog_*.txt`) and steps to reproduce.

## Modules (v0.4.1)
- Core bars: player/target health & power.
- Castbar (lag overlay), Mirror timers.
- ToT, Pet.
- Druid Mana overlay (forms).
- Absorb tracker (shows lowest absorb across schools); import DB via `/ghud absorb import data/AbsorbDB_Sample.csv`.
- Range buckets (≤10y/≤28y/>28y).
- Combo Points (Rogue/Druid Feral).
- Slice and Dice timer (Rogue).
- Shards counter (Warlock).
- Crowd Control indicator (minimal placeholder).
- Threat-lite (AGGRO when target’s target is you/pet).
- Energy Ticker (Rogue/Druid Cat): 2s tick countdown, resets on observed energy gain.

## SuperWoW Extras
- If SuperWoW is present, Absorb decrementer uses raw combat log text to reduce absorb pools on “absorbed” hits (heuristic by school keywords).

## Localization
- Baseline `locales/enUS.lua`. Contributions welcome.

## License
- MIT.
