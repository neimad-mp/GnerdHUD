-- GnerdHUD/modules/Options.lua
-- UTF-8, UNIX LF
-- Minimal in-game options panel (toggle modules, tweak alphas, pick texture string)

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "Options" }

local panel, shown

local textures = {
  "Interface\\TargetingFrame\\UI-StatusBar",
  "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
  "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
}

local function MakeCheckbox(parent, label, x, y, initial, onToggle)
  local b = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetChecked(initial and true or false)
  getglobal(b:GetName().."Text"):SetText(label)
  b:SetScript("OnClick", function(self)
    local state = self:GetChecked() and true or false
    onToggle(state)
  end)
  return b
end

local function MakeSlider(parent, label, x, y, minv, maxv, step, initial, onChange)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  s:SetMinMaxValues(minv, maxv)
  s:SetValueStep(step)
  s:SetValue(initial)
  getglobal(s:GetName().."Text"):SetText(label)
  getglobal(s:GetName().."Low"):SetText(tostring(minv))
  getglobal(s:GetName().."High"):SetText(tostring(maxv))
  s:SetScript("OnValueChanged", function(self)
    onChange(self:GetValue())
  end)
  return s
end

local function ReapplyTexture()
  local tex = GnerdHUDDB.profile.bars.texture
  if GH.bars.playerHealth then GH.bars.playerHealth:SetStatusBarTexture(tex) end
  if GH.bars.playerPower then GH.bars.playerPower:SetStatusBarTexture(tex) end
  if GH.bars.targetHealth then GH.bars.targetHealth:SetStatusBarTexture(tex) end
  if GH.bars.targetPower then GH.bars.targetPower:SetStatusBarTexture(tex) end
end

local function BuildPanel()
  if panel then return end
  panel = CreateFrame("Frame", "GnerdHUD_Options", UIParent)
  panel:SetWidth(360); panel:SetHeight(360)
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left=11,right=12,top=12,bottom=11 } })
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
  panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  local title = panel:CreateFontString(nil, "OVERLAY")
  title:SetFont(GnerdHUDDB.profile.bars.font, 14, "OUTLINE")
  title:SetPoint("TOP", panel, "TOP", 0, -16)
  title:SetText("GnerdHUD "..(GetAddOnMetadata and GetAddOnMetadata("GnerdHUD","Version") or "").." - "..L["Options"])

  local y = -44
  MakeCheckbox(panel, L["Lock/Unlock"], 16, y, GnerdHUDDB.profile.locked, function(state)
    if SlashCmdList and SlashCmdList["GNERDHUD"] then
      if state then SlashCmdList["GNERDHUD"]("lock") else SlashCmdList["GNERDHUD"]("unlock") end
    end
  end)

  y = y - 36
  MakeSlider(panel, L["Alpha (Idle)"], 16, y, 0, 1, 0.05, GnerdHUDDB.profile.alpha.idle, function(v)
    GnerdHUDDB.profile.alpha.idle = v; GH.UpdateAllBars()
  end)
  y = y - 48
  MakeSlider(panel, L["Alpha (Combat)"], 16, y, 0, 1, 0.05, GnerdHUDDB.profile.alpha.combat, function(v)
    GnerdHUDDB.profile.alpha.combat = v; GH.UpdateAllBars()
  end)
  y = y - 48
  MakeSlider(panel, L["Alpha (Target)"], 16, y, 0, 1, 0.05, GnerdHUDDB.profile.alpha.hasTarget, function(v)
    GnerdHUDDB.profile.alpha.hasTarget = v; GH.UpdateAllBars()
  end)

  y = y - 52
  local texIdx = 1
  local cur = GnerdHUDDB.profile.bars.texture
  local i
  for i=1, table.getn(textures) do if textures[i]==cur then texIdx=i break end end
  local btnTex = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  btnTex:SetWidth(120); btnTex:SetHeight(24)
  btnTex:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
  btnTex:SetText(L["Texture"])
  btnTex:SetScript("OnClick", function()
    texIdx = texIdx + 1
    if texIdx > table.getn(textures) then texIdx = 1 end
    GnerdHUDDB.profile.bars.texture = textures[texIdx]
    ReapplyTexture()
  end)

  -- Module toggles (a few common)
  y = y - 40
  local mods = { "ToT","Pet","Castbar","Mirror","DruidMana","Range","ComboPoints","SnD","Shards","CrowdControl","ThreatLite","EnergyTicker" }
  local cx = 16; local row = 0; local col = 0
  local m
  for m=1, table.getn(mods) do
    local key = mods[m]
    local on = GnerdHUDDB.profile.modules[key] and GnerdHUDDB.profile.modules[key].enabled
    MakeCheckbox(panel, key, cx + (col*160), y - (row*24), on, function(state)
      if SlashCmdList and SlashCmdList["GNERDHUD"] then
        SlashCmdList["GNERDHUD"]("mod "..key.." "..(state and "on" or "off"))
      end
    end)
    col = col + 1
    if col >= 2 then col = 0; row = row + 1 end
  end

  local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  close:SetWidth(80); close:SetHeight(24)
  close:SetPoint("BOTTOM", panel, "BOTTOM", 0, 16)
  close:SetText("Close")
  close:SetScript("OnClick", function() panel:Hide(); shown=false end)

  panel:Hide()
end

function M.Toggle(self)
  BuildPanel()
  if shown then panel:Hide(); shown=false else panel:Show(); shown=true end
end

function M.Enable(self, cfg)
  BuildPanel()
end

function M.Disable(self)
  if panel then panel:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
