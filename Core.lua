-- GnerdHUD/core.lua
-- UTF-8, UNIX LF
-- TurtleWoW 1.12 (Lua 5.0)
-- v0.4.3-dev5: 1.12-safe handlers (this/event/argN), mover fix, real rebuild, strata/alpha hotfix, diag, vis

GnerdHUDDB = GnerdHUDDB or { schema = 5, profile = {
  locked = false,
  alpha = { idle = 0.25, combat = 1.0, hasTarget = 0.9 },
  positions = { player={x=-180,y=-40}, target={x=180,y=-40}, absorb={x=0,y=40} },
  bars = { width=180, height=18, texture="Interface\\TargetingFrame\\UI-StatusBar", inset=1, font="Fonts\\FRIZQT__.TTF", fontSize=12, outline="OUTLINE" },
  colors = {
    health={r=0.0,g=1.0,b=0.2},
    power={[0]={r=0.0,g=0.55,b=1.0}, [1]={r=1,g=0,b=0}, [2]={r=1,g=0.5,b=0.25}, [3]={r=1,g=1,b=0}, [4]={r=0.6,g=0,b=0.6}},
  },
  modules = {
    ToT={enabled=true,anchor={x=220,y=-40}}, Pet={enabled=true,anchor={x=-220,y=-80}},
    Castbar={enabled=true,anchor={x=0,y=-120},showLag=true}, Mirror={enabled=true,anchor={x=0,y=140}},
    DruidMana={enabled=true,anchor={x=-180,y=-64}}, Range={enabled=true,mode="simple",anchor={x=180,y=-70}},
    ComboPoints={enabled=true,anchor={x=0,y=-80}}, SnD={enabled=true,anchor={x=0,y=-100}},
    Shards={enabled=true,anchor={x=-300,y=-120}}, CrowdControl={enabled=true,anchor={x=180,y=20}},
    ThreatLite={enabled=true,anchor={x=0,y=20}}, EnergyTicker={enabled=true,anchor={x=0,y=-60}},
    Options={enabled=true}, AbsorbDB={enabled=true},
  },
  absorb = { enabled=true, showLowestBySchool=true, debug=false },
}}
local DB = GnerdHUDDB
local L = GnerdHUD_L or setmetatable({}, { __index=function(t,k) return k end })

-- Namespace
local GH = _G.GnerdHUD or {}; _G.GnerdHUD = GH
GH.modules = GH.modules or {}
GH.bars    = GH.bars    or {}   -- always exists

-- Feature probe
GH.features = GH.features or { superwow=false, hasFileIO=false, auraIdAPI=false, rawCombatLog=false, unitCastEvent=false }
local function ProbeFeatures()
  GH.features.hasFileIO = (type(ExportFile)=="function") and (type(ImportFile)=="function") or false
  GH.features.superwow  = GH.features.hasFileIO or (type(SUPERWOW_VERSION)=="string")
  GH.features.auraIdAPI = (type(GetPlayerBuffID)=="function")
  GH.features.rawCombatLog = false
  GH.features.unitCastEvent = false
end

-- Utils
local VIS_FORCE=nil
local function Clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function SetAlphaSmart(frame)
  if not frame or not frame.SetAlpha then return end
  if VIS_FORCE then frame:SetAlpha(1.0); return end
  local alpha = (DB.profile.alpha and DB.profile.alpha.idle) or 0.25
  if UnitAffectingCombat("player") then
    alpha = (DB.profile.alpha and DB.profile.alpha.combat) or 1.0
  elseif UnitExists("target") then
    alpha = (DB.profile.alpha and DB.profile.alpha.hasTarget) or 0.9
  end
  frame:SetAlpha(Clamp(alpha,0,1))
end
GH.SetAlphaSmart = SetAlphaSmart

local function PowerColorFor(unit)
  local pt = UnitPowerType(unit) or 0
  local c = DB.profile.colors.power[pt] or DB.profile.colors.power[0]
  return c.r, c.g, c.b
end
GH.PowerColorFor = PowerColorFor

-- Bar factory
local function CreateBar(name, unit, kind, x, y)
  local cfg = DB.profile.bars
  local f = CreateFrame("StatusBar", name, UIParent)
  f:SetWidth(cfg.width); f:SetHeight(cfg.height)
  f:SetStatusBarTexture(cfg.texture)
  f:SetMinMaxValues(0, 1); f:SetValue(0)
  f:SetPoint("CENTER", UIParent, "CENTER", x, y)
  f:SetFrameStrata("HIGH"); f:SetFrameLevel(20)

  local bg = f:CreateTexture(name.."_BG", "BACKGROUND")
  bg:SetAllPoints(f); bg:SetTexture(0,0,0,0.5); f.bg = bg

  local fs = f:CreateFontString(name.."_Text", "OVERLAY")
  fs:SetFont(cfg.font, cfg.fontSize, DB.profile.bars.outline)
  fs:SetPoint("CENTER", f, "CENTER", 0, 0)
  fs:SetText(kind.." ??")
  f.text = fs

  f.unit = unit; f.kind = kind
  f.Update = function()
    if f.unit ~= "player" and not UnitExists(f.unit) then f:Hide(); return end
    f:Show()
    if f.kind == "HEALTH" then
      local cur = UnitHealth(f.unit) or 0; local max = UnitHealthMax(f.unit) or 1
      if cur > max then cur = max elseif cur < 0 then cur = 0 end
      f:SetMinMaxValues(0, max); f:SetValue(cur)
      f:SetStatusBarColor(DB.profile.colors.health.r, DB.profile.colors.health.g, DB.profile.colors.health.b)
      local n = UnitName(f.unit) or f.unit; f.text:SetText(n.." "..cur.."/"..max)
    else
      local cur = UnitMana(f.unit) or 0; local max = UnitManaMax(f.unit) or 1
      if cur > max then cur = max elseif cur < 0 then cur = 0 end
      f:SetMinMaxValues(0, max); f:SetValue(cur)
      local r,g,b = PowerColorFor(f.unit); f:SetStatusBarColor(r,g,b)
      local n = UnitName(f.unit) or f.unit; f.text:SetText(n.." "..cur.."/"..max)
    end
    GH.SetAlphaSmart(f)
  end

  f:Hide()
  return f
end

-- Build/replace all 4 bars (rebuild-safe)
local function BuildBars()
  -- hide old if any (avoids stacks after /ghud rebuild)
  if GH.bars.playerHealth then GH.bars.playerHealth:Hide() end
  if GH.bars.playerPower  then GH.bars.playerPower:Hide()  end
  if GH.bars.targetHealth then GH.bars.targetHealth:Hide() end
  if GH.bars.targetPower  then GH.bars.targetPower:Hide()  end

  local px,py = DB.profile.positions.player.x, DB.profile.positions.player.y
  local tx,ty = DB.profile.positions.target.x, DB.profile.positions.target.y
  GH.bars.playerHealth = CreateBar("GnerdHUD_PlayerHealth","player","HEALTH",px,py+10)
  GH.bars.playerPower  = CreateBar("GnerdHUD_PlayerPower","player","POWER", px,py-10)
  GH.bars.targetHealth = CreateBar("GnerdHUD_TargetHealth","target","HEALTH",tx,ty+10)
  GH.bars.targetPower  = CreateBar("GnerdHUD_TargetPower","target","POWER", tx,ty-10)
end

local function EnsureBars()
  if not (GH.bars and GH.bars.playerHealth and GH.bars.playerPower and GH.bars.targetHealth and GH.bars.targetPower) then
    BuildBars()
  end
end

local function UpdateAllBars()
  if not GH.bars then return end
  if GH.bars.playerHealth then GH.bars.playerHealth.Update() end
  if GH.bars.playerPower  then GH.bars.playerPower.Update()  end
  if GH.bars.targetHealth then GH.bars.targetHealth.Update() end
  if GH.bars.targetPower  then GH.bars.targetPower.Update()  end
end
GH.UpdateAllBars = UpdateAllBars

-- Absorb text
GH.Absorb = GH.Absorb or { frame=nil, schools={"physical","holy","fire","nature","frost","shadow","arcane"}, active={}, effects={}, auraIndexByBuff={}, superMode=false }
function GH.Absorb:EnsureFrame()
  if self.frame then return end
  local cfg = DB.profile.bars
  local f = CreateFrame("Frame","GnerdHUD_Absorb",UIParent)
  f:SetWidth(200); f:SetHeight(24)
  f:SetPoint("CENTER",UIParent,"CENTER",DB.profile.positions.absorb.x,DB.profile.positions.absorb.y)
  f:SetFrameStrata("HIGH"); f:SetFrameLevel(21)
  local fs = f:CreateFontString("GnerdHUD_AbsorbText","OVERLAY")
  fs:SetFont(cfg.font,cfg.fontSize+2,"OUTLINE"); fs:SetPoint("CENTER",f,"CENTER",0,0); fs:SetText("Absorb: 0")
  f.text = fs
  self.frame = f
end
function GH.Absorb:SetDebug(msg) if not DB.profile.absorb.debug then return end DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff[GnerdHUD Absorb]|r "..msg) end
local function minPositive(a,b) if not a then return b end if not b then return a end if a<=0 then return b end if b<=0 then return a end if a<b then return a else return b end end
function GH.Absorb:Recalculate()
  local lowest; local i; for i=1,table.getn(self.schools) do local s=self.schools[i]; local v=self.active[s]; lowest=minPositive(lowest,v) end
  self:EnsureFrame(); if not DB.profile.absorb.enabled then self.frame:Hide(); return end; self.frame:Show()
  self.frame.text:SetText(L["Absorb"]..": "..(lowest or 0)); GH.SetAlphaSmart(self.frame)
end
function GH.Absorb:ClearAll() self.active = {}; self:Recalculate() end
function GH.Absorb:RebuildFromAuras()
  self:ClearAll()
  local idx=0
  while true do
    idx=idx+1; local name=GetPlayerBuffName(idx); if not name then break end
    local key=name; local auraId
    if GH.features.auraIdAPI then auraId=GetPlayerBuffID(idx); if auraId then key="id:"..auraId end end
    local eff=self.effects[key]
    if not eff then
      local low=string.lower(name); local isWard=string.find(low,"ward",1,true)
      local schools
      if isWard then
        if string.find(low,"fire",1,true) then schools={"fire"}
        elseif string.find(low,"frost",1,true) then schools={"frost"}
        elseif string.find(low,"shadow",1,true) then schools={"shadow"} else schools={"holy"} end
      else schools={"physical"} end
      eff={ schools=schools, amount=0, source="buff" }
    end
    local amount=eff.amount or 0; if amount<=0 then amount=1 end
    local j; for j=1,table.getn(eff.schools) do local s=eff.schools[j]; self.active[s]=(self.active[s] or 0)+amount end
  end
  self:Recalculate()
end
local function contains(h,n) return string.find(h,n,1,true)~=nil end
local function parseNumberBefore(h,w) local p=string.find(h,w,1,true); if not p then return nil end; local i=p-1; local s=i; while i>=1 do local c=string.sub(h,i,i); if c<"0" or c>"9" then break end s=i; i=i-1 end; return tonumber(string.sub(h,s,p-2)) end
local function inferSchool(line) local low=string.lower(line); if contains(low,"fire") then return "fire" end; if contains(low,"frost") then return "frost" end; if contains(low,"shadow") then return "shadow" end; if contains(low,"arcane") then return "arcane" end; if contains(low,"nature") then return "nature" end; if contains(low,"holy") then return "holy" end; return "physical" end
function GH.Absorb:OnRawCombatLog(line)
  if not GH.features.rawCombatLog then GH.features.rawCombatLog=true; self:SetDebug("RAW_COMBATLOG detected; absorb decrementer active.") end
  local low=string.lower(line or ""); if not contains(low,"absorb") then return end
  local dmg=parseNumberBefore(line," absorb"); if not dmg or dmg<=0 then return end
  local s=inferSchool(line); if not self.active[s] then return end
  self.active[s]=self.active[s]-dmg; if self.active[s]<0 then self.active[s]=0 end; self:Recalculate()
end

-- Module registry
function GH:RegisterModule(name, mod) if name and mod then GH.modules[name]=mod end end
local function EnableConfiguredModules() local n,cfg,mod; for n,cfg in pairs(DB.profile.modules) do mod=GH.modules[n]; if mod and cfg and cfg.enabled and mod.Enable then pcall(mod.Enable,mod,cfg) end end end

-- Root frame and watchdog (1.12-safe scripts use globals this/event/arg1)
local root = CreateFrame("Frame","GnerdHUD_Root",UIParent); GH.root=root
local wdFrames = 8
local function StartWatchdog()
  wdFrames = 8
  root:SetScript("OnUpdate", function()
    if wdFrames > 0 then
      wdFrames = wdFrames - 1
      EnsureBars(); UpdateAllBars(); GH.Absorb:EnsureFrame(); GH.Absorb:Recalculate()
      if wdFrames == 0 then root:SetScript("OnUpdate", nil) end
    end
  end)
end

local function RegisterEvents()
  root:RegisterEvent("VARIABLES_LOADED")
  root:RegisterEvent("PLAYER_LOGIN")
  root:RegisterEvent("PLAYER_ENTERING_WORLD")
  root:RegisterEvent("PLAYER_REGEN_DISABLED"); root:RegisterEvent("PLAYER_REGEN_ENABLED")
  root:RegisterEvent("PLAYER_TARGET_CHANGED")
  root:RegisterEvent("UNIT_HEALTH"); root:RegisterEvent("UNIT_MAXHEALTH")
  root:RegisterEvent("UNIT_MANA"); root:RegisterEvent("UNIT_MAXMANA"); root:RegisterEvent("UNIT_ENERGY"); root:RegisterEvent("UNIT_RAGE"); root:RegisterEvent("UNIT_DISPLAYPOWER")
  root:RegisterEvent("UNIT_AURA"); root:RegisterEvent("UNIT_PET")
  root:RegisterEvent("RAID_TARGET_UPDATE")
  root:RegisterEvent("RAW_COMBATLOG"); root:RegisterEvent("UNIT_CASTEVENT")
  root:RegisterEvent("MIRROR_TIMER_START"); root:RegisterEvent("MIRROR_TIMER_STOP"); root:RegisterEvent("MIRROR_TIMER_PAUSE")
  root:RegisterEvent("SPELLCAST_START"); root:RegisterEvent("SPELLCAST_STOP"); root:RegisterEvent("SPELLCAST_FAILED"); root:RegisterEvent("SPELLCAST_INTERRUPTED"); root:RegisterEvent("SPELLCAST_CHANNEL_START"); root:RegisterEvent("SPELLCAST_CHANNEL_STOP")
  root:RegisterEvent("BAG_UPDATE"); root:RegisterEvent("PLAYER_COMBO_POINTS")
end

local function OnEvent()
  if event=="VARIABLES_LOADED" then
    ProbeFeatures(); EnsureBars(); UpdateAllBars(); GH.Absorb:EnsureFrame(); GH.Absorb:Recalculate(); StartWatchdog()

  elseif event=="PLAYER_LOGIN" then
    EnsureBars(); UpdateAllBars(); GH.Absorb:EnsureFrame(); GH.Absorb:Recalculate(); EnableConfiguredModules(); StartWatchdog()
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r v"..(GetAddOnMetadata and GetAddOnMetadata("GnerdHUD","Version") or "0.4.x")..(GH.features.superwow and " | SuperWoW: ON" or " | SuperWoW: OFF"))

  elseif event=="PLAYER_ENTERING_WORLD" or event=="RAID_TARGET_UPDATE" then
    UpdateAllBars()

  elseif event=="PLAYER_TARGET_CHANGED" then
    UpdateAllBars()
    if GH.modules.ToT and GH.modules.ToT.OnEvent then pcall(GH.modules.ToT.OnEvent,GH.modules.ToT,event) end
    if GH.modules.Range and GH.modules.Range.OnEvent then pcall(GH.modules.Range.OnEvent,GH.modules.Range,event) end
    if GH.modules.CrowdControl and GH.modules.CrowdControl.OnEvent then pcall(GH.modules.CrowdControl.OnEvent,GH.modules.CrowdControl,event) end
    if GH.modules.ThreatLite and GH.modules.ThreatLite.OnEvent then pcall(GH.modules.ThreatLite.OnEvent,GH.modules.ThreatLite,event) end

  elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" then
    UpdateAllBars(); GH.Absorb:Recalculate()

  elseif event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH" then
    if arg1=="player" and GH.bars.playerHealth then GH.bars.playerHealth.Update() end
    if arg1=="target" and GH.bars.targetHealth then GH.bars.targetHealth.Update() end
    if arg1=="pet" and GH.modules.Pet and GH.modules.Pet.OnEvent then pcall(GH.modules.Pet.OnEvent,GH.modules.Pet,event,arg1) end
    if arg1=="targettarget" and GH.modules.ToT and GH.modules.ToT.OnEvent then pcall(GH.modules.ToT.OnEvent,GH.modules.ToT,event,arg1) end

  elseif event=="UNIT_MANA" or event=="UNIT_MAXMANA" or event=="UNIT_RAGE" or event=="UNIT_ENERGY" or event=="UNIT_DISPLAYPOWER" then
    if arg1=="player" and GH.bars.playerPower then GH.bars.playerPower.Update() end
    if arg1=="target" and GH.bars.targetPower then GH.bars.targetPower.Update() end
    if GH.modules.DruidMana and GH.modules.DruidMana.OnEvent then pcall(GH.modules.DruidMana.OnEvent,GH.modules.DruidMana,event,arg1) end
    if GH.modules.Pet and GH.modules.Pet.OnEvent then pcall(GH.modules.Pet.OnEvent,GH.modules.Pet,event,arg1) end
    if GH.modules.Castbar and GH.modules.Castbar.OnEvent then pcall(GH.modules.Castbar.OnEvent,GH.modules.Castbar,event,arg1) end
    if GH.modules.EnergyTicker and GH.modules.EnergyTicker.OnEvent then pcall(GH.modules.EnergyTicker.OnEvent,GH.modules.EnergyTicker,event,arg1) end

  elseif event=="UNIT_AURA" then
    if arg1=="player" then GH.Absorb:RebuildFromAuras() end
    if GH.modules.SnD and GH.modules.SnD.OnEvent then pcall(GH.modules.SnD.OnEvent,GH.modules.SnD,event,arg1) end
    if GH.modules.CrowdControl and GH.modules.CrowdControl.OnEvent then pcall(GH.modules.CrowdControl.OnEvent,GH.modules.CrowdControl,event,arg1) end

  elseif event=="UNIT_PET" then
    if GH.modules.Pet and GH.modules.Pet.OnEvent then pcall(GH.modules.Pet.OnEvent,GH.modules.Pet,event,arg1) end

  elseif event=="RAW_COMBATLOG" and type(arg2)=="string" then
    GH.Absorb:OnRawCombatLog(arg2)
    if GH.modules.Castbar and GH.modules.Castbar.OnRawCombatLog then pcall(GH.modules.Castbar.OnRawCombatLog,GH.modules.Castbar,arg2) end

  elseif event=="UNIT_CASTEVENT" then
    GH.features.unitCastEvent=true
    if GH.modules.Castbar and GH.modules.Castbar.OnCastEvent then pcall(GH.modules.Castbar.OnCastEvent,GH.modules.Castbar,arg1,arg2,arg3,arg4,arg5) end

  elseif event=="MIRROR_TIMER_START" or event=="MIRROR_TIMER_STOP" or event=="MIRROR_TIMER_PAUSE" then
    if GH.modules.Mirror and GH.modules.Mirror.OnEvent then pcall(GH.modules.Mirror.OnEvent,GH.modules.Mirror,event,arg1,arg2) end

  elseif event=="SPELLCAST_START" or event=="SPELLCAST_STOP" or event=="SPELLCAST_FAILED" or event=="SPELLCAST_INTERRUPTED" or event=="SPELLCAST_CHANNEL_START" or event=="SPELLCAST_CHANNEL_STOP" then
    if GH.modules.Castbar and GH.modules.Castbar.OnEvent then pcall(GH.modules.Castbar.OnEvent,GH.modules.Castbar,event,arg1) end

  elseif event=="BAG_UPDATE" then
    if GH.modules.Shards and GH.modules.Shards.OnEvent then pcall(GH.modules.Shards.OnEvent,GH.modules.Shards,event) end

  elseif event=="PLAYER_COMBO_POINTS" then
    if GH.modules.ComboPoints and GH.modules.ComboPoints.OnEvent then pcall(GH.modules.ComboPoints.OnEvent,GH.modules.ComboPoints,event) end
  end
end
root:SetScript("OnEvent", OnEvent)
RegisterEvents()

-- Movers / Locking (use 1.12 'this')
local function CreateMover(title, attachFrame, key)
  local m = CreateFrame("Button", title.."_Mover", UIParent)
  m:SetWidth(attachFrame:GetWidth()+8); m:SetHeight(attachFrame:GetHeight()+8)
  m:SetPoint("CENTER", attachFrame, "CENTER", 0, 0)
  m:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={left=3,right=3,top=3,bottom=3} })
  m:SetBackdropColor(0,0,0,0.5)
  m:SetFrameStrata("DIALOG")
  m:SetMovable(true); m:EnableMouse(true); m:RegisterForDrag("LeftButton")

  local label = m:CreateFontString(nil, "OVERLAY")
  label:SetFont(DB.profile.bars.font, 12, "OUTLINE"); label:SetPoint("CENTER", m, "CENTER", 0, 0); label:SetText(title.." (drag)")

  m:SetScript("OnDragStart", function() this:StartMoving() end)
  m:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local cx,cy = this:GetCenter(); local ux,uy = UIParent:GetCenter()
    local dx = cx-ux; local dy = cy-uy
    DB.profile.positions[key].x = math.floor(dx+0.5)
    DB.profile.positions[key].y = math.floor(dy+0.5)
    attachFrame:ClearAllPoints()
    attachFrame:SetPoint("CENTER", UIParent, "CENTER", DB.profile.positions[key].x, DB.profile.positions[key].y)
  end)

  m:Hide()
  return m
end

GH.movers = GH.movers or {}
local function EnsureMovers()
  EnsureBars()
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
    local k,mod; for k,mod in pairs(GH.modules) do if mod.SetLocked then pcall(mod.SetLocked,mod,true) end end
  else
    GH.movers.player:Show(); GH.movers.target:Show(); GH.movers.absorb:Show()
    local k,mod; for k,mod in pairs(GH.modules) do if mod.SetLocked then pcall(mod.SetLocked,mod,false) end end
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..(DB.profile.locked and L["Locked"] or L["Unlocked"]))
end
GH.SetLocked = SetLocked

-- Slash
SlashCmdList = SlashCmdList or {}; SLASH_GNERDHUD1="/gnerdhud"; SLASH_GNERDHUD2="/ghud"
local function barsState()
  local b=GH.bars or {}; local on=function(x) return (x and x:IsShown()) and "ON" or ((x and not x:IsShown()) and "off" or "nil") end
  return "PH="..on(b.playerHealth).." PP="..on(b.playerPower).." TH="..on(b.targetHealth).." TP="..on(b.targetPower)
end
local function PrintHelp()
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..(GetAddOnMetadata and GetAddOnMetadata("GnerdHUD","Version") or ""))
  DEFAULT_CHAT_FRAME:AddMessage("/ghud lock|unlock")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud alpha idle|combat|target <0.0-1.0>")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud vis on|off  - force max alpha for debugging")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud test, /ghud rebuild, /ghud diag")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud absorb on|off|debug|import <file>")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud mod <name> on|off")
  DEFAULT_CHAT_FRAME:AddMessage("/ghud options  - open simple options panel")
end
local function PrintDiag()
  local a = DB.profile.alpha or {}
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff[GnerdHUD Diag]|r schema="..tostring(DB.schema))
  DEFAULT_CHAT_FRAME:AddMessage(string.format("alpha idle=%.2f combat=%.2f target=%.2f", a.idle or 0.25, a.combat or 1.0, a.hasTarget or 0.9))
  DEFAULT_CHAT_FRAME:AddMessage("bars: "..barsState())
  DEFAULT_CHAT_FRAME:AddMessage("features: superwow="..tostring(GH.features.superwow).." fileIO="..tostring(GH.features.hasFileIO).." auraIdAPI="..tostring(GH.features.auraIdAPI).." unitCastEvent="..tostring(GH.features.unitCastEvent))
  local mods="modules:"; if DB.profile.modules then for name,cfg in pairs(DB.profile.modules) do mods=mods.." "..name.."="..((cfg and cfg.enabled) and "ON" or "off") end else mods=mods.." n/a" end
  DEFAULT_CHAT_FRAME:AddMessage(mods)
end

SlashCmdList["GNERDHUD"]=function(msg)
  msg = msg or ""; while string.find(msg,"^%s") do msg = string.sub(msg,2) end
  if msg=="" or msg=="help" then PrintHelp(); return end
  if msg=="lock" then SetLocked(true); return end
  if msg=="unlock" then SetLocked(false); return end
  if msg=="test" then EnsureBars(); UpdateAllBars(); GH.Absorb:Recalculate(); DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r Test updated."); return end
  if msg=="diag" then PrintDiag(); return end
  if msg=="rebuild" then BuildBars(); UpdateAllBars(); EnsureMovers(); DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r rebuilt ("..barsState()..")"); return end
  if msg=="vis on" then VIS_FORCE=true; UpdateAllBars(); GH.Absorb:Recalculate(); DEFAULT_CHAT_FRAME:AddMessage("GnerdHUD vis: FORCED"); return end
  if msg=="vis off" then VIS_FORCE=nil; UpdateAllBars(); GH.Absorb:Recalculate(); DEFAULT_CHAT_FRAME:AddMessage("GnerdHUD vis: normal"); return end

  local _,_,what,val = string.find(msg, "^alpha%s+(%a+)%s+([%d%.]+)$")
  if what and val then
    local n = tonumber(val)
    if n then
      if what=="idle" then DB.profile.alpha.idle=Clamp(n,0,1)
      elseif what=="combat" then DB.profile.alpha.combat=Clamp(n,0,1)
      elseif what=="target" then DB.profile.alpha.hasTarget=Clamp(n,0,1) end
      UpdateAllBars(); GH.Absorb:Recalculate()
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r alpha "..what.." = "..Clamp(n,0,1))
      return
    end
  end

  local _,_,abs = string.find(msg, "^absorb%s+(%a+)$")
  if abs then
    if abs=="on" then DB.profile.absorb.enabled=true; GH.Absorb:RebuildFromAuras(); return end
    if abs=="off" then DB.profile.absorb.enabled=false; GH.Absorb:Recalculate(); return end
    if abs=="debug" then DB.profile.absorb.debug=not DB.profile.absorb.debug; DEFAULT_CHAT_FRAME:AddMessage("Absorb debug: "..(DB.profile.absorb.debug and "ON" or "OFF")); return end
  end
  local _,_,imp,file = string.find(msg, "^absorb%s+(import)%s+(.+)$")
  if imp and file and GH.modules.AbsorbDB and GH.modules.AbsorbDB.ImportFile then pcall(GH.modules.AbsorbDB.ImportFile, GH.modules.AbsorbDB, file); return end

  local _,_,mname,toggle = string.find(msg, "^mod%s+(%a+)%s+(%a+)$")
  if mname and toggle then
    local mod=GH.modules[mname]
    if mod then
      local on = (toggle=="on")
      DB.profile.modules[mname]=DB.profile.modules[mname] or {enabled=on}
      DB.profile.modules[mname].enabled=on
      if on and mod.Enable then pcall(mod.Enable,mod,DB.profile.modules[mname]) end
      if not on and mod.Disable then pcall(mod.Disable,mod) end
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r module "..mname.." = "..(on and "ON" or "OFF"))
      return
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r "..L["Unknown module"]..": "..mname); return
    end
  end

  local _,_,mname2,rest = string.find(msg, "^mod%s+(%a+)%s+(.+)$")
  if mname2 and rest then local mod=GH.modules[mname2]; if mod and mod.OnSlash then pcall(mod.OnSlash,mod,rest); return end end

  PrintHelp()
end
