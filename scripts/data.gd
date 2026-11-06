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
	{"id": "tanque", "cls": "Tanque", "style": "Guardia de primera línea", "color": Color("#6fa8dc"), "hp": 950, "speed": 6.2, "phys": true, "natural": "escudo",
	 "s1": {"name": "Onda de choque", "type": "cone", "range": 7.0, "angle": 70.0, "dmg": 40, "slow": 0.5, "slow_dur": 2.0, "cd": 6.0},
	 "s2": {"name": "Carga de escudo", "type": "dash", "range": 8.0, "width": 2.4, "dmg": 35, "stun": 0.8, "cd": 8.0},
	 "passive": {"name": "Bloqueo", "effect": "block", "desc": "Cada 4 golpes recibidos, bloqueás uno."},
	 "s3": {"name": "Muralla", "type": "buff", "buff": "shield", "val": 280.0, "dur": 4.0, "cd": 14.0},
	 "ult": {"name": "Implosión", "type": "pull", "radius": 6.5, "dmg": 80, "stun": 1.4, "cd": 35.0}},
	{"id": "luchador", "cls": "Luchador", "style": "Cazademonios", "color": Color("#e06666"), "hp": 780, "speed": 6.6, "phys": true, "natural": "mandoble",
	 "s1": {"name": "Golpe sísmico", "type": "leap", "range": 9.0, "radius": 3.0, "dmg": 45, "cd": 7.0},
	 "s2": {"name": "Torbellino", "type": "nova", "radius": 3.6, "dmg": 42, "cd": 5.0},
	 "passive": {"name": "Persecución", "effect": "chase", "desc": "Tras una habilidad, tu próximo básico salta al objetivo."},
	 "s3": {"name": "Paso veloz", "type": "dash", "range": 5.0, "width": 1.8, "dmg": 22, "cd": 6.0},
	 "ult": {"name": "Onda de fisión", "type": "line", "range": 11.0, "width": 2.6, "dmg": 95, "delay": 0.15, "buff": "lifesteal", "val": 0.4, "dur": 6.0, "cd": 32.0}},
	{"id": "asesino", "cls": "Asesino", "style": "Sombra del templo", "color": Color("#b4a7d6"), "hp": 620, "speed": 7.4, "phys": true, "natural": "garras",
	 "s1": {"name": "Zarpazo", "type": "dash", "range": 6.5, "width": 1.8, "dmg": 32, "cd": 4.0},
	 "s2": {"name": "Bomba de humo", "type": "smoke", "radius": 4.0, "dur": 4.0, "slow": 0.4, "cd": 11.0},
	 "passive": {"name": "Instinto", "effect": "camo", "desc": "Tras 3 s sin recibir daño te camuflás; el primer golpe aturde y pega +50%."},
	 "s3": {"name": "Garra arrojadiza", "type": "proj", "range": 13.0, "speed": 32.0, "width": 0.7, "dmg": 38, "cd": 5.0},
	 "ult": {"name": "Cacería", "type": "buff", "buff": "hunt", "dur": 5.0, "shots": 2, "cd": 30.0}},
	{"id": "mago", "cls": "Mago", "style": "Electromante", "color": Color("#f6b26b"), "hp": 560, "speed": 6.4, "phys": false, "natural": "libro",
	 "s1": {"name": "Rayo bifurcado", "type": "cone", "range": 9.0, "angle": 50.0, "dmg": 46, "cd": 5.0, "el": "rayo"},
	 "s2": {"name": "Bola de rayo", "type": "proj", "range": 14.0, "speed": 20.0, "width": 1.0, "dmg": 42, "stun": 1.0, "cd": 7.0, "bounce": true, "el": "rayo"},
	 "passive": {"name": "Superconductor", "effect": "mark", "desc": "Tus habilidades marcan: el rayo pega +40% y la bola rebota entre marcados."},
	 "s3": {"name": "Paso eléctrico", "type": "blink", "range": 7.0, "cd": 10.0},
	 "ult": {"name": "Ira del trueno", "type": "blast", "range": 14.0, "radius": 3.2, "delay": 0.45, "dmg": 150, "cd": 38.0, "chain": true, "el": "rayo"}},
	{"id": "tirador", "cls": "Tirador", "style": "Artillera", "color": Color("#93c47d"), "hp": 600, "speed": 6.6, "phys": true, "natural": "canon",
	 "s1": {"name": "Bomba incendiaria", "type": "proj", "range": 16.0, "speed": 28.0, "width": 0.8, "dmg": 42, "cd": 5.0, "range_buff": true, "explode": 2.2, "el": "fuego"},
	 "s2": {"name": "Proyectil del vacío", "type": "proj", "range": 13.0, "speed": 24.0, "width": 0.8, "dmg": 34, "cd": 7.0, "explode": 2.6, "void_mark": true},
	 "passive": {"name": "Arma maléfica", "effect": "far", "desc": "Tus básicos pegan hasta +40% cuanto más lejos está el objetivo."},
	 "s3": {"name": "Rodada", "type": "dash", "range": 5.0, "width": 0.0, "dmg": 0, "cd": 6.0},
	 "ult": {"name": "Ráfaga ardiente", "type": "line", "range": 22.0, "width": 2.2, "dmg": 150, "delay": 0.35, "cd": 36.0, "el": "fuego"}},
	{"id": "soporte", "cls": "Soporte", "style": "Sacerdotisa", "color": Color("#ffe599"), "hp": 680, "speed": 6.5, "phys": false, "natural": "baculo",
	 "s1": {"name": "Luz de castigo", "type": "auto3", "range": 9.0, "dmg": 30, "slow": 0.4, "slow_dur": 1.5, "cd": 5.0},
	 "s2": {"name": "Curación sagrada", "type": "buff", "buff": "heal", "val": 0.25, "dur": 3.0, "cd": 10.0},
	 "passive": {"name": "Resurrección divina", "effect": "deathburst", "desc": "Al caer, liberás un estallido de luz que daña alrededor."},
	 "s3": {"name": "Sello de luz", "type": "blast", "range": 10.0, "radius": 3.0, "delay": 0.6, "dmg": 28, "slow": 0.5, "slow_dur": 2.0, "cd": 8.0},
	 "ult": {"name": "Bautismo sagrado", "type": "line", "range": 16.0, "width": 2.4, "dmg": 95, "delay": 0.7, "stun": 1.4, "cd": 34.0}},
]

const MOBDEF = {
	"lobo":    {"name": "Lobo", "hp": 130.0, "r": 0.8, "speed": 5.2, "aggro": 13.0, "dmg": 13.0, "xp": 12, "color": Color("#7a7f88"), "reach": 2.0, "wind": 0.45, "cd": 1.3},
	"arquero": {"name": "Arquero", "hp": 95.0, "r": 0.7, "speed": 4.4, "aggro": 16.0, "dmg": 16.0, "xp": 15, "color": Color("#9a6b3c"), "range": 13.0, "wind": 0.75, "cd": 2.2},
	"ogro":    {"name": "Ogro", "hp": 950.0, "r": 1.6, "speed": 3.6, "aggro": 15.0, "dmg": 22.0, "xp": 90, "color": Color("#7d5a3c"), "reach": 3.2, "wind": 0.6, "cd": 1.6},
}
