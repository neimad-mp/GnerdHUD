-- GnerdHUD/modules/Shards.lua
-- UTF-8, UNIX LF
-- Warlock Soul Shard counter (bag scan, throttled on BAG_UPDATE)

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "Shards" }

local frame, mover
local lastCount, lastTick = -1, 0

local function Ensure()
  if frame then return end
  local a = GnerdHUDDB.profile.modules.Shards.anchor
  local cfg = GnerdHUDDB.profile.bars
  frame = CreateFrame("Frame", "GnerdHUD_Shards", UIParent)
  frame:SetWidth(80); frame:SetHeight(cfg.height+2)
  frame:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  local fs = frame:CreateFontString(nil, "OVERLAY")
  fs:SetFont(cfg.font, cfg.fontSize+2, "OUTLINE")
  fs:SetPoint("CENTER", frame, "CENTER", 0, 0)
  fs:SetText("0")
  frame.text = fs
  frame:Hide()
end

local function CountShards()
  local total = 0
  local bag
  for bag=0,4 do
    local slots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0
    local s
    for s=1, slots do
      local link = GetContainerItemLink and GetContainerItemLink(bag, s)
      if link and string.find(link, "Soul Shard", 1, true) then
        total = total + 1
      end
    end
  end
  return total
end

local function Update(now)
  Ensure()
  if not frame then return end
  if (now - lastTick) < 0.2 then return end
  lastTick = now
  local cnt = CountShards()
  if cnt ~= lastCount then
    frame.text:SetText(cnt)
    if cnt > 0 then frame:Show() else frame:Hide() end
    GH.SetAlphaSmart(frame)
    lastCount = cnt
  end
end

local function CreateMover()
  if mover then return end
  Ensure()
  local b = CreateFrame("Button", "GnerdHUD_Shards_Mover", UIParent)
  b:SetWidth(frame:GetWidth()+8); b:SetHeight(frame:GetHeight()+8)
  b:SetPoint("CENTER", frame, "CENTER", 0, 0)
  b:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets={ left=3,right=3,top=3,bottom=3 } })
  b:SetBackdropColor(0,0,0,0.5)
  b:EnableMouse(true); b:RegisterForDrag("LeftButton"); b:SetFrameStrata("DIALOG")
  local fs = b:CreateFontString(nil, "OVERLAY")
  fs:SetFont(GnerdHUDDB.profile.bars.font, 12, "OUTLINE")
  fs:SetPoint("CENTER", b, "CENTER", 0, 0)
  fs:SetText("Shards (drag)")
  b:SetScript("OnDragStart", function(self) self:StartMoving() end)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter(); local ux, uy = UIParent:GetCenter()
    local dx = math.floor(cx-ux+0.5); local dy = math.floor(cy-uy+0.5)
    local a = GnerdHUDDB.profile.modules.Shards.anchor
    a.x = dx; a.y = dy
    frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", a.x, a.y)
  end)
  mover = b
end

function M.SetLocked(self, lock)
  CreateMover()
  if lock then mover:Hide() else mover:Show() end
end

function M.OnEvent(self, event)
  Update(GetTime())
end

function M.Enable(self, cfg)
  Ensure()
  Update(GetTime())
end

function M.Disable(self)
  if frame then frame:Hide() end
  if mover then mover:Hide() end
end

GnerdHUD:RegisterModule(M.name, M)
