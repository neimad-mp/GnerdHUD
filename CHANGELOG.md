# Changelog

## v0.5.5 (Center Cast & Mirror) — M1e refresh
Status: stable in smoke tests on TurtleWoW 1.12.

New
- Center Cast Bar (Vanilla SPELLCAST_* and CHANNEL_* events).
- Center Mirror Bar (Breath/Fatigue/Feign/etc.). Reads Blizzard MirrorTimer statusbars every frame (authoritative), with safe fallbacks to frame fields and GetMirrorTimerInfo.
- Options additions (now tabbed: **Global** | **Center Bars**)
  - Separate enable/disable checkboxes for Cast and Mirror.
  - Independent width scale sliders for each.
  - **Independent height sliders (px) for each.**
  - Independent alpha stacks for each (OOC Full, OOC Hurt, Has Target, In Combat) + per-bar “alpha multiplier.”
  - Panel is draggable, closes with ESC or [Close], and each tab has its own scroll area with hover-hints.
- Movers
  - Global Lock/Unlock now shows movers for Cast/Mirror as well as the arcs.
  - While unlocked, inactive bars show a demo half-fill so they can be positioned.
- Slash
  - `/ghud options` opens reliably on first call after login or /reload.
  - `/ghud diag` prints schema, positions, and both bar configs.

Schema
- Bumped to v11. New keys:
  - `profile.center = { x, y }`
  - `profile.castBar = { enabled, scale, height, alpha }`
  - `profile.mirrorBar = { enabled, scale, height, alpha }`
  - `profile.castAlpha = { ooc_full, ooc_hurt, target, combat }`
  - `profile.mirrorAlpha = { ooc_full, ooc_hurt, target, combat }`
- Migration is automatic from prior 0.5.x.

Behavior notes
- Mirror prioritizes BREATH when multiple timers are active; other timers are supported via the same reader.
- Fade-after-complete for Cast/Mirror is intentionally short (~0.1s); we can expose as a slider later.

## v0.5.0 (Ice layout – Milestone 0)
- Segmented arc renderer that replicates IceHUD-style curved bars in a 1.12-legal way (no texture masking/rotation). Default 64 segments per arc.
- Player (left) and Target (right) arc HUDs.
  - Player Health uses a smooth green→yellow→red gradient by current %HP.
  - Player/Target Power colors map to Mana/Rage/Energy (and similar types) automatically.
  - Right (target) HUD can be shown/hidden via Options and updates immediately on toggle.
- UX: Scale-invariant dragging with visually scaled movers.
  - Movers themselves stay at scale 1.0 for perfect drag math; inner content scales.
  - Mover frames resize to match the selected scale so placement feels natural.
  - Positions are stored as center offsets in parent space to avoid snapping at any scale.
  - `/ghud center` button/command to safely recenter both movers.
- Options: Rebuilt panel (draggable; ESC and [X] to close) with:
  - Locked checkbox, Scale slider (0.5–1.5).
  - Alpha sliders for four states: OOC+NoTarget(Full HP), OOC+NoTarget(Missing HP), Has Target, In Combat.
  - “Show Target HUD” toggle.
  - “Center Both” convenience button.
- Persistence: Settings (scale, alphas, toggles, positions) now persist reliably across reloads/logins.
- Slash: `/ghud options|opt|o`, `/ghud lock|unlock`, `/ghud center`, `/ghud diag`, `/ghud test`, `/ghud flash`.
- Stability fixes:
  - Replaced calls to non-Vanilla `:IsMoving()` with an internal `_dragging` flag.
  - Removed screen clamping on movers (prevents scale-dependent snapping on 1.12).
  - Corrected right-HUD show/hide to update immediately on toggle.
  - Fixed options panel not reopening/closing consistently in earlier builds.
- Schema: Bumped internal DB schema to v6 with sane defaults and migration from prior 0.4.x keys (existing positions preserved).
- Known scope: This is Milestone 0 of the Ice layout. Cast/Mirror bars, Energy Tick, Combo Points, ToT/Pet, etc., will land in Milestone 1 with matching arc/skin styling.

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
