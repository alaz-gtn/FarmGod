local addonName, ns = ...
local L = ns.L

-- Settings: whatever is missing from the saved ones is filled in from here
local defaults = {
	session = {
		autoStart = true, -- looting or gathering with no session going starts one
		idleMinutes = 10, -- this long with nothing looted: paused, and that stretch doesn't count (0: never)
		bigLoot = 5, -- gold: loot worth this much or more is said in the chat (0: never)
	},
	prices = {
		source = "auto", -- auto (Auctionator, then TSM) | auctionator | tsm | vendor
		tsm = "DBMarket", -- the TSM price source
		best = true, -- the better of the auction price and what a vendor pays
		cut = false, -- take off the auction house's 5%
		vendorFallback = true, -- no auction price: what a vendor pays
	},
	categories = {}, -- by family: auction | vendor | skip (Items.lua fills in each one's default)
	goals = {
		announce = true, -- each step in the middle of the screen, as quests do
		bank = false, -- count what's in the bank too
	},
	-- Notes on players, for every character of the account: by lower-case name, { name, note,
	-- added, seen, zone, class }
	notes = {},
	noteAlerts = {
		enabled = true, -- a noted player seen: said in the chat
		center = true, -- and in the middle of the screen
		sound = true,
		minutes = 5, -- the same player isn't said again for this long
		near = true, -- the session window lists who was seen lately
		nearMinutes = 10,
	},
	tracker = {
		shown = true,
		onlyActive = false, -- hidden while there's no session
		locked = false, -- dragging the title bar moves it
		width = 250,
		scale = 100, -- %
		alpha = 80, -- the background, %
		rows = 8, -- families listed at most
		counts = true, -- nodes, fish, XP and skill-ups at the foot
		kills = true, -- the kills, small in the title bar
		rep = true, -- the reputation gained, under the families
		collapsed = false, -- just the time and the total
	},
	day = {
		gapHours = 3, -- a playing day ends after this long logged out
	},
	minimapButton = { hide = false, angle = 220 },
	positions = {},
}
ns.defaults = defaults

-- Per character: the session going on and the ones before
local charDefaults = {
	current = nil,
	history = {},
	goals = {}, -- { id, need, link }, in the order you set them
	day = nil, -- the playing day going on (Day.lua)
	days = {}, -- the ones before, the last first
}

local function Fill(saved, default)
	for k, v in pairs(default) do
		if saved[k] == nil then
			saved[k] = type(v) == "table" and Fill({}, v) or v
		elseif type(v) == "table" and type(saved[k]) == "table" then
			Fill(saved[k], v)
		end
	end
	return saved
end

function ns.Print(msg)
	print(L.PREFIX .. msg)
end

-- Events by name. One the client doesn't have (Forever leaves some out) makes RegisterEvent throw
-- an error, which would stop the rest of the file that asked for it: it's skipped instead and
-- noted for /farmgod events
ns.missingEvents = {}
function ns.Listen(frame, ...)
	for i = 1, select("#", ...) do
		local event = select(i, ...)
		if not pcall(frame.RegisterEvent, frame, event) then ns.missingEvents[event] = true end
	end
end

function ns.ListenUnit(frame, event, ...)
	if not pcall(frame.RegisterUnitEvent, frame, event, ...) then ns.missingEvents[event] = true end
end

-- Forever hides some values from addons during combat
function ns.IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

function ns.SpellName(id)
	if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
	return (GetSpellInfo(id))
end

-- Copper as the game writes it: 12g 34s 56c, with the coins' colours. Short leaves out what
-- doesn't matter at that size
local GOLD, SILVER, COPPER = "|cffffd100g|r", "|cffc7c7cfs|r", "|cffeda55fc|r"
function ns.Money(copper, short)
	copper = floor((copper or 0) + 0.5)
	local sign = copper < 0 and "-" or ""
	copper = abs(copper)
	local g, s, c = floor(copper / 10000), floor(copper / 100) % 100, copper % 100
	if g >= 1000 or (short and g >= 100) then
		local digits = tostring(g):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		return sign .. digits .. GOLD
	end
	local parts = {}
	if g > 0 then parts[#parts + 1] = g .. GOLD end
	if s > 0 then parts[#parts + 1] = s .. SILVER end
	if c > 0 and not (short and g > 0) then parts[#parts + 1] = c .. COPPER end
	if #parts == 0 then parts[1] = "0" .. COPPER end
	return sign .. table.concat(parts, " ")
end

-- Seconds as a clock: 4:05 or 1:02:03
function ns.Clock(seconds)
	seconds = max(floor(seconds or 0), 0)
	local h, m, s = floor(seconds / 3600), floor(seconds / 60) % 60, seconds % 60
	if h > 0 then return format("%d:%02d:%02d", h, m, s) end
	return format("%d:%02d", m, s)
end

-- The addon's round font for titles, over the game's in case it can't load
ns.FONTS = {
	fredoka = "Interface\\AddOns\\FarmGod\\media\\FredokaOne-Regular.ttf",
}
function ns.FancyFont(fontString, size, flags)
	fontString:SetFont(GameFontNormal:GetFont(), size, flags or "")
	fontString:SetFont(ns.FONTS.fredoka, size, flags or "")
end

-- The thin letters of the window: the game's narrow Arial, over its usual font in case it isn't
-- there
local THIN_FONT = "Fonts\\ARIALN.TTF"
function ns.ThinFont(fontString, size)
	fontString:SetFont(GameFontNormal:GetFont(), size, "")
	fontString:SetFont(THIN_FONT, size, "")
end

-- One pixel of the screen in a frame's own units: an edge one UI unit wide comes out blurry, or
-- not at all, depending on your UI scale
function ns.OnePixel(frame)
	if not (PixelUtil and PixelUtil.GetPixelToUIUnitFactor) then return 1 end
	local scale = frame:GetEffectiveScale()
	if ns.IsSecret(scale) or not scale or scale <= 0 then return 1 end
	return PixelUtil.GetPixelToUIUnitFactor() / scale
end

-- Each module adds the function that redraws it; the options call them all
ns.refreshers = {}
function ns.RefreshAll()
	for _, refresh in ipairs(ns.refreshers) do
		refresh()
	end
end

-- Displays the player can drag around while they are unlocked
ns.movers = {}
ns.unlocked = false

function ns.PlaceFrame(frame)
	local p = ns.db.positions[frame.moverKey]
	if not p and frame.placeDefault and frame:placeDefault() then return end
	p = p or frame.defaultPoint
	frame:ClearAllPoints()
	frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

function ns.SavePosition(frame)
	local point, _, relPoint, x, y = frame:GetPoint()
	if x and not ns.IsSecret(x) then
		ns.db.positions[frame.moverKey] = { point, relPoint, x, y }
	end
end

-- While unlocked each display gets a box on top of it, big enough to grab
local function SizeHandle(frame)
	local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
	if ns.IsSecret(w) or ns.IsSecret(h) then w, h = 0, 0 end
	frame.mover:SetSize(max(w + 16, 140), max(h + 16, 44))
end

function ns.Movable(frame, key, defaultPoint, label)
	frame.moverKey = key
	frame.defaultPoint = defaultPoint
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	local handle = CreateFrame("Frame", nil, frame)
	handle:SetPoint("CENTER")
	handle:SetFrameLevel(frame:GetFrameLevel() + 20)
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		if not InCombatLockdown() then frame:StartMoving() end
	end)
	handle:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		ns.SavePosition(frame)
	end)
	local box = handle:CreateTexture(nil, "BACKGROUND")
	box:SetAllPoints()
	box:SetColorTexture(0.95, 0.76, 0.31, 0.35)
	local name = handle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("CENTER")
	name:SetText(label)
	handle:Hide()
	frame.mover = handle
	ns.movers[key] = frame
	ns.PlaceFrame(frame)
end

function ns.SetUnlocked(on)
	if InCombatLockdown() then
		ns.Print(L.NOT_IN_COMBAT)
		return
	end
	ns.unlocked = on
	if not on then
		for _, frame in pairs(ns.movers) do ns.PlaceFrame(frame) end
	end
	ns.RefreshAll() -- while unlocked the displays show, so the boxes fit them
	for _, frame in pairs(ns.movers) do
		SizeHandle(frame)
		frame.mover:SetShown(on)
	end
	ns.Print(on and L.UNLOCKED or L.LOCKED)
end

-- Slash command words: each module adds its own
ns.commands = {}

local function Help()
	for _, line in ipairs(L.HELP) do
		print(line)
	end
end

ns.commands.unlock = function() ns.SetUnlocked(true) end
ns.commands.desbloquear = ns.commands.unlock
ns.commands.lock = function() ns.SetUnlocked(false) end
ns.commands.bloquear = ns.commands.lock
ns.commands.help = Help
ns.commands.ayuda = Help

-- Which events this client doesn't have
local function Events()
	local missing = {}
	for event in pairs(ns.missingEvents) do missing[#missing + 1] = event end
	table.sort(missing)
	ns.Print(#missing == 0 and L.EVENTS_ALL or format(L.EVENTS_MISSING, table.concat(missing, ", ")))
end
ns.commands.events = Events
ns.commands.eventos = Events

SLASH_FARMGOD1 = "/farmgod"
SLASH_FARMGOD2 = "/farmeo"
-- The first word is the command; the rest goes to it as you typed it (item links keep their case)
SlashCmdList.FARMGOD = function(msg)
	msg = strtrim(msg or "")
	if msg == "" then
		if ns.ToggleOptions then ns.ToggleOptions() end
		return
	end
	local word, rest = msg:match("^(%S+)%s*(.-)$")
	local command = ns.commands[strlower(word)]
	if command then
		command(rest, word)
	else
		Help()
	end
end

-- Settings saved by an older version: what changed since
local SETTINGS_VERSION = 3
function ns.MigrateSettings(db)
	local version = db.version or 1
	if version < 2 and db.categories.green == "auction" then
		-- 0.1.0 valued green gear at auction prices, which came out unrealistic: now at what a vendor pays
		db.categories.green = "vendor"
	end
	if version == 2 and db.categories.blue == "vendor" then
		-- version 2 moved the blues to vendor prices too, and they're better at auction prices
		db.categories.blue = "auction"
	end
	db.version = SETTINGS_VERSION
end

-- Per character
function ns.MigrateChar(char)
	if (char.version or 1) < 2 then
		-- The first reputation version counted the game filling the factions in as gains: start again
		local function Clear(t)
			if type(t) == "table" then t.rep, t.repNames = nil, nil end
		end
		Clear(char.current)
		Clear(char.day)
		for _, s in ipairs(char.history or {}) do Clear(s) end
		for _, d in ipairs(char.days or {}) do Clear(d) end
	end
	char.version = 2
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
	if name ~= addonName then return end
	FarmGodDB = Fill(FarmGodDB or {}, defaults)
	ns.MigrateSettings(FarmGodDB)
	FarmGodCharDB = Fill(FarmGodCharDB or {}, charDefaults)
	ns.MigrateChar(FarmGodCharDB)
	ns.db = FarmGodDB
	ns.char = FarmGodCharDB
	self:UnregisterEvent("ADDON_LOADED")
end)
