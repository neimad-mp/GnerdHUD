-- GnerdHUD/modules/EnergyTicker.lua
-- UTF-8, UNIX LF
-- Rogue/Druid (cat) 2-second energy tick visualizer.
-- Logic: bar cycles every 2.0s. Reset early on observed energy gain or power-type changes.

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "EnergyTicker" }

local bar, mover
local TICK = 2.0
local state = { start=0, dur=TICK, lastEnergy=0, lastPT=0, enabled=false }

local function Ensure()
  if bar then return end
  local a = GnerdHUDDB.profile.modules.EnergyTicker.anchor
  local cfg = GnerdHUDDB.profile.bars
  bar = CreateFrame("StatusBar", "GnerdHUD_EnergyTicker", UIParent)
  bar:SetWidth(cfg.width); bar:SetHeight(cfg.height-2)
  bar:SetStatusBarTexture(cfg.texture)
  bar:SetMinMaxValues(0, TICK); bar:SetValue(0)
  bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local bg = bar:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(bar); bg:SetTexture(0,0,0,0.5)
  local fs = bar:CreateFontString(nil, "OVERLAY"); fs:SetFont(cfg.font, cfg.fontSize-1, "OUTLINE"); fs:SetPoint("CENTER", bar, "CENTER", 0, 0); fs:SetText(L["Energy Ticker"])
  bar.text = fs
  bar:Hide()
end

local function IsEnergyUser()
  local pt = UnitPowerType("player") or 0
  if pt == 3 then return true end -- energy
  return false
end

local function ResetTick()
  state.start = GetTime()
  state.dur = TICK
end

local function Start()
  Ensure()
  if not bar then return end
  state.enabled = true
  ResetTick()
  bar:SetScript("OnUpdate", function(self)
    local t = GetTime() - state.start
    if t > state.dur then
      ResetTick()
      t = 0
    end
    self:SetMinMaxValues(0, state.dur)
    self:SetValue(state.dur - t) -- countdown style
    GH.SetAlphaSmart(self)
  end)
  bar:Show()
end

local function Stop()
  state.enabled = false
  if bar then bar:Hide(); bar:SetScript("OnUpdate", nil) end
end

local function CreateMover()
  if mover then return end
  Ensure()
  local b = CreateFrame("Button", "GnerdHUD_EnergyTicker_Mover", UIParent)
  b:SetWidth(bar:GetWidth()+8); b:SetHeight(bar:GetHeight()+8)
  b:SetPoint("CENTER", bar, "CENTER", 0, 0)
  b:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left=3,right=3,top=3,bottom=3 } })
  b:SetBackdropColor(0,0,0,0.5)
  b:EnableMouse(true); b:RegisterForDrag("LeftButton"); b:SetFrameStrata("DIALOG")
  local fs = b:CreateFontString(nil, "OVERLAY")
  fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE")
  fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  fs:SetText("Energy (drag)")
  b:SetScript("OnDragStart", function(self) self:StartMoving() end)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter(); local ux, uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    local a = GnerdHUDDB.profile.modules.EnergyTicker.anchor
    a.x = dx; a.y = dy
    bar:ClearAllPoints(); bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover = b
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

local function MaybeStartOrStop()
  if IsEnergyUser() then
    if not state.enabled then
      state.lastEnergy = UnitMana("player") or 0
      state.lastPT = 3
      Start()
    end
  else
    Stop()
  end
end

local function OnEnergyUpdate()
  if not state.enabled then return end
  local cur = UnitMana("player") or 0
  if cur > state.lastEnergy then
    ResetTick()
  end
  state.lastEnergy = cur
end

function M.OnEvent(self, event, unit)
  if unit == "player" then
    if event == "UNIT_DISPLAYPOWER" then
      MaybeStartOrStop()
    elseif event == "UNIT_ENERGY" then
      OnEnergyUpdate()
    end
  end
end

function M.Enable(self, cfg)
  Ensure()
  MaybeStartOrStop()
end

function M.Disable(self)
  Stop()
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
