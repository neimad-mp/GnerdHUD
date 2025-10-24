-- Options_CastMirror.lua
-- UTF-8, UNIX newlines
-- Minimal options section for Cast/Mirror bars. Safe to coexist with an existing options panel.

local panel = CreateFrame("Frame", "GnerdHUD_CMOptions", UIParent)
panel:Hide()
panel:SetWidth(420); panel:SetHeight(260)
panel:SetFrameStrata("DIALOG")
panel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
panel:SetBackdropColor(0,0,0,0.8)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
panel.title:SetText("GnerdHUD • Cast & Mirror Options")

local function mkCheck(parent, label, y, onClick)
  local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
  b:SetScript("OnClick", onClick)
  getglobal(b:GetName().."Text"):SetText(label)
  return b
end

local function mkSlider(name, parent, label, y, minV, maxV, step, onChange)
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
  s:SetMinMaxValues(minV, maxV); s:SetValueStep(step or 0.05)
  s:SetObeyStepOnDrag(true)
  getglobal(s:GetName().."Text"):SetText(label)
  getglobal(s:GetName().."Low"):SetText(string.format("%.1f", minV))
  getglobal(s:GetName().."High"):SetText(string.format("%.1f", maxV))
  s:SetScript("OnValueChanged", onChange)
  return s
end

local y = -40
panel.castEnable = mkCheck(panel, "Enable Cast Bar", y, function()
  local p=GnerdHUDDB.profile; p.castBar.enabled = (this:GetChecked()==1)
  if GnerdHUD.Cast_SetEnabled then GnerdHUD.Cast_SetEnabled(p.castBar.enabled, p.mirrorBar.enabled) end
end)

y = y - 30
panel.castScale = mkSlider("GnerdHUD_CastScale", panel, "Cast Scale", y, 0.5, 1.5, 0.05, function()
  local p=GnerdHUDDB.profile; p.castBar.scale = tonumber(this:GetValue()) or 1.0
  if GnerdHUD.Cast_SetLocalScales then GnerdHUD.Cast_SetLocalScales(p.castBar.scale, p.mirrorBar.scale) end
end)

y = y - 40
panel.castAlpha = mkSlider("GnerdHUD_CastAlpha", panel, "Cast Alpha", y, 0.0, 1.0, 0.05, function()
  local p=GnerdHUDDB.profile; p.castBar.alpha = tonumber(this:GetValue()) or 1.0
  if GnerdHUD.Cast_SetLocalAlphas and GnerdHUD.LayoutUpdateAlpha then
    GnerdHUD.Cast_SetLocalAlphas(p.castBar.alpha, p.mirrorBar.alpha); GnerdHUD.LayoutUpdateAlpha()
  end
end)

y = y - 50
panel.mirrorEnable = mkCheck(panel, "Enable Mirror Bar", y, function()
  local p=GnerdHUDDB.profile; p.mirrorBar.enabled = (this:GetChecked()==1)
  if GnerdHUD.Cast_SetEnabled then GnerdHUD.Cast_SetEnabled(p.castBar.enabled, p.mirrorBar.enabled) end
end)

y = y - 30
panel.mirrorScale = mkSlider("GnerdHUD_MirrorScale", panel, "Mirror Scale", y, 0.5, 1.5, 0.05, function()
  local p=GnerdHUDDB.profile; p.mirrorBar.scale = tonumber(this:GetValue()) or 1.0
  if GnerdHUD.Cast_SetLocalScales then GnerdHUD.Cast_SetLocalScales(p.castBar.scale, p.mirrorBar.scale) end
end)

y = y - 40
panel.mirrorAlpha = mkSlider("GnerdHUD_MirrorAlpha", panel, "Mirror Alpha", y, 0.0, 1.0, 0.05, function()
  local p=GnerdHUDDB.profile; p.mirrorBar.alpha = tonumber(this:GetValue()) or 1.0
  if GnerdHUD.Cast_SetLocalAlphas and GnerdHUD.LayoutUpdateAlpha then
    GnerdHUD.Cast_SetLocalAlphas(p.castBar.alpha, p.mirrorBar.alpha); GnerdHUD.LayoutUpdateAlpha()
  end
end)

y = y - 50
panel.centerBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.centerBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
panel.centerBtn:SetWidth(160); panel.centerBtn:SetHeight(22)
panel.centerBtn:SetText("Center Cast/Mirror")
panel.centerBtn:SetScript("OnClick", function()
  local p=GnerdHUDDB.profile; p.center.x, p.center.y = 0, -32
  if GnerdHUD.Cast_SetPosition then GnerdHUD.Cast_SetPosition(0, -32) end
end)

panel.closeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.closeBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
panel.closeBtn:SetWidth(80); panel.closeBtn:SetHeight(22)
panel.closeBtn:SetText("Close")
panel.closeBtn:SetScript("OnClick", function() panel:Hide() end)

local function refreshUI()
  local p = GnerdHUDDB and GnerdHUDDB.profile
  if not p then return end
  panel.castEnable:SetChecked(p.castBar.enabled and 1 or 0)
  panel.castScale:SetValue(p.castBar.scale or 1.0)
  panel.castAlpha:SetValue(p.castBar.alpha or 1.0)
  panel.mirrorEnable:SetChecked(p.mirrorBar.enabled and 1 or 0)
  panel.mirrorScale:SetValue(p.mirrorBar.scale or 1.0)
  panel.mirrorAlpha:SetValue(p.mirrorBar.alpha or 1.0)
end

function GnerdHUD_ShowOptions()
  if not panel:IsShown() then refreshUI(); panel:Show() else panel:Hide() end
end
