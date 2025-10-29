-- CastMirror.lua
-- UTF-8, UNIX newlines
-- Center group for Cast + Mirror bars.
-- Mirror timers read Blizzard MirrorTimer statusbars each frame (authoritative), with safe fallbacks.

local cm = {
  root = nil, mover = nil,
  locked = true,
  pos = { x = 0, y = -32 },

  cast =   { frame=nil, active=false, channel=false, start=0, finish=0, name="", fadeOutUntil=0, scale=1.0, alpha=1.0, enabled=true, height=12 },
  mirror = { frame=nil, active=false, current="", paused=false, label="", fadeOutUntil=0, scale=1.0, alpha=1.0, enabled=true, height=12 },
}

local BASE_W, BASE_H, GAP = 260, 12, 6

local function clamp01(x) x=tonumber(x) or 0; if x<0 then return 0 elseif x>1 then return 1 else return x end end
local function clampScale(x) x=tonumber(x) or 1.0; if x<0.5 then return 0.5 elseif x>1.5 then return 1.5 else return x end end
local function clampHeight(x) x=tonumber(x) or BASE_H; if x<6 then return 6 elseif x>24 then return 24 else return x end end

local function setCenterOffsets(f, x, y)
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "CENTER", tonumber(x) or 0, tonumber(y) or 0)
end

local function setMoverLocked(f, locked)
  f:SetMovable(not locked); f:EnableMouse(not locked)
  if locked then
    f.border:SetVertexColor(0,0.8,1,0.00); f.bg:SetVertexColor(0,0,0,0.00)
  else
    f.border:SetVertexColor(0,0.8,1,0.35); f.bg:SetVertexColor(0,1,0,0.08)
  end
end

local function ensureRoot()
  if cm.root then return end

  local mover = CreateFrame("Frame", "GnerdHUD_CenterMover", UIParent)
  mover:SetWidth(BASE_W); mover:SetHeight((cm.cast.height or BASE_H) + (cm.mirror.height or BASE_H) + GAP + 10)
  setCenterOffsets(mover, cm.pos.x, cm.pos.y)
  mover:SetFrameStrata("HIGH"); mover:SetScale(1.0)
  mover:SetMovable(true); mover:EnableMouse(true)
  mover:RegisterForDrag("LeftButton")
  mover.bg = mover:CreateTexture(nil, "BACKGROUND"); mover.bg:SetAllPoints(mover); mover.bg:SetTexture(0,0,0,0.00)
  mover.border = mover:CreateTexture(nil, "BORDER"); mover.border:SetAllPoints(mover); mover.border:SetTexture(0,0.8,1,0.00)

  mover:SetScript("OnDragStart", function()
    if cm.locked then return end
    mover:StartMoving()
  end)
  mover:SetScript("OnDragStop", function()
    mover:StopMovingOrSizing()
    local fx,fy = mover:GetCenter(); local px,py = UIParent:GetCenter(); px,py=px or 0,py or 0
    local ox,oy = (fx - px), (fy - py)
    setCenterOffsets(mover, ox, oy)
    cm.pos.x, cm.pos.y = ox, oy
    if GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.center then
      GnerdHUDDB.profile.center.x, GnerdHUDDB.profile.center.y = ox, oy
    end
  end)

  local root = CreateFrame("Frame", "GnerdHUD_CenterBars", mover)
  root:SetAllPoints(mover)
  root:SetFrameStrata("HIGH")
  root:SetFrameLevel((mover:GetFrameLevel() or 0) + 2)

  cm.mover = mover
  cm.root = root

  local function makeBar(name, anchor, yOfs, height)
    local h = clampHeight(height or BASE_H)
    local bar = CreateFrame("Frame", name, root)
    bar:SetPoint("TOP", anchor or root, "TOP", 0, yOfs or 0)
    bar:SetWidth(BASE_W); bar:SetHeight(h)
    bar.bg   = bar:CreateTexture(nil, "BACKGROUND"); bar.bg:SetAllPoints(bar); bar.bg:SetTexture(0, 0, 0, 0.70)
    bar.fill = bar:CreateTexture(nil, "ARTWORK");    bar.fill:SetHeight(h); bar.fill:SetTexture(0.2, 0.65, 1.0, 1.0)
    bar.fill:ClearAllPoints(); bar.fill:SetPoint("LEFT", bar, "LEFT", 0, 0); bar.fill:SetWidth(1)
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0); bar.text:SetText("")
    bar._height = h
    bar:Hide()
    return bar
  end

  cm.cast.height   = clampHeight(GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.castBar and GnerdHUDDB.profile.castBar.height or cm.cast.height or BASE_H)
  cm.mirror.height = clampHeight(GnerdHUDDB and GnerdHUDDB.profile and GnerdHUDDB.profile.mirrorBar and GnerdHUDDB.profile.mirrorBar.height or cm.mirror.height or BASE_H)

  cm.cast.frame   = makeBar("GnerdHUD_CastBar", nil, 0, cm.cast.height)
  cm.mirror.frame = makeBar("GnerdHUD_MirrorBar", cm.cast.frame, -(cm.cast.height + GAP), cm.mirror.height)

  cm.cast.frame.fill:SetTexture(1.0, 0.7, 0.1, 1.0)
  cm.mirror.frame.fill:SetTexture(0.2, 0.8, 1.0, 1.0)

  setMoverLocked(mover, cm.locked)
end

local function applyLocalSizes()
  if not cm.root then return end
  local cw = BASE_W * cm.cast.scale
  local mw = BASE_W * cm.mirror.scale
  local ch = clampHeight(cm.cast.height)
  local mh = clampHeight(cm.mirror.height)

  cm.cast.frame:SetWidth(cw);     cm.cast.frame:SetHeight(ch);     cm.cast.frame.fill:SetHeight(ch); cm.cast.frame._height = ch
  cm.mirror.frame:SetWidth(mw);   cm.mirror.frame:SetHeight(mh);   cm.mirror.frame.fill:SetHeight(mh); cm.mirror.frame._height = mh

  -- reposition mirror below cast using their real heights
  cm.mirror.frame:ClearAllPoints()
  cm.mirror.frame:SetPoint("TOP", cm.cast.frame, "BOTTOM", 0, -GAP)

  -- adjust mover bounds
  cm.mover:SetWidth(math.max(cw, mw))
  cm.mover:SetHeight(ch + mh + GAP + 10)
end

local function setBarFrac(bar, frac, scale)
  frac = clamp01(frac)
  local w = (BASE_W * (scale or 1.0)) * frac
  if w < 1 then w = 1 end
  bar.fill:SetWidth(w)
end

local function ensureMirrorFramesLoaded()
  if getglobal and getglobal("MirrorTimer1") then return end
  if UIParentLoadAddOn then pcall(UIParentLoadAddOn, "Blizzard_Mirror") end
end

-- Prefer statusbars (works with pfUI)
local function readFromStatusBars()
  ensureMirrorFramesLoaded()
  local best
  for i=1,3 do
    local f  = getglobal("MirrorTimer"..i)
    local sb = getglobal("MirrorTimer"..i.."StatusBar")
    if f and sb and f.timer and f.timer ~= "" then
      local minv, maxv = sb:GetMinMaxValues()
      local v = sb:GetValue()
      if maxv and maxv > 0 and v and v >= 0 then
        local frac = v / maxv
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        local label = (f.label and f.label.GetText and f.label:GetText()) or f.timer
        local entry = { name=f.timer, label=label, frac=frac, paused=(f.paused and true or false) }
        if not best or f.timer == "BREATH" then best = entry; if f.timer == "BREATH" then break end end
      end
    end
  end
  return best
end

-- Fallback: raw frames
local function readFromFrames()
  ensureMirrorFramesLoaded()
  local best
  for i=1,3 do
    local f = getglobal("MirrorTimer"..i)
    if f and f.timer and f.timer ~= "" and f.maxvalue and f.maxvalue ~= 0 then
      local v = f.value
      if not v and f.statusbar and f.statusbar.GetValue then v = f.statusbar:GetValue() end
      if v and v >= 0 then
        local frac = v / (f.maxvalue or 1)
        if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
        local label = (f.label and f.label.GetText and f.label:GetText()) or f.timer
        local entry = { name=f.timer, label=label, frac=frac, paused=(f.paused and true or false) }
        if not best or f.timer == "BREATH" then best = entry; if f.timer == "BREATH" then break end end
      end
    end
  end
  return best
end

-- Fallback: API
local function readFromAPI()
  if not GetMirrorTimerInfo then return nil end
  local best
  for i=1,3 do
    local n, text, value, maxv, scale, paused, label = GetMirrorTimerInfo(i)
    if n and n ~= "" and n ~= "UNKNOWN" and maxv and maxv ~= 0 and value and value >= 0 then
      local frac = (tonumber(value) or 0) / (tonumber(maxv) or 1)
      if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
      local entry = { name=n, label=(label or text or n), frac=frac, paused=(paused==1) }
      if not best or n == "BREATH" then best = entry; if n == "BREATH" then break end end
    end
  end
  return best
end

local function computeStateAlpha(which)
  local p = GnerdHUDDB and GnerdHUDDB.profile or nil
  if not p then return 1.0 end
  local aSet = (which == "cast") and p.castAlpha or p.mirrorAlpha
  local inCombat = GnerdHUD and GnerdHUD.env and GnerdHUD.env.state and GnerdHUD.env.state.inCombat
  local hasTarget = GnerdHUD and GnerdHUD.env and GnerdHUD.env.state and GnerdHUD.env.state.hasTarget
  if inCombat then return aSet.combat end
  if hasTarget then return aSet.target end
  local hp, hpm = UnitHealth("player") or 0, UnitHealthMax("player") or 1
  if hpm > 0 and hp >= hpm then return aSet.ooc_full end
  return aSet.ooc_hurt
end

local function applyAlpha()
  if not cm.root then return end
  local p = GnerdHUDDB and GnerdHUDDB.profile or {}
  local ca = clamp01((p.castBar   and p.castBar.alpha   or 1.0) * computeStateAlpha("cast"))
  local ma = clamp01((p.mirrorBar and p.mirrorBar.alpha or 1.0) * computeStateAlpha("mirror"))
  if cm.cast.frame   then cm.cast.frame:SetAlpha(ca) end
  if cm.mirror.frame then cm.mirror.frame:SetAlpha(ma) end
  if cm.mover then cm.mover:SetAlpha(math.max(ca, ma)) end
end

local function updateCast()
  if not cm.cast.active or not cm.cast.enabled then return end
  local now = GetTime()

  if cm.cast.fadeOutUntil > 0 then
    if now >= cm.cast.fadeOutUntil then
      cm.cast.fadeOutUntil = 0
      cm.cast.active = false
      cm.cast.frame:Hide()
      return
    else
      setBarFrac(cm.cast.frame, 1.0, cm.cast.scale)
      return
    end
  end

  local t0, t1 = cm.cast.start, cm.cast.finish
  if now >= t1 then
    cm.cast.fadeOutUntil = now + 0.10
    setBarFrac(cm.cast.frame, 1.0, cm.cast.scale)
    return
  end
  local frac = (now - t0) / (t1 - t0)
  if cm.cast.channel then frac = 1 - frac end
  setBarFrac(cm.cast.frame, frac, cm.cast.scale)
  cm.cast.frame:Show()
end

local function updateMirror()
  local p = GnerdHUDDB and GnerdHUDDB.profile or {}
  if not p.mirrorBar or not p.mirrorBar.enabled then
    if cm.mirror.frame then cm.mirror.frame:Hide() end
    return
  end

  local info = readFromStatusBars() or readFromFrames() or readFromAPI()

  if info then
    cm.mirror.active  = true
    cm.mirror.current = info.name
    cm.mirror.label   = info.label or info.name
    cm.mirror.paused  = info.paused and true or false
    cm.mirror.frame.text:SetText(cm.mirror.label)
    setBarFrac(cm.mirror.frame, clamp01(info.frac), cm.mirror.scale)
    cm.mirror.frame:Show()
    return
  end

  if cm.mirror.fadeOutUntil > 0 and GetTime() < cm.mirror.fadeOutUntil then
    setBarFrac(cm.mirror.frame, 1.0, cm.mirror.scale)
    cm.mirror.frame:Show()
  else
    cm.mirror.active = false
    if cm.locked then
      if cm.mirror.frame then cm.mirror.frame:Hide() end
    else
      if cm.mirror.frame then
        cm.mirror.frame.text:SetText(cm.mirror.label ~= "" and cm.mirror.label or "Mirror")
        setBarFrac(cm.mirror.frame, 0.5, cm.mirror.scale)
        cm.mirror.frame:Show()
      end
    end
  end
end

local updater = CreateFrame("Frame", "GnerdHUD_CenterBarsUpdater", UIParent)
local alphaTick = 0
updater:SetScript("OnUpdate", function()
  updateCast()
  updateMirror()
  alphaTick = (alphaTick or 0) + (arg1 or 0)
  if alphaTick > 0.2 then
    applyAlpha()
    alphaTick = 0
  end
end)

-- External API

function GnerdHUD.Cast_Init()
  ensureRoot()
  -- seed heights from DB when present
  local p = GnerdHUDDB and GnerdHUDDB.profile or nil
  if p and p.castBar then cm.cast.height = clampHeight(p.castBar.height or cm.cast.height or BASE_H) end
  if p and p.mirrorBar then cm.mirror.height = clampHeight(p.mirrorBar.height or cm.mirror.height or BASE_H) end
  applyLocalSizes()
  cm.cast.active = false; cm.cast.fadeOutUntil = 0
  cm.mirror.active = false; cm.mirror.fadeOutUntil = 0
  if cm.cast.frame then cm.cast.frame:Hide() end
  if cm.mirror.frame then cm.mirror.frame:Hide() end
  applyAlpha()
end

function GnerdHUD.Cast_Destroy()
  if cm.root then cm.root:Hide(); cm.root:SetParent(nil) end
  if cm.mover then cm.mover:Hide(); cm.mover:SetParent(nil) end
  cm.root, cm.mover = nil, nil
  cm.cast = { frame=nil, active=false, channel=false, start=0, finish=0, name="", fadeOutUntil=0, scale=1.0, alpha=1.0, enabled=true, height=12 }
  cm.mirror = { frame=nil, active=false, current="", paused=false, label="", fadeOutUntil=0, scale=1.0, alpha=1.0, enabled=true, height=12 }
end

function GnerdHUD.Cast_UpdateAlpha()
  applyAlpha()
end

function GnerdHUD.Cast_SetLocked(locked)
  cm.locked = (locked ~= false)
  ensureRoot()
  setMoverLocked(cm.mover, cm.locked)
  if not cm.locked then
    if cm.cast.frame and (not cm.cast.active) and (GnerdHUDDB.profile.castBar.enabled ~= false) then
      cm.cast.frame.text:SetText(cm.cast.name ~= "" and cm.cast.name or "Cast")
      setBarFrac(cm.cast.frame, 0.5, cm.cast.scale)
      cm.cast.frame:Show()
    end
    if cm.mirror.frame and (not cm.mirror.active) and (GnerdHUDDB.profile.mirrorBar.enabled ~= false) then
      cm.mirror.frame.text:SetText(cm.mirror.label ~= "" and cm.mirror.label or "Mirror")
      setBarFrac(cm.mirror.frame, 0.5, cm.mirror.scale)
      cm.mirror.frame:Show()
    end
  else
    if cm.cast.frame and not cm.cast.active then cm.cast.frame:Hide() end
    if cm.mirror.frame and not cm.mirror.active then cm.mirror.frame:Hide() end
  end
  applyAlpha()
end

function GnerdHUD.Cast_SetPosition(x,y)
  ensureRoot()
  cm.pos.x, cm.pos.y = tonumber(x) or 0, tonumber(y) or -32
  setCenterOffsets(cm.mover, cm.pos.x, cm.pos.y)
end

function GnerdHUD.Cast_SetLocalScales(castScale, mirrorScale)
  cm.cast.scale   = clampScale(castScale)
  cm.mirror.scale = clampScale(mirrorScale)
  ensureRoot()
  applyLocalSizes()
end

function GnerdHUD.Cast_SetLocalHeights(castHeight, mirrorHeight)
  cm.cast.height   = clampHeight(castHeight)
  cm.mirror.height = clampHeight(mirrorHeight)
  ensureRoot()
  applyLocalSizes()
end

function GnerdHUD.Cast_SetLocalAlphas(castAlpha, mirrorAlpha)
  cm.cast.alpha   = clamp01(castAlpha)
  cm.mirror.alpha = clamp01(mirrorAlpha)
  applyAlpha()
end

function GnerdHUD.Cast_SetEnabled(castEnabled, mirrorEnabled)
  cm.cast.enabled   = (castEnabled ~= false)
  cm.mirror.enabled = (mirrorEnabled ~= false)
  if not cm.cast.enabled and cm.cast.frame then cm.cast.frame:Hide() end
  if not cm.mirror.enabled and cm.mirror.frame then cm.mirror.frame:Hide() end
end

function GnerdHUD.Cast_OnEvent()
  local e = event

  if e == "SPELLCAST_START" then
    if GnerdHUDDB.profile.castBar.enabled == false then return end
    ensureRoot()
    local name = tostring(arg1 or "")
    local dur  = tonumber(arg2) or 0
    if dur <= 0 then dur = 1500 end
    cm.cast.name   = name
    cm.cast.start  = GetTime()
    cm.cast.finish = cm.cast.start + (dur / 1000.0)
    cm.cast.channel= false
    cm.cast.fadeOutUntil = 0
    cm.cast.active = true
    cm.cast.frame.text:SetText(name)
    setBarFrac(cm.cast.frame, 0, cm.cast.scale)
    cm.cast.frame:Show()
    return
  end

  if e == "SPELLCAST_STOP" then
    if not cm.cast.active then return end
    cm.cast.fadeOutUntil = GetTime() + 0.10
    return
  end

  if e == "SPELLCAST_FAILED" or e == "SPELLCAST_INTERRUPTED" then
    cm.cast.active=false; cm.cast.fadeOutUntil=0; if cm.cast.frame then cm.cast.frame:Hide() end
    return
  end

  if e == "SPELLCAST_DELAYED" then
    local delay = tonumber(arg1) or 0
    if cm.cast.active then cm.cast.finish = cm.cast.finish + (delay / 1000.0) end
    return
  end

  if e == "SPELLCAST_CHANNEL_START" then
    if GnerdHUDDB.profile.castBar.enabled == false then return end
    ensureRoot()
    local name = tostring(arg1 or "")
    local dur  = tonumber(arg2) or 0
    if dur <= 0 then dur = 1500 end
    cm.cast.name   = name
    cm.cast.start  = GetTime()
    cm.cast.finish = cm.cast.start + (dur / 1000.0)
    cm.cast.channel= true
    cm.cast.fadeOutUntil=0
    cm.cast.active = true
    cm.cast.frame.text:SetText(name)
    setBarFrac(cm.cast.frame, 1.0, cm.cast.scale)
    cm.cast.frame:Show()
    return
  end

  if e == "SPELLCAST_CHANNEL_UPDATE" then
    local remaining = tonumber(arg1) or 0
    if cm.cast.active and cm.cast.channel then
      cm.cast.finish = GetTime() + (remaining / 1000.0)
    end
    return
  end

  if e == "SPELLCAST_CHANNEL_STOP" then
    if cm.cast.active then cm.cast.fadeOutUntil = GetTime() + 0.10 end
    return
  end

  if e == "MIRROR_TIMER_START" then
    if GnerdHUDDB.profile.mirrorBar.enabled == false then return end
    ensureRoot()
    cm.mirror.fadeOutUntil = 0
    cm.mirror.active = true
    if cm.mirror.frame then cm.mirror.frame:Show() end
    return
  end

  if e == "MIRROR_TIMER_STOP" then
    cm.mirror.fadeOutUntil = GetTime() + 0.10
    return
  end

  if e == "MIRROR_TIMER_PAUSE" then
    local paused = arg1
    if type(paused) ~= "number" and type(paused) ~= "boolean" then paused = arg2 end
    cm.mirror.paused = (paused == 1) or (paused == true)
    return
  end
end
