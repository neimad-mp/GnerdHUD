-- Options.lua
-- UTF-8, UNIX newlines
-- Guard against SetValue calling OnValueChanged while initializing; persist all alphas.

local function Lf(key, default)
  local t = _G.GnerdHUD_L
  local v = t and t[key]
  if v == nil then return default end
  return v
end

local panel = CreateFrame("Frame", "GnerdHUD_Options", UIParent)
panel.name = Lf("OPTS_TITLE", "GnerdHUD Options")
panel:SetWidth(500); panel:SetHeight(360)
panel:ClearAllPoints(); panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG"); panel:SetToplevel(true); panel:EnableMouse(true)
panel:SetMovable(true); panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function() panel:StartMoving() end)
panel:SetScript("OnDragStop",  function() panel:StopMovingOrSizing() end)
panel:Hide(); tinsert(UISpecialFrames, panel:GetName())

panel.bg = panel:CreateTexture(nil, "BACKGROUND"); panel.bg:SetAllPoints(panel); panel.bg:SetTexture(0, 0, 0, 0.80)

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16); title:SetText(Lf("OPTS_TITLE", "GnerdHUD Options"))

local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)

local lockCB = CreateFrame("CheckButton", "GnerdHUD_OptLocked", panel, "OptionsCheckButtonTemplate")
lockCB:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
_G[lockCB:GetName().."Text"]:SetText(Lf("OPTS_LOCK","Locked"))

local rightEnableCB = CreateFrame("CheckButton", "GnerdHUD_OptRightEnable", panel, "OptionsCheckButtonTemplate")
rightEnableCB:SetPoint("TOPLEFT", lockCB, "BOTTOMLEFT", 0, -10)
_G[rightEnableCB:GetName().."Text"]:SetText("Show Target HUD")

local scaleS = CreateFrame("Slider", "GnerdHUD_OptScale", panel, "OptionsSliderTemplate")
scaleS:SetPoint("TOPLEFT", rightEnableCB, "BOTTOMLEFT", 0, -20)
scaleS:SetMinMaxValues(0.5, 1.5); scaleS:SetValueStep(0.05)
_G[scaleS:GetName().."Text"]:SetText(Lf("OPTS_SCALE","Scale"))
_G[scaleS:GetName().."Low"]:SetText("0.5")
_G[scaleS:GetName().."High"]:SetText("1.5")

local function makeAlphaSlider(name, label, anchor, yOfs)
  local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOfs or -24)
  s:SetMinMaxValues(0, 1); s:SetValueStep(0.05)
  _G[s:GetName().."Text"]:SetText(label); _G[s:GetName().."Low"]:SetText("0"); _G[s:GetName().."High"]:SetText("1")
  return s
end

local oocFullS = makeAlphaSlider("GnerdHUD_AlphaOOCFull",  "Alpha: OOC • No Target (Full HP)",    scaleS)
local oocHurtS = makeAlphaSlider("GnerdHUD_AlphaOOCHurt",  "Alpha: OOC • No Target (Missing HP)",  oocFullS)
local targetS  = makeAlphaSlider("GnerdHUD_AlphaTarget",   "Alpha: Has Target",                     oocHurtS)
local combatS  = makeAlphaSlider("GnerdHUD_AlphaCombat",   "Alpha: In Combat",                      targetS)

local centerB = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
centerB:SetWidth(130); centerB:SetHeight(22)
centerB:SetPoint("TOPLEFT", combatS, "BOTTOMLEFT", 0, -18)
centerB:SetText("Center Both")
centerB:SetScript("OnClick", function()
  if not GnerdHUDDB or not GnerdHUDDB.profile then return end
  GnerdHUDDB.profile.left.x,  GnerdHUDDB.profile.left.y  = 0, 0
  GnerdHUDDB.profile.right.x, GnerdHUDDB.profile.right.y = 0, 0
  if GnerdHUD.LayoutSetPositions then GnerdHUD.LayoutSetPositions(GnerdHUDDB.profile.left, GnerdHUDDB.profile.right) end
end)

lockCB:SetScript("OnClick", function()
  if not GnerdHUDDB or not GnerdHUDDB.profile then return end
  local checked = (this:GetChecked() == 1) or (this:GetChecked() == true)
  GnerdHUDDB.profile.locked = checked and true or false
  GnerdHUD.LayoutSetLocked(GnerdHUDDB.profile.locked)
  GnerdHUD.LayoutUpdateAlpha()
end)

rightEnableCB:SetScript("OnClick", function()
  if not GnerdHUDDB or not GnerdHUDDB.profile then return end
  local checked = (this:GetChecked() == 1) or (this:GetChecked() == true)
  GnerdHUDDB.profile.rightEnabled = checked and true or false
  GnerdHUD.LayoutSetRightEnabled(GnerdHUDDB.profile.rightEnabled)
  if GnerdHUD.LayoutUpdateTargetColors then GnerdHUD.LayoutUpdateTargetColors() end
  if GnerdHUD.LayoutUpdateTarget then GnerdHUD.LayoutUpdateTarget() end
  GnerdHUD.LayoutUpdateAlpha()
end)

scaleS:SetScript("OnValueChanged", function()
  if not GnerdHUDDB or not GnerdHUDDB.profile then return end
  local v = tonumber(this:GetValue() or 1) or 1
  GnerdHUDDB.profile.scale = v
  GnerdHUD.LayoutSetScale(v)
end)

local function alphaChanged()
  if panel._setting then return end
  if not GnerdHUDDB or not GnerdHUDDB.profile then return end
  local a = GnerdHUDDB.profile.alpha
  a.ooc_full = tonumber(oocFullS:GetValue() or a.ooc_full) or a.ooc_full
  a.ooc_hurt = tonumber(oocHurtS:GetValue() or a.ooc_hurt) or a.ooc_hurt
  a.target   = tonumber(targetS:GetValue()  or a.target)   or a.target
  a.combat   = tonumber(combatS:GetValue()  or a.combat)   or a.combat
  GnerdHUD.LayoutUpdateAlpha()
end
oocFullS:SetScript("OnValueChanged", alphaChanged)
oocHurtS:SetScript("OnValueChanged", alphaChanged)
targetS:SetScript("OnValueChanged",  alphaChanged)
combatS:SetScript("OnValueChanged",  alphaChanged)

panel:SetScript("OnShow", function()
  local p = (GnerdHUDDB and GnerdHUDDB.profile)
            or { locked=true, scale=1, rightEnabled=true, alpha={ooc_full=0, ooc_hurt=0.25, target=0.6, combat=1} }
  panel._setting = true
  lockCB:SetChecked(p.locked and 1 or 0)
  rightEnableCB:SetChecked(p.rightEnabled and 1 or 0)
  scaleS:SetValue(p.scale or 1)
  oocFullS:SetValue(p.alpha.ooc_full or 0.0)
  oocHurtS:SetValue(p.alpha.ooc_hurt or 0.25)
  targetS:SetValue(p.alpha.target or 0.6)
  combatS:SetValue(p.alpha.combat or 1.0)
  panel._setting = false
  if GnerdHUD and GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
end)

function GnerdHUD_ShowOptions()
  if not _G.GnerdHUD_Options then return end
  if GnerdHUD_Options:IsShown() then
    GnerdHUD_Options:Hide()
  else
    GnerdHUD_Options:Show()
    if GnerdHUD_Options.Raise then GnerdHUD_Options:Raise() end
  end
end

SLASH_GNERDHUDOPTS1 = "/ghudopts"
SlashCmdList["GNERDHUDOPTS"] = function() GnerdHUD_ShowOptions() end
