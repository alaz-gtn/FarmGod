local addonName, ns = ...
local L = ns.L

-- The crafting cost in item tooltips: what the materials of the cheapest recipe cost with
-- FarmGod's prices, against the item's own auction price, and the profession and skill it takes.
-- The recipes are in Recipes.lua (AtlasLoot Forever's data), so it works for professions none of
-- your characters has, with no recipe addon. Shift shows each material
local GOLD = { 0.95, 0.76, 0.31 }
local GREEN = { 0.35, 0.85, 0.4 }
local RED = { 1, 0.4, 0.35 }
local MUTED = { 0.58, 0.62, 0.68 }
local SHIFT_KEYS = { LSHIFT = true, RSHIFT = true }
-- The item tooltips it writes in: the usual one, a clicked link and the comparisons
local TOOLTIPS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2" }
local wanted = {}

-- What a vendor charges for it, when one sells it (thread, vials, flux...): Auctionator remembers
-- the merchants you've seen, TSM has its own list
local function VendorBuy(itemID)
	if ns.HasAuctionator() and type(Auctionator.API.v1.GetVendorPriceByItemID) == "function" then
		local ok, price = pcall(Auctionator.API.v1.GetVendorPriceByItemID, addonName, itemID)
		if ok and type(price) == "number" and price > 0 then return price end
	end
	if ns.HasTSM() then
		local ok, price = pcall(TSM_API.GetCustomPriceValue, "VendorBuy", "i:" .. itemID)
		if ok and type(price) == "number" and price > 0 then return price end
	end
end

-- A material: the cheaper of the auction house and a vendor that sells it; nil with no price
function ns.MaterialPrice(itemID)
	local auction, vendor = ns.AuctionPrice(itemID), VendorBuy(itemID)
	if auction and vendor then return min(auction, vendor) end
	return auction or vendor
end

-- One recipe { profession, skill, made, material, count, ... }: what one of what it makes costs
local function Cost(recipe)
	local made = recipe[3] and recipe[3] > 0 and recipe[3] or 1
	local parts, total, missing = {}, 0, 0
	for i = 4, #recipe - 1, 2 do
		local id, count = recipe[i], recipe[i + 1]
		local price = ns.MaterialPrice(id)
		parts[#parts + 1] = { id = id, count = count, price = price }
		if price then total = total + price * count else missing = missing + 1 end
	end
	return { profession = recipe[1], skill = recipe[2], made = made, parts = parts, missing = missing,
		total = total, each = total / made }
end

-- The cheapest recipe with every material priced, or the first one if none has them all:
-- { profession, skill, made, parts, missing, each, recipes }
function ns.CraftCost(itemID)
	local recipes = ns.RECIPES and ns.RECIPES[itemID]
	if not recipes or #recipes == 0 then return nil end
	local best, first
	for _, recipe in ipairs(recipes) do
		local cost = Cost(recipe)
		first = first or cost
		if cost.missing == 0 and (not best or cost.each < best.each) then best = cost end
	end
	local result = best or first
	result.recipes = #recipes
	return result
end

local function ItemOf(tooltip, data)
	if type(data) == "table" and type(data.id) == "number" and not ns.IsSecret(data.id) then return data.id end
	if tooltip.GetItem then
		local ok, _, link = pcall(tooltip.GetItem, tooltip)
		if ok and type(link) == "string" and not ns.IsSecret(link) then return tonumber(link:match("item:(%d+)")) end
	end
end

local function Lines(tooltip, data)
	if not ns.db or not ns.db.craft.enabled or not wanted[tooltip] then return end
	local itemID = ItemOf(tooltip, data)
	local cost = itemID and ns.CraftCost(itemID)
	if not cost then return end
	tooltip:AddLine(" ")
	if cost.missing > 0 then
		tooltip:AddDoubleLine(L.CRAFT_COST, L.TAG_NO_PRICE, GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)
	else
		tooltip:AddDoubleLine(L.CRAFT_COST, ns.Money(cost.each), GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)
		local auction = ns.AuctionPrice(itemID)
		if auction then
			local gain = auction - cost.each
			local colour = gain >= 0 and GREEN or RED
			tooltip:AddDoubleLine(format(L.CRAFT_VS_AH, ns.Money(auction)),
				format(gain >= 0 and L.CRAFT_CHEAPER or L.CRAFT_DEARER, ns.Money(abs(gain))),
				MUTED[1], MUTED[2], MUTED[3], colour[1], colour[2], colour[3])
		end
	end
	local recipe = format("%s %d", L.PROFESSION[cost.profession] or "?", cost.skill)
	if cost.made > 1 then recipe = recipe .. "  ·  " .. format(L.CRAFT_MAKES, cost.made) end
	tooltip:AddDoubleLine(L.CRAFT_RECIPE, recipe, MUTED[1], MUTED[2], MUTED[3], MUTED[1], MUTED[2], MUTED[3])
	if IsShiftKeyDown() then
		for _, part in ipairs(cost.parts) do
			tooltip:AddDoubleLine("  " .. ns.ItemName(part.id),
				part.price and format("%d × %s", part.count, ns.Money(part.price)) or format("%d × %s", part.count, L.TAG_NO_PRICE),
				0.9, 0.9, 0.9, 1, 1, 1)
		end
		if cost.made > 1 then tooltip:AddLine(format(L.CRAFT_PER_UNIT, cost.made), MUTED[1], MUTED[2], MUTED[3]) end
		if cost.recipes > 1 then tooltip:AddLine(format(L.CRAFT_CHEAPEST, cost.recipes), MUTED[1], MUTED[2], MUTED[3]) end
	else
		tooltip:AddLine(L.CRAFT_SHIFT, MUTED[1], MUTED[2], MUTED[3])
	end
	tooltip:Show() -- fit the new lines
end
ns.CraftTooltipLines = Lines -- for the tests

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_LOGIN", "MODIFIER_STATE_CHANGED")
events:SetScript("OnEvent", function(_, event, key)
	if event == "PLAYER_LOGIN" then
		for _, name in ipairs(TOOLTIPS) do
			if _G[name] then wanted[_G[name]] = true end
		end
		if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
			and Enum.TooltipDataType.Item then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, Lines)
		else
			for tooltip in pairs(wanted) do
				if tooltip.HookScript then tooltip:HookScript("OnTooltipSetItem", Lines) end
			end
		end
	elseif SHIFT_KEYS[key] and ns.db and ns.db.craft.enabled then
		-- Shift pressed or let go over an item: its tooltip again, with or without the materials
		for _, name in ipairs({ "GameTooltip", "ItemRefTooltip" }) do
			local tooltip = _G[name]
			if tooltip and tooltip.RefreshData and tooltip:IsShown() then pcall(tooltip.RefreshData, tooltip) end
		end
	end
end)
