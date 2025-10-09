-- GnerdHUD/modules/AbsorbDB.lua
-- UTF-8, UNIX LF
-- Bridge for importing absorb effect definitions and wiring them to GH.Absorb.effects.

local GH = GnerdHUD
local L = GnerdHUD_L
local M = { name = "AbsorbDB" }

M.db = {
  ["Power Word: Shield"] = { schools = { "physical" }, amount = 500, source = "buff" },
  ["Mana Shield"] = { schools = { "physical" }, amount = 600, source = "buff" },
  ["Fire Ward"] = { schools = { "fire" }, amount = 400, source = "buff" },
  ["Frost Ward"] = { schools = { "frost" }, amount = 400, source = "buff" },
}

local function ApplyDB()
  local k,v
  for k,v in pairs(M.db) do
    GH.Absorb.effects[k] = { schools = v.schools, amount = v.amount, source = v.source }
  end
  GH.Absorb:RebuildFromAuras()
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r AbsorbDB applied ("..(table.getn and table.getn(M.db) or 0).." entries)")
end

local function split(line, sep)
  local out = {}
  local pos = 1
  while true do
    local b,e = string.find(line, sep, pos, true)
    if not b then
      table.insert(out, string.sub(line, pos))
      break
    end
    table.insert(out, string.sub(line, pos, b-1))
    pos = e + 1
  end
  return out
end
local function parseSchools(s)
  local list = {}
  local parts = split(s, "|")
  local i
  for i=1, table.getn(parts) do
    local v = parts[i]
    while string.find(v, "^%s") do v = string.sub(v, 2) end
    while string.find(v, "%s$") do v = string.sub(v, 1, string.len(v)-1) end
    if v ~= "" then table.insert(list, string.lower(v)) end
  end
  if table.getn(list) == 0 then list = { "physical" } end
  return list
end

function M.ImportFile(self, filename)
  if not GH.features.hasFileIO or type(ImportFile) ~= "function" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r Import not available (SuperWoW required).")
    return
  end
  if not filename or filename == "" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r Usage: /ghud absorb import <file>")
    return
  end
  local ok, data = pcall(ImportFile, filename)
  if not ok or not data or data == "" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r Import failed: "..(data or "nil"))
    return
  end
  local count = 0
  local sep = ";"
  if string.find(data, ",", 1, true) and not string.find(data, ";", 1, true) then sep = "," end
  local start = 1
  while true do
    local nl = string.find(data, "\n", start, true)
    local line
    if nl then
      line = string.sub(data, start, nl - 1)
      start = nl + 1
    else
      line = string.sub(data, start)
      start = nil
    end
    if string.sub(line, -1) == "\r" then line = string.sub(line, 1, string.len(line)-1) end
    local trimmed = line
    while string.find(trimmed, "^%s") do trimmed = string.sub(trimmed, 2) end
    if trimmed ~= "" and string.sub(trimmed,1,1) ~= "#" then
      local cols = split(trimmed, sep)
      if table.getn(cols) >= 3 then
        local key = cols[1]
        local amount = tonumber(cols[2]) or 0
        local schools = parseSchools(cols[3])
        if key and key ~= "" then
          M.db[key] = { schools = schools, amount = amount, source = "buff" }
          count = count + 1
        end
      end
    end
    if not start then break end
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cff88ccffGnerdHUD|r Imported "..count.." absorb rows from "..filename)
  ApplyDB()
end

function M.Enable(self, cfg)
  ApplyDB()
end

function M.Disable(self)
end

GnerdHUD:RegisterModule(M.name, M)
