-- Core hardening and Vanilla handler safety for GnerdHUD (0.4.4)
-- This file adds safe script wrappers and applies drag-handler fixes
-- without modifying existing modules. It also validates module shapes.

local function msg(s)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff7fdfffGnerdHUD|r: "..tostring(s)) end
end

-- Defensive global namespace fetch (won't create the table if nil)
local GH = GnerdHUD

-- Safe wrapper that tolerates Retail-style handlers expecting 'self' (and elapsed)
local function _wrap_noargs(frame, fn)
  return function()
    if type(fn) ~= "function" then return end
    -- Try (self), then () as a fallback. Ignore errors.
    if not pcall(fn, frame) then pcall(fn) end
  end
end

local function _wrap_onupdate(frame, fn)
  return function()
    if type(fn) ~= "function" then return end
    local e = arg1
    if not pcall(fn, frame, e) then
      if not pcall(fn, e) then
        pcall(fn)
      end
    end
  end
end

local function _wrap_onevent(frame, fn)
  return function()
    if type(fn) ~= "function" then return end
    local ev = event
    -- (self, event, ...) is common on newer code; tolerate (event, ...) and () too.
    if not pcall(fn, frame, ev, arg1, arg2, arg3, arg4, arg5) then
      if not pcall(fn, ev, arg1, arg2, arg3, arg4, arg5) then
        pcall(fn)
      end
    end
  end
end

-- Public helper: safely assign handlers regardless of expected signature
GnerdHUD_SafeSetScript = function(frame, script, fn)
  if not frame or type(frame) ~= "table" or type(frame.SetScript) ~= "function" then return end
  if type(fn) ~= "function" then
    -- Allow clearing via nil or assigning a raw function (rare)
    frame:SetScript(script, fn)
    return
  end
  if script == "OnUpdate" then
    frame:SetScript("OnUpdate", _wrap_onupdate(frame, fn))
  elseif script == "OnEvent" then
    frame:SetScript("OnEvent", _wrap_onevent(frame, fn))
  else
    frame:SetScript(script, _wrap_noargs(frame, fn))
  end
end

-- Public helper: make any frame draggable with safe handlers
GnerdHUD_MakeDraggable = function(frame)
  if not frame or type(frame.RegisterForDrag) ~= "function" then return end
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  GnerdHUD_SafeSetScript(frame, "OnDragStart", function(self) if self and self.StartMoving then self:StartMoving() end end)
  GnerdHUD_SafeSetScript(frame, "OnDragStop",  function(self) if self and self.StopMovingOrSizing then self:StopMovingOrSizing() end end)
end

-- Validation: warn if any module is a function (should be a table)
local function validate_modules()
  if not GH or type(GH.modules) ~= "table" then return end
  local bad = 0
  for name, mod in GH.modules do
    if type(name) == "string" and type(mod) == "function" then
      bad = bad + 1
    end
  end
  if bad > 0 then
    msg("warning: "..bad.." module(s) registered as functions; prefer table modules (no action needed if things work).")
  end
end

-- Apply drag safety across known bars if present.
local function fix_known_frames()
  if not GH or type(GH.bars) ~= "table" then return false end
  local fixed = 0
  local function fix(f) if f then GnerdHUD_MakeDraggable(f); fixed = fixed + 1 end end

  fix(GH.bars.playerHealth)
  fix(GH.bars.playerPower)
  fix(GH.bars.targetHealth)
  fix(GH.bars.targetPower)
  -- Add more known frames if core exposes them later.

  return fixed > 0
end

-- Defer fixes until login; then retry briefly to catch late-built frames
local driver = CreateFrame("Frame")
driver._elapsed = 0
driver._tries = 0
driver._done = false

driver:SetScript("OnUpdate", function()
  if not driver._armed then return end
  driver._elapsed = driver._elapsed + (arg1 or 0)
  if driver._elapsed < 0.5 then return end
  driver._elapsed = 0

  local any = fix_known_frames()
  driver._tries = driver._tries + 1
  if driver._tries >= 12 or any then
    driver._done = true
    driver._armed = false
    driver:SetScript("OnUpdate", nil)
  end
end)

driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function()
  validate_modules()
  -- Arm a short retry loop (~6s max) to wait for core-created frames
  driver._armed = true
  driver._elapsed = 0
  driver._tries = 0
end)

-- Extra guard: if GetPlayerBuffName is absent (should be provided by compat.lua),
-- create a no-op to avoid hard errors. compat.lua supplies the real one.
if not GetPlayerBuffName then
  GetPlayerBuffName = function() return nil end
end
