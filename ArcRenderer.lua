-- ArcRenderer.lua
-- UTF-8, UNIX newlines
-- Segmented arc builder, explicitly anchored to the parent center. High strata/level.
-- Supports fill direction (from start or from end of arc).

local function clamp01(x) if x < 0 then return 0 elseif x > 1 then return 1 else return x end end

function GnerdHUD_CreateArc(parent, name, opts)
  local segs   = math.max(8, tonumber(opts.segments or 64))
  local radius = tonumber(opts.radius or 180)
  local thick  = tonumber(opts.thickness or 26)
  local a0deg  = tonumber(opts.startAngle or 130)    -- vertical-left default
  local a1deg  = tonumber(opts.endAngle   or 230)
  local fromEnd= (opts.fillFromEnd == true)          -- show from arc end backwards (bottom-up on left arcs)

  local f = CreateFrame("Frame", name, parent)
  f:SetWidth(radius * 2)
  f:SetHeight(radius * 2)
  f:ClearAllPoints()
  f:SetPoint("CENTER", parent, "CENTER", 0, 0)
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel((parent:GetFrameLevel() or 0) + 50)
  f:SetAlpha(1.0)
  f:Show()

  f._opts    = { segments = segs, radius = radius, thickness = thick, a0 = a0deg, a1 = a1deg }
  f._lit     = -1
  f._fromEnd = fromEnd
  f._color   = {
    r = (opts.color and opts.color.r) or 1,
    g = (opts.color and opts.color.g) or 1,
    b = (opts.color and opts.color.b) or 1,
    a = (opts.color and opts.color.a) or 1,
  }

  local a0, a1 = math.rad(a0deg), math.rad(a1deg)
  local span   = (a1 - a0)
  local segLen = math.max(6, math.floor(thick * 0.40))  -- visual smoothing without rotation

  f._segments = {}
  for i = 1, segs do
    local t   = (i - 0.5) / segs
    local ang = a0 + span * t
    local rmid = radius - (thick / 2)
    local x = math.cos(ang) * rmid
    local y = math.sin(ang) * rmid

    local s = f:CreateTexture(name .. "_Seg" .. i, "OVERLAY")
    s:SetTexture(1, 1, 1, 1)  -- solid color (1.12-safe)
    s:SetVertexColor(f._color.r, f._color.g, f._color.b, f._color.a)
    s:SetWidth(thick)
    s:SetHeight(segLen)
    s:ClearAllPoints()
    s:SetPoint("CENTER", f, "CENTER", x, y)
    s:Hide()
    f._segments[i] = s
  end

  function f:SetColor(r, g, b, a)
    self._color.r, self._color.g, self._color.b, self._color.a = r, g, b, a or 1
    for i = 1, self._opts.segments do
      local seg = self._segments[i]
      seg:SetVertexColor(r, g, b, a or 1)
    end
  end

  function f:SetFillFromEnd(flag)
    self._fromEnd = (flag == true)
    self:SetFraction(self._lit / self._opts.segments) -- re-apply
  end

  function f:SetFraction(frac)
    local n = math.floor(clamp01(frac) * self._opts.segments + 0.5)
    if n == self._lit then return end
    self._lit = n

    local s, e
    if self._fromEnd then
      s = self._opts.segments - n + 1
      e = self._opts.segments
    else
      s = 1
      e = n
    end
    if s < 1 then s = 1 end
    if e < 0 then e = 0 end

    for i = 1, self._opts.segments do
      local tex = self._segments[i]
      if tex then
        if i >= s and i <= e then tex:Show() else tex:Hide() end
      end
    end
  end

  return f
end
