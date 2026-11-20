local addonName, ns = ...
local L = ns.L

-- A dark window with a menu down the side, in gold, as HunterGod and MageGod have it. Square
-- pieces only: Forever's client draws icons cut round with a mask as stripes
local WIDTH, HEIGHT = 660, 560
local SIDE = 170 -- the menu
local TOP = 60 -- the title bar
local PAGE_WIDTH = WIDTH - SIDE - 40
local ACCENT = { 0.95, 0.76, 0.31 }
local TEXT = { 0.92, 0.94, 0.97 }
local MUTED = { 0.58, 0.62, 0.68 }
local window, scroll, scrollBar
local tabs, pages = {}, {}

-- Drawing pieces

local function Rect(parent, layer, r, g, b, a, sublevel)
	local t = parent:CreateTexture(nil, layer, nil, sublevel)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end

-- A white block, to tint with SetVertexColor
local function Block(parent, layer, width, height)
	local t = Rect(parent, layer, 1, 1, 1)
	t:SetSize(width, height)
	return t
end

local function Icon(parent, size, texture, coords)
	local t = parent:CreateTexture(nil, "ARTWORK")
	t:SetSize(size, size)
	t:SetTexture(texture)
	t:SetTexCoord(unpack(coords or { 0.08, 0.92, 0.08, 0.92 }))
	return t
end

-- The addon's round font, over the game's in case it can't load
local function Fancy(fs, size, flags)
	ns.FancyFont(fs, size, flags)
end

local function Text(parent, template, color)
	local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
	fs:SetTextColor(unpack(color or TEXT))
	fs:SetJustifyH("LEFT")
	return fs
end

-- A faint light behind a button while the mouse is on it
local function Highlight(button, alpha)
	local hl = button:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, alpha or 0.04)
end

-- An on/off switch for a CheckButton; returns the function that draws it
local function Switch(button, width, height)
	local track = Block(button, "ARTWORK", width, height)
	local knob = Block(button, "OVERLAY", height - 4, height - 4)
	local function Paint()
		local on = button:GetChecked()
		if on then track:SetVertexColor(unpack(ACCENT)) else track:SetVertexColor(0.22, 0.25, 0.3) end
		local shade = on and 1 or 0.7
		knob:SetVertexColor(shade, shade, shade)
		knob:ClearAllPoints()
		knob:SetPoint(on and "RIGHT" or "LEFT", track, on and "RIGHT" or "LEFT", on and -2 or 2, 0)
	end
	return track, Paint
end

local function Click()
	if SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
end

-- Controls: each one is a row of the page and knows how to read its setting back (Refresh)

-- A row with its text on the left, as tall as the text needs
local function Row(page, y, kind, text, textWidth, minHeight, icon)
	local row = CreateFrame(kind, nil, page)
	local label = Text(row)
	label:SetPoint("LEFT", icon and 36 or 10, 0)
	label:SetWidth(textWidth - (icon and 26 or 0))
	label:SetText(text)
	if icon then
		local picture = Icon(row, 18, icon)
		picture:SetPoint("LEFT", 10, 0)
	end
	local height = max(minHeight or 30, ceil(label:GetStringHeight() or 0) + 14)
	row:SetSize(PAGE_WIDTH, height)
	row:SetPoint("TOPLEFT", 0, y)
	row.label = label
	return row, y - height
end

local function Section(page, y, text)
	local title = page:CreateFontString(nil, "ARTWORK")
	Fancy(title, 14)
	title:SetTextColor(unpack(ACCENT))
	title:SetPoint("TOPLEFT", 10, y - 12)
	title:SetText(text)
	local line = Rect(page, "ARTWORK", ACCENT[1], ACCENT[2], ACCENT[3], 0.25)
	line:SetHeight(1)
	line:SetPoint("LEFT", title, "RIGHT", 10, 0)
	line:SetPoint("RIGHT", page, "RIGHT", -10, 0)
	return y - 36
end

-- Grey small print under a section
local function Hint(page, y, text)
	local hint = Text(page, "GameFontHighlightSmall", MUTED)
	hint:SetPoint("TOPLEFT", 10, y - 6)
	hint:SetWidth(PAGE_WIDTH - 20)
	hint:SetText(text)
	return y - 16 - ceil(hint:GetStringHeight() or 14), hint
end

local function Check(page, y, text, get, set, icon)
	local row
	row, y = Row(page, y, "CheckButton", text, PAGE_WIDTH - 66, nil, icon)
	Highlight(row)
	local switch, Paint = Switch(row, 34, 18)
	switch:SetPoint("RIGHT", -10, 0)
	row:SetScript("OnClick", function(self)
		set(self:GetChecked() and true or false)
		Paint()
		Click()
	end)
	row.Refresh = function()
		row:SetChecked(get())
		Paint()
	end
	row.setting = text
	table.insert(page.controls, row)
	return y
end

local function Slider(page, y, text, low, high, step, get, set)
	local row
	row, y = Row(page, y, "Frame", text, PAGE_WIDTH - 236)
	local value = Text(row, "GameFontHighlight", ACCENT)
	value:SetPoint("RIGHT", -10, 0)
	value:SetWidth(40)
	value:SetJustifyH("RIGHT")
	local slider = CreateFrame("Slider", nil, row)
	slider:SetOrientation("HORIZONTAL")
	slider:SetSize(150, 18)
	slider:SetPoint("RIGHT", -58, 0)
	slider:EnableMouse(true)
	local track = Rect(slider, "BACKGROUND", 0.22, 0.25, 0.3)
	track:SetSize(150, 4)
	track:SetPoint("CENTER")
	local thumb = Block(slider, "OVERLAY", 10, 16)
	slider:SetThumbTexture(thumb)
	local fill = Rect(slider, "ARTWORK", unpack(ACCENT))
	fill:SetHeight(4)
	fill:SetPoint("LEFT")
	fill:SetPoint("RIGHT", thumb, "CENTER")
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
	slider:SetScript("OnValueChanged", function(self, v)
		v = floor(v / step + 0.5) * step
		value:SetText(v)
		if not self.loading then set(v) end
	end)
	slider.Refresh = function()
		slider.loading = true
		slider:SetValue(get())
		value:SetText(get())
		slider.loading = false
	end
	slider.setting = text
	table.insert(page.controls, slider)
	return y
end

-- One of a few values, with arrows to go through them: { { value, text }, ... }
local function Choice(page, y, text, choices, get, set, icon)
	local row
	row, y = Row(page, y, "Frame", text, PAGE_WIDTH - 280, 34, icon)
	local box = CreateFrame("Button", nil, row)
	box:SetSize(250, 26)
	box:SetPoint("RIGHT", -10, 0)
	Rect(box, "BACKGROUND", 1, 1, 1, 0.06):SetAllPoints()
	Highlight(box)
	local value = box:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	value:SetPoint("LEFT", 26, 0)
	value:SetPoint("RIGHT", -26, 0)
	value:SetWordWrap(false)
	box:SetFontString(value)
	local function Pick(step)
		local at = 1
		for i, c in ipairs(choices) do
			if c[1] == get() then at = i end
		end
		set(choices[(at - 1 + step) % #choices + 1][1])
		box.Refresh()
		Click()
	end
	box:SetScript("OnClick", function() Pick(1) end)
	for _, side in ipairs({ { "LEFT", "<", -1 }, { "RIGHT", ">", 1 } }) do
		local arrow = CreateFrame("Button", nil, box)
		arrow:SetSize(26, 26)
		arrow:SetPoint(side[1])
		local glyph = arrow:CreateFontString(nil, "ARTWORK")
		Fancy(glyph, 15)
		glyph:SetPoint("CENTER")
		glyph:SetText(side[2])
		glyph:SetTextColor(unpack(MUTED))
		arrow:SetScript("OnEnter", function() glyph:SetTextColor(unpack(ACCENT)) end)
		arrow:SetScript("OnLeave", function() glyph:SetTextColor(unpack(MUTED)) end)
		arrow:SetScript("OnClick", function() Pick(side[3]) end)
	end
	box.Refresh = function()
		for _, c in ipairs(choices) do
			if c[1] == get() then box:SetText(c[2]) end
		end
	end
	box.setting = text
	table.insert(page.controls, box)
	return y
end

-- A row that does something when you click it, its word on the right (a function when it
-- changes)
local function Action(page, y, text, word, run)
	local row
	row, y = Row(page, y, "Button", text, PAGE_WIDTH - 130)
	Highlight(row)
	local label = Text(row, "GameFontHighlight", ACCENT)
	label:SetPoint("RIGHT", -10, 0)
	label:SetJustifyH("RIGHT")
	row.word = label
	row.Refresh = function()
		label:SetText(type(word) == "function" and word() or word)
	end
	row.Refresh()
	row:SetScript("OnClick", function()
		Click()
		run()
		row.Refresh()
	end)
	row.setting = text
	table.insert(page.controls, row)
	return y
end

-- A line of text that reads something when the page shows
local function Status(page, y, read)
	local row = CreateFrame("Frame", nil, page)
	row:SetSize(PAGE_WIDTH, 26)
	row:SetPoint("TOPLEFT", 0, y)
	local text = Text(row, "GameFontHighlightSmall", MUTED)
	text:SetPoint("LEFT", 10, 0)
	text:SetWidth(PAGE_WIDTH - 20)
	row.text = text
	row.Refresh = function() text:SetText(read()) end
	row.setting = "status"
	table.insert(page.controls, row)
	return y - 26
end

-- A box to type in, flat like the rest; grey words inside while it's empty
local function Box(parent, width, numeric, placeholder)
	local box = CreateFrame("EditBox", nil, parent)
	box:SetSize(width, 26)
	box:SetAutoFocus(false)
	box:SetFontObject(GameFontHighlight)
	box:SetTextInsets(8, 8, 0, 0)
	box:SetMaxLetters(numeric and 5 or 255)
	if numeric then box:SetNumeric(true) end
	Rect(box, "BACKGROUND", 1, 1, 1, 0.06):SetAllPoints()
	local hint = Text(box, "GameFontHighlightSmall", MUTED)
	hint:SetPoint("LEFT", 8, 0)
	hint:SetPoint("RIGHT", -8, 0)
	hint:SetWordWrap(false)
	hint:SetText(placeholder or "")
	box.placeholder = hint
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	box:HookScript("OnTextChanged", function(self) hint:SetShown((self:GetText() or "") == "") end)
	return box
end

-- A new goal: the item (dragged onto the square, shift-clicked or typed: name or id) and how many
local editor
local function GoalEditor(page, y)
	local row = CreateFrame("Frame", nil, page)
	row:SetSize(PAGE_WIDTH, 44)
	row:SetPoint("TOPLEFT", 0, y)
	local slot = CreateFrame("Button", nil, row)
	slot:SetSize(34, 34)
	slot:SetPoint("LEFT", 10, 0)
	Rect(slot, "BACKGROUND", 1, 1, 1, 0.06):SetAllPoints()
	Highlight(slot, 0.08)
	local picture = Icon(slot, 30)
	picture:SetPoint("CENTER")
	local plus = slot:CreateFontString(nil, "ARTWORK")
	Fancy(plus, 18)
	plus:SetPoint("CENTER")
	plus:SetText("+")
	plus:SetTextColor(unpack(MUTED))
	local add = CreateFrame("Button", nil, row)
	add:SetSize(84, 26)
	add:SetPoint("RIGHT", -10, 0)
	Rect(add, "BACKGROUND", ACCENT[1], ACCENT[2], ACCENT[3], 0.18):SetAllPoints()
	Highlight(add, 0.08)
	local addText = add:CreateFontString(nil, "ARTWORK")
	Fancy(addText, 13)
	addText:SetTextColor(unpack(ACCENT))
	add:SetFontString(addText)
	add:SetText(L.ADD)
	local amount = Box(row, 64, true, L.AMOUNT)
	amount:SetPoint("RIGHT", add, "LEFT", -6, 0)
	local item = Box(row, 10, false, L.ITEM_PLACEHOLDER)
	item:SetPoint("LEFT", slot, "RIGHT", 8, 0)
	item:SetPoint("RIGHT", amount, "LEFT", -6, 0)

	local chosen -- { id, link }: from a drag, a shift-click or a goal you clicked
	local function Choose(id, link)
		chosen = id and { id = id, link = link } or nil
		picture:SetTexture(id and ns.ItemIcon(id) or nil)
		picture:SetShown(id ~= nil)
		plus:SetShown(id == nil)
	end
	local function Take(link)
		local id = tonumber(link:match("item:(%d+)"))
		if not id then return end
		item:SetText(ns.ItemName(id, link))
		Choose(id, link:match("|H") and link or nil)
		amount:SetFocus()
	end
	local function FromCursor()
		local kind, id, link = GetCursorInfo()
		if kind == "item" and id then
			ClearCursor()
			Take(link or ("item:" .. id))
		end
	end
	slot:SetScript("OnReceiveDrag", FromCursor)
	slot:SetScript("OnClick", FromCursor)
	-- Typing another name forgets the item you had chosen
	item:HookScript("OnTextChanged", function(self, typed) if typed then Choose(nil) end end)
	local function Add()
		local id, link
		if chosen then
			id, link = chosen.id, chosen.link
		else
			id, link = ns.ResolveItem(item:GetText())
		end
		if not id then
			ns.Print(format(L.GOAL_UNKNOWN, item:GetText() or ""))
			item:SetFocus()
			return
		end
		local need = tonumber(amount:GetText())
		if not need or need <= 0 then
			ns.Print(L.GOAL_AMOUNT)
			amount:SetFocus()
			return
		end
		ns.SetGoal(id, need, link)
		item:SetText("")
		amount:SetText("")
		Choose(nil)
		item:ClearFocus()
		amount:ClearFocus()
		Click()
	end
	add:SetScript("OnClick", Add)
	item:SetScript("OnEnterPressed", function() amount:SetFocus() end)
	amount:SetScript("OnEnterPressed", Add)
	Choose(nil)
	row.Refresh = function() end
	row.Edit = function(goal)
		item:SetText(ns.ItemName(goal.id, goal.link))
		Choose(goal.id, goal.link)
		amount:SetText(tostring(goal.need))
		amount:SetFocus()
	end
	row.Take = Take
	row.item, row.amount, row.add, row.slot, row.picture = item, amount, add, slot, picture
	row.setting = "goal editor"
	editor = row
	table.insert(page.controls, row)
	return y - 48
end

-- A shift-clicked item goes to the goal box while you're typing in it
local function InsertLink(link)
	if editor and type(link) == "string" and link:match("item:") and (editor.item:HasFocus() or editor.amount:HasFocus()) then
		editor.Take(link)
	end
end
if hooksecurefunc then
	if ChatFrameUtil and ChatFrameUtil.InsertLink then hooksecurefunc(ChatFrameUtil, "InsertLink", InsertLink) end
	if ChatEdit_InsertLink then hooksecurefunc("ChatEdit_InsertLink", InsertLink) end
end

-- Your goals: click one to change its amount, × to take it off
local function GoalList(page, y)
	local list = CreateFrame("Frame", nil, page)
	list:SetPoint("TOPLEFT", 0, y)
	list:SetSize(PAGE_WIDTH, 30)
	local lines = {}
	local empty = Text(list, "GameFontHighlight", MUTED)
	empty:SetPoint("TOPLEFT", 10, -8)
	empty:SetWidth(PAGE_WIDTH - 20)
	empty:SetText(L.GOALS_NONE_HINT)
	local function Line(i)
		if lines[i] then return lines[i] end
		local line = CreateFrame("Button", nil, list)
		line:SetSize(PAGE_WIDTH, 32)
		line:SetPoint("TOPLEFT", 0, -(i - 1) * 34)
		Highlight(line)
		line.icon = Icon(line, 22)
		line.icon:SetPoint("LEFT", 10, 0)
		line.remove = CreateFrame("Button", nil, line)
		line.remove:SetSize(26, 26)
		line.remove:SetPoint("RIGHT", -6, 0)
		local cross = line.remove:CreateFontString(nil, "ARTWORK")
		cross:SetFont(GameFontNormal:GetFont(), 18, "")
		cross:SetPoint("CENTER", 0, 1)
		cross:SetText("×")
		cross:SetTextColor(unpack(MUTED))
		line.remove:SetScript("OnEnter", function() cross:SetTextColor(1, 0.4, 0.35) end)
		line.remove:SetScript("OnLeave", function() cross:SetTextColor(unpack(MUTED)) end)
		line.remove:SetScript("OnClick", function()
			if line.goal then ns.SetGoal(line.goal.id, 0) end
			Click()
		end)
		line.count = Text(line, "GameFontHighlight", ACCENT)
		line.count:SetPoint("RIGHT", line.remove, "LEFT", -8, 0)
		line.count:SetJustifyH("RIGHT")
		line.name = Text(line)
		line.name:SetPoint("LEFT", line.icon, "RIGHT", 10, 0)
		line.name:SetPoint("RIGHT", line.count, "LEFT", -10, 0)
		line.name:SetWordWrap(false)
		line:SetScript("OnClick", function()
			if line.goal and editor then editor.Edit(line.goal) end
		end)
		lines[i] = line
		return line
	end
	list.Refresh = function()
		local goals = ns.Goals()
		empty:SetShown(#goals == 0)
		for i, goal in ipairs(goals) do
			local line = Line(i)
			line.goal = goal
			line.icon:SetTexture(ns.ItemIcon(goal.id))
			line.name:SetText(goal.link or ns.ItemName(goal.id))
			line.count:SetText(format("%d/%d", min(goal.have, goal.need), goal.need))
			line.count:SetTextColor(unpack(goal.done and { 0.35, 0.85, 0.4 } or ACCENT))
			line:Show()
		end
		for i = #goals + 1, #lines do
			lines[i]:Hide()
			lines[i].goal = nil
		end
		local height = max(#goals * 34, 30)
		list:SetHeight(height)
		page:SetHeight(-y + height + 12)
	end
	list.lines = lines
	list.setting = "goals"
	table.insert(page.controls, list)
end

-- A note on a player: their name (or your target's) and what to call them
local noteEditor
local function NoteEditor(page, y)
	local row = CreateFrame("Frame", nil, page)
	row:SetSize(PAGE_WIDTH, 40)
	row:SetPoint("TOPLEFT", 0, y)
	local add = CreateFrame("Button", nil, row)
	add:SetSize(84, 26)
	add:SetPoint("RIGHT", -10, 0)
	Rect(add, "BACKGROUND", ACCENT[1], ACCENT[2], ACCENT[3], 0.18):SetAllPoints()
	Highlight(add, 0.08)
	local addText = add:CreateFontString(nil, "ARTWORK")
	Fancy(addText, 13)
	addText:SetTextColor(unpack(ACCENT))
	add:SetFontString(addText)
	add:SetText(L.ADD)
	local name = Box(row, 200, false, L.NOTE_NAME_PLACEHOLDER)
	name:SetPoint("LEFT", 10, 0)
	local note = Box(row, 10, false, L.NOTE_TEXT_PLACEHOLDER)
	note:SetMaxLetters(60)
	note:SetPoint("LEFT", name, "RIGHT", 6, 0)
	note:SetPoint("RIGHT", add, "LEFT", -6, 0)
	local function Add()
		local who = strtrim(name:GetText() or "")
		if who == "" then
			ns.Print(L.NOTE_NEED_NAME)
			name:SetFocus()
			return
		end
		local text = strtrim(note:GetText() or "")
		if text == "" then
			ns.Print(L.NOTE_NEED_TEXT)
			note:SetFocus()
			return
		end
		ns.SetNote(who, text)
		name:SetText("")
		note:SetText("")
		name:ClearFocus()
		note:ClearFocus()
		Click()
	end
	add:SetScript("OnClick", Add)
	name:SetScript("OnEnterPressed", function() note:SetFocus() end)
	note:SetScript("OnEnterPressed", Add)
	row.Refresh = function() end
	row.Edit = function(entry)
		name:SetText(entry.name)
		note:SetText(entry.note)
		note:SetFocus()
	end
	row.Target = function()
		local who = ns.IsOtherPlayer("target") and ns.UnitFullName("target")
		if not who then
			ns.Print(L.NOTE_NO_TARGET)
			return
		end
		name:SetText(who)
		local entry = ns.Note(who)
		note:SetText(entry and entry.note or "")
		note:SetFocus()
	end
	row.name, row.note, row.add = name, note, add
	row.setting = "note editor"
	noteEditor = row
	table.insert(page.controls, row)
	return y - 44
end

-- The noted players, the last seen first: click one to change it, × to take it off
local function NoteList(page, y)
	local list = CreateFrame("Frame", nil, page)
	list:SetPoint("TOPLEFT", 0, y)
	list:SetSize(PAGE_WIDTH, 30)
	local lines = {}
	local empty = Text(list, "GameFontHighlight", MUTED)
	empty:SetPoint("TOPLEFT", 10, -8)
	empty:SetWidth(PAGE_WIDTH - 20)
	empty:SetText(L.NOTES_NONE_HINT)
	local function Line(i)
		if lines[i] then return lines[i] end
		local line = CreateFrame("Button", nil, list)
		line:SetSize(PAGE_WIDTH, 38)
		line:SetPoint("TOPLEFT", 0, -(i - 1) * 40)
		Highlight(line)
		line.remove = CreateFrame("Button", nil, line)
		line.remove:SetSize(26, 26)
		line.remove:SetPoint("RIGHT", -6, 0)
		local cross = line.remove:CreateFontString(nil, "ARTWORK")
		cross:SetFont(GameFontNormal:GetFont(), 18, "")
		cross:SetPoint("CENTER", 0, 1)
		cross:SetText("×")
		cross:SetTextColor(unpack(MUTED))
		line.remove:SetScript("OnEnter", function() cross:SetTextColor(1, 0.4, 0.35) end)
		line.remove:SetScript("OnLeave", function() cross:SetTextColor(unpack(MUTED)) end)
		line.remove:SetScript("OnClick", function()
			if line.entry then ns.SetNote(line.entry.name, "") end
			Click()
		end)
		line.who = Text(line)
		line.who:SetPoint("TOPLEFT", 10, -4)
		line.note = Text(line, "GameFontHighlight", { 1, 0.55, 0.15 })
		line.note:SetPoint("LEFT", line.who, "RIGHT", 10, 0)
		line.note:SetPoint("RIGHT", line.remove, "LEFT", -8, 0)
		line.note:SetWordWrap(false)
		line.seen = Text(line, "GameFontHighlightSmall", MUTED)
		line.seen:SetPoint("BOTTOMLEFT", 10, 4)
		line:SetScript("OnClick", function()
			if line.entry and noteEditor then noteEditor.Edit(line.entry) end
		end)
		lines[i] = line
		return line
	end
	list.Refresh = function()
		local entries = {}
		for _, entry in pairs(ns.db.notes) do entries[#entries + 1] = entry end
		table.sort(entries, function(a, b)
			if (a.seen or 0) ~= (b.seen or 0) then return (a.seen or 0) > (b.seen or 0) end
			return a.name < b.name
		end)
		empty:SetShown(#entries == 0)
		for i, entry in ipairs(entries) do
			local line = Line(i)
			line.entry = entry
			line.who:SetText(ns.ClassColoured(entry))
			line.note:SetText(entry.note)
			line.seen:SetText(entry.seen and format(L.SEEN_AGO, ns.Ago(time() - entry.seen), entry.zone or "?") or L.SEEN_NEVER)
			line:Show()
		end
		for i = #entries + 1, #lines do
			lines[i]:Hide()
			lines[i].entry = nil
		end
		local height = max(#entries * 40, 30)
		list:SetHeight(height)
		page:SetHeight(-y + height + 12)
	end
	list.lines = lines
	list.setting = "notes"
	table.insert(page.controls, list)
end

-- A block of lines that rebuilds itself from a list each time it's shown: { kind = section | big |
-- line | note | gap, left, right, leftColor, color, indent, tip = function(tooltip) }
local GREEN, RED = { 0.35, 0.85, 0.4 }, { 1, 0.4, 0.35 }
local function ReportBlock(page, y, build, key)
	local block = CreateFrame("Frame", nil, page)
	block:SetPoint("TOPLEFT", 0, y)
	block:SetSize(PAGE_WIDTH, 30)
	local rows = {}
	local function Line(i)
		if rows[i] then return rows[i] end
		local row = CreateFrame("Button", nil, block)
		row:SetWidth(PAGE_WIDTH)
		Highlight(row, 0.03)
		row.left = Text(row)
		row.right = Text(row)
		row.right:SetJustifyH("RIGHT")
		row.rule = Rect(row, "ARTWORK", ACCENT[1], ACCENT[2], ACCENT[3], 0.25)
		row.rule:SetHeight(1)
		row:SetScript("OnEnter", function(self)
			if not self.tip then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			self.tip(GameTooltip)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		rows[i] = row
		return row
	end
	block.Refresh = function()
		local spec = build()
		local top = 0
		for i, r in ipairs(spec) do
			local row = Line(i)
			row.tip, row.spec = r.tip, r
			row.left:ClearAllPoints()
			row.right:ClearAllPoints()
			row.rule:Hide()
			row.right:SetText(r.right or "")
			row.right:SetTextColor(unpack(r.color or TEXT))
			row.left:SetText(r.left or "")
			row.left:SetTextColor(unpack(r.leftColor or TEXT))
			row.left:SetWordWrap(r.kind == "note")
			local height
			if r.kind == "section" then
				Fancy(row.left, 14)
				row.left:SetTextColor(unpack(ACCENT))
				row.left:SetWidth(0)
				row.left:SetPoint("LEFT", 10, -4)
				row.rule:ClearAllPoints()
				row.rule:SetPoint("LEFT", row.left, "RIGHT", 10, 0)
				row.rule:SetPoint("RIGHT", row, "RIGHT", -10, 0)
				row.rule:Show()
				height = 36
			elseif r.kind == "note" then
				row.left:SetFont(GameFontNormal:GetFont(), 11, "")
				row.left:SetTextColor(unpack(MUTED))
				row.left:SetWidth(PAGE_WIDTH - 20)
				row.left:SetPoint("TOPLEFT", 10, -3)
				height = ceil(row.left:GetStringHeight() or 14) + 8
			elseif r.kind == "gap" then
				height = 8
			else
				local size = r.kind == "big" and 16 or 13
				row.left:SetFont(GameFontNormal:GetFont(), size, "")
				row.right:SetFont(GameFontNormal:GetFont(), size, "")
				row.left:SetWidth(PAGE_WIDTH - 200)
				row.left:SetPoint("LEFT", r.indent and 26 or 10, 0)
				row.right:SetPoint("RIGHT", -10, 0)
				height = r.kind == "big" and 28 or 20
			end
			row:SetHeight(height)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -top)
			row:Show()
			top = top + height
		end
		for i = #spec + 1, #rows do
			rows[i]:Hide()
			rows[i].tip, rows[i].spec = nil, nil
		end
		block:SetHeight(max(top, 30))
		page:SetHeight(-y + top + 12)
	end
	block.rows = rows
	block.setting = key
	table.insert(page.controls, block)
end

local function Signed(copper)
	return (copper > 0 and "+" or "") .. ns.Money(copper)
end

-- The money of a day, came in and went out, as rows (or tooltip lines)
local function MoneyLines(day, add)
	local came, went = {}, {}
	for _, kind in ipairs(ns.MONEY_KINDS) do
		local m = day.money[kind]
		local label = kind == "quest" and day.quests > 0 and format(L.MONEY_QUESTS, day.quests) or L.MONEY_IN[kind]
		if m.inc > 0 then came[#came + 1] = { label, m.inc } end
		if m.out > 0 then went[#went + 1] = { L.MONEY_OUT[kind], m.out } end
	end
	if #came > 0 then add(L.DAY_INCOME, nil, true) end
	for _, c in ipairs(came) do add(c[1], "+" .. ns.Money(c[2]), false, GREEN) end
	if #went > 0 then add(L.DAY_SPENT, nil, true) end
	for _, w in ipairs(went) do add(w[1], "-" .. ns.Money(w[2]), false, RED) end
end

local function DayCounts(day)
	local parts = {}
	local kills = max(day.kills, day.mobs)
	if kills > 0 then parts[#parts + 1] = format(L.DAY_KILLS, kills) end
	local nodes = 0
	for _, n in pairs(day.gathers) do nodes = nodes + n end
	if nodes > 0 then parts[#parts + 1] = format(L.DAY_NODES, nodes) end
	if day.quests > 0 then parts[#parts + 1] = format(L.DAY_QUESTS, day.quests) end
	if day.xp > 0 then parts[#parts + 1] = format(L.DAY_XP, ns.Short(day.xp)) end
	local sessions = 0
	local function During(s) return s and s.started >= day.started and (not day.ended or s.started <= day.ended) end
	if During(ns.char.current) then sessions = sessions + 1 end
	for _, s in ipairs(ns.char.history) do
		if During(s) then sessions = sessions + 1 end
	end
	if sessions > 0 then parts[#parts + 1] = format(L.DAY_SESSIONS, sessions) end
	return table.concat(parts, "  ·  ")
end

local function DayZones(day)
	local list = {}
	for zone, n in pairs(day.zones) do list[#list + 1] = { zone, n } end
	table.sort(list, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
	local names = {}
	for i = 1, min(#list, 5) do names[i] = list[i][1] end
	return table.concat(names, ", ")
end

-- The day as rows: the gold, where it came from and went, the loot, the rest; then the days before
local function DayRows()
	local rows = {}
	-- Day.lua is a newer file: until the game restarts it isn't there
	if not ns.Day then return { { kind = "note", left = L.NEEDS_RESTART } } end
	local day = ns.Day()
	if day then
		local played = ns.DayPlayed(day)
		local net = ns.DayNet(day)
		local hour = ns.PerHour(net, played)
		table.insert(rows, { kind = "line", left = format(L.DAY_STARTED, date("%d/%m %H:%M", day.started)),
			right = format(L.DAY_PLAYED, ns.Clock(played)), leftColor = MUTED, color = MUTED })
		table.insert(rows, { kind = "big", left = L.DAY_NET, right = Signed(net), color = net < 0 and RED or GREEN })
		if hour then table.insert(rows, { kind = "line", left = L.DAY_NET_HOUR, right = Signed(hour) }) end
		local now = day.moneyStart + net
		table.insert(rows, { kind = "line", left = L.DAY_GOLD_NOW,
			right = format(L.DAY_GOLD_NOW_VALUE, ns.Money(now), ns.Money(day.moneyStart)), color = MUTED })
		MoneyLines(day, function(left, right, header, colour)
			table.insert(rows, header and { kind = "line", left = left, leftColor = MUTED }
				or { kind = "line", left = left, right = right, color = colour, indent = true })
		end)
		local loot = ns.DayLootWorth(day)
		if loot.total > 0 then
			table.insert(rows, { kind = "gap" })
			table.insert(rows, { kind = "big", left = L.DAY_LOOT, right = ns.Money(loot.total) })
			for i, family in ipairs(loot.families) do
				if i > 6 then break end
				if not family.skip and family.value > 0 then
					table.insert(rows, { kind = "line", indent = true, left = format("%s  |cff9da3ad%d|r", L.CATEGORY[family.key], family.count),
						right = ns.Money(family.value, true), tip = function(tip)
							tip:AddLine(L.CATEGORY[family.key], ACCENT[1], ACCENT[2], ACCENT[3])
							for j, item in ipairs(family.items) do
								if j > 12 then break end
								tip:AddDoubleLine(format("%d × %s", item.count, item.link or ns.ItemName(item.id)), ns.Money(item.value),
									1, 1, 1, 1, 1, 1)
							end
						end })
				end
			end
			table.insert(rows, { kind = "note", left = L.DAY_LOOT_NOTE })
		end
		local reps = ns.RepList and ns.RepList(day) or {}
		if #reps > 0 then
			table.insert(rows, { kind = "gap" })
			table.insert(rows, { kind = "big", left = L.DAY_REP })
			for _, rep in ipairs(reps) do
				local d = rep.data
				table.insert(rows, { kind = "line", indent = true, left = rep.name, leftColor = ns.StandingColour(d and d.reaction),
					right = ns.Signed(rep.delta) .. (d and "  ·  " .. ns.StandingName(d.reaction) or ""), color = rep.delta < 0 and RED or GREEN })
			end
		end
		local counts = DayCounts(day)
		if counts ~= "" then table.insert(rows, { kind = "line", left = counts, leftColor = MUTED }) end
		local zones = DayZones(day)
		if zones ~= "" then table.insert(rows, { kind = "line", left = format(L.DAY_ZONES, zones), leftColor = MUTED }) end
	end
	-- The days before
	table.insert(rows, { kind = "section", left = L.SEC_DAYS })
	if #ns.char.days == 0 then table.insert(rows, { kind = "note", left = L.DAYS_NONE }) end
	for _, past in ipairs(ns.char.days) do
		local net = ns.DayNet(past)
		local loot = ns.DayLootWorth(past).total
		table.insert(rows, { kind = "line",
			left = format("%s  ·  %s", date("%d/%m %H:%M", past.started), ns.Clock(past.played)),
			right = format(L.DAY_LINE_RIGHT, Signed(net), ns.Money(loot, true)), color = net < 0 and RED or GREEN,
			tip = function(tip)
				tip:AddLine(format(L.DAY_STARTED, date("%d/%m %H:%M", past.started)), ACCENT[1], ACCENT[2], ACCENT[3])
				tip:AddDoubleLine(L.DAY_NET, Signed(net), 1, 1, 1, 1, 1, 1)
				MoneyLines(past, function(left, right, header)
					if header then tip:AddLine(left, MUTED[1], MUTED[2], MUTED[3]) else tip:AddDoubleLine("  " .. left, right, 1, 1, 1, 1, 1, 1) end
				end)
				tip:AddDoubleLine(L.DAY_LOOT, ns.Money(loot), 1, 1, 1, 1, 1, 1)
				for _, rep in ipairs(ns.RepList and ns.RepList(past) or {}) do tip:AddDoubleLine("  " .. rep.name, ns.Signed(rep.delta), 1, 1, 1, 1, 1, 1) end
				local counts = DayCounts(past)
				if counts ~= "" then tip:AddLine(counts, MUTED[1], MUTED[2], MUTED[3]) end
				local zones = DayZones(past)
				if zones ~= "" then tip:AddLine(format(L.DAY_ZONES, zones), MUTED[1], MUTED[2], MUTED[3], true) end
			end })
	end
	return rows
end

-- Past sessions, the last first, valued with today's prices
local function HistoryList(page, y)
	local list = CreateFrame("Frame", nil, page)
	list:SetPoint("TOPLEFT", 0, y)
	list:SetSize(PAGE_WIDTH, 30)
	local lines = {}
	local empty = Text(list, "GameFontHighlight", MUTED)
	empty:SetPoint("TOPLEFT", 10, -8)
	empty:SetText(L.HISTORY_EMPTY)
	local function ShowTip(line)
		local s = line.session
		if not s then return end
		local worth = ns.Appraise(s)
		GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
		GameTooltip:AddLine(line.when:GetText(), ACCENT[1], ACCENT[2], ACCENT[3])
		if ns.Kills(s) > 0 then GameTooltip:AddDoubleLine(L.TIP_KILLS, ns.Kills(s), 1, 1, 1, 1, 1, 1) end
		for _, rep in ipairs(ns.RepList and ns.RepList(s) or {}) do GameTooltip:AddDoubleLine(rep.name, ns.Signed(rep.delta), 1, 1, 1, 1, 1, 1) end
		if worth.money > 0 then GameTooltip:AddDoubleLine(L.LOOTED_GOLD, ns.Money(worth.money), 1, 1, 1, 1, 1, 1) end
		for _, family in ipairs(worth.families) do
			if not family.skip then
				GameTooltip:AddDoubleLine(format("%s (%d)", L.CATEGORY[family.key], family.count), ns.Money(family.value),
					1, 1, 1, 1, 1, 1)
			end
		end
		GameTooltip:Show()
	end
	local function Line(i)
		if lines[i] then return lines[i] end
		local line = CreateFrame("Button", nil, list)
		line:SetSize(PAGE_WIDTH, 40)
		line:SetPoint("TOPLEFT", 0, -(i - 1) * 42)
		Highlight(line)
		line.when = Text(line)
		line.when:SetPoint("TOPLEFT", 10, -5)
		line.total = Text(line, "GameFontHighlight", ACCENT)
		line.total:SetPoint("TOPRIGHT", -10, -5)
		line.total:SetJustifyH("RIGHT")
		line.detail = Text(line, "GameFontHighlightSmall", MUTED)
		line.detail:SetPoint("BOTTOMLEFT", 10, 5)
		line.detail:SetPoint("BOTTOMRIGHT", -10, 5)
		line:SetScript("OnEnter", ShowTip)
		line:SetScript("OnLeave", GameTooltip_Hide)
		lines[i] = line
		return line
	end
	list.Refresh = function()
		local history = ns.char.history
		empty:SetShown(#history == 0)
		for i, s in ipairs(history) do
			local line = Line(i)
			local worth = ns.Appraise(s)
			local hour = ns.PerHour(worth.total, s.elapsed)
			line.session = s
			line.when:SetText(format("%s  ·  %s", date("%d/%m %H:%M", s.started), s.zone ~= "" and s.zone or "?"))
			line.total:SetText(ns.Money(worth.total))
			local best = {}
			for _, family in ipairs(worth.families) do
				if #best < 3 and not family.skip and family.value > 0 then best[#best + 1] = L.CATEGORY[family.key] end
			end
			line.detail:SetText(format(L.HISTORY_DETAIL, ns.Clock(s.elapsed), hour and ns.Money(hour, true) or "-",
				#best > 0 and table.concat(best, ", ") or "-"))
			line:Show()
		end
		for i = #history + 1, #lines do
			lines[i]:Hide()
			lines[i].session = nil
		end
		local height = max(#history * 42, 30)
		list:SetHeight(height)
		page:SetHeight(-y + height + 12)
	end
	list.lines = lines
	list.setting = "history"
	table.insert(page.controls, list)
end

-- Pages and the menu

local function UpdateScrollBar()
	local range, height = scroll:GetVerticalScrollRange() or 0, scroll:GetHeight() or 0
	if range < 1 or height < 1 then
		scrollBar:Hide()
		return
	end
	local thumb = max(height * height / (height + range), 30)
	scrollBar.thumb:SetHeight(thumb)
	scrollBar.thumb:ClearAllPoints()
	scrollBar.thumb:SetPoint("TOP", 0, -(scroll:GetVerticalScroll() or 0) / range * (height - thumb))
	scrollBar:Show()
end

local function NewPage(key, title, icon)
	local page = CreateFrame("Frame", nil, scroll)
	page:SetSize(PAGE_WIDTH, 10)
	page:Hide()
	page.controls = {}
	page.key = key
	pages[#pages + 1] = page
	local tab = CreateFrame("Button", nil, window)
	tab:SetSize(SIDE, 38)
	tab:SetPoint("TOPLEFT", 0, -TOP - 12 - (#pages - 1) * 40)
	Highlight(tab)
	tab.selected = Rect(tab, "BACKGROUND", ACCENT[1], ACCENT[2], ACCENT[3], 0.12)
	tab.selected:SetAllPoints()
	tab.bar = Rect(tab, "ARTWORK", unpack(ACCENT))
	tab.bar:SetPoint("TOPLEFT")
	tab.bar:SetPoint("BOTTOMLEFT")
	tab.bar:SetWidth(3)
	tab.icon = Icon(tab, 22, icon)
	tab.icon:SetPoint("LEFT", 18, 0)
	tab.label = tab:CreateFontString(nil, "ARTWORK")
	Fancy(tab.label, 15)
	tab.label:SetPoint("LEFT", tab.icon, "RIGHT", 10, 0)
	tab.label:SetText(title)
	tab.title = title
	tab:SetScript("OnClick", function()
		ns.ShowOptionsPage(key)
		Click()
	end)
	tab.key = key
	tabs[#tabs + 1] = tab
	return page, -4
end

-- The page is as tall as what's on it, so the window scrolls when it doesn't fit
local function Done(page, y)
	page:SetHeight(-y + 12)
end

function ns.ShowOptionsPage(key)
	for i, page in ipairs(pages) do
		local on = page.key == key
		local tab = tabs[i]
		page:SetShown(on)
		tab.selected:SetShown(on)
		tab.bar:SetShown(on)
		tab.label:SetTextColor(unpack(on and TEXT or MUTED))
		-- Text set while the game was still loading the round font can come out blank: set it again,
		-- in the game's own font if the round one draws nothing
		tab.label:SetText(tab.title)
		if (tab.label:GetStringWidth() or 0) < 1 then
			tab.label:SetFont(GameFontNormal:GetFont(), 15, "")
			tab.label:SetText(tab.title)
		end
		if on then
			scroll:SetScrollChild(page)
			scroll:SetVerticalScroll(0)
			for _, control in ipairs(page.controls) do control.Refresh() end
		end
	end
	window.page = key
	UpdateScrollBar()
end

local function RefreshPage(key)
	for _, page in ipairs(pages) do
		if page.key == key and page:IsShown() then
			for _, control in ipairs(page.controls) do control.Refresh() end
		end
	end
end
ns.RefreshOptionsPage = RefreshPage

local function BuildWindow()
	window = CreateFrame("Frame", "FarmGodOptions", UIParent)
	window:SetSize(WIDTH, HEIGHT)
	window:SetPoint("CENTER")
	window:SetFrameStrata("HIGH")
	window:SetToplevel(true)
	window:EnableMouse(true)
	window:SetMovable(true)
	window:SetClampedToScreen(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	table.insert(UISpecialFrames, "FarmGodOptions") -- Escape closes it

	local edge = Rect(window, "BACKGROUND", 0, 0, 0, 0.9, -8)
	edge:SetPoint("TOPLEFT", -1, 1)
	edge:SetPoint("BOTTOMRIGHT", 1, -1)
	Rect(window, "BACKGROUND", 0.06, 0.07, 0.09, 0.97, -7):SetAllPoints()
	local side = Rect(window, "BACKGROUND", 0.04, 0.05, 0.07, 0.98, -6)
	side:SetPoint("TOPLEFT")
	side:SetPoint("BOTTOMLEFT")
	side:SetWidth(SIDE)
	local head = Rect(window, "BACKGROUND", 0.04, 0.05, 0.07, 0.98, -6)
	head:SetPoint("TOPLEFT")
	head:SetPoint("TOPRIGHT")
	head:SetHeight(TOP)
	local headLine = Rect(window, "ARTWORK", ACCENT[1], ACCENT[2], ACCENT[3], 0.5)
	headLine:SetPoint("TOPLEFT", 0, -TOP)
	headLine:SetPoint("TOPRIGHT", 0, -TOP)
	headLine:SetHeight(1)
	local sideLine = Rect(window, "ARTWORK", 1, 1, 1, 0.06)
	sideLine:SetPoint("TOPLEFT", SIDE, -TOP - 1)
	sideLine:SetPoint("BOTTOMLEFT", SIDE, 0)
	sideLine:SetWidth(1)

	local logo = window:CreateTexture(nil, "ARTWORK")
	logo:SetSize(38, 38)
	logo:SetPoint("TOPLEFT", 16, -11)
	logo:SetTexture("Interface\\AddOns\\FarmGod\\media\\icon")
	local title = window:CreateFontString(nil, "ARTWORK")
	Fancy(title, 22)
	title:SetTextColor(unpack(TEXT))
	title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -1)
	title:SetText("FarmGod")
	local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	local version = GetMetadata and GetMetadata(addonName, "Version")
	local subtitle = Text(window, "GameFontHighlightSmall", MUTED)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -2)
	subtitle:SetText(version and L.SUBTITLE .. "  ·  v" .. version or L.SUBTITLE)

	local close = CreateFrame("Button", nil, window)
	close:SetSize(32, 32)
	close:SetPoint("TOPRIGHT", -12, -14)
	Highlight(close, 0.08)
	local cross = close:CreateFontString(nil, "ARTWORK")
	cross:SetFont(GameFontNormal:GetFont(), 22, "")
	cross:SetPoint("CENTER", 0, 1)
	cross:SetText("×")
	cross:SetTextColor(unpack(MUTED))
	close:SetScript("OnEnter", function() cross:SetTextColor(1, 0.4, 0.35) end)
	close:SetScript("OnLeave", function() cross:SetTextColor(unpack(MUTED)) end)
	close:SetScript("OnClick", function() window:Hide() end)

	scroll = CreateFrame("ScrollFrame", nil, window)
	scroll:SetPoint("TOPLEFT", SIDE + 16, -TOP - 8)
	scroll:SetPoint("BOTTOMRIGHT", -24, 10)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange() or 0
		self:SetVerticalScroll(min(max((self:GetVerticalScroll() or 0) - delta * 40, 0), range))
		UpdateScrollBar()
	end)
	scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
	scrollBar = CreateFrame("Frame", nil, window)
	scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 10, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 10, 0)
	scrollBar:SetWidth(4)
	Rect(scrollBar, "BACKGROUND", 1, 1, 1, 0.06):SetAllPoints()
	scrollBar.thumb = Rect(scrollBar, "ARTWORK", ACCENT[1], ACCENT[2], ACCENT[3], 0.6)
	scrollBar.thumb:SetWidth(4)
	scrollBar:Hide()
end

StaticPopupDialogs.FARMGOD_CLEAR_GOALS = {
	text = L.GOALS_CLEAR_CONFIRM,
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function() ns.ClearGoals() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs.FARMGOD_NEW_DAY = {
	text = L.NEW_DAY_CONFIRM,
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function()
		if ns.NewDay then ns.NewDay() end
		ns.Print(L.NEW_DAY_DONE)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs.FARMGOD_CLEAR_HISTORY = {
	text = L.CLEAR_CONFIRM,
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function() ns.ClearHistory() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function Build()
	local db = ns.db
	BuildWindow()
	local function Tracker() ns.UpdateTracker() end

	-- The session and its window
	local session, tracker = db.session, db.tracker
	local page, y = NewPage("session", L.TAB_SESSION, "Interface\\Icons\\INV_Misc_Coin_01")
	y = Section(page, y, L.SEC_SESSION)
	y = Action(page, y, L.OPT_TOGGLE, function()
		local state = ns.SessionState()
		return state == "running" and L.BTN_PAUSE or (state == "paused" and L.BTN_RESUME or L.BTN_START)
	end, ns.ToggleSession)
	y = Action(page, y, L.OPT_END, L.BTN_STOP, ns.EndSession)
	y = Action(page, y, L.OPT_RESET, L.BTN_RESET, function()
		if ns.SessionState() ~= "idle" then StaticPopup_Show("FARMGOD_RESET") end
	end)
	y = Check(page, y, L.OPT_AUTO_START, function() return session.autoStart end,
		function(v) session.autoStart = v Tracker() end)
	y = Slider(page, y, L.OPT_IDLE, 0, 30, 1, function() return session.idleMinutes end,
		function(v) session.idleMinutes = v end)
	y = Slider(page, y, L.OPT_BIG_LOOT, 0, 100, 1, function() return session.bigLoot end,
		function(v) session.bigLoot = v end)
	y = Hint(page, y, L.SESSION_HINT)
	y = Section(page, y, L.SEC_WINDOW)
	y = Check(page, y, L.OPT_SHOW, function() return tracker.shown end, function(v) tracker.shown = v Tracker() end)
	y = Check(page, y, L.OPT_ONLY_ACTIVE, function() return tracker.onlyActive end,
		function(v) tracker.onlyActive = v Tracker() end)
	y = Check(page, y, L.OPT_LOCKED, function() return tracker.locked end, function(v) tracker.locked = v end)
	y = Check(page, y, L.OPT_REP, function() return tracker.rep end, function(v) tracker.rep = v Tracker() end)
	y = Check(page, y, L.OPT_KILLS, function() return tracker.kills end, function(v) tracker.kills = v Tracker() end)
	y = Check(page, y, L.OPT_COUNTS, function() return tracker.counts end, function(v) tracker.counts = v Tracker() end)
	y = Slider(page, y, L.OPT_WIDTH, 180, 420, 5, function() return tracker.width end,
		function(v) tracker.width = v Tracker() end)
	y = Slider(page, y, L.OPT_SCALE, 60, 160, 5, function() return tracker.scale end,
		function(v) tracker.scale = v Tracker() end)
	y = Slider(page, y, L.OPT_ALPHA, 0, 100, 5, function() return tracker.alpha end,
		function(v) tracker.alpha = v Tracker() end)
	y = Slider(page, y, L.OPT_ROWS, 1, #ns.CATEGORY_ORDER + 1, 1, function() return tracker.rows end,
		function(v) tracker.rows = v Tracker() end)
	Done(page, y)

	-- Goals: so many of an item, as a quest's objectives
	local goals = db.goals
	page, y = NewPage("goals", L.TAB_GOALS, "Interface\\Icons\\INV_Misc_Note_01")
	y = Section(page, y, L.SEC_GOAL_ADD)
	y = GoalEditor(page, y)
	y = Hint(page, y, L.GOAL_ADD_HINT)
	y = Section(page, y, L.SEC_GOAL_OPTIONS)
	y = Check(page, y, L.OPT_GOAL_ANNOUNCE, function() return goals.announce end, function(v) goals.announce = v end)
	y = Check(page, y, L.OPT_GOAL_BANK, function() return goals.bank end, function(v) goals.bank = v ns.CheckGoals() end)
	y = Action(page, y, L.OPT_GOALS_CLEAR, L.CLEAR, function()
		if #ns.char.goals > 0 then StaticPopup_Show("FARMGOD_CLEAR_GOALS") end
	end)
	y = Section(page, y, L.SEC_GOALS)
	GoalList(page, y)

	-- Notes on players: who farms your layer
	local alerts = db.noteAlerts
	page, y = NewPage("notes", L.TAB_NOTES, "Interface\\Icons\\INV_Misc_Note_02")
	y = Section(page, y, L.SEC_NOTE_ADD)
	y = NoteEditor(page, y)
	y = Action(page, y, L.OPT_NOTE_TARGET, L.USE_TARGET, function() noteEditor.Target() end)
	y = Hint(page, y, L.NOTE_ADD_HINT)
	y = Section(page, y, L.SEC_NOTE_ALERTS)
	y = Check(page, y, L.OPT_NOTE_ALERT, function() return alerts.enabled end, function(v) alerts.enabled = v end)
	y = Check(page, y, L.OPT_NOTE_CENTER, function() return alerts.center end, function(v) alerts.center = v end)
	y = Check(page, y, L.OPT_NOTE_SOUND, function() return alerts.sound end, function(v) alerts.sound = v end)
	y = Slider(page, y, L.OPT_NOTE_MINUTES, 1, 30, 1, function() return alerts.minutes end,
		function(v) alerts.minutes = v end)
	y = Check(page, y, L.OPT_NOTE_NEAR, function() return alerts.near end, function(v) alerts.near = v Tracker() end)
	y = Slider(page, y, L.OPT_NOTE_NEAR_MINUTES, 1, 60, 1, function() return alerts.nearMinutes end,
		function(v) alerts.nearMinutes = v Tracker() end)
	y = Action(page, y, L.OPT_LAYER, L.CLEAR, function()
		ns.LayerChanged()
		ns.Print(L.LAYER_CLEARED)
	end)
	y = Hint(page, y, L.NOTE_ALERT_HINT)
	y = Section(page, y, L.SEC_NOTES)
	NoteList(page, y)

	-- The playing day: all the gold of the time you play, sessions or not
	page, y = NewPage("day", L.TAB_DAY, "Interface\\Icons\\INV_Misc_PocketWatch_01")
	y = Section(page, y, L.SEC_DAY)
	y = Action(page, y, L.OPT_NEW_DAY, L.NEW, function() StaticPopup_Show("FARMGOD_NEW_DAY") end)
	y = Slider(page, y, L.OPT_DAY_GAP, 1, 12, 1, function() return db.day.gapHours end,
		function(v) db.day.gapHours = v end)
	ReportBlock(page, y, DayRows, "day report")

	-- Prices
	local prices = db.prices
	local function PricesChanged()
		ns.Changed()
		RefreshPage("prices")
	end
	page, y = NewPage("prices", L.TAB_PRICES, "Interface\\Icons\\INV_Misc_Coin_02")
	y = Section(page, y, L.SEC_SOURCE)
	y = Choice(page, y, L.OPT_SOURCE, {
		{ "auto", L.SOURCE.auto }, { "auctionator", "Auctionator" }, { "tsm", "TradeSkillMaster" }, { "vendor", L.SOURCE.vendor },
	}, function() return prices.source end, function(v) prices.source = v PricesChanged() end)
	local tsmChoices = {}
	for _, key in ipairs(ns.TSM_SOURCES) do tsmChoices[#tsmChoices + 1] = { key, key } end
	y = Choice(page, y, L.OPT_TSM, tsmChoices, function() return prices.tsm end,
		function(v) prices.tsm = v PricesChanged() end)
	y = Status(page, y, function()
		local found = {}
		found[#found + 1] = format(L.FOUND, "Auctionator", ns.HasAuctionator() and L.YES or L.NO)
		found[#found + 1] = format(L.FOUND, "TSM", ns.HasTSM() and L.YES or L.NO)
		return table.concat(found, "   ·   ") .. "\n" .. ns.PriceSourceText()
	end)
	y = Section(page, y, L.SEC_VALUE)
	y = Check(page, y, L.OPT_BEST, function() return prices.best end, function(v) prices.best = v PricesChanged() end)
	y = Check(page, y, L.OPT_CUT, function() return prices.cut end, function(v) prices.cut = v PricesChanged() end)
	y = Check(page, y, L.OPT_FALLBACK, function() return prices.vendorFallback end,
		function(v) prices.vendorFallback = v PricesChanged() end)
	y = Action(page, y, L.OPT_REFRESH, L.REFRESH, function() ns.commands.prices() end)
	y = Hint(page, y, L.PRICES_HINT)
	Done(page, y)

	-- Families: how each one is valued
	page, y = NewPage("families", L.TAB_FAMILIES, ns.CategoryIcon("ore"))
	y = Section(page, y, L.SEC_FAMILIES)
	local modes = { { "auction", L.MODE.auction }, { "vendor", L.MODE.vendor }, { "skip", L.MODE.skip } }
	for _, key in ipairs(ns.CATEGORY_ORDER) do
		y = Choice(page, y, L.CATEGORY[key], modes, function() return db.categories[key] end,
			function(v) db.categories[key] = v ns.Changed() end, ns.CategoryIcon(key))
	end
	y = Hint(page, y, L.FAMILIES_HINT)
	Done(page, y)

	-- History
	page, y = NewPage("history", L.TAB_HISTORY, "Interface\\Icons\\INV_Misc_Book_09")
	y = Section(page, y, L.SEC_HISTORY)
	y = Action(page, y, L.OPT_CLEAR, L.CLEAR, function()
		if #ns.char.history > 0 then StaticPopup_Show("FARMGOD_CLEAR_HISTORY") end
	end)
	HistoryList(page, y)

	-- At the foot of the menu: moving the window and the minimap button
	local unlock = CreateFrame("Button", nil, window)
	unlock:SetSize(SIDE - 28, 30)
	unlock:SetPoint("BOTTOMLEFT", 14, 46)
	Rect(unlock, "BACKGROUND", ACCENT[1], ACCENT[2], ACCENT[3], 0.14):SetAllPoints()
	Highlight(unlock, 0.08)
	local unlockText = unlock:CreateFontString(nil, "ARTWORK")
	Fancy(unlockText, 13)
	unlockText:SetTextColor(unpack(ACCENT))
	unlock:SetFontString(unlockText)
	unlock:SetScript("OnClick", function()
		ns.SetUnlocked(not ns.unlocked)
		unlock:SetText(ns.unlocked and L.LOCK or L.UNLOCK)
	end)
	window.unlockButton = unlock
	local minimap = CreateFrame("CheckButton", nil, window)
	minimap:SetSize(SIDE - 20, 26)
	minimap:SetPoint("BOTTOMLEFT", 10, 12)
	Highlight(minimap)
	local switch, Paint = Switch(minimap, 28, 16)
	switch:SetPoint("LEFT", 4, 0)
	local minimapLabel = Text(minimap, "GameFontHighlightSmall", MUTED)
	minimapLabel:SetPoint("LEFT", switch, "RIGHT", 8, 0)
	minimapLabel:SetPoint("RIGHT", -4, 0)
	minimapLabel:SetText(L.OPT_MINIMAP_BUTTON)
	minimap:SetScript("OnClick", function(self)
		db.minimapButton.hide = not self:GetChecked()
		ns.UpdateMinimapButton()
		Paint()
		Click()
	end)
	window.minimapCheck = minimap
	window:SetScript("OnShow", function()
		minimap:SetChecked(not db.minimapButton.hide)
		Paint()
		unlock:SetText(ns.unlocked and L.LOCK or L.UNLOCK)
	end)
	window:Hide()
end

function ns.ToggleOptions(key)
	if not window then Build() end
	if window:IsShown() and not key then
		window:Hide()
		return
	end
	window:Show()
	ns.ShowOptionsPage(key or window.page or "session")
end

-- For the tests
function ns.OptionsWindow()
	return window, pages
end

ns.commands.options = function() ns.ToggleOptions() end
ns.commands.opciones = ns.commands.options
ns.commands.config = ns.commands.options
