local _, ns = ...
local L = ns.L

-- Goals: so many of an item (40 Thorium Ore, 2 Arcane Crystals...), counted in your bags as a
-- quest counts its objectives. Each time one goes up it says so in the middle of the screen, in
-- yellow, as quests do; when it's met, in green with the quest sound
local last = {} -- by item: the count last seen, to tell what went up (nil: not read yet)

local function Changed()
	if ns.Changed then ns.Changed() end
end

function ns.GoalCount(id)
	local bank = ns.db.goals.bank
	local count
	if C_Item and C_Item.GetItemCount then
		count = C_Item.GetItemCount(id, bank)
	elseif GetItemCount then
		count = GetItemCount(id, bank)
	end
	if type(count) ~= "number" or ns.IsSecret(count) then return last[id] or 0 end
	return count
end

local function LinkOf(id)
	local link = C_Item and C_Item.GetItemInfo and select(2, C_Item.GetItemInfo(id))
	return type(link) == "string" and link or nil
end

-- The goals as they stand: { id, need, have, done, link }
function ns.Goals()
	local list = {}
	for _, goal in ipairs(ns.char.goals) do
		local have = ns.GoalCount(goal.id)
		goal.link = goal.link or LinkOf(goal.id)
		list[#list + 1] = { id = goal.id, need = goal.need, have = have, done = have >= goal.need, link = goal.link }
	end
	return list
end

-- A new goal, or another amount for one you have; 0 takes it off
function ns.SetGoal(id, need, link)
	need = floor(tonumber(need) or 0)
	local goals = ns.char.goals
	for i, goal in ipairs(goals) do
		if goal.id == id then
			if need <= 0 then
				table.remove(goals, i)
				last[id] = nil
			else
				goal.need = need
				goal.link = link or goal.link
			end
			Changed()
			return true
		end
	end
	if need <= 0 then return false end
	table.insert(goals, { id = id, need = need, link = link or LinkOf(id) })
	last[id] = ns.GoalCount(id)
	Changed()
	return true
end

function ns.ClearGoals()
	wipe(ns.char.goals)
	wipe(last)
	Changed()
end

-- What you've looted of it this session and how long the rest would take at that pace
function ns.GoalPace(id, missing)
	local s = ns.char.current
	local got = s and s.items[id]
	if not got or got <= 0 then return nil end
	local hour = ns.PerHour(got, ns.Elapsed(s))
	local minutes = hour and missing > 0 and missing / hour * 60 or nil
	return got, hour, minutes
end

-- An item from what you typed: its id, a link, or its name (known to the game, in your bags, or
-- in a session)
function ns.ResolveItem(text)
	text = strtrim(text or "")
	if text == "" then return nil end
	local id = tonumber(text) or tonumber(text:match("item:(%d+)"))
	if id then return id, text:match("|H") and text or nil end
	local wanted = strlower(text:gsub("^%[", ""):gsub("%]$", ""))
	if C_Item and C_Item.GetItemInfo then
		local _, link = C_Item.GetItemInfo(text)
		if type(link) == "string" then return tonumber(link:match("item:(%d+)")), link end
	end
	local function Same(itemID, itemLink)
		local itemName = ns.ItemName(itemID, itemLink)
		return type(itemName) == "string" and strlower(itemName) == wanted
	end
	if C_Container and C_Container.GetContainerNumSlots then
		for bag = 0, NUM_BAG_SLOTS or 4 do
			for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
				local info = C_Container.GetContainerItemInfo(bag, slot)
				if info and info.itemID and Same(info.itemID, info.hyperlink) then return info.itemID, info.hyperlink end
			end
		end
	end
	local sessions = { ns.char.current }
	for _, s in ipairs(ns.char.history) do sessions[#sessions + 1] = s end
	for _, s in ipairs(sessions) do
		for itemID, itemLink in pairs(s.links) do
			if Same(itemID, itemLink) then return itemID, itemLink end
		end
	end
	return nil
end

local function Announce(goal, before, have)
	if not ns.db.goals.announce or before >= goal.need or have <= before then return false end
	local name = ns.ItemName(goal.id, goal.link)
	local shown = min(have, goal.need)
	local text = format("%s: %d/%d", name, shown, goal.need)
	if have >= goal.need then
		if UIErrorsFrame then UIErrorsFrame:AddMessage(text, 0.35, 0.85, 0.4) end
		if SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE then PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE) end
		ns.Print(format(L.GOAL_DONE, goal.link or name, goal.need))
		return true
	end
	if UIErrorsFrame then UIErrorsFrame:AddMessage(text, 1, 0.82, 0) end
	return false
end

function ns.CheckGoals()
	local finished, all = false, #ns.char.goals > 0
	for _, goal in ipairs(ns.char.goals) do
		local have = ns.GoalCount(goal.id)
		local before = last[goal.id]
		last[goal.id] = have
		if before and Announce(goal, before, have) then finished = true end
		if have < goal.need then all = false end
	end
	if finished and all and #ns.char.goals > 1 then ns.Print(L.GOALS_ALL_DONE) end
	Changed()
end

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_LOGIN")
ns.Listen(events, "BAG_UPDATE_DELAYED")
events:SetScript("OnEvent", function(_, event)
	if event == "BAG_UPDATE_DELAYED" then
		ns.CheckGoals()
	else
		-- The bags fill in after you log in: what's there then isn't progress
		C_Timer.After(3, function()
			for _, goal in ipairs(ns.char.goals) do
				if last[goal.id] == nil then last[goal.id] = ns.GoalCount(goal.id) end
			end
		end)
	end
end)

-- /farmgod goal 40 [Thorium Ore], or the item first; 0 takes it off; alone it lists them
local function Goal(rest)
	rest = strtrim(rest or "")
	if rest == "" then
		local goals = ns.Goals()
		if #goals == 0 then
			ns.Print(L.GOALS_NONE)
			return
		end
		ns.Print(L.GOALS_TITLE)
		for _, goal in ipairs(goals) do
			print(format("  %s: %d/%d%s", goal.link or ns.ItemName(goal.id), min(goal.have, goal.need), goal.need,
				goal.done and "  " .. L.GOAL_DONE_TAG or ""))
		end
		return
	end
	local lower = strlower(rest)
	if lower == "clear" or lower == "borrar" then
		ns.ClearGoals()
		ns.Print(L.GOALS_CLEARED)
		return
	end
	local amount, item = rest:match("^(%d+)%s+(.+)$")
	if not amount then item, amount = rest:match("^(.-)%s+(%d+)$") end
	if not amount then
		ns.Print(L.GOAL_USAGE)
		return
	end
	local id, link = ns.ResolveItem(item)
	if not id then
		ns.Print(format(L.GOAL_UNKNOWN, item))
		return
	end
	amount = tonumber(amount)
	ns.SetGoal(id, amount, link)
	local name = link or ns.ItemName(id)
	ns.Print(amount > 0 and format(L.GOAL_SET, amount, name) or format(L.GOAL_REMOVED, name))
end
ns.commands.goal = Goal
ns.commands.goals = Goal
ns.commands.objetivo = Goal
ns.commands.objetivos = Goal
