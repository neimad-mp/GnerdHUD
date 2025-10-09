-- GnerdHUD/modules/Castbar.lua
-- UTF-8, UNIX LF
-- Player cast/channel bar with optional lag indicator. Works with vanilla SPELLCAST_* and SuperWoW UNIT_CASTEVENT.

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "Castbar" }

local bar, lagTex, mover
local cast = { active=false, start=0, dur=0, channeled=false, spell="" }
local lastSend = nil

local function Ensure()
  if bar then return end
  local a = GnerdHUDDB.profile.modules.Castbar.anchor
  local cfg = GnerdHUDDB.profile.bars
  bar = CreateFrame("StatusBar", "GnerdHUD_Castbar", UIParent)
  bar:SetWidth(cfg.width); bar:SetHeight(cfg.height)
  bar:SetStatusBarTexture(cfg.texture)
  bar:SetMinMaxValues(0,1); bar:SetValue(0)
  bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local bg = bar:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(bar); bg:SetTexture(0,0,0,0.5)
  local fs = bar:CreateFontString(nil,"OVERLAY"); fs:SetFont(cfg.font, cfg.fontSize, "OUTLINE"); fs:SetPoint("CENTER", bar, "CENTER", 0, 0); fs:SetText(L["Casting"])
  bar.text = fs
  if GnerdHUDDB.profile.modules.Castbar.showLag then
    lagTex = bar:CreateTexture(nil, "OVERLAY")
    lagTex:SetTexture(1,0,0,0.25)
    lagTex:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    lagTex:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    lagTex:SetWidth(1)
  end
  bar:Hide()
end

local function StopCast()
  cast.active=false; cast.channeled=false; cast.spell=""; cast.start=0; cast.dur=0
  if bar then bar:Hide(); bar:SetScript("OnUpdate", nil) end
end

local function StartCast(name, duration, channeled)
  Ensure()
  cast.active=true; cast.spell=name or ""; cast.dur=duration or 0; cast.start=GetTime(); cast.channeled = channeled and true or false
  bar.text:SetText(cast.channeled and L["Channeling"] or L["Casting"])
  bar:SetMinMaxValues(0, cast.dur)
  bar:SetScript("OnUpdate", function(self)
    local t = GetTime() - cast.start
    local v = cast.channeled and (cast.dur - t) or t
    if v < 0 then v = 0 end
    if v > cast.dur then v = cast.dur end
    self:SetValue(v)
    GH.SetAlphaSmart(self)
    if lagTex and lastSend then
      local lag = (GetTime() - lastSend)
      if lag < 0 then lag = 0 end
      local w = (lag / cast.dur) * self:GetWidth()
      if w < 0 then w = 0 end
      if w > self:GetWidth() then w = self:GetWidth() end
      lagTex:SetWidth(w)
    end
    if t >= cast.dur then StopCast() end
  end)
  bar:Show()
end

local function DefaultCastDuration()
  return 2.5
end

local function CreateMover()
  if mover then return end
  Ensure()
  local a = GnerdHUDDB.profile.modules.Castbar.anchor
  mover = CreateFrame("Button", "GnerdHUD_Castbar_Mover", UIParent)
  mover:SetWidth(bar:GetWidth()+8); mover:SetHeight(bar:GetHeight()+8)
  mover:SetPoint("CENTER", bar, "CENTER", 0, 0)
  mover:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={ left=3,right=3,top=3,bottom=3 } })
  mover:SetBackdropColor(0,0,0,0.5)
  mover:EnableMouse(true); mover:RegisterForDrag("LeftButton"); mover:SetFrameStrata("DIALOG")
  local fs = mover:CreateFontString(nil,"OVERLAY"); fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE"); fs:SetPoint("CENTER", mover, "CENTER", 0, 0); fs:SetText("Castbar (drag)")
  mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
  mover:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx,cy = self:GetCenter(); local ux,uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    a.x = dx; a.y = dy
    bar:ClearAllPoints(); bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover:Hide()
end

function M.OnEvent(self, event, unit)
  if event == "SPELLCAST_START" and (unit == nil or unit == "player") then
    StartCast("spell", DefaultCastDuration(), false)
  elseif event == "SPELLCAST_CHANNEL_START" and (unit == nil or unit == "player") then
    StartCast("channel", DefaultCastDuration(), true)
  elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" or event == "SPELLCAST_CHANNEL_STOP" then
    StopCast()
  end
end

function M.OnCastEvent(self, unit, evt, name, rank, ms)
  if unit ~= "player" then return end
  if evt == "CAST_START" then
    lastSend = GetTime()
    local d = (ms and (ms/1000.0)) or DefaultCastDuration()
    StartCast(name or "spell", d, false)
  elseif evt == "CAST_CHANNEL_START" then
    lastSend = GetTime()
    local d = (ms and (ms/1000.0)) or DefaultCastDuration()
    StartCast(name or "channel", d, true)
  elseif evt == "CAST_STOP" or evt == "CAST_FAILED" or evt == "CAST_INTERRUPTED" then
    StopCast()
  end
end

function M.OnRawCombatLog(self, line)
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.Enable(self, cfg)
  Ensure()
end

function M.Disable(self)
  StopCast()
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
