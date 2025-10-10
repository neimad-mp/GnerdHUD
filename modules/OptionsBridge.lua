-- Hooks the existing /ghud slash handler and routes "options" to the panel.
-- 1.12-safe; avoids string.match; defers hook until PLAYER_LOGIN.

local function trimLower(s)
  if not s then return "" end
  s = string.gsub(s, "^%s+", ""); s = string.gsub(s, "%s+$", "")
  return string.lower(s)
end

local function hookSlash()
  local g = getfenv(0)
  local foundToken = nil
  for k,v in g do
    if type(k)=="string" and string.find(k, "^SLASH_") and type(v)=="string" then
      local vv = string.lower(v)
      if vv == "/ghud" then
        local token = string.gsub(k, "^SLASH_", "")
        token = string.gsub(token, "%d+$", "")
        foundToken = token
        break
      end
    end
  end
  if not foundToken then return end
  if not SlashCmdList or not SlashCmdList[foundToken] then return end

  local old = SlashCmdList[foundToken]
  SlashCmdList[foundToken] = function(msg)
    local s = trimLower(msg)
    if s == "options" or s == "opt" or s == "o" then
      if GnerdHUD_OpenOptions then GnerdHUD_OpenOptions() end
      return
    end
    return old(msg)
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  hookSlash()
  f:UnregisterEvent("PLAYER_LOGIN")
end)
