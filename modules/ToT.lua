-- GnerdHUD/modules/ToT.lua
-- UTF-8, UNIX LF
-- Target-of-Target health/power micro bars.

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "ToT" }

local bars = { hp=nil, pow=nil }
local mover

local function Ensure()
  if bars.hp then return end
  local a = GnerdHUDDB.profile.modules.ToT.anchor
  local cfg = GnerdHUDDB.profile.bars
  local w, h = math.floor(cfg.width * 0.70), math.max(12, cfg.height - 4)

  bars.hp = CreateFrame("StatusBar", "GnerdHUD_ToT_HP", UIParent)
  bars.hp:SetWidth(w); bars.hp:SetHeight(h)
  bars.hp:SetStatusBarTexture(cfg.texture)
  bars.hp:SetMinMaxValues(0, 1); bars.hp:SetValue(0)
  bars.hp:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y + (h/2)+2)
  local bg1 = bars.hp:CreateTexture(nil, "BACKGROUND"); bg1:SetAllPoints(bars.hp); bg1:SetTexture(0,0,0,0.5)
  local fs1 = bars.hp:CreateFontString(nil, "OVERLAY"); fs1:SetFont(cfg.font, math.max(10, cfg.fontSize-2), "OUTLINE"); fs1:SetPoint("CENTER", bars.hp, "CENTER", 0, 0); fs1:SetText("ToT HP")
  bars.hp.text = fs1

  bars.pow = CreateFrame("StatusBar", "GnerdHUD_ToT_POW", UIParent)
  bars.pow:SetWidth(w); bars.pow:SetHeight(h)
  bars.pow:SetStatusBarTexture(cfg.texture)
  bars.pow:SetMinMaxValues(0, 1); bars.pow:SetValue(0)
  bars.pow:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y - (h/2)-2)
  local bg2 = bars.pow:CreateTexture(nil, "BACKGROUND"); bg2:SetAllPoints(bars.pow); bg2:SetTexture(0,0,0,0.5)
  local fs2 = bars.pow:CreateFontString(nil, "OVERLAY"); fs2:SetFont(cfg.font, math.max(10, cfg.fontSize-2), "OUTLINE"); fs2:SetPoint("CENTER", bars.pow, "CENTER", 0, 0); fs2:SetText("ToT MP")
  bars.pow.text = fs2

  bars.hp:Hide(); bars.pow:Hide()
end

local function Update()
  Ensure()
  if not UnitExists("targettarget") then
    bars.hp:Hide(); bars.pow:Hide(); return
  end
  -- Health
  local cur = UnitHealth("targettarget") or 0
  local max = UnitHealthMax("targettarget") or 1
  if cur < 0 then cur = 0 elseif cur > max then cur = max end
  bars.hp:SetMinMaxValues(0, max); bars.hp:SetValue(cur)
  bars.hp:SetStatusBarColor(GnerdHUDDB.profile.colors.health.r, GnerdHUDDB.profile.colors.health.g, GnerdHUDDB.profile.colors.health.b)
  local nm = UnitName("targettarget") or "ToT"
  bars.hp.text:SetText(nm.." "..cur.."/"..max)
  GH.SetAlphaSmart(bars.hp)
  bars.hp:Show()

  -- Power
  local pcur = UnitMana("targettarget") or 0
  local pmax = UnitManaMax("targettarget") or 1
  if pcur < 0 then pcur = 0 elseif pcur > pmax then pcur = pmax end
  local r,g,b = GH.PowerColorFor("targettarget")
  bars.pow:SetMinMaxValues(0, pmax); bars.pow:SetValue(pcur); bars.pow:SetStatusBarColor(r,g,b)
  bars.pow.text:SetText(pcur.."/"..pmax)
  GH.SetAlphaSmart(bars.pow)
  bars.pow:Show()
end

local function CreateMover()
  if mover then return end
  Ensure()
  local key = "ToT"
  local a = GnerdHUDDB.profile.modules.ToT.anchor
  mover = CreateFrame("Button", "GnerdHUD_ToT_Mover", UIParent)
  mover:SetWidth(bars.hp:GetWidth()+8); mover:SetHeight((bars.hp:GetHeight()*2)+12)
  mover:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  mover:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={ left=3,right=3,top=3,bottom=3 } })
  mover:SetBackdropColor(0,0,0,0.4)
  mover:EnableMouse(true); mover:RegisterForDrag("LeftButton"); mover:SetFrameStrata("DIALOG")
  local fs = mover:CreateFontString(nil,"OVERLAY"); fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE"); fs:SetPoint("CENTER", mover, "CENTER", 0, 0); fs:SetText("ToT (drag)")
  mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
  mover:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx,cy = self:GetCenter(); local ux,uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    a.x = dx; a.y = dy
    bars.hp:ClearAllPoints(); bars.hp:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y + (bars.hp:GetHeight()/2)+2)
    bars.pow:ClearAllPoints(); bars.pow:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y - (bars.pow:GetHeight()/2)-2)
    mover:ClearAllPoints(); mover:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover:Hide()
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.OnEvent(self, event, unit)
  if event == "PLAYER_TARGET_CHANGED" or unit == "targettarget" then
    Update()
  elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_MANA" or event == "UNIT_MAXMANA" or event == "UNIT_DISPLAYPOWER" then
    if unit == "targettarget" then Update() end
  end
end

function M.Enable(self, cfg)
  Ensure()
  Update()
end

function M.Disable(self)
  if bars.hp then bars.hp:Hide() end
  if bars.pow then bars.pow:Hide() end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
