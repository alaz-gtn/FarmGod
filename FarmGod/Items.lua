local addonName, ns = ...
local L = ns.L

-- Families of loot. Each one is valued at auction prices, at what a vendor pays, or not at all
-- (your choice in the options); the grey ones only sell to vendors
ns.CATEGORY_ORDER = { "junk", "ore", "herb", "leather", "cloth", "elemental", "meat", "enchanting", "mats", "recipe",
	"green", "blue", "other" }
ns.CATEGORIES = {
	junk = { mode = "vendor", icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01" },
	ore = { mode = "auction", item = 2770 },
	herb = { mode = "auction", item = 2447 },
	leather = { mode = "auction", item = 2318 },
	cloth = { mode = "auction", item = 2589 },
	elemental = { mode = "auction", item = 7068 },
	meat = { mode = "auction", item = 769 },
	enchanting = { mode = "auction", item = 10940 },
	mats = { mode = "auction", icon = "Interface\\Icons\\INV_Misc_Dust_02" },
	recipe = { mode = "auction", icon = "Interface\\Icons\\INV_Scroll_03" },
	-- Green gear at what a vendor pays: at the auction house greens are listed high and many never
	-- sell, and the price by item can't tell "of the Bear" from "of the Monkey". Blues and epics
	-- are fewer and their price is a real one (those bound when picked up go by a vendor's anyway)
	green = { mode = "vendor", icon = "Interface\\Icons\\INV_Chest_Chain" },
	blue = { mode = "auction", icon = "Interface\\Icons\\INV_Sword_04" },
	other = { mode = "vendor", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
}
for key, category in pairs(ns.CATEGORIES) do
	ns.defaults.categories[key] = category.mode
end

-- Vanilla's gathering materials by item, in case Forever files one somewhere else
local LISTS = {
	ore = {
		2770, 2771, 2772, 2775, 2776, 3858, 7911, 10620, 11370, 18562, -- ores
		2840, 2841, 2842, 3575, 3576, 3577, 3859, 3860, 6037, 11371, 12359, 12655, -- bars
		2835, 2836, 2838, 7912, 12365, -- stones
		774, 818, 1206, 1210, 1529, 1705, 3864, 7909, 7910, 11382, 11754, 12361, 12363, 12364, 12799, 12800, -- gems
	},
	herb = {
		765, 785, 2447, 2449, 2450, 2452, 2453, 3355, 3356, 3357, 3358, 3369, 3818, 3819, 3820, 3821, 4625,
		8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466, 13467, 13468, 19726,
	},
	leather = {
		783, 2318, 2319, 2934, 4232, 4234, 4235, 4304, 5784, 5785, 6470, 6471, 7286, 7392, 8154, 8165, 8169,
		8170, 8171, 15408, 15412, 15414, 15415, 15416, 15417, 15419, 17012, 19767, 19768,
	},
	cloth = { 2589, 2592, 4306, 4338, 14047, 14256, 14342 },
	elemental = { 7067, 7068, 7069, 7070, 7075, 7076, 7077, 7078, 7079, 7080, 7081, 7082, 7972, 12803, 12808 },
	meat = {
		723, 729, 730, 731, 769, 1015, 1468, 2672, 2673, 2674, 2675, 2677, 2924, 3173, 3667, 3685, 3712, 3730,
		3731, 5465, 5503, 5504, 7974, 12037, 12184, 12203, 12204, 12205, 12206, 12207, 12208, 20424, -- meat
		4603, 6289, 6291, 6303, 6308, 6317, 6358, 6359, 6361, 6362, 8365, 13754, 13755, 13756, 13758, 13759,
		13760, 13888, 13889, 21071, 21153, -- raw fish
	},
	enchanting = {
		10940, 11083, 11137, 11176, 16204, -- dust
		10938, 10939, 10998, 11082, 11134, 11135, 11174, 11175, 16202, 16203, -- essences
		10978, 11084, 11138, 11139, 11177, 11178, 14343, 14344, 20725, -- shards
	},
}
local LISTED = {}
for key, ids in pairs(LISTS) do
	for _, id in ipairs(ids) do LISTED[id] = key end
end

-- Trade goods by their subclass
local TRADE = { [5] = "cloth", [6] = "leather", [7] = "ore", [8] = "meat", [9] = "herb", [10] = "elemental", [12] = "enchanting" }
local CLASS_GEM, CLASS_TRADE, CLASS_RECIPE, CLASS_WEAPON, CLASS_ARMOR = 3, 7, 9, 2, 4

local function InfoInstant(itemID)
	if C_Item and C_Item.GetItemInfoInstant then return C_Item.GetItemInfoInstant(itemID) end
	if GetItemInfoInstant then return GetItemInfoInstant(itemID) end
end

local function Info(itemID)
	if C_Item and C_Item.GetItemInfo then return C_Item.GetItemInfo(itemID) end
	if GetItemInfo then return GetItemInfo(itemID) end
end

-- The game is asked for an item it hasn't loaded yet once; the windows redraw when it comes
local asked = {}
local function Ask(itemID)
	if asked[itemID] then return end
	asked[itemID] = true
	if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
end

-- An item's quality from its link: the old colour codes and the new |cnIQ tags
local LINK_QUALITY = { ff9d9d9d = 0, ffffffff = 1, ff1eff00 = 2, ff0070dd = 3, ffa335ee = 4, ffff8000 = 5, ffe6cc80 = 6 }
function ns.ItemQuality(itemID, link)
	if C_Item and C_Item.GetItemQualityByID then
		local q = C_Item.GetItemQualityByID(itemID)
		if type(q) == "number" then return q end
	end
	local q = select(3, Info(itemID))
	if type(q) == "number" then return q end
	if type(link) == "string" then
		local tag = link:match("|cnIQ(%d+):")
		if tag then return tonumber(tag) end
		local colour = link:match("|c(%x%x%x%x%x%x%x%x)")
		if colour then return LINK_QUALITY[colour:lower()] end
	end
end

function ns.Classify(itemID, quality)
	if quality == 0 then return "junk" end
	if LISTED[itemID] then return LISTED[itemID] end
	local _, _, _, _, _, classID, subclassID = InfoInstant(itemID)
	if classID == CLASS_GEM then return "ore" end
	if classID == CLASS_TRADE then return TRADE[subclassID] or "mats" end
	if classID == CLASS_RECIPE then return "recipe" end
	if classID == CLASS_WEAPON or classID == CLASS_ARMOR then
		if quality == 2 then return "green" end
		if quality and quality >= 3 then return "blue" end
	end
	return "other"
end

function ns.CategoryIcon(key)
	local c = ns.CATEGORIES[key]
	if c.item and C_Item and C_Item.GetItemIconByID then
		local icon = C_Item.GetItemIconByID(c.item)
		if icon then return icon end
	end
	return c.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function ns.ItemIcon(itemID)
	if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(itemID) end
	return select(10, Info(itemID))
end

-- Its name, or the one in the link while the game hasn't loaded it
function ns.ItemName(itemID, link)
	local name = Info(itemID)
	if type(name) == "string" then return name end
	if type(link) == "string" then
		local inLink = link:match("%[(.-)%]")
		if inLink then return inLink end
	end
	Ask(itemID)
	return "item:" .. itemID
end

-- What a vendor pays for one, or nil until the game has the item loaded
function ns.VendorPrice(itemID)
	local name, _, _, _, _, _, _, _, _, _, sell = Info(itemID)
	if not name then
		Ask(itemID)
		return nil
	end
	return sell or 0
end

-- Bound when picked up or a quest item: it can't go to the auction house
local function Auctionable(itemID)
	local name, _, _, _, _, _, _, _, _, _, _, classID, _, bind = Info(itemID)
	if not name then return true end
	return bind ~= 1 and bind ~= 4 and classID ~= 12
end

-- The price sources the player has
function ns.HasAuctionator()
	return type(Auctionator) == "table" and type(Auctionator.API) == "table" and type(Auctionator.API.v1) == "table"
		and type(Auctionator.API.v1.GetAuctionPriceByItemID) == "function"
end

function ns.HasTSM()
	return type(TSM_API) == "table" and type(TSM_API.GetCustomPriceValue) == "function"
end

ns.TSM_SOURCES = { "DBMarket", "DBMinBuyout", "DBRecent", "DBHistorical", "DBRegionMarketAvg", "DBRegionSaleAvg" }

local function FromAuctionator(itemID)
	if not ns.HasAuctionator() then return end
	local ok, price = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, addonName, itemID)
	if ok and type(price) == "number" and price > 0 then return price end
end

local function FromTSM(itemID)
	if not ns.HasTSM() then return end
	local ok, price = pcall(TSM_API.GetCustomPriceValue, ns.db.prices.tsm, "i:" .. itemID)
	if ok and type(price) == "number" and price > 0 then return price end
end

-- The last auction price for one, and whose: auctionator | tsm
function ns.AuctionPrice(itemID)
	local source = ns.db.prices.source
	if source == "auto" or source == "auctionator" then
		local price = FromAuctionator(itemID)
		if price then return price, "auctionator" end
	end
	if source == "auto" or source == "tsm" then
		local price = FromTSM(itemID)
		if price then return price, "tsm" end
	end
end

-- What one is worth in the session and where that comes from: auctionator | tsm | vendor |
-- none (no price yet) | skip (a family you don't count)
function ns.ItemValue(itemID, category)
	local prices = ns.db.prices
	local mode = ns.db.categories[category] or "auction"
	if mode == "skip" then return 0, "skip" end
	local vendor = ns.VendorPrice(itemID)
	if mode == "vendor" or prices.source == "vendor" or not Auctionable(itemID) then
		if vendor then return vendor, "vendor" end
		return 0, "none"
	end
	local auction, source = ns.AuctionPrice(itemID)
	if auction then
		if prices.cut then auction = floor(auction * 0.95) end
		if prices.best and vendor and vendor > auction then return vendor, "vendor" end
		return auction, source
	end
	if prices.vendorFallback and vendor then return vendor, "vendor" end
	return 0, "none"
end

-- The windows redraw when the game loads an item they show
local events = CreateFrame("Frame")
ns.Listen(events, "GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, _, itemID)
	if itemID and asked[itemID] then
		asked[itemID] = nil
		if ns.Changed then ns.Changed() end
	end
end)
