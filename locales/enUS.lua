-- locales/enUS.lua
-- UTF-8, UNIX newlines
-- Baseline localization. Keep keys stable; other locales can override this file later.

GnerdHUD = GnerdHUD or {}
GnerdHUD.L = GnerdHUD.L or {}
local L = GnerdHUD.L

-- Fallback: unknown keys return the key itself
setmetatable(L, { __index = function(t, k) return k end })

-- General
L.OPTIONS_TITLE               = "GnerdHUD Options"
L.LOCKED                      = "Locked"
L.SHOW_TARGET_HUD             = "Show Target HUD"
L.SCALE                       = "Scale"
L.CLOSE                       = "Close"
L.CENTER_BOTH                 = "Center Both"

-- Alpha (global arc rules)
L.ALPHA_OOC_FULL              = "Alpha: OOC \226\128\162 No Target (Full HP)"
L.ALPHA_OOC_HURT              = "Alpha: OOC \226\128\162 No Target (Missing HP)"
L.ALPHA_TARGET                = "Alpha: Has Target"
L.ALPHA_COMBAT                = "Alpha: In Combat"

-- Cast & Mirror section
L.SECTION_CAST_MIRROR         = "Cast & Mirror"
L.ENABLE_CAST                 = "Enable Cast Bar"
L.ENABLE_MIRROR               = "Enable Mirror Bar"
L.CAST_SCALE                  = "Cast Scale (width)"
L.MIRROR_SCALE                = "Mirror Scale (width)"
L.CAST_ALPHA_MULT             = "Cast Alpha (multiplier)"
L.MIRROR_ALPHA_MULT           = "Mirror Alpha (multiplier)"
L.CAST_ALPHA_OOC_FULL         = "Cast Alpha: OOC \226\128\162 No Target (Full HP)"
L.CAST_ALPHA_OOC_HURT         = "Cast Alpha: OOC \226\128\162 No Target (Missing HP)"
L.CAST_ALPHA_TARGET           = "Cast Alpha: Has Target"
L.CAST_ALPHA_COMBAT           = "Cast Alpha: In Combat"
L.MIRROR_ALPHA_OOC_FULL       = "Mirror Alpha: OOC \226\128\162 No Target (Full HP)"
L.MIRROR_ALPHA_OOC_HURT       = "Mirror Alpha: OOC \226\128\162 No Target (Missing HP)"
L.MIRROR_ALPHA_TARGET         = "Mirror Alpha: Has Target"
L.MIRROR_ALPHA_COMBAT         = "Mirror Alpha: In Combat"

-- Slash / diagnostics
L.SLASH_HELP_TITLE            = "GnerdHUD Slash Help"
L.SLASH_HELP_OPTIONS          = "/ghud options  \226\128\148  Open/close options"
L.SLASH_HELP_LOCK             = "/ghud lock|unlock  \226\128\148  Toggle movers"
L.SLASH_HELP_CENTER           = "/ghud center  \226\128\148  Recenter arcs and bars"
L.SLASH_HELP_DIAG             = "/ghud diag  \226\128\148  Print diagnostics"

-- UI strings used when movers are unlocked
L.MOVER_CAST                  = "Cast"
L.MOVER_MIRROR                = "Mirror"

-- Future keys (reserve)
L.TAB_GLOBAL                  = "Global"
L.TAB_ARCS                    = "Arcs"
L.TAB_CENTER                  = "Center Bars"
L.TAB_CLASS                   = "Class"
L.TAB_MISC                    = "Misc"

-- End of enUS
