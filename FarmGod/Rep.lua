local _, ns = ...
local L = ns.L

-- Reputation: what each faction gave you in the session and in the day, an hour, and how far the
-- next standing is at that pace. Read from the factions themselves (how much you have with each)
-- rather than from the chat: Forever leaves some chat events out. A gain is the difference with
-- what was there before. After each loading screen the game fills the factions in over a few
-- moments (20 Nov 2026: a session counted 15 factions' whole standing as gains): nothing counts
-- until 5 seconds after it, when where each one stands is read again
local SETTLE = 5
local MAX_ID = 4000 -- faction ids looked up once: Forever's own may be past vanilla's
local BOGUS = 10000 -- more than this at once is the game loading the factions, not a gain
local known -- by faction id: how much you had last time
local seen -- the factions there are
local ready = false -- read since the last loading screen

local function Changed()
	if ns.Changed then ns.Changed() end
end

-- One faction: { id, name, value, reaction, low, high } (high == low: nothing past this standing)
function ns.FactionData(id)
	if C_Reputation and C_Reputation.GetFactionDataByID then
		local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
		if not ok or type(d) ~= "table" or type(d.name) ~= "string" or d.name == "" then return nil end
		if ns.IsSecret(d.currentStanding) or type(d.currentStanding) ~= "number" then return nil end
		if d.isHeader and not d.isHeaderWithRep then return nil end
		return { id = id, name = d.name, value = d.currentStanding, reaction = d.reaction,
			low = d.currentReactionThreshold, high = d.nextReactionThreshold }
	end
	if GetFactionInfoByID then
		local ok, name, _, standing, low, high, value, _, _, isHeader, _, hasRep = pcall(GetFactionInfoByID, id)
		if not ok or type(name) ~= "string" or name == "" or ns.IsSecret(value) or type(value) ~= "number" then return nil end
		if isHeader and not hasRep then return nil end
		return { id = id, name = name, value = value, reaction = standing, low = low, high = high }
	end
end

-- The standing's name, as the game writes it
function ns.StandingName(reaction)
	if not reaction then return "" end
	local label = GetText and GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex and UnitSex("player"))
	return label or _G["FACTION_STANDING_LABEL" .. reaction] or ""
end

function ns.StandingColour(reaction)
	local c = FACTION_BAR_COLORS and reaction and FACTION_BAR_COLORS[reaction]
	if c then return { c.r, c.g, c.b } end
	return { 0.35, 0.85, 0.4 }
end

local function Scan()
	seen, known = {}, {}
	for id = 1, MAX_ID do
		local d = ns.FactionData(id)
		if d then
			seen[id] = true
			known[id] = d.value
		end
	end
end

local function Add(where, id, delta, name)
	if not where then return end
	where.rep = where.rep or {}
	where.repNames = where.repNames or {}
	where.rep[id] = (where.rep[id] or 0) + delta
	where.repNames[id] = name
end

-- Where each one stands now: what changes from here on is a gain
local function Settled()
	Scan()
	ready = true
end
ns.SettleRep = Settled -- for the tests

function ns.CheckRep()
	if not ready then return end
	local any = false
	for id in pairs(seen) do
		local d = ns.FactionData(id)
		if d then
			local before = known[id]
			local delta = d.value - (before or d.value)
			known[id] = d.value
			-- From nothing to a lot at once: the game filling a faction in, not a gain
			local loading = abs(delta) > BOGUS or (before == 0 and abs(delta) > 250)
			if delta ~= 0 and not loading then
				any = true
				Add(ns.Day and ns.Day(), id, delta, d.name)
				local s = ns.char.current
				if s and s.state == "running" then Add(s, id, delta, d.name) end
			end
		end
	end
	if any then Changed() end
end

-- The factions of a session or a day, the most gained first: { id, name, delta, data }
function ns.RepList(where)
	local list = {}
	for id, delta in pairs(where and where.rep or {}) do
		if delta ~= 0 then
			list[#list + 1] = { id = id, name = (where.repNames and where.repNames[id]) or "?", delta = delta,
				data = ns.FactionData(id) }
		end
	end
	table.sort(list, function(a, b)
		if abs(a.delta) ~= abs(b.delta) then return abs(a.delta) > abs(b.delta) end
		return a.id < b.id
	end)
	return list
end

-- 1234 -> 1,234 (or as the game groups thousands)
function ns.Number(n)
	n = floor(n + 0.5)
	if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
	local digits = tostring(abs(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return (n < 0 and "-" or "") .. digits
end

function ns.Signed(n)
	return (n > 0 and "+" or "") .. ns.Number(n)
end

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_ENTERING_WORLD", "UPDATE_FACTION", "CHAT_MSG_COMBAT_FACTION_CHANGE")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		ready = false
		C_Timer.After(SETTLE, Settled)
	else
		ns.CheckRep()
	end
end)
