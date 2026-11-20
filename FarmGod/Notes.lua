local _, ns = ...
local L = ns.L

-- Notes on players ("Farmer"), to know who is farming your layer. A noted player you see (their
-- nameplate, your target or the mouse over them) is on your layer: it says so in the chat, in the
-- middle of the screen and with a sound, and the session window lists them for a while. A layer
-- change empties that list. Forever names are "First Surname" with no realm (LayerSwap measured it:
-- UnitName gives the two parts apart for anyone but you). In combat Forever may hide names: then
-- nothing is read
local recent = {} -- by key: GetTime() last seen on this layer
local alerted = {} -- by key: GetTime() of the last alert

local function Changed()
	if ns.Changed then ns.Changed() end
end

local function Separator()
	local c = Constants and Constants.CharacterNameSeparatorConsts
	local sep = c and c.CHARACTERNAME_SURNAME_SEPARATOR
	if type(sep) == "string" and sep ~= "" then return sep end
	return " "
end

local function Key(name)
	return strlower(strtrim(name or ""))
end

-- A unit's whole name, or nil if the game hides it
function ns.UnitFullName(unit)
	local ok, first, surname = pcall(UnitName, unit)
	if not ok or ns.IsSecret(first) or type(first) ~= "string" or first == "" then return nil end
	if not ns.IsSecret(surname) and type(surname) == "string" and surname ~= "" then
		return first .. Separator() .. surname
	end
	return first
end

local function IsOtherPlayer(unit)
	local ok, player = pcall(UnitIsPlayer, unit)
	if not ok or ns.IsSecret(player) or not player then return false end
	local okSelf, self = pcall(UnitIsUnit, unit, "player")
	return not (okSelf and not ns.IsSecret(self) and self)
end
ns.IsOtherPlayer = IsOtherPlayer

function ns.Note(name)
	return name and ns.db.notes[Key(name)]
end

-- A note on a player; empty takes it off
function ns.SetNote(name, text)
	name = strtrim(name or "")
	if name == "" then return false end
	text = strtrim(text or "")
	local key = Key(name)
	if text == "" then
		local had = ns.db.notes[key] ~= nil
		ns.db.notes[key] = nil
		recent[key], alerted[key] = nil, nil
		Changed()
		return had
	end
	local entry = ns.db.notes[key] or { added = time() }
	entry.name = name
	entry.note = text
	ns.db.notes[key] = entry
	Changed()
	return true
end

function ns.ClassColoured(entry)
	local colour = entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
	if colour and colour.colorStr then return "|c" .. colour.colorStr .. entry.name .. "|r" end
	return entry.name
end

-- How long ago, in a few letters
function ns.Ago(seconds)
	seconds = max(seconds or 0, 0)
	if seconds < 60 then return L.AGO_NOW end
	if seconds < 3600 then return format(L.AGO_MIN, floor(seconds / 60)) end
	if seconds < 86400 then return format(L.AGO_HOUR, floor(seconds / 3600)) end
	return format(L.AGO_DAY, floor(seconds / 86400))
end

-- The noted players seen on this layer lately, the last first: { entry, ago }
function ns.NearbyNoted()
	local list, now = {}, GetTime()
	local window = ns.db.noteAlerts.nearMinutes * 60
	for key, at in pairs(recent) do
		local entry = ns.db.notes[key]
		if entry and now - at <= window then list[#list + 1] = { entry = entry, ago = now - at } end
	end
	table.sort(list, function(a, b)
		if a.ago ~= b.ago then return a.ago < b.ago end
		return a.entry.name < b.entry.name
	end)
	return list
end

function ns.SeenUnit(unit)
	if not IsOtherPlayer(unit) then return end
	local name = ns.UnitFullName(unit)
	local key = name and Key(name)
	local entry = key and ns.db.notes[key]
	if not entry then return end
	local now = GetTime()
	entry.name = name -- as the game writes it
	entry.seen = time()
	entry.zone = GetRealZoneText and GetRealZoneText() or entry.zone
	local okClass, _, class = pcall(UnitClass, unit)
	if okClass and type(class) == "string" and not ns.IsSecret(class) then entry.class = class end
	recent[key] = now
	local alerts = ns.db.noteAlerts
	if alerts.enabled and (not alerted[key] or now - alerted[key] >= alerts.minutes * 60) then
		alerted[key] = now
		ns.Print(format(L.NOTE_SEEN, ns.ClassColoured(entry), entry.note, entry.zone or "?"))
		if alerts.center and UIErrorsFrame then
			UIErrorsFrame:AddMessage(format(L.NOTE_SEEN_CENTER, entry.name, entry.note), 1, 0.55, 0.15)
		end
		if alerts.sound and SOUNDKIT and SOUNDKIT.RAID_WARNING then PlaySound(SOUNDKIT.RAID_WARNING) end
	end
	Changed()
end

-- Nameplates still in view keep their players on the list
local function ScanPlates()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) or next(ns.db.notes) == nil then return end
	local ok, plates = pcall(C_NamePlate.GetNamePlates)
	if not ok or type(plates) ~= "table" then return end
	for _, plate in ipairs(plates) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if type(unit) == "string" then ns.SeenUnit(unit) end
	end
end
ns.ScanPlates = ScanPlates

-- Another layer: who was on the last one isn't on this one
function ns.LayerChanged()
	wipe(recent)
	wipe(alerted)
	Changed()
end

-- The note in a player's tooltip
local function TooltipNote(tooltip)
	if tooltip ~= GameTooltip or not tooltip.GetUnit then return end
	local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
	if not ok or type(unit) ~= "string" or ns.IsSecret(unit) or not IsOtherPlayer(unit) then return end
	local entry = ns.Note(ns.UnitFullName(unit))
	if entry then tooltip:AddLine(format(L.NOTE_TIP, entry.note), 1, 0.55, 0.15) end
end

-- The note from a player's right-click menu: a box to write it in
StaticPopupDialogs.FARMGOD_NOTE = {
	text = L.NOTE_POPUP,
	button1 = ACCEPT or OKAY or "OK",
	button2 = CANCEL or "Cancel",
	hasEditBox = 1,
	maxLetters = 60,
	OnShow = function(self, data)
		local box = self.GetEditBox and self:GetEditBox() or self.editBox or self.EditBox
		local entry = ns.Note(data)
		if box then
			box:SetText(entry and entry.note or L.NOTE_DEFAULT)
			box:HighlightText()
		end
	end,
	OnAccept = function(self, data)
		local box = self.GetEditBox and self:GetEditBox() or self.editBox or self.EditBox
		if box then ns.SetNote(data, box:GetText()) end
	end,
	-- The game hands over the player as data; older clients only through the box's parent
	EditBoxOnEnterPressed = function(box, data)
		local parent = box:GetParent()
		ns.SetNote(data or (parent and parent.data), box:GetText())
		StaticPopup_Hide("FARMGOD_NOTE")
	end,
	EditBoxOnEscapePressed = function() StaticPopup_Hide("FARMGOD_NOTE") end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function ns.EditNote(name)
	if name then StaticPopup_Show("FARMGOD_NOTE", name, nil, name) end
end

local MENUS = { "PLAYER", "ENEMY_PLAYER", "PARTY", "RAID_PLAYER", "FRIEND", "TARGET", "FOCUS", "COMMUNITIES_GUILD_MEMBER" }
local function AddToMenus()
	if not (Menu and Menu.ModifyMenu) then return end
	for _, which in ipairs(MENUS) do
		Menu.ModifyMenu("MENU_UNIT_" .. which, function(_, root, context)
			if type(context) ~= "table" then return end
			local name = context.unit and ns.UnitFullName(context.unit)
			if not name and type(context.name) == "string" and not ns.IsSecret(context.name) then name = context.name end
			if not name or (context.unit and not IsOtherPlayer(context.unit)) then return end
			root:CreateDivider()
			root:CreateButton(ns.Note(name) and L.NOTE_MENU_EDIT or L.NOTE_MENU_ADD, function() ns.EditNote(name) end)
		end)
	end
end

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_LOGIN")
ns.Listen(events, "NAME_PLATE_UNIT_ADDED")
ns.Listen(events, "PLAYER_TARGET_CHANGED")
ns.Listen(events, "UPDATE_MOUSEOVER_UNIT")
-- Forever's layer change (its shard transfer); the Classic clients don't have it
for _, event in ipairs({ "SHARD_TRANSFER" }) do ns.Listen(events, event) end
events:SetScript("OnEvent", function(_, event, unit)
	if event == "NAME_PLATE_UNIT_ADDED" then
		ns.SeenUnit(unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		ns.SeenUnit("target")
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		ns.SeenUnit("mouseover")
	elseif event == "SHARD_TRANSFER" then
		ns.LayerChanged()
	elseif event == "PLAYER_LOGIN" then
		if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, TooltipNote)
		elseif GameTooltip and GameTooltip.HookScript then
			GameTooltip:HookScript("OnTooltipSetUnit", TooltipNote)
		end
		AddToMenus()
		C_Timer.NewTicker(5, ScanPlates)
	end
end)

-- /farmgod note Farmer: on your target. Alone: the box for your target, or the list
local function Note(rest)
	rest = strtrim(rest or "")
	local name = IsOtherPlayer("target") and ns.UnitFullName("target")
	if not name then
		if rest ~= "" then
			ns.Print(L.NOTE_NO_TARGET)
			return
		end
		local any = false
		for _, entry in pairs(ns.db.notes) do
			if not any then ns.Print(L.NOTES_TITLE) end
			any = true
			print(format("  %s: %s  (%s)", ns.ClassColoured(entry), entry.note,
				entry.seen and format(L.SEEN_AGO, ns.Ago(time() - entry.seen), entry.zone or "?") or L.SEEN_NEVER))
		end
		if not any then ns.Print(L.NOTES_NONE) end
		return
	end
	if rest == "" then
		ns.EditNote(name)
		return
	end
	local lower = strlower(rest)
	if lower == "remove" or lower == "quitar" or rest == "-" then
		ns.SetNote(name, "")
		ns.Print(format(L.NOTE_REMOVED, name))
		return
	end
	ns.SetNote(name, rest)
	alerted[Key(name)] = GetTime() -- you're looking at them: on the list, without the alert
	ns.SeenUnit("target")
	ns.Print(format(L.NOTE_SET, name, rest))
end
ns.commands.note = Note
ns.commands.notes = Note
ns.commands.nota = Note
ns.commands.notas = Note
-- You changed layer and the game didn't say: forget who was on the last one
ns.commands.layer = function()
	ns.LayerChanged()
	ns.Print(L.LAYER_CLEARED)
end
ns.commands.capa = ns.commands.layer
