# Changelog

## v0.4.5
- Core UX: Promoted the temporary Options bridge into a stable `/ghud` router (`modules/Slash.lua`). It cooperates with the original handler and guarantees that `options|opt|o` opens the panel.
- Options: Added “Reset Positions” (calls Core’s `ResetPositions()` when available) and “Reload UI” buttons.
- Note: `hardening.lua` remains in place; we’ll make a deeper internal sweep later and can remove hardening once all modules are explicitly Vanilla-safe.

## v0.4.4
- Hardening and compat improvements; guaranteed `/ghud options` via bridge; fixed Lua first-line issues.
- Hardening: Added `hardening.lua` with safe script wrappers (`GnerdHUD_SafeSetScript`, `GnerdHUD_MakeDraggable`) and a post-login pass that applies vanilla-safe drag handlers to known HUD bars. Also validates module registry and provides a harmless fallback for `GetPlayerBuffName` if compat didn't load.
- Stability: Kept `modules/OptionsBridge.lua` to route `/ghud options` reliably across core variants.
- Packaging: `.toc` now loads `hardening.lua` after `Core.lua`. Version bumped to 0.4.4.

## v0.4.3
- Fix: Options module registered as a table; options bridge ensures `/ghud options` opens the panel.
- Cleanup: Removed stray filename-only first lines from Lua/TOC files that caused parse errors.
- Fix (Vanilla compat): Converted remaining `SetScript` drag handlers to 1.12-safe style (no parameters; use global `this`). Options panel is movable and no longer errors when dragged.
- Fix (Visibility): `/ghud vis on|off` keeps visibility consistent with alpha rules; `/ghud diag` prints per-bar state.
- Fix: Options panel rewritten for Lua 5.0 / Vanilla handler semantics (no `self` param; uses global `this`). Draggable again, no load errors.
- Fix: Added `compat.lua` shim implementing `GetPlayerBuffName()` via tooltip scan to prevent nil-call errors when gaining/losing buffs or changing forms.
- Change: `.toc` now loads `compat.lua` before `Core.lua`.
- Change: Normalize `.toc` to reference `Core.lua` and bump version to 0.4.3.

## v0.4.2
- Fix: core.lua loader syntax (mis-nested OnEvent branches). This removed init errors like “attempt to index global ‘GnerdHUD’ (a nil value)” in modules. No feature changes.

## v0.4.1
- New: Energy Ticker module (2-second countdown for energy classes; resets on observed gains).
- Core: version bump, schema v5; wiring to UNIT_ENERGY and UNIT_DISPLAYPOWER.
- Docs: README updated.

## v0.4.0
- Added Options panel (lock, alpha sliders, texture cycler, module toggles).
- New modules: ComboPoints, Slice and Dice timer, Warlock Shards, CrowdControl (placeholder), ThreatLite.
- Absorb: sample CSV + lightweight decrementer via SuperWoW RAW_COMBATLOG.
- Polished bar factory, movers, slash commands.
