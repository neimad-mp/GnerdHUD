-- Options.lua
-- UTF-8, UNIX newlines
-- Tabbed options panel (Vanilla 1.12-safe): Global | Center Bars
-- Draggable, each tab has its own scroll area with hover tooltips.
-- First /ghud options always opens; subsequent calls toggle.

local panel, tabs = nil, {}
local forceFirstShow = true

-- Utility: basic tooltip binder
local function addTip(widget, title, text)
  if not widget then return end
  widget:EnableMouse(true)
  widget:SetScript("OnEnter", function()
    GameTooltip:SetOwner(widget, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if title and title ~= "" then GameTooltip:AddLine(title, 1, 0.82, 0) end
    if text and text ~= "" then GameTooltip:AddLine(text, 0.9, 0.9, 0.9, 1) end
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Factories
local function mkCheck(parent, name, label, x, y, onClick)
  local b = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 12, y or 0)
  getglobal(name.."Text"):SetText(label or name)
  b:SetScript("OnClick", onClick)
  return b
end

local function mkSlider(parent, name, label, x, y, minV, maxV, step, onChange)
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 20, y or 0)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step or 0.05)
  getglobal(name.."Text"):SetText(label or name)
  getglobal(name.."Low"):SetText(string.format("%.1f", minV))
  getglobal(name.."High"):SetText(string.format("%.1f", maxV))
  s:SetScript("OnValueChanged", onChange)
  return s
end

local function mkSep(parent, y)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
  t:SetHeight(1); t:SetWidth(484); t:SetTexture(1,1,1,0.15)
  return t
end

-- Build contents for each tab
local function buildGlobalTab(body)
  local y = -8

  local locked = mkCheck(body, "GnerdHUD_OptLocked", "Locked", 12, y, function()
    local p=GnerdHUDDB.profile; p.locked = (this:GetChecked()==1)
    if GnerdHUD.LayoutSetLocked then GnerdHUD.LayoutSetLocked(p.locked) end
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)
  addTip(locked, "Lock/Unlock movers", "Unlock to drag the HUD arcs and center bars.")
  y = y - 28

  local right = mkCheck(body, "GnerdHUD_OptRight", "Show Target HUD", 12, y, function()
    local p=GnerdHUDDB.profile; p.rightEnabled = (this:GetChecked()==1)
    if GnerdHUD.LayoutSetRightEnabled then GnerdHUD.LayoutSetRightEnabled(p.rightEnabled) end
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end)
  addTip(right, "Toggle Right HUD", "Enables the target health/power arcs.")
  y = y - 40

  local scale = mkSlider(body, "GnerdHUD_OptScale", "Scale", 20, y, 0.5, 1.5, 0.05, function()
    local p=GnerdHUDDB.profile; p.scale = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.LayoutSetScale then GnerdHUD.LayoutSetScale(p.scale) end
  end)
  addTip(scale, "Global Scale", "Scales both left/right arc HUDs.")
  y = y - 50

  local a_full = mkSlider(body, "GnerdHUD_OptAFull", "Alpha: OOC • No Target (Full HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.ooc_full = tonumber(this:GetValue()) or 0.0
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end); y = y - 50

  local a_hurt = mkSlider(body, "GnerdHUD_OptAHurt", "Alpha: OOC • No Target (Missing HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.ooc_hurt = tonumber(this:GetValue()) or 0.25
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end); y = y - 50

  local a_tgt = mkSlider(body, "GnerdHUD_OptATarget", "Alpha: Has Target", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.target = tonumber(this:GetValue()) or 0.6
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end); y = y - 50

  local a_combat = mkSlider(body, "GnerdHUD_OptACombat", "Alpha: In Combat", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.alpha.combat = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.LayoutUpdateAlpha then GnerdHUD.LayoutUpdateAlpha() end
  end); y = y - 55

  local centerBoth = CreateFrame("Button", "GnerdHUD_OptCenterBoth", body, "UIPanelButtonTemplate")
  centerBoth:SetPoint("TOPLEFT", body, "TOPLEFT", 12, y)
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
  addTip(centerBoth, "Recenter HUD", "Recenter left/right arcs and center bars.")
  mkSep(body, y - 10)

  body._refresh = function()
    local p=GnerdHUDDB and GnerdHUDDB.profile
    if not p then return end
    locked:SetChecked(p.locked and 1 or 0)
    right:SetChecked(p.rightEnabled and 1 or 0)
    scale:SetValue(p.scale or 1.0)
    a_full:SetValue(p.alpha.ooc_full or 0.0)
    a_hurt:SetValue(p.alpha.ooc_hurt or 0.25)
    a_tgt:SetValue(p.alpha.target or 0.6)
    a_combat:SetValue(p.alpha.combat or 1.0)
    body:SetHeight(-y + 120)
  end
end

local function buildCenterTab(body)
  local y = -8

  local title = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", body, "TOPLEFT", 12, y)
  title:SetText("Cast & Mirror")
  y = y - 24

  local castEnable = mkCheck(body, "GnerdHUD_OptCastEnable", "Enable Cast Bar", 12, y, function()
    local p=GnerdHUDDB.profile; p.castBar.enabled = (this:GetChecked()==1)
    if GnerdHUD.Cast_SetEnabled then GnerdHUD.Cast_SetEnabled(p.castBar.enabled, p.mirrorBar.enabled) end
  end)
  addTip(castEnable, "Toggle Cast Bar", "Show or hide the center cast bar.")
  y = y - 30

  local castScale = mkSlider(body, "GnerdHUD_OptCastScale", "Cast Scale (width)", 20, y, 0.5, 1.5, 0.05, function()
    local p=GnerdHUDDB.profile; p.castBar.scale = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_SetLocalScales then GnerdHUD.Cast_SetLocalScales(p.castBar.scale, p.mirrorBar.scale) end
  end); y = y - 50

  local castHeight = mkSlider(body, "GnerdHUD_OptCastHeight", "Cast Height (px)", 20, y, 6, 24, 1, function()
    local p=GnerdHUDDB.profile; p.castBar.height = tonumber(this:GetValue()) or 12
    if GnerdHUD.Cast_SetLocalHeights then GnerdHUD.Cast_SetLocalHeights(p.castBar.height, p.mirrorBar.height) end
  end); y = y - 50

  local castAlphaMul = mkSlider(body, "GnerdHUD_OptCastAlphaMul", "Cast Alpha (multiplier)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castBar.alpha = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ca_full = mkSlider(body, "GnerdHUD_OptCastAFull", "Cast Alpha: OOC • No Target (Full HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.ooc_full = tonumber(this:GetValue()) or 0.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ca_hurt = mkSlider(body, "GnerdHUD_OptCastAHurt", "Cast Alpha: OOC • No Target (Missing HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.ooc_hurt = tonumber(this:GetValue()) or 0.25
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ca_tgt = mkSlider(body, "GnerdHUD_OptCastATarget", "Cast Alpha: Has Target", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.target = tonumber(this:GetValue()) or 0.6
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ca_combat = mkSlider(body, "GnerdHUD_OptCastACombat", "Cast Alpha: In Combat", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.castAlpha.combat = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 55

  local mirrorEnable = mkCheck(body, "GnerdHUD_OptMirrorEnable", "Enable Mirror Bar", 12, y, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.enabled = (this:GetChecked()==1)
    if GnerdHUD.Cast_SetEnabled then GnerdHUD.Cast_SetEnabled(p.castBar.enabled, p.mirrorBar.enabled) end
  end)
  addTip(mirrorEnable, "Toggle Mirror Bar", "Show or hide breath/fatigue/feign timer bar.")
  y = y - 30

  local mirrorScale = mkSlider(body, "GnerdHUD_OptMirrorScale", "Mirror Scale (width)", 20, y, 0.5, 1.5, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.scale = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_SetLocalScales then GnerdHUD.Cast_SetLocalScales(p.castBar.scale, p.mirrorBar.scale) end
  end); y = y - 50

  local mirrorHeight = mkSlider(body, "GnerdHUD_OptMirrorHeight", "Mirror Height (px)", 20, y, 6, 24, 1, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.height = tonumber(this:GetValue()) or 12
    if GnerdHUD.Cast_SetLocalHeights then GnerdHUD.Cast_SetLocalHeights(p.castBar.height, p.mirrorBar.height) end
  end); y = y - 50

  local mirrorAlphaMul = mkSlider(body, "GnerdHUD_OptMirrorAlphaMul", "Mirror Alpha (multiplier)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorBar.alpha = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ma_full = mkSlider(body, "GnerdHUD_OptMirrorAFull", "Mirror Alpha: OOC • No Target (Full HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.ooc_full = tonumber(this:GetValue()) or 0.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ma_hurt = mkSlider(body, "GnerdHUD_OptMirrorAHurt", "Mirror Alpha: OOC • No Target (Missing HP)", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.ooc_hurt = tonumber(this:GetValue()) or 0.25
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ma_tgt = mkSlider(body, "GnerdHUD_OptMirrorATarget", "Mirror Alpha: Has Target", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.target = tonumber(this:GetValue()) or 0.6
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end); y = y - 50

  local ma_combat = mkSlider(body, "GnerdHUD_OptMirrorACombat", "Mirror Alpha: In Combat", 20, y, 0.0, 1.0, 0.05, function()
    local p=GnerdHUDDB.profile; p.mirrorAlpha.combat = tonumber(this:GetValue()) or 1.0
    if GnerdHUD.Cast_UpdateAlpha then GnerdHUD.Cast_UpdateAlpha() end
  end)

  body._refresh = function()
    local p=GnerdHUDDB and GnerdHUDDB.profile
    if not p then return end
    -- Cast
    getglobal("GnerdHUD_OptCastEnable"):SetChecked(p.castBar.enabled and 1 or 0)
    getglobal("GnerdHUD_OptCastScale"):SetValue(p.castBar.scale or 1.0)
    getglobal("GnerdHUD_OptCastHeight"):SetValue(p.castBar.height or 12)
    getglobal("GnerdHUD_OptCastAlphaMul"):SetValue(p.castBar.alpha or 1.0)
    getglobal("GnerdHUD_OptCastAFull"):SetValue(p.castAlpha.ooc_full or 0.0)
    getglobal("GnerdHUD_OptCastAHurt"):SetValue(p.castAlpha.ooc_hurt or 0.25)
    getglobal("GnerdHUD_OptCastATarget"):SetValue(p.castAlpha.target or 0.6)
    getglobal("GnerdHUD_OptCastACombat"):SetValue(p.castAlpha.combat or 1.0)
    -- Mirror
    getglobal("GnerdHUD_OptMirrorEnable"):SetChecked(p.mirrorBar.enabled and 1 or 0)
    getglobal("GnerdHUD_OptMirrorScale"):SetValue(p.mirrorBar.scale or 1.0)
    getglobal("GnerdHUD_OptMirrorHeight"):SetValue(p.mirrorBar.height or 12)
    getglobal("GnerdHUD_OptMirrorAlphaMul"):SetValue(p.mirrorBar.alpha or 1.0)
    getglobal("GnerdHUD_OptMirrorAFull"):SetValue(p.mirrorAlpha.ooc_full or 0.0)
    getglobal("GnerdHUD_OptMirrorAHurt"):SetValue(p.mirrorAlpha.ooc_hurt or 0.25)
    getglobal("GnerdHUD_OptMirrorATarget"):SetValue(p.mirrorAlpha.target or 0.6)
    getglobal("GnerdHUD_OptMirrorACombat"):SetValue(p.mirrorAlpha.combat or 1.0)
    body:SetHeight(-y + 140)
  end
end

-- Simple tab widget (no reliance on Blizzard PanelTemplates textures)
local function selectTab(idx)
  for i, t in ipairs(tabs) do
    local sel = (i == idx)
    if t.btn and t.btn.LockHighlight and t.btn.UnlockHighlight then
      if sel then t.btn:LockHighlight() else t.btn:UnlockHighlight() end
    end
    if t.scroll then
      if sel then t.scroll:Show() else t.scroll:Hide() end
    end
  end
end

local function mkTab(parent, title, tabIndex, buildFn)
  local btn = CreateFrame("Button", "GnerdHUD_Tab"..tabIndex, parent, "CharacterFrameTabButtonTemplate")
  btn:SetID(tabIndex)
  btn:SetText(title)
  if tabIndex == 1 then
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -8)
  else
    btn:SetPoint("LEFT", tabs[tabIndex-1].btn, "RIGHT", -16, 0)
  end
  btn:SetScript("OnClick", function() selectTab(tabIndex) end)

  -- Create scroll area for this tab
  local scroll = CreateFrame("ScrollFrame", "GnerdHUD_Scroll"..tabIndex, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -36)
  scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 44)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function()
    local sb = getglobal(scroll:GetName().."ScrollBar"); if not sb then return end
    local cur = sb:GetValue() or 0
    local step = 20
    local delta = (arg1 and tonumber(arg1) or 0) * -step
    sb:SetValue(cur + delta)
  end)

  local body = CreateFrame("Frame", "GnerdHUD_Body"..tabIndex, scroll)
  body:SetWidth(500); body:SetHeight(1000)
  scroll:SetScrollChild(body)

  buildFn(body)

  scroll:Hide() -- hidden until selected

  table.insert(tabs, {
    btn = btn,
    scroll = scroll,
    body = body,
    refresh = function() if body._refresh then body._refresh() end end,
  })
end

-- Create main panel and tabs
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

  -- Build tabs
  tabs = {}
  mkTab(panel, "Global", 1, buildGlobalTab)
  mkTab(panel, "Center Bars", 2, buildCenterTab)

  -- Close button
  panel.closeBtn = CreateFrame("Button", "GnerdHUD_OptClose", panel, "UIPanelButtonTemplate")
  panel.closeBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
  panel.closeBtn:SetWidth(80); panel.closeBtn:SetHeight(22)
  panel.closeBtn:SetText("Close")
  panel.closeBtn:SetScript("OnClick", function() panel:Hide() end)

  -- Refresh tabs on show and select first tab
  panel:SetScript("OnShow", function()
    for _,t in ipairs(tabs) do t.refresh() end
    selectTab(1)
  end)

  panel:Hide()
  return panel
end

-- Public entry
function GnerdHUD_ShowOptions()
  local p = mkPanel()
  if forceFirstShow then
    forceFirstShow = false
    p:Show()
    return
  end
  if not p:IsShown() then p:Show() else p:Hide() end
end
