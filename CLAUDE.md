# MMO táctico — guía para Claude Code

Proyecto de David Aranda: un MMORPG de acción táctica con skillshots, con héroes al estilo MLBB, la simpleza de Metin2 y un mundo abierto lindo como el de Breath of the Wild. Esta carpeta es la **demo jugable en Godot**. El diseño completo vive en la **Biblia** (un doc en claude.ai: https://claude.ai/artifact/9RDbX5DwEHUDEcz3mrVZs6). Desde Claude Code no se puede editar: si una decisión de diseño cambia, avisale a David para que la anote ahí.

## Cómo trabajar con David
- **Mirá `TAREAS.md` al empezar.** Es el buzón con lo que se decidió en la charla de diseño y hay que programar. Marcá lo que termines.
- Hablale en **español rioplatense/paraguayo**, directo y sin vueltas. Él no programa: explicale qué cambió en el juego, no el código.
- **Antes de pisar archivos que él pudo haber tocado** (escenas, assets, cosas que edita en Godot), revisá `git status` y `git diff`. Si hay cambios suyos sin commitear, preguntale antes.
- **Borrá los archivos de prueba** que crees (scripts de test, capturas, guardados de prueba) antes de terminar.
- **Antes de cambiar datos reales** (su guardado `user://progreso.json`, cosas publicadas, el repo remoto) mostrale qué vas a cambiar y esperá su OK.
- Nunca escribas sus contraseñas ni toques la configuración de red. El inicio de sesión lo hace él.
- Hacé commits chicos con mensaje en español. Hacé push solo si él lo pide o ya lo tiene pedido para esa tarea.

## Cómo correr y probar
- Godot **4.7 estándar (GDScript)**, renderer **Compatibility**. Escena principal: `main.tscn` (un Node3D con `scripts/main.gd`).
- El ejecutable de Godot está en la máquina de David. Si no lo encontrás en el PATH, preguntale dónde está (por ejemplo `C:\...\Godot_v4.7-stable_win64.exe`).
- Revisar errores de sintaxis sin abrir el juego:
  `godot --headless --path . --check-only --script scripts/main.gd` (y lo mismo con `menu.gd`, `data.gd`, `terrain.gd`)
- Pruebas automáticas: un script `extends SceneTree` que instancie `main.tscn`, llame a `choose("tanque", "escudo")` y ejercite funciones. Correrlo con `godot --path . -s prueba.gd`. Borralo al terminar.
- Al arrancar se genera el terreno, que tarda unos 5 s. No es un cuelgue.
- `.godot/` está en `.gitignore`. Los archivos `*.gd.uid` **sí** van al repo: no los borres.

## Estructura
- `scripts/main.gd` (~5000 líneas): todo el juego. Mundo, ciudades, vegetación, vetas, flora, monstruos e IA, combate, héroe, HUD, minimapa, oficios y guardado. Usa clases internas: `Player`, `Mob`, `Proj`, `Blast`, `Fx`, `Zone`, `FloatText`, `Cell`, `TreeObj`, `Puddle`.
- `scripts/terrain.gd`: heightmap de 1024 m con resolución de 2 m, en chunks de 64. Define biomas (`biome_at`, `BIOME_NAMES`), caminos, río, lago, `CROSSINGS` (dónde van los puentes), colores y densidad de árboles.
- `scripts/data.gd`: datos puros. Facciones, tipos de arma, clases con sus kits, bestiario (`MOBDEF` con `temper` y `ai`), franjas de nivel, vetas (`ORES`), flora, oficios, ingredientes, recetas, piezas de equipo y stats de piedras.
  - El bloque entre `# >>> CATÁLOGO DE GEMAS` y `# <<< CATÁLOGO DE GEMAS` **se genera**: editá `herramientas/catalogo.py` y corré `python herramientas/catalogo.py`. El script también deja `herramientas/gemas.md` con las tablas para la Biblia; borralo después de pasárselo a David.
- `scripts/menu.gd`: el menú estilo BotW (tecla I/Tab). Pestañas Armas, Equipo, Gemas, Oficio, Materiales y Comida, con el héroe en un SubViewport.
- `shaders/`: terreno (color de vértice + ruido) y agua.
- `assets/heroes/tanque.glb`: héroe hecho con Rodin, rig y animaciones de Mixamo (idle, run, strafe, attack, skill, death). Las otras clases todavía usan una cápsula.

## Convenciones y trampas conocidas
- **Todo se arma desde código** (mundo, UI, personajes), no en escenas del editor. Los textos van en español.
- GDScript: `:=` falla al inferir el tipo con expresiones Variant (valores de diccionarios, `max()`, elementos de arrays sin tipo). Usá tipos explícitos (`var x: float = ...`) o `maxf`/`maxi`.
- La altura del suelo siempre sale de `H(x, z)`: tiene en cuenta el agua y los puentes. Todo lo que se posiciona en el mundo se suma sobre `H`.
- Colisiones: cajas orientadas en una grilla de 16 m (`add_collider`, `solid_box`, `blocked`). Los dashes atraviesan muros (`dash_end`). Para "borrar" un collider se le pone `off = true`.
- Muchos objetos repetidos (árboles, pasto, flora, postes de cercos) usan MultiMesh con `visibility_range_end`. La compu de David es una Lenovo X1 Yoga (gráficos integrados): cuidá el rendimiento.
- El esqueleto de Mixamo viene en centímetros (escala 0,013): las armas en los huesos compensan la escala.
- Guardado: `user://progreso.json` (maestría, rangos, inventario, oficios, cuenta GM).

## Qué hay hecho en la demo (resumen)
- **Mundo:** dos ciudades de inicio, **Lumen** (Tanque, Luchador, Soporte) y **Sapientia** (Mago, Tirador, Asesino). Ocho biomas (praderas, bosque, campos, cañadón, desierto, playa, montañas, nieve). Pasto alto para esconderse. Árboles que se talan y vuelven a crecer.
- **Lugares:** santuarios con viaje rápido desde el minimapa, cofres (los de campamento se abren al vaciarlo), posadas, puente, carteles, arcos, pájaros y viajeros.
- **Monstruos:** cuatro franjas de nivel (animales, humanoides, orcos y goblins, cumbres) con comportamiento estilo BotW: sospecha "?", sigilo, campamentos que duermen y dan la alarma, manadas, huida, gólem dormido, espectro, troll que regenera.
- **Combate:** apuntado estilo MLBB (mantener la tecla y soltar), maestría por estilo con 21 puntos (H1 8, H2 6, H3 4, definitiva 3) y aceites elementales.
- **Recursos:** vetas de mineral por bioma (golpes pesados y explosiones rompen el doble, la magia la mitad) y flora recolectable.
- **Gemas:** 16 piedras básicas y 51 gemas. Se engarzan en 6 piezas (cabeza, torso, manos, piernas, pies y accesorio); los pies solo llevan Movimiento; la pieza es solo apariencia.
- **Oficios:** Cocinero (cocina estilo BotW en fogatas), Alquimista (tallar piedras, destilar aceites y frascos), Joyero (combinar gemas, lupa que muestra vetas), Armero (forjar apariencias en la forja de una ciudad), Criador (domar caballos y montar con H) y Constructor (fogatas y empalizadas). Una cuenta normal elige un oficio; la cuenta GM, que es la de David, tiene todos.

## Pendientes conocidos
- Pasivas de las gemas (hoy solo suman stats), subir gemas de nivel con catalizadores, teñido del Armero.
- Pestañas Objetos clave y Apariencias en el menú.
- Ciclo de día y noche, torres de facción que revelan el mapa, más héroes con modelo, efectos visuales de habilidades.
- Decisiones abiertas de David: si el Alquimista talla y el Joyero combina (así está hecho ahora), y cómo se cambia de oficio en una cuenta normal.
