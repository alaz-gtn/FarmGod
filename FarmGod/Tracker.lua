local _, ns = ...
local L = ns.L

-- The session window: flat and dark like the options, thin letters, one-pixel black edge. The
-- time and buttons on top, then what it's worth and each family of loot
local ACCENT = { 0.95, 0.76, 0.31 }
local TEXT = { 0.92, 0.94, 0.97 }
local MUTED = { 0.58, 0.62, 0.68 }
local GREEN = { 0.35, 0.85, 0.4 }
local MEDIA = "Interface\\AddOns\\FarmGod\\media\\"
local HEAD, ROW, PAD = 24, 18, 8
local MAX_TIP_ITEMS = 15

local db
local frame = CreateFrame("Frame", "FarmGodTracker", UIParent)
frame:SetFrameStrata("MEDIUM")
frame:SetSize(250, 100)
frame:EnableMouse(true)
frame:Hide()

local back = frame:CreateTexture(nil, "BACKGROUND")
back:SetAllPoints()
local edges = {}
for i = 1, 4 do
	edges[i] = frame:CreateTexture(nil, "BORDER")
	edges[i]:SetColorTexture(0, 0, 0, 1)
end

local function Thin(parent, size, color, justify)
	local fs = parent:CreateFontString(nil, "ARTWORK")
	ns.ThinFont(fs, size)
	fs:SetTextColor(unpack(color or TEXT))
	fs:SetJustifyH(justify or "LEFT")
	fs:SetWordWrap(false)
	return fs
end

-- The title bar: drag it to move the window
local head = CreateFrame("Frame", nil, frame)
head:SetPoint("TOPLEFT")
head:SetPoint("TOPRIGHT")
head:SetHeight(HEAD)
head:EnableMouse(true)
head:RegisterForDrag("LeftButton")
head:SetScript("OnDragStart", function()
	if not db.locked and not InCombatLockdown() then frame:StartMoving() end
end)
head:SetScript("OnDragStop", function()
	frame:StopMovingOrSizing()
	ns.SavePosition(frame)
end)
local headBack = head:CreateTexture(nil, "BACKGROUND", nil, 1)
headBack:SetAllPoints()
headBack:SetColorTexture(0, 0, 0, 0.35)
local headLine = frame:CreateTexture(nil, "ARTWORK")
headLine:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.5)
headLine:SetPoint("TOPLEFT", 0, -HEAD)
headLine:SetPoint("TOPRIGHT", 0, -HEAD)
headLine:SetHeight(1)
local light = head:CreateTexture(nil, "ARTWORK")
light:SetSize(6, 6)
light:SetPoint("LEFT", PAD, 0)
local clock = Thin(head, 15)
clock:SetPoint("LEFT", light, "RIGHT", 6, 0)
local stateText = Thin(head, 12, MUTED)
stateText:SetPoint("LEFT", clock, "RIGHT", 6, 0)

-- Buttons drawn with the addon's own white glyphs, tinted
local buttons = {}
local function Glyph(name, tip, onClick)
	local b = CreateFrame("Button", nil, head)
	b:SetSize(20, 20)
	local glyph = b:CreateTexture(nil, "ARTWORK")
	glyph:SetSize(12, 12)
	glyph:SetPoint("CENTER")
	glyph:SetTexture(MEDIA .. name)
	glyph:SetVertexColor(unpack(MUTED))
	b.glyph = glyph
	b.tip = tip
	b:SetScript("OnEnter", function(self)
		glyph:SetVertexColor(unpack(ACCENT))
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(self.tip)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function()
		glyph:SetVertexColor(unpack(MUTED))
		GameTooltip_Hide()
	end)
	b:SetScript("OnClick", onClick)
	local anchor = buttons[#buttons]
	if anchor then
		b:SetPoint("RIGHT", anchor, "LEFT", -1, 0)
	else
		b:SetPoint("RIGHT", -4, 0)
	end
	buttons[#buttons + 1] = b
	return b
end

local options = Glyph("gear", L.BTN_OPTIONS, function() if ns.ToggleOptions then ns.ToggleOptions() end end)
local fold = Glyph("fold", L.BTN_FOLD, function()
	db.collapsed = not db.collapsed
	ns.UpdateTracker()
end)
local reset = Glyph("reset", L.BTN_RESET, function()
	if ns.SessionState() ~= "idle" then StaticPopup_Show("FARMGOD_RESET") end
end)
local stop = Glyph("stop", L.BTN_STOP, function() ns.EndSession() end)
local play = Glyph("play", L.BTN_START, function() ns.ToggleSession() end)

-- Kills, small in the title bar: there in the folded window too. Hover for the rest
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local kills = CreateFrame("Frame", nil, head)
kills:SetSize(40, HEAD)
kills:SetPoint("RIGHT", play, "LEFT", -2, 0)
kills:EnableMouse(true)
local killText = Thin(kills, 13, TEXT, "RIGHT")
killText:SetPoint("RIGHT")
stateText:SetPoint("RIGHT", kills, "LEFT", -4, 0)
kills:SetScript("OnEnter", function(self)
	local s = self.session
	if not s then return end
	local n = ns.Kills(s)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:AddLine(L.TIP_KILLS, ACCENT[1], ACCENT[2], ACCENT[3])
	GameTooltip:AddDoubleLine(L.TIP_KILLS, n, 1, 1, 1, 1, 1, 1)
	local hour = ns.PerHour(n, self.seconds)
	if hour then GameTooltip:AddDoubleLine(L.TIP_HOUR, format("%.0f", hour), 1, 1, 1, 1, 1, 1) end
	if s.mobs > 0 then GameTooltip:AddDoubleLine(L.TIP_LOOTED, s.mobs, 1, 1, 1, 1, 1, 1) end
	if n > 0 and self.total then GameTooltip:AddDoubleLine(L.TIP_PER_KILL, ns.Money(self.total / n), 1, 1, 1, 1, 1, 1) end
	GameTooltip:Show()
end)
kills:SetScript("OnLeave", GameTooltip_Hide)

StaticPopupDialogs.FARMGOD_RESET = {
	text = L.RESET_CONFIRM,
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function() ns.ResetSession() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- The total and what it makes an hour
local total = Thin(frame, 22)
total:SetPoint("TOPLEFT", PAD, -HEAD - 7)
local perHour = Thin(frame, 13, MUTED, "RIGHT")
local hint = Thin(frame, 12, MUTED)
hint:SetWordWrap(true)

-- One line each: the looted gold, then the families
local rows = {}
local function ShowTip(row)
	local family = row.family
	if not family then return end
	GameTooltip:SetOwner(row, "ANCHOR_LEFT")
	GameTooltip:AddLine(L.CATEGORY[family.key], ACCENT[1], ACCENT[2], ACCENT[3])
	for i, item in ipairs(family.items) do
		if i > MAX_TIP_ITEMS then
			GameTooltip:AddLine(format(L.TIP_MORE, #family.items - MAX_TIP_ITEMS), MUTED[1], MUTED[2], MUTED[3])
			break
		end
		local name = item.link or ns.ItemName(item.id)
		local worth = ns.Money(item.value)
		if item.source == "vendor" then
			worth = worth .. " " .. L.TAG_VENDOR
		elseif item.source == "none" then
			worth = L.TAG_NO_PRICE
		elseif item.source == "skip" then
			worth = L.TAG_SKIP
		end
		GameTooltip:AddDoubleLine(format("%d × %s", item.count, name), worth, 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(ns.PriceSourceText(), MUTED[1], MUTED[2], MUTED[3])
	GameTooltip:Show()
end

local function Row(i)
	local row = rows[i]
	if row then return row end
	row = CreateFrame("Button", nil, frame)
	row:SetHeight(ROW)
	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.05)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(14, 14)
	row.icon:SetPoint("LEFT", PAD, 0)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.value = Thin(row, 13, TEXT, "RIGHT")
	row.value:SetPoint("RIGHT", -PAD, 0)
	row.name = Thin(row, 13)
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.name:SetPoint("RIGHT", row.value, "LEFT", -6, 0)
	row:SetScript("OnEnter", ShowTip)
	row:SetScript("OnLeave", GameTooltip_Hide)
	rows[i] = row
	return row
end

-- Goals, as a quest's objectives: the item, how many of how many and a thin bar under it
local GOAL_ROW = 20
local goalRows = {}
local function GoalTip(row)
	local goal = row.goal
	if not goal then return end
	GameTooltip:SetOwner(row, "ANCHOR_LEFT")
	GameTooltip:AddLine(goal.link or ns.ItemName(goal.id))
	GameTooltip:AddDoubleLine(L.GOAL_HAVE, format("%d/%d", goal.have, goal.need), 1, 1, 1, 1, 1, 1)
	local missing = goal.need - goal.have
	local got, hour, minutes = ns.GoalPace(goal.id, missing)
	if got then
		GameTooltip:AddDoubleLine(L.GOAL_SESSION, hour and format(L.GOAL_RATE, got, ns.Short(hour)) or "+" .. got,
			1, 1, 1, 1, 1, 1)
	end
	if goal.done then
		GameTooltip:AddLine(L.GOAL_DONE_TAG, GREEN[1], GREEN[2], GREEN[3])
	elseif minutes then
		GameTooltip:AddLine(format(L.GOAL_ETA, missing, ns.Clock(minutes * 60)), MUTED[1], MUTED[2], MUTED[3])
	end
	GameTooltip:AddLine(L.GOAL_TIP_CLICK, ACCENT[1], ACCENT[2], ACCENT[3])
	GameTooltip:Show()
end

local function GoalRow(i)
	local row = goalRows[i]
	if row then return row end
	row = CreateFrame("Button", nil, frame)
	row:SetHeight(GOAL_ROW)
	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.05)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(14, 14)
	row.icon:SetPoint("TOPLEFT", PAD, -2)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.count = Thin(row, 13, ACCENT, "RIGHT")
	row.count:SetPoint("TOPRIGHT", -PAD, -2)
	row.name = Thin(row, 13)
	row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
	row.name:SetPoint("RIGHT", row.count, "LEFT", -6, 0)
	row.track = row:CreateTexture(nil, "BACKGROUND", nil, 2)
	row.track:SetColorTexture(1, 1, 1, 0.08)
	row.track:SetPoint("BOTTOMLEFT", PAD + 20, 2)
	row.track:SetPoint("BOTTOMRIGHT", -PAD, 2)
	row.track:SetHeight(2)
	row.fill = row:CreateTexture(nil, "ARTWORK")
	row.fill:SetPoint("BOTTOMLEFT", row.track, "BOTTOMLEFT")
	row.fill:SetHeight(2)
	row:SetScript("OnEnter", GoalTip)
	row:SetScript("OnLeave", GameTooltip_Hide)
	row:SetScript("OnClick", function() if ns.ToggleOptions then ns.ToggleOptions("goals") end end)
	goalRows[i] = row
	return row
end

local function DrawGoals(y)
	local goals = ns.Goals()
	local barWidth = db.width - 2 * PAD - 20
	for i, goal in ipairs(goals) do
		local row = GoalRow(i)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:SetPoint("TOPRIGHT", 0, y)
		row.icon:SetTexture(ns.ItemIcon(goal.id))
		row.name:SetText(ns.ItemName(goal.id, goal.link))
		row.name:SetTextColor(unpack(goal.done and GREEN or TEXT))
		row.count:SetText(format("%d/%d", min(goal.have, goal.need), goal.need))
		row.count:SetTextColor(unpack(goal.done and GREEN or ACCENT))
		local share = min(goal.have / goal.need, 1)
		row.fill:SetShown(share > 0)
		row.fill:SetWidth(max(barWidth * share, 1))
		row.fill:SetColorTexture(unpack(goal.done and GREEN or ACCENT))
		row.goal = goal
		row:Show()
		y = y - GOAL_ROW
	end
	for i = #goals + 1, #goalRows do
		goalRows[i]:Hide()
		goalRows[i].goal = nil
	end
	return #goals > 0 and y - 4 or y
end

-- Reputation, the factions you gained the most with: in their standing's colour, the gain and an
-- hour, a thin bar for how far into the standing you are. Hover for how long to the next one
local MAX_REP = 3
local repRows = {}
local function RepTip(row)
	local rep = row.rep
	if not rep then return end
	local d = rep.data
	local colour = ns.StandingColour(d and d.reaction)
	GameTooltip:SetOwner(row, "ANCHOR_LEFT")
	GameTooltip:AddLine(rep.name, colour[1], colour[2], colour[3])
	GameTooltip:AddDoubleLine(L.REP_SESSION, ns.Signed(rep.delta), 1, 1, 1, 1, 1, 1)
	if rep.hour then GameTooltip:AddDoubleLine(L.REP_HOUR, ns.Number(rep.hour), 1, 1, 1, 1, 1, 1) end
	if d then
		local span = (d.high or 0) - (d.low or 0)
		if span > 0 then
			GameTooltip:AddDoubleLine(ns.StandingName(d.reaction), format("%s / %s", ns.Number(d.value - d.low), ns.Number(span)),
				1, 1, 1, 1, 1, 1)
			local missing = d.high - d.value
			if rep.hour and rep.hour > 0 then
				GameTooltip:AddLine(format(L.REP_ETA, ns.Number(missing), ns.StandingName(d.reaction + 1),
					ns.Clock(missing / rep.hour * 3600)), MUTED[1], MUTED[2], MUTED[3], true)
			end
		else
			GameTooltip:AddLine(format(L.REP_TOP, ns.StandingName(d.reaction)), MUTED[1], MUTED[2], MUTED[3])
		end
	end
	GameTooltip:Show()
end

local function RepRow(i)
	local row = repRows[i]
	if row then return row end
	row = CreateFrame("Button", nil, frame)
	row:SetHeight(GOAL_ROW)
	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.05)
	row.value = Thin(row, 12, MUTED, "RIGHT")
	row.value:SetPoint("TOPRIGHT", -PAD, -3)
	row.name = Thin(row, 13)
	row.name:SetPoint("TOPLEFT", PAD, -2)
	row.name:SetPoint("RIGHT", row.value, "LEFT", -6, 0)
	row.track = row:CreateTexture(nil, "BACKGROUND", nil, 2)
	row.track:SetColorTexture(1, 1, 1, 0.08)
	row.track:SetPoint("BOTTOMLEFT", PAD, 2)
	row.track:SetPoint("BOTTOMRIGHT", -PAD, 2)
	row.track:SetHeight(2)
	row.fill = row:CreateTexture(nil, "ARTWORK")
	row.fill:SetPoint("BOTTOMLEFT", row.track, "BOTTOMLEFT")
	row.fill:SetHeight(2)
	row:SetScript("OnEnter", RepTip)
	row:SetScript("OnLeave", GameTooltip_Hide)
	repRows[i] = row
	return row
end

local function DrawRep(y, s, seconds)
	local list = s and ns.RepList and ns.RepList(s) or {} -- (Rep.lua is new: missing until the game restarts)
	local shown = min(#list, MAX_REP)
	for i = 1, shown do
		local rep = list[i]
		local row = RepRow(i)
		local d = rep.data
		rep.hour = ns.PerHour(rep.delta, seconds)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y)
		row:SetPoint("TOPRIGHT", 0, y)
		local colour = ns.StandingColour(d and d.reaction)
		row.name:SetText(rep.name)
		row.name:SetTextColor(unpack(colour))
		row.value:SetText(rep.hour and format("%s  ·  %s/h", ns.Signed(rep.delta), ns.Short(rep.hour)) or ns.Signed(rep.delta))
		local span = d and (d.high or 0) - (d.low or 0) or 0
		local share = span > 0 and min(max((d.value - d.low) / span, 0), 1) or 1
		row.fill:SetShown(share > 0)
		row.fill:SetWidth(max((db.width - 2 * PAD) * share, 1))
		row.fill:SetColorTexture(unpack(colour))
		row.rep = rep
		row:Show()
		y = y - GOAL_ROW
	end
	for i = shown + 1, #repRows do
		repRows[i]:Hide()
		repRows[i].rep = nil
	end
	return shown > 0 and y - 2 or y
end

local counts = Thin(frame, 12, MUTED)
counts:SetWordWrap(true)
local skills = Thin(frame, 12, MUTED)
skills:SetWordWrap(true)
-- Noted players seen on your layer lately
local near = Thin(frame, 12, { 1, 0.55, 0.15 })
near:SetWordWrap(true)

-- The gathering icons, from the spells themselves
local COUNT_ORDER = { "mining", "herb", "skin", "fish", "pick" }
local COUNT_SPELLS = { mining = 2575, herb = 2366, skin = 8613, fish = 7620, pick = 921 }
local function Inline(texture)
	return format("|T%s:13:13:0:0:64:64:5:59:5:59|t", tostring(texture))
end

local function CountsText(s, seconds)
	local parts = {}
	for _, kind in ipairs(COUNT_ORDER) do
		local n = s.gathers[kind]
		if n and n > 0 then
			local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(COUNT_SPELLS[kind])
			parts[#parts + 1] = (icon and Inline(icon) or L.GATHER[kind]) .. " " .. n
		end
	end
	if s.xp > 0 then
		local hour = ns.PerHour(s.xp, seconds)
		parts[#parts + 1] = hour and format(L.XP_HOUR, ns.Short(hour)) or format(L.XP, ns.Short(s.xp))
	end
	return table.concat(parts, "   ")
end

function ns.Short(n)
	if n >= 1000000 then return format("%.1fM", n / 1000000) end
	if n >= 10000 then return format("%.0fk", n / 1000) end
	if n >= 1000 then return format("%.1fk", n / 1000) end
	return tostring(floor(n))
end

local function SkillsText(s)
	local parts = {}
	for name, skill in pairs(s.skills) do
		parts[#parts + 1] = format("%s %d (+%d)", name, skill.to, skill.to - skill.from)
	end
	table.sort(parts)
	return table.concat(parts, "   ")
end

local function Edge()
	local px = ns.OnePixel(frame)
	local top, bottom, left, right = unpack(edges)
	top:ClearAllPoints()
	top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -px, 0)
	top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", px, 0)
	top:SetHeight(px)
	bottom:ClearAllPoints()
	bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -px, 0)
	bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", px, 0)
	bottom:SetHeight(px)
	left:ClearAllPoints()
	left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
	left:SetWidth(px)
	right:ClearAllPoints()
	right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
	right:SetWidth(px)
end

-- While the displays are unlocked and there's no session, a sample to place
local function Sample()
	return {
		state = "running", elapsed = 2732, money = 184500, mobs = 23, xp = 0, skills = {},
		gathers = { mining = 31, herb = 4 },
	}, {
		total = 1532200, money = 184500,
		families = {
			{ key = "ore", value = 1104000, count = 96, items = {} },
			{ key = "elemental", value = 180000, count = 3, items = {} },
			{ key = "junk", value = 63700, count = 41, items = {} },
		},
	}
end

function ns.UpdateTracker()
	if not db then return end
	local state = ns.SessionState()
	local s = ns.char.current
	local sample = ns.unlocked and not s
	local shown = ns.unlocked or (db.shown and not (db.onlyActive and state == "idle" and #ns.char.goals == 0
		and not (ns.NearbyNoted and #ns.NearbyNoted() > 0)))
	frame:SetShown(shown)
	if not shown then return end
	frame:SetScale(db.scale / 100)
	frame:SetWidth(db.width)
	back:SetColorTexture(0.04, 0.05, 0.07, db.alpha / 100)
	Edge()

	local worth, seconds
	if sample then
		s, worth = Sample()
		state = "running"
		seconds = s.elapsed
	elseif s then
		worth = ns.Appraise(s)
		seconds = ns.Elapsed(s)
	end

	-- The title bar: a light for the state and the time
	if state == "running" then
		light:SetColorTexture(unpack(GREEN))
	elseif state == "paused" then
		light:SetColorTexture(unpack(ACCENT))
	else
		light:SetColorTexture(unpack(MUTED))
	end
	clock:SetText(s and ns.Clock(seconds) or "FarmGod")
	clock:SetTextColor(unpack(state == "running" and TEXT or MUTED))
	stateText:SetText(state == "paused" and (s.pause == "idle" and L.STATE_IDLE or L.STATE_PAUSED) or "")
	play.glyph:SetTexture(MEDIA .. (state == "running" and "pause" or "play"))
	play.tip = state == "running" and L.BTN_PAUSE or (state == "paused" and L.BTN_RESUME or L.BTN_START)
	stop:SetShown(s ~= nil)
	reset:SetShown(s ~= nil)
	local killCount = s and ns.Kills(s) or 0
	kills:SetShown(db.kills and killCount > 0)
	killText:SetText(format("|T%s:12:12|t %d", SKULL, killCount))
	kills:SetWidth(max((killText:GetStringWidth() or 30) + 4, 24))
	kills.session, kills.seconds, kills.total = s, seconds, worth and worth.total
	fold.glyph:SetTexCoord(0, 1, db.collapsed and 1 or 0, db.collapsed and 0 or 1)

	local y = -HEAD - 7
	local used = 0
	if not s then
		total:Hide()
		perHour:Hide()
		hint:Show()
		hint:ClearAllPoints()
		hint:SetPoint("TOPLEFT", PAD, y)
		hint:SetPoint("TOPRIGHT", -PAD, y)
		hint:SetText(db.collapsed and "" or (ns.db.session.autoStart and L.IDLE_HINT_AUTO or L.IDLE_HINT))
		y = y - (db.collapsed and 0 or max(ceil(hint:GetStringHeight() or 14), 14) + 4)
		y = DrawGoals(y)
	else
		hint:Hide()
		total:Show()
		total:SetText(ns.Money(worth.total))
		local hour = ns.PerHour(worth.total, seconds)
		perHour:SetShown(hour ~= nil)
		perHour:SetText(hour and format(L.PER_HOUR, ns.Money(hour, true)) or "")
		perHour:ClearAllPoints()
		perHour:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -PAD, y - 22)
		y = y - 28
		y = DrawGoals(y)
		if not db.collapsed then
			-- The looted gold, then the families that count, the most valuable first
			local lines = {}
			if worth.money > 0 then
				lines[#lines + 1] = { icon = "Interface\\Icons\\INV_Misc_Coin_01", name = L.LOOTED_GOLD, value = worth.money }
			end
			for _, family in ipairs(worth.families) do
				if #lines >= db.rows then break end
				if not family.skip then
					lines[#lines + 1] = {
						icon = family.items[1] and ns.ItemIcon(family.items[1].id) or ns.CategoryIcon(family.key),
						name = format("%s  |cff9da3ad%d|r", L.CATEGORY[family.key], family.count),
						value = family.value, family = family,
					}
				end
			end
			for i, line in ipairs(lines) do
				local row = Row(i)
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", 0, y)
				row:SetPoint("TOPRIGHT", 0, y)
				row.icon:SetTexture(line.icon)
				row.name:SetText(line.name)
				row.value:SetText(ns.Money(line.value, true))
				row.family = line.family
				row:Show()
				y = y - ROW
			end
			used = #lines
		end
	end
	for i = used + 1, #rows do
		rows[i]:Hide()
		rows[i].family = nil
	end
	-- Reputation gained this session
	y = DrawRep(y, (s and not sample and db.rep and not db.collapsed) and s or nil, seconds)

	-- At the foot: nodes, mobs, XP and skill-ups
	local countText = (s and db.counts and not db.collapsed) and CountsText(s, seconds) or ""
	counts:SetShown(countText ~= "")
	if countText ~= "" then
		y = y - 4
		counts:ClearAllPoints()
		counts:SetPoint("TOPLEFT", PAD, y)
		counts:SetPoint("TOPRIGHT", -PAD, y)
		counts:SetText(countText)
		y = y - max(ceil(counts:GetStringHeight() or 14), 14)
	end
	local skillText = (s and db.counts and not db.collapsed) and SkillsText(s) or ""
	skills:SetShown(skillText ~= "")
	if skillText ~= "" then
		y = y - 3
		skills:ClearAllPoints()
		skills:SetPoint("TOPLEFT", PAD, y)
		skills:SetPoint("TOPRIGHT", -PAD, y)
		skills:SetText(skillText)
		y = y - max(ceil(skills:GetStringHeight() or 14), 14)
	end
	-- (Notes.lua is a newer file: until the game restarts it isn't there)
	local seen = ns.db.noteAlerts.near and ns.NearbyNoted and ns.NearbyNoted() or {}
	near:SetShown(#seen > 0)
	if #seen > 0 then
		local parts = {}
		for _, one in ipairs(seen) do
			parts[#parts + 1] = format("%s (%s) %s", ns.ClassColoured(one.entry), one.entry.note, ns.Ago(one.ago))
		end
		y = y - 4
		near:ClearAllPoints()
		near:SetPoint("TOPLEFT", PAD, y)
		near:SetPoint("TOPRIGHT", -PAD, y)
		near:SetText(format(L.NEAR, table.concat(parts, ", ")))
		y = y - max(ceil(near:GetStringHeight() or 14), 14)
	end
	frame:SetHeight(-y + 6)
end
table.insert(ns.refreshers, ns.UpdateTracker)

-- Whatever changed in the session or the prices
function ns.Changed()
	ns.UpdateTracker()
	if ns.RefreshOptionsPage then
		ns.RefreshOptionsPage("history")
		ns.RefreshOptionsPage("goals")
		ns.RefreshOptionsPage("notes")
		ns.RefreshOptionsPage("day")
		ns.RefreshOptionsPage("session") -- its start/pause word
	end
end

-- The clock moves once a second while the window shows
local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
	elapsed = elapsed + dt
	if elapsed < 1 then return end
	elapsed = 0
	ns.UpdateTracker()
	if ns.RefreshOptionsPage then ns.RefreshOptionsPage("day") end -- its time played
end)

-- Which prices these are: the source and whether it's there
function ns.PriceSourceText()
	local prices = ns.db.prices
	local source = prices.source
	if source == "vendor" then return L.SOURCE_TEXT.vendor end
	local names = {}
	if (source == "auto" or source == "auctionator") and ns.HasAuctionator() then names[#names + 1] = "Auctionator" end
	if (source == "auto" or source == "tsm") and ns.HasTSM() then names[#names + 1] = "TSM (" .. prices.tsm .. ")" end
	if #names == 0 then return L.SOURCE_TEXT.missing end
	return format(L.SOURCE_TEXT.auction, table.concat(names, L.THEN))
end

-- After a visit to the auction house the prices are new: say what the session is worth now
local before
local function PricesUpdated()
	local s = ns.char.current
	if not s then
		ns.Changed()
		return
	end
	local now = ns.Appraise(s).total
	if before and now ~= before then
		ns.Print(format(L.PRICES_UPDATED, ns.Money(now), ns.Money(before)))
	end
	before = nil
	ns.Changed()
end

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_LOGIN")
ns.Listen(events, "AUCTION_HOUSE_SHOW")
ns.Listen(events, "AUCTION_HOUSE_CLOSED")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		db = ns.db.tracker
		ns.Movable(frame, "tracker", { "TOPRIGHT", "TOPRIGHT", -250, -200 }, L.TRACKER_NAME)
		ns.UpdateTracker()
	elseif event == "AUCTION_HOUSE_SHOW" then
		local s = ns.char.current
		before = s and ns.Appraise(s).total
	elseif event == "AUCTION_HOUSE_CLOSED" then
		-- The price addons save their scan as the window closes
		C_Timer.After(1, PricesUpdated)
	end
end)

local function Prices()
	ns.Print(ns.PriceSourceText())
	local s = ns.char.current
	before = s and ns.Appraise(s).total
	PricesUpdated()
	ns.Report()
end
ns.commands.prices = Prices
ns.commands.precios = Prices

local function Toggle()
	db.shown = not db.shown
	ns.UpdateTracker()
end
ns.commands.show = Toggle
ns.commands.mostrar = Toggle
ns.commands.ventana = Toggle
