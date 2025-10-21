# GnerdHUD

A lightweight, modular, center-screen HUD for TurtleWoW 1.12 (Vanilla), inspired by DHUD/MetaHUD/IceHUD. Keeps your eyes on your character with compact bars and zero external dependencies. SuperWoW is optional and auto-detected.

This README reflects the 0.5.x “Ice layout” work: segmented arc bars that mirror IceHUD’s look and feel while remaining 1.12-legal.

## Requirements
- TurtleWoW 1.12 client.
- Optional: SuperWoW (feature-probed) to enable file import (ExportFile/ImportFile) and raw combat log hooks used by some advanced modules.

## Installation
- Folder name must be `GnerdHUD`. Zip root equals this folder.
- Copy to `Interface\AddOns\GnerdHUD`.

## Usage (slash)
- `/ghud` or `/gnerdhud` shows help.
- `/ghud options` opens/closes the Options panel.
- `/ghud lock` | `/ghud unlock` toggles movers (drag while unlocked).
- `/ghud center` centers both HUD movers (safety rope if you drag off-screen).
- `/ghud diag` prints current schema/version, positions, alpha set, and toggles.
- `/ghud test` shows a short demo fill for smoke checks.
- `/ghud flash` forces full alpha briefly (useful when tuning alphas).

## Current feature set (0.5.x “Ice layout”, Milestone 0)
- Segmented arc renderer (default 64 segments) that draws:
  - Left HUD: Player Health (green→yellow→red gradient by %HP) and Power (Mana/Rage/Energy color mapping) arcs.
  - Right HUD: Target Health and Power arcs (optional; see Options).
- Pixel-perfect movers:
  - Drag from screen center offsets (no grid/snap).
  - Drag math is scale-invariant; movers visually resize with the scale so placement “feels” right at any size.
  - Positions and options persist across reloads/logins.
  - `/ghud center` safely recenters both movers.
- Visibility & alpha rules:
  - Out of combat + no target (full HP)
  - Out of combat + no target (missing HP)
  - Has target
  - In combat
- Options panel (ESC and [X] close; draggable):
  - Locked checkbox (enables/disables dragging).
  - Scale slider (0.5–1.5).
  - Four alpha sliders (states above).
  - “Show Target HUD” toggle.
  - “Center Both” convenience button.

## Legacy modules (from 0.4.x)
The 0.4.x straight-bar modules remain in the codebase but are not the focus of the 0.5.x Ice layout milestone. As we progress through Milestone 1+, cast/mirror bars, Energy Tick, Combo Points, ToT/Pet, etc., will be re-introduced with Ice-style visuals.

## Reporting issues
- Please include steps to reproduce and any runtime errors via **!GnerdBugCatcher**.
  - `/gbc show 10` or attach `Interface\AddOns\!GnerdBugCatcher\imports\GBC_ErrorLog_*.txt`.

## Notes for Vanilla (1.12) environment
- Handlers use Vanilla semantics (`this`, `event`, `arg1..n`), no `self,event` parameters.
- Movers are not clamped to screen (clamping on 1.12 can cause scale-dependent jumps). Use `/ghud center` if needed.

## Localization
- Baseline `locales/enUS.lua`. Contributions welcome.

## License
- MIT.
