# FarmGod

Farming sessions for **WoW Forever**: everything you gather and loot (mining, herbalism, skinning, fishing or just killing mobs) and what it's worth, valued with **Auctionator or TSM prices** that update as soon as you scan the auction house.

Everything is set up from the **minimap button** (or `/farmgod`) in one options window. English and Spanish.

## The session window

- The time, what the session is worth and your **gold per hour**. Fold it down to just that line if you like it clean.
- Your loot by family, the most valuable first: grey items, ores and gems, herbs, leather and hides, cloth, elementals, meat and fish, enchanting, other materials, recipes, green gear, blue and epic gear. Hover a family to see each item, how many and what it's worth.
- A small **kill counter** in the title bar. Hover it for kills an hour and gold a kill.
- **Reputation** gained with each faction, an hour, with a bar for your standing. Hover it for how long until the next standing at your pace.
- Nodes mined, herbs picked, skins, fish, XP an hour and skill-ups at the foot.
- The session starts by itself when you loot or gather something. After 10 minutes with nothing looted it pauses, and those minutes don't count. It goes on with your next loot. It survives a /reload or a logout, and the time you're logged out doesn't count.

## Prices

- Auctionator, then TSM (DBMarket, or the price source you choose), or vendor prices only.
- Prices are read each time, never stored. Scan the auction house and your session (and your history) is worth today's prices. Close the auction house and FarmGod tells you what the session is worth now.
- For each family: auction price, vendor price or not counted. Green gear goes at vendor price by default, because greens are listed high and rarely sell. Blues and epics go at auction price. Grey items and items bound on pickup always go at what a vendor pays.
- Optionally take off the auction house's 5% cut, and use the better of the auction and vendor prices.

## Goals, like quest objectives

"40 Thorium Ore, 60 Thick Leather, 2 Arcane Crystals".
- Goals count what's in your bags (and your bank, if you want), with a bar in the window.
- Each step shows in yellow in the middle of the screen, as quest objectives do, and in green with the quest sound when a goal is met.
- Hover one to see how long the rest would take at your pace.
- Set them by dragging the item, shift-clicking it, typing its name, or with `/farmgod goal 40 [Thorium Ore]`.

## Your playing day

A summary of everything you play, session or not, until you've been away a few hours:
- the real **gold made** (what you have now against what you had) and per hour played;
- where it came from: looted gold, quests, vendors, mail, the auction house, trades;
- where it went: repairs and purchases, flights, trainers, the auction house;
- the loot you got, at today's prices;
- kills, nodes, quests, XP, reputation and the zones you played in.

Past days are kept, so you know what that six-hour evening of dungeons, farming and quests was really worth.

## Player notes: who's farming your layer

- Note a player ("Farmer", "Bot"…) from their right-click menu, or with `/farmgod note Farmer` on your target.
- When a noted player shows up near you (their nameplate, your target or your mouse), FarmGod tells you they're on your layer, and the window lists who was seen lately.
- Changing layer clears the list. The note also shows in their tooltip.

## Also

- The history of your last 30 sessions, at today's prices.
- A chat message when something you loot is worth 5 gold or more (you set how much).
- Works in dungeons too: your loot and rolls won, your share of the gold, and your group's kills.

Made for WoW Forever (game version 1.60.1). Forever hides some things from addons in combat and leaves out some game events: FarmGod works around both.
