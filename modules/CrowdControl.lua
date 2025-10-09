-- GnerdHUD/modules/CrowdControl.lua
-- UTF-8, UNIX LF
-- Simple CC presence indicators on target (placeholder for v0.4.1)

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "CrowdControl" }

local frame, mover

local function Ensure()
  if frame then return end
  local a = GnerdHUDDB.profile.modules.CrowdControl.anchor
  local cfg = GnerdHUDDB.profile.bars
  frame = CreateFrame("Frame", "GnerdHUD_CC", UIParent)
  frame:SetWidth(200); frame:SetHeight(cfg.height+2)
  frame:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local fs = frame:CreateFontString(nil, "OVERLAY")
  fs:SetFont(cfg.font, cfg.fontSize, "OUTLINE")
  fs:SetPoint("CENTER", frame, "CENTER", 0, 0)
  fs:SetText("")
  frame.text = fs
  frame:Hide()
end

local function Update()
  Ensure()
  if not UnitExists("target") then frame:Hide(); return end
  -- Placeholder: show nothing by default. Future versions may scan tooltips/debuff textures.
  frame:Hide()
end

local function CreateMover()
  if mover then return end
  Ensure()
  local b = CreateFrame("Button", "GnerdHUD_CC_Mover", UIParent)
  b:SetWidth(frame:GetWidth()+8); b:SetHeight(frame:GetHeight()+8)
  b:SetPoint("CENTER", frame, "CENTER", 0, 0)
  b:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left=3,right=3,top=3,bottom=3 } })
  b:SetBackdropColor(0,0,0,0.5)
  b:EnableMouse(true); b:RegisterForDrag("LeftButton"); b:SetFrameStrata("DIALOG")
  local fs = b:CreateFontString(nil, "OVERLAY")
  fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE")
  fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  fs:SetText("CC (drag)")
  b:SetScript("OnDragStart", function(self) self:StartMoving() end)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter(); local ux, uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    local a = GnerdHUDDB.profile.modules.CrowdControl.anchor
    a.x = dx; a.y = dy
    frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover = b
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.OnEvent(self, event, unit)
  if event == "PLAYER_TARGET_CHANGED" or unit == "target" then Update() end
end

function M.Enable(self, cfg)
  Ensure()
  Update()
end

function M.Disable(self)
  if frame then frame:Hide() end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
