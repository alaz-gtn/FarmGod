# FarmGod

*Farming tracker for WoW Forever · Tracker de farmeo para WoW Forever*

> ⚠️ **Needs a price addon: [Auctionator](https://www.curseforge.com/wow/addons/auctionator) or [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskill-master)** for auction house prices. Without one, FarmGod still works, but values your loot at what a vendor pays.
>
> ⚠️ **Necesita un addon de precios: [Auctionator](https://www.curseforge.com/wow/addons/auctionator) o [TradeSkillMaster](https://www.curseforge.com/wow/addons/tradeskill-master)** para los precios de la casa de subastas. Sin ninguno, FarmGod funciona igual, pero valora el botín a lo que paga un vendedor.

### At a glance

- 💰 **Gold earned farming**: mining, skinning, herbalism, fishing… and killing mobs, valued with Auctionator or TSM prices
- ⭐ **Reputation gained**
- 💀 **Kills**
- 📈 **Experience**
- 👀 **Mark players who are also farming**: you're told when they show up, so you know when to change layer
- 📜 **Track the materials you need**, like a quest's objectives ("40 Thorium Ore")
- 🕒 **Gold per hour**, and a summary of your whole playing day

### De un vistazo

- 💰 **Oro ganado farmeando**: minería, desuello, herboristería, pesca… y matando bichos, valorado con los precios de Auctionator o TSM
- ⭐ **Reputación ganada**
- 💀 **Bichos matados (kills)**
- 📈 **Experiencia**
- 👀 **Marca a los jugadores que también están farmeando**: te avisa cuando aparecen, para saber cuándo cambiar de capa (layer)
- 📜 **Sigue los materiales que necesitas**, como si fueran los objetivos de una misión ("40 menas de torio")
- 🕒 **Oro por hora**, y un resumen de toda tu jornada de juego

Everything is set up from the **minimap button** or `/farmgod`. English and Spanish.
Todo se configura desde el **botón del minimapa** o con `/farmgod`. En inglés y en español.

---

## In detail

### The session window

- The time, what the session is worth and your **gold per hour**. Fold it down to just that line if you like it clean.
- Your loot by family, the most valuable first: grey items, ores and gems, herbs, leather and hides, cloth, elementals, meat and fish, enchanting, other materials, recipes, green gear, blue and epic gear. Hover a family to see each item, how many and what it's worth.
- A small **kill counter** in the title bar. Hover it for kills an hour and gold a kill.
- **Reputation** gained with each faction, an hour, with a bar for your standing. Hover it for how long until the next standing at your pace.
- Nodes mined, herbs picked, skins, fish, XP an hour and skill-ups at the foot.
- The session starts by itself when you loot or gather something. After 10 minutes with nothing looted it pauses, and those minutes don't count. It goes on with your next loot. It survives a /reload or a logout, and the time you're logged out doesn't count.

### Prices

- Auctionator, then TSM (DBMarket, or the price source you choose), or vendor prices only.
- Prices are read each time, never stored. Scan the auction house and your session (and your history) is worth today's prices. Close the auction house and FarmGod tells you what the session is worth now.
- For each family: auction price, vendor price or not counted. Green gear goes at vendor price by default, because greens are listed high and rarely sell. Blues and epics go at auction price. Grey items and items bound on pickup always go at what a vendor pays.
- Optionally take off the auction house's 5% cut, and use the better of the auction and vendor prices.

### Goals, like quest objectives

"40 Thorium Ore, 60 Thick Leather, 2 Arcane Crystals".
- Goals count what's in your bags (and your bank, if you want), with a bar in the window.
- Each step shows in yellow in the middle of the screen, as quest objectives do, and in green with the quest sound when a goal is met.
- Hover one to see how long the rest would take at your pace.
- Set them by dragging the item, shift-clicking it, typing its name, or with `/farmgod goal 40 [Thorium Ore]`.

### Your playing day

A summary of everything you play, session or not, until you've been away a few hours:
- the real **gold made** (what you have now against what you had) and per hour played;
- where it came from: looted gold, quests, vendors, mail, the auction house, trades;
- where it went: repairs and purchases, flights, trainers, the auction house;
- the loot you got, at today's prices;
- kills, nodes, quests, XP, reputation and the zones you played in.

Past days are kept, so you know what that six-hour evening of dungeons, farming and quests was really worth.

### Player notes: who's farming your layer

- Note a player ("Farmer", "Bot"…) from their right-click menu, or with `/farmgod note Farmer` on your target.
- When a noted player shows up near you (their nameplate, your target or your mouse), FarmGod tells you they're on your layer, and the window lists who was seen lately.
- Changing layer clears the list. The note also shows in their tooltip.

### Also

- The history of your last 30 sessions, at today's prices.
- A chat message when something you loot is worth 5 gold or more (you set how much).
- Works in dungeons too: your loot and rolls won, your share of the gold, and your group's kills.

Made for WoW Forever (game version 1.60.1). Forever hides some things from addons in combat and leaves out some game events: FarmGod works around both.

---

## En detalle

### La ventana de la sesión

- El tiempo, lo que vale la sesión y tu **oro por hora**. Si la quieres limpia, pliégala y se queda solo esa línea.
- Tu botín por familias, la más valiosa primero: objetos grises, menas y gemas, hierbas, cuero y pieles, telas, elementales, carne y pescado, encantamiento, otros materiales, recetas, equipo verde, equipo azul y épico. Pasa el ratón por una familia para ver cada objeto, cuántos llevas y lo que vale.
- Un **contador de bichos matados** pequeño en la barra de título. Al pasar el ratón: bichos por hora y oro por bicho.
- La **reputación** ganada con cada facción, por hora, con una barra de tu nivel. Al pasar el ratón: cuánto tardarías en el siguiente nivel a tu ritmo.
- Abajo: nodos de minería, hierbas, pieles, peces, experiencia por hora y subidas de habilidad.
- La sesión empieza sola cuando despojas o recolectas algo. Tras 10 minutos sin despojar nada se pausa, y esos minutos no cuentan; sigue sola con tu próximo botín. Aguanta un /reload o salir del juego, y el tiempo desconectado no cuenta.

### Precios

- Auctionator y, si no tiene el objeto, TSM (DBMarket o la fuente de precios que elijas); o solo precio de vendedor.
- Los precios se leen cada vez, nunca se guardan. Escanea la casa de subastas y la sesión (y el historial) vale con los precios de hoy. Al cerrar la casa de subastas, FarmGod te dice cuánto vale ahora la sesión.
- Para cada familia: precio de subasta, precio de vendedor o no contarla. El equipo verde va por defecto a precio de vendedor, porque en subasta se anuncia caro y casi no se vende. El azul y el épico, a precio de subasta. Los grises y lo que se liga al recogerlo, siempre a lo que paga un vendedor.
- Opcional: descontar el 5% de la casa de subastas y quedarte con lo mejor entre subasta y vendedor.

### Objetivos, como los de una misión

"40 menas de torio, 60 de cuero grueso, 2 cristales arcanos".
- Cuentan lo que llevas en las bolsas (y en el banco, si quieres), con una barra en la ventana.
- Cada avance sale en amarillo en el centro de la pantalla, como en las misiones, y en verde con el sonido de misión cuando lo cumples.
- Al pasar el ratón: cuánto tardarías en el resto a tu ritmo.
- Se ponen arrastrando el objeto, con Mayús+clic, escribiendo su nombre o con `/farmgod objetivo 40 [Mena de torio]`.

### Tu jornada de juego

Un resumen de todo lo que juegas, haya sesión o no, hasta que pasas unas horas desconectado:
- el **oro ganado de verdad** (lo que tienes ahora menos lo que tenías al empezar) y por hora jugada;
- de dónde vino: oro despojado, misiones, vendedores, correo, casa de subastas, comercio;
- a dónde fue: reparaciones y compras, vuelos, instructores, casa de subastas;
- el botín conseguido, a precios de hoy;
- bichos, nodos, misiones, experiencia, reputación y las zonas por las que pasaste.

Las jornadas anteriores se guardan, así sabes cuánto te dejó de verdad esa tarde de seis horas de mazmorras, farmeo y misiones.

### Notas a jugadores: quién farmea tu capa

- Ponle una nota a un jugador ("Farmer", "Bot"…) desde su menú del clic derecho, o con `/farmgod nota Farmer` sobre tu objetivo.
- Cuando un jugador con nota aparece cerca (su placa de nombre, tu objetivo o el ratón encima), FarmGod te avisa de que está en tu capa, y la ventana lista a los que has visto hace poco.
- Al cambiar de capa, la lista se vacía. La nota también sale en su tooltip.

### Además

- El historial de tus últimas 30 sesiones, a precios de hoy.
- Un aviso en el chat cuando despojas algo que vale 5 de oro o más (tú eliges cuánto).
- También funciona en mazmorras: tu botín y lo que ganas en las tiradas, tu parte del oro y los bichos de todo el grupo.

Hecho para WoW Forever (versión del juego 1.60.1). Forever esconde algunas cosas a los addons en combate y no tiene algunos eventos del juego: FarmGod sortea las dos cosas.
