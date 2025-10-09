-- GnerdHUD/modules/DruidMana.lua
-- UTF-8, UNIX LF
-- Druid mana overlay: shows mana pool while in non-mana forms (bear/cat).

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "DruidMana" }

local bar, mover
local mem = { lastMana = 0, lastMax = 0 }

local function Ensure()
  if bar then return end
  local a = GnerdHUDDB.profile.modules.DruidMana.anchor
  local cfg = GnerdHUDDB.profile.bars
  bar = CreateFrame("StatusBar", "GnerdHUD_DruidMana", UIParent)
  bar:SetWidth(cfg.width); bar:SetHeight(math.max(10, cfg.height-6))
  bar:SetStatusBarTexture(cfg.texture)
  bar:SetMinMaxValues(0,1); bar:SetValue(0)
  bar:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local bg = bar:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(bar); bg:SetTexture(0,0,0,0.5)
  local fs = bar:CreateFontString(nil, "OVERLAY"); fs:SetFont(cfg.font, math.max(10, cfg.fontSize-2), "OUTLINE"); fs:SetPoint("CENTER", bar, "CENTER", 0, 0); fs:SetText(L["Druid Mana"])
  bar.text = fs
  bar:SetStatusBarColor(GnerdHUDDB.profile.colors.power[0].r, GnerdHUDDB.profile.colors.power[0].g, GnerdHUDDB.profile.colors.power[0].b)
  bar:Hide()
end

local function IsDruid()
  local _, cls = UnitClass("player")
  return cls == "DRUID"
end

local function IsManaUser()
  local pt = UnitPowerType("player") or 0
  return pt == 0
end

local function UpdateStored()
  mem.lastMana = UnitMana("player") or mem.lastMana or 0
  mem.lastMax = UnitManaMax("player") or mem.lastMax or 1
end

local function Update()
  Ensure()
  if not IsDruid() then bar:Hide(); return end
  if IsManaUser() then
    UpdateStored()
    bar:Hide()
    return
  end
  if mem.lastMax <= 0 then mem.lastMax = 1 end
  bar:SetMinMaxValues(0, mem.lastMax)
  bar:SetValue(mem.lastMana)
  bar.text:SetText(mem.lastMana.."/"..mem.lastMax)
  GH.SetAlphaSmart(bar)
  bar:Show()
end

local function CreateMover()
  if mover then return end
  Ensure()
  local a = GnerdHUDDB.profile.modules.DruidMana.anchor
  mover = CreateFrame("Button", "GnerdHUD_DruidMana_Mover", UIParent)
  mover:SetWidth(bar:GetWidth()+8); mover:SetHeight(bar:GetHeight()+8)
  mover:SetPoint("CENTER", bar, "CENTER", 0, 0)
  mover:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={ left=3,right=3,top=3,bottom=3 } })
  mover:SetBackdropColor(0,0,0,0.5)
  mover:EnableMouse(true); mover:RegisterForDrag("LeftButton"); mover:SetFrameStrata("DIALOG")
  local fs = mover:CreateFontString(nil,"OVERLAY"); fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE"); fs:SetPoint("CENTER", mover, "CENTER", 0, 0); fs:SetText("Druid Mana (drag)")
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

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.OnEvent(self, event, unit)
  if unit == "player" then
    if event == "UNIT_MANA" or event == "UNIT_MAXMANA" then
      UpdateStored()
      Update()
    elseif event == "UNIT_DISPLAYPOWER" then
      Update()
    end
  end
end

function M.Enable(self, cfg)
  Ensure()
  UpdateStored()
  Update()
end

function M.Disable(self)
  if bar then bar:Hide() end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
