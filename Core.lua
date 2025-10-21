-- Core.lua
-- UTF-8, UNIX newlines

GnerdHUD = GnerdHUD or {}

local function sl(s)
  if type(strlower) == "function" then return strlower(tostring(s or "")) end
  if type(string) == "table" and type(string.lower) == "function" then return string.lower(tostring(s or "")) end
  return tostring(s or "")
end

local function Lf(key, default)
  local t = _G.GnerdHUD_L
  local v = t and t[key]
  if v == nil then return default end
  return v
end

local ROOT = CreateFrame("Frame", "GnerdHUD_Root", UIParent)
ROOT:Hide()

-- Defaults
local DEFAULTS = {
  schema = 6,
  profile = {
    locked = true,
    scale = 1.00,
    segments = 64,
    left  = { x = -230, y = -100 },
    right = { x =  230, y = -100 },
    rightEnabled = true,
    alpha = {
      ooc_full = 0.00,
      ooc_hurt = 0.25,
      target   = 0.60,
      combat   = 1.00,
    },
    colors = {
      health = { r = 0.15, g = 0.95, b = 0.25, a = 1.0 },
      power  = { r = 0.25, g = 0.65, b = 1.00, a = 1.0 },
    },
  },
}

local function clamp01(x) x = tonumber(x) or 0; if x < 0 then return 0 elseif x > 1 then return 1 else return x end end
local function printf(msg) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage((Lf("PRINT_PREFIX","GnerdHUD: ")) .. (msg or "")) end end

-- Merge only missing keys from src into dst (in-place, preserve identity)
local function mergeDefaults(dst, src)
  if type(dst) ~= "table" then return end
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      mergeDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

-- Strict normalizer: no resets of existing values, only clamping + filling holes.
local function normalizeDB(db)
  if type(db) ~= "table" then db = {} end
  if type(db.profile) ~= "table" then db.profile = {} end

  mergeDefaults(db, DEFAULTS)

  local p = db.profile

  -- primitive clamps
  local s = tonumber(p.scale) or DEFAULTS.profile.scale
  if s < 0.5 then s = 0.5 elseif s > 1.5 then s = 1.5 end
  p.scale = s

  local segs = tonumber(p.segments) or DEFAULTS.profile.segments
  segs = math.floor(segs + 0.5); if segs < 8 then segs = 8 elseif segs > 128 then segs = 128 end
  p.segments = segs

  if type(p.left)  ~= "table" then p.left  = { x = 0, y = 0 } end
  if type(p.right) ~= "table" then p.right = { x = 0, y = 0 } end
  p.left.x  = tonumber(p.left.x)  or 0
  p.left.y  = tonumber(p.left.y)  or 0
  p.right.x = tonumber(p.right.x) or 0
  p.right.y = tonumber(p.right.y) or 0

  if type(p.alpha) ~= "table" then p.alpha = {} end
  p.alpha.ooc_full = clamp01(p.alpha.ooc_full ~= nil and p.alpha.ooc_full or DEFAULTS.profile.alpha.ooc_full)
  p.alpha.ooc_hurt = clamp01(p.alpha.ooc_hurt ~= nil and p.alpha.ooc_hurt or DEFAULTS.profile.alpha.ooc_hurt)
  p.alpha.target   = clamp01(p.alpha.target   ~= nil and p.alpha.target   or DEFAULTS.profile.alpha.target)
  p.alpha.combat   = clamp01(p.alpha.combat   ~= nil and p.alpha.combat   or DEFAULTS.profile.alpha.combat)

  if type(p.colors) ~= "table" then p.colors = {} end
  if type(p.colors.health) ~= "table" then p.colors.health = {} end
  if type(p.colors.power)  ~= "table" then p.colors.power  = {} end

  local ch, cp = p.colors.health, p.colors.power
  ch.r = clamp01(ch.r ~= nil and ch.r or DEFAULTS.profile.colors.health.r)
  ch.g = clamp01(ch.g ~= nil and ch.g or DEFAULTS.profile.colors.health.g)
  ch.b = clamp01(ch.b ~= nil and ch.b or DEFAULTS.profile.colors.health.b)
  ch.a = clamp01(ch.a ~= nil and ch.a or DEFAULTS.profile.colors.health.a)
  cp.r = clamp01(cp.r ~= nil and cp.r or DEFAULTS.profile.colors.power.r)
  cp.g = clamp01(cp.g ~= nil and cp.g or DEFAULTS.profile.colors.power.g)
  cp.b = clamp01(cp.b ~= nil and cp.b or DEFAULTS.profile.colors.power.b)
  cp.a = clamp01(cp.a ~= nil and cp.a or DEFAULTS.profile.colors.power.a)

  db.schema = 6
  return db
end

-- Stubs expected by Layout/Options; guarded no-ops
GnerdHUD.ApplyAll                   = GnerdHUD.ApplyAll                   or function() end
GnerdHUD.LayoutCreate               = GnerdHUD.LayoutCreate               or function() end
GnerdHUD.LayoutDestroy              = GnerdHUD.LayoutDestroy              or function() end
GnerdHUD.LayoutSetLocked            = GnerdHUD.LayoutSetLocked            or function(_) end
GnerdHUD.LayoutSetScale             = GnerdHUD.LayoutSetScale             or function(_) end
GnerdHUD.LayoutSetPositions         = GnerdHUD.LayoutSetPositions         or function(_, _) end
GnerdHUD.LayoutSetRightEnabled      = GnerdHUD.LayoutSetRightEnabled      or function(_) end
GnerdHUD.LayoutUpdateAlpha          = GnerdHUD.LayoutUpdateAlpha          or function() end
GnerdHUD.LayoutUpdatePlayer         = GnerdHUD.LayoutUpdatePlayer         or function() end
GnerdHUD.LayoutUpdatePlayerColors   = GnerdHUD.LayoutUpdatePlayerColors   or function() end
GnerdHUD.LayoutUpdateTarget         = GnerdHUD.LayoutUpdateTarget         or function() end
GnerdHUD.LayoutUpdateTargetColors   = GnerdHUD.LayoutUpdateTargetColors   or function() end

-- Slash
SLASH_GNERDHUD1 = "/ghud"
SlashCmdList["GNERDHUD"] = function(msg)
  local cmd = sl(msg or "")

  if cmd == "" or cmd == "help" then
    printf(Lf("CMD_HELP_HEADER", "GnerdHUD commands:"))
    printf(Lf("CMD_HELP_2", "/ghud options - Toggle options"))
    printf(Lf("CMD_HELP_3", "/ghud lock - Lock frames"))
    printf(Lf("CMD_HELP_4", "/ghud unlock - Unlock frames"))
    printf(Lf("CMD_HELP_5", "/ghud diag - Print state"))
    printf(Lf("CMD_HELP_6", "/ghud rebuild - Recreate layout"))
    printf("/ghud reset - Reset settings to defaults")
    printf("/ghud center - Center both movers")
    printf("/ghud ttest - Target demo (6s)")
    printf("/ghud test - Player demo (6s)")
    printf("/ghud show - Force 100%% (5s)")
    printf("/ghud dbg - Toggle red debug square")
    printf("/ghud flash - Force alpha=1 for 5s")
    return
  elseif cmd == "options" then
    if _G.GnerdHUD_Options then
      if GnerdHUD_Options:IsShown() then GnerdHUD_Options:Hide() else GnerdHUD_Options:Show(); if GnerdHUD_Options.Raise then GnerdHUD_Options:Raise() end end
    else
      printf("Options UI not loaded (Options.lua).")
    end
    return
  elseif cmd == "lock" then
    GnerdHUDDB.profile.locked = true; GnerdHUD.LayoutSetLocked(true); GnerdHUD.LayoutUpdateAlpha(); printf(Lf("STATE_LOCKED","Locked")); return
  elseif cmd == "unlock" then
    GnerdHUDDB.profile.locked = false; GnerdHUD.LayoutSetLocked(false); GnerdHUD.LayoutUpdateAlpha(); printf(Lf("STATE_UNLOCKED","Unlocked")); return
  elseif cmd == "center" then
    GnerdHUDDB.profile.left.x,  GnerdHUDDB.profile.left.y  = 0, 0
    GnerdHUDDB.profile.right.x, GnerdHUDDB.profile.right.y = 0, 0
    GnerdHUD.LayoutSetPositions(GnerdHUDDB.profile.left, GnerdHUDDB.profile.right)
    printf("Centered both movers."); return
  elseif cmd == "rebuild" then
    GnerdHUD.LayoutDestroy(); GnerdHUD.LayoutCreate(); GnerdHUD.ApplyAll(true); printf(Lf("STATE_REBUILT","Layout rebuilt.")); return
  elseif cmd == "reset" then
    GnerdHUDDB = {}; normalizeDB(GnerdHUDDB); GnerdHUD.env.db = GnerdHUDDB
    GnerdHUD.LayoutDestroy(); GnerdHUD.LayoutCreate(); GnerdHUD.ApplyAll(true); printf("Settings reset."); return
  elseif cmd == "diag" then
    local p = GnerdHUDDB.profile
    printf(string.format("Schema=%s Segments=%d Scale=%.2f Locked=%s", tostring(GnerdHUDDB.schema or "?"), tonumber(p.segments or 0), tonumber(p.scale or 1), tostring(p.locked)))
    printf(string.format("LeftHUD x=%.2f y=%.2f  RightHUD x=%.2f y=%.2f", tonumber(p.left.x or 0), tonumber(p.left.y or 0), tonumber(p.right.x or 0), tonumber(p.right.y or 0)))
    printf(string.format("Right enabled=%s", tostring(p.rightEnabled)))
    printf(string.format("Alpha ooc_full=%.2f ooc_hurt=%.2f target=%.2f combat=%.2f", p.alpha.ooc_full, p.alpha.ooc_hurt, p.alpha.target, p.alpha.combat))
    return
  elseif cmd == "test" then
    if GnerdHUD_TestSet then GnerdHUD_TestSet(0.75, 0.50) end
    local t0 = CreateFrame("Frame", nil, UIParent); local s = GetTime()
    t0:SetScript("OnUpdate", function() if GetTime() - s > 6 then t0:SetScript("OnUpdate", nil); if GnerdHUD and GnerdHUD.LayoutUpdatePlayer then GnerdHUD.LayoutUpdatePlayer() end end end)
    printf("Player test fill active for 6s."); return
  elseif cmd == "ttest" then
    if GnerdHUD_TestTargetSet then GnerdHUD_TestTargetSet(0.65, 0.40) end
    local t1 = CreateFrame("Frame", nil, UIParent); local s = GetTime()
    t1:SetScript("OnUpdate", function() if GetTime() - s > 6 then t1:SetScript("OnUpdate", nil); if GnerdHUD and GnerdHUD.LayoutUpdateTarget then GnerdHUD.LayoutUpdateTarget() end end end)
    printf("Target test fill active for 6s."); return
  elseif cmd == "show" then
    if GnerdHUD_TestSet then GnerdHUD_TestSet(1.0, 1.0) end
    local t2 = CreateFrame("Frame", nil, UIParent); local s = GetTime()
    t2:SetScript("OnUpdate", function() if GetTime() - s > 5 then t2:SetScript("OnUpdate", nil); if GnerdHUD and GnerdHUD.LayoutUpdatePlayer then GnerdHUD.LayoutUpdatePlayer() end end end)
    printf("Full fill for 5s."); return
  elseif cmd == "dbg" then
    if GnerdHUD_DebugToggle then GnerdHUD_DebugToggle() end; printf("Debug square toggled."); return
  elseif cmd == "flash" then
    local old = GnerdHUDDB.profile.locked; GnerdHUDDB.profile.locked = false; GnerdHUD.LayoutUpdateAlpha()
    local t3 = CreateFrame("Frame", nil, UIParent); local s = GetTime()
    t3:SetScript("OnUpdate", function() if GetTime() - s > 5 then t3:SetScript("OnUpdate", nil); GnerdHUDDB.profile.locked = old; GnerdHUD.LayoutUpdateAlpha() end end)
    printf("Alpha forced to 1.0 for 5s."); return
  end

  printf("Unknown. Type /ghud help.")
end

ROOT:SetScript("OnEvent", function()
  local e = event
  if e == "PLAYER_LOGIN" then
    GnerdHUDDB = normalizeDB(GnerdHUDDB)
    GnerdHUD.env = GnerdHUD.env or {}
    GnerdHUD.env.db = GnerdHUDDB
    GnerdHUD.env.L = _G.GnerdHUD_L or {}
    GnerdHUD.env.state = { inCombat = (UnitAffectingCombat("player")==1), hasTarget = (UnitExists("target")==1) }

    GnerdHUD.LayoutCreate(); GnerdHUD.ApplyAll(true)

    ROOT:RegisterEvent("UNIT_HEALTH"); ROOT:RegisterEvent("UNIT_MAXHEALTH")
    ROOT:RegisterEvent("UNIT_MANA"); ROOT:RegisterEvent("UNIT_MAXMANA")
    ROOT:RegisterEvent("UNIT_RAGE"); ROOT:RegisterEvent("UNIT_MAXRAGE")
    ROOT:RegisterEvent("UNIT_ENERGY"); ROOT:RegisterEvent("UNIT_MAXENERGY")
    ROOT:RegisterEvent("UNIT_DISPLAYPOWER")
    ROOT:RegisterEvent("PLAYER_REGEN_DISABLED"); ROOT:RegisterEvent("PLAYER_REGEN_ENABLED"); ROOT:RegisterEvent("PLAYER_TARGET_CHANGED")
    ROOT:Show(); return
  end

  if e == "UNIT_HEALTH" or e == "UNIT_MAXHEALTH" then
    if arg1 == "player" then GnerdHUD.LayoutUpdatePlayer(); GnerdHUD.LayoutUpdateAlpha() end
    if arg1 == "target" then GnerdHUD.LayoutUpdateTarget(); GnerdHUD.LayoutUpdateAlpha() end
    return
  end
  if e == "UNIT_MANA" or e == "UNIT_MAXMANA" or e == "UNIT_RAGE" or e == "UNIT_MAXRAGE" or e == "UNIT_ENERGY" or e == "UNIT_MAXENERGY" then
    if arg1 == "player" then GnerdHUD.LayoutUpdatePlayer() end
    if arg1 == "target" then GnerdHUD.LayoutUpdateTarget() end
    return
  end
  if e == "UNIT_DISPLAYPOWER" then
    if arg1 == "player" then GnerdHUD.LayoutUpdatePlayerColors(); GnerdHUD.LayoutUpdatePlayer() end
    if arg1 == "target" then GnerdHUD.LayoutUpdateTargetColors(); GnerdHUD.LayoutUpdateTarget() end
    return
  end
  if e == "PLAYER_REGEN_DISABLED" then GnerdHUD.env.state.inCombat = true;  GnerdHUD.LayoutUpdateAlpha(); return end
  if e == "PLAYER_REGEN_ENABLED"  then GnerdHUD.env.state.inCombat = false; GnerdHUD.LayoutUpdateAlpha(); return end
  if e == "PLAYER_TARGET_CHANGED" then
    GnerdHUD.env.state.hasTarget = (UnitExists("target") == 1)
    GnerdHUD.LayoutUpdateTargetColors(); GnerdHUD.LayoutUpdateTarget(); GnerdHUD.LayoutUpdateAlpha()
    return
  end
end)
ROOT:RegisterEvent("PLAYER_LOGIN")

function GnerdHUD.ApplyAll(fromRebuild)
  local p = GnerdHUDDB.profile
  GnerdHUD.LayoutSetScale(p.scale)
  GnerdHUD.LayoutSetPositions(p.left, p.right)
  GnerdHUD.LayoutSetLocked(p.locked)
  GnerdHUD.LayoutSetRightEnabled(p.rightEnabled)
  GnerdHUD.LayoutUpdatePlayerColors()
  GnerdHUD.LayoutUpdateTargetColors()
  GnerdHUD.LayoutUpdatePlayer()
  GnerdHUD.LayoutUpdateTarget()
  GnerdHUD.LayoutUpdateAlpha()
  if not fromRebuild then printf(Lf("STATE_APPLIED","Settings applied.")) end
end
