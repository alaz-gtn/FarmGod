# FarmGod

Addon de sesiones de farmeo para WoW Forever, hermano de HunterGod y MageGod, con la misma ventana de opciones en dorado. Sirve para cualquier clase: minería, herboristería, desuello, pesca o matar bichos.

- **Sesiones**: empieza sola al despojar o recolectar algo (o con el botón de play), se pausa, se reanuda, se termina (va al historial) o se pone a cero. Si pasas un rato sin despojar nada (10 minutos por defecto) se pausa sola, quita ese rato de su tiempo y sigue con el próximo botín. Aguanta un `/reload` o salir del juego; el tiempo desconectado no cuenta.
- **Lo que vale**: el oro despojado y el botín por familias (objetos grises, menas y gemas, hierbas, cuero y pieles, telas, elementales, carne y pescado, encantamiento, otros materiales, recetas, equipo verde, equipo azul y épico, otros), la más valiosa primero, con oro por hora. Al pasar el ratón por una familia salen sus objetos, cuántos y lo que vale cada uno.
- **Precios**: de Auctionator o de TSM (los dos están instalados en Forever; TSM trae datos de Forever-EU de su aplicación). Se leen cada vez, no se guardan: después de escanear la casa de subastas, la sesión y el historial valen con los precios nuevos, y al cerrar la casa de subastas dice cuánto vale ahora la sesión. Los grises, lo que se liga al recogerlo y el equipo verde van por lo que paga un vendedor: en subasta los verdes se anuncian caros, muchos no se venden y el precio por ID no distingue el sufijo (del Oso, del Mono). El equipo azul y épico va a precio de subasta, que es más fiable. Se cambia por familia en la pestaña Familias. Opciones: fuente (Auctionator y luego TSM, solo uno, o solo vendedor), qué precio de TSM, lo mejor entre subasta y vendedor, descontar el 5% de la casa de subastas, y para cada familia si va por subasta, por vendedor o no cuenta.
- **Bichos matados**: una calavera pequeña con el número en la barra de título, junto al reloj, que se ve también con la ventana plegada. Al pasar el ratón: por hora, cuántos despojaste y cuánto vale cada bicho. Forever cierra el registro de combate, pero avisa de una muerte de tres maneras: su evento `PARTY_KILL` (golpes de gracia tuyos o de tu grupo; en mazmorras no dice quién murió, pero llega), "¡Has matado a X!" y "X muere, ganas N de experiencia". Los avisos de maneras distintas en el mismo segundo y medio son la misma muerte. Si el juego no dijera nada, cuenta al menos los bichos que despojas.
- **Reputación**: con la ventana desplegada y bajo las familias, hasta 3 facciones con las que has ganado reputación en la sesión.
  - Cada una sale en el color de su nivel, con lo ganado, lo que da por hora y una barrita de cuánto llevas del nivel.
  - Al pasar el ratón: dónde estás (Amistoso 800/6.000), cuánto falta para el siguiente nivel y cuánto tardarías a ese ritmo.
  - También sale en la jornada y en los tooltips del historial.
  - Se lee de las propias facciones del juego, comparando lo que tienes con lo que había, y no de los mensajes del chat. Tras cada pantalla de carga espera 5 segundos antes de contar: en ese rato el juego va rellenando las facciones, y la primera versión contaba eso como reputación ganada.
- **Contadores**: abajo, nodos de minería, hierbas, desuellos, peces, robos, experiencia por hora y subidas de habilidad.
- **Mazmorras**: cuenta igual. Tu botín (también lo que ganas en las tiradas), tu parte del oro en grupo y las muertes de todo el grupo. El equipo verde va por lo que paga un vendedor y el azul y épico a precio de subasta (salvo el que se liga al recogerlo, a vendedor); se cambia en Familias. Si una sesión empieza dentro, el historial la guarda con el nombre de la mazmorra. Si no quieres que un jefe largo o un wipe la pausen por inactividad, sube los minutos de la pausa o ponlos a 0.
- **Objetivos**: "40 menas de torio, 60 de cuero grueso, 2 cristales arcanos". Cuentan lo que llevas en las bolsas (y en el banco, si quieres), como los objetivos de una misión: salen en la ventana con su barra, cada paso aparece en amarillo en el centro de la pantalla y, al cumplirlo, en verde con el sonido de las misiones. Al pasar el ratón dice cuánto llevas de ese objeto en la sesión y cuánto tardarías en el resto a ese ritmo. Se ponen en la pestaña Objetivos (arrastrando el objeto, con Mayús+clic o escribiendo su nombre o su ID) o con `/farmgod objetivo 40 [Mena de torio]`.
- **Notas a jugadores**: "Farmer", "Bot"… para saber quién farmea tu capa. Un jugador con nota que ves (su placa de nombre, tu objetivo o el ratón encima) está en tu capa: lo dice en el chat, en naranja en el centro de la pantalla y con el sonido de aviso de banda (no repite al mismo en 5 minutos), y la ventana de la sesión lista abajo a los vistos en los últimos 10 minutos ("En tu capa: Goten Pérez (Farmer) 2 min"). El cambio de capa de Forever (`SHARD_TRANSFER`) vacía esa lista; `/farmgod capa` lo hace a mano. La nota sale también en su tooltip. Se ponen con clic derecho en el jugador (su retrato, el de tu objetivo o su nombre en el chat), seleccionándolo y `/farmgod nota Farmer`, o en la pestaña Notas. Valen para todos tus personajes. En Forever los nombres son "Nombre Apellido" sin reino (lo midió LayerSwap); en combate Forever puede esconderlos y entonces no se leen. Para ver de lejos a los de tu facción hacen falta las placas de aliados (Mayús+V).
- **Aviso de botín gordo**: en el chat, lo que valga 5 de oro o más (se cambia en las opciones).
- **Jornada**: el resumen de todo lo que juegas, haya sesión o no. Cuenta desde que te conectas hasta que pasas más de 3 horas desconectado (se cambia, y se puede empezar otra a mano). Incluye:
  - el oro ganado de verdad (el que tienes ahora menos el que tenías al empezar) y por hora jugada;
  - de dónde vino: oro despojado, misiones, ventas a vendedor, correo, comercio, subasta;
  - a dónde fue: compras y reparaciones, envíos, subasta, instructores, vuelos;
  - aparte, el botín a precios de hoy (lo que ya vendiste está en el oro: no se suman);
  - bichos, nodos, misiones, experiencia, sesiones de farmeo y zonas.

  El oro se reparte según la ventana que estaba abierta al moverse (la del botín, el vendedor, el buzón…). Están la pestaña Jornada con las 20 anteriores, `/farmgod jornada` y una línea en el botón del minimapa.
- **Historial**: las últimas 30 sesiones por personaje, con sus familias, valoradas con los precios de hoy.

## Cómo cuenta

- El botín, de las líneas "Recibes botín" del chat, construidas con las frases del propio juego (vale en cualquier idioma). No cuenta lo que recibe otro ni lo que te dan (misiones, compras).
- El oro, de las líneas de "Despojas X de oro" (también con los iconos de monedas); en grupo, tu parte, sin lo que va al banco de hermandad.
- Los nodos, por el nombre del hechizo al recolectar (Forever tiene varios ID para cada uno: 2575 Minería, 2366 Herboristería, 8613 Desuello; los saqué de `ForeverAuras/SpellNameData.lua` y de GatherMate2). Los peces, porque el botín es de pesca. Los bichos, por el botín de un `Creature-...` que no viene de un nodo, sin repetir el mismo cuerpo.
- Las familias, por la clase y subclase del objeto en el juego y, para los materiales del clásico, por una lista de IDs, por si Forever guarda alguno en otro sitio.

## En Forever

Registrar un evento que el cliente no tiene da un error, y ese error corta el resto del archivo. El 2026-11-20 le pasó a `Session.lua`: tras entrar al juego, la sesión no leía el botín y el reloj no avanzaba. Desde entonces todos los eventos van por `ns.Listen`, que se salta el que falte y lo apunta para `/farmgod eventos`. Las pruebas comprueban que ningún archivo registra eventos de otra forma y cargan el addon en un cliente al que le faltan varios.

## Carpetas

- `FarmGod/`: el addon tal como se instala en `_forever_\Interface\AddOns`. En este PC esa carpeta es una unión (junction) a esta, así que los cambios llegan al juego sin copiar nada: con `/reload` basta. Un `/reload` también carga los archivos nuevos: el 2026-11-20 cargó `Day.lua` y `Rep.lua`, creados con el juego abierto.
- `tools/`: `test_addon.py` (pruebas con lupa) y `make_logo.py` (logo, icono del minimapa y los iconos blancos de los botones de la ventana; necesita pillow).
- `curseforge/`: logo, descripción y registro de cambios para la página del proyecto.
- `release/`: los zips que se suben a CurseForge (no van al repositorio).
- `.github/workflows/release.yml`: la publicación al subir una etiqueta.

## Sacar una versión nueva

1. Cambia `## Version:` en `FarmGod/FarmGod.toc` y añade su entrada en `curseforge/changelog.md` (en inglés, como la descripción de `curseforge/description.md`).
2. Pasa las pruebas en los dos idiomas.
3. Haz commit, crea la etiqueta `v<versión>` y súbela: `git tag v1.0.1` y `git push origin main v1.0.1`.
4. GitHub Actions (`.github/workflows/release.yml`) prueba el addon y lo sube a CurseForge con su nota de cambios. Lo hace `tools/publish.py`, con el proyecto de `## X-Curse-Project-ID` del TOC y la clave de CurseForge en el secreto `CF_API_KEY` del repositorio.
5. Para ver el zip sin subirlo: `python -I tools/build_zip.py`, o `python -I tools/publish.py --dry-run`.

## Probar

`python -I tools/test_addon.py FarmGod enUS` y lo mismo con `esES`.

## Comandos

`/farmgod` (o `/farmeo`) abre las opciones. `empezar | pausa | terminar | reiniciar`, `informe`, `objetivo 40 [objeto]`, `nota Farmer` (a tu objetivo; `nota quitar`, o sola para la lista), `capa`, `historial`, `precios`, `mostrar`, `desbloquear | bloquear`, `boton`, `jornada`, `eventos` (los eventos que este cliente no tiene) y `ayuda`. En inglés: `start | pause | stop | reset`, `report`, `goal`, `note`, `layer`, `history`, `prices`, `show`, `unlock | lock`, `button`, `day`, `events`, `help`.

El botón del minimapa: clic izquierdo muestra u oculta la ventana, Mayús+clic empieza o pausa, clic derecho abre las opciones.
