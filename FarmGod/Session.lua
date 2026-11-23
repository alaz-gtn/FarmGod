local _, ns = ...
local L = ns.L

-- A farming session: what you loot and gather while it runs, its time without the pauses.
-- Kept per character, so a /reload or a logout doesn't lose it; the time you're logged out
-- doesn't count
local HISTORY_SIZE = 30
local runningSince -- GetTime() when it last started running
local lastActivity -- GetTime() of the last loot or gather

local function Now() return GetTime() end

local function Current() return ns.char and ns.char.current end

local function NewSession()
	return {
		started = time(),
		zone = GetRealZoneText and GetRealZoneText() or "",
		elapsed = 0, -- seconds counted before it last started running
		state = "running", -- running | paused
		pause = nil, -- manual | idle
		money = 0, -- copper looted
		items = {}, -- by item: how many
		links = {}, -- by item: one of its links, for the name and colour
		quality = {},
		gathers = {}, -- mining | herb | skin | fish | pick: how many
		mobs = 0, -- mobs looted
		kills = 0, -- killing blows of yours or your group's
		xp = 0,
		skills = {}, -- by name: { from, to }
	}
end

-- idle | running | paused
function ns.SessionState()
	local s = Current()
	if not s then return "idle" end
	return s.state
end

function ns.Elapsed(s)
	s = s or Current()
	if not s then return 0 end
	-- Running with no start time (the login didn't reach it): from now, rather than a frozen clock
	if s.state == "running" and s == Current() and not runningSince then runningSince = Now() end
	if s.state == "running" and s == Current() and runningSince then
		return s.elapsed + max(Now() - runningSince, 0)
	end
	return s.elapsed
end

-- Everything a session is worth with today's prices: the total, the looted gold and each family
-- with its items, the most valuable first
function ns.Appraise(s)
	s = s or Current()
	local families, total = {}, 0
	if not s then return { total = 0, money = 0, families = {} } end
	for itemID, count in pairs(s.items) do
		local link = s.links[itemID]
		local quality = s.quality[itemID] or ns.ItemQuality(itemID, link)
		local key = ns.Classify(itemID, quality)
		local each, source = ns.ItemValue(itemID, key)
		local family = families[key]
		if not family then
			family = { key = key, value = 0, count = 0, items = {}, skip = source == "skip" }
			families[key] = family
		end
		local value = each * count
		family.value = family.value + value
		family.count = family.count + count
		table.insert(family.items, { id = itemID, link = link, count = count, each = each, value = value, source = source })
		total = total + value
	end
	local list = {}
	for _, family in pairs(families) do
		table.sort(family.items, function(a, b)
			if a.value ~= b.value then return a.value > b.value end
			return a.id < b.id
		end)
		list[#list + 1] = family
	end
	local order = {}
	for i, key in ipairs(ns.CATEGORY_ORDER) do order[key] = i end
	table.sort(list, function(a, b)
		if a.skip ~= b.skip then return b.skip end
		if a.value ~= b.value then return a.value > b.value end
		return order[a.key] < order[b.key]
	end)
	return { total = total + s.money, money = s.money, items = total, families = list }
end

-- Copper an hour, once there's a minute to go by
function ns.PerHour(value, seconds)
	if not seconds or seconds < 60 then return nil end
	return value * 3600 / seconds
end

local function Changed()
	if ns.Changed then ns.Changed() end
end

function ns.StartSession()
	local s = Current()
	if s and s.state == "running" then return end
	if not s then
		ns.char.current = NewSession()
		ns.Print(L.STARTED)
	else
		s.state, s.pause = "running", nil
		ns.Print(L.RESUMED)
	end
	runningSince, lastActivity = Now(), Now()
	Changed()
end

-- The time it has run goes into its count; an idle pause leaves out the stretch with nothing
-- looted
function ns.PauseSession(reason)
	local s = Current()
	if not s or s.state ~= "running" then return end
	local upTo = Now()
	if reason == "idle" and lastActivity then upTo = lastActivity end
	s.elapsed = s.elapsed + max(upTo - (runningSince or upTo), 0)
	s.state, s.pause = "paused", reason or "manual"
	runningSince = nil
	ns.Print(reason == "idle" and format(L.IDLE_PAUSED, ns.db.session.idleMinutes) or L.PAUSED)
	Changed()
end

function ns.ToggleSession()
	if ns.SessionState() == "running" then ns.PauseSession("manual") else ns.StartSession() end
end

local function HasSomething(s)
	return s.money > 0 or next(s.items) ~= nil or s.mobs > 0 or next(s.gathers) ~= nil or s.xp > 0
		or (s.kills or 0) > 0 or (s.rep ~= nil and next(s.rep) ~= nil)
end

-- Ended: it goes to the history (if anything happened in it) and nothing runs until you start
-- another one or loot something
function ns.EndSession()
	local s = Current()
	if not s then return end
	if s.state == "running" then
		s.elapsed = ns.Elapsed(s)
	end
	s.state, s.pause = "paused", nil
	s.ended = time()
	runningSince = nil
	ns.char.current = nil
	if HasSomething(s) then
		table.insert(ns.char.history, 1, s)
		while #ns.char.history > HISTORY_SIZE do table.remove(ns.char.history) end
		local worth = ns.Appraise(s)
		ns.Print(format(L.ENDED, ns.Clock(s.elapsed), ns.Money(worth.total)))
	else
		ns.Print(L.ENDED_EMPTY)
	end
	Changed()
end

-- Back to zero, still running
function ns.ResetSession()
	if not Current() then return end
	ns.char.current = NewSession()
	runningSince, lastActivity = Now(), Now()
	ns.Print(L.RESET_DONE)
	Changed()
end

function ns.ClearHistory()
	wipe(ns.char.history)
	Changed()
end

-- Something was looted or gathered: does it count? With no session it starts one (if you want);
-- after an idle pause it carries on, after one of yours it doesn't
local function Counting()
	local s = Current()
	if not s then
		if not ns.db.session.autoStart then return false end
		ns.StartSession()
		return true
	end
	if s.state == "paused" then
		if s.pause ~= "idle" then return false end
		ns.StartSession()
	end
	lastActivity = Now()
	return true
end

function ns.CheckIdle()
	if not ns.db.session.idlePause then return end
	local minutes = ns.db.session.idleMinutes
	if minutes <= 0 or ns.SessionState() ~= "running" or not lastActivity then return end
	if Now() - lastActivity >= minutes * 60 then ns.PauseSession("idle") end
end

function ns.AddLoot(itemID, count, link)
	if ns.DayLoot then ns.DayLoot(itemID, count, link) end -- the day counts it, session or not
	if not Counting() then return end
	local s = Current()
	s.items[itemID] = (s.items[itemID] or 0) + count
	if link then s.links[itemID] = link end
	if not s.quality[itemID] then s.quality[itemID] = ns.ItemQuality(itemID, link) end
	-- Something worth telling
	local bigLoot = ns.db.session.bigLoot
	if bigLoot > 0 then
		local key = ns.Classify(itemID, s.quality[itemID])
		local each = ns.ItemValue(itemID, key)
		if each * count >= bigLoot * 10000 then
			ns.Print(format(L.BIG_LOOT, link or ns.ItemName(itemID), count, ns.Money(each * count)))
		end
	end
	Changed()
end

function ns.AddMoney(copper)
	if copper <= 0 or not Counting() then return end
	local s = Current()
	s.money = s.money + copper
	Changed()
end

function ns.AddGather(kind)
	if ns.DayCount then ns.DayCount("gathers", kind) end
	if not Counting() then return end
	local s = Current()
	s.gathers[kind] = (s.gathers[kind] or 0) + 1
	Changed()
end

function ns.AddMob()
	if ns.DayCount then ns.DayCount("mobs") end
	if not Counting() then return end
	local s = Current()
	s.mobs = s.mobs + 1
	Changed()
end

function ns.AddKill()
	if ns.DayCount then ns.DayCount("kills") end
	if not Counting() then return end
	local s = Current()
	s.kills = (s.kills or 0) + 1
	Changed()
end

-- The kills to show: a mob you looted was killed too, in case the game didn't say
function ns.Kills(s)
	s = s or Current()
	if not s then return 0 end
	return max(s.kills or 0, s.mobs or 0)
end

-- Forever closes the combat log, but tells a kill up to three ways: its PARTY_KILL event, "You have
-- slain X!" and "X dies, you gain N experience." Reports from different ways within a moment are
-- the same kill; two of the same way are two kills
local KILL_MERGE = 1.5
local killReports = {} -- { at, ways = { party = true, ... } }
local function KillReport(way)
	local now = Now()
	for i = #killReports, 1, -1 do
		if now - killReports[i].at > KILL_MERGE then table.remove(killReports, i) end
	end
	for _, report in ipairs(killReports) do
		if not report.ways[way] then
			report.ways[way] = true
			return
		end
	end
	table.insert(killReports, { at = now, ways = { [way] = true } })
	ns.AddKill()
end
ns.KillReport = KillReport

-- Chat lines: the game's own sentences turned into patterns, so any language works

-- %s an item link or a name, %d a number
local function Pattern(sentence, anchored)
	if type(sentence) ~= "string" then return nil end
	local p = sentence:gsub("%%%d*%$?s", "\001"):gsub("%%%d*%$?d", "\002")
	p = p:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	p = p:gsub("\001", "(.+)"):gsub("\002", "(%%d+)")
	return anchored and "^" .. p .. "$" or p
end

local SLAIN = Pattern(SELFKILLOTHER, true)
-- "X dies, you gain N experience." with whatever bonus comes after
local XP_KILL = COMBATLOG_XPGAIN_FIRSTPERSON and Pattern((COMBATLOG_XPGAIN_FIRSTPERSON:gsub("%.$", "")))
XP_KILL = XP_KILL and "^" .. XP_KILL
local LOOT_MULTIPLE = Pattern(LOOT_ITEM_SELF_MULTIPLE, true)
local LOOT_SINGLE = Pattern(LOOT_ITEM_SELF, true)
local SKILL_UP = Pattern(SKILL_RANK_UP, true)
-- The coins in "You loot 1 Gold, 2 Silver, 3 Copper", or with the coin pictures
local COINS = {}
for _, coin in ipairs({ { GOLD_AMOUNT, 10000, "Gold" }, { SILVER_AMOUNT, 100, "Silver" }, { COPPER_AMOUNT, 1, "Copper" } }) do
	local words = Pattern(coin[1])
	if words then table.insert(COINS, { words, coin[2] }) end
	table.insert(COINS, { "(%d+)|TInterface\\MoneyFrame\\UI%-" .. coin[3] .. "Icon", coin[2] })
end

function ns.ParseLoot(text)
	if type(text) ~= "string" or ns.IsSecret(text) then return end
	local link, count
	if LOOT_MULTIPLE then link, count = text:match(LOOT_MULTIPLE) end
	if not link and LOOT_SINGLE then link = text:match(LOOT_SINGLE) end
	if not link then return end
	local itemID = tonumber(link:match("item:(%d+)"))
	if not itemID then return end
	return itemID, tonumber(count) or 1, link
end

function ns.ParseMoney(text)
	if type(text) ~= "string" or ns.IsSecret(text) then return 0 end
	text = text:match("^[^%(]*") -- what's in brackets went to the guild bank
	local total, seen = 0, {}
	for _, coin in ipairs(COINS) do
		local n = text:match(coin[1])
		if n and not seen[coin[2]] then
			seen[coin[2]] = true
			total = total + tonumber(n) * coin[2]
		end
	end
	return total
end

-- Gathering: the casts by name, as Forever has several ids for each
local GATHER_SPELLS = { mining = 2575, herb = 2366, skin = 8613, pick = 921 }
local gatherNames
local function GatherKind(spellID)
	if not gatherNames then
		gatherNames = {}
		for kind, id in pairs(GATHER_SPELLS) do
			local name = ns.SpellName(id)
			if name then gatherNames[name] = kind end
		end
	end
	return gatherNames[ns.SpellName(spellID) or ""]
end
local lastGather = 0 -- GetTime() of the last gathering cast: the loot after it isn't a mob
local recentMobs = {} -- mobs looted lately, so opening one again doesn't count twice

local function LootSourceGUID()
	if not GetLootSourceInfo then return end
	local guid = GetLootSourceInfo(1)
	if type(guid) == "string" and not ns.IsSecret(guid) then return guid end
end

local function LootOpened(isFromItem)
	if IsFishingLoot and IsFishingLoot() then
		ns.AddGather("fish")
		return
	end
	if isFromItem or Now() - lastGather < 3 then return end
	local guid = LootSourceGUID()
	if guid then
		if not (guid:match("^Creature") or guid:match("^Vehicle")) or recentMobs[guid] then return end
		recentMobs[guid] = true
		table.insert(recentMobs, guid)
		if #recentMobs > 50 then recentMobs[table.remove(recentMobs, 1)] = nil end
	end
	ns.AddMob()
end

-- XP and the level you were at, to count what you gain across a level up
local xp, xpMax, level
local function ReadXP()
	local cur, top, lvl = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
	if ns.IsSecret(cur) or ns.IsSecret(top) then return end
	local gained = 0
	if xp then
		if lvl == level and cur >= xp then
			gained = cur - xp
		else -- a level up, even if the game hasn't said the new level yet
			gained = max(xpMax - xp, 0) + cur
		end
	end
	xp, xpMax, level = cur, top, lvl
	return gained
end

local function SkillUp(text)
	if not SKILL_UP or type(text) ~= "string" or ns.IsSecret(text) then return end
	local name, rank = text:match(SKILL_UP)
	rank = tonumber(rank)
	if not rank then return end
	local s = Current()
	if not s or s.state ~= "running" then return end
	local skill = s.skills[name]
	if not skill then
		s.skills[name] = { from = rank - 1, to = rank }
	else
		skill.to = rank
	end
	Changed()
end

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_LOGIN")
ns.Listen(events, "PLAYER_LOGOUT")
ns.Listen(events, "CHAT_MSG_LOOT")
ns.Listen(events, "CHAT_MSG_MONEY")
ns.Listen(events, "CHAT_MSG_SKILL")
ns.Listen(events, "LOOT_OPENED")
ns.Listen(events, "PLAYER_XP_UPDATE")
ns.ListenUnit(events, "UNIT_SPELLCAST_SUCCEEDED", "player")
ns.Listen(events, "CHAT_MSG_COMBAT_HOSTILE_DEATH")
ns.Listen(events, "CHAT_MSG_COMBAT_XP_GAIN")
-- Forever's own kill event; the Classic clients don't have it
ns.Listen(events, "PARTY_KILL")
local function ChatLine(text, pattern)
	return pattern and type(text) == "string" and not ns.IsSecret(text) and text:match(pattern) ~= nil
end
events:SetScript("OnEvent", function(_, event, ...)
	if event == "PARTY_KILL" then
		KillReport("party") -- who died may be hidden (in dungeons it is): that a kill happened is enough
	elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
		if ChatLine((...), SLAIN) then KillReport("slain") end
	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		if ChatLine((...), XP_KILL) then KillReport("xp") end
	elseif event == "CHAT_MSG_LOOT" then
		local itemID, count, link = ns.ParseLoot((...))
		if itemID then ns.AddLoot(itemID, count, link) end
	elseif event == "CHAT_MSG_MONEY" then
		ns.AddMoney(ns.ParseMoney((...)))
	elseif event == "LOOT_OPENED" then
		LootOpened(select(2, ...))
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spellID = ...
		if unit ~= "player" or ns.IsSecret(spellID) or not spellID then return end
		local kind = GatherKind(spellID)
		if kind then
			lastGather = Now()
			ns.AddGather(kind)
		end
	elseif event == "PLAYER_XP_UPDATE" then
		local gained = ReadXP()
		if ns.DayXP then ns.DayXP(gained) end
		local s = Current()
		if gained and gained > 0 and s and s.state == "running" then
			s.xp = s.xp + gained
			Changed()
		end
	elseif event == "CHAT_MSG_SKILL" then
		SkillUp((...))
	elseif event == "PLAYER_LOGIN" then
		ReadXP()
		local s = Current()
		if s and s.state == "running" then
			runningSince, lastActivity = Now(), Now()
		end
		C_Timer.NewTicker(5, ns.CheckIdle)
		Changed()
	elseif event == "PLAYER_LOGOUT" then
		-- The time it ran goes into its count; logged out it doesn't run
		local s = Current()
		if s and s.state == "running" then
			s.elapsed = ns.Elapsed(s)
			runningSince = nil
		end
	end
end)

local function Report()
	local s = Current()
	if not s then
		ns.Print(L.NO_SESSION)
		return
	end
	local worth = ns.Appraise(s)
	local seconds = ns.Elapsed(s)
	local hour = ns.PerHour(worth.total, seconds)
	ns.Print(format(L.REPORT, ns.Clock(seconds), ns.Money(worth.total), hour and ns.Money(hour, true) or "-", ns.Kills(s)))
end
ns.Report = Report

local function History()
	local history = ns.char.history
	if #history == 0 then
		ns.Print(L.HISTORY_EMPTY)
		return
	end
	ns.Print(L.HISTORY_TITLE)
	for i = 1, min(#history, 5) do
		local s = history[i]
		local worth = ns.Appraise(s)
		local hour = ns.PerHour(worth.total, s.elapsed)
		print(format(L.HISTORY_LINE, date("%d/%m %H:%M", s.started), s.zone ~= "" and s.zone or "?", ns.Clock(s.elapsed),
			ns.Money(worth.total), hour and ns.Money(hour, true) or "-"))
	end
end

ns.commands.start = function() ns.StartSession() end
ns.commands.empezar = ns.commands.start
ns.commands.pause = function() ns.PauseSession("manual") end
ns.commands.pausa = ns.commands.pause
ns.commands.stop = function() ns.EndSession() end
ns.commands.terminar = ns.commands.stop
ns.commands.reset = function() ns.ResetSession() end
ns.commands.reiniciar = ns.commands.reset
ns.commands.report = Report
ns.commands.informe = Report
ns.commands.history = History
ns.commands.historial = History
