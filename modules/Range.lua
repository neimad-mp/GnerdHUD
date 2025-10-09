-- GnerdHUD/modules/Range.lua
-- UTF-8, UNIX LF
-- Lightweight target range indicator using CheckInteractDistance buckets (no polling timers, event-driven).

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "Range" }

local textFrame, mover

local function Ensure()
  if textFrame then return end
  local a = GnerdHUDDB.profile.modules.Range.anchor
  local cfg = GnerdHUDDB.profile.bars
  textFrame = CreateFrame("Frame", "GnerdHUD_Range", UIParent)
  textFrame:SetWidth(60); textFrame:SetHeight(cfg.height+2)
  textFrame:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local fs = textFrame:CreateFontString(nil, "OVERLAY")
  fs:SetFont(cfg.font, cfg.fontSize, "OUTLINE")
  fs:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
  fs:SetText("")
  textFrame.text = fs
  textFrame:Hide()
end

local function CreateMover()
  if mover then return end
  Ensure()
  local b = CreateFrame("Button", "GnerdHUD_Range_Mover", UIParent)
  b:SetWidth(textFrame:GetWidth()+8); b:SetHeight(textFrame:GetHeight()+8)
  b:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
  b:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left=3,right=3,top=3,bottom=3 } })
  b:SetBackdropColor(0,0,0,0.5)
  b:EnableMouse(true); b:RegisterForDrag("LeftButton"); b:SetFrameStrata("DIALOG")
  local fs = b:CreateFontString(nil, "OVERLAY")
  fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE")
  fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  fs:SetText("Range (drag)")
  b:SetScript("OnDragStart", function(self) self:StartMoving() end)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter(); local ux, uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    local a = GnerdHUDDB.profile.modules.Range.anchor
    a.x = dx; a.y = dy
    textFrame:ClearAllPoints(); textFrame:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover = b
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

local function UpdateRange()
  if not UnitExists("target") then
    if textFrame then textFrame:Hide() end
    return
  end
  Ensure()
  textFrame:Show()
  local within10 = CheckInteractDistance and CheckInteractDistance("target", 3)
  local within28 = CheckInteractDistance and CheckInteractDistance("target", 4)
  local label
  if within10 then
    label = L["RANGE_10"]
  elseif within28 then
    label = L["RANGE_28"]
  else
    label = L["RANGE_GT28"]
  end
  textFrame.text:SetText(label)
  GH.SetAlphaSmart(textFrame)
end

function M.OnEvent(self, event)
  if event == "PLAYER_TARGET_CHANGED" then
    UpdateRange(); return
  end
  UpdateRange()
end

function M.Enable(self, cfg)
  Ensure()
  UpdateRange()
end

function M.Disable(self)
  if textFrame then textFrame:Hide() end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
