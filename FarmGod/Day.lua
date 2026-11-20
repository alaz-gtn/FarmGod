local _, ns = ...
local L = ns.L

-- The playing day: everything from when you sit down to play until you've been away a few hours,
-- sessions or not. Your real gold (what you have now against what you had), where it came from
-- and where it went, what you looted with today's prices, kills, nodes, quests and XP. Per
-- character; the last ones are kept
local DAYS_KEPT = 20
local GRACE = 2 -- seconds: the gold that comes just after a window closes is still that window's
local loginAt -- GetTime() of the login, for the time played
local lastMoney -- what you had at the last change

-- Where gold comes from and goes, in the order they're listed
ns.MONEY_KINDS = { "loot", "quest", "vendor", "mail", "auction", "trade", "trainer", "taxi", "other" }

local function Now() return GetTime() end

local function Changed()
	if ns.Changed then ns.Changed() end
end

local function Money()
	local m = GetMoney and GetMoney()
	if type(m) ~= "number" or ns.IsSecret(m) then return nil end
	return m
end

local function NewDay()
	local money = {}
	for _, kind in ipairs(ns.MONEY_KINDS) do money[kind] = { inc = 0, out = 0 } end
	return {
		started = time(),
		lastSeen = time(),
		played = 0, -- seconds logged in before this login
		moneyStart = Money() or 0,
		money = money,
		items = {}, links = {}, quality = {},
		kills = 0, mobs = 0, gathers = {}, xp = 0, quests = 0,
		zones = {}, -- where you played, by name: how many times you got there
	}
end

function ns.Day()
	return ns.char and ns.char.day
end

function ns.DayPlayed(day)
	day = day or ns.Day()
	if not day then return 0 end
	if day == ns.Day() and loginAt then return day.played + max(Now() - loginAt, 0) end
	return day.played
end

local function HasSomething(day)
	if day.played >= 60 then return true end
	for _, m in pairs(day.money) do
		if m.inc > 0 or m.out > 0 then return true end
	end
	return next(day.items) ~= nil or day.kills > 0
end

-- The day so far goes to the list of past ones and a new one starts now
function ns.NewDay()
	local day = ns.Day()
	if day then
		day.played = ns.DayPlayed(day)
		day.ended = day.lastSeen
		day.moneyEnd = lastMoney or Money() or day.moneyStart
		if HasSomething(day) then
			table.insert(ns.char.days, 1, day)
			while #ns.char.days > DAYS_KEPT do table.remove(ns.char.days) end
		end
	end
	ns.char.day = NewDay()
	loginAt = Now()
	lastMoney = Money()
	Changed()
end

-- The gold you have now against what you had when the day started
function ns.DayNet(day)
	day = day or ns.Day()
	if not day then return 0 end
	local now = day.moneyEnd or (day == ns.Day() and (Money() or lastMoney)) or day.moneyStart
	return now - day.moneyStart
end

-- What you looted, at today's prices
function ns.DayLootWorth(day)
	day = day or ns.Day()
	if not day then return { total = 0, money = 0, items = 0, families = {} } end
	return ns.Appraise({ items = day.items, links = day.links, quality = day.quality, money = 0 })
end

-- Everything else the sessions count happens on the day too, session or not
function ns.DayLoot(itemID, count, link)
	local day = ns.Day()
	if not day then return end
	day.items[itemID] = (day.items[itemID] or 0) + count
	if link then day.links[itemID] = link end
	if not day.quality[itemID] then day.quality[itemID] = ns.ItemQuality(itemID, link) end
end

function ns.DayCount(what, kind)
	local day = ns.Day()
	if not day then return end
	if kind then
		day[what][kind] = (day[what][kind] or 0) + 1
	else
		day[what] = (day[what] or 0) + 1
	end
end

function ns.DayXP(gained)
	local day = ns.Day()
	if day and gained and gained > 0 then day.xp = day.xp + gained end
end

-- Which window the gold moved in: what's open, or what closed a moment ago
local open, closedAt = {}, {}
local WINDOWS = { "loot", "quest", "vendor", "mail", "auction", "trade", "trainer", "taxi" }
local function Context()
	-- A window open now, before one that closed a moment ago
	for _, what in ipairs(WINDOWS) do
		if open[what] then return what end
	end
	local latest, at
	for _, what in ipairs(WINDOWS) do
		local t = closedAt[what]
		if t and Now() - t <= GRACE and (not at or t > at) then latest, at = what, t end
	end
	return latest or "other"
end

local function Open(what, on)
	open[what] = on or nil
	if not on then closedAt[what] = Now() end
end
ns.DayWindow = Open -- for the tests

local function MoneyChanged()
	local day, money = ns.Day(), Money()
	if not day or not money then return end
	local delta = money - (lastMoney or money)
	lastMoney = money
	if delta == 0 then return end
	local entry = day.money[Context()]
	if delta > 0 then entry.inc = entry.inc + delta else entry.out = entry.out - delta end
	Changed()
end

-- The game's windows by the old events and by Midnight's interaction manager
local WINDOW_EVENTS = {
	MERCHANT_SHOW = { "vendor", true }, MERCHANT_CLOSED = { "vendor", false },
	MAIL_SHOW = { "mail", true }, MAIL_CLOSED = { "mail", false },
	AUCTION_HOUSE_SHOW = { "auction", true }, AUCTION_HOUSE_CLOSED = { "auction", false },
	TRADE_SHOW = { "trade", true }, TRADE_CLOSED = { "trade", false },
	TRAINER_SHOW = { "trainer", true }, TRAINER_CLOSED = { "trainer", false },
	TAXIMAP_OPENED = { "taxi", true }, TAXIMAP_CLOSED = { "taxi", false },
	LOOT_OPENED = { "loot", true }, LOOT_CLOSED = { "loot", false },
	QUEST_COMPLETE = { "quest", true }, QUEST_FINISHED = { "quest", false },
}
local INTERACTIONS = { Merchant = "vendor", MailInfo = "mail", Auctioneer = "auction", TradePartner = "trade",
	Trainer = "trainer", TaxiNode = "taxi" }
local interactionKinds
local function InteractionKind(kind)
	if not interactionKinds then
		interactionKinds = {}
		local enum = Enum and Enum.PlayerInteractionType
		if enum then
			for name, what in pairs(INTERACTIONS) do
				if enum[name] then interactionKinds[enum[name]] = what end
			end
		end
	end
	return interactionKinds[kind]
end

local events = CreateFrame("Frame")
for event in pairs(WINDOW_EVENTS) do ns.Listen(events, event) end
for _, event in ipairs({ "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
	ns.Listen(events, event)
end
ns.Listen(events, "PLAYER_LOGIN")
ns.Listen(events, "PLAYER_LOGOUT")
ns.Listen(events, "PLAYER_MONEY")
ns.Listen(events, "CHAT_MSG_MONEY")
ns.Listen(events, "QUEST_TURNED_IN")
ns.Listen(events, "ZONE_CHANGED_NEW_AREA")

local function NoteZone()
	local day = ns.Day()
	local zone = GetRealZoneText and GetRealZoneText()
	if day and type(zone) == "string" and zone ~= "" and not ns.IsSecret(zone) then
		day.zones[zone] = (day.zones[zone] or 0) + 1
	end
end

events:SetScript("OnEvent", function(_, event, ...)
	local window = WINDOW_EVENTS[event]
	if window then
		Open(window[1], window[2])
	elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
		local what = InteractionKind((...))
		if what then Open(what, event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW") end
	elseif event == "PLAYER_MONEY" then
		MoneyChanged()
	elseif event == "CHAT_MSG_MONEY" then
		-- your share of a group's gold can come with no loot window of yours
		closedAt.loot = Now()
	elseif event == "QUEST_TURNED_IN" then
		closedAt.quest = Now()
		ns.DayCount("quests")
		Changed()
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		NoteZone()
	elseif event == "PLAYER_LOGIN" then
		-- A day ends after a few hours away
		local day = ns.Day()
		if not day or time() - (day.lastSeen or 0) > ns.db.day.gapHours * 3600 then
			lastMoney = day and day.lastMoney
			ns.NewDay()
		else
			loginAt = Now()
			-- Gold that moved while the addon wasn't looking
			local money = Money()
			if money and day.lastMoney and money ~= day.lastMoney then
				local entry = day.money.other
				if money > day.lastMoney then entry.inc = entry.inc + money - day.lastMoney
				else entry.out = entry.out + day.lastMoney - money end
			end
			lastMoney = money
		end
		NoteZone()
		-- In case the game closes without a logout
		C_Timer.NewTicker(60, function()
			local d = ns.Day()
			if d then
				d.lastSeen = time()
				d.lastMoney = lastMoney
			end
		end)
	elseif event == "PLAYER_LOGOUT" then
		local day = ns.Day()
		if day then
			day.played = ns.DayPlayed(day)
			loginAt = Now()
			day.lastSeen = time()
			day.lastMoney = lastMoney
		end
	end
end)

-- In the chat: the day in one line
local function Report()
	local day = ns.Day()
	if not day then return end
	local played = ns.DayPlayed(day)
	local net = ns.DayNet(day)
	local hour = ns.PerHour(net, played)
	ns.Print(format(L.DAY_REPORT, ns.Clock(played), (net >= 0 and "+" or "") .. ns.Money(net),
		hour and ns.Money(hour, true) or "-", ns.Money(ns.DayLootWorth(day).total), max(day.kills, day.mobs), day.quests))
end
ns.DayReport = Report
ns.commands.day = Report
ns.commands.today = Report
ns.commands.summary = Report
ns.commands.jornada = Report
ns.commands.hoy = Report
ns.commands.resumen = Report
