-- GnerdHUD/modules/Mirror.lua
-- UTF-8, UNIX LF
-- Breath/Exhaustion/Feign mirror timers. Uses MIRROR_TIMER_* events and GetMirrorTimerInfo.

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "Mirror" }

local bars = {}
local mover
local order = { "BREATH", "EXHAUSTION", "FEIGNDEATH" }

local function Ensure()
  if bars["BREATH"] then return end
  local a = GnerdHUDDB.profile.modules.Mirror.anchor
  local cfg = GnerdHUDDB.profile.bars
  local i
  for i=1, 3 do
    local key = order[i]
    local b = CreateFrame("StatusBar", "GnerdHUD_Mirror_"..key, UIParent)
    b:SetWidth(cfg.width); b:SetHeight(math.max(10, cfg.height-4))
    b:SetStatusBarTexture(cfg.texture)
    b:SetMinMaxValues(0, 1); b:SetValue(0)
    b:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y + ((3-i)* (b:GetHeight()+4)))
    local bg = b:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(b); bg:SetTexture(0,0,0,0.5)
    local fs = b:CreateFontString(nil,"OVERLAY"); fs:SetFont(cfg.font, math.max(10,cfg.fontSize-2), "OUTLINE"); fs:SetPoint("CENTER", b, "CENTER", 0, 0); fs:SetText(key)
    b.text = fs
    bars[key] = b
    b:Hide()
  end
end

local function UpdateAll()
  Ensure()
  local i
  for i=1, 3 do
    local name, text, value, maxvalue = GetMirrorTimerInfo(i)
    if name and bars[name] then
      local b = bars[name]
      b:SetMinMaxValues(0, maxvalue or 1)
      b:SetValue(value or 0)
      b.text:SetText(name)
      if value and value > 0 then b:Show() else b:Hide() end
      GH.SetAlphaSmart(b)
    end
  end
end

local function CreateMover()
  if mover then return end
  Ensure()
  local a = GnerdHUDDB.profile.modules.Mirror.anchor
  mover = CreateFrame("Button", "GnerdHUD_Mirror_Mover", UIParent)
  mover:SetWidth(bars["BREATH"]:GetWidth()+8); mover:SetHeight((bars["BREATH"]:GetHeight()*3)+16)
  mover:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y + (bars["BREATH"]:GetHeight()))
  mover:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={ left=3,right=3,top=3,bottom=3 } })
  mover:SetBackdropColor(0,0,0,0.4)
  mover:EnableMouse(true); mover:RegisterForDrag("LeftButton"); mover:SetFrameStrata("DIALOG")
  local fs = mover:CreateFontString(nil,"OVERLAY"); fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE"); fs:SetPoint("CENTER", mover, "CENTER", 0, 0); fs:SetText("Mirror (drag)")
  mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
  mover:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx,cy = self:GetCenter(); local ux,uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    a.x = dx; a.y = dy - bars["BREATH"]:GetHeight()
    local i
    for i=1,3 do
      local key = order[i]; local b = bars[key]
      b:ClearAllPoints(); b:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y + ((3-i)* (b:GetHeight()+4)))
    end
    mover:ClearAllPoints(); mover:SetPoint("CENTER", UIParent, "CENTER", dx, dy)
  end)
  mover:Hide()
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.OnEvent(self, event)
  UpdateAll()
end

function M.Enable(self, cfg)
  Ensure()
  UpdateAll()
end

function M.Disable(self)
  local i
  for i=1,3 do local key=order[i]; if bars[key] then bars[key]:Hide() end end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
