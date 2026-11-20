"""Loads the addon against a mocked WoW API (LuaJIT = Lua 5.1) and checks its behaviour.

Usage: python -I test_addon.py <FarmGod folder> [enUS|esES]
Needs: pip install lupa
"""
import re
import sys
from pathlib import Path

from lupa.luajit21 import LuaRuntime

ADDON = Path(sys.argv[1])
LOCALE = sys.argv[2] if len(sys.argv) > 2 else "enUS"
lua = LuaRuntime(unpack_returned_tuples=True)

printed = []
lua.globals().py_print = lambda *a: printed.append(" ".join(str(x) for x in a))
lua.globals().LOCALE = LOCALE

MOCK = r'''
print = function(...) local t = {} for i = 1, select("#", ...) do t[#t+1] = tostring((select(i, ...))) end py_print(table.concat(t, " ")) end
format = string.format; strlower = string.lower; max = math.max; min = math.min; abs = math.abs; floor = math.floor; ceil = math.ceil
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
date = os.date
GetLocale = function() return LOCALE end
-- A value the game hides from addons
SECRET = {}
issecretvalue = function(v) return v == SECRET end
YES, NO = "Yes", "No"

-- The game's own sentences, as each client has them
if LOCALE == "esES" then
  LOOT_ITEM_SELF = "Recibes botín: %s."
  LOOT_ITEM_SELF_MULTIPLE = "Recibes botín: %sx%d."
  LOOT_ITEM = "%s recibe botín: %s."
  LOOT_ITEM_PUSHED_SELF = "Recibes objeto: %s."
  YOU_LOOT_MONEY = "Despojas %s"
  LOOT_MONEY_SPLIT = "Tu parte del botín es %s."
  GOLD_AMOUNT = "%d de oro"; SILVER_AMOUNT = "%d de plata"; COPPER_AMOUNT = "%d de cobre"
  SKILL_RANK_UP = "Tu habilidad en %s ha aumentado a %d."
  SELFKILLOTHER = "¡Has matado a %s!"
  UNITDIESOTHER = "%s muere."
  COMBATLOG_XPGAIN_FIRSTPERSON = "%s muere, ganas %d puntos de experiencia."
  COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = "Ganas %d puntos de experiencia."
else
  LOOT_ITEM_SELF = "You receive loot: %s."
  LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
  LOOT_ITEM = "%s receives loot: %s."
  LOOT_ITEM_PUSHED_SELF = "You receive item: %s."
  YOU_LOOT_MONEY = "You loot %s"
  LOOT_MONEY_SPLIT = "Your share of the loot is %s."
  GOLD_AMOUNT = "%d Gold"; SILVER_AMOUNT = "%d Silver"; COPPER_AMOUNT = "%d Copper"
  SKILL_RANK_UP = "Your skill in %s has increased to %d."
  SELFKILLOTHER = "You have slain %s!"
  UNITDIESOTHER = "%s dies."
  COMBATLOG_XPGAIN_FIRSTPERSON = "%s dies, you gain %d experience."
  COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = "You gain %d experience."
end

-- Spells by id: Forever has more than one id for each gathering cast
SPELLS = { [2575] = "Mining", [1240951] = "Mining", [2366] = "Herbalism", [1240949] = "Herbalism",
  [8613] = "Skinning", [7620] = "Fishing", [921] = "Pick Pocket", [133] = "Fireball" }

-- Items: name, quality, vendor price, class, subclass, bind (1 = when picked up)
ITEMS = {
  [2770] = { "Copper Ore", 1, 5, 7, 7 }, [2771] = { "Tin Ore", 1, 25, 7, 7 },
  [818] = { "Tigerseye", 2, 100, 7, 0 }, -- vanilla's gems: on the list, whatever their class
  [2447] = { "Peacebloom", 1, 10, 7, 9 }, [2318] = { "Light Leather", 1, 15, 7, 6 },
  [2589] = { "Linen Cloth", 1, 13, 7, 5 }, [7068] = { "Elemental Fire", 1, 400, 7, 10 },
  [769] = { "Chunk of Boar Meat", 1, 4, 7, 8 }, [10940] = { "Strange Dust", 1, 25, 7, 12 },
  [4359] = { "Handful of Copper Bolts", 1, 12, 7, 1 }, [7073] = { "Broken Fang", 0, 6, 15, 0 },
  [15000] = { "Green Sword", 2, 2000, 2, 7 }, [15001] = { "Blue Ring", 3, 5000, 4, 0, 1 },
  [2881] = { "Recipe: Something", 1, 50, 9, 0 }, [3000] = { "Linen Bandage", 1, 10, 0, 7 },
  [50000] = { "Forever Ore", 1, 30, 7, 7 }, [50001] = { "Forever Thing", 1, 8, 7, 0 },
  [10620] = { "Thorium Ore", 1, 100, 7, 7 }, [12363] = { "Arcane Crystal", 2, 1000, 7, 7 },
  [4304] = { "Thick Leather", 1, 50, 7, 6 }, [15002] = { "Blue Boots", 3, 3000, 4, 0, 2 },
}
QUALITY_COLOURS = { [0] = "ff9d9d9d", [1] = "ffffffff", [2] = "ff1eff00", [3] = "ff0070dd" }
-- An item link, with the old colour code or Midnight's |cnIQ tag
function Link(id, newStyle)
  local it = ITEMS[id]
  local head = newStyle and ("|cnIQ" .. it[2] .. ":") or ("|c" .. QUALITY_COLOURS[it[2]])
  return head .. "|Hitem:" .. id .. "::::::::20:::::::|h[" .. it[1] .. "]|h|r"
end

-- Game state the tests change
G = { money = 1000000, now = 100, epoch = 1000000, timers = {}, tickers = 0, uncached = {}, requested = {}, combat = false,
      xp = 100, xpMax = 1000, level = 20, zone = "Elwynn Forest", fishing = false, lootGUID = nil, shift = false }
GetTime = function() return G.now end
time = function() return G.epoch end
GetRealZoneText = function() return G.zone end
UnitXP = function() return G.xp end
UnitXPMax = function() return G.xpMax end
UnitLevel = function() return G.level end
IsFishingLoot = function() return G.fishing end
GetLootSourceInfo = function() return G.lootGUID end
InCombatLockdown = function() return G.combat end
IsShiftKeyDown = function() return G.shift end
PixelUtil = { GetPixelToUIUnitFactor = function() return 0.5 end }
C_Spell = {
  GetSpellName = function(id) return SPELLS[id] end,
  GetSpellTexture = function(id) return id end,
}
C_Item = {
  GetItemInfo = function(id)
    local it = ITEMS[id]
    if not it or G.uncached[id] then return nil end
    return it[1], Link(id), it[2], 20, 1, "type", "subtype", 20, "", id * 10, it[3], it[4], it[5], it[6] or 0
  end,
  GetItemInfoInstant = function(id) local it = ITEMS[id] if it then return id, "type", "subtype", "", id * 10, it[4], it[5] end end,
  GetItemQualityByID = function(id) local it = ITEMS[id] if it and not G.uncached[id] then return it[2] end end,
  GetItemIconByID = function(id) return id * 10 end,
  RequestLoadItemDataByID = function(id) G.requested[id] = true end,
}
-- The price addons: Auctionator's last scan and TSM's sources
AH = { [2770] = 60, [2771] = 150, [818] = 2500, [2447] = 40, [7068] = 12000, [10940] = 300, [15000] = 15000,
       [50000] = 80, [2589] = 5, [15001] = 90000, [15002] = 40000 }
Auctionator = { API = { v1 = { GetAuctionPriceByItemID = function(caller, id)
  assert(caller == "FarmGod", "the caller is the addon")
  return AH[id]
end } } }
TSM = { DBMarket = { [2770] = 70, [2447] = 55, [2318] = 90 }, DBMinBuyout = { [2770] = 65 } }
TSM_API = { GetCustomPriceValue = function(source, itemString)
  local id = tonumber(itemString:match("^i:(%d+)$"))
  return TSM[source] and TSM[source][id]
end }
C_Timer = { After = function(t, f) table.insert(G.timers, f) end,
  NewTicker = function(t, f) G.tickers = G.tickers + 1 table.insert(TICKERS, f) return { Cancel = function() end } end }
TICKERS = {}
function RunTickers() for _, f in ipairs(TICKERS) do f() end end
function RunTimers() local t = G.timers G.timers = {} for _, f in ipairs(t) do f() end end
-- What's in the bags and the bank, by item; the bags slot by slot for names
G.bag, G.bank, G.bags = {}, {}, {}
C_Item.GetItemCount = function(id, bank) return (G.bag[id] or 0) + (bank and (G.bank[id] or 0) or 0) end
NUM_BAG_SLOTS = 4
C_Container = {
  GetContainerNumSlots = function(bag) return G.bags[bag] and #G.bags[bag] or 0 end,
  GetContainerItemInfo = function(bag, slot) local id = G.bags[bag] and G.bags[bag][slot] if id then return { itemID = id, hyperlink = Link(id) } end end,
}
-- The game finds an item by name only once it has seen it
local byId = C_Item.GetItemInfo
C_Item.GetItemInfo = function(id)
  if type(id) == "string" then
    if G.noNames then return nil end
    for itemID, it in pairs(ITEMS) do if it[1] == id then return byId(itemID) end end
    return nil
  end
  return byId(id)
end
GetCursorInfo = function() if G.cursor then return G.cursor[1], G.cursor[2], G.cursor[3] end end
ClearCursor = function() G.cursor = nil end
CENTER = {}
UIErrorsFrame = { AddMessage = function(_, text, r, g, b) table.insert(CENTER, { text, r, g, b }) end }
SOUNDKIT_PLAYED = {}
ChatEdit_InsertLink = function(link) return false end
function hooksecurefunc(a, b, c)
  if type(a) == "string" then local orig = _G[a] _G[a] = function(...) local r = orig(...) b(...) return r end
  else local orig = a[b] a[b] = function(...) local r = orig(...) c(...) return r end end
end
-- Players around: by unit, { first name, surname, class }, .player, .secret (the game hides the name)
G.units = {}
UnitName = function(unit) local u = G.units[unit] if not u then return nil end if u.secret then return SECRET end return u[1], u[2] end
UnitIsPlayer = function(unit) local u = G.units[unit] return u and u.player or false end
UnitIsUnit = function(a, b) if a == b then return true end local u = G.units[a] return b == "player" and u and u.me or false end
UnitClass = function(unit) local u = G.units[unit] if u then return "Class", u[3] end end
RAID_CLASS_COLORS = { WARRIOR = { colorStr = "ffc69b6d" }, ROGUE = { colorStr = "fffff468" } }
Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
G.plates = {}
C_NamePlate = { GetNamePlates = function() return G.plates end }
MENUS = {}
Menu = { ModifyMenu = function(tag, fn) MENUS[tag] = fn end }
function MenuRoot() local r = { buttons = {} } function r:CreateDivider() end
  function r:CreateButton(text, fn) table.insert(self.buttons, { text = text, fn = fn }) end return r end
Enum = { TooltipDataType = { Unit = 2 },
  PlayerInteractionType = { TradePartner = 1, Merchant = 5, TaxiNode = 6, Trainer = 7, MailInfo = 17, Auctioneer = 21 } }
-- Factions: how much you have with each and the edges of its standing
G.factions = {
  [529] = { name = "Argent Dawn", currentStanding = 3500, reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000 },
  [576] = { name = "Timbermaw Hold", currentStanding = 0, reaction = 4, currentReactionThreshold = 0, nextReactionThreshold = 3000 },
  [270] = { name = "Zandalar Tribe", currentStanding = 0, reaction = 4, currentReactionThreshold = 0, nextReactionThreshold = 3000 },
  [1100] = { name = "Classic", isHeader = true },
}
C_Reputation = { GetFactionDataByID = function(id) return G.factions[id] end }
FACTION_STANDING_LABEL4, FACTION_STANDING_LABEL5, FACTION_STANDING_LABEL6 = "Neutral", "Friendly", "Honored"
FACTION_BAR_COLORS = { [4] = { r = 0.9, g = 0.7, b = 0 }, [5] = { r = 0, g = 0.6, b = 0.1 } }
-- Events this client doesn't have: registering one is an error, as in the game
MISSING = {}
-- Your gold
GetMoney = function() return G.money end
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) if kind == 2 then TIP_POST = fn end end }
ACCEPT, CANCEL = "Accept", "Cancel"
StaticPopupDialogs = {}
StaticPopup_Show = function(name, a, b, data) POPUP = name POPUP_DATA = data end
GetCursorPosition = function() return 0, 100 end

-- Frames and textures: the methods the tests look at keep their state, the rest do nothing
local function Texture() local t = { shown = true } TEXTS = TEXTS or {} table.insert(TEXTS, t) setmetatable(t, { __index = function(_, k) return function(self, ...)
  if k == "SetShown" then self.shown = (...) and true or false
  elseif k == "Hide" then self.shown = false elseif k == "Show" then self.shown = true
  elseif k == "IsShown" then return self.shown
  elseif k == "SetTexture" then self.tex = ...
  elseif k == "SetColorTexture" or k == "SetTextColor" or k == "SetVertexColor" then self.color = { ... }
  elseif k == "SetText" then self.text = ... elseif k == "GetStringWidth" then return #tostring(self.text or "") * 6
  elseif k == "SetFont" then self.font = { ... }
  elseif k == "SetWidth" then self.width = ...
  elseif k == "SetPoint" then self.points = rawget(self, "points") or {} table.insert(self.points, { ... })
  elseif k == "ClearAllPoints" then self.points = {}
  elseif k == "GetText" then return self.text
  elseif k == "CreateAnimationGroup" then return CreateFrame("Frame") end
end end }) return t end
NAMED = {}
function CreateFrame(kind, name, parent, template)
  local f = { scripts = {}, events = {}, kind = kind, parent = parent, template = template, shown = true, width = 100 }
  setmetatable(f, { __index = function(_, k)
    if k:match("^Create") then return function() return CreateFrame("Frame") end end
    if k:match("^%u") then return function() end end
  end })
  function f:SetScript(n, fn) self.scripts[n] = fn end
  function f:GetScript(n) return self.scripts[n] end
  function f:RegisterEvent(e) if MISSING[e] then error('Attempt to register unknown event "' .. e .. '"') end self.events[e] = true end
  function f:RegisterUnitEvent(e) self.events[e] = true end
  function f:UnregisterEvent(e) self.events[e] = nil end
  function f:CreateTexture() return Texture() end
  function f:CreateFontString() return Texture() end
  function f:SetShown(v) self.shown = v and true or false end
  function f:Hide() self.shown = false end function f:Show() self.shown = true end
  function f:IsShown() return self.shown end
  function f:IsVisible() return self.shown end
  function f:SetChecked(v) self.checked = v and true or false end
  function f:GetChecked() return self.checked end
  function f:GetFrameLevel() return 1 end
  function f:GetParent() return self.parent end
  function f:SetPoint(...) self.point = { ... } end
  function f:GetPoint() local p = self.point return p[1], p[2], p[3], p[4], p[5] end
  function f:SetSize(w, h) self.width, self.height = w, h end
  function f:SetWidth(w) self.width = w end
  function f:SetHeight(h) self.height = h end
  function f:GetWidth() return self.width end
  function f:GetHeight() return self.height end
  function f:GetCenter() return 0, 0 end
  function f:GetEffectiveScale() return 1 end
  function f:SetScale(s) self.scale = s end
  function f:SetText(t) self.text = t end
  function f:GetText() return self.text end
  function f:SetValue(v) self.value = v end
  function f:HookScript(n, fn) local old = self.scripts[n] if old then self.scripts[n] = function(...) old(...) fn(...) end else self.scripts[n] = fn end end
  function f:SetFocus() self.focus = true end
  function f:ClearFocus() self.focus = false end
  function f:HasFocus() return self.focus or false end
  FRAMES = FRAMES or {} table.insert(FRAMES, f)
  if name then NAMED[name] = f end
  return f
end
UIParent = CreateFrame("Frame")
Minimap = CreateFrame("Frame")
Minimap.width = 140
GameFontNormal = { GetFont = function() return "font" end }
UISpecialFrames = {}
SOUNDKIT = { IG_MAINMENU_OPTION_CHECKBOX_ON = 1, IG_QUEST_LIST_COMPLETE = 878, RAID_WARNING = 8959 }
PlaySound = function(id) table.insert(SOUNDKIT_PLAYED, id) end
TOOLTIP = {}
GameTooltip = { SetOwner = function() TOOLTIP = {} end, AddLine = function(_, s) table.insert(TOOLTIP, s) end,
  AddDoubleLine = function(_, a, b) table.insert(TOOLTIP, a .. " | " .. b) end, Show = function() end,
  GetUnit = function() return "someone", G.tipUnit end }
GameTooltip_Hide = function() end
SlashCmdList = {}

function Same(a, b) return rawequal(a, b) end
function Fire(event, ...) for _, f in ipairs(FRAMES) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end end
'''
lua.execute(MOCK)

load = lua.eval('function(src, name) return assert(loadstring(src, "@" .. name)) end')
ns = lua.table()
toc = Path(ADDON, "FarmGod.toc").read_text(encoding="utf-8")
for fname in re.findall(r"^(\w+\.lua)$", toc, re.M):
    load(Path(ADDON, fname).read_text(encoding="utf-8"), fname)("FarmGod", ns)

G = lua.globals()
S = G.G  # the game state
L = ns.L
es = LOCALE in ("esES", "esMX")
fails = []


def check(cond, msg):
    print(("OK   " if cond else "FAIL ") + msg)
    if not cond:
        fails.append(msg)


def slash(arg):
    printed.clear()
    G.SlashCmdList.FARMGOD(arg)
    return list(printed)


def word(en, sp):
    return sp if es else en


def loot(item, count=1, new_style=False):
    link = G.Link(item, new_style)
    if count > 1:
        G.Fire("CHAT_MSG_LOOT", G.string.format(G.LOOT_ITEM_SELF_MULTIPLE, link, count))
    else:
        G.Fire("CHAT_MSG_LOOT", G.string.format(G.LOOT_ITEM_SELF, link))
    return link


def coins(g=0, s=0, c=0):
    parts = []
    if g:
        parts.append(G.string.format(G.GOLD_AMOUNT, g))
    if s:
        parts.append(G.string.format(G.SILVER_AMOUNT, s))
    if c:
        parts.append(G.string.format(G.COPPER_AMOUNT, c))
    return ", ".join(parts)


def money_loot(g=0, s=0, c=0):
    G.Fire("CHAT_MSG_MONEY", G.string.format(G.YOU_LOOT_MONEY, coins(g, s, c)))


def cur():
    return G.FarmGodCharDB.current


def value(item, key):
    v, source = ns.ItemValue(item, key)
    return (v, source)


tracker = G.NAMED["FarmGodTracker"]


def everything():
    return list(G.FRAMES.values()) + list(G.TEXTS.values())


def tracker_texts():
    """The window's lines as shown: (name, value) of each row"""
    out = []
    for f in G.FRAMES.values():
        if f.parent is not None and G.Same(f.parent, tracker) and f.kind == "Button" and f.shown and f["name"]:
            out.append((f["name"].text, f.value.text if f.value else None, f))
    return out


def rows():
    # Each row's frame keeps its font strings as name and value
    return [(r[0], r[1]) for r in tracker_texts()]


M = ns.Money
GOLD, SILVER, COPPER = "|cffffd100g|r", "|cffc7c7cfs|r", "|cffeda55fc|r"

# ---------------------------------------------------------------- Login
# Settings saved by 0.1.0, when gear went at auction prices
G.FarmGodDB = lua.eval('{ categories = { green = "auction", blue = "auction" } }')
G.Fire("ADDON_LOADED", "FarmGod")
G.Fire("PLAYER_LOGIN")
db = G.FarmGodDB
char = G.FarmGodCharDB
check(db.prices.source == "auto" and db.session.autoStart and db.tracker.shown, "settings filled in from the defaults")
check(db.categories.junk == "vendor" and db.categories.ore == "auction" and db.categories.other == "vendor",
      "each family with its default valuation")
check(db.categories.green == "vendor" and db.categories.blue == "auction" and db.version == 3,
      "0.1.0's settings: green gear moved to vendor prices, blues left at auction prices")
db.version, db.categories.blue = 2, "vendor"
ns.MigrateSettings(db)
check(db.categories.blue == "auction" and db.version == 3, "version 2 had the blues at vendor prices: back to auction prices")
db.categories.green = "auction"
ns.MigrateSettings(db)
check(db.categories.green == "auction", "once moved, your own choice stays")
db.categories.green = "vendor"
check(char.history is not None and char.current is None, "per character: no session, an empty history")
check(S.tickers >= 1, "the idle check runs on a ticker")
check(tracker.shown, "the session window shows")
hint = [f for f in everything() if f.text == L.IDLE_HINT_AUTO]
check(len(hint) == 1 and hint[0].shown, "no session: a hint that it starts by itself")
out = slash("")
check(G.NAMED["FarmGodOptions"] is not None and G.NAMED["FarmGodOptions"].shown, "/farmgod opens the options")
slash("")
check(not G.NAMED["FarmGodOptions"].shown, "and closes them")

# ---------------------------------------------------------------- Money and time as the game writes them
check(M(123456) == f"12{GOLD} 34{SILVER} 56{COPPER}", f"12g 34s 56c: {M(123456)}")
check(M(123456, True) == f"12{GOLD} 34{SILVER}", "short: no copper next to gold")
check(M(5) == f"5{COPPER}" and M(0) == f"0{COPPER}" and M(200) == f"2{SILVER}", "small amounts")
check(M(1234567890) == f"123,456{GOLD}", f"thousands of gold: {M(1234567890)}")
check(M(1500000, True) == f"150{GOLD}", "short over 100 gold: just gold")
check(ns.Clock(3725) == "1:02:05" and ns.Clock(65) == "1:05", "the clock")

# ---------------------------------------------------------------- Loot starts a session
printed.clear()
link_ore = loot(2770, 5)
check(cur() is not None and ns.SessionState() == "running", "looting with no session starts one")
check(L.PREFIX + L.STARTED in printed, "and says so")
check(cur()["items"][2770] == 5 and cur().links[2770] == link_ore, "5 Copper Ore counted, with its link")
check(cur().zone == "Elwynn Forest" and cur().started == 1000000, "where and when it started")
loot(818, 1, new_style=True)
check(cur()["items"][818] == 1 and cur().quality[818] == 2, "Tigerseye from a |cnIQ link: counted, green")
G.Fire("CHAT_MSG_LOOT", G.string.format(G.LOOT_ITEM, "Goten", G.Link(2771)))
G.Fire("CHAT_MSG_LOOT", G.string.format(G.LOOT_ITEM_PUSHED_SELF, G.Link(2771)))
check(cur()["items"][2771] is None, "someone else's loot and items handed to you don't count")
G.Fire("CHAT_MSG_LOOT", G.SECRET)
check(True, "a hidden chat line is left alone")
loot(7073, 3)
check(cur()["items"][7073] == 3 and cur().quality[7073] == 0, "3 grey Broken Fangs")

# ---------------------------------------------------------------- Looted gold
money_loot(1, 2, 3)
check(cur().money == 10203, f"1g 2s 3c looted: {cur().money}")
G.Fire("CHAT_MSG_MONEY", G.string.format(G.LOOT_MONEY_SPLIT, coins(c=5)) + " (" + coins(c=1) + " deposited to guild bank)")
check(cur().money == 10208, "a share of the loot, without the guild's part")
G.Fire("CHAT_MSG_MONEY", G.string.format(G.YOU_LOOT_MONEY, "3|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"))
check(cur().money == 10508, f"written with coin pictures: {cur().money}")
G.Fire("CHAT_MSG_MONEY", G.SECRET)
check(cur().money == 10508, "a hidden one: nothing")

# ---------------------------------------------------------------- What it's worth
check(value(2770, "ore") == (60, "auctionator"), f"Copper Ore at Auctionator's price: {value(2770, 'ore')}")
check(value(7073, "junk") == (6, "vendor"), "grey items at what a vendor pays")
worth = ns.Appraise()
fam = {f.key: f for f in worth.families.values()}
check(fam["ore"].value == 300 + 2500 and fam["ore"].count == 6, f"ores and gems: 5 ores and a gem, {fam['ore'].value}")
check(fam["junk"].value == 18, "the greys: 18c")
check(worth.total == 2818 + 10508 and worth.money == 10508, f"total with the gold: {worth.total}")
check([f.key for f in worth.families.values()] == ["ore", "junk"], "the most valuable family first")
check([i.id for i in fam["ore"]["items"].values()] == [818, 2770], "and in it, the most valuable item first")

ns.UpdateTracker()
total_fs = [f for f in everything() if f.text == M(worth.total)]
check(len(total_fs) >= 1, "the window shows the total")
r = rows()
check(r[0] == (L.LOOTED_GOLD, M(10508, True)), f"first the looted gold: {r[0]}")
check(r[1][0].startswith(L.CATEGORY.ore) and r[1][1] == M(2800, True), f"then the ores: {r[1]}")
check(r[2][0].startswith(L.CATEGORY.junk), f"then the greys: {r[2]}")
per_hour = [f for f in everything() if f.text and isinstance(f.text, str) and f.text.endswith("/h") and f.shown]
check(len(per_hour) == 0, "under a minute: no gold per hour yet")
S.now = S.now + 1800
ns.UpdateTracker()
check(ns.Elapsed() == 1800, "half an hour")
want = G.string.format(L.PER_HOUR, M(worth.total * 2, True))
check(any(f.text == want and f.shown for f in everything()), f"gold per hour: {want}")
clock = [f for f in everything() if f.text == "30:00"]
check(len(clock) == 1, "the clock in the title bar")

# The tooltip of a family lists its items
ore_row = tracker_texts()[1][2]
ore_row.scripts.OnEnter(ore_row)
tip = list(G.TOOLTIP.values())
check(tip[0] == L.CATEGORY.ore and tip[1].startswith("1 × " + G.Link(818, True)) and tip[1].endswith(M(2500)),
      f"hovering the ores: each item, its count and worth: {tip[:3]}")
check(tip[2].startswith("5 × ") and "Auctionator" in tip[-1], "and where the prices come from")

# ---------------------------------------------------------------- Gathering, mobs and fishing
S.now = S.now + 10
G.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 1240951)  # Forever's other Mining id
check(cur().gathers.mining == 1, "a Mining cast by Forever's own id: one node")
G.Fire("LOOT_OPENED", False, False)
check(cur().mobs == 0, "its loot is not a mob")
G.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 2366)
G.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 8613)
G.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 133)
G.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", G.SECRET)
check(cur().gathers.herb == 1 and cur().gathers.skin == 1 and cur().gathers.fish is None, "a herb, a skinning; not a Fireball or a hidden cast")
S.now = S.now + 5
S.lootGUID = "Creature-0-1-2-3-299-0000A1"
G.Fire("LOOT_OPENED", False, False)
G.Fire("LOOT_OPENED", False, False)
check(cur().mobs == 1, "a mob looted, opened twice: one")
S.lootGUID = "Creature-0-1-2-3-299-0000A2"
G.Fire("LOOT_OPENED", True, False)
S.lootGUID = "GameObject-0-1-2-3-299-0000A3"
G.Fire("LOOT_OPENED", False, False)
S.lootGUID = "Creature-0-1-2-3-299-0000A4"
G.Fire("LOOT_OPENED", False, True)
check(cur().mobs == 2, "another mob counts; a chest or a bag you open doesn't")
S.lootGUID = None
G.Fire("LOOT_OPENED", False, False)
check(cur().mobs == 3, "without a source the game won't say: counted as a mob")
S.fishing = True
G.Fire("LOOT_OPENED", False, False)
S.fishing = False
check(cur().gathers.fish == 1 and cur().mobs == 3, "a fish caught")
ns.UpdateTracker()
counts = [f for f in everything() if isinstance(f.text, str) and "|T2575:" in f.text]
check(len(counts) == 1 and "|T2366:" in counts[0].text and "|T7620:" in counts[0].text and "Skull" not in counts[0].text,
      f"the foot counts nodes by profession and fish (the kills go up top): {counts[0].text if counts else None}")

# ---------------------------------------------------------------- Kills, small in the title bar
kill_box = [f for f in G.FRAMES.values() if f.seconds is not None][0]


def kill_text():
    t = [f for f in G.TEXTS.values() if isinstance(f.text, str) and "UI-TargetingFrame-Skull:12:12|t" in f.text]
    return t[0].text if t else None


check(kill_box.shown and kill_text().endswith(" 3"), f"3 mobs looted, the game said no kill: 3 in the title bar: {kill_text()}")
fmt = G.string.format
S.now = S.now + 10
G.Fire("PARTY_KILL", "Player-1-0001", "Creature-0-1-2-3-299-0000B1")
G.Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH", fmt(G.SELFKILLOTHER, "Kobold Vermin"))
G.Fire("CHAT_MSG_COMBAT_XP_GAIN", fmt(G.COMBATLOG_XPGAIN_FIRSTPERSON, "Kobold Vermin", 45))
check(cur().kills == 1, f"a kill told three ways at once: one kill ({cur().kills})")
S.now = S.now + 0.5
G.Fire("PARTY_KILL", G.SECRET, G.SECRET)
G.Fire("PARTY_KILL", G.SECRET, G.SECRET)
G.Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH", fmt(G.SELFKILLOTHER, "Kobold Worker"))
G.Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH", fmt(G.SELFKILLOTHER, "Kobold Laborer"))
G.Fire("CHAT_MSG_COMBAT_XP_GAIN", fmt(G.COMBATLOG_XPGAIN_FIRSTPERSON, "Kobold Worker", 45) + " (+22 exp Rested bonus)")
check(cur().kills == 3, f"two at once (who died hidden, as in dungeons): two more ({cur().kills})")
S.now = S.now + 5
G.Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH", fmt(G.SELFKILLOTHER, "Wolf"))
check(cur().kills == 4, "without PARTY_KILL the chat line is enough")
S.now = S.now + 5
G.Fire("CHAT_MSG_COMBAT_XP_GAIN", fmt(G.COMBATLOG_XPGAIN_FIRSTPERSON, "Wolf", 30) + " (+15 exp Rested bonus)")
check(cur().kills == 5, "or the XP one, with its rested bonus")
G.Fire("CHAT_MSG_COMBAT_XP_GAIN", fmt(G.COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, 500))
G.Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH", fmt(G.UNITDIESOTHER, "Someone's Boar"))
G.Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH", G.SECRET)
G.Fire("CHAT_MSG_COMBAT_XP_GAIN", G.SECRET)
check(cur().kills == 5, "a quest's XP, a mob someone else killed or a hidden line: no kill")
ns.UpdateTracker()
check(kill_text().endswith(" 5"), f"5 in the title bar: {kill_text()}")
kill_box.scripts.OnEnter(kill_box)
tip = list(G.TOOLTIP.values())
check(f"{L.TIP_KILLS} | 5" in tip and f"{L.TIP_LOOTED} | 3" in tip and any(t.startswith(L.TIP_PER_KILL + " | ") for t in tip),
      f"hover: kills, looted and what a kill is worth: {tip}")
db.tracker.collapsed = True
ns.UpdateTracker()
check(kill_box.shown, "there in the folded window too")
db.tracker.collapsed = False
db.tracker.kills = False
ns.UpdateTracker()
check(not kill_box.shown, "it can be turned off")
db.tracker.kills = True
slash(word("pause", "pausa"))
G.Fire("PARTY_KILL", G.SECRET, G.SECRET)
check(cur().kills == 5, "paused: kills don't count")
slash(word("start", "empezar"))
out = slash(word("report", "informe"))
check(out[0].endswith(fmt(L.REPORT, ns.Clock(ns.Elapsed()), M(ns.Appraise().total), M(ns.PerHour(ns.Appraise().total, ns.Elapsed()), True), 5)),
      f"the report says them: {out}")


# ---------------------------------------------------------------- XP and skill-ups
S.xp = 350
G.Fire("PLAYER_XP_UPDATE", "player")
check(cur().xp == 250, f"XP gained: {cur().xp}")
S.level, S.xp, S.xpMax = 21, 50, 1200
G.Fire("PLAYER_XP_UPDATE", "player")
check(cur().xp == 250 + 650 + 50, f"across a level up: {cur().xp}")
G.Fire("CHAT_MSG_SKILL", G.string.format(G.SKILL_RANK_UP, "Mining", 76))
G.Fire("CHAT_MSG_SKILL", G.string.format(G.SKILL_RANK_UP, "Mining", 77))
check(cur().skills.Mining["from"] == 75 and cur().skills.Mining.to == 77, "Mining from 75 to 77")
ns.UpdateTracker()
check(any(isinstance(f.text, str) and "Mining 77 (+2)" in f.text and f.shown for f in everything()), "shown at the foot")
check(any(isinstance(f.text, str) and L.XP_HOUR.split("%s")[0] in f.text and "/h" in f.text and f.shown
          for f in everything()), "and the XP an hour")

# ---------------------------------------------------------------- A big loot is said
db.session.bigLoot = 1
printed.clear()
loot(7068)
check(any(G.string.format(L.BIG_LOOT, G.Link(7068), 1, M(12000)) in p for p in printed), f"Elemental Fire, 1g 20s: said: {printed}")
printed.clear()
loot(2770)
check(not printed, "a Copper Ore: not")
db.session.bigLoot = 5

# ---------------------------------------------------------------- Families
cl = ns.Classify
check(cl(50000, 1) == "ore" and cl(50001, 1) == "mats", "Forever's own materials by their kind")
check(cl(15000, 2) == "green" and cl(15001, 3) == "blue" and cl(2881, 1) == "recipe" and cl(3000, 1) == "other",
      "green and blue gear, recipes, the rest")
check((cl(2447, 1), cl(2318, 1), cl(2589, 1), cl(7068, 1), cl(769, 1), cl(10940, 1), cl(7073, 0)) ==
      ("herb", "leather", "cloth", "elemental", "meat", "enchanting", "junk"), "herbs, leather, cloth, elementals, meat, dust, greys")
check(ns.ItemQuality(99999, "|cnIQ3:|Hitem:99999|h[x]|h|r") == 3 and ns.ItemQuality(99998, "|cff1eff00|Hitem:99998|h[x]|h|r") == 2,
      "the quality of an item the game hasn't loaded, from its link")

# ---------------------------------------------------------------- Price sources and how loot is valued
prices = db.prices
prices.source = "tsm"
check(value(2770, "ore") == (70, "tsm"), "TSM: its market value")
prices.tsm = "DBMinBuyout"
check(value(2770, "ore") == (65, "tsm"), "or the source you pick")
prices.tsm = "DBMarket"
prices.source = "auctionator"
check(value(2770, "ore") == (60, "auctionator") and value(2318, "leather") == (15, "vendor"),
      "Auctionator only: no price for leather, a vendor's")
prices.source = "auto"
check(value(2318, "leather") == (90, "tsm"), "both: Auctionator first, then TSM")
saved = G.Auctionator
G.Auctionator = None
check(value(2770, "ore") == (70, "tsm") and not ns.HasAuctionator(), "without Auctionator: TSM")
G.Auctionator = saved
prices.source = "vendor"
check(value(2770, "ore") == (5, "vendor"), "vendor prices only")
prices.source = "auto"
check(value(2589, "cloth") == (13, "vendor"), "Linen Cloth sells for less than a vendor pays: the vendor's")
prices.best = False
check(value(2589, "cloth") == (5, "auctionator"), "unless you want the auction price anyway")
prices.best = True
prices.cut = True
check(value(2770, "ore") == (57, "auctionator"), "the auction house's 5% off")
prices.cut = False
check(value(4359, "mats") == (12, "vendor"), "no auction price: what a vendor pays")
prices.vendorFallback = False
check(value(4359, "mats") == (0, "none"), "or nothing")
prices.vendorFallback = True
check(value(15001, "blue") == (5000, "vendor"), "bound when picked up: only a vendor's price")
check(value(15002, "blue") == (40000, "auctionator"), "blue boots that can be sold: at auction prices")
check(value(15000, "green") == (2000, "vendor"), "a green sword at what a vendor pays, though the auction house lists it at 1g 50s")
db.categories.green = "auction"
check(value(15000, "green") == (15000, "auctionator"), "or at auction prices, if you choose so")
db.categories.green = "vendor"
db.categories.ore = "vendor"
check(value(2770, "ore") == (5, "vendor"), "a family valued at vendor prices")
db.categories.ore = "auction"
db.categories.junk = "skip"
check(value(7073, "junk") == (0, "skip"), "a family you don't count")
ns.UpdateTracker()
check(not any(n.startswith(L.CATEGORY.junk) for n, _ in rows()), "not listed in the window")
db.categories.junk = "vendor"
S.uncached[2771] = True
check(value(2771, "ore") == (150, "auctionator") and S.requested[2771], "an item not loaded: its auction price, and the game asked for it")
check(ns.VendorPrice(2771) is None, "no vendor price until it comes")
S.uncached[2771] = None
printed.clear()
G.Fire("GET_ITEM_INFO_RECEIVED", 2771)
check(ns.VendorPrice(2771) == 25, "loaded: its vendor price")

# ---------------------------------------------------------------- Pausing
before = ns.Elapsed()
out = slash(word("pause", "pausa"))
check(ns.SessionState() == "paused" and out == [L.PREFIX + L.PAUSED], "paused")
loot(2770, 10)
check(cur()["items"][2770] == 6, "loot while paused doesn't count")
S.now = S.now + 600
check(ns.Elapsed() == before, "nor does the time")
ns.UpdateTracker()
check(any(f.text == L.STATE_PAUSED and f.shown for f in everything()), "the window says paused")
out = slash(word("start", "empezar"))
check(ns.SessionState() == "running" and out == [L.PREFIX + L.RESUMED], "resumed")

# Nothing looted for a while: an idle pause that takes those minutes off
loot(2770)
at = ns.Elapsed()
S.now = S.now + 300
ns.CheckIdle()
check(ns.SessionState() == "running", "5 minutes with nothing: still going")
S.now = S.now + 400
printed.clear()
G.RunTickers()
check(ns.SessionState() == "paused" and cur().pause == "idle", "over 10: paused by itself")
check(ns.Elapsed() == at, f"and the idle minutes don't count: {ns.Elapsed()} == {at}")
check(printed == [L.PREFIX + G.string.format(L.IDLE_PAUSED, 10)], "it says so")
ns.UpdateTracker()
check(any(f.text == L.STATE_IDLE and f.shown for f in everything()), "the window says why")
loot(2770)
check(ns.SessionState() == "running" and cur()["items"][2770] == 8, "the next loot carries on, and counts")
db.session.idleMinutes = 0
S.now = S.now + 3600
ns.CheckIdle()
check(ns.SessionState() == "running", "idle pause off: it never pauses")
db.session.idleMinutes = 10

# ---------------------------------------------------------------- A /reload or a logout keeps it, without the time logged out
at = ns.Elapsed()
G.Fire("PLAYER_LOGOUT")
S.now = S.now + 5000
G.Fire("PLAYER_LOGIN")
check(ns.SessionState() == "running" and ns.Elapsed() == at, "logged in again: the same session, the time away not counted")
S.now = S.now + 60
check(ns.Elapsed() == at + 60, "and it goes on")

out = slash(word("report", "informe"))
check(len(out) == 1 and M(ns.Appraise().total) in out[0], f"report: {out}")

# ---------------------------------------------------------------- The auction house: new prices
S.now = S.now + 10
G.Fire("AUCTION_HOUSE_SHOW")
was = ns.Appraise().total
G.AH[2770] = 80
G.Fire("AUCTION_HOUSE_CLOSED")
printed.clear()
G.RunTimers()
now = ns.Appraise().total
check(now == was + 8 * 20, f"Copper Ore went up 20c: the session is worth more ({was} -> {now})")
check(printed == [L.PREFIX + G.string.format(L.PRICES_UPDATED, M(now), M(was))], f"and it says so: {printed}")
G.Fire("AUCTION_HOUSE_SHOW")
G.Fire("AUCTION_HOUSE_CLOSED")
printed.clear()
G.RunTimers()
check(printed == [], "no change: nothing said")

# ---------------------------------------------------------------- Ending and the history
session = cur()
printed.clear()
slash(word("stop", "terminar"))
check(cur() is None and ns.SessionState() == "idle", "ended: no session")
check(len(char.history) == 1 and G.Same(char.history[1], session) and session.ended == 1000000, "it's in the history")
check(any(M(ns.Appraise(session).total) in p for p in printed), "and it says what it was worth")
out = slash(word("history", "historial"))
check(out[0] == L.PREFIX + L.HISTORY_TITLE and len(out) == 2 and "Elwynn Forest" in out[1], f"/farmgod history: {out}")
G.AH[2770] = 100
check(ns.Appraise(session).total > now, "the history goes by today's prices too")
G.AH[2770] = 60

# Reset: back to zero after asking
loot(2770, 2)
check(ns.SessionState() == "running" and cur()["items"][2770] == 2, "a new session with the next loot")
reset_button = [f for f in G.FRAMES.values() if f.kind == "Button" and f.tip == L.BTN_RESET]
check(len(reset_button) == 1, "the window has a reset button")
G.POPUP = None
reset_button[0].scripts.OnClick(reset_button[0])
check(G.POPUP == "FARMGOD_RESET" and cur()["items"][2770] == 2, "it asks first")
G.StaticPopupDialogs.FARMGOD_RESET.OnAccept()
check(cur() is not None and next(iter(cur()["items"].keys()), None) is None and ns.SessionState() == "running", "then back to zero, running")
printed.clear()
slash(word("stop", "terminar"))
check(printed == [L.PREFIX + L.ENDED_EMPTY] and len(char.history) == 1, "an empty session isn't kept")

# The play button
play = [f for f in G.FRAMES.values() if f.kind == "Button" and f.tip in (L.BTN_START, L.BTN_PAUSE, L.BTN_RESUME)][0]
ns.UpdateTracker()
check(play.tip == L.BTN_START and play.glyph.tex.endswith("play"), "no session: play to start")
play.scripts.OnClick(play)
ns.UpdateTracker()
check(ns.SessionState() == "running" and play.tip == L.BTN_PAUSE and play.glyph.tex.endswith("pause"), "started: pause")
play.scripts.OnClick(play)
ns.UpdateTracker()
check(ns.SessionState() == "paused" and play.tip == L.BTN_RESUME, "paused: resume")
slash(word("stop", "terminar"))

# Not starting by itself
db.session.autoStart = False
loot(2770)
check(cur() is None, "auto-start off: loot doesn't start a session")
ns.UpdateTracker()
check(any(f.text == L.IDLE_HINT and f.shown for f in everything()), "and the hint says to press play")
db.session.autoStart = True

# The window
db.tracker.onlyActive = True
ns.UpdateTracker()
check(not tracker.shown, "only while there's a session: hidden now")
db.tracker.onlyActive = False
ns.UpdateTracker()
check(tracker.shown, "shown again")
loot(2770, 3)
loot(2447, 2)
db.tracker.collapsed = True
ns.UpdateTracker()
check(rows() == [], "folded: just the time and the total")
fold = [f for f in G.FRAMES.values() if f.kind == "Button" and f.tip == L.BTN_FOLD][0]
fold.scripts.OnClick(fold)
check(not db.tracker.collapsed and len(rows()) == 2, "unfolded with its button")
db.tracker.rows = 1
ns.UpdateTracker()
check(len(rows()) == 1, "as many families as you want listed")
db.tracker.rows = 8
out = slash(word("show", "mostrar"))
check(not tracker.shown and not db.tracker.shown, "/farmgod show hides it")
slash(word("show", "mostrar"))
check(tracker.shown, "and shows it")
slash(word("stop", "terminar"))

# Moving it
ns.SetUnlocked(True)
check(tracker.shown and tracker.mover.shown, "unlocked: the window with its handle")
check(any(f.text == "45:32" and f.shown for f in everything()), "no session: a sample to place")
ns.SetUnlocked(False)
check(not tracker.mover.shown and not any(f.text == "45:32" and f.shown for f in everything()), "locked: back to what's real")
db.positions.tracker = lua.table("CENTER", "CENTER", 10, 20)
ns.PlaceFrame(tracker)
check(tracker.point[1] == "CENTER" and tracker.point[4] == 10, "where you put it")
S.combat = True
out = slash(word("unlock", "desbloquear"))
check(not ns.unlocked and out[0] == L.PREFIX + L.NOT_IN_COMBAT, "not in combat")
S.combat = False

# ---------------------------------------------------------------- Options
slash("")
win, pages = ns.OptionsWindow()
page = {p.key: p for p in pages.values()}
check(set(page.keys()) == {"session", "goals", "notes", "day", "prices", "families", "history"}, f"pages: {list(page.keys())}")
controls = {c.setting: c for c in page["session"].controls.values()}
toggle = controls[L.OPT_TOGGLE]
check(toggle.word.text == L.BTN_START, "the session page: start")
toggle.scripts.OnClick(toggle)
check(ns.SessionState() == "running" and toggle.word.text == L.BTN_PAUSE, "started from the options, now it says pause")
toggle.scripts.OnClick(toggle)
check(ns.SessionState() == "paused" and toggle.word.text == L.BTN_RESUME, "paused")
end = controls[L.OPT_END]
end.scripts.OnClick(end)
check(ns.SessionState() == "idle" and toggle.word.text == L.BTN_START, "ended")
width = controls[L.OPT_WIDTH]
width.scripts.OnValueChanged(width, 300)
check(db.tracker.width == 300 and tracker.width == 300, "the window's width")
idle = controls[L.OPT_IDLE]
idle.scripts.OnValueChanged(idle, 15)
check(db.session.idleMinutes == 15, "the idle minutes")
auto = controls[L.OPT_AUTO_START]
auto.checked = False
auto.scripts.OnClick(auto)
check(not db.session.autoStart, "auto-start can be turned off")
auto.checked = True
auto.scripts.OnClick(auto)

ns.ShowOptionsPage("prices")
pcontrols = {c.setting: c for c in page["prices"].controls.values()}
source = pcontrols[L.OPT_SOURCE]
check(source.text == L.SOURCE.auto, f"price source: {source.text}")
source.scripts.OnClick(source)
check(db.prices.source == "auctionator" and source.text == "Auctionator", "next: Auctionator")
for _ in range(3):
    source.scripts.OnClick(source)
check(db.prices.source == "auto", "and round again")
tsm = pcontrols[L.OPT_TSM]
tsm.scripts.OnClick(tsm)
check(db.prices.tsm == "DBMinBuyout", "the TSM price")
db.prices.tsm = "DBMarket"
status = pcontrols["status"]
status.Refresh()
check("Auctionator" in status.text.text and "TSM" in status.text.text, f"it says which price addons it found: {status.text.text}")
cut = pcontrols[L.OPT_CUT]
cut.checked = True
cut.scripts.OnClick(cut)
check(db.prices.cut, "the auction cut switch")
cut.checked = False
cut.scripts.OnClick(cut)

ns.ShowOptionsPage("families")
fcontrols = {c.setting: c for c in page["families"].controls.values()}
check(all(L.CATEGORY[k] in fcontrols for k in ns.CATEGORY_ORDER.values()), "one row per family")
ore = fcontrols[L.CATEGORY.ore]
check(ore.text == L.MODE.auction, "ores at auction prices")
ore.scripts.OnClick(ore)
check(db.categories.ore == "vendor" and ore.text == L.MODE.vendor, "or a vendor's")
ore.scripts.OnClick(ore)
check(db.categories.ore == "skip", "or not counted")
ore.scripts.OnClick(ore)
check(db.categories.ore == "auction", "and round again")

ns.ShowOptionsPage("history")
hist = [c for c in page["history"].controls.values() if c.setting == "history"][0]
shown_lines = [line for line in hist.lines.values() if line.shown]
check(len(char.history) == 2 and len(shown_lines) == 2 and shown_lines[0].total.text == M(ns.Appraise(char.history[1]).total),
      "the history page lists the two sessions kept, the last first, with their worth")
shown_lines[0].scripts.OnEnter(shown_lines[0])
check(any(L.CATEGORY.ore in t for t in G.TOOLTIP.values()), "hover: its families")
clear = [c for c in page["history"].controls.values() if c.setting == L.OPT_CLEAR][0]
G.POPUP = None
clear.scripts.OnClick(clear)
check(G.POPUP == "FARMGOD_CLEAR_HISTORY" and len(char.history) == 2, "clearing it asks first")
G.StaticPopupDialogs.FARMGOD_CLEAR_HISTORY.OnAccept()
check(len(char.history) == 0 and not any(line.shown for line in hist.lines.values()), "then it's empty")
win.Hide(win)

# ---------------------------------------------------------------- Goals, as a quest's objectives
gw = word("goal", "objetivo")
out = slash(gw)
check(out == [L.PREFIX + L.GOALS_NONE], "no goals: it says how to set one")
thorium = G.Link(10620)
out = slash(f"{gw} 40 {thorium}")
goals = G.FarmGodCharDB.goals
check(len(goals) == 1 and goals[1].id == 10620 and goals[1].need == 40, "/farmgod goal 40 [Thorium Ore]")
check(out == [L.PREFIX + G.string.format(L.GOAL_SET, 40, thorium)], f"it says so: {out}")
out = slash(f"{gw} Arcane Crystal 2")
check(len(goals) == 2 and goals[2].id == 12363 and goals[2].need == 2, "by name, the amount after it")
S.noNames = True
S.bags[0] = lua.table(4304)
out = slash(f"{gw} 60 thick leather")
check(len(goals) == 3 and goals[3].id == 4304 and goals[3].need == 60, "a name the game won't look up: found in the bags")
S.bags[0] = None
out = slash(f"{gw} 5 Nothing Like It")
check(out == [L.PREFIX + G.string.format(L.GOAL_UNKNOWN, "Nothing Like It")], "an item it can't find: says how")
S.noNames = False
out = slash(f"{gw} Thorium Ore")
check(out == [L.PREFIX + L.GOAL_USAGE], "no amount: how to write it")
out = slash(f"{gw} 3 12363")
check(len(goals) == 3 and goals[2].need == 3, "by id, and again for one you have: its new amount")
out = slash(gw)
check(out[0] == L.PREFIX + L.GOALS_TITLE and len(out) == 4 and "0/40" in out[1], f"listed: {out}")

ns.UpdateTracker()


def goal_rows():
    return [f for f in G.FRAMES.values() if f.goal is not None and f.shown]


gr = goal_rows()
check([(r["name"].text, r.count.text) for r in gr] == [("Thorium Ore", "0/40"), ("Arcane Crystal", "0/3"), ("Thick Leather", "0/60")],
      f"the window lists them like a quest's objectives: {[(r['name'].text, r.count.text) for r in gr]}")
check(not gr[0].fill.shown, "nothing yet: no bar")

G.CENTER = lua.table()
S.bag[10620] = 12
G.Fire("BAG_UPDATE_DELAYED")
center = [tuple(m.values()) for m in G.CENTER.values()]
check(center == [("Thorium Ore: 12/40", 1, 0.82, 0)], f"12 ore in the bags: in the middle of the screen, in yellow: {center}")
gr = goal_rows()
check(gr[0].count.text == "12/40" and gr[0].fill.shown and abs(gr[0].fill.width - (db.tracker.width - 36) * 0.3) < 1e-6,
      f"its bar 30% full: {gr[0].fill.width}")
S.bag[10620] = 10
G.CENTER = lua.table()
G.Fire("BAG_UPDATE_DELAYED")
check(len(list(G.CENTER.values())) == 0, "fewer (sold some): nothing said")
printed.clear()
S.bag[10620] = 41
G.SOUNDKIT_PLAYED = lua.table()
G.Fire("BAG_UPDATE_DELAYED")
center = [tuple(m.values()) for m in G.CENTER.values()]
check(center == [("Thorium Ore: 40/40", 0.35, 0.85, 0.4)], f"met: in green, never past 40: {center}")
check(878 in list(G.SOUNDKIT_PLAYED.values()) and printed == [L.PREFIX + G.string.format(L.GOAL_DONE, thorium, 40)],
      "with the quest sound, and in the chat")
gr = goal_rows()
check(gr[0].count.text == "40/40" and gr[0]["name"].color[1] == 0.35, "done: green in the window")
printed.clear()
S.bag[12363], S.bag[4304] = 3, 60
G.Fire("BAG_UPDATE_DELAYED")
check(L.PREFIX + L.GOALS_ALL_DONE in printed, "all met: it says so")
S.bag[10620], S.bag[12363], S.bag[4304] = 10, 0, 0
G.Fire("BAG_UPDATE_DELAYED")
db.goals.bank = True
S.bank[10620] = 5
check(ns.GoalCount(10620) == 15, "counting the bank too")
db.goals.bank = False
db.goals.announce = False
G.CENTER = lua.table()
S.bag[10620] = 11
G.Fire("BAG_UPDATE_DELAYED")
check(len(list(G.CENTER.values())) == 0, "announcing off: silent")
db.goals.announce = True

# Its pace in this session
S.now = S.now + 10
loot(10620, 6)
S.now = S.now + 1800
ns.UpdateTracker()
gr = goal_rows()
gr[0].scripts.OnEnter(gr[0])
tip = list(G.TOOLTIP.values())
check(any(t.startswith(L.GOAL_SESSION) and "+6" in t for t in tip), f"hover: what you looted of it this session: {tip}")
check(any(t == G.string.format(L.GOAL_ETA, 29, ns.Clock(29 / 12 * 3600)) for t in tip), "and how long the rest would take")
slash(word("stop", "terminar"))

# Shown with no session if there are goals, even when only shown with one
db.tracker.onlyActive = True
ns.UpdateTracker()
check(tracker.shown, "goals keep the window up with no session")
db.tracker.onlyActive = False

# In the options
ns.ToggleOptions("goals")
gcontrols = {c.setting: c for c in page["goals"].controls.values()}
ed = gcontrols["goal editor"]
glist = gcontrols["goals"]
check(len([ln for ln in glist.lines.values() if ln.shown]) == 3, "the goals page lists them")
ed.item.SetText(ed.item, "Peacebloom")
ed.item.scripts.OnTextChanged(ed.item, True)
ed.amount.SetText(ed.amount, "20")
check(not ed.item.placeholder.shown, "typing hides the grey hint in the box")
ed.add.scripts.OnClick(ed.add)
check(len(goals) == 4 and goals[4].id == 2447 and goals[4].need == 20 and ed.item.text == "", "typed and added")
check(len([ln for ln in glist.lines.values() if ln.shown]) == 4, "and listed")
ed.item.SetText(ed.item, "Linen Cloth")
ed.amount.SetText(ed.amount, "")
printed.clear()
ed.add.scripts.OnClick(ed.add)
check(printed == [L.PREFIX + L.GOAL_AMOUNT] and len(goals) == 4, "no amount: it asks how many")
S.cursor = lua.table("item", 2589, G.Link(2589))
ed.slot.scripts.OnReceiveDrag(ed.slot)
check(S.cursor is None and ed.item.text == "Linen Cloth" and ed.picture.tex == 25890 and ed.amount.focus,
      "an item dragged onto the square: chosen, the amount next")
ed.amount.SetText(ed.amount, "100")
ed.amount.scripts.OnEnterPressed(ed.amount)
check(len(goals) == 5 and goals[5].id == 2589 and goals[5].need == 100, "Enter adds it")
ed.item.SetFocus(ed.item)
G.ChatEdit_InsertLink(G.Link(7068))
check(ed.item.text == "Elemental Fire" and ed.amount.focus, "shift-click while typing: that item")
ed.amount.SetText(ed.amount, "4")
ed.add.scripts.OnClick(ed.add)
check(goals[6].id == 7068 and goals[6].need == 4, "added")
first = [ln for ln in glist.lines.values() if ln.shown][0]
first.scripts.OnClick(first)
check(ed.item.text == "Thorium Ore" and ed.amount.text == "40", "click one: it's in the box to change its amount")
first.remove.scripts.OnClick(first.remove)
check(len(goals) == 5 and goals[1].id == 12363, "× takes it off")
clear_goals = gcontrols[L.OPT_GOALS_CLEAR]
G.POPUP = None
clear_goals.scripts.OnClick(clear_goals)
check(G.POPUP == "FARMGOD_CLEAR_GOALS" and len(goals) == 5, "taking them all off asks first")
out = slash(f"{gw} 0 {G.Link(12363)}")
check(len(goals) == 4 and out == [L.PREFIX + G.string.format(L.GOAL_REMOVED, G.Link(12363))], "0 takes one off")
out = slash(f"{gw} " + word("clear", "borrar"))
check(len(goals) == 0 and out == [L.PREFIX + L.GOALS_CLEARED], "and clear, all of them")
ns.UpdateTracker()
check(goal_rows() == [], "none left in the window")
win.Hide(win)

# ---------------------------------------------------------------- Notes on players: who farms your layer
nw = word("note", "nota")


def player(token, first, surname, cls="WARRIOR", is_player=True, secret=False, me=False):
    u = lua.table(first, surname, cls)
    u.player, u.secret, u.me = is_player, secret, me
    S.units[token] = u


def near_text():
    prefix = L.NEAR.split("%s")[0]
    hits = [f for f in G.TEXTS.values() if isinstance(f.text, str) and f.text.startswith(prefix) and f.shown]
    return hits[0].text if hits else None


notes = db.notes
out = slash(nw)
check(out == [L.PREFIX + L.NOTES_NONE], "no notes, no target: how to set one")
out = slash(f"{nw} Farmer")
check(out == [L.PREFIX + L.NOTE_NO_TARGET], "a note with nobody targeted: target someone first")
player("target", "Goten", "Farmson", "ROGUE")
out = slash(f"{nw} Farmer")
goten = notes["goten farmson"]
check(goten is not None and goten.note == "Farmer" and goten.name == "Goten Farmson", "/farmgod note Farmer on your target: First Surname")
check(goten["class"] == "ROGUE" and goten.zone == "Elwynn Forest" and goten.seen == 1000000, "with their class, where and when")
check(out == [L.PREFIX + G.string.format(L.NOTE_SET, "Goten Farmson", "Farmer")], f"said once, no alert for who you're looking at: {out}")
ns.UpdateTracker()
check(near_text() == G.string.format(L.NEAR, "|cfffff468Goten Farmson|r (Farmer) " + L.AGO_NOW),
      f"the window: on your layer, in their class colour: {near_text()}")

# Seen by their nameplate: on your layer
ns.SetNote("Vegeta Botson", "Bot")
player("nameplate1", "Vegeta", "Botson")
printed.clear()
G.CENTER = lua.table()
G.SOUNDKIT_PLAYED = lua.table()
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(printed == [L.PREFIX + G.string.format(L.NOTE_SEEN, "|cffc69b6dVegeta Botson|r", "Bot", "Elwynn Forest")],
      f"a noted player's nameplate: said in the chat: {printed}")
center = [tuple(m.values()) for m in G.CENTER.values()]
check(center == [(G.string.format(L.NOTE_SEEN_CENTER, "Vegeta Botson", "Bot"), 1, 0.55, 0.15)] and 8959 in list(G.SOUNDKIT_PLAYED.values()),
      "in the middle of the screen, with the raid warning sound")
S.now = S.now + 60
printed.clear()
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(printed == [], "seen again a minute later: not said again")
S.now = S.now + 300
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(len(printed) == 1, "after 5 minutes: said again")
db.noteAlerts.center = False
db.noteAlerts.sound = False
S.now = S.now + 400
G.CENTER = lua.table()
G.SOUNDKIT_PLAYED = lua.table()
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(len(list(G.CENTER.values())) == 0 and len(list(G.SOUNDKIT_PLAYED.values())) == 0, "chat only, if you want")
db.noteAlerts.center = True
db.noteAlerts.sound = True

printed.clear()
player("nameplate2", "Kobold", None, is_player=False)
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
player("nameplate3", "Hidden", "Name", secret=True)
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
player("nameplate4", "Someone", "Else")
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate4")
check(printed == [], "a mob, a hidden name or a player without a note: nothing")
ns.SetNote("Me Myself", "Farmer")
player("mouseover", "Me", "Myself", me=True)
G.Fire("UPDATE_MOUSEOVER_UNIT")
check(printed == [], "nor you")
ns.SetNote("Me Myself", "")
check(notes["me myself"] is None, "an empty note takes it off")
ns.SetNote("Krillin Bald", "Farmer")
S.now = S.now + 5
player("mouseover", "Krillin", "Bald")
G.Fire("UPDATE_MOUSEOVER_UNIT")
check(len(printed) == 1 and "Krillin Bald" in printed[0], "the mouse over one: seen")

# Who's on your layer, in the window, until it's old news or you change layer
ns.UpdateTracker()
text = near_text()
check(text is not None and text.index("Krillin") < text.index("Vegeta") and "Goten" not in text,
      f"the last seen first; Goten, not seen for over 10 minutes, gone: {text}")
S.now = S.now + 11 * 60
ns.UpdateTracker()
check(near_text() is None, "after 10 minutes not seen: off the list")
S.plates = lua.table(lua.table(), lua.table())
S.plates[1].namePlateUnitToken = "nameplate1"
S.plates[2].namePlateUnitToken = "nameplate2"
printed.clear()
ns.ScanPlates()
ns.UpdateTracker()
check(near_text() == G.string.format(L.NEAR, "|cffc69b6dVegeta Botson|r (Bot) " + L.AGO_NOW) and len(printed) == 1,
      "nameplates still in view keep them on the list (and say it again after so long)")
G.Fire("SHARD_TRANSFER")
ns.UpdateTracker()
check(near_text() is None, "Forever moves you to another layer: the list empties")
printed.clear()
S.epoch = S.epoch + 100
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(len(printed) == 1, "and seeing them on the new one says so at once")
out = slash(word("layer", "capa"))
check(out == [L.PREFIX + L.LAYER_CLEARED] and ns.NearbyNoted()[1] is None, "/farmgod layer does it by hand")
S.plates = lua.table()
db.noteAlerts.near = False
G.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
ns.UpdateTracker()
check(near_text() is None, "the list in the window can be turned off")
db.noteAlerts.near = True

# The note in their tooltip
G.TOOLTIP = lua.table()
S.tipUnit = "nameplate1"
G.TIP_POST(G.GameTooltip, lua.table())
check(list(G.TOOLTIP.values()) == [G.string.format(L.NOTE_TIP, "Bot")], "in the tooltip of a noted player")
G.TOOLTIP = lua.table()
S.tipUnit = "nameplate4"
G.TIP_POST(G.GameTooltip, lua.table())
check(list(G.TOOLTIP.values()) == [], "nothing for one without a note")

# Their right-click menu
root = G.MenuRoot()
G.MENUS["MENU_UNIT_TARGET"](None, root, lua.table(unit="target"))
check(len(list(root.buttons.values())) == 1 and root.buttons[1].text == L.NOTE_MENU_EDIT, "your target's menu: change the note")
root = G.MenuRoot()
G.MENUS["MENU_UNIT_FRIEND"](None, root, lua.table(name="Bulma Brief"))
check(root.buttons[1].text == L.NOTE_MENU_ADD, "a name in the chat: add one")
G.POPUP = None
root.buttons[1].fn()
check(G.POPUP == "FARMGOD_NOTE" and G.POPUP_DATA == "Bulma Brief", "a box to write it")
dialog = G.StaticPopupDialogs.FARMGOD_NOTE
popup = G.CreateFrame("Frame")
box = G.CreateFrame("EditBox", None, popup)
popup.GetEditBox = lambda self: box
dialog.OnShow(popup, "Bulma Brief")
check(box.text == L.NOTE_DEFAULT, "it starts as Farmer")
box.SetText(box, "Farmer pesada")
dialog.OnAccept(popup, "Bulma Brief")
check(notes["bulma brief"].note == "Farmer pesada", "accepted: noted")
popup.data = "Bulma Brief"
box.SetText(box, "")
dialog.EditBoxOnEnterPressed(box)
check(notes["bulma brief"] is None, "emptied with Enter: taken off")
root = G.MenuRoot()
player("party1", "Me", "Myself", me=True)
G.MENUS["MENU_UNIT_PARTY"](None, root, lua.table(unit="party1"))
check(len(list(root.buttons.values())) == 0, "not in your own menu")

# Slash: the box, taking it off, the list
G.POPUP = None
slash(nw)
check(G.POPUP == "FARMGOD_NOTE" and G.POPUP_DATA == "Goten Farmson", "/farmgod note alone with a target: the box")
out = slash(f"{nw} " + word("remove", "quitar"))
check(notes["goten farmson"] is None and out == [L.PREFIX + G.string.format(L.NOTE_REMOVED, "Goten Farmson")], "and taking it off")
S.units.target = None
out = slash(nw)
check(out[0] == L.PREFIX + L.NOTES_TITLE and len(out) == 3, f"alone with nobody targeted: the list: {out}")

# In the options
ns.ToggleOptions("notes")
ncontrols = {c.setting: c for c in page["notes"].controls.values()}
ned = ncontrols["note editor"]
nlist = ncontrols["notes"]
lines = [ln for ln in nlist.lines.values() if ln.shown]
check([ln.who.text for ln in lines] == ["|cffc69b6dVegeta Botson|r", "|cffc69b6dKrillin Bald|r"], f"the notes page, the last seen first: {[ln.who.text for ln in lines]}")
check(lines[0].seen.text == G.string.format(L.SEEN_AGO, L.AGO_NOW, "Elwynn Forest"), f"when and where: {lines[0].seen.text}")
ned.name.SetText(ned.name, "Piccolo Green")
ned.note.SetText(ned.note, "")
printed.clear()
ned.add.scripts.OnClick(ned.add)
check(printed == [L.PREFIX + L.NOTE_NEED_TEXT] and notes["piccolo green"] is None, "no note written: it asks for one")
ned.note.SetText(ned.note, "Farmer")
ned.note.scripts.OnEnterPressed(ned.note)
check(notes["piccolo green"].note == "Farmer" and ned.name.text == "", "written by name: noted")
check(len([ln for ln in nlist.lines.values() if ln.shown]) == 3, "and listed")
player("target", "Goku", "Son", "WARRIOR")
use_target = ncontrols[L.OPT_NOTE_TARGET]
use_target.scripts.OnClick(use_target)
check(ned.name.text == "Goku Son" and ned.note.focus, "your target's name filled in")
first = [ln for ln in nlist.lines.values() if ln.shown][0]
first.scripts.OnClick(first)
check(ned.name.text == "Vegeta Botson" and ned.note.text == "Bot", "click one: in the boxes to change it")
first.remove.scripts.OnClick(first.remove)
check(notes["vegeta botson"] is None and len([ln for ln in nlist.lines.values() if ln.shown]) == 2, "× takes it off")
mins = ncontrols[L.OPT_NOTE_MINUTES]
mins.scripts.OnValueChanged(mins, 10)
check(db.noteAlerts.minutes == 10, "how long before the same player is said again")
S.units.target = None
win.Hide(win)

# ---------------------------------------------------------------- The playing day: all the gold of the time you play
check(ns.Day() is not None and G.FarmGodCharDB.day.moneyStart == 1000000, "a day started at the login, with the gold you had")
ns.NewDay()
check(len(G.FarmGodCharDB.days) >= 1, "a new day: the one before goes to the list")
day = ns.Day()
start_played = ns.DayPlayed()


def money(delta):
    S.money = S.money + delta
    G.Fire("PLAYER_MONEY")


def kinds():
    return {k: (day.money[k].inc, day.money[k].out) for k in ns.MONEY_KINDS.values() if day.money[k].inc or day.money[k].out}


G.Fire("LOOT_OPENED", False, False)
money(10203)
G.Fire("LOOT_CLOSED")
G.Fire("MERCHANT_SHOW")
money(5000)  # greys sold
money(-2500)  # repairs
G.Fire("MERCHANT_CLOSED")
S.now = S.now + 10
G.Fire("QUEST_TURNED_IN", 123, 450, 3000)
money(3000)
S.now = S.now + 10
G.Fire("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", 17)  # the mailbox, as Midnight says it
money(20000)
G.Fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", 17)
S.now = S.now + 10
G.Fire("TAXIMAP_OPENED")
G.Fire("TAXIMAP_CLOSED")
S.now = S.now + 1
money(-200)  # the flight is paid just after the map closes
S.now = S.now + 10
money(7)
check(kinds() == {"loot": (10203, 0), "vendor": (5000, 2500), "quest": (3000, 0), "mail": (20000, 0), "taxi": (0, 200), "other": (7, 0)},
      f"each change of gold by the window it moved in: {kinds()}")
check(ns.DayNet() == 10203 + 5000 - 2500 + 3000 + 20000 - 200 + 7 and day.quests == 1, "gold made: what you have against the start")
if ns.SessionState() != "idle":
    slash(word("stop", "terminar"))
db.session.autoStart = False
loot(2770, 4)
G.Fire("PARTY_KILL", G.SECRET, G.SECRET)
check(cur() is None and day["items"][2770] == 4 and day.kills == 1, "loot and kills count for the day, with no session")
db.session.autoStart = True
S.xp, S.xpMax, S.level = S.xp + 100, S.xpMax, S.level
G.Fire("PLAYER_XP_UPDATE", "player")
check(day.xp == 100, "and XP")
S.now = S.now + 3600
check(abs(ns.DayPlayed() - start_played - 3641) < 1e-6, f"time played: {ns.DayPlayed() - start_played}")

# In the chat and in its tab
out = slash(word("day", "jornada"))
net = ns.DayNet()
check(len(out) == 1 and ("+" + M(net)) in out[0] and M(ns.DayLootWorth().total) in out[0], f"/farmgod day: {out}")
ns.ToggleOptions("day")
dcontrols = {c.setting: c for c in page["day"].controls.values()}
report = dcontrols["day report"]
rows_shown = [r.spec for r in report.rows.values() if r.shown]
lefts = {r.left: r.right for r in rows_shown}
check(lefts.get(L.DAY_NET) == "+" + M(net), f"the tab: gold made, {lefts.get(L.DAY_NET)}")
check(lefts.get(L.MONEY_IN.mail) == "+" + M(20000) and lefts.get(G.string.format(L.MONEY_QUESTS, 1)) == "+" + M(3000),
      "where it came from: mail, quests (with how many)")
check(lefts.get(L.MONEY_OUT.vendor) == "-" + M(2500) and lefts.get(L.MONEY_OUT.taxi) == "-" + M(200), "where it went: repairs, flights")
check(lefts.get(L.DAY_LOOT) == M(ns.DayLootWorth().total), "the loot at today's prices, apart")
check(any(r.left == L.SEC_DAYS for r in rows_shown) and any(r.tip is not None and r.kind == "line" and "·" in r.left for r in rows_shown),
      "and the days before, below")
past = [r for r in report.rows.values() if r.shown and r.spec.tip is not None and r.spec.left.count("·") == 1 and r.spec.kind == "line"]
past[0].scripts.OnEnter(past[0])
check(any(t.startswith(L.DAY_NET) for t in G.TOOLTIP.values()), "hover a past day: its gold")

# A new day by hand
new_day = dcontrols[L.OPT_NEW_DAY]
G.POPUP = None
new_day.scripts.OnClick(new_day)
check(G.POPUP == "FARMGOD_NEW_DAY", "starting another asks first")
G.StaticPopupDialogs.FARMGOD_NEW_DAY.OnAccept()
check(G.Same(G.FarmGodCharDB.days[1], day) and ns.DayNet(day) == net and ns.DayNet() == 0, "the day kept with its gold; the new one from zero")
win.Hide(win)

# Away a while: the same day, without the time away; away for hours: another
day = ns.Day()
G.Fire("PLAYER_LOGOUT")
played = ns.DayPlayed()
S.epoch, S.now = S.epoch + 3600, S.now + 3600
S.money = S.money + 50  # moved while the addon wasn't looking
G.Fire("PLAYER_LOGIN")
check(G.Same(ns.Day(), day) and ns.DayPlayed() == played and day.money.other.inc == 50,
      "back after an hour: the same day, the hour away not played")
G.Fire("PLAYER_LOGOUT")
S.epoch, S.now = S.epoch + 4 * 3600, S.now + 4 * 3600
G.Fire("PLAYER_LOGIN")
check(not G.Same(ns.Day(), day) and G.Same(G.FarmGodCharDB.days[1], day), "back after 4 hours: a new day")
db.day.gapHours = 6
check(db.day.gapHours == 6, "how many hours away end a day is yours to set")
db.day.gapHours = 3
button_tip = G.NAMED["FarmGodMinimapButton"]
button_tip.scripts.OnEnter(button_tip)
check(any(t.startswith(L.TIP_DAY) for t in G.TOOLTIP.values()), "the minimap button says the day too")

# ---------------------------------------------------------------- Reputation
slash(word("start", "empezar"))
G.RunTimers()  # the reading after the login: where each faction stands
s = cur()
S.factions[529].currentStanding = 3750  # Argent Dawn, +250
G.Fire("UPDATE_FACTION")
check(s.rep[529] == 250 and s.repNames[529] == "Argent Dawn", "250 with the Argent Dawn: in the session")
check(ns.Day().rep[529] == 250, "and in the day")
S.factions[576].currentStanding = 25  # Timbermaw from nothing: a kill's worth
S.factions[270].currentStanding = 6000  # Zandalar from nothing to 6,000: the game filling it in
G.Fire("UPDATE_FACTION")
check(s.rep[576] == 25 and (s.rep[270] is None), "a small gain from nothing counts; a jump from nothing doesn't")
S.factions[529].currentStanding = 3700
G.Fire("UPDATE_FACTION")
check(s.rep[529] == 200, "a loss comes off")
S.factions[529].currentStanding = 3750
G.Fire("UPDATE_FACTION")
slash(word("pause", "pausa"))
S.factions[529].currentStanding = 3800
G.Fire("UPDATE_FACTION")
check(s.rep[529] == 250 and ns.Day().rep[529] == 300, "paused: the day counts it, the session doesn't")
slash(word("start", "empezar"))
S.now = S.now + 1800
ns.UpdateTracker()
rep_rows = [f for f in G.FRAMES.values() if f.rep is not None and f.shown]
check([(r["name"].text, r.value.text) for r in rep_rows] == [
    ("Argent Dawn", "+250  ·  " + ns.Short(250 * 3600 / ns.Elapsed()) + "/h"), ("Timbermaw Hold", "+25  ·  " + ns.Short(25 * 3600 / ns.Elapsed()) + "/h")],
      f"the window: each faction, the gain and an hour, the most first: {[(r['name'].text, r.value.text) for r in rep_rows]}")
check(tuple(rep_rows[0]["name"].color.values()) == (0, 0.6, 0.1), "in the colour of its standing")
check(abs(rep_rows[0].fill.width - (db.tracker.width - 16) * 800 / 6000) < 1e-6, "its bar: how far into Friendly")
rep_rows[0].scripts.OnEnter(rep_rows[0])
tip = list(G.TOOLTIP.values())
check(f"Friendly | 800 / 6,000" in tip and any(t.startswith(G.string.format(L.REP_ETA, "5,200", "Honored", "")[:10]) for t in tip),
      f"hover: where you are in Friendly and how long to Honored: {tip}")
db.tracker.collapsed = True
ns.UpdateTracker()
check(not any(f.rep is not None and f.shown for f in G.FRAMES.values()), "folded: not there")
db.tracker.collapsed = False
db.tracker.rep = False
ns.UpdateTracker()
check(not any(f.rep is not None and f.shown for f in G.FRAMES.values()), "and it can be turned off")
db.tracker.rep = True
ns.ToggleOptions("day")
report = {c.setting: c for c in page["day"].controls.values()}["day report"]
specs = [r.spec for r in report.rows.values() if r.shown]
check(any(r.left == L.DAY_REP for r in specs) and any(r.left == "Argent Dawn" and r.right.startswith("+300") for r in specs),
      "the day lists it too")
win.Hide(win)
ended = cur()
slash(word("stop", "terminar"))
ns.ToggleOptions("history")
hist = [c for c in page["history"].controls.values() if c.setting == "history"][0]
line = [ln for ln in hist.lines.values() if ln.shown and G.Same(ln.session, ended)][0]
line.scripts.OnEnter(line)
check("Argent Dawn | +250" in list(G.TOOLTIP.values()), "and a past session's tooltip")
win.Hide(win)

# ---------------------------------------------------------------- The minimap button
button = G.NAMED["FarmGodMinimapButton"]
button.scripts.OnClick(button, "LeftButton")
check(not db.tracker.shown and not tracker.shown, "left click hides the window")
button.scripts.OnClick(button, "LeftButton")
check(tracker.shown, "and shows it")
S.shift = True
button.scripts.OnClick(button, "LeftButton")
S.shift = False
check(ns.SessionState() == "running", "shift-click starts a session")
button.scripts.OnEnter(button)
check(any(t.startswith(L.TIP_TOTAL) for t in G.TOOLTIP.values()), "its tooltip says what it's worth")
button.scripts.OnClick(button, "RightButton")
check(win.shown, "right click: the options")
win.Hide(win)
slash(word("stop", "terminar"))

out = slash("help")
check(len(out) == len(list(L.HELP.values())), "help lists the commands")
out = slash(word("button", "boton"))
check(db.minimapButton.hide and not button.shown, "the minimap button can be hidden")
slash("button")
check(button.shown, "and shown")

# ---------------------------------------------------------------- A client without some events: nothing stops
# (20 Nov 2026: one combat chat event Forever didn't have stopped Session.lua half loaded. After the next
# login the session read no loot and its clock stood still)
direct = [f for f in re.findall(r"^(\w+\.lua)$", toc, re.M) if f != "Init.lua"
          and re.search(r":Register(Unit)?Event\(", Path(ADDON, f).read_text(encoding="utf-8"))]
check(direct == [], f"every event goes through ns.Listen, which skips one the client doesn't have: {direct}")
lua2 = LuaRuntime(unpack_returned_tuples=True)
lua2.globals().py_print = lambda *a: printed.append(" ".join(str(x) for x in a))
lua2.globals().LOCALE = LOCALE
lua2.execute(MOCK)
G2 = lua2.globals()
for event in ("CHAT_MSG_COMBAT_HOSTILE_DEATH", "CHAT_MSG_COMBAT_XP_GAIN", "PARTY_KILL", "SHARD_TRANSFER", "TAXIMAP_OPENED"):
    G2.MISSING[event] = True
G2.FarmGodCharDB = lua2.eval('''{ current = { started = 1, zone = "", elapsed = 600, state = "running", money = 0, items = {},
  links = {}, quality = {}, gathers = {}, mobs = 0, kills = 0, xp = 0, skills = {} }, history = {} }''')
ns2 = lua2.table()
load2 = lua2.eval('function(src, name) return assert(loadstring(src, "@" .. name)) end')
for fname in re.findall(r"^(\w+\.lua)$", toc, re.M):
    load2(Path(ADDON, fname).read_text(encoding="utf-8"), fname)("FarmGod", ns2)
G2.Fire("ADDON_LOADED", "FarmGod")
G2.Fire("PLAYER_LOGIN")
G2.G.now = G2.G.now + 60
check(ns2.SessionState() == "running" and ns2.Elapsed() == 660, f"logged in with a session running: its clock goes on ({ns2.Elapsed()})")
G2.Fire("CHAT_MSG_LOOT", G2.string.format(G2.LOOT_ITEM_SELF, G2.Link(2770)))
check(G2.FarmGodCharDB.current["items"][2770] == 1, "and loot counts")
check(ns2.missingEvents.CHAT_MSG_COMBAT_HOSTILE_DEATH and ns2.missingEvents.TAXIMAP_OPENED, "the events it hasn't got are noted")
printed.clear()
G2.SlashCmdList.FARMGOD(word("events", "eventos"))
check(len(printed) == 1 and "CHAT_MSG_COMBAT_HOSTILE_DEATH" in printed[0], "/farmgod events lists them")

print()
print("FAILURES:" if fails else f"All good ({LOCALE}).", fails if fails else "")
sys.exit(1 if fails else 0)
