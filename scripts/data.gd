# Datos del juego. Modelo de armas v2:
#   - El KIT (habilidades) sale de facción + clase + rareza.
#   - El TIPO DE ARMA solo define el ataque básico.
# Acá: facción Imperio de la Luz, rareza Inicial.
extends RefCounted

const FACTIONS = [
	{"id": "luz", "name": "Imperio de la Luz", "on": true},
	{"id": "abismo", "name": "Abismo", "on": false},
	{"id": "oriente", "name": "Reinos de Oriente", "on": false},
	{"id": "salvajes", "name": "Tierras Salvajes", "on": false},
	{"id": "arenas", "name": "Arenas y Mares", "on": false},
]

# phys = el básico escala con ataque físico; si no, con magia.
const WTYPES = {
	"escudo":   {"name": "Espada y escudo",    "phys": true,  "basic": {"range": 2.7, "dmg": 22, "cd": 0.9,  "melee": true}},
	"mandoble": {"name": "Espada larga",       "phys": true,  "basic": {"range": 2.9, "dmg": 30, "cd": 1.0,  "melee": true}},
	"garras":   {"name": "Garras ocultas",     "phys": true,  "basic": {"range": 2.4, "dmg": 19, "cd": 0.55, "melee": true}},
	"libro":    {"name": "Libro de tormentas", "phys": false, "basic": {"range": 13.0, "dmg": 18, "cd": 0.9, "proj": true, "speed": 26.0, "width": 0.5, "bounce": true}},
	"canon":    {"name": "Cañón de mano",      "phys": true,  "basic": {"range": 15.0, "dmg": 20, "cd": 0.8, "proj": true, "speed": 34.0, "width": 0.4}},
	"baculo":   {"name": "Báculo sagrado",     "phys": false, "basic": {"range": 12.0, "dmg": 15, "cd": 1.0, "proj": true, "speed": 24.0, "width": 0.5}},
}

# el = elemento que interactúa con el mundo vivo ("fuego" o "rayo").
const CLASSES = [
	{"id": "tanque", "start": "lumen", "cls": "Tanque", "style": "Guardia de primera línea", "color": Color("#6fa8dc"), "hp": 950, "speed": 6.2, "phys": true, "natural": "escudo",
	 "s1": {"name": "Onda de choque", "type": "cone", "range": 7.0, "angle": 70.0, "dmg": 40, "slow": 0.5, "slow_dur": 2.0, "cd": 6.0},
	 "s2": {"name": "Carga de escudo", "type": "dash", "range": 8.0, "width": 2.4, "dmg": 35, "stun": 0.8, "cd": 8.0},
	 "passive": {"name": "Bloqueo", "effect": "block", "desc": "Cada 4 golpes recibidos, bloqueás uno."},
	 "s3": {"name": "Muralla", "type": "buff", "buff": "shield", "val": 280.0, "dur": 4.0, "cd": 14.0},
	 "ult": {"name": "Implosión", "type": "pull", "radius": 6.5, "dmg": 80, "stun": 1.4, "cd": 35.0}},
	{"id": "luchador", "start": "lumen", "cls": "Luchador", "style": "Cazademonios", "color": Color("#e06666"), "hp": 780, "speed": 6.6, "phys": true, "natural": "mandoble",
	 "s1": {"name": "Golpe sísmico", "type": "leap", "range": 9.0, "radius": 3.0, "dmg": 45, "cd": 7.0},
	 "s2": {"name": "Torbellino", "type": "nova", "radius": 3.6, "dmg": 42, "cd": 5.0},
	 "passive": {"name": "Persecución", "effect": "chase", "desc": "Tras una habilidad, tu próximo básico salta al objetivo."},
	 "s3": {"name": "Paso veloz", "type": "dash", "range": 5.0, "width": 1.8, "dmg": 22, "cd": 6.0},
	 "ult": {"name": "Onda de fisión", "type": "line", "range": 11.0, "width": 2.6, "dmg": 95, "delay": 0.15, "buff": "lifesteal", "val": 0.4, "dur": 6.0, "cd": 32.0}},
	{"id": "asesino", "start": "sapientia", "cls": "Asesino", "style": "Agente secreto", "color": Color("#b4a7d6"), "hp": 620, "speed": 7.4, "phys": true, "natural": "garras",
	 "s1": {"name": "Zarpazo", "type": "dash", "range": 6.5, "width": 1.8, "dmg": 32, "cd": 4.0},
	 "s2": {"name": "Bomba de humo", "type": "smoke", "radius": 4.0, "dur": 4.0, "slow": 0.4, "cd": 11.0},
	 "passive": {"name": "Instinto", "effect": "camo", "desc": "Tras 3 s sin recibir daño te camuflás; el primer golpe aturde y pega +50%."},
	 "s3": {"name": "Garra arrojadiza", "type": "proj", "range": 13.0, "speed": 32.0, "width": 0.7, "dmg": 38, "cd": 5.0},
	 "ult": {"name": "Cacería", "type": "buff", "buff": "hunt", "dur": 5.0, "shots": 2, "cd": 30.0}},
	{"id": "mago", "start": "sapientia", "cls": "Mago", "style": "Electromante", "color": Color("#f6b26b"), "hp": 560, "speed": 6.4, "phys": false, "natural": "libro",
	 "s1": {"name": "Rayo bifurcado", "type": "cone", "range": 9.0, "angle": 50.0, "dmg": 46, "cd": 5.0, "el": "rayo"},
	 "s2": {"name": "Bola de rayo", "type": "proj", "range": 14.0, "speed": 20.0, "width": 1.0, "dmg": 42, "stun": 1.0, "cd": 7.0, "bounce": true, "el": "rayo"},
	 "passive": {"name": "Superconductor", "effect": "mark", "desc": "Tus habilidades marcan: el rayo pega +40% y la bola rebota entre marcados."},
	 "s3": {"name": "Paso eléctrico", "type": "blink", "range": 7.0, "cd": 10.0},
	 "ult": {"name": "Ira del trueno", "type": "blast", "range": 14.0, "radius": 3.2, "delay": 0.45, "dmg": 150, "cd": 38.0, "chain": true, "el": "rayo"}},
	{"id": "tirador", "start": "sapientia", "cls": "Tirador", "style": "Artillera", "color": Color("#93c47d"), "hp": 600, "speed": 6.6, "phys": true, "natural": "canon",
	 "s1": {"name": "Bomba incendiaria", "type": "proj", "range": 16.0, "speed": 28.0, "width": 0.8, "dmg": 42, "cd": 5.0, "range_buff": true, "explode": 2.2, "el": "fuego"},
	 "s2": {"name": "Proyectil del vacío", "type": "proj", "range": 13.0, "speed": 24.0, "width": 0.8, "dmg": 34, "cd": 7.0, "explode": 2.6, "void_mark": true},
	 "passive": {"name": "Arma maléfica", "effect": "far", "desc": "Tus básicos pegan hasta +40% cuanto más lejos está el objetivo."},
	 "s3": {"name": "Rodada", "type": "dash", "range": 5.0, "width": 0.0, "dmg": 0, "cd": 6.0},
	 "ult": {"name": "Ráfaga ardiente", "type": "line", "range": 22.0, "width": 2.2, "dmg": 150, "delay": 0.35, "cd": 36.0, "el": "fuego"}},
	{"id": "soporte", "start": "lumen", "cls": "Soporte", "style": "Sacerdotisa", "color": Color("#ffe599"), "hp": 680, "speed": 6.5, "phys": false, "natural": "baculo",
	 "s1": {"name": "Luz de castigo", "type": "auto3", "range": 9.0, "dmg": 30, "slow": 0.4, "slow_dur": 1.5, "cd": 5.0},
	 "s2": {"name": "Curación sagrada", "type": "buff", "buff": "heal", "val": 0.25, "dur": 3.0, "cd": 10.0},
	 "passive": {"name": "Resurrección divina", "effect": "deathburst", "desc": "Al caer, liberás un estallido de luz que daña alrededor."},
	 "s3": {"name": "Sello de luz", "type": "blast", "range": 10.0, "radius": 3.0, "delay": 0.6, "dmg": 28, "slow": 0.5, "slow_dur": 2.0, "cd": 8.0},
	 "ult": {"name": "Bautismo sagrado", "type": "line", "range": 16.0, "width": 2.4, "dmg": 95, "delay": 0.7, "stun": 1.4, "cd": 34.0}},
]

# Bestiario por franjas de nivel (ecología tipo "Mazmorras y tragones": cada bicho vive en su hábitat
# y muchos se comen). ai: melee / ranged / brute (jefe con golpes telegrafiados).
# temper (comportamiento, al estilo BotW): timid huye · neutral solo pelea si lo atacás (y embiste) ·
# pack caza en manada rodeándote · territorial avisa y ataca de cerca · camp duerme junto al fuego,
# tiene vigía y alerta al campamento · coward huye herido · dormant duerme como roca ·
# ghost es casi invisible y se teletransporta · regen se regenera si no lo golpeás
# body: quad (animal), biped (humanoide), brute (grandote). food: ingrediente que puede soltar.
const MOBDEF = {
	# --- Nv 1–15 · animales ---
	"conejo":  {"name": "Conejo cornudo", "temper": "timid", "ai": "melee", "body": "quad", "size": 0.55, "hp": 70.0, "r": 0.5, "speed": 5.6, "aggro": 9.0, "dmg": 8.0, "xp": 7, "color": Color("#c9b08a"), "accent": Color("#f2ead8"), "reach": 1.4, "wind": 0.35, "cd": 1.1, "food": "Carne tierna"},
	"lobo":    {"name": "Lobo", "temper": "pack", "ai": "melee", "body": "quad", "size": 1.0, "hp": 130.0, "r": 0.8, "speed": 5.2, "aggro": 13.0, "dmg": 13.0, "xp": 12, "color": Color("#7a7f88"), "accent": Color("#5e636b"), "reach": 2.0, "wind": 0.45, "cd": 1.3, "food": ""},
	"jabali":  {"name": "Jabalí", "temper": "neutral", "ai": "melee", "body": "quad", "size": 1.15, "hp": 190.0, "r": 0.9, "speed": 4.8, "aggro": 11.0, "dmg": 16.0, "xp": 15, "color": Color("#5b4636"), "accent": Color("#e8e0cc"), "reach": 2.0, "wind": 0.5, "cd": 1.5, "food": "Panceta de jabalí"},
	"oso":     {"name": "Oso pardo", "temper": "territorial", "ai": "brute", "body": "quad", "size": 2.1, "hp": 900.0, "r": 1.5, "speed": 3.8, "aggro": 8.0, "dmg": 20.0, "xp": 80, "color": Color("#6b4a2e"), "accent": Color("#4a321f"), "reach": 3.0, "wind": 0.6, "cd": 1.6, "food": "Zarpa de oso"},
	# --- Nv 15–35 · humanoides ---
	"bandido": {"name": "Bandido", "temper": "camp", "ai": "melee", "body": "biped", "size": 1.0, "hp": 160.0, "r": 0.7, "speed": 4.8, "aggro": 13.0, "dmg": 17.0, "xp": 16, "color": Color("#6e5a44"), "accent": Color("#b23a3a"), "reach": 2.0, "wind": 0.45, "cd": 1.3, "weapon": "espada", "food": ""},
	"arquero": {"name": "Arquero bandido", "temper": "camp", "ai": "ranged", "body": "biped", "size": 1.0, "hp": 95.0, "r": 0.7, "speed": 4.4, "aggro": 16.0, "dmg": 16.0, "xp": 15, "color": Color("#9a6b3c"), "accent": Color("#3a2a1a"), "range": 13.0, "wind": 0.75, "cd": 2.2, "weapon": "arco", "food": ""},
	"jefe":    {"name": "Jefe bandido", "temper": "camp", "ai": "brute", "body": "biped", "size": 1.7, "hp": 1000.0, "r": 1.3, "speed": 3.8, "aggro": 15.0, "dmg": 22.0, "xp": 95, "color": Color("#4d3b2c"), "accent": Color("#b23a3a"), "reach": 3.0, "wind": 0.6, "cd": 1.6, "weapon": "hacha", "food": ""},
	# --- Nv 35–45 · orcos, goblins y parientes ---
	"goblin":  {"name": "Goblin", "temper": "coward", "ai": "melee", "body": "biped", "size": 0.7, "hp": 120.0, "r": 0.55, "speed": 6.0, "aggro": 14.0, "dmg": 14.0, "xp": 14, "color": Color("#6f9a3a"), "accent": Color("#4a3a26"), "reach": 1.6, "wind": 0.35, "cd": 0.9, "weapon": "daga", "food": ""},
	"hondero": {"name": "Goblin hondero", "temper": "coward", "ai": "ranged", "body": "biped", "size": 0.7, "hp": 85.0, "r": 0.55, "speed": 5.0, "aggro": 16.0, "dmg": 15.0, "xp": 14, "color": Color("#7fa548"), "accent": Color("#4a3a26"), "range": 12.0, "wind": 0.6, "cd": 1.8, "weapon": "honda", "food": ""},
	"orco":    {"name": "Orco", "temper": "camp", "ai": "melee", "body": "biped", "size": 1.35, "hp": 320.0, "r": 1.0, "speed": 4.2, "aggro": 13.0, "dmg": 24.0, "xp": 28, "color": Color("#5d7552"), "accent": Color("#3b3b3b"), "reach": 2.4, "wind": 0.6, "cd": 1.6, "weapon": "hacha", "food": ""},
	"ogro":    {"name": "Ogro", "temper": "camp", "ai": "brute", "body": "brute", "size": 1.0, "hp": 950.0, "r": 1.6, "speed": 3.6, "aggro": 15.0, "dmg": 22.0, "xp": 90, "color": Color("#7d5a3c"), "accent": Color("#9b7653"), "reach": 3.2, "wind": 0.6, "cd": 1.6, "food": "Hígado de ogro"},
	# --- Nv 45+ · criaturas de las cumbres ---
	"golem":   {"name": "Gólem de piedra", "temper": "dormant", "ai": "brute", "body": "brute", "size": 1.15, "hp": 1300.0, "r": 1.7, "speed": 3.0, "aggro": 12.0, "dmg": 26.0, "xp": 120, "color": Color("#8a8a82"), "accent": Color("#6f9a5a"), "reach": 3.4, "wind": 0.75, "cd": 1.9, "food": "Musgo de gólem"},
	"espectro":{"name": "Espectro", "temper": "ghost", "ai": "ranged", "body": "biped", "size": 1.1, "hp": 180.0, "r": 0.7, "speed": 5.0, "aggro": 17.0, "dmg": 22.0, "xp": 26, "color": Color("#8b7fd6"), "accent": Color("#d9d2ff"), "range": 14.0, "wind": 0.7, "cd": 2.0, "weapon": "", "food": ""},
	"troll":   {"name": "Troll de las nieves", "temper": "regen", "ai": "melee", "body": "brute", "size": 0.8, "hp": 520.0, "r": 1.3, "speed": 4.0, "aggro": 13.0, "dmg": 28.0, "xp": 40, "color": Color("#b9c7d6"), "accent": Color("#7d8fa3"), "reach": 2.6, "wind": 0.55, "cd": 1.5, "food": "Grasa de troll"},
}

# vetas de mineral que se rompen a golpes (como en BotW). Vuelven a aparecer a los 5 minutos.
# Golpes pesados (espada larga, espada y escudo) y explosiones: ×2 · magia: ×0,5.
# Minerales:
#  - comunes y de alquimia: pedernal, sal de roca, azufre, ámbar, luminita
#  - catalizadores por tramo (suben la gema de nivel): pedernal (Nv1) · hierro (Nv2) · plata (Nv3) · mithril (Nv4) · ...
#  - minerales de facción (definen la categoría de la gema): cada facción tiene el suyo en su territorio;
#    los otros se consiguen comerciando en el Puerto libre o en las vetas de la frontera, que se disputan en la guerra.
const FACTION_MINERALS = {
	"luz": {"mineral": "Cuarzo solar", "gem": "Defensa"},
	"abismo": {"mineral": "Obsidiana del vacío", "gem": "Magia"},
	"oriente": {"mineral": "Jade de viento", "gem": "Movimiento"},
	"salvajes": {"mineral": "Rubí ígneo", "gem": "Ataque"},
	"arenas": {"mineral": "Perla de marea", "gem": "Soporte"},
}
const ORES = {
	"piedra":   {"name": "Veta de piedra", "hp": 60.0, "rock": Color("#8a8780"), "gem": Color("#e6dfcf"), "glow": false,
				 "drops": [["Pedernal", 0.9], ["Sal de roca", 0.2]]},
	"cobre":    {"name": "Veta de cobre", "hp": 80.0, "rock": Color("#7a6a5a"), "gem": Color("#d9824a"), "glow": false,
				 "drops": [["Cobre", 0.9], ["Pedernal", 0.3]]},
	"hierro":   {"name": "Veta de hierro", "hp": 100.0, "rock": Color("#6e5a4c"), "gem": Color("#b5552e"), "glow": false,
				 "drops": [["Hierro", 0.9], ["Pedernal", 0.3]]},
	"azufre":   {"name": "Veta de azufre", "hp": 90.0, "rock": Color("#8c6f4e"), "gem": Color("#f0cf3a"), "glow": false,
				 "drops": [["Azufre", 0.9], ["Ámbar", 0.35]]},
	"sal":      {"name": "Veta de sal", "hp": 70.0, "rock": Color("#b8b0a0"), "gem": Color("#fbf7ee"), "glow": false,
				 "drops": [["Sal de roca", 0.9], ["Ámbar", 0.15]]},
	"cuarzo":   {"name": "Veta de cuarzo solar", "hp": 120.0, "rock": Color("#9a917e"), "gem": Color("#ffe9a8"), "glow": true,
				 "drops": [["Cuarzo solar", 0.9]]},
	"luminita": {"name": "Veta de luminita", "hp": 140.0, "rock": Color("#6f7480"), "gem": Color("#b9f3ff"), "glow": true,
				 "drops": [["Luminita", 0.9], ["Cuarzo solar", 0.2]]},
	"plata":    {"name": "Veta de plata", "hp": 160.0, "rock": Color("#5f6168"), "gem": Color("#dfe6ee"), "glow": false,
				 "drops": [["Plata", 0.9], ["Ámbar", 0.3]]},
	"hielo":    {"name": "Veta de cristal de hielo", "hp": 180.0, "rock": Color("#8b97a8"), "gem": Color("#9fd8ff"), "glow": true,
				 "drops": [["Cristal de hielo", 0.9]]},
	"mithril":  {"name": "Veta de mithril", "hp": 220.0, "rock": Color("#4a4a52"), "gem": Color("#7ee7ff"), "glow": true,
				 "drops": [["Mithril", 0.9], ["Luminita", 0.3]]},
	"frontera": {"name": "Veta extranjera", "hp": 260.0, "rock": Color("#3d3540"), "gem": Color("#ff5a6e"), "glow": true,
				 "drops": [["Rubí ígneo", 0.3], ["Obsidiana del vacío", 0.3], ["Jade de viento", 0.3], ["Perla de marea", 0.3], ["Turquesa", 0.3]]},
}

# flora que se recolecta (como en BotW): cada bioma tiene la suya. use: para qué sirve.
const FLORA = {
	"hierba_dulce":  {"name": "Hierba dulce", "biomes": ["pradera", "campos"], "use": "cocina", "n": 140},
	"hierba_vida":   {"name": "Hierba de vida", "biomes": ["pradera", "bosque"], "use": "alquimia", "n": 90},
	"bayas":         {"name": "Bayas silvestres", "biomes": ["bosque", "pradera"], "use": "cocina", "n": 80},
	"hongo":         {"name": "Hongo del bosque", "biomes": ["bosque", "montana"], "use": "cocina", "n": 90},
	"hongo_luz":     {"name": "Hongo luminoso", "biomes": ["bosque"], "use": "alquimia", "n": 40},
	"zanahoria":     {"name": "Zanahoria silvestre", "biomes": ["campos"], "use": "cocina", "n": 80},
	"calabaza":      {"name": "Calabaza", "biomes": ["campos"], "use": "cocina", "n": 50},
	"trigo":         {"name": "Trigo silvestre", "biomes": ["campos", "pradera"], "use": "cocina", "n": 70},
	"tuna":          {"name": "Fruta de cactus", "biomes": ["desierto", "canadon"], "use": "cocina", "n": 60},
	"pimiento":      {"name": "Pimiento ardiente", "biomes": ["canadon", "desierto"], "use": "cocina y alquimia", "n": 60},
	"menta":         {"name": "Menta glacial", "biomes": ["montana", "nieve"], "use": "cocina", "n": 60},
	"flor_escarcha": {"name": "Flor de escarcha", "biomes": ["nieve"], "use": "alquimia", "n": 50},
	"coco":          {"name": "Coco", "biomes": ["playa"], "use": "cocina", "n": 35},
	"alga":          {"name": "Alga del lago", "biomes": ["playa"], "use": "cocina y alquimia", "n": 40},
}

# franjas de nivel del mundo (para nombres de zona y colores)
const TIERS = [
	{"name": "Animales", "lvl": [1, 15], "color": Color("#7ee787")},
	{"name": "Humanoides", "lvl": [15, 35], "color": Color("#f2cc60")},
	{"name": "Orcos y goblins", "lvl": [35, 45], "color": Color("#ff9b50")},
	{"name": "Criaturas de las cumbres", "lvl": [45, 60], "color": Color("#f85149")},
]
# --- generado por gen/catalogo.py: catálogo de gemas del Imperio de la Luz ---
# El Alquimista talla minerales en piedras básicas; el Joyero combina piedras en gemas finales.
const PIEDRAS = {
	"filo": {"name": "Piedra de filo", "cat": "Ataque", "recipe": ["Cobre", "Pedernal"], "effect": "+ataque físico"},
	"mira": {"name": "Piedra de mira", "cat": "Ataque", "recipe": ["Cuarzo solar", "Cobre"], "effect": "+probabilidad de crítico"},
	"furia": {"name": "Piedra de furia", "cat": "Ataque", "recipe": ["Rubí ígneo", "Azufre"], "effect": "+velocidad de ataque"},
	"arcana": {"name": "Piedra arcana", "cat": "Magia", "recipe": ["Luminita", "Pedernal"], "effect": "+poder mágico"},
	"eco": {"name": "Piedra de eco", "cat": "Magia", "recipe": ["Cristal de hielo", "Luminita"], "effect": "−enfriamiento de habilidades"},
	"vacio": {"name": "Piedra del vacío", "cat": "Magia", "recipe": ["Obsidiana del vacío", "Luminita"], "effect": "+penetración mágica"},
	"muralla": {"name": "Piedra de muralla", "cat": "Defensa", "recipe": ["Cuarzo solar", "Pedernal"], "effect": "+defensa física"},
	"vida": {"name": "Piedra de vida", "cat": "Defensa", "recipe": ["Ámbar", "Sal de roca"], "effect": "+vida máxima"},
	"calma": {"name": "Piedra de calma", "cat": "Defensa", "recipe": ["Perla de marea", "Cuarzo solar"], "effect": "+defensa mágica"},
	"paso": {"name": "Piedra de paso", "cat": "Movimiento", "recipe": ["Cobre", "Ámbar"], "effect": "+velocidad de movimiento (poca)"},
	"viento": {"name": "Piedra de viento", "cat": "Movimiento", "recipe": ["Jade de viento", "Pedernal"], "effect": "+velocidad de movimiento"},
	"cazador": {"name": "Piedra del cazador", "cat": "PvE", "recipe": ["Ámbar", "Colmillo de monstruo"], "effect": "+daño a monstruos"},
	"presa": {"name": "Piedra de presa", "cat": "PvE", "recipe": ["Azufre", "Sal de roca"], "effect": "+robo de vida contra monstruos"},
	"guia": {"name": "Piedra de guía", "cat": "Soporte", "recipe": ["Luminita", "Cuarzo solar"], "effect": "+regeneración de energía"},
	"amparo": {"name": "Piedra de amparo", "cat": "Soporte", "recipe": ["Perla de marea", "Ámbar"], "effect": "+curación y escudos que das"},
	"temple": {"name": "Piedra de temple", "cat": "Soporte", "recipe": ["Turquesa", "Cobre"], "effect": "+resistencia al control"},
}
const GEMAS = [
	{"name": "Hoja del alba", "cat": "Ataque", "stones": ["filo", "filo", "mira"], "stats": "Ataque, crítico", "passive": "Después de un crítico, tu próximo básico hace +20%."},
	{"name": "Ojo del tirador", "cat": "Ataque", "stones": ["mira", "filo"], "stats": "Ataque, crítico", "passive": "Acertar la H1 desde lejos potencia el próximo básico."},
	{"name": "Furia carmesí", "cat": "Ataque", "stones": ["furia", "filo"], "stats": "Ataque, vel. de ataque", "passive": "Cada básico al mismo objetivo da +3% de velocidad de ataque (hasta 5 veces)."},
	{"name": "Cuchilla del ocaso", "cat": "Ataque", "stones": ["filo", "mira", "furia"], "stats": "Ataque, penetración", "passive": "+15% de daño a enemigos con menos del 40% de vida."},
	{"name": "Sed de sangre", "cat": "Ataque", "stones": ["filo", "vida"], "stats": "Ataque, vida", "passive": "Robo de vida físico del 12%."},
	{"name": "Martillo de asedio", "cat": "Ataque", "stones": ["filo", "muralla", "muralla"], "stats": "Ataque, defensa", "passive": "+30% de daño a estructuras (guerra y asedio)."},
	{"name": "Lanza del juicio", "cat": "Ataque", "stones": ["furia", "eco"], "stats": "Ataque, vel. de ataque", "passive": "Después de una habilidad, tu próximo básico atraviesa en línea."},
	{"name": "Rompeescudos", "cat": "Ataque", "stones": ["mira", "muralla"], "stats": "Ataque, crítico", "passive": "Tus golpes le sacan un 30% extra al escudo del enemigo."},
	{"name": "Daga de la bruma", "cat": "Ataque", "stones": ["mira", "viento"], "stats": "Crítico, velocidad", "passive": "Al salir del pasto, tu primer golpe hace +25%."},
	{"name": "Ojo del vacío", "cat": "Magia", "stones": ["arcana", "vacio"], "stats": "Poder mágico, penetración", "passive": "Tus habilidades queman un % de la vida del objetivo."},
	{"name": "Cetro del sol", "cat": "Magia", "stones": ["arcana", "arcana", "mira"], "stats": "Poder mágico", "passive": "Cada 6 s tu próxima habilidad deja una zona de luz que quema."},
	{"name": "Corona de escarcha", "cat": "Magia", "stones": ["eco", "arcana"], "stats": "Poder mágico, enfriamiento", "passive": "Tus habilidades ralentizan un 15%."},
	{"name": "Tomo del eco", "cat": "Magia", "stones": ["eco", "eco"], "stats": "Enfriamiento", "passive": "Acertar una habilidad le resta 1 s a las demás."},
	{"name": "Cristal de tormenta", "cat": "Magia", "stones": ["arcana", "eco", "eco"], "stats": "Poder mágico, enfriamiento", "passive": "Tus rayos saltan a un enemigo más."},
	{"name": "Velo del vacío", "cat": "Magia", "stones": ["vacio", "eco"], "stats": "Penetración, enfriamiento", "passive": "+12% de daño mágico a objetivos con más del 50% de vida."},
	{"name": "Lámpara del erudito", "cat": "Magia", "stones": ["arcana", "guia"], "stats": "Poder mágico, energía", "passive": "Mientras más lejos estés del objetivo, más daño mágico (hasta +15%)."},
	{"name": "Grimorio sangrante", "cat": "Magia", "stones": ["arcana", "vida"], "stats": "Poder mágico, vida", "passive": "Robo de vida con habilidades del 10%."},
	{"name": "Prisma solar", "cat": "Magia", "stones": ["arcana", "mira"], "stats": "Poder mágico, crítico", "passive": "Las reacciones elementales (fuego, agua, rayo) que provocás hacen +15%."},
	{"name": "Coraza de espinas", "cat": "Defensa", "stones": ["muralla", "muralla"], "stats": "Defensa física", "passive": "Devuelve parte del daño de los básicos."},
	{"name": "Égida del alba", "cat": "Defensa", "stones": ["muralla", "calma"], "stats": "Defensa física y mágica", "passive": "Al bajar del 40% de vida ganás un escudo (cada 60 s)."},
	{"name": "Corazón de roble", "cat": "Defensa", "stones": ["vida", "vida"], "stats": "Vida", "passive": "Si no recibís daño por 5 s, regenerás un 2% de vida por segundo."},
	{"name": "Manto de calma", "cat": "Defensa", "stones": ["calma", "vida"], "stats": "Defensa mágica, vida", "passive": "Los controles te duran un 20% menos."},
	{"name": "Bastión inmortal", "cat": "Defensa", "stones": ["muralla", "vida", "calma"], "stats": "Vida, defensas", "passive": "Al morir, revivís con el 20% de vida (cada 3 min)."},
	{"name": "Cinturón del trueno", "cat": "Defensa", "stones": ["muralla", "vida"], "stats": "Vida, defensa física", "passive": "Cada 4 s tu próximo básico hace daño extra según tus defensas."},
	{"name": "Yelmo del centinela", "cat": "Defensa", "stones": ["muralla", "temple"], "stats": "Defensa física, enfriamiento", "passive": "Después de un control, ganás +30% de defensa por 2 s."},
	{"name": "Coraza antigua", "cat": "Defensa", "stones": ["muralla", "filo"], "stats": "Defensa física, ataque", "passive": "Al pegarle con una habilidad, el enemigo pierde un 8% de ataque por 2 s."},
	{"name": "Hielo dominante", "cat": "Defensa", "stones": ["calma", "eco"], "stats": "Defensa mágica, enfriamiento", "passive": "Los enemigos cerca tuyo se curan un 30% menos."},
	{"name": "Sandalias del rayo", "cat": "Movimiento", "stones": ["paso", "guia"], "stats": "Velocidad, enfriamiento", "passive": "Corrés más rápido después de usar la definitiva."},
	{"name": "Botas de guerrero", "cat": "Movimiento", "stones": ["paso", "muralla"], "stats": "Velocidad, defensa física", "passive": "Recibir básicos te da más defensa física (hasta 5 veces)."},
	{"name": "Botas firmes", "cat": "Movimiento", "stones": ["paso", "calma"], "stats": "Velocidad, defensa mágica", "passive": "Los controles te duran un 30% menos."},
	{"name": "Botas arcanas", "cat": "Movimiento", "stones": ["paso", "arcana"], "stats": "Velocidad, penetración mágica", "passive": "—"},
	{"name": "Botas veloces", "cat": "Movimiento", "stones": ["paso", "furia"], "stats": "Velocidad, vel. de ataque", "passive": "—"},
	{"name": "Botas del viento", "cat": "Movimiento", "stones": ["viento", "viento"], "stats": "Mucha velocidad", "passive": "Fuera de combate corrés un 20% más."},
	{"name": "Botas del eco", "cat": "Movimiento", "stones": ["paso", "eco"], "stats": "Velocidad, enfriamiento", "passive": "—"},
	{"name": "Sello del cazador", "cat": "PvE", "stones": ["cazador", "filo"], "stats": "Ataque, vel. de ataque", "passive": "Cada monstruo que matás te devuelve un 5% de vida."},
	{"name": "Piedra matajefes", "cat": "PvE", "stones": ["cazador", "cazador"], "stats": "Ataque", "passive": "+15% de daño a jefes de mazmorra y de mundo."},
	{"name": "Ojo del guardián", "cat": "PvE", "stones": ["cazador", "vida"], "stats": "Vida, defensa", "passive": "Generás el doble de amenaza."},
	{"name": "Coraza de la cripta", "cat": "PvE", "stones": ["presa", "muralla"], "stats": "Defensa", "passive": "Recibís un 15% menos de daño de monstruos."},
	{"name": "Diente del gourmet", "cat": "PvE", "stones": ["cazador", "presa"], "stats": "Ataque", "passive": "Los monstruos sueltan ingredientes con +25% de probabilidad."},
	{"name": "Martillo del minero", "cat": "PvE", "stones": ["cazador", "muralla"], "stats": "Ataque", "passive": "Rompés vetas y árboles el doble de rápido."},
	{"name": "Brújula del explorador", "cat": "PvE", "stones": ["presa", "paso"], "stats": "Velocidad", "passive": "+15% de velocidad en el mundo abierto (no cuenta en PvP)."},
	{"name": "Estandarte de guerra", "cat": "Soporte", "stones": ["guia", "filo"], "stats": "Ataque, energía", "passive": "Los aliados cerca tuyo hacen un 6% más de daño."},
	{"name": "Lazo protector", "cat": "Soporte", "stones": ["amparo", "vida"], "stats": "Vida, curación", "passive": "Tus curas y escudos rinden un 20% más."},
	{"name": "Marca del guía", "cat": "Soporte", "stones": ["guia", "temple"], "stats": "Energía, resistencia al control", "passive": "El enemigo que controlás queda marcado: tus aliados le pegan un 8% más."},
	{"name": "Pluma del rescate", "cat": "Soporte", "stones": ["amparo", "paso"], "stats": "Curación, velocidad", "passive": "Si curás a un aliado por debajo del 30%, también le das un escudo."},
	{"name": "Campana del santuario", "cat": "Soporte", "stones": ["amparo", "guia"], "stats": "Curación, energía", "passive": "Al usar tu definitiva, los aliados cerca se limpian de controles."},
	{"name": "Lámpara del peregrino", "cat": "Soporte", "stones": ["guia", "guia"], "stats": "Energía, enfriamiento", "passive": "Los aliados cerca recuperan sus habilidades un 10% más rápido."},
	{"name": "Velo de bruma", "cat": "Soporte", "stones": ["temple", "calma"], "stats": "Resistencia al control, defensa mágica", "passive": "Los aliados cerca siguen ocultos en el pasto después de su primer ataque."},
	{"name": "Lanza del eclipse", "cat": "Ataque·Magia", "stones": ["filo", "arcana"], "stats": "Ataque, poder mágico", "passive": "Alternar básico y habilidad potencia el siguiente golpe un 10%."},
	{"name": "Corona invernal", "cat": "Defensa·Magia", "stones": ["muralla", "eco"], "stats": "Defensas, enfriamiento", "passive": "Te congelás: inmune a todo por 2 s (cada 2 min)."},
	{"name": "Sable del cielo", "cat": "Ataque·Magia", "stones": ["filo", "mira", "arcana"], "stats": "Ataque, poder mágico", "passive": "Tus golpes ejecutan a enemigos con menos del 8% de vida."},
]
