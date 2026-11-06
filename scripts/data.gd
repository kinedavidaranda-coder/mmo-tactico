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

# franjas de nivel del mundo (para nombres de zona y colores)
const TIERS = [
	{"name": "Animales", "lvl": [1, 15], "color": Color("#7ee787")},
	{"name": "Humanoides", "lvl": [15, 35], "color": Color("#f2cc60")},
	{"name": "Orcos y goblins", "lvl": [35, 45], "color": Color("#ff9b50")},
	{"name": "Criaturas de las cumbres", "lvl": [45, 60], "color": Color("#f85149")},
]
