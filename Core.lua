-- GnerdHUD/core.lua
-- UTF-8, UNIX LF
-- TurtleWoW 1.12 (Lua 5.0) + optional SuperWoW (feature-probed)

--[[---------------------------------------------------------------------------
SavedVariables (schema v5)
-----------------------------------------------------------------------------]]
GnerdHUDDB = GnerdHUDDB or { schema = 5, profile = {
  locked = false,
  alpha = { idle = 0.25, combat = 1.0, hasTarget = 0.9 },
  positions = {
    player = { x = -180, y = -40 },
    target = { x =  180, y = -40 },
    absorb = { x = 0, y = 40 },
  },
  bars = {
    width = 180, height = 18, texture = "Interface\\TargetingFrame\\UI-StatusBar",
    inset = 1,
    font = "Fonts\\FRIZQT__.TTF", fontSize = 12, outline = "OUTLINE",
  },
  colors = {
    health = { r = 0.0, g = 1.0, b = 0.2 },
    power = {
      [0] = { r = 0.0, g = 0.55, b = 1.0 },
      [1] = { r = 1.0, g = 0.0, b = 0.0 },
      [2] = { r = 1.0, g = 0.5, b = 0.25 },
      [3] = { r = 1.0, g = 1.0, b = 0.0 },
      [4] = { r = 0.6, g = 0.0, b = 0.6 },
    },
  },
  modules = {
    ToT = { enabled = true, anchor = { x = 220, y = -40 } },
    Pet = { enabled = true, anchor = { x = -220, y = -80 } },
    Castbar = { enabled = true, anchor = { x = 0, y = -120 }, showLag = true },
    Mirror = { enabled = true, anchor = { x = 0, y = 140 } },
    DruidMana = { enabled = true, anchor = { x = -180, y = -64 } },
    Range = { enabled = true, mode = "simple", anchor = { x = 180, y = -70 } },
    ComboPoints = { enabled = true, anchor = { x = 0, y = -80 } },
    SnD = { enabled = true, anchor = { x = 0, y = -100 } },
    Shards = { enabled = true, anchor = { x = -300, y = -120 } },
    CrowdControl = { enabled = true, anchor = { x = 180, y = 20 } },
    ThreatLite = { enabled = true, anchor = { x = 0, y = 20 } },
    EnergyTicker = { enabled = true, anchor = { x = 0, y = -60 } },
    Options = { enabled = true },
    AbsorbDB = { enabled = true },
  },
  absorb = {
    enabled = true,
    showLowestBySchool = true,
    debug = false,
  },
}}
local DB = GnerdHUDDB

local L = GnerdHUD_L or setmetatable({}, { __index = function(t,k) return k end })

local GH = _G.GnerdHUD or {}
_G.GnerdHUD = GH
GH.modules = GH.modules or {}

--[[---------------------------------------------------------------------------
Feature Detection (SuperWoW and helpers)
-----------------------------------------------------------------------------]]
GH.features = GH.features or {
  superwow = false,
  hasFileIO = false,
  auraIdAPI = false,
  rawCombatLog = false,
  unitCastEvent = false,
}
local function ProbeFeatures()
  GH.features.hasFileIO = (type(ExportFile)=="function") and (type(ImportFile)=="function") or false
  GH.features.superwow = GH.features.hasFileIO or (type(SUPERWOW_VERSION)=="string")
  GH.features.auraIdAPI = (type(GetPlayerBuffID)=="function")
  GH.features.rawCombatLog = false
  GH.features.unitCastEvent = false
end

--[[---------------------------------------------------------------------------
Utility (Lua 5.0-safe)
-----------------------------------------------------------------------------]]
local function Clamp(v, minv, maxv)
  if v < minv then return minv end
  if v > maxv then return maxv end
  return v
end

local function SetAlphaSmart(frame)
  if not frame or not frame.SetAlpha then return end
  local alpha = DB.profile.alpha.idle
  if UnitAffectingCombat("player") then
    alpha = DB.profile.alpha.combat
  elseif UnitExists("target") then
    alpha = DB.profile.alpha.hasTarget
  end
  frame:SetAlpha(alpha)
end
GH.SetAlphaSmart = SetAlphaSmart

local function PowerColorFor(unit)
  local pt = UnitPowerType(unit) or 0
  local c = DB.profile.colors.power[pt] or DB.profile.colors.power[0]
  return c.r, c.g, c.b
end
GH.PowerColorFor = PowerColorFor

--[[---------------------------------------------------------------------------
Bar Factory
-----------------------------------------------------------------------------]]
GH.bars = GH.bars or {}

function GH:CreateStatusBar(name, unit, kind, anchorX, anchorY)
  local cfg = DB.profile.bars
  local f = CreateFrame("StatusBar", name, UIParent)
  f:SetWidth(cfg.width)
  f:SetHeight(cfg.height)
  f:SetStatusBarTexture(cfg.texture)
  f:SetMinMaxValues(0, 1)
  f:SetValue(0)
  f:SetPoint("CENTER", UIParent, "CENTER", anchorX, anchorY)

  local bg = f:CreateTexture(name.."_BG", "BACKGROUND")
  bg:SetAllPoints(f)
  bg:SetTexture(0,0,0,0.5)
  f.bg = bg

  local fs = f:CreateFontString(name.."_Text", "OVERLAY")
  fs:SetFont(cfg.font, cfg.fontSize, DB.profile.bars.outline)
  fs:SetPoint("CENTER", f, "CENTER", 0, 0)
  fs:SetText(kind.." ??")
  f.text = fs

  f.unit = unit
  f.kind = kind

  f.Update = function(self)
    if not UnitExists(self.unit) and self.unit ~= "player" then
      self:Hide()
      return
    end
    self:Show()
    if self.kind == "HEALTH" then
      local cur = UnitHealth(self.unit) or 0
      local max = UnitHealthMax(self.unit) or 1
      if cur > max then cur = max end
      if cur < 0 then cur = 0 end
      self:SetMinMaxValues(0, max)
      self:SetValue(cur)
      self:SetStatusBarColor(DB.profile.colors.health.r, DB.profile.colors.health.g, DB.profile.colors.health.b)
      local name = UnitName(self.unit) or self.unit
      self.text:SetText(name.." "..cur.."/"..max)
    else
      local cur = UnitMana(self.unit) or 0
      local max = UnitManaMax(self.unit) or 1
      if cur > max then cur = max end
      if cur < 0 then cur = 0 end
      self:SetMinMaxValues(0, max)
      self:SetValue(cur)
      local r,g,b = PowerColorFor(self.unit)
      self:SetStatusBarColor(r,g,b)
      local name = UnitName(self.unit) or self.unit
      self.text:SetText(name.." "..cur.."/"..max)
    end
    SetAlphaSmart(self)
  end

  f:Hide()
  return f
end

local function EnsureBars()
  if GH.bars.playerHealth then return end
  local px = DB.profile.positions.player.x
  local py = DB.profile.positions.player.y
  local tx = DB.profile.positions.target.x
  local ty = DB.profile.positions.target.y

  GH.bars.playerHealth = GH:CreateStatusBar("GnerdHUD_PlayerHealth", "player", "HEALTH", px, py + 10)
  GH.bars.playerPower  = GH:CreateStatusBar("GnerdHUD_PlayerPower",  "player", "POWER",  px, py - 10)
  GH.bars.targetHealth = GH:CreateStatusBar("GnerdHUD_TargetHealth", "target", "HEALTH", tx, ty + 10)
  GH.bars.targetPower  = GH:CreateStatusBar("GnerdHUD_TargetPower",  "target", "POWER",  tx, ty - 10)
end

local function UpdateAllBars()
  if not GH.bars.playerHealth then return end
  GH.bars.playerHealth:Update()
  GH.bars.playerPower:Update()
  GH.bars.targetHealth:Update()
  GH.bars.targetPower:Update()
end
GH.UpdateAllBars = UpdateAllBars

--[[---------------------------------------------------------------------------
Absorb Tracker (core)
-----------------------------------------------------------------------------]]
GH.Absorb = GH.Absorb or {
  frame = nil,
  schools = { "physical","holy","fire","nature","frost","shadow","arcane" },
  active = {},
  effects = {},
  auraIndexByBuff = {},
  superMode = false,
}

function GH.Absorb:EnsureFrame()
  if self.frame then return end
  local cfg = DB.profile.bars
  local f = CreateFrame("Frame", "GnerdHUD_Absorb", UIParent)
  f:SetWidth(200); f:SetHeight(24)
  f:SetPoint("CENTER", UIParent, "CENTER", DB.profile.positions.absorb.x, DB.profile.positions.absorb.y)
  local fs = f:CreateFontString("GnerdHUD_AbsorbText", "OVERLAY")
  fs:SetFont(cfg.font, cfg.fontSize + 2, "OUTLINE")
  fs:SetPoint("CENTER", f, "CENTER", 0, 0)
  fs:SetText("Absorb — init")
  f.text = fs
  self.frame = f
end

function GH.Absorb:SetDebug(msg)
  if not DB.profile.absorb.debug then return end
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff[GnerdHUD Absorb]|r "..msg)
end

local function minPositive(a, b)
  if not a then return b end
  if not b then return a end
  if a <= 0 then return b end
  if b <= 0 then return a end
  if a < b then return a else return b end
end

function GH.Absorb:Recalculate()
  local lowest
  local i
  for i=1, table.getn(self.schools) do
    local s = self.schools[i]
    local v = self.active[s]
    lowest = minPositive(lowest, v)
  end
  self:EnsureFrame()
  if not DB.profile.absorb.enabled then
    self.frame:Hide(); return
  end
  self.frame:Show()
  if lowest then
    self.frame.text:SetText(L["Absorb"]..": "..lowest)
  else
    self.frame.text:SetText(L["Absorb"]..": 0")
  end
  SetAlphaSmart(self.frame)
end

function GH.Absorb:ClearAll()
  self.active = {}
  self:Recalculate()
end

function GH.Absorb:RebuildFromAuras()
  self:ClearAll()
  local idx = 0
  while true do
    idx = idx + 1
    local name = GetPlayerBuffName(idx)
    if not name then break end
    local key = name
    local auraId
    if GH.features.auraIdAPI then
      auraId = GetPlayerBuffID(idx)
      if auraId then key = "id:"..auraId end
    end
    local eff = self.effects[key]
    if not eff then
      local low = string.lower(name)
      local isWard = string.find(low, "ward", 1, true)
      local isFire = string.find(low, "fire", 1, true)
      local isFrost = string.find(low, "frost", 1, true)
      local isShadow = string.find(low, "shadow", 1, true)
      local schools
      if isWard then
        if isFire then schools = { "fire" }
        elseif isFrost then schools = { "frost" }
        elseif isShadow then schools = { "shadow" }
        else schools = { "holy" }
        end
      else
        schools = { "physical" }
      end
      eff = { schools = schools, amount = 0, source = "buff" }
    end
    local amount = eff.amount or 0
    if amount <= 0 then amount = 1 end
    local j
    for j=1, table.getn(eff.schools) do
      local s = eff.schools[j]
      self.active[s] = (self.active[s] or 0) + amount
    end
  end
  self:Recalculate()
end

-- very-lightweight decrementer using SuperWoW RAW_COMBATLOG text lines
local function contains(hay, needle)
  return string.find(hay, needle, 1, true) ~= nil
end
local function parseNumberBefore(hay, word)
  local pos = string.find(hay, word, 1, true)
  if not pos then return nil end
  local i = pos - 1
  local start = i
  while i >= 1 do
    local ch = string.sub(hay, i, i)
    if ch < "0" or ch > "9" then break end
    start = i
    i = i - 1
  end
  local s = string.sub(hay, start, pos-2)
  local n = tonumber(s)
  return n
end
local function inferSchool(line)
  local low = string.lower(line)
  if contains(low,"fire") then return "fire" end
  if contains(low,"frost") then return "frost" end
  if contains(low,"shadow") then return "shadow" end
  if contains(low,"arcane") then return "arcane" end
  if contains(low,"nature") then return "nature" end
  if contains(low,"holy") then return "holy" end
  return "physical"
end

function GH.Absorb:OnRawCombatLog(line)
  if not GH.features.rawCombatLog then
    GH.features.rawCombatLog = true
    self:SetDebug("RAW_COMBATLOG detected; absorb decrementer active.")
  end
  local low = string.lower(line or "")
  if not contains(low, "absorb") then return end
  local dmg = parseNumberBefore(line, " absorb")
  if not dmg or dmg <= 0 then return end
  local school = inferSchool(line)
  if not self.active[school] then return end
  self.active[school] = self.active[school] - dmg
  if self.active[school] < 0 then self.active[school] = 0 end
  self:Recalculate()
end

--[[---------------------------------------------------------------------------
Module System
-----------------------------------------------------------------------------]]
function GH:RegisterModule(name, mod)
  if not name or not mod then return end
  GH.modules[name] = mod
end

local function EnableConfiguredModules()
  local name, cfg, mod
  for name, cfg in pairs(DB.profile.modules) do
    mod = GH.modules[name]
    if mod and cfg and cfg.enabled and mod.Enable then
      pcall(mod.Enable, mod, cfg)
    end
  end
end

--[[---------------------------------------------------------------------------
Events
-----------------------------------------------------------------------------]]
local f = CreateFrame("Frame", "GnerdHUD_Root", UIParent)
GH.root = f
local function RegisterEvents()
  f:RegisterEvent("PLAYER_LOGIN")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("PLAYER_REGEN_DISABLED")
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  f:RegisterEvent("UNIT_HEALTH")
  f:RegisterEvent("UNIT_MAXHEALTH")
  f:RegisterEvent("UNIT_MANA")
  f:RegisterEvent("UNIT_MAXMANA")
  f:RegisterEvent("UNIT_ENERGY")
  f:RegisterEvent("UNIT_RAGE")
  f:RegisterEvent("UNIT_DISPLAYPOWER")
  f:RegisterEvent("UNIT_AURA")
  f:RegisterEvent("RAID_TARGET_UPDATE")
  f:RegisterEvent("RAW_COMBATLOG")
  f:RegisterEvent("UNIT_CASTEVENT")
  f:RegisterEvent("MIRROR_TIMER_START")
  f:RegisterEvent("MIRROR_TIMER_STOP")
  f:RegisterEvent("MIRROR_TIMER_PAUSE")
  f:RegisterEvent("SPELLCAST_START")
  f:RegisterEvent("SPELLCAST_STOP")
  f:RegisterEvent("SPELLCAST_FAILED")
  f:RegisterEvent("SPELLCAST_INTERRUPTED")
  f:RegisterEvent("SPELLCAST_CHANNEL_START")
  f:RegisterEvent("SPELLCAST_CHANNEL_STOP")
  f:RegisterEvent("BAG_UPDATE")
  f:RegisterEvent("PLAYER_COMBO_POINTS")
end

local function OnEvent(self, event, arg1, arg2, arg3, arg4, arg5)
  if event == "PLAYER_LOGIN" then
    ProbeFeatures()
    EnsureBars()
    GH.Absorb:EnsureFrame()
    GH.Absorb:RebuildFromAuras()
    UpdateAllBars()
    EnableConfiguredModules()
    GH.SetAlphaSmart(GH.bars.playerHealth); GH.SetAlphaSmart(GH.bars.playerPower)
    GH.SetAlphaSmart(GH.bars.targetHealth); GH.SetAlphaSmart(GH.bars.targetPower)
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r v"..(GetAddOnMetadata and GetAddOnMetadata("GnerdHUD","Version") or "0.4.1")
      ..(GH.features.superwow and " | SuperWoW: ON" or " | SuperWoW: OFF"))
  elseif event == "PLAYER_ENTERING_WORLD" or event == "RAID_TARGET_UPDATE" then
    UpdateAllBars()
  elseif event == "PLAYER_TARGET_CHANGED" then
    UpdateAllBars()
    if GH.modules.ToT and GH.modules.ToT.OnEvent then pcall(GH.modules.ToT.OnEvent, GH.modules.ToT, event) end
    if GH.modules.Range and GH.modules.Range.OnEvent then pcall(GH.modules.Range.OnEvent, GH.modules.Range, event) end
    if GH.modules.CrowdControl and GH.modules.CrowdControl.OnEvent then pcall(GH.modules.CrowdControl.OnEvent, GH.modules.CrowdControl, event) end
    if GH.modules.ThreatLite and GH.modules.ThreatLite.OnEvent then pcall(GH.modules.ThreatLite.OnEvent, GH.modules.ThreatLite, event) end
  elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
    UpdateAllBars(); GH.Absorb:Recalculate()
  elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    if arg1 == "player" then GH.bars.playerHealth:Update()
    elseif arg1 == "target" then GH.bars.targetHealth:Update()
    elseif arg1 == "pet" and GH.modules.Pet and GH.modules.Pet.OnEvent then pcall(GH.modules.Pet.OnEvent, GH.modules.Pet, event, arg1) end
    elseif arg1 == "targettarget" and GH.modules.ToT and GH.modules.ToT.OnEvent then pcall(GH.modules.ToT.OnEvent, GH.modules.ToT, event, arg1) end
  elseif event == "UNIT_MANA" or event == "UNIT_MAXMANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" or event == "UNIT_DISPLAYPOWER" then
    if arg1 == "player" then GH.bars.playerPower:Update() end
    if arg1 == "target" then GH.bars.targetPower:Update() end
    if GH.modules.DruidMana and GH.modules.DruidMana.OnEvent then pcall(GH.modules.DruidMana.OnEvent, GH.modules.DruidMana, event, arg1) end
    if GH.modules.Pet and GH.modules.Pet.OnEvent then pcall(GH.modules.Pet.OnEvent, GH.modules.Pet, event, arg1) end
    if GH.modules.Castbar and GH.modules.Castbar.OnEvent then pcall(GH.modules.Castbar.OnEvent, GH.modules.Castbar, event, arg1) end
    if GH.modules.EnergyTicker and GH.modules.EnergyTicker.OnEvent then pcall(GH.modules.EnergyTicker.OnEvent, GH.modules.EnergyTicker, event, arg1) end
  elseif event == "UNIT_AURA" then
    if arg1 == "player" then GH.Absorb:RebuildFromAuras() end
    if GH.modules.SnD and GH.modules.SnD.OnEvent then pcall(GH.modules.SnD.OnEvent, GH.modules.SnD, event, arg1) end
    if GH.modules.CrowdControl and GH.modules.CrowdControl.OnEvent then pcall(GH.modules.CrowdControl.OnEvent, GH.modules.CrowdControl, event, arg1) end
  elseif event == "RAW_COMBATLOG" and type(arg2)=="string" then
    GH.Absorb:OnRawCombatLog(arg2)
    if GH.modules.Castbar and GH.modules.Castbar.OnRawCombatLog then pcall(GH.modules.Castbar.OnRawCombatLog, GH.modules.Castbar, arg2) end
  elseif event == "UNIT_CASTEVENT" then
    GH.features.unitCastEvent = true
    if GH.modules.Castbar and GH.modules.Castbar.OnCastEvent then pcall(GH.modules.Castbar.OnCastEvent, GH.modules.Castbar, arg1, arg2, arg3, arg4, arg5) end
  elseif event == "MIRROR_TIMER_START" or event == "MIRROR_TIMER_STOP" or event == "MIRROR_TIMER_PAUSE" then
    if GH.modules.Mirror and GH.modules.Mirror.OnEvent then pcall(GH.modules.Mirror.OnEvent, GH.modules.Mirror, event, arg1, arg2) end
  elseif event == "SPELLCAST_START" or event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" or event == "SPELLCAST_CHANNEL_START" or event == "SPELLCAST_CHANNEL_STOP" then
    if GH.modules.Castbar and GH.modules.Castbar.OnEvent then pcall(GH.modules.Castbar.OnEvent, GH.modules.Castbar, event, arg1) end
  elseif event == "BAG_UPDATE" then
    if GH.modules.Shards and GH.modules.Shards.OnEvent then pcall(GH.modules.Shards.OnEvent, GH.modules.Shards, event) end
  elseif event == "PLAYER_COMBO_POINTS" then
    if GH.modules.ComboPoints and GH.modules.ComboPoints.OnEvent then pcall(GH.modules.ComboPoints.OnEvent, GH.modules.ComboPoints, event) end
  end
end
f:SetScript("OnEvent", OnEvent)
RegisterEvents()

--[[---------------------------------------------------------------------------
Movers/Locking
-----------------------------------------------------------------------------]]
local function CreateMover(title, attachFrame, key)
  local m = CreateFrame("Button", title.."_Mover", UIParent)
  m:SetWidth(attachFrame:GetWidth()+8); m:SetHeight(attachFrame:GetHeight()+8)
  m:SetPoint("CENTER", attachFrame, "CENTER", 0, 0)
  m:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left=3,right=3,top=3,bottom=3 } })
  m:SetBackdropColor(0,0,0,0.5)
  m:EnableMouse(true)
  m:RegisterForDrag("LeftButton")
  m:SetFrameStrata("DIALOG")
  local label = m:CreateFontString(nil, "OVERLAY")
  label:SetFont(DB.profile.bars.font, 12, "OUTLINE")
  label:SetPoint("CENTER", m, "CENTER", 0, 0)
  label:SetText(title.." (drag)")
  m:SetScript("OnDragStart", function(self) self:StartMoving() end)
  m:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter()
    local ux, uy = UIParent:GetCenter()
    local dx = cx - ux
    local dy = cy - uy
    DB.profile.positions[key].x = math.floor(dx + 0.5)
    DB.profile.positions[key].y = math.floor(dy + 0.5)
    attachFrame:ClearAllPoints()
    attachFrame:SetPoint("CENTER", UIParent, "CENTER", DB.profile.positions[key].x, DB.profile.positions[key].y)
  end)
  m:Hide()
  return m
end

GH.movers = GH.movers or {}
local function EnsureMovers()
  if GH.movers.player then return end
  GH.movers.player = CreateMover("GH Player", GH.bars.playerHealth, "player")
  GH.movers.target = CreateMover("GH Target", GH.bars.targetHealth, "target")
  GH.Absorb:EnsureFrame()
  GH.movers.absorb = CreateMover("GH Absorb", GH.Absorb.frame, "absorb")
end

local function SetLocked(state)
  DB.profile.locked = state and true or false
  EnsureMovers()
  if DB.profile.locked then
    GH.movers.player:Hide(); GH.movers.target:Hide(); GH.movers.absorb:Hide()
    local k,mod
    for k,mod in pairs(GH.modules) do if mod.SetLocked then pcall(mod.SetLocked, mod, true) end end
  else
    GH.movers.player:Show(); GH.movers.target:Show(); GH.movers.absorb:Show()
    local k,mod
    for k,mod in pairs(GH.modules) do if mod.SetLocked then pcall(mod.SetLocked, mod, false) end end
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..(DB.profile.locked and L["Locked"] or L["Unlocked"]))
end

--[[---------------------------------------------------------------------------
Slash Commands
-----------------------------------------------------------------------------]]
SlashCmdList = SlashCmdList or {}
SLASH_GNERDHUD1 = "/gnerdhud"
SLASH_GNERDHUD2 = "/ghud"

local function PrintHelp()
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..(GetAddOnMetadata and GetAddOnMetadata("GnerdHUD","Version") or ""))
  DEFAULT_CHAT_FRAME:AddMessage("/ghud lock|unlock")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud alpha idle|combat|target <0.0-1.0>")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud test")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud absorb on|off|debug|import <file>")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud mod <name> on|off")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud options  - open simple options panel")
end

SlashCmdList["GNERDHUD"] = function(msg)
  msg = msg or ""
  while string.find(msg, "^%s") do msg = string.sub(msg, 2) end
  if msg == "" or msg == "help" then PrintHelp(); return end
  if msg == "lock" then SetLocked(true); return end
  if msg == "unlock" then SetLocked(false); return end
  if msg == "test" then EnsureBars(); UpdateAllBars(); GH.Absorb:Recalculate(); DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..L["Test updated."]); return end
  if msg == "options" and GH.modules.Options and GH.modules.Options.Toggle then pcall(GH.modules.Options.Toggle, GH.modules.Options); return end
  local _,_,what,val = string.find(msg, "^alpha%s+(%a+)%s+([%d%.]+)$")
  if what and val then
    local n = tonumber(val)
    if n then
      if what == "idle" then DB.profile.alpha.idle = Clamp(n,0,1)
      elseif what == "combat" then DB.profile.alpha.combat = Clamp(n,0,1)
      elseif what == "target" then DB.profile.alpha.hasTarget = Clamp(n,0,1)
      end
      UpdateAllBars(); GH.Absorb:Recalculate()
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r alpha "..what.." = "..Clamp(n,0,1))
      return
    end
  end
  local _,_,abs = string.find(msg, "^absorb%s+(%a+)$")
  if abs then
    if abs == "on" then DB.profile.absorb.enabled = true; GH.Absorb:RebuildFromAuras(); return end
    if abs == "off" then DB.profile.absorb.enabled = false; GH.Absorb:Recalculate(); return end
    if abs == "debug" then DB.profile.absorb.debug = not DB.profile.absorb.debug; DEFAULT_CHAT_FRAME:AddMessage("Absorb debug: "..(DB.profile.absorb.debug and "ON" or "OFF")); return end
  end
  local _,_,imp,file = string.find(msg, "^absorb%s+(import)%s+(.+)$")
  if imp and file and GH.modules.AbsorbDB and GH.modules.AbsorbDB.ImportFile then
    pcall(GH.modules.AbsorbDB.ImportFile, GH.modules.AbsorbDB, file)
    return
  end
  local _,_,mname,toggle = string.find(msg, "^mod%s+(%a+)%s+(%a+)$")
  if mname and toggle then
    local key = mname
    local mod = GH.modules[key]
    if mod then
      local on = (toggle == "on")
      DB.profile.modules[key] = DB.profile.modules[key] or { enabled = on }
      DB.profile.modules[key].enabled = on
      if on and mod.Enable then pcall(mod.Enable, mod, DB.profile.modules[key]) end
      if not on and mod.Disable then pcall(mod.Disable, mod) end
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r module "..key.." = "..(on and "ON" or "OFF"))
      return
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..L["Unknown module"]..": "..key)
      return
    end
  end
  local _,_,mname2,rest = string.find(msg, "^mod%s+(%a+)%s+(.+)$")
  if mname2 and rest then
    local mod = GH.modules[mname2]
    if mod and mod.OnSlash then pcall(mod.OnSlash, mod, rest); return end
  end
  PrintHelp()
end
