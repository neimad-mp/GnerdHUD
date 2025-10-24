-- Options.lua
-- UTF-8, UNIX newlines
-- Unified options panel (Vanilla 1.12-safe), draggable with a scrollable content area.
-- First /ghud options always opens; subsequent calls toggle.

local panel, content, forceFirstShow = nil, nil, true

local function mkPanel()
  if panel then return panel end

  panel = CreateFrame("Frame", "GnerdHUD_Options", UIParent)
  panel:SetWidth(560); panel:SetHeight(520)
  panel:SetFrameStrata("DIALOG")
  if panel.SetBackdrop then
    panel:SetBackdrop({
      bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
      tile=true, tileSize=16, edgeSize=16,
      insets={left=4,right=4,top=4,bottom=4}
    })
    panel:SetBackdropColor(0,0,0,0.85)
  end
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function() panel:StartMoving() end)
  panel:SetScript("OnDragStop",  function() panel:StopMovingOrSizing() end)

  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
  panel.title:SetText("GnerdHUD Options")

  local scroll = CreateFrame("ScrollFrame", "GnerdHUD_OptScroll", panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -36)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 44)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function()
    local sb = getglobal(scroll:GetName().."ScrollBar"); if not sb then return end
    local cur = sb:GetValue() or 0
    local step = 20
    local delta = (arg1 and tonumber(arg1) or 0) * -step
    sb:SetValue(cur + delta)
  end)

  content = CreateFrame("Frame", "GnerdHUD_OptContent", scroll)
  content:SetWidth(500); content:SetHeight(1000)
  scroll:SetScrollChild(content)

  local y = -8

  local function mkCheck(name, label, x, y, onClick)
    local b = CreateFrame("CheckButton", name, content, "UICheckButtonTemplate")
    b:SetPoint("TOPLEFT", content, "TOPLEFT", x or 12, y or 0)
    getglobal(name.."Text"):SetText(label)
    b:SetScript("OnClick", onClick)
    return b
  end

  local function mkSlider(name, label, x, y, minV, maxV, step, onChange)
    local s = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", content, "TOPLEFT", x or 20, y or 0)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step or 0.05)
    getglobal(name.."Text"):SetText(label)
    getglobal(name.."Low"):SetText(string.format("%.1f", minV))
    getglobal(name.."High"):SetText(string.format("%.1f", maxV))
    s:SetScript("OnValueChanged", onChange)
    return s
  end

  local function sepLine(ypos)
    local sep = content:CreateTexture(nil, "ARTWORK"); sep:SetPoint("TOPLEFT", content, "TOPLEFT", 8, ypos); sep:SetHeight(1); sep:SetWidth(484); sep:SetTexture(1,1,1,0.15)
  end

  local locked = mkCheck("GnerdHUD_OptLocked", "Locked", 12, y, function()
    local p=GnerdHUDDB.profile; p.locked = (this:GetChecked()==1)
    if GnerdHUD.LayoutSetLocked then GnerdHUD.LayoutSetLocked(p.locked) end
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)
  y = y - 28
  local right = mkCheck("GnerdHUD_OptRight", "Show Target HUD", 12, y, function()
    local p=GnerdHUDDB.profile; p.rightEnabled = (this:GetChecked()==1)
    if GnerdHUD.LayoutSetRightEnabled then GnerdHUD.LayoutSetRightEnabled(p.rightEnabled) end
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)

  y = y - 40
  local scale = mkSlider("GnerdHUD_OptScale", "Scale", 20, y, 0.5, 1.5, 0.05, function()
    local p=GnerdHUDDB.profile; p.scale = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.LayoutSetScale then GnerdHUD.LayoutSetScale(p.scale) end
  end)

  y = y - 50
  local a_full = mkSlider("GnerdHUD_OptAFull", "Alpha: OOC • No Target (Full HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.ooc_full = tonumber(this:GetValue()) or 0.0
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)
  y = y - 50
  local a_hurt = mkSlider("GnerdHUD_OptAHurt", "Alpha: OOC • No Target (Missing HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.ooc_hurt = tonumber(this:GetValue()) or 0.25
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)
  y = y - 50
  local a_tgt = mkSlider("GnerdHUD_OptATarget", "Alpha: Has Target", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.target = tonumber(this:GetValue()) or 0.6
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)
  y = y - 50
  local a_combat = mkSlider("GnerdHUD_OptACombat", "Alpha: In Combat", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.combat = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)

  y = y - 55
  local centerBoth = CreateFrame("Button", "GnerdHUD_OptCenterBoth", content, "UIPanelButtonTemplate")
  centerBoth:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
  centerBoth:SetWidth(160); centerBoth:SetHeight(22)
  centerBoth:SetText("Center Both")
  centerBoth:SetScript("OnClick", function()
    local p=GnerdHUDDB.profile
    p.left.x, p.left.y = 0, 0
    p.right.x, p.right.y = 0, 0
    p.center.x, p.center.y = 0, -32
    if GnerdHUD.LayoutSetPositions then GnerdHUD.LayoutSetPositions(p.left, p.right) end
    if GnerdHUD.Cast_SetPosition then GnerdHUD.Cast_SetPosition(0, -32) end
  end)

  sepLine(y - 10)

  y = y - 40
  local cmTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  cmTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 12, y)
  cmTitle:SetText("Cast & Mirror")

  y = y - 24
  local castEnable = mkCheck("GnerdHUD_OptCastEnable", "Enable Cast Bar", 12, y, function()
    local p=GnerdHUDDB.profile; p.castBar.enabled = (this:GetChecked()==1)
    if GnerdHUD.Cast_SetEnabled then GnerdHUD.Cast_SetEnabled(p.castBar.enabled, p.mirrorBar.enabled) end
  end)

  y = y - 30
  local castScale = mkSlider("GnerdHUD_OptCastScale", "Cast Scale (width)", 20, y, 0.5, 1.5, 0.05, function()
    local p=GnerdHUDDB.profile; p.castBar.scale = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_SetLocalScales then GnerdHUD.Cast_SetLocalScales(p.castBar.scale, p.mirrorBar.scale) end
  end)

  y = y - 50
  local castAlphaMul = mkSlider("GnerdHUD_OptCastAlphaMul", "Cast Alpha (multiplier)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castBar.alpha = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)

  y = y - 50
  local ca_full = mkSlider("GnerdHUD_OptCastAFull", "Cast Alpha: OOC • No Target (Full HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.ooc_full = tonumber(this:GetValue()) or 0.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)
  y = y - 50
  local ca_hurt = mkSlider("GnerdHUD_OptCastAHurt", "Cast Alpha: OOC • No Target (Missing HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.ooc_hurt = tonumber(this:GetValue()) or 0.25
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)
  y = y - 50
  local ca_tgt = mkSlider("GnerdHUD_OptCastATarget", "Cast Alpha: Has Target", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.target = tonumber(this:GetValue()) or 0.6
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)
  y = y - 50
  local ca_combat = mkSlider("GnerdHUD_OptCastACombat", "Cast Alpha: In Combat", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.combat = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)

  y = y - 55
  local mirrorEnable = mkCheck("GnerdHUD_OptMirrorEnable", "Enable Mirror Bar", 12, y, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.enabled = (this:GetChecked()==1)
    if GnerdHUD.Cast_SetEnabled then GnerdHUD.Cast_SetEnabled(p.castBar.enabled, p.mirrorBar.enabled) end
  end)

  y = y - 30
  local mirrorScale = mkSlider("GnerdHUD_OptMirrorScale", "Mirror Scale (width)", 20, y, 0.5, 1.5, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.scale = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_SetLocalScales then GnerdHUD.Cast_SetLocalScales(p.castBar.scale, p.mirrorBar.scale) end
  end)

  y = y - 50
  local mirrorAlphaMul = mkSlider("GnerdHUD_OptMirrorAlphaMul", "Mirror Alpha (multiplier)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.alpha = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)

  y = y - 50
  local ma_full = mkSlider("GnerdHUD_OptMirrorAFull", "Mirror Alpha: OOC • No Target (Full HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.ooc_full = tonumber(this:GetValue()) or 0.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)
  y = y - 50
  local ma_hurt = mkSlider("GnerdHUD_OptMirrorAHurt", "Mirror Alpha: OOC • No Target (Missing HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.ooc_hurt = tonumber(this:GetValue()) or 0.25
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)
  y = y - 50
  local ma_tgt = mkSlider("GnerdHUD_OptMirrorATarget", "Mirror Alpha: Has Target", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.target = tonumber(this:GetValue()) or 0.6
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)
  y = y - 50
  local ma_combat = mkSlider("GnerdHUD_OptMirrorACombat", "Mirror Alpha: In Combat", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.combat = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)

  content:SetHeight(-y + 80)

  panel.closeBtn = CreateFrame("Button", "GnerdHUD_OptClose", panel, "UIPanelButtonTemplate")
  panel.closeBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
  panel.closeBtn:SetWidth(80); panel.closeBtn:SetHeight(22)
  panel.closeBtn:SetText("Close")
  panel.closeBtn:SetScript("OnClick", function() panel:Hide() end)

  function panel:Refresh()
    local p=GnerdHUDDB and GnerdHUDDB.profile
    if not p then return end
    locked:SetChecked(p.locked and 1 or 0)
    right:SetChecked(p.rightEnabled and 1 or 0)
    scale:SetValue(p.scale or 1.0)
    a_full:SetValue(p.alpha.ooc_full or 0.0)
    a_hurt:SetValue(p.alpha.ooc_hurt or 0.25)
    a_tgt:SetValue(p.alpha.target or 0.6)
    a_combat:SetValue(p.alpha.combat or 1.0)

    castEnable:SetChecked(p.castBar.enabled and 1 or 0)
    castScale:SetValue(p.castBar.scale or 1.0)
    castAlphaMul:SetValue(p.castBar.alpha or 1.0)
    getglobal("GnerdHUD_OptCastAFull"):SetValue(p.castAlpha.ooc_full or 0.0)
    getglobal("GnerdHUD_OptCastAHurt"):SetValue(p.castAlpha.ooc_hurt or 0.25)
    getglobal("GnerdHUD_OptCastATarget"):SetValue(p.castAlpha.target or 0.6)
    getglobal("GnerdHUD_OptCastACombat"):SetValue(p.castAlpha.combat or 1.0)

    mirrorEnable:SetChecked(p.mirrorBar.enabled and 1 or 0)
    mirrorScale:SetValue(p.mirrorBar.scale or 1.0)
    mirrorAlphaMul:SetValue(p.mirrorBar.alpha or 1.0)
    getglobal("GnerdHUD_OptMirrorAFull"):SetValue(p.mirrorAlpha.ooc_full or 0.0)
    getglobal("GnerdHUD_OptMirrorAHurt"):SetValue(p.mirrorAlpha.ooc_hurt or 0.25)
    getglobal("GnerdHUD_OptMirrorATarget"):SetValue(p.mirrorAlpha.target or 0.6)
    getglobal("GnerdHUD_OptMirrorACombat"):SetValue(p.mirrorAlpha.combat or 1.0)
  end

  panel:SetScript("OnShow", function() panel:Refresh() end)
  panel:Hide()
  return panel
end

function GnerdHUD_ShowOptions()
  local p = mkPanel()
  if forceFirstShow then
    forceFirstShow = false
    p:Refresh(); p:Show()
    return
  end
  if not p:IsShown() then p:Refresh(); p:Show() else p:Hide() end
end
