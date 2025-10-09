-- GnerdHUD/modules/SnD.lua
-- UTF-8, UNIX LF
-- Rogue Slice and Dice timer bar (buff scan of player)

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "SnD" }

local bar, mover
local function Ensure()
  if bar then return end
  local a = GnerdHUDDB.profile.modules.SnD.anchor
  local cfg = GnerdHUDDB.profile.bars
  bar = CreateFrame("StatusBar", "GnerdHUD_SnD", UIParent)
  bar:SetWidth(cfg.width); bar:SetHeight(cfg.height)
  bar:SetStatusBarTexture(cfg.texture)
  bar:SetMinMaxValues(0,1); bar:SetValue(0)
  bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local bg = bar:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(bar); bg:SetTexture(0,0,0,0.5)
  local fs = bar:CreateFontString(nil, "OVERLAY"); fs:SetFont(cfg.font, cfg.fontSize, "OUTLINE"); fs:SetPoint("CENTER", bar, "CENTER", 0, 0); fs:SetText(L["Slice and Dice"])
  bar.text = fs
  bar:Hide()
end

local active = { start=0, dur=0 }
local function FindSnD()
  local idx = 0
  while true do
    idx = idx + 1
    local name = GetPlayerBuffName(idx)
    if not name then break end
    local low = string.lower(name)
    if string.find(low, "slice", 1, true) and string.find(low, "dice", 1, true) then
      local t = GetPlayerBuffTimeLeft and GetPlayerBuffTimeLeft(idx)
      if t and t > 0 then
        return t
      else
        return 0
      end
    end
  end
  return nil
end

local function UpdateBar()
  if active.dur <= 0 then bar:Hide(); bar:SetScript("OnUpdate", nil); return end
  bar:SetScript("OnUpdate", function(self)
    local t = GetTime() - active.start
    local rem = active.dur - t
    if rem < 0 then rem = 0 end
    self:SetMinMaxValues(0, active.dur)
    self:SetValue(rem)
    GH.SetAlphaSmart(self)
    if rem <= 0 then self:Hide(); self:SetScript("OnUpdate", nil); active.dur = 0 end
  end)
  bar:Show()
end

local function Refresh()
  Ensure()
  local t = FindSnD()
  if t and t > 0 then
    active.start = GetTime()
    active.dur = t
    UpdateBar()
  else
    active.dur = 0
    bar:Hide()
  end
end

local function CreateMover()
  if mover then return end
  Ensure()
  local b = CreateFrame("Button", "GnerdHUD_SnD_Mover", UIParent)
  b:SetWidth(bar:GetWidth()+8); b:SetHeight(bar:GetHeight()+8)
  b:SetPoint("CENTER", bar, "CENTER", 0, 0)
  b:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets={ left=3,right=3,top=3,bottom=3 } })
  b:SetBackdropColor(0,0,0,0.5)
  b:EnableMouse(true); b:RegisterForDrag("LeftButton"); b:SetFrameStrata("DIALOG")
  local fs = b:CreateFontString(nil, "OVERLAY")
  fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE")
  fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  fs:SetText("SnD (drag)")
  b:SetScript("OnDragStart", function(self) self:StartMoving() end)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter(); local ux, uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    local a = GnerdHUDDB.profile.modules.SnD.anchor
    a.x = dx; a.y = dy
    bar:ClearAllPoints(); bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover = b
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.OnEvent(self, event, unit)
  if unit == "player" then Refresh() end
end

function M.Enable(self, cfg)
  Ensure()
  Refresh()
end

function M.Disable(self)
  if bar then bar:Hide(); bar:SetScript("OnUpdate", nil) end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
