# GnerdHUD

A lightweight, modular, center-screen HUD for TurtleWoW 1.12 (Vanilla), inspired by DHUD/MetaHUD/IceHUD. Keeps your eyes on your character with compact bars and zero external dependencies. SuperWoW is optional and auto-detected.

This README reflects the 0.5.x work: (segmented arcs); 0.5.5 adds Center Cast & Mirror bars.


## Requirements
- TurtleWoW 1.12 client.
- Optional: SuperWoW (feature-probed) to enable file import (ExportFile/ImportFile) and raw combat log hooks used by some advanced modules.


## Installation
1. [Download here.](https://github.com/neimad-mp/GnerdHUD/archive/refs/heads/main.zip)
2. Rename the extracted folder to `GnerdHUD`.
3. Copy to `WoW-Directory\Interface\AddOns\`.
4. Restart WoW.

or

Install with TurtleWoW's launcher `https://github.com/neimad-mp/GnerdHUD.git`

## Usage (slash)
- `/ghud` or `/gnerdhud` shows help.
- `/ghud options` opens/closes the Options panel.
- `/ghud lock` | `/ghud unlock` toggles movers (drag while unlocked).
- `/ghud center` centers both HUD movers (safety rope if you drag off-screen).
- `/ghud diag` prints current schema/version, positions, alpha set, and toggles.
- `/ghud test` shows a short demo fill for smoke checks.
- `/ghud flash` forces full alpha briefly (useful when tuning alphas).

## Current feature set (0.5.5)
Arc Bars
- Segmented arc renderer (default 64 segments) that draws:
  - Left HUD: Player Health (green→yellow→red gradient by %HP) and Power (Mana/Rage/Energy color mapping) arcs.
  - Right HUD: Target Health and Power arcs (toggle in options).
- Scale-invariant movers; positions persist; four state-driven alpha rules.
  - Out of combat + no target (full HP)
  - Out of combat + no target (missing HP)
  - Has target
  - In combat
  
Center bars
- Cast Bar: start/stop, delays, channel start/update/stop; brief completion fade.
- Mirror Bar: breath/fatigue/feign, etc. Authoritative per-frame read of Blizzard MirrorTimer statusbars; drains underwater, refills while surfacing.
- Options → “Cast & Mirror”
  - Enable Cast Bar / Enable Mirror Bar
  - Cast Scale (width) • Mirror Scale (width)
  - Cast Alpha (multiplier) • Mirror Alpha (multiplier)
  - Per-state alpha sets for Cast and for Mirror (OOC Full, OOC Hurt, Target, Combat).
- Movers: unlocking shows demo bars for easy positioning even when inactive.

Options panel
  - (ESC and [X] close; draggable):
  - Locked checkbox (enables/disables dragging).
  - Scale slider (0.5–1.5).
  - Four alpha sliders (states above).
  - “Show Target HUD” toggle.
  - “Center” convenience button.

## Reporting issues
- Please include steps to reproduce and any runtime errors via **!GnerdBugCatcher**.
  - `/gbc show` or attach `TurtleWoW\Imports\GBC_ErrorLog_*.txt` if using SuperWoW.

## Localization
- Baseline `enUS.lua`. Contributions welcome.

## License
- MIT.
