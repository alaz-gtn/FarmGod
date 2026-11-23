local _, ns = ...

-- English first; the Spanish client overwrites what it has
local L = {
	PREFIX = "|cfff2c14eFarmGod:|r ",
	SUBTITLE = "Farming sessions and what they're worth",
	NOT_IN_COMBAT = "not in combat: try again when the fight is over.",
	UNLOCKED = "window unlocked: drag it where you want it. /farmgod lock when you're done.",
	LOCKED = "window locked.",
	YES = "yes",
	NO = "no",

	-- The session
	TRACKER_NAME = "FarmGod",
	STARTED = "session started.",
	RESUMED = "session resumed.",
	PAUSED = "session paused: loot doesn't count until you resume it.",
	IDLE_PAUSED = "session paused after %d minutes with nothing looted (they don't count). It goes on with your next loot.",
	ENDED = "session over: %s, worth %s. It's in the history.",
	ENDED_EMPTY = "session over (nothing in it, not kept).",
	RESET_DONE = "session back to zero.",
	RESET_CONFIRM = "Put the FarmGod session back to zero? What it has counted is lost (end it instead to keep it in the history).",
	CLEAR_CONFIRM = "Clear FarmGod's history of past sessions?",
	BIG_LOOT = "%s x%d, worth %s!",
	NO_SESSION = "no session going.",
	REPORT = "%s farming, worth %s (%s an hour), %d kills.",
	STATE_PAUSED = "paused",
	STATE_IDLE = "paused, idle",
	IDLE_HINT_AUTO = "No session. It starts by itself when you loot or gather something, or with the play button.",
	IDLE_HINT = "No session. Press play to start one.",
	PER_HOUR = "%s/h",
	LOOTED_GOLD = "Looted gold",
	XP = "XP %s",
	XP_HOUR = "XP %s/h",
	TIP_MORE = "...and %d more",
	TAG_VENDOR = "|cff9da3ad(vendor)|r",
	TAG_NO_PRICE = "|cff9da3adno price|r",
	TAG_SKIP = "|cff9da3adnot counted|r",
	PRICES_UPDATED = "prices updated: the session is now worth %s (it was %s).",
	THEN = ", then ",
	SOURCE_TEXT = {
		auction = "Prices: %s; what a vendor pays when there's none.",
		vendor = "Prices: what a vendor pays.",
		missing = "No price addon found (Auctionator or TSM): what a vendor pays.",
	},
	HISTORY_EMPTY = "No past sessions yet.",
	HISTORY_TITLE = "last sessions (with today's prices):",
	HISTORY_LINE = "  %s  %s  %s  %s  (%s/h)",
	HISTORY_DETAIL = "%s  ·  %s/h  ·  %s",

	-- Families of loot
	CATEGORY = {
		junk = "Grey items",
		ore = "Ores and gems",
		herb = "Herbs",
		leather = "Leather and hides",
		cloth = "Cloth",
		elemental = "Elementals",
		meat = "Meat and fish",
		enchanting = "Enchanting",
		mats = "Other materials",
		recipe = "Recipes",
		green = "Green gear",
		blue = "Blue and epic gear",
		other = "Other",
	},
	GATHER = { mining = "Mining", herb = "Herbs", skin = "Skinning", fish = "Fishing", pick = "Pickpocket" },

	-- The window's buttons
	BTN_START = "Start",
	BTN_PAUSE = "Pause",
	BTN_RESUME = "Resume",
	BTN_STOP = "End",
	BTN_RESET = "Reset",
	BTN_FOLD = "Fold / unfold",
	BTN_OPTIONS = "Options",

	-- Options
	TAB_SESSION = "Session",
	TAB_PRICES = "Prices",
	TAB_FAMILIES = "Families",
	TAB_HISTORY = "History",
	SEC_SESSION = "The session",
	OPT_TOGGLE = "Start, pause or resume the session",
	OPT_END = "End it and keep it in the history",
	OPT_RESET = "Back to zero (it isn't kept)",
	OPT_AUTO_START = "Start a session by itself when you loot or gather something",
	OPT_IDLE_ON = "Pause by itself when you loot nothing for a while (off: the real time counts)",
	OPT_IDLE = "After how many minutes",
	OPT_BIG_LOOT = "Say in the chat when loot is worth this much gold (0: never)",
	SESSION_HINT = "A paused session doesn't count loot. The pause for looting nothing is off unless you turn it on: then the minutes with nothing looted come off the session's time, and it goes on by itself with your next loot. The session survives a /reload or a logout; the time you're logged out doesn't count.",
	SEC_WINDOW = "The window",
	OPT_SHOW = "Show the session window",
	OPT_ONLY_ACTIVE = "Only while there's a session",
	OPT_LOCKED = "Lock it (the title bar doesn't move it)",
	OPT_COUNTS = "Nodes, fish, XP and skill-ups at its foot",
	OPT_WIDTH = "Width",
	OPT_SCALE = "Size (%)",
	OPT_ALPHA = "Background (%)",
	OPT_ROWS = "Families listed at most",
	SEC_SOURCE = "Where prices come from",
	OPT_SOURCE = "Price source",
	SOURCE = { auto = "Auctionator, then TSM", vendor = "Vendor only" },
	OPT_TSM = "TSM price",
	FOUND = "%s: %s",
	SEC_VALUE = "How loot is valued",
	OPT_BEST = "The better of the auction price and what a vendor pays",
	OPT_CUT = "Take off the auction house's 5% cut",
	OPT_FALLBACK = "No auction price: what a vendor pays",
	OPT_REFRESH = "Read the prices again",
	REFRESH = "Refresh",
	PRICES_HINT = "Prices are read each time, never stored: scan the auction house with Auctionator (or let TSM update) and the session, and the history, are worth today's prices. When you close the auction house it tells you what the session is worth now. Grey items and items bound when picked up go by what a vendor pays.",
	SEC_FAMILIES = "How each family is valued",
	MODE = { auction = "Auction price", vendor = "Vendor price", skip = "Don't count it" },
	FAMILIES_HINT = "Green gear goes by what a vendor pays: at the auction house greens are listed high, many never sell, and the price can't tell one suffix from another (of the Bear, of the Monkey). Blues and epics go at auction prices, a truer one (those bound when picked up, at a vendor's). Switch any of them here. Gathering materials are told apart by their kind in the game and, for vanilla's, by a list, in case Forever files one elsewhere. Hover a family in the session window to see its items.",
	SEC_HISTORY = "Past sessions",
	OPT_CLEAR = "Clear the history",
	CLEAR = "Clear",
	UNLOCK = "Move the window",
	LOCK = "Lock the window",
	OPT_MINIMAP_BUTTON = "Minimap button",

	-- Goals
	TAB_GOALS = "Goals",
	SEC_GOAL_ADD = "A new goal",
	ADD = "Add",
	AMOUNT = "How many",
	ITEM_PLACEHOLDER = "Name, id or shift-click an item",
	GOAL_ADD_HINT = "Drag an item from your bags onto the square, shift-click it while typing in the box, or write its name (an item the game has seen, in your bags or in a session) or its id. Adding one you already have changes its amount. Also: /farmgod goal 40 [Thorium Ore].",
	SEC_GOAL_OPTIONS = "How they count",
	OPT_GOAL_ANNOUNCE = "Each step in the middle of the screen, as quests do",
	OPT_GOAL_BANK = "Count what's in the bank too",
	OPT_GOALS_CLEAR = "Take off all the goals",
	GOALS_CLEAR_CONFIRM = "Take off all your FarmGod goals?",
	SEC_GOALS = "Your goals",
	GOALS_NONE_HINT = "No goals yet. Click one to change its amount; × takes it off.",
	GOALS_NONE = "no goals. /farmgod goal 40 [item] sets one.",
	GOALS_TITLE = "your goals:",
	GOALS_CLEARED = "goals cleared.",
	GOAL_SET = "goal: %d %s.",
	GOAL_REMOVED = "goal taken off: %s.",
	GOAL_USAGE = "write how many and the item: /farmgod goal 40 [Thorium Ore] (shift-click it), or its name or id.",
	GOAL_UNKNOWN = "I can't find \"%s\": shift-click it, drag it onto the square, or use its id.",
	GOAL_AMOUNT = "how many do you need?",
	GOAL_DONE = "goal met: %s x%d!",
	GOAL_DONE_TAG = "(done)",
	GOALS_ALL_DONE = "all your goals are met!",
	GOAL_HAVE = "You have",
	GOAL_SESSION = "This session",
	GOAL_RATE = "+%d (%s/h)",
	GOAL_ETA = "%d to go: about %s at this pace",
	GOAL_TIP_CLICK = "Click: the goals in the options",

	-- Notes on players
	TAB_NOTES = "Notes",
	SEC_NOTE_ADD = "A note on a player",
	NOTE_NAME_PLACEHOLDER = "Name Surname",
	NOTE_TEXT_PLACEHOLDER = "Farmer",
	NOTE_DEFAULT = "Farmer",
	OPT_NOTE_TARGET = "Fill in your target's name",
	USE_TARGET = "Target",
	NOTE_ADD_HINT = "Or right-click a player (their portrait, your target's, or their name in the chat) and pick FarmGod's note, or target them and type /farmgod note Farmer. Notes are for all your characters.",
	SEC_NOTE_ALERTS = "When one is near",
	OPT_NOTE_ALERT = "Say it in the chat",
	OPT_NOTE_CENTER = "And in the middle of the screen",
	OPT_NOTE_SOUND = "With a sound",
	OPT_NOTE_MINUTES = "Not again for the same player for (minutes)",
	OPT_NOTE_NEAR = "List who was seen lately in the session window",
	OPT_NOTE_NEAR_MINUTES = "For how long (minutes)",
	OPT_LAYER = "I changed layer: forget who I saw",
	NOTE_ALERT_HINT = "A noted player you see is on your layer: their nameplate, your target or your mouse over them. To see players of your own faction from far away, turn on friendly nameplates (Shift-V). Forever's layer change empties the list by itself; the button is in case it doesn't. In combat Forever may hide names: they count once the fight is over.",
	SEC_NOTES = "Noted players",
	NOTES_NONE_HINT = "No notes yet. Click one to change it; × takes it off.",
	NOTES_NONE = "no notes. Target a player and type /farmgod note Farmer.",
	NOTES_TITLE = "your notes:",
	NOTE_SET = "note for %s: %s.",
	NOTE_REMOVED = "note taken off: %s.",
	NOTE_NO_TARGET = "target a player first (or write the name in the Notes tab).",
	NOTE_NEED_NAME = "write the player's name.",
	NOTE_NEED_TEXT = "write the note (Farmer, for instance).",
	NOTE_POPUP = "FarmGod note for %s (empty to take it off):",
	NOTE_MENU_ADD = "FarmGod: add a note",
	NOTE_MENU_EDIT = "FarmGod: change the note",
	NOTE_SEEN = "%s (%s) is on your layer, in %s.",
	NOTE_SEEN_CENTER = "%s (%s) is on your layer",
	NOTE_TIP = "FarmGod: %s",
	NEAR = "On your layer: %s",
	SEEN_AGO = "seen %s ago, in %s",
	SEEN_NEVER = "not seen yet",
	AGO_NOW = "now",
	AGO_MIN = "%d min",
	AGO_HOUR = "%d h",
	AGO_DAY = "%d d",
	LAYER_CLEARED = "forgot who was on your last layer.",

	EVENTS_ALL = "the game has every event FarmGod listens to.",
	EVENTS_MISSING = "events this client doesn't have (skipped): %s",

	-- The playing day
	TAB_DAY = "Day",
	SEC_DAY = "Your playing day",
	OPT_NEW_DAY = "Start a new day now (this one goes to the list)",
	NEW = "New",
	OPT_DAY_GAP = "A day ends after this many hours logged out",
	NEW_DAY_CONFIRM = "Close this FarmGod day and start a new one?",
	NEW_DAY_DONE = "a new day starts now.",
	DAY_STARTED = "Started %s",
	DAY_PLAYED = "%s played",
	DAY_NET = "Gold made",
	DAY_NET_HOUR = "An hour played",
	DAY_GOLD_NOW = "Your gold",
	DAY_GOLD_NOW_VALUE = "%s (%s when it started)",
	DAY_INCOME = "Came in",
	DAY_SPENT = "Went out",
	MONEY_IN = {
		loot = "Looted gold", quest = "Quests", vendor = "Sold to vendors", mail = "Mail (auctions sold, others')",
		auction = "Auction house", trade = "Trades", trainer = "Trainers", taxi = "Flights", other = "Other",
	},
	MONEY_OUT = {
		loot = "Loot", quest = "Quests", vendor = "Bought and repairs", mail = "Mail sent", auction = "Auction house (buys and deposits)",
		trade = "Trades", trainer = "Trainers", taxi = "Flights", other = "Other",
	},
	MONEY_QUESTS = "Quests (%d)",
	DAY_LOOT = "Loot, at today's prices",
	DAY_LOOT_NOTE = "What you've already sold of it is in the gold above too (sold to vendors, mail): the two aren't added up.",
	DAY_KILLS = "%d kills",
	DAY_NODES = "%d nodes",
	DAY_QUESTS = "%d quests",
	DAY_XP = "XP %s",
	DAY_SESSIONS = "%d farming sessions",
	DAY_ZONES = "Where: %s",
	SEC_DAYS = "Past days",
	DAYS_NONE = "No past days yet.",
	DAY_LINE_RIGHT = "%s  ·  loot %s",
	DAY_REPORT = "day: %s played, %s gold (%s an hour played), loot worth %s, %d kills, %d quests.",
	TIP_DAY = "Day",
	NEEDS_RESTART = "Reload the interface (/reload) to see this: it comes in a new file.",

	REP_SESSION = "This session",
	REP_HOUR = "An hour",
	REP_ETA = "%s to %s: about %s at this pace",
	REP_TOP = "%s: the top",
	OPT_REP = "Reputation gained, under the families (hover a faction for the next standing)",
	DAY_REP = "Reputation",
	-- Crafting cost in item tooltips
	SEC_CRAFT = "Crafting cost in item tooltips",
	OPT_CRAFT = "Show what an item costs to craft in its tooltip",
	CRAFT_HINT = "For any item a profession makes, even one none of your characters has: its materials with these prices (each at the cheaper of the auction house and a vendor that sells it), against the item's own auction price. Shift shows each material. The recipes come with FarmGod, from AtlasLoot Forever's data: no recipe addon needed.",
	CRAFT_COST = "Crafting cost",
	CRAFT_VS_AH = "At the auction house: %s",
	CRAFT_CHEAPER = "%s cheaper to craft",
	CRAFT_DEARER = "%s dearer to craft",
	CRAFT_RECIPE = "Recipe",
	CRAFT_MAKES = "makes %d",
	CRAFT_SHIFT = "Shift: the materials",
	CRAFT_PER_UNIT = "The cost is for one: the recipe makes %d.",
	CRAFT_CHEAPEST = "The cheapest of its %d recipes.",
	PROFESSION = {
		[1] = "First Aid", [2] = "Blacksmithing", [3] = "Leatherworking", [4] = "Alchemy", [6] = "Cooking",
		[7] = "Mining", [8] = "Tailoring", [9] = "Engineering", [10] = "Enchanting", [13] = "Poisons",
	},

	TIP_KILLS = "Kills",
	TIP_LOOTED = "Looted",
	TIP_PER_KILL = "Worth a kill",
	OPT_KILLS = "Kill counter in the title bar (hover it for kills an hour)",
	TIP_TIME = "Time",
	TIP_TOTAL = "Worth",
	TIP_HOUR = "An hour",
	TIP_LEFT = "Left click: show or hide the window",
	TIP_SHIFT = "Shift-click: start or pause",
	TIP_RIGHT = "Right click: options",
	TIP_DRAG = "Drag: move this button",

	HELP = {
		"|cfff2c14eFarmGod|r commands:",
		"  /farmgod  - options (or right click the minimap button)",
		"  /farmgod start | pause | stop | reset  - the session",
		"  /farmgod report  - what the session is worth",
		"  /farmgod goal 40 [item]  - a goal (0 takes it off; alone it lists them; clear takes all off)",
		"  /farmgod note Farmer  - a note on your target (remove takes it off; alone it lists them)",
		"  /farmgod layer  - you changed layer: forget who you saw",
		"  /farmgod day  - your playing day: gold made, where from, loot, kills",
		"  /farmgod history  - the last sessions",
		"  /farmgod prices  - read the prices again",
		"  /farmgod show  - show or hide the window",
		"  /farmgod unlock | lock  - move the window",
		"  /farmgod button  - show or hide the minimap button",
	},
}

if GetLocale() == "esES" or GetLocale() == "esMX" then
	L.SUBTITLE = "Sesiones de farmeo y lo que valen"
	L.NOT_IN_COMBAT = "no en combate: vuelve a probar cuando acabe la pelea."
	L.UNLOCKED = "ventana desbloqueada: arrástrala donde quieras. /farmgod bloquear cuando acabes."
	L.LOCKED = "ventana bloqueada."
	L.YES = "sí"
	L.NO = "no"

	L.STARTED = "sesión empezada."
	L.RESUMED = "sesión reanudada."
	L.PAUSED = "sesión en pausa: el botín no cuenta hasta que la reanudes."
	L.IDLE_PAUSED = "sesión en pausa tras %d minutos sin despojar nada (no cuentan). Sigue sola con tu próximo botín."
	L.ENDED = "sesión terminada: %s, vale %s. Está en el historial."
	L.ENDED_EMPTY = "sesión terminada (vacía, no se guarda)."
	L.RESET_DONE = "sesión puesta a cero."
	L.RESET_CONFIRM = "¿Poner a cero la sesión de FarmGod? Se pierde lo contado (si quieres guardarla en el historial, termínala)."
	L.CLEAR_CONFIRM = "¿Borrar el historial de sesiones de FarmGod?"
	L.BIG_LOOT = "¡%s x%d, vale %s!"
	L.NO_SESSION = "no hay ninguna sesión."
	L.REPORT = "%s farmeando, vale %s (%s por hora), %d bichos matados."
	L.STATE_PAUSED = "en pausa"
	L.STATE_IDLE = "en pausa, sin actividad"
	L.IDLE_HINT_AUTO = "Sin sesión. Empieza sola al despojar o recolectar algo, o con el botón de play."
	L.IDLE_HINT = "Sin sesión. Pulsa play para empezar una."
	L.LOOTED_GOLD = "Oro despojado"
	L.XP = "Exp %s"
	L.XP_HOUR = "Exp %s/h"
	L.TIP_MORE = "...y %d más"
	L.TAG_VENDOR = "|cff9da3ad(vendedor)|r"
	L.TAG_NO_PRICE = "|cff9da3adsin precio|r"
	L.TAG_SKIP = "|cff9da3adno cuenta|r"
	L.PRICES_UPDATED = "precios actualizados: la sesión vale ahora %s (antes %s)."
	L.THEN = ", luego "
	L.SOURCE_TEXT = {
		auction = "Precios: %s; si no hay, lo que paga un vendedor.",
		vendor = "Precios: lo que paga un vendedor.",
		missing = "No hay addon de precios (Auctionator o TSM): lo que paga un vendedor.",
	}
	L.HISTORY_EMPTY = "Todavía no hay sesiones pasadas."
	L.HISTORY_TITLE = "últimas sesiones (con los precios de hoy):"

	L.CATEGORY = {
		junk = "Objetos grises",
		ore = "Menas y gemas",
		herb = "Hierbas",
		leather = "Cuero y pieles",
		cloth = "Telas",
		elemental = "Elementales",
		meat = "Carne y pescado",
		enchanting = "Encantamiento",
		mats = "Otros materiales",
		recipe = "Recetas",
		green = "Equipo verde",
		blue = "Equipo azul y épico",
		other = "Otros",
	}
	L.GATHER = { mining = "Minería", herb = "Hierbas", skin = "Desuello", fish = "Pesca", pick = "Robos" }

	L.BTN_START = "Empezar"
	L.BTN_PAUSE = "Pausa"
	L.BTN_RESUME = "Seguir"
	L.BTN_STOP = "Terminar"
	L.BTN_RESET = "Poner a cero"
	L.BTN_FOLD = "Plegar / desplegar"
	L.BTN_OPTIONS = "Opciones"

	L.TAB_SESSION = "Sesión"
	L.TAB_PRICES = "Precios"
	L.TAB_FAMILIES = "Familias"
	L.TAB_HISTORY = "Historial"
	L.SEC_SESSION = "La sesión"
	L.OPT_TOGGLE = "Empezar, pausar o reanudar la sesión"
	L.OPT_END = "Terminarla y guardarla en el historial"
	L.OPT_RESET = "Ponerla a cero (no se guarda)"
	L.OPT_AUTO_START = "Empezar una sesión sola al despojar o recolectar algo"
	L.OPT_IDLE_ON = "Pausar sola si pasas un rato sin despojar nada (apagado: cuenta el tiempo real)"
	L.OPT_IDLE = "Tras cuántos minutos"
	L.OPT_BIG_LOOT = "Avisar en el chat del botín que valga este oro (0: nunca)"
	L.SESSION_HINT = "Una sesión en pausa no cuenta el botín. La pausa por no despojar nada está apagada salvo que la enciendas: entonces los minutos sin despojar nada se quitan del tiempo de la sesión, y sigue sola con tu próximo botín. La sesión aguanta un /reload o salir del juego; el tiempo desconectado no cuenta."
	L.SEC_WINDOW = "La ventana"
	L.OPT_SHOW = "Mostrar la ventana de la sesión"
	L.OPT_ONLY_ACTIVE = "Solo mientras haya una sesión"
	L.OPT_LOCKED = "Bloquearla (la barra de título no la mueve)"
	L.OPT_COUNTS = "Nodos, peces, experiencia y subidas de habilidad abajo"
	L.OPT_WIDTH = "Ancho"
	L.OPT_SCALE = "Tamaño (%)"
	L.OPT_ALPHA = "Fondo (%)"
	L.OPT_ROWS = "Familias que se listan como mucho"
	L.SEC_SOURCE = "De dónde salen los precios"
	L.OPT_SOURCE = "Fuente de precios"
	L.SOURCE = { auto = "Auctionator, luego TSM", vendor = "Solo vendedor" }
	L.OPT_TSM = "Precio de TSM"
	L.SEC_VALUE = "Cómo se valora el botín"
	L.OPT_BEST = "Lo mejor entre el precio de subasta y lo que paga un vendedor"
	L.OPT_CUT = "Descontar la comisión del 5% de la casa de subastas"
	L.OPT_FALLBACK = "Sin precio de subasta: lo que paga un vendedor"
	L.OPT_REFRESH = "Volver a leer los precios"
	L.REFRESH = "Actualizar"
	L.PRICES_HINT = "Los precios se leen cada vez, nunca se guardan: escanea la casa de subastas con Auctionator (o deja que TSM se actualice) y la sesión, y también el historial, valen con los precios de hoy. Al cerrar la casa de subastas te dice cuánto vale ahora la sesión. Los objetos grises y los que se ligan al recogerlos van por lo que paga un vendedor."
	L.SEC_FAMILIES = "Cómo se valora cada familia"
	L.MODE = { auction = "Precio de subasta", vendor = "Precio de vendedor", skip = "No contarla" }
	L.FAMILIES_HINT = "El equipo verde va a lo que paga un vendedor: en subasta los verdes se anuncian caros, muchos no se venden nunca y el precio no distingue un sufijo de otro (del Oso, del Mono). Los azules y épicos van a precio de subasta, que es más fiable (los que se ligan al recogerlos, a precio de vendedor). Cualquiera se cambia aquí. Los materiales de recolección se distinguen por su tipo en el juego y, los del clásico, también por una lista, por si Forever guarda alguno en otro sitio. Pasa el ratón por una familia en la ventana de la sesión para ver sus objetos."
	L.SEC_HISTORY = "Sesiones pasadas"
	L.OPT_CLEAR = "Borrar el historial"
	L.CLEAR = "Borrar"
	L.UNLOCK = "Mover la ventana"
	L.LOCK = "Bloquear la ventana"
	L.OPT_MINIMAP_BUTTON = "Botón del minimapa"

	L.TAB_GOALS = "Objetivos"
	L.SEC_GOAL_ADD = "Nuevo objetivo"
	L.ADD = "Añadir"
	L.AMOUNT = "Cuántos"
	L.ITEM_PLACEHOLDER = "Nombre, ID o Mayús+clic en un objeto"
	L.GOAL_ADD_HINT = "Arrastra un objeto de tus bolsas al cuadro, haz Mayús+clic en él mientras escribes en la casilla, o escribe su nombre (de un objeto que el juego ya haya visto, en tus bolsas o en una sesión) o su ID. Si añades uno que ya tienes, cambia su cantidad. También: /farmgod objetivo 40 [Mena de torio]."
	L.SEC_GOAL_OPTIONS = "Cómo cuentan"
	L.OPT_GOAL_ANNOUNCE = "Cada paso en el centro de la pantalla, como las misiones"
	L.OPT_GOAL_BANK = "Contar también lo que hay en el banco"
	L.OPT_GOALS_CLEAR = "Quitar todos los objetivos"
	L.GOALS_CLEAR_CONFIRM = "¿Quitar todos tus objetivos de FarmGod?"
	L.SEC_GOALS = "Tus objetivos"
	L.GOALS_NONE_HINT = "Todavía no hay objetivos. Haz clic en uno para cambiar su cantidad; × lo quita."
	L.GOALS_NONE = "no hay objetivos. /farmgod objetivo 40 [objeto] pone uno."
	L.GOALS_TITLE = "tus objetivos:"
	L.GOALS_CLEARED = "objetivos quitados."
	L.GOAL_SET = "objetivo: %d %s."
	L.GOAL_REMOVED = "objetivo quitado: %s."
	L.GOAL_USAGE = "escribe cuántos y el objeto: /farmgod objetivo 40 [Mena de torio] (con Mayús+clic), o su nombre o su ID."
	L.GOAL_UNKNOWN = "no encuentro \"%s\": haz Mayús+clic en él, arrástralo al cuadro o usa su ID."
	L.GOAL_AMOUNT = "¿cuántos necesitas?"
	L.GOAL_DONE = "¡objetivo cumplido: %s x%d!"
	L.GOAL_DONE_TAG = "(cumplido)"
	L.GOALS_ALL_DONE = "¡has cumplido todos tus objetivos!"
	L.GOAL_HAVE = "Tienes"
	L.GOAL_SESSION = "Esta sesión"
	L.GOAL_ETA = "Faltan %d: unos %s a este ritmo"
	L.GOAL_TIP_CLICK = "Clic: los objetivos en las opciones"

	L.TAB_NOTES = "Notas"
	L.SEC_NOTE_ADD = "Nota a un jugador"
	L.NOTE_NAME_PLACEHOLDER = "Nombre Apellido"
	L.OPT_NOTE_TARGET = "Rellenar con el nombre de tu objetivo"
	L.USE_TARGET = "Objetivo"
	L.NOTE_ADD_HINT = "También: clic derecho en un jugador (su retrato, el de tu objetivo o su nombre en el chat) y la nota de FarmGod, o selecciónalo y escribe /farmgod nota Farmer. Las notas valen para todos tus personajes."
	L.SEC_NOTE_ALERTS = "Cuando hay uno cerca"
	L.OPT_NOTE_ALERT = "Avisar en el chat"
	L.OPT_NOTE_CENTER = "Y en el centro de la pantalla"
	L.OPT_NOTE_SOUND = "Con un sonido"
	L.OPT_NOTE_MINUTES = "No repetir el aviso del mismo jugador durante (minutos)"
	L.OPT_NOTE_NEAR = "Listar en la ventana de la sesión a los vistos hace poco"
	L.OPT_NOTE_NEAR_MINUTES = "Durante cuánto (minutos)"
	L.OPT_LAYER = "He cambiado de capa: olvidar a los que vi"
	L.NOTE_ALERT_HINT = "Un jugador con nota que ves está en tu capa: por su placa de nombre, porque lo seleccionas o porque le pasas el ratón por encima. Para ver de lejos a los de tu facción, activa las placas de nombre de aliados (Mayús+V). El cambio de capa de Forever vacía la lista solo; el botón es por si no lo hace. En combate Forever puede esconder los nombres: cuentan al acabar la pelea."
	L.SEC_NOTES = "Jugadores con nota"
	L.NOTES_NONE_HINT = "Todavía no hay notas. Haz clic en una para cambiarla; × la quita."
	L.NOTES_NONE = "no hay notas. Selecciona a un jugador y escribe /farmgod nota Farmer."
	L.NOTES_TITLE = "tus notas:"
	L.NOTE_SET = "nota para %s: %s."
	L.NOTE_REMOVED = "nota quitada: %s."
	L.NOTE_NO_TARGET = "selecciona antes a un jugador (o escribe su nombre en la pestaña Notas)."
	L.NOTE_NEED_NAME = "escribe el nombre del jugador."
	L.NOTE_NEED_TEXT = "escribe la nota (Farmer, por ejemplo)."
	L.NOTE_POPUP = "Nota de FarmGod para %s (vacía para quitarla):"
	L.NOTE_MENU_ADD = "FarmGod: poner una nota"
	L.NOTE_MENU_EDIT = "FarmGod: cambiar la nota"
	L.NOTE_SEEN = "%s (%s) está en tu capa, en %s."
	L.NOTE_SEEN_CENTER = "%s (%s) está en tu capa"
	L.NEAR = "En tu capa: %s"
	L.SEEN_AGO = "visto hace %s, en %s"
	L.SEEN_NEVER = "sin ver todavía"
	L.AGO_NOW = "ahora"
	L.LAYER_CLEARED = "olvidados los que estaban en tu capa anterior."

	L.EVENTS_ALL = "el juego tiene todos los eventos que escucha FarmGod."
	L.EVENTS_MISSING = "eventos que este cliente no tiene (se saltan): %s"

	L.TAB_DAY = "Jornada"
	L.SEC_DAY = "Tu jornada"
	L.OPT_NEW_DAY = "Empezar otra jornada ahora (esta pasa a la lista)"
	L.NEW = "Nueva"
	L.OPT_DAY_GAP = "Una jornada acaba tras estas horas desconectado"
	L.NEW_DAY_CONFIRM = "¿Cerrar esta jornada de FarmGod y empezar otra?"
	L.NEW_DAY_DONE = "empieza una jornada nueva."
	L.DAY_STARTED = "Empezó el %s"
	L.DAY_PLAYED = "%s jugadas"
	L.DAY_NET = "Oro ganado"
	L.DAY_NET_HOUR = "Por hora jugada"
	L.DAY_GOLD_NOW = "Tu oro"
	L.DAY_GOLD_NOW_VALUE = "%s (%s al empezar)"
	L.DAY_INCOME = "Entró"
	L.DAY_SPENT = "Salió"
	L.MONEY_IN = {
		loot = "Oro despojado", quest = "Misiones", vendor = "Ventas a vendedor", mail = "Correo (subastas vendidas, otros)",
		auction = "Casa de subastas", trade = "Comercio", trainer = "Instructores", taxi = "Vuelos", other = "Otros",
	}
	L.MONEY_OUT = {
		loot = "Botín", quest = "Misiones", vendor = "Compras y reparaciones", mail = "Envíos por correo",
		auction = "Casa de subastas (compras y depósitos)", trade = "Comercio", trainer = "Instructores", taxi = "Vuelos", other = "Otros",
	}
	L.MONEY_QUESTS = "Misiones (%d)"
	L.DAY_LOOT = "Botín, a precios de hoy"
	L.DAY_LOOT_NOTE = "Lo que ya hayas vendido está también arriba, en el oro (ventas a vendedor, correo): no se suman."
	L.DAY_KILLS = "%d bichos"
	L.DAY_NODES = "%d nodos"
	L.DAY_QUESTS = "%d misiones"
	L.DAY_XP = "Exp %s"
	L.DAY_SESSIONS = "%d sesiones de farmeo"
	L.DAY_ZONES = "Dónde: %s"
	L.SEC_DAYS = "Jornadas anteriores"
	L.DAYS_NONE = "Todavía no hay jornadas anteriores."
	L.DAY_LINE_RIGHT = "%s  ·  botín %s"
	L.DAY_REPORT = "jornada: %s jugadas, %s de oro (%s por hora jugada), botín por %s, %d bichos, %d misiones."
	L.TIP_DAY = "Jornada"
	L.NEEDS_RESTART = "Recarga la interfaz (/reload) para ver esto: viene en un archivo nuevo."

	L.REP_SESSION = "Esta sesión"
	L.REP_HOUR = "Por hora"
	L.REP_ETA = "Faltan %s para %s: unos %s a este ritmo"
	L.REP_TOP = "%s: lo más alto"
	L.OPT_REP = "Reputación ganada, bajo las familias (pasa el ratón por una facción para ver el siguiente nivel)"
	L.DAY_REP = "Reputación"
	L.SEC_CRAFT = "Coste de fabricación en los tooltips"
	L.OPT_CRAFT = "Mostrar en el tooltip lo que cuesta fabricar un objeto"
	L.CRAFT_HINT = "Para cualquier objeto que haga una profesión, aunque no la tenga ninguno de tus personajes: sus materiales con estos precios (cada uno a lo más barato entre la casa de subastas y un vendedor que lo venda), frente al precio en subasta del propio objeto. Con Mayús, cada material. Las recetas van dentro de FarmGod, con los datos de AtlasLoot Forever: no hace falta ningún addon de recetas."
	L.CRAFT_COST = "Coste de fabricación"
	L.CRAFT_VS_AH = "En subasta: %s"
	L.CRAFT_CHEAPER = "%s más barato fabricarlo"
	L.CRAFT_DEARER = "%s más caro fabricarlo"
	L.CRAFT_RECIPE = "Receta"
	L.CRAFT_MAKES = "crea %d"
	L.CRAFT_SHIFT = "Mayús: los materiales"
	L.CRAFT_PER_UNIT = "El coste es por unidad: la receta crea %d."
	L.CRAFT_CHEAPEST = "La más barata de sus %d recetas."
	L.PROFESSION = {
		[1] = "Primeros auxilios", [2] = "Herrería", [3] = "Peletería", [4] = "Alquimia", [6] = "Cocina",
		[7] = "Minería", [8] = "Sastrería", [9] = "Ingeniería", [10] = "Encantamiento", [13] = "Venenos",
	}

	L.TIP_KILLS = "Bichos matados"
	L.TIP_LOOTED = "Despojados"
	L.TIP_PER_KILL = "Por bicho"
	L.OPT_KILLS = "Contador de bichos matados en la barra de título (pasa el ratón para verlos por hora)"
	L.TIP_TIME = "Tiempo"
	L.TIP_TOTAL = "Vale"
	L.TIP_HOUR = "Por hora"
	L.TIP_LEFT = "Clic izquierdo: mostrar u ocultar la ventana"
	L.TIP_SHIFT = "Mayús+clic: empezar o pausar"
	L.TIP_RIGHT = "Clic derecho: opciones"
	L.TIP_DRAG = "Arrastrar: mover este botón"

	L.HELP = {
		"Comandos de |cfff2c14eFarmGod|r:",
		"  /farmgod  - opciones (o clic derecho en el botón del minimapa)",
		"  /farmgod empezar | pausa | terminar | reiniciar  - la sesión",
		"  /farmgod informe  - lo que vale la sesión",
		"  /farmgod objetivo 40 [objeto]  - un objetivo (0 lo quita; solo, los lista; borrar los quita todos)",
		"  /farmgod nota Farmer  - una nota a tu objetivo (quitar la quita; solo, las lista)",
		"  /farmgod capa  - has cambiado de capa: olvidar a los que viste",
		"  /farmgod jornada  - tu jornada: oro ganado, de dónde, botín, bichos",
		"  /farmgod historial  - las últimas sesiones",
		"  /farmgod precios  - volver a leer los precios",
		"  /farmgod mostrar  - mostrar u ocultar la ventana",
		"  /farmgod desbloquear | bloquear  - mover la ventana",
		"  /farmgod boton  - mostrar u ocultar el botón del minimapa",
	}
end

ns.L = L
