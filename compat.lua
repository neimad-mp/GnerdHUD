-- GnerdHUD/compat.lua
-- UTF-8, UNIX LF
-- compat file.
local tip = getglobal("GnerdHUD_ScanTip")
if not tip then
  tip = CreateFrame("GameTooltip", "GnerdHUD_ScanTip", UIParent, "GameTooltipTemplate")
  tip:SetOwner(UIParent, "ANCHOR_NONE")
end

if not GetPlayerBuffName then
  function GetPlayerBuffName(index)
    if not index then return nil end
    tip:ClearLines()
    local ok = pcall(function() tip:SetPlayerBuff(index) end)
    if not ok then return nil end
    local fs = getglobal("GnerdHUD_ScanTipTextLeft1")
    local name = fs and fs:GetText() or nil
    tip:Hide()
    return name
  end
end
