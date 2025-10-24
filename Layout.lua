-- Layout.lua
-- UTF-8, UNIX newlines

local lay = {
  frames = {
    leftMover = nil, rightMover = nil,
    leftRoot = nil,  rightRoot = nil,
    playerHealth = nil, playerPower = nil,
    targetHealth = nil, targetPower = nil,
    dbg = nil,
  },
}

local MOVERSIZE = 280

local function healthGradientColor(frac)
  if frac >= 0.5 then local t=(frac-0.5)*2; return (1-t), 1, 0 end
  local t=frac*2; return 1, t, 0
end

local function setCenterOffsets(f, x, y)
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "CENTER", tonumber(x) or 0, tonumber(y) or 0)
end

local function makeMover(name, x, y, sideTag)
  local f = CreateFrame("Frame", name, UIParent)
  f:SetWidth(MOVERSIZE); f:SetHeight(MOVERSIZE)
  setCenterOffsets(f, tonumber(x) or 0, tonumber(y) or 0)
  f:SetFrameStrata("MEDIUM")
  f._side = sideTag
  f._dragging = false

  f:SetScale(1.0)
  f:SetMovable(true); f:EnableMouse(true)

  f.bg = f:CreateTexture(nil, "BACKGROUND"); f.bg:SetAllPoints(f); f.bg:SetTexture(0, 0, 0, 0.00)
  f.border = CreateFrame("Frame", nil, f); f.border:SetAllPoints(f); f.border:SetFrameStrata("MEDIUM"); f.border:SetFrameLevel((f:GetFrameLevel() or 0) + 1)
  f.border.tex = f.border:CreateTexture(nil, "BORDER"); f.border.tex:SetAllPoints(f.border); f.border.tex:SetTexture(0, 0.8, 1, 0.00)

  local root = CreateFrame("Frame", name .. "_Root", f)
  root:SetAllPoints(f)
  root:SetFrameStrata("DIALOG")
  root:SetFrameLevel((f:GetFrameLevel() or 0) + 20)
  root:SetScale(1.0)
  f.root = root

  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function()
    if not f:IsMovable() then return end
    f._dragging = true
    f:StartMoving()
  end)
  f:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    f._dragging = false
    local fx,fy = f:GetCenter(); local px,py = UIParent:GetCenter(); px,py=px or 0,py or 0
    local ox,oy = (fx - px), (fy - py)
    f:ClearAllPoints(); f:SetPoint("CENTER", UIParent, "CENTER", ox, oy)
    if GnerdHUDDB and GnerdHUDDB.profile then
      if f._side == "left" then GnerdHUDDB.profile.left.x,  GnerdHUDDB.profile.left.y  = ox, oy
      else                       GnerdHUDDB.profile.right.x, GnerdHUDDB.profile.right.y = ox, oy
      end
    end
  end)
  f:SetScript("OnHide", function()
    if f._dragging then f:StopMovingOrSizing(); f._dragging=false end
  end)

  return f
end

local function setMoverLocked(f, locked)
  f:SetMovable(not locked); f:EnableMouse(not locked)
  if locked then
    f.border.tex:SetTexture(0, 0.8, 1, 0.00); f.bg:SetTexture(0, 0, 0, 0.00)
  else
    f.border.tex:SetTexture(0, 0.8, 1, 0.35); f.bg:SetTexture(0, 1, 0, 0.08)
  end
end

function GnerdHUD.LayoutSetRightEnabled(flag)
  local f = lay.frames
  if flag then
    if not f.targetHealth then
      f.targetHealth = GnerdHUD_CreateArc(f.rightRoot, "GnerdHUD_TargetHealthArc", {
        segments = (GnerdHUDDB.profile.segments or 64),
        radius = 180, thickness = 28, startAngle = 50, endAngle = -50, color = {r=0.2,g=1,b=0.2,a=1}, fillFromEnd = true,
      })
    end
    if not f.targetPower then
      f.targetPower = GnerdHUD_CreateArc(f.rightRoot, "GnerdHUD_TargetPowerArc", {
        segments = (GnerdHUDDB.profile.segments or 64),
        radius = 140, thickness = 22, startAngle = 45, endAngle = -45, color = {r=0.25,g=0.65,b=1,a=1}, fillFromEnd = true,
      })
    end
  else
    if f.targetHealth then f.targetHealth:Hide(); f.targetHealth:SetParent(nil); f.targetHealth = nil end
    if f.targetPower  then f.targetPower:Hide();  f.targetPower:SetParent(nil);  f.targetPower  = nil end
  end
  if f.rightMover then f.rightMover:Show() end
  GnerdHUD.LayoutUpdateAlpha()
end

function GnerdHUD.LayoutSetPositions(left, right)
  if not lay.frames.leftMover or not lay.frames.rightMover then return end
  setCenterOffsets(lay.frames.leftMover,  tonumber(left and left.x or 0),  tonumber(left and left.y or 0))
  setCenterOffsets(lay.frames.rightMover, tonumber(right and right.x or 0), tonumber(right and right.y or 0))
  if GnerdHUDDB and GnerdHUDDB.profile and GnerdHUD.Cast_SetPosition then
    local c = GnerdHUDDB.profile.center
    GnerdHUD.Cast_SetPosition(tonumber(c and c.x or 0), tonumber(c and c.y or -32))
  end
end

function GnerdHUD.LayoutCreate()
  local p  = (GnerdHUDDB and GnerdHUDDB.profile) or nil
  local left  = (p and p.left)  or { x = 0, y = 0 }
  local right = (p and p.right) or { x = 0, y = 0 }

  lay.frames.leftMover  = lay.frames.leftMover  or makeMover("GnerdHUD_LeftHUD",  left.x,  left.y,  "left")
  lay.frames.rightMover = lay.frames.rightMover or makeMover("GnerdHUD_RightHUD", right.x, right.y, "right")

  lay.frames.leftRoot   = lay.frames.leftMover.root
  lay.frames.rightRoot  = lay.frames.rightMover.root

  local segs   = (p and tonumber(p.segments)) or 64
  local colors = (p and p.colors) or { health={r=0.2,g=1,b=0.2,a=1}, power={r=0.25,g=0.65,b=1,a=1} }

  if not lay.frames.playerHealth then
    lay.frames.playerHealth = GnerdHUD_CreateArc(lay.frames.leftRoot, "GnerdHUD_PlayerHealthArc", {
      segments = segs, radius = 180, thickness = 28, startAngle = 130, endAngle = 230, color = colors.health, fillFromEnd = true,
    })
  end
  if not lay.frames.playerPower then
    lay.frames.playerPower = GnerdHUD_CreateArc(lay.frames.leftRoot, "GnerdHUD_PlayerPowerArc", {
      segments = segs, radius = 140, thickness = 22, startAngle = 135, endAngle = 225, color = colors.power, fillFromEnd = true,
    })
  end

  if p and p.rightEnabled then
    GnerdHUD.LayoutSetRightEnabled(true)
  end

  GnerdHUD.LayoutSetScale(p and p.scale or 1.0)
  GnerdHUD.LayoutUpdatePlayerColors()
  GnerdHUD.LayoutUpdateTargetColors()
  GnerdHUD.LayoutUpdatePlayer()
  GnerdHUD.LayoutUpdateTarget()

  if GnerdHUD.Cast_Init then GnerdHUD.Cast_Init() end
  if GnerdHUD.Cast_SetPosition and p and p.center then GnerdHUD.Cast_SetPosition(p.center.x, p.center.y) end
end

function GnerdHUD.LayoutDestroy()
  local f = lay.frames
  if f.playerHealth then f.playerHealth:Hide(); f.playerHealth:SetParent(nil); f.playerHealth = nil end
  if f.playerPower  then f.playerPower:Hide();  f.playerPower:SetParent(nil);  f.playerPower  = nil end
  if f.targetHealth then f.targetHealth:Hide(); f.targetHealth:SetParent(nil); f.targetHealth = nil end
  if f.targetPower  then f.targetPower:Hide();  f.targetPower:SetParent(nil);  f.targetPower  = nil end
  if f.dbg          then f.dbg:Hide();          f.dbg = nil end
  if f.leftMover    then f.leftMover:Hide();    f.leftMover:SetParent(nil);    f.leftMover    = nil end
  if f.rightMover   then f.rightMover:Hide();   f.rightMover:SetParent(nil);   f.rightMover   = nil end
  f.leftRoot, f.rightRoot = nil, nil
  if GnerdHUD.Cast_Destroy then GnerdHUD.Cast_Destroy() end
end

function GnerdHUD.LayoutSetLocked(locked)
  local f = lay.frames
  if not f.leftMover or not f.rightMover then return end
  local setMoverLocked = setMoverLocked
  setMoverLocked(f.leftMover, locked)
  setMoverLocked(f.rightMover, locked)
  if GnerdHUD.Cast_SetLocked then GnerdHUD.Cast_SetLocked(locked) end
  GnerdHUD.LayoutUpdateAlpha()
end

function GnerdHUD.LayoutSetScale(scale)
  scale = tonumber(scale) or 1.0
  if scale < 0.5 then scale = 0.5 elseif scale > 1.5 then scale = 1.5 end

  if lay.frames.leftMover then
    lay.frames.leftMover:SetScale(1.0)
    lay.frames.leftMover:SetWidth(MOVERSIZE * scale)
    lay.frames.leftMover:SetHeight(MOVERSIZE * scale)
  end
  if lay.frames.rightMover then
    lay.frames.rightMover:SetScale(1.0)
    lay.frames.rightMover:SetWidth(MOVERSIZE * scale)
    lay.frames.rightMover:SetHeight(MOVERSIZE * scale)
  end

  if lay.frames.leftRoot  then lay.frames.leftRoot:SetScale(scale)  end
  if lay.frames.rightRoot then lay.frames.rightRoot:SetScale(scale) end
end

local function powerColor(unit)
  local t = UnitPowerType and UnitPowerType(unit) or 0
  if t == 1 then return 1.0, 0.10, 0.10 end
  if t == 3 then return 1.0, 0.70, 0.10 end
  if t == 4 then return 0.60, 0.00, 0.60 end
  if t == 2 then return 1.00, 1.00, 0.10 end
  return 0.25, 0.65, 1.00
end

function GnerdHUD.LayoutUpdatePlayerColors()
  if not lay.frames.playerPower then return end
  local r,g,b = powerColor("player")
  lay.frames.playerPower:SetColor(r,g,b,1.0)
end

function GnerdHUD.LayoutUpdateTargetColors()
  if not lay.frames.targetPower then return end
  local r,g,b = powerColor("target")
  lay.frames.targetPower:SetColor(r,g,b,1.0)
end

function GnerdHUD.LayoutUpdatePlayer()
  if not lay.frames.playerHealth then return end
  local hp  = UnitHealth("player") or 0
  local hpm = UnitHealthMax("player") or 1
  local mp  = UnitMana("player") or 0
  local mpm = UnitManaMax("player") or 1
  local hf = (hpm > 0) and (hp / hpm) or 0
  local mf = (mpm > 0) and (mp / mpm) or 0
  do local r,g,b = healthGradientColor(hf); lay.frames.playerHealth:SetColor(r,g,b,1.0) end
  lay.frames.playerHealth:SetFraction(hf)
  lay.frames.playerPower:SetFraction(mf)
end

function GnerdHUD.LayoutUpdateTarget()
  if not lay.frames.targetHealth then return end
  if UnitExists("target") ~= 1 then
    lay.frames.targetHealth:SetFraction(0); lay.frames.targetPower:SetFraction(0); return
  end
  local hp  = UnitHealth("target") or 0
  local hpm = UnitHealthMax("target") or 1
  local mp  = UnitMana("target") or 0
  local mpm = UnitManaMax("target") or 1
  local hf = (hpm > 0) and (hp / hpm) or 0
  local mf = (mpm > 0) and (mp / mpm) or 0
  do local r,g,b = healthGradientColor(hf); lay.frames.targetHealth:SetColor(r,g,b,1.0) end
  lay.frames.targetHealth:SetFraction(hf)
  lay.frames.targetPower:SetFraction(mf)
end

local function baseAlpha()
  local p = GnerdHUDDB and GnerdHUDDB.profile or nil
  local a = (p and p.alpha) or { ooc_full=0.0, ooc_hurt=0.25, target=0.6, combat=1.0 }
  if p and p.locked == false then return 1.0 end
  if GnerdHUD.env and GnerdHUD.env.state and GnerdHUD.env.state.inCombat then return a.combat end
  if GnerdHUD.env and GnerdHUD.env.state and GnerdHUD.env.state.hasTarget then return a.target end
  local hp, hpm = UnitHealth("player") or 0, UnitHealthMax("player") or 1
  if hpm > 0 and hp >= hpm then return a.ooc_full end
  return a.ooc_hurt
end

function GnerdHUD.LayoutUpdateAlpha()
  local p = GnerdHUDDB and GnerdHUDDB.profile or nil
  local la = baseAlpha()
  local ra = (p and p.locked == false) and 1.0 or ((p and p.rightEnabled) and la or 0)
  if lay.frames.leftMover  then lay.frames.leftMover:SetAlpha(la) end
  if lay.frames.rightMover then lay.frames.rightMover:SetAlpha(ra) end
  if GnerdHUD.Cast_SetBaseAlpha then GnerdHUD.Cast_SetBaseAlpha(la) end
end
