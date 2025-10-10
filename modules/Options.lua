local GH = GnerdHUD
local L = GnerdHUD_L

local panel, shown
local seq = 0
local function uid(prefix) seq = seq + 1; return (prefix or "GnerdHUD_")..seq end

local function fontPath()
  local p = GnerdHUDDB and GnerdHUDDB.profile
  if p and p.bars and p.bars.font then return p.bars.font end
  return "Fonts\\FRIZQT__.TTF"
end

local textures = {
  "Interface\\TargetingFrame\\UI-StatusBar",
  "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
  "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
}

local function MakeHeader(parent, text, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(fontPath(), 14, "OUTLINE")
  fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  fs:SetText(text)
  return fs
end

local function MakeCheck(parent, label, x, y, initial, onToggle)
  local name = uid("GnerdHUD_CB")
  local b = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  local t = getglobal(name.."Text"); if t then t:SetText(label) end
  if initial then b:SetChecked(1) else b:SetChecked(nil) end
  b:SetScript("OnClick", function()
    local state = this:GetChecked() and true or false
    if onToggle then onToggle(state) end
  end)
  return b
end

local function MakeSlider(parent, label, x, y, minv, maxv, step, initial, onChange)
  local name = uid("GnerdHUD_SL")
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  s:SetMinMaxValues(minv, maxv)
  s:SetValueStep(step)
  s:SetValue(initial or minv)
  local t = getglobal(name.."Text"); if t then t:SetText(label) end
  local lo = getglobal(name.."Low");  if lo then lo:SetText(tostring(minv)) end
  local hi = getglobal(name.."High"); if hi then hi:SetText(tostring(maxv)) end
  s:SetScript("OnValueChanged", function()
    if onChange then onChange(this:GetValue()) end
  end)
  return s
end

local function ReapplyTexture()
  local tex = (GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.bars and GnerdHUDDB.profile.bars.texture) or textures[1]
  if GH and GH.bars then
    if GH.bars.playerHealth then GH.bars.playerHealth:SetStatusBarTexture(tex) end
    if GH.bars.playerPower  then GH.bars.playerPower:SetStatusBarTexture(tex)  end
    if GH.bars.targetHealth then GH.bars.targetHealth:SetStatusBarTexture(tex) end
    if GH.bars.targetPower  then GH.bars.targetPower:SetStatusBarTexture(tex)  end
  end
end

local function CycleTexture()
  local cur = (GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.bars and GnerdHUDDB.profile.bars.texture) or textures[1]
  local i, idx = 1, 1
  while textures[i] do
    if textures[i] == cur then idx = i + 1; break end
    i = i + 1
  end
  if not textures[idx] then idx = 1 end
  GnerdHUDDB.profile.bars.texture = textures[idx]
  ReapplyTexture()
end

local function BuildPanel()
  if panel then return end

  panel = CreateFrame("Frame", "GnerdHUD_Options", UIParent)
  panel:SetWidth(360); panel:SetHeight(360)
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                      tile = true, tileSize = 32, edgeSize = 32,
                      insets = { left=11, right=12, top=12, bottom=11 } })
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function() this:StartMoving() end)
  panel:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  local title = panel:CreateFontString(nil, "OVERLAY")
  title:SetFont(fontPath(), 14, "OUTLINE")
  title:SetPoint("TOP", panel, "TOP", 0, -6)
  title:SetText("GnerdHUD Options")

  local close = CreateFrame("Button", uid("GnerdHUD_OptClose"), panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
  close:SetScript("OnClick", function() panel:Hide(); shown=false end)

  MakeHeader(panel, "General", 16, -32)

  local locked = GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.locked
  MakeCheck(panel, "Locked (/ghud lock|unlock)", 16, -56, locked, function(state)
    if GnerdHUDDB and GnerdHUDDB.profile then GnerdHUDDB.profile.locked = state and true or false end
    if state then if GH and GH.Lock then GH.Lock() end else if GH and GH.Unlock then GH.Unlock() end end
  end)

  local forceVis = (GH and GH._forceVisible) and true or false
  MakeCheck(panel, "Force visible (/ghud vis on|off)", 16, -84, forceVis, function(state)
    if GH and GH.ForceVisible then GH.ForceVisible(state) end
  end)

  local alpha = (GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.alpha) or {}
  MakeSlider(panel, "Idle alpha", 16, -128, 0.0, 1.0, 0.05, alpha.idle or 0.25,
    function(v)
      if not (GnerdHUDDB and GnerdHUDDB.profile) then return end
      GnerdHUDDB.profile.alpha = GnerdHUDDB.profile.alpha or {}
      GnerdHUDDB.profile.alpha.idle = v
      if GH and GH.UpdateAllBars then GH.UpdateAllBars() end
    end)

  MakeSlider(panel, "Combat alpha", 16, -168, 0.0, 1.0, 0.05, alpha.combat or 1.0,
    function(v)
      if not (GnerdHUDDB and GnerdHUDDB.profile) then return end
      GnerdHUDDB.profile.alpha = GnerdHUDDB.profile.alpha or {}
      GnerdHUDDB.profile.alpha.combat = v
      if GH and GH.UpdateAllBars then GH.UpdateAllBars() end
    end)

  MakeSlider(panel, "Has target alpha", 16, -208, 0.0, 1.0, 0.05, alpha.hasTarget or 0.9,
    function(v)
      if not (GnerdHUDDB and GnerdHUDDB.profile) then return end
      GnerdHUDDB.profile.alpha = GnerdHUDDB.profile.alpha or {}
      GnerdHUDDB.profile.alpha.hasTarget = v
      if GH and GH.UpdateAllBars then GH.UpdateAllBars() end
    end)

  MakeHeader(panel, "Bars", 16, -248)
  local texBtn = CreateFrame("Button", uid("GnerdHUD_Tex"), panel, "UIPanelButtonTemplate")
  texBtn:SetWidth(160); texBtn:SetHeight(22)
  texBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -272)
  texBtn:SetText("Cycle texture")
  texBtn:SetScript("OnClick", function() CycleTexture() end)

  MakeHeader(panel, "Modules", 200, -32)
  local y = -56
  local k, mod = next(GH and GH.modules or {}, nil)
  while k do
    if k ~= "Options" then
      local enabled = (mod and mod.enabled ~= false) and true or false
      MakeCheck(panel, tostring(k), 200, y, enabled, function(state)
        if GH and GH.ToggleModule then GH.ToggleModule(k, state) end
      end)
      y = y - 24
    end
    k, mod = next(GH.modules, k)
  end

  panel:Hide()
end

local M = { name = "Options", enabled = true }

function M:Enable(cfg) BuildPanel() end
function M:Disable() if panel then panel:Hide() end end
function M:Slash(msg)
  local s = msg or ""
  s = string.gsub(s, "^%s+", ""); s = string.gsub(s, "%s+$", "")
  s = string.lower(s)
  if s == "" or s == "toggle" or s == "options" or s == "opt" or s == "o" then
    BuildPanel()
    if shown then panel:Hide(); shown=false else panel:Show(); shown=true end
    return true
  end
end

if GH then
  GH.modules = GH.modules or {}
  GH.modules[M.name] = M
end

GnerdHUD_OpenOptions = function()
  BuildPanel()
  if shown then panel:Hide(); shown=false else panel:Show(); shown=true end
end
