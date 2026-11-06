# Demo de combate del MMORPG táctico.
# Cámara estilo Metin2 con apuntado, puntos de habilidad por maestría y mundo vivo (fuego y agua).
# Todo el mundo, la interfaz y los personajes se crean desde este script para que el proyecto sea fácil de leer.
extends Node3D

const Data = preload("res://scripts/data.gd")
const Terrain = preload("res://scripts/terrain.gd")

const ACT = ["s1", "s2", "s3", "ult"]
const MAXR = {"s1": 8, "s2": 6, "s3": 4, "ult": 3}
const SLOTNAME = {"s1": "Habilidad 1", "s2": "Habilidad 2", "s3": "Habilidad 3", "ult": "Definitiva", "passive": "Pasiva"}
const KEYNAME = {"s1": "1", "s2": "2", "s3": "3", "ult": "4"}
const XP_MAX = 1000.0
const B = 470.0                     # límite del mundo (el terreno mide 1 × 1 km)
const SAFE = Vector2(0, 0)
const SAFE_R = 52.0                 # la capital Lumen es zona segura
# ciudades: zonas seguras y puntos de inicio
const CITIES = {
	"lumen": {"name": "Lumen", "pos": Vector2(0, 0), "r": 52.0, "spawn": Vector2(0, 6)},
	"sapientia": {"name": "Sapientia", "pos": Vector2(-235, 40), "r": 46.0, "spawn": Vector2(-235, 58)},
}
const CELL = 2.0                    # tamaño de casillero de la grilla del mundo vivo
const SAVE_PATH = "user://progreso.json"

# ---------------------------------------------------------------- clases internas
class Player:
	var x := 0.0
	var z := 3.0
	var y := 0.0
	var fx := 0.0
	var fz := -1.0
	var hp := 100.0
	var max_hp := 100.0
	var shield := 0.0
	var shield_t := 0.0
	var speed := 6.0
	var cds := {"basic": 0.0, "s1": 0.0, "s2": 0.0, "s3": 0.0, "ult": 0.0}
	var weave := 0.0
	var calm := 99.0
	var dead := 0.0
	var dash = null
	var leap = null
	var hits := 0
	var chase := 0.0
	var lifesteal := 0.0
	var lifesteal_t := 0.0
	var camo := false
	var hunt := 0
	var hunt_t := 0.0
	var range_buff := 0.0
	var speed_t := 0.0
	var burn_t := 0.0
	var burn_acc := 0.0
	var queued = null
	var hidden := false
	var reveal_t := 0.0

class Mob:
	var type := ""
	var lvl := 1
	var tier := 0
	var mult := 1.0
	# comportamiento (estilo BotW)
	var camp := -1
	var state := "idle"         # idle, rest, dormant, flee, search, alert
	var init_state := "idle"
	var sentinel := false
	var sus := 0.0               # sospecha: "?" se llena hasta "!"
	var flee_t := 0.0
	var search_t := 0.0
	var last_seen := Vector2.ZERO
	var wander_t := 0.0
	var wx := 0.0
	var wz := 0.0
	var wake_t := 0.0
	var hit_t := 99.0
	var orbit := 1.0
	var charge = null
	var blink_t := 4.0
	var d := {}
	var x := 0.0
	var z := 0.0
	var sx := 0.0
	var sz := 0.0
	var hp := 0.0
	var max_hp := 0.0
	var atk_cd := 0.0
	var wind := 0.0
	var wind_dir := Vector2.ZERO
	var special := 3.0
	var slam = null
	var stun_t := 0.0
	var slow_t := 0.0
	var slow_v := 0.0
	var dead := 0.0
	var flash := 0.0
	var aggroed := false
	var mark := 0.0
	var void_mark := 0.0
	var tele = null
	var fx := 0.0
	var fz := 1.0
	var burn_acc := 0.0
	var node: Node3D
	var mats: Array = []
	var base_colors: Array = []

class Proj:
	var x := 0.0
	var z := 0.0
	var vx := 0.0
	var vz := 0.0
	var rng := 0.0
	var trav := 0.0
	var w := 0.5
	var s := {}
	var o := {}
	var hit := {}
	var node: Node3D
	var enemy := false
	var dmg := 0.0

class Blast:
	var line := false
	var ox := 0.0
	var oz := 0.0
	var d := Vector2.ZERO
	var x := 0.0
	var z := 0.0
	var r := 0.0
	var s := {}
	var t := 0.0
	var node: Node3D

class Fx:
	var node: Node3D
	var t := 0.3
	var mx := 0.3
	var mats: Array = []
	var base_a := 0.5

class Zone:
	var x := 0.0
	var z := 0.0
	var r := 0.0
	var t := 0.0
	var slow := 0.0
	var node: Node3D
	var mat: StandardMaterial3D

class FloatText:
	var pos := Vector3.ZERO
	var s := ""
	var color := Color.WHITE
	var size := 14
	var t := 1.0

class Cell:
	var i := 0
	var j := 0
	var x := 0.0
	var z := 0.0
	var st := "grass"
	var t := 0.0
	var spread := 0.0
	var idx := 0
	var base_y := 0.0
	var tint := Color.WHITE

class TreeObj:
	var x := 0.0
	var z := 0.0
	var sp := 0                # especie (índice de malla)
	var idx := 0               # índice dentro del MultiMesh de su especie
	var id := 0                # índice general (para el tocón)
	var sc := 1.0
	var rot := 0.0
	var size := 1              # 0 chico, 1 mediano, 2 grande (no se rompe)
	var hp := 0.0
	var max_hp := 0.0
	var alive := true
	var regrow := 0.0
	var grow := 1.0

class Puddle:
	var x := 0.0
	var z := 0.0
	var r := 0.0
	var elec := 0.0
	var cool := 0.0
	var node: MeshInstance3D
	var mat: StandardMaterial3D

# ---------------------------------------------------------------- estado
var weapon := {}                    # kit de la clase + básico del arma
var terrain = null                  # alturas y colores del mundo
var minimap_tex: ImageTexture
var P: Player = null
var pnode: Node3D = null
var pmats: Array = []
var running := false
var mobs: Array = []
var projs: Array = []
var blasts: Array = []
var fxs: Array = []
var zones: Array = []
var texts: Array = []
var cells := {}
var cell_list: Array = []
var grass_mm: MultiMesh
var trees: Array = []
var tree_mms: Array = []           # un MultiMesh por especie
var tree_meshes: Array = []
var veg_mat: StandardMaterial3D
var stump_mm: MultiMesh
var tree_grid := {}
var falling: Array = []
var regrowing: Array = []
var wood := 0
var ingredients := {}
# inventario de gemas: piedras básicas, gemas finales y lo engarzado en cada pieza
var piedras := {"filo": 1, "muralla": 1, "paso": 1}
var gemas := {}
var equipped := {}
var gear := {}                       # stats sumados de lo engarzado
var menu
var running_prev := false
const Menu = preload("res://scripts/menu.gd")
var minerals := {}                   # minerales de las vetas (para el Alquimista)
var ores: Array = []
var last_col := {}
var shrines: Array = []              # santuarios (viaje rápido)
var chests: Array = []
var pois: Array = []                 # nombres que se ven al acercarte
var flocks: Array = []
var travelers: Array = []                # ingredientes de cocina que sueltan los bichos
var camps: Array = []                # campamentos de monstruos (por franja de nivel)
var fence_xf: Array = []             # postes de cercos (MultiMesh)
var fence_col: Array = []
var cur_zone := ""
var colliders: Array = []          # muros y edificios: cajas en el plano (centro, medio tamaño, giro)
var col_grid := {}                  # grilla de 16 m para buscar colisiones rápido
var puddles: Array = []

var mastery := {}                   # maestría por estilo (facción:clase:rareza)
var ranks_all := {}
var xp_mult := 1
var oil = null                      # aceite del básico: null, "fuego" o "rayo"
var pick_w = null                   # arma elegida en el selector (null = natural)

var cam_yaw := 0.6
var cam_pitch := 0.95
var cam_dist := 20.0
var cam_x := 0.0
var cam_z := 0.0
var cam_drag := false
var basic_held := false

var camera: Camera3D
var world: Node3D
var sector_cache := {}
var line_mesh: BoxMesh
var ring_mesh: TorusMesh
var grass_mesh: BoxMesh
var grass_mat: StandardMaterial3D
var burnt_mat: StandardMaterial3D
var fire_mat: StandardMaterial3D
var aim_line: Node3D

# héroe con modelo 3D y animaciones (si existe en assets/heroes/<clase>.glb)
const HERO_SCALE = 1.3
const SWORD_POS = Vector3(0.0, 0.08, 0.03)
const SWORD_ROT = Vector3(0, 0, 90)
const SHIELD_POS = Vector3(0.05, 0.08, 0.0)
const SHIELD_ROT = Vector3(-90, 90, 0)
var hero_model: Node3D = null
var hero_anim: AnimationPlayer = null
var hero_cur := ""
var act_t := 0.0
var act_name := ""
var moving := false

# indicador de apuntado estilo MLBB: mantener la tecla, apuntar y soltar
const SLOT_KEYS = {KEY_1: "s1", KEY_Q: "s1", KEY_2: "s2", KEY_E: "s2", KEY_3: "s3", KEY_R: "s3", KEY_4: "ult", KEY_F: "ult"}
var aim_slot := ""
var aim_root: Node3D
var aim_ring: MeshInstance3D
var aim_sector: MeshInstance3D
var aim_disc: MeshInstance3D
var aim_target: MeshInstance3D
var aim_rect: Node3D
var aim_mats: Array = []

# interfaz
var ui: CanvasLayer
var overlay: Control
var name_lbl: Label
var sub_lbl: Label
var hp_bar: ProgressBar
var hp_lbl: Label
var m_bar: ProgressBar
var m_lbl: Label
var chips_lbl: Label
var toast_lbl: Label
var toast_t := 0.0
var btn_pts: Button
var btn_oil: Button
var btn_xp: Button
var skill_btns := {}
var pts_panel: PanelContainer
var pts_box: VBoxContainer
var pick_panel: Panel
var pick_box: VBoxContainer
var pts_was_running := false
var rng := RandomNumberGenerator.new()

# ================================================================= ARRANQUE
func _ready() -> void:
	rng.seed = 7
	load_progress()
	build_environment()
	terrain = Terrain.new()
	build_world()
	build_living_world()
	build_ui()
	show_picker()

# ================================================================= GUARDADO
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		mastery = data.get("mastery", {})
		ranks_all = data.get("ranks", {})
		xp_mult = int(data.get("xp_mult", 1))
		var inv: Dictionary = data.get("inv", {})
		if not inv.is_empty():
			piedras = inv.get("piedras", piedras)
			gemas = inv.get("gemas", {})
			equipped = inv.get("equipped", {})
			minerals = inv.get("minerals", {})
			ingredients = inv.get("ingredients", {})
	recompute_gear()

func save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"mastery": mastery, "ranks": ranks_all, "xp_mult": xp_mult,
			"inv": {"piedras": piedras, "gemas": gemas, "equipped": equipped, "minerals": minerals, "ingredients": ingredients}}))

# ================================================================= GEMAS, PIEDRAS Y EQUIPO
func gem_def(name: String) -> Dictionary:
	for g in Data.GEMAS:
		if g.name == name:
			return g
	return {}

func item_cat(it: Dictionary) -> String:
	if it.kind == "piedra":
		return Data.PIEDRAS[it.id].cat
	return gem_def(it.id).get("cat", "")

func item_stats(it: Dictionary) -> Dictionary:
	if it.kind == "piedra":
		return Data.STONE_STATS[it.id].duplicate()
	var out := {}
	for pid in gem_def(it.id).get("stones", []):
		for k in Data.STONE_STATS[pid]:
			out[k] = out.get(k, 0) + Data.STONE_STATS[pid][k]
	for k in out:
		out[k] = int(round(out[k] * 1.6))       # la gema rinde más que sus piedras sueltas (y además tiene pasiva)
	return out

func recompute_gear() -> void:
	gear = {}
	for sl in equipped:
		var it = equipped[sl]
		if it:
			var st := item_stats(it)
			for k in st:
				gear[k] = gear.get(k, 0) + st[k]
	if P and weapon:
		var frac: float = P.hp / max(1.0, P.max_hp)
		P.max_hp = weapon.hp * (1.0 + gear.get("hp", 0) / 100.0)
		P.hp = P.max_hp * frac
		P.speed = weapon.speed * (1.0 + gear.get("spd", 0) / 100.0)

func owned_items() -> Array:
	var out := []
	for g in gemas:
		if int(gemas[g]) > 0:
			out.append({"kind": "gema", "id": g, "count": int(gemas[g])})
	for pid in piedras:
		if int(piedras[pid]) > 0:
			out.append({"kind": "piedra", "id": pid, "count": int(piedras[pid])})
	return out

# las botas solo llevan Movimiento, y Movimiento solo va en las botas; la misma gema no se repite
func fits_slot(it: Dictionary, slot: String) -> bool:
	var mov := item_cat(it) == "Movimiento"
	if (slot == "pies") != mov:
		return false
	if it.kind == "gema":
		for sl in equipped:
			var e = equipped[sl]
			if e and sl != slot and e.kind == "gema" and e.id == it.id:
				return false
	return true

func equip(slot: String, it: Dictionary) -> void:
	var bag: Dictionary = gemas if it.kind == "gema" else piedras
	if not fits_slot(it, slot) or int(bag.get(it.id, 0)) < 1:
		return
	unequip(slot)
	bag[it.id] = int(bag.get(it.id, 0)) - 1
	equipped[slot] = {"kind": it.kind, "id": it.id}
	recompute_gear()
	save_progress()

func unequip(slot: String) -> void:
	var e = equipped.get(slot)
	if e:
		var bag: Dictionary = gemas if e.kind == "gema" else piedras
		bag[e.id] = int(bag.get(e.id, 0)) + 1
		equipped.erase(slot)
		recompute_gear()
		save_progress()

func material_count(mn: String) -> int:
	return int(minerals.get(mn, 0)) + int(ingredients.get(mn, 0))

func use_material(mn: String) -> void:
	if int(minerals.get(mn, 0)) > 0:
		minerals[mn] = int(minerals[mn]) - 1
	else:
		ingredients[mn] = int(ingredients.get(mn, 0)) - 1

# Alquimia: tallar una piedra con sus dos minerales
func can_carve(pid: String) -> bool:
	for mn in Data.PIEDRAS[pid].recipe:
		if material_count(mn) < 1:
			return false
	return true

func carve(pid: String) -> void:
	if not can_carve(pid):
		return
	for mn in Data.PIEDRAS[pid].recipe:
		use_material(mn)
	piedras[pid] = int(piedras.get(pid, 0)) + 1
	save_progress()

# Joyería: combinar piedras en una gema
func can_combine(gname: String) -> bool:
	var need := {}
	for pid in gem_def(gname).get("stones", []):
		need[pid] = need.get(pid, 0) + 1
	for pid in need:
		if int(piedras.get(pid, 0)) < need[pid]:
			return false
	return not need.is_empty()

func combine(gname: String) -> void:
	if not can_combine(gname):
		return
	for pid in gem_def(gname).stones:
		piedras[pid] = int(piedras[pid]) - 1
	gemas[gname] = int(gemas.get(gname, 0)) + 1
	save_progress()

func open_menu() -> void:
	if menu.visible or weapon == null or weapon.is_empty() or P == null:
		return
	running_prev = running
	running = false
	aim_slot = ""
	basic_held = false
	menu.open()

func menu_closed() -> void:
	running = running_prev
	save_progress()

# ================================================================= MAESTRÍA Y PUNTOS
func style_key(id: String) -> String:
	return "luz:%s:inicial" % id

func sk() -> String:
	return style_key(weapon.id)

func pct(key: String) -> float:
	return min(100.0, float(mastery.get(key, 0.0)) / XP_MAX * 100.0)

func total_pts(p: float) -> int:
	return 1 + int(floor(p / 5.0 + 1e-9))          # 0% → 1 punto … 100% → 21

func cap_for(slot: String, p: float) -> int:
	if slot == "ult":
		return 3 if p >= 100.0 else (2 if p >= 90.0 else (1 if p >= 75.0 else 0))
	return min(MAXR[slot], 1 + int(floor(p / 12.5 + 1e-9)))

func ranks_of(id: String) -> Dictionary:
	var k := style_key(id)
	if not ranks_all.has(k):
		ranks_all[k] = {"s1": 1, "s2": 0, "s3": 0, "ult": 0}
	return ranks_all[k]

func R() -> Dictionary:
	return ranks_of(weapon.id)

func spent(r: Dictionary) -> int:
	return int(r.s1) + int(r.s2) + int(r.s3) + int(r.ult)

func free_pts() -> int:
	return total_pts(pct(sk())) - spent(R())

func can_add(slot: String) -> bool:
	return free_pts() > 0 and int(R()[slot]) < cap_for(slot, pct(sk()))

func unlocked(slot: String) -> bool:
	return slot == "passive" or int(R()[slot]) > 0

func passive() -> Dictionary:
	return weapon.passive

func slot_of(s: Dictionary) -> String:
	for k in ACT:
		if weapon[k] == s:
			return k
	return ""

func rank_mult(slot: String) -> float:
	if slot == "":
		return 1.0
	var r := int(R()[slot])
	if r <= 1:
		return 1.0
	return 1.0 + (0.10 if slot == "ult" else 0.08) * (r - 1)

func skill_cd(slot: String) -> float:
	return float(weapon[slot].cd) * (1.0 - 0.04 * max(0, int(R()[slot]) - 1)) * (1.0 - min(0.4, gear.get("cdr", 0) / 100.0))

# ¿el punto está dentro de alguna ciudad (más un margen)?
func in_city(x: float, z: float, margin := 0.0) -> bool:
	for k in CITIES:
		var c: Dictionary = CITIES[k]
		if Vector2(x, z).distance_to(c.pos) < c.r + margin:
			return true
	return false

# altura del suelo (o del agua) en un punto
func H(x: float, z: float) -> float:
	if not terrain:
		return 0.0
	var h: float = terrain.ground(x, z)
	if h < 2.5 and not bridges.is_empty():
		var bt := bridge_top(x, z)
		if bt > h:
			return bt
	return h

var bridges: Array = []

# altura de la tabla del puente en (x, z), o -INF si no hay puente
func bridge_top(x: float, z: float) -> float:
	for b in bridges:
		var d: Vector2 = Vector2(x, z) - b.c
		var along: float = d.dot(b.dir)
		var across: float = d.dot(Vector2(b.dir.y, -b.dir.x))
		if abs(along) < b.hl and abs(across) < 2.5:
			return b.y + 0.25
	return -INF

# ================================================================= GEOMETRÍA
func mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m

func ind_mat(c: Color, a: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, a)
	m.render_priority = 1
	m.no_depth_test = true            # los indicadores se ven siempre, aunque el piso tenga relieve
	return m

func sector_mesh(deg: float) -> ArrayMesh:
	if sector_cache.has(deg):
		return sector_cache[deg]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := deg_to_rad(deg) / 2.0
	var n := 40
	for k in n:
		var a0 := -h + 2.0 * h * k / n
		var a1 := -h + 2.0 * h * (k + 1) / n
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a1), 0, cos(a1)))
		st.add_vertex(Vector3(sin(a0), 0, cos(a0)))
	var m := st.commit()
	sector_cache[deg] = m
	return m

func disc_mesh() -> ArrayMesh:
	return sector_mesh(360.0)

func ground_mesh(mesh: Mesh, c: Color, a: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ind_mat(c, a)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	mi.position.y = 0.06
	return mi

func line_holder(w: float, L: float, c: Color, a: float, parent: Node3D) -> Node3D:
	# rectángulo plano que arranca en el origen y se extiende hacia +Z
	var holder := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = line_mesh
	mi.material_override = ind_mat(c, a)
	mi.position = Vector3(0, 0, 0.5)
	holder.add_child(mi)
	holder.scale = Vector3(max(0.01, w), 1, max(0.01, L))
	parent.add_child(holder)
	return holder

func orient(n: Node3D, dx: float, dz: float) -> void:
	n.rotation.y = atan2(dx, dz)

func box(size: Vector3, c: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi

func cyl(top: float, bottom: float, h: float, c: Color, pos: Vector3, parent: Node3D, seg := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = seg
	mi.mesh = cm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi

func sphere(r: float, c: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = 12
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi

# ================================================================= MUNDO
func build_environment() -> void:
	world = Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#3f7fd0")
	sm.sky_horizon_color = Color("#f2dcc0")
	sm.ground_horizon_color = Color("#e8d6bf")
	sm.ground_bottom_color = Color("#6a8a5a")
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.68, 0.78)
	e.ambient_light_energy = 0.45
	e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	e.fog_enabled = true
	e.fog_light_color = Color("#e6dccb")
	e.fog_density = 0.0022
	e.fog_sky_affect = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.9
	e.tonemap_white = 1.6
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.18
	e.adjustment_contrast = 1.06
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 55, 0)
	sun.light_energy = 0.85
	sun.light_color = Color(1.0, 0.9, 0.74)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = 50
	camera.far = 900
	add_child(camera)
	line_mesh = BoxMesh.new()
	line_mesh.size = Vector3(1, 0.02, 1)
	ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.92
	ring_mesh.outer_radius = 1.0
	ring_mesh.rings = 48

func build_world() -> void:
	# terreno con relieve: colores por zona, altura y pendiente + detalle del shader
	var tmat := ShaderMaterial.new()
	tmat.shader = load("res://shaders/terreno.gdshader")
	tmat.set_shader_parameter("detail", make_noise_tex(3, 0.05))
	terrain.build_mesh(world, tmat)
	# agua (río y lago)
	var water := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(Terrain.SIZE, Terrain.SIZE)
	water.mesh = wp
	var wm := ShaderMaterial.new()
	wm.shader = load("res://shaders/agua.gdshader")
	wm.set_shader_parameter("ripples", make_noise_tex(9, 0.03))
	water.material_override = wm
	water.position.y = Terrain.WATER
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(water)
	build_capital()
	build_sapientia()
	plan_camps()
	build_structures()
	build_vegetation()
	build_ores()
	build_flora()
	build_points_of_interest()
	# minimapa
	minimap_tex = ImageTexture.create_from_image(terrain.minimap_image(256))
	# línea de apuntado hacia el cursor
	aim_line = line_holder(0.12, 1, Color.WHITE, 0.25, world)
	aim_line.visible = false
	build_aim_indicator()

func make_noise_tex(seed_: int, freq: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	t.generate_mipmaps = true
	return t

# Lumen, capital del Imperio: murallas blancas, techos azules y una ciudadela en el centro
func build_capital() -> void:
	var stone := Color("#e3dccb")
	var roof := Color("#3d5f9e")
	var gold := Color("#d9b04c")
	var y0 := H(0, 0)
	var exits := []
	for r in Terrain.ROADS:
		exits.append(atan2(r[1].x, r[1].y))
	var segs := 64
	for k in segs:
		var a := TAU * k / segs
		var gap := false
		for e in exits:
			if abs(angle_difference(a, e)) < 0.16:
				gap = true
		if gap:
			continue
		var px := sin(a) * SAFE_R
		var pz := cos(a) * SAFE_R
		solid_box(Vector3(5.4, 5.0, 1.6), stone, Vector3(px, y0 + 2.5, pz), a)
		if k % 8 == 0:
			cyl(1.8, 2.0, 8.0, stone, Vector3(px, y0 + 4.0, pz), world, 10)
			add_collider(Vector2(px, pz), Vector2(1.9, 1.9), 0.0)
			cyl(0.01, 2.4, 3.0, roof, Vector3(px, y0 + 9.5, pz), world, 10)
	# ciudadela central
	solid_box(Vector3(14, 10, 14), stone, Vector3(0, y0 + 5, -6), 0.0)
	box(Vector3(9, 6, 9), stone, Vector3(0, y0 + 13, -6), world)
	cyl(0.01, 7.5, 6.0, roof, Vector3(0, y0 + 19, -6), world, 4).rotation.y = PI / 4
	for c in [Vector2(-7, -13), Vector2(7, -13), Vector2(-7, 1), Vector2(7, 1)]:
		cyl(1.6, 1.8, 14.0, stone, Vector3(c.x, y0 + 7, c.y), world, 10)
		add_collider(c, Vector2(1.8, 1.8), 0.0)
		cyl(0.01, 2.2, 3.5, roof, Vector3(c.x, y0 + 15.7, c.y), world, 10)
	cyl(0.25, 0.25, 4.0, gold, Vector3(0, y0 + 24, -6), world, 6)
	sphere(0.9, gold, Vector3(0, y0 + 26.5, -6), world)
	# casas
	var r := RandomNumberGenerator.new()
	r.seed = 99
	var placed := 0
	var tries := 0
	while placed < 26 and tries < 400:
		tries += 1
		var a := r.randf() * TAU
		var d := r.randf_range(20.0, SAFE_R - 7.0)
		var x := sin(a) * d
		var z := cos(a) * d
		if terrain.road_dist(Vector2(x, z)) < 6.0:
			continue
		var w := r.randf_range(4.0, 6.5)
		var hgt := r.randf_range(3.0, 5.0)
		if blocked(x, z, w * 0.8):
			continue
		solid_box(Vector3(w, hgt, w * 0.8), stone.darkened(r.randf() * 0.12), Vector3(x, y0 + hgt / 2, z), a)
		var rf := cyl(0.01, w * 0.78, 2.2, roof.lightened(r.randf() * 0.15), Vector3(x, y0 + hgt + 1.1, z), world, 4)
		rf.rotation.y = a + PI / 4
		placed += 1
	# zona segura (borde azul en el piso)
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.material_override = ind_mat(Color("#58a6ff"), 0.35)
	ring.material_override.no_depth_test = false
	ring.scale = Vector3(SAFE_R + 2.5, 0.05, SAFE_R + 2.5)
	ring.position.y = y0 + 0.08
	world.add_child(ring)

# ----------------------------------------------------------------- colisiones (muros y edificios)
func add_collider(c: Vector2, half: Vector2, rot: float) -> void:
	var col := {"c": c, "h": half, "r": rot, "off": false}
	colliders.append(col)
	var reach: float = half.length()
	for gx in range(int(floor((c.x - reach) / 16.0)), int(floor((c.x + reach) / 16.0)) + 1):
		for gz in range(int(floor((c.y - reach) / 16.0)), int(floor((c.y + reach) / 16.0)) + 1):
			var k := Vector2i(gx, gz)
			if not col_grid.has(k):
				col_grid[k] = []
			col_grid[k].append(col)
	last_col = col

func solid_box(size: Vector3, c: Color, pos: Vector3, rot: float) -> MeshInstance3D:
	var mi := box(size, c, pos, world)
	mi.rotation.y = rot
	add_collider(Vector2(pos.x, pos.z), Vector2(size.x / 2.0, size.z / 2.0), rot)
	return mi

# ¿el punto (con un radio) choca con algún muro o edificio?
func blocked(x: float, z: float, pad := 0.6) -> bool:
	var k := Vector2i(int(floor(x / 16.0)), int(floor(z / 16.0)))
	if not col_grid.has(k):
		return false
	for col in col_grid[k]:
		if col.get("off", false):
			continue
		var dx: float = x - col.c.x
		var dz: float = z - col.c.y
		var cr := cos(col.r)
		var sr := sin(col.r)
		var lx := dx * cr - dz * sr
		var lz := dx * sr + dz * cr
		if abs(lx) < col.h.x + pad and abs(lz) < col.h.y + pad:
			return true
	return false

# un dash atraviesa muros, pero no puede terminar adentro de uno: se estira hasta salir
func dash_end(sx: float, sz: float, ex: float, ez: float) -> Vector2:
	var d := Vector2(ex - sx, ez - sz)
	var dir := d.normalized() if d.length() > 0.01 else Vector2(P.fx, P.fz)
	var p := Vector2(ex, ez)
	var tries := 0
	while blocked(p.x, p.y) and tries < 20:
		p += dir * 0.5
		tries += 1
	if blocked(p.x, p.y):
		p = Vector2(ex, ez)
		while blocked(p.x, p.y) and p.distance_to(Vector2(sx, sz)) > 0.3:
			p -= dir * 0.5
	return Vector2(clamp(p.x, -B, B), clamp(p.y, -B, B))

# ----------------------------------------------------------------- construcciones dispersas
func ok_site(x: float, z: float, r: float) -> bool:
	var p := Vector2(x, z)
	if in_city(x, z, 20.0) or terrain.road_dist(p) < r + 4.0 or terrain.river_dist(p) < r + 10.0:
		return false
	if p.distance_to(Terrain.LAKE) < Terrain.LAKE_R + r + 15.0:
		return false
	if terrain.height(x, z) < 1.5 or terrain.height(x, z) > 30.0 or blocked(x, z, r):
		return false
	return true

func wall_run(a: Vector2, b: Vector2, thick: float, hgt: float, col: Color, broken: float, r: RandomNumberGenerator) -> void:
	var L := a.distance_to(b)
	var n: int = max(1, int(L / 4.0))
	var dir := (b - a) / L
	var rot := atan2(dir.x, dir.y) + PI / 2
	for i in n:
		if r.randf() < broken:
			continue
		var c := a + dir * (L * (i + 0.5) / n)
		var hh: float = hgt * (r.randf_range(0.55, 1.0) if broken > 0 else 1.0)
		solid_box(Vector3(L / n + 0.05, hh, thick), col, Vector3(c.x, H(c.x, c.y) + hh / 2.0 - 0.2, c.y), rot)

func build_structures() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 777
	var stone := Color("#cfc7b5")
	var old := Color("#a59c8a")
	var wood := Color("#7a5634")
	var roof := Color("#3d5f9e")
	var straw := Color("#c9a94f")
	# torres de vigía en los caminos
	for spot in [Vector2(-50, -150), Vector2(150, -45), Vector2(-160, 35), Vector2(28, 190), Vector2(-115, -300), Vector2(330, -75)]:
		var x: float = spot.x + 9.0
		var z: float = spot.y + 6.0
		var y := H(x, z)
		cyl(2.2, 2.6, 11.0, stone, Vector3(x, y + 5.5, z), world, 8)
		cyl(0.01, 3.2, 3.5, roof, Vector3(x, y + 12.7, z), world, 8)
		add_collider(Vector2(x, z), Vector2(2.5, 2.5), 0.0)
	# ruinas: muros rotos al pie de la cordillera y en el cañadón
	var ruins := 0
	var tries := 0
	while ruins < 16 and tries < 300:
		tries += 1
		var x := r.randf_range(-430, 430)
		var z := r.randf_range(-330, 60)
		if x > -180 and z > -120:
			continue
		if not ok_site(x, z, 10):
			continue
		var a := r.randf() * TAU
		var d := Vector2(cos(a), sin(a))
		var c := Vector2(x, z)
		wall_run(c - d * 9, c + d * 9, 1.4, 3.2, old, 0.25, r)
		wall_run(c + d * 9, c + d * 9 + Vector2(-d.y, d.x) * 8, 1.4, 3.2, old, 0.3, r)
		ruins += 1
	# granjas con cercos en los campos del sur, y un molino
	var farms := 0
	tries = 0
	while farms < 9 and tries < 300:
		tries += 1
		var x := r.randf_range(-340, 340)
		var z := r.randf_range(170, 420)
		if not ok_site(x, z, 9):
			continue
		var a := r.randf_range(-0.4, 0.4)
		var y := H(x, z)
		solid_box(Vector3(7, 4, 5.5), Color("#e8dcc0"), Vector3(x, y + 2, z), a)
		cyl(0.01, 5.2, 2.6, straw, Vector3(x, y + 5.3, z), world, 4).rotation.y = a + PI / 4
		var f := Vector2(x, z)
		var fx := Vector2(cos(a), -sin(a))
		var fz := Vector2(sin(a), cos(a))
		var corners = [f + fx * -9 + fz * 7, f + fx * 9 + fz * 7, f + fx * 9 + fz * 14, f + fx * -9 + fz * 14]
		for k in 3:
			fence_run(corners[k], corners[k + 1], "rustico", r)
		if farms == 2:
			var mx := x + 14.0
			cyl(1.8, 2.4, 10.0, Color("#e8dcc0"), Vector3(mx, H(mx, z) + 5, z), world, 8)
			add_collider(Vector2(mx, z), Vector2(2.3, 2.3), 0.0)
			var hub := Node3D.new()
			hub.position = Vector3(mx, H(mx, z) + 9, z + 2.6)
			hub.name = "Aspas"
			world.add_child(hub)
			for k in 4:
				var blade := box(Vector3(0.5, 7, 0.15), wood, Vector3(0, 3.5, 0), hub)
				var arm := Node3D.new()
				hub.add_child(arm)
				blade.reparent(arm)
				arm.rotation.z = k * PI / 2
		farms += 1
	# alrededor de cada campamento: cercos, empalizadas o ruinas según quién vive ahí
	for cp in camps:
		decorate_camp(cp, r, old)
	finish_fences()

# ----------------------------------------------------------------- campamentos por franja de nivel
# Nv 1–15 animales cerca de las ciudades · 15–35 humanoides en los caminos ·
# 35–45 orcos y goblins en las fronteras · 45+ criaturas en las cumbres del norte
const CAMP_PLAN = [
	# [tier, lvl_min, lvl_max, x, z, [[tipo, cantidad], ...]]
	[0, 1, 3, -110, 90, [["conejo", 4]]],
	[0, 1, 3, 60, -70, [["conejo", 4]]],
	[0, 2, 6, -195, -25, [["conejo", 3], ["jabali", 1]]],
	[0, 4, 8, 70, 120, [["jabali", 3]]],
	[0, 5, 9, -70, -110, [["lobo", 4]]],
	[0, 6, 10, 140, -75, [["lobo", 4]]],
	[0, 6, 10, -290, 95, [["jabali", 3]]],
	[0, 12, 15, 170, -130, [["oso", 1], ["lobo", 2]]],
	[0, 13, 15, -160, 145, [["oso", 1]]],
	[1, 16, 22, 40, 230, [["bandido", 3], ["arquero", 2]]],
	[1, 18, 25, 225, 40, [["bandido", 3], ["arquero", 2]]],
	[1, 20, 28, -120, 245, [["bandido", 3], ["arquero", 1]]],
	[1, 22, 30, -60, -250, [["bandido", 2], ["arquero", 2]]],
	[1, 28, 35, 200, -190, [["jefe", 1], ["bandido", 2], ["arquero", 2]]],
	[1, 30, 35, -385, -60, [["jefe", 1], ["arquero", 2]]],
	[2, 35, 40, 340, 100, [["goblin", 4], ["hondero", 2]]],
	[2, 36, 40, 150, 340, [["goblin", 3], ["hondero", 2]]],
	[2, 38, 43, 360, -150, [["orco", 3], ["goblin", 2]]],
	[2, 38, 42, -240, 350, [["orco", 2], ["goblin", 2]]],
	[2, 43, 45, 330, 300, [["ogro", 1], ["orco", 2]]],
	[2, 42, 45, -450, 300, [["ogro", 1], ["goblin", 3]]],
	[3, 46, 50, -60, -370, [["golem", 1]]],
	[3, 47, 52, 150, -360, [["troll", 3]]],
	[3, 48, 54, -300, -330, [["espectro", 3]]],
	[3, 52, 58, 360, -360, [["golem", 1], ["troll", 2]]],
]

func site_ok(x: float, z: float, r: float) -> bool:
	if in_city(x, z, 25.0) or terrain.road_dist(Vector2(x, z)) < 6.0 or terrain.river_dist(Vector2(x, z)) < 9.0:
		return false
	if terrain.height(x, z) < 1.5 or blocked(x, z, r):
		return false
	for dd in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		if abs(terrain.height(x + dd.x, z + dd.y) - terrain.height(x, z)) > r * 0.55:
			return false
	return true

# busca el lugar libre más cercano en espiral
func free_spot(p: Vector2, pad: float) -> Vector2:
	if not blocked(p.x, p.y, pad):
		return p
	for ring in range(1, 40):
		for k in 12:
			var a := TAU * k / 12.0
			var q := p + Vector2(cos(a), sin(a)) * ring * 1.5
			if not blocked(q.x, q.y, pad) and terrain.height(q.x, q.y) > Terrain.WATER - 0.5:
				return q
	return p

func plan_camps() -> void:
	camps.clear()
	for c in CAMP_PLAN:
		var p := Vector2(c[3], c[4])
		var found := p
		var ok := site_ok(p.x, p.y, 8.0)
		var ring := 1
		while not ok and ring < 30:
			for k in 16:
				var a := TAU * k / 16.0
				var q := p + Vector2(cos(a), sin(a)) * ring * 4.0
				if site_ok(q.x, q.y, 8.0):
					found = q
					ok = true
					break
			ring += 1
		camps.append({"tier": c[0], "lvl": [c[1], c[2]], "pos": found, "roster": c[5]})

func zone_at(x: float, z: float) -> Dictionary:
	if in_city(x, z):
		var best := ""
		for k in CITIES:
			if Vector2(x, z).distance_to(CITIES[k].pos) < CITIES[k].r:
				best = CITIES[k].name
		return {"name": best, "tier": -1}
	var bn: String = Terrain.BIOME_NAMES[Terrain.biome_at(x, z)]
	if z < -290.0:
		return {"name": bn, "tier": 3}
	var dl := Vector2(x, z).distance_to(CITIES.lumen.pos)
	var ds := Vector2(x, z).distance_to(CITIES.sapientia.pos)
	var d: float = min(dl, ds)
	if d < 170.0:
		return {"name": bn, "tier": 0}
	if d < 300.0:
		return {"name": bn, "tier": 1}
	return {"name": bn, "tier": 2}

# cercos: "rustico" (postes y travesaños, como de granja), "empalizada" (troncos en punta)
# y "orca" (empalizada oscura). Bloquean el paso, pero los dashes los atraviesan.
func fence_run(a: Vector2, b: Vector2, style: String, r: RandomNumberGenerator) -> void:
	var L := a.distance_to(b)
	if L < 0.5:
		return
	var dir := (b - a) / L
	var rot := atan2(dir.x, dir.y) + PI / 2
	var step := 0.95 if style == "rustico" else 0.55
	var n := int(L / step) + 1
	var base := Color("#6e5a3a") if style != "orca" else Color("#3e3326")
	var hgt := 1.5 if style == "rustico" else (3.0 if style == "empalizada" else 3.4)
	var rad := 0.13 if style == "rustico" else 0.24
	for i in n:
		var c: Vector2 = a + dir * (L * i / float(maxi(1, n - 1)))
		var hh: float = hgt * r.randf_range(0.85, 1.12)
		var gy := H(c.x, c.y)
		var bs := Basis.from_euler(Vector3(r.randf_range(-0.06, 0.06), r.randf() * TAU, r.randf_range(-0.06, 0.06))).scaled(Vector3(rad, hh, rad))
		fence_xf.append(Transform3D(bs, Vector3(c.x, gy + hh / 2.0 - 0.15, c.y)))
		var tint := base.lerp(Color("#5c6b3a"), r.randf() * 0.45)       # musgo
		fence_col.append(tint)
		if style != "rustico":
			var tip := Basis.from_euler(Vector3(0, r.randf() * TAU, 0)).scaled(Vector3(rad, 0.5, rad))
			fence_xf.append(Transform3D(tip, Vector3(c.x, gy + hh - 0.15 + 0.25, c.y)))
			fence_col.append(tint.darkened(0.15) if style == "empalizada" else Color("#d9d2bf"))
	if style == "rustico":
		for yy in [0.55, 1.1]:
			var mid := (a + b) / 2.0
			var rail := box(Vector3(L, 0.12, 0.12), Color("#7a6040"), Vector3(mid.x, (H(a.x, a.y) + H(b.x, b.y)) / 2.0 + yy, mid.y), world)
			rail.rotation.y = rot
	add_collider((a + b) / 2.0, Vector2(L / 2.0, 0.3 if style == "rustico" else 0.4), rot)

func finish_fences() -> void:
	if fence_xf.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 6
	cm.rings = 1
	mm.mesh = cm
	mm.instance_count = fence_xf.size()
	for i in fence_xf.size():
		mm.set_instance_transform(i, fence_xf[i])
		mm.set_instance_color(i, fence_col[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	mi.material_override = m
	world.add_child(mi)

# arco de piedra con dintel de madera (entrada de campamento)
func stone_gate(c: Vector2, rot: float) -> void:
	var dx := Vector2(cos(rot), -sin(rot))
	var y := H(c.x, c.y)
	for sgn in [-1.0, 1.0]:
		var q: Vector2 = c + dx * 2.6 * sgn
		solid_box(Vector3(1.4, 4.2, 1.4), Color("#bdb39a"), Vector3(q.x, H(q.x, q.y) + 2.0, q.y), rot)
	var lintel := box(Vector3(7.2, 0.6, 0.7), Color("#6b5234"), Vector3(c.x, y + 4.4, c.y), world)
	lintel.rotation.y = rot
	var sign_b := box(Vector3(2.0, 0.8, 0.12), Color("#7a6040"), Vector3(c.x, y + 3.6, c.y), world)
	sign_b.rotation.y = rot

func decorate_camp(cp: Dictionary, r: RandomNumberGenerator, old: Color) -> void:
	var c: Vector2 = cp.pos
	var to_road := (Vector2.ZERO - c).normalized()      # la entrada mira hacia el centro del reino
	var open_a := atan2(to_road.y, to_road.x)
	match int(cp.tier):
		0:
			# animales: cercos rústicos de pastoreo, sueltos, para esconderse y hacer pasillos
			for k in 3:
				var a := r.randf() * TAU
				var d := r.randf_range(12, 19)
				var q: Vector2 = c + Vector2(cos(a), sin(a)) * d
				if in_city(q.x, q.y, 12.0) or terrain.road_dist(q) < 4.0 or terrain.height(q.x, q.y) < 1.5:
					continue
				var t := Vector2(cos(a + PI / 2), sin(a + PI / 2))
				fence_run(q - t * 6, q + t * 6, "rustico", r)
				if k == 0:
					fence_run(q + t * 6, q + t * 6 + Vector2(-t.y, t.x) * 5, "rustico", r)
		1, 2:
			# bandidos u orcos: empalizada en arco con una entrada; fogata y carpas adentro
			var style := "empalizada" if int(cp.tier) == 1 else "orca"
			var R := 15.0
			var segs := 14
			for k in segs:
				var a0 := open_a + 0.45 + (TAU - 0.9) * k / segs
				var a1 := open_a + 0.45 + (TAU - 0.9) * (k + 1) / segs
				var p0 := c + Vector2(cos(a0), sin(a0)) * R
				var p1 := c + Vector2(cos(a1), sin(a1)) * R
				if terrain.height(p0.x, p0.y) < 1.0 or terrain.road_dist(p0) < 3.0:
					continue
				fence_run(p0, p1, style, r)
			var gate := c + to_road * R
			if int(cp.tier) == 1:
				stone_gate(gate, atan2(to_road.x, to_road.y) + PI / 2)
			else:
				for sgn in [-1.0, 1.0]:
					var q: Vector2 = gate + Vector2(-to_road.y, to_road.x) * 2.4 * sgn
					cyl(0.25, 0.3, 5.0, Color("#3e3326"), Vector3(q.x, H(q.x, q.y) + 2.5, q.y), world, 6)
					box(Vector3(0.7, 0.6, 0.6), Color("#d9d2bf"), Vector3(q.x, H(q.x, q.y) + 5.2, q.y), world)
			var fire := c + Vector2(r.randf_range(-2, 2), r.randf_range(-2, 2))
			cyl(0.9, 1.1, 0.3, Color("#5a5048"), Vector3(fire.x, H(fire.x, fire.y) + 0.15, fire.y), world, 8)
			var fl := sphere(0.55, Color("#ff9b50"), Vector3(fire.x, H(fire.x, fire.y) + 0.6, fire.y), world)
			fl.material_override.emission_enabled = true
			fl.material_override.emission = Color("#ff7a30")
			fl.material_override.emission_energy_multiplier = 1.6
			for k in 3:
				var a := open_a + PI + (k - 1) * 0.9
				var q := c + Vector2(cos(a), sin(a)) * 9.5
				var tc := Color("#a8875c") if int(cp.tier) == 1 else Color("#5b4a38")
				cyl(0.05, 2.2, 2.6, tc, Vector3(q.x, H(q.x, q.y) + 1.3, q.y), world, 4).rotation.y = r.randf()
				add_collider(q, Vector2(1.5, 1.5), 0.0)
		3:
			# cumbres: ruinas antiguas de piedra
			for k in 3:
				var a := r.randf() * TAU
				var q: Vector2 = c + Vector2(cos(a), sin(a)) * r.randf_range(13, 20)
				var t := Vector2(cos(a + PI / 2), sin(a + PI / 2))
				wall_run(q - t * 7, q + t * 7, 1.4, 3.4, old, 0.25, r)

# Sapientia, ciudad del conocimiento: arenisca, techos de bronce, cúpulas de cristal,
# una academia, un observatorio, la torre del reloj, talleres y un engranaje gigante en la plaza
func build_sapientia() -> void:
	var C: Vector2 = CITIES.sapientia.pos
	var R: float = CITIES.sapientia.r
	var y0 := H(C.x, C.y)
	var sand := Color("#e0caa0")
	var sand2 := Color("#c9ad7e")
	var bronze := Color("#b8733a")
	var glass := Color("#5fb3b0")
	var exits := []
	for road in Terrain.ROADS:
		for i in road.size():
			if road[i].distance_to(C) < R + 60.0:
				var nb: Vector2 = road[i]
				exits.append(atan2(nb.x - C.x, nb.y - C.y))
	exits.append(atan2(-150.0 - C.x, 25.0 - C.y))     # hacia Lumen
	exits.append(atan2(-280.0 - C.x, 50.0 - C.y))     # hacia el cañadón
	# muralla baja con almenas de bronce
	var segs := 56
	for k in segs:
		var a := TAU * k / segs
		var gap := false
		for e in exits:
			if abs(angle_difference(a, e)) < 0.2:
				gap = true
		if gap:
			continue
		var px := C.x + sin(a) * R
		var pz := C.y + cos(a) * R
		solid_box(Vector3(5.6, 4.0, 1.4), sand, Vector3(px, y0 + 2.0, pz), a)
		if k % 7 == 0:
			cyl(1.6, 1.8, 6.5, sand2, Vector3(px, y0 + 3.25, pz), world, 8)
			sphere(1.7, bronze, Vector3(px, y0 + 6.8, pz), world)
			add_collider(Vector2(px, pz), Vector2(1.7, 1.7), 0.0)
	# academia: edificio central con cúpula de cristal
	var ac := C + Vector2(0, -16)
	solid_box(Vector3(22, 9, 14), sand, Vector3(ac.x, y0 + 4.5, ac.y), 0.0)
	box(Vector3(23, 0.8, 15), bronze, Vector3(ac.x, y0 + 9.2, ac.y), world)
	cyl(5.5, 5.8, 4.0, sand2, Vector3(ac.x, y0 + 11.5, ac.y), world, 16)
	var dome := sphere(5.6, glass, Vector3(ac.x, y0 + 13.5, ac.y), world)
	dome.material_override.metallic = 0.3
	dome.material_override.roughness = 0.25
	cyl(0.2, 0.2, 3.0, bronze, Vector3(ac.x, y0 + 20.5, ac.y), world, 6)
	for col in [-8, -4, 0, 4, 8]:
		cyl(0.55, 0.6, 8.0, Color("#f0e2c4"), Vector3(ac.x + col, y0 + 4.0, ac.y + 7.6), world, 10)
	# observatorio: torre alta con cúpula y telescopio
	var ob := C + Vector2(-26, 8)
	cyl(3.2, 3.8, 18.0, sand2, Vector3(ob.x, y0 + 9.0, ob.y), world, 12)
	add_collider(ob, Vector2(3.6, 3.6), 0.0)
	sphere(3.4, bronze, Vector3(ob.x, y0 + 18.5, ob.y), world)
	var tel := cyl(0.45, 0.7, 5.0, Color("#3b3b46"), Vector3(ob.x + 1.6, y0 + 20.5, ob.y), world, 8)
	tel.rotation.z = -0.9
	# torre del reloj
	var tw := C + Vector2(24, 4)
	solid_box(Vector3(5, 20, 5), sand, Vector3(tw.x, y0 + 10, tw.y), 0.0)
	cyl(0.01, 4.0, 4.0, bronze, Vector3(tw.x, y0 + 22, tw.y), world, 4).rotation.y = PI / 4
	var face := cyl(1.8, 1.8, 0.3, Color("#f7f1e3"), Vector3(tw.x, y0 + 16, tw.y + 2.6), world, 20)
	face.rotation.x = PI / 2
	var hand := Node3D.new()
	hand.name = "AgujaReloj"
	hand.position = Vector3(tw.x, y0 + 16, tw.y + 2.8)
	world.add_child(hand)
	box(Vector3(0.18, 1.5, 0.08), Color("#2b2b2b"), Vector3(0, 0.6, 0), hand)
	# engranaje gigante en la plaza (gira)
	var gear := Node3D.new()
	gear.name = "Engranaje"
	gear.position = Vector3(C.x, y0 + 4.5, C.y + 6)
	world.add_child(gear)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 2.4
	tm.outer_radius = 3.2
	tm.rings = 24
	ring.mesh = tm
	ring.material_override = mat(bronze)
	ring.rotation.x = PI / 2
	gear.add_child(ring)
	for k in 12:
		var tooth := box(Vector3(0.7, 0.9, 0.6), bronze, Vector3(sin(TAU * k / 12) * 3.5, cos(TAU * k / 12) * 3.5, 0), gear)
		tooth.rotation.z = -TAU * k / 12
	box(Vector3(0.8, 4.5, 0.8), sand2, Vector3(C.x, y0 + 2.2, C.y + 6), world)
	add_collider(C + Vector2(0, 6), Vector2(0.8, 0.8), 0.0)
	# talleres con chimenea y casas con techo de bronce
	var r := RandomNumberGenerator.new()
	r.seed = 1234
	var placed := 0
	var tries := 0
	while placed < 13 and tries < 400:
		tries += 1
		var a := r.randf() * TAU
		var d := r.randf_range(14.0, R - 7.0)
		var x := C.x + sin(a) * d
		var z := C.y + cos(a) * d
		if terrain.road_dist(Vector2(x, z)) < 5.5 or blocked(x, z, 4.5):
			continue
		if Vector2(x, z).distance_to(CITIES.sapientia.spawn) < 9.0 or Vector2(x, z).distance_to(C + Vector2(0, 6)) < 9.0:
			continue
		var w := r.randf_range(4.5, 7.0)
		var hgt := r.randf_range(3.5, 6.0)
		solid_box(Vector3(w, hgt, w * 0.85), sand.darkened(r.randf() * 0.1), Vector3(x, y0 + hgt / 2, z), a)
		if placed % 3 == 0:
			cyl(0.5, 0.6, 3.5, Color("#5a4a3a"), Vector3(x + 1.2, y0 + hgt + 1.5, z), world, 6)
			box(Vector3(w + 0.2, 0.5, w * 0.85 + 0.2), bronze, Vector3(x, y0 + hgt + 0.2, z), world).rotation.y = a
		else:
			cyl(0.01, w * 0.75, 2.0, bronze.lightened(r.randf() * 0.15), Vector3(x, y0 + hgt + 1.0, z), world, 4).rotation.y = a + PI / 4
		placed += 1
	var safe := MeshInstance3D.new()
	safe.mesh = ring_mesh
	safe.material_override = ind_mat(Color("#58a6ff"), 0.35)
	safe.material_override.no_depth_test = false
	safe.scale = Vector3(R + 2.5, 0.05, R + 2.5)
	safe.position = Vector3(C.x, y0 + 0.08, C.y)
	world.add_child(safe)

# árboles y rocas con MultiMesh: miles de copias en pocas llamadas de dibujo
const SPECIES = ["pino", "redondo", "abedul", "otono"]
const TREE_HP = [35.0, 180.0, INF]

func tree_mesh(kind: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.radial_segments = 6
	if kind == "abedul":
		trunk.top_radius = 0.14
		trunk.bottom_radius = 0.2
		trunk.height = 3.0
		append_mesh(st, trunk, Transform3D(Basis(), Vector3(0, 1.5, 0)), Color("#e9e4d8"))
	else:
		trunk.top_radius = 0.22
		trunk.bottom_radius = 0.32
		trunk.height = 1.6
		append_mesh(st, trunk, Transform3D(Basis(), Vector3(0, 0.8, 0)), Color("#6b4a2b"))
	match kind:
		"pino":
			for k in 3:
				var c := CylinderMesh.new()
				c.top_radius = 0.01
				c.bottom_radius = 1.7 - k * 0.4
				c.height = 2.2
				c.radial_segments = 7
				append_mesh(st, c, Transform3D(Basis(), Vector3(0, 2.2 + k * 1.2, 0)), Color("#2f6b3f").lightened(k * 0.06))
		"abedul":
			var sp := SphereMesh.new()
			sp.radius = 1.0
			sp.height = 2.6
			sp.radial_segments = 8
			sp.rings = 5
			append_mesh(st, sp, Transform3D(Basis(), Vector3(0, 3.6, 0)), Color("#9cc64a"))
			append_mesh(st, sp, Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(0.5, 2.9, 0.2)), Color("#b3d45a"))
		_:
			var top := Color("#4f8f3a") if kind == "redondo" else Color("#d9822b")
			var top2 := Color("#5fa043") if kind == "redondo" else Color("#e6a33a")
			var sp := SphereMesh.new()
			sp.radius = 1.6
			sp.height = 2.8
			sp.radial_segments = 8
			sp.rings = 5
			append_mesh(st, sp, Transform3D(Basis(), Vector3(0, 2.9, 0)), top)
			append_mesh(st, sp, Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(0.7, 3.7, 0.3)), top2)
			append_mesh(st, sp, Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(-0.8, 3.3, -0.4)), top.darkened(0.08))
	st.generate_normals()
	return st.commit()

func append_mesh(st: SurfaceTool, m: PrimitiveMesh, xf: Transform3D, c: Color) -> void:
	var arr := m.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for i in idx:
		st.set_color(c)
		st.add_vertex(xf * verts[i])

func pick_species(x: float, z: float, r: RandomNumberGenerator) -> int:
	var q := r.randf()
	if z < -150.0:
		return 0 if q < 0.7 else 2
	if x > 150.0:
		return 0 if q < 0.45 else (1 if q < 0.8 else 3)
	if z > 150.0:
		return 1 if q < 0.6 else 3
	return 1 if q < 0.5 else (2 if q < 0.75 else (3 if q < 0.9 else 0))

func tree_xform(t: TreeObj) -> Transform3D:
	var s2: float = t.sc * t.grow
	return Transform3D(Basis(Vector3.UP, t.rot).scaled(Vector3.ONE * max(0.001, s2)), Vector3(t.x, terrain.height(t.x, t.z) - 0.1, t.z))

func add_tree(x: float, z: float, sp: int, size: int, sc: float, rot: float) -> void:
	var t := TreeObj.new()
	t.x = x
	t.z = z
	t.sp = sp
	t.size = size
	t.sc = sc
	t.rot = rot
	t.max_hp = TREE_HP[size] * (0.7 + sc * 0.3)
	t.hp = t.max_hp
	t.id = trees.size()
	trees.append(t)
	var k := Vector2i(int(floor(x / 16.0)), int(floor(z / 16.0)))
	if not tree_grid.has(k):
		tree_grid[k] = []
	tree_grid[k].append(t)
	if size == 2:
		add_collider(Vector2(x, z), Vector2(0.3, 0.3) * sc, 0.0)    # los grandes bloquean el paso

func build_vegetation() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	var rocks := []
	# árboles antiguos gigantes: puntos de referencia del mapa
	for g in [[Vector2(-150, -55), 1], [Vector2(215, -5), 3], [Vector2(70, 300), 1], [Vector2(-330, -200), 0]]:
		add_tree(g[0].x, g[0].y, g[1], 2, 4.6, r.randf() * TAU)
	var step := 6.0
	var x := -Terrain.HALF + 10.0
	while x < Terrain.HALF - 10.0:
		var z := -Terrain.HALF + 10.0
		while z < Terrain.HALF - 10.0:
			var px := x + r.randf_range(-2.5, 2.5)
			var pz := z + r.randf_range(-2.5, 2.5)
			var dens: float = 0.0 if blocked(px, pz, 2.5) else terrain.tree_density(px, pz)
			if r.randf() < dens:
				var q := r.randf()
				var size := 0 if q < 0.4 else (1 if q < 0.92 or dens < 0.25 else 2)
				var sc: float = [r.randf_range(0.45, 0.7), r.randf_range(0.85, 1.3), r.randf_range(1.9, 2.6)][size]
				add_tree(px, pz, pick_species(px, pz, r), size, sc, r.randf() * TAU)
			elif r.randf() < 0.012 and terrain.height(px, pz) > 1.0 and terrain.road_dist(Vector2(px, pz)) > 6.0 and not in_city(px, pz, 10.0):
				var sc := r.randf_range(0.5, 1.8) * (2.0 if px < -250.0 else 1.0)
				rocks.append(Transform3D(Basis(Vector3(r.randf(), 1, r.randf()).normalized(), r.randf() * TAU).scaled(Vector3(sc, sc * 0.7, sc)), Vector3(px, terrain.height(px, pz), pz)))
			z += step
		x += step
	veg_mat = StandardMaterial3D.new()
	veg_mat.vertex_color_use_as_albedo = true
	veg_mat.roughness = 0.9
	var counts := [0, 0, 0, 0]
	for t in trees:
		t.idx = counts[t.sp]
		counts[t.sp] += 1
	for k in SPECIES.size():
		tree_meshes.append(tree_mesh(SPECIES[k]))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tree_meshes[k]
		mm.instance_count = counts[k]
		tree_mms.append(mm)
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = veg_mat
		world.add_child(mi)
	for t in trees:
		tree_mms[t.sp].set_instance_transform(t.idx, tree_xform(t))
	# tocones (aparecen cuando un árbol cae)
	var stump := CylinderMesh.new()
	stump.top_radius = 0.28
	stump.bottom_radius = 0.36
	stump.height = 0.5
	stump.radial_segments = 7
	stump_mm = MultiMesh.new()
	stump_mm.transform_format = MultiMesh.TRANSFORM_3D
	stump_mm.mesh = stump
	stump_mm.instance_count = trees.size()
	for t in trees:
		stump_mm.set_instance_transform(t.id, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(t.x, -50, t.z)))
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = stump_mm
	smi.material_override = mat(Color("#8a6440"))
	world.add_child(smi)
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 1.6
	rock.radial_segments = 6
	rock.rings = 3
	add_multimesh(rock, rocks, mat(Color("#8d8a84")))
	build_ground_cover()

func add_multimesh(mesh: Mesh, xforms: Array, m: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	world.add_child(mi)
	return mi

# ----------------------------------------------------------------- pasto bajo y flores (solo se dibujan cerca)
func blades_mesh(n: int, hmin: float, hmax: float, spread: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rr := RandomNumberGenerator.new()
	rr.seed = 77
	for k in n:
		var b := Vector3(rr.randf_range(-spread, spread), 0, rr.randf_range(-spread, spread))
		var a := rr.randf() * TAU
		var side := Vector3(cos(a), 0, sin(a)) * 0.07
		var tip := b + Vector3(rr.randf_range(-0.12, 0.12), rr.randf_range(hmin, hmax), rr.randf_range(-0.12, 0.12))
		st.set_color(Color(0.85, 0.85, 0.85))
		st.add_vertex(b - side)
		st.set_color(Color(0.85, 0.85, 0.85))
		st.add_vertex(b + side)
		st.set_color(Color(1.2, 1.2, 1.1))
		st.add_vertex(tip)
	st.generate_normals()
	return st.commit()

func flower_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.015
	stem.bottom_radius = 0.02
	stem.height = 0.4
	stem.radial_segments = 4
	append_mesh(st, stem, Transform3D(Basis(), Vector3(0, 0.2, 0)), Color(0.35, 0.6, 0.3))
	var head := SphereMesh.new()
	head.radius = 0.09
	head.height = 0.12
	head.radial_segments = 6
	head.rings = 3
	append_mesh(st, head, Transform3D(Basis(), Vector3(0, 0.42, 0)), Color(1, 1, 1))
	st.generate_normals()
	return st.commit()

func build_ground_cover() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 909
	var blades := blades_mesh(6, 0.25, 0.55, 0.35)
	var flowers := flower_mesh()
	var cover_mat := StandardMaterial3D.new()
	cover_mat.vertex_color_use_as_albedo = true
	cover_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cover_mat.roughness = 0.95
	var petals = [Color("#ffffff"), Color("#ffe066"), Color("#c792ea"), Color("#7fb7ff"), Color("#ff8fa3")]
	var CH := 64.0
	var n_side := int(Terrain.SIZE / CH)
	for cj in n_side:
		for ci in n_side:
			var gx := []
			var gc := []
			var fx := []
			var fc := []
			for k in 900:
				var x := -Terrain.HALF + ci * CH + r.randf() * CH
				var z := -Terrain.HALF + cj * CH + r.randf() * CH
				var h: float = terrain.height(x, z)
				if h < 0.9 or h > 40.0:
					continue
				var p := Vector2(x, z)
				if terrain.road_dist(p) < 3.5 or in_city(x, z, 2.0) or blocked(x, z, 0.4):
					continue
				var i := int((x + Terrain.HALF) / Terrain.RES)
				var j := int((z + Terrain.HALF) / Terrain.RES)
				if terrain.slope_at(i, j) > 0.6:
					continue
				var base: Color = terrain.colors[j * Terrain.N + i]
				gx.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.7, 1.4)), Vector3(x, h - 0.03, z)))
				gc.append(base.lightened(0.08))
				# flores en los prados (no en el cañadón ni en el bosque cerrado)
				if k % 14 == 0 and x > -200.0 and r.randf() < 0.6:
					var fx2 := x + r.randf_range(-0.6, 0.6)
					fx.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.8, 1.3)), Vector3(fx2, terrain.height(fx2, z), z)))
					fc.append(petals[r.randi() % petals.size()])
			for spec in [[blades, gx, gc], [flowers, fx, fc]]:
				if spec[1].is_empty():
					continue
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.use_colors = true
				mm.mesh = spec[0]
				mm.instance_count = spec[1].size()
				for q in spec[1].size():
					mm.set_instance_transform(q, spec[1][q])
					mm.set_instance_color(q, spec[2][q])
				var mi := MultiMeshInstance3D.new()
				mi.multimesh = mm
				mi.material_override = cover_mat
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.visibility_range_end = 110.0
				world.add_child(mi)

# ----------------------------------------------------------------- árboles que se rompen según tu poder
func damage_trees(x: float, z: float, r: float, dmg: float, once = null, blast := false) -> void:
	if dmg <= 0:
		return
	damage_ores(x, z, r, dmg, once, blast)
	for gx in range(int(floor((x - r - 3.0) / 16.0)), int(floor((x + r + 3.0) / 16.0)) + 1):
		for gz in range(int(floor((z - r - 3.0) / 16.0)), int(floor((z + r + 3.0) / 16.0)) + 1):
			var k := Vector2i(gx, gz)
			if not tree_grid.has(k):
				continue
			for t in tree_grid[k]:
				if not t.alive or t.grow < 1.0:
					continue
				if Vector2(t.x - x, t.z - z).length() > r + 0.5 * t.sc:
					continue
				if once != null:
					if once.has(t):
						continue
					once[t] = true
				if t.size == 2:
					add_text(Vector3(t.x, 2.5, t.z), "Demasiado grande", Color("#c9b48a"), 12)
					continue
				t.hp -= dmg
				add_text(Vector3(t.x, 2.0 + t.sc * 2.0, t.z), str(int(dmg)), Color("#d7b98a"), 13)
				if t.hp <= 0:
					fell_tree(t, x, z)

func fell_tree(t: TreeObj, fx: float, fz: float) -> void:
	t.alive = false
	t.regrow = 120.0 if t.size == 0 else 300.0     # chicos: 2 min, medianos: 5 min
	regrowing.append(t)
	var xf := tree_xform(t)
	tree_mms[t.sp].set_instance_transform(t.idx, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(t.x, -50, t.z)))
	stump_mm.set_instance_transform(t.id, Transform3D(Basis().scaled(Vector3.ONE * t.sc), Vector3(t.x, terrain.height(t.x, t.z) + 0.1, t.z)))
	var node := MeshInstance3D.new()
	node.mesh = tree_meshes[t.sp]
	node.material_override = veg_mat
	world.add_child(node)
	node.transform = xf
	var away := Vector2(t.x - fx, t.z - fz)
	if away.length() < 0.1:
		away = Vector2(P.fx, P.fz)
	away = away.normalized()
	var axis := Vector3(away.y, 0, -away.x).normalized()      # cae hacia el lado contrario al golpe
	falling.append({"node": node, "t": 0.0, "axis": axis, "basis": xf.basis, "pos": xf.origin})
	var got := 1 if t.size == 0 else 3
	wood += got
	add_text(Vector3(t.x, 3.0, t.z), "+%d madera" % got, Color("#e0b46a"), 15)

func tree_at(x: float, z: float):
	var k := Vector2i(int(floor(x / 16.0)), int(floor(z / 16.0)))
	if not tree_grid.has(k):
		return null
	for t in tree_grid[k]:
		if t.alive and Vector2(t.x - x, t.z - z).length() < 0.35 * t.sc + 0.25:
			return t
	return null

# ----------------------------------------------------------------- lugares de interés (que el mundo no se sienta vacío)
const SHRINE_NAMES = ["Alba", "Vigía", "Rocío", "Brasa", "Eco", "Faro", "Cenit", "Bruma", "Ceniza", "Escarcha", "Umbral", "Ocaso"]

func find_site(p: Vector2, r: float) -> Vector2:
	if site_ok(p.x, p.y, r):
		return p
	for ring in range(1, 30):
		for k in 16:
			var a := TAU * k / 16.0
			var q := p + Vector2(cos(a), sin(a)) * ring * 4.0
			if site_ok(q.x, q.y, r):
				return q
	return Vector2(INF, INF)

func glow_mat(c: Color, e := 1.2) -> StandardMaterial3D:
	var m := mat(c)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m

func build_points_of_interest() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 2026
	# santuarios: un pedestal con luz; de lejos se ve un haz naranja hasta que lo descubrís
	var spots = [Vector2(95, -30), Vector2(-150, -70), Vector2(-120, 170), Vector2(130, 175), Vector2(260, -60), Vector2(-330, 10),
		Vector2(40, -200), Vector2(-260, 230), Vector2(300, 230), Vector2(-200, -280), Vector2(230, -300), Vector2(420, -40)]
	for i in spots.size():
		var q: Vector2 = find_site(spots[i], 4.0)
		if q.x == INF:
			continue
		var y := H(q.x, q.y)
		solid_box(Vector3(5, 0.6, 5), Color("#d8d0bd"), Vector3(q.x, y + 0.2, q.y), PI / 4)
		for k in 4:
			var a := PI / 4 + k * PI / 2
			cyl(0.35, 0.45, 2.2, Color("#cfc7b5"), Vector3(q.x + cos(a) * 2.6, y + 1.1, q.y + sin(a) * 2.6), world, 6)
		cyl(0.7, 0.9, 2.4, Color("#bdb39f"), Vector3(q.x, y + 1.5, q.y), world, 8)
		var orb := sphere(0.6, Color("#ff9b50"), Vector3(q.x, y + 3.2, q.y), world)
		orb.material_override = glow_mat(Color("#ff9b50"), 1.0)
		var beam := cyl(0.8, 0.8, 70.0, Color("#ffb070"), Vector3(q.x, y + 38.0, q.y), world, 10)
		beam.material_override = ind_mat(Color("#ffa05a"), 0.4)
		beam.material_override.no_depth_test = false
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shrines.append({"name": "Santuario " + SHRINE_NAMES[i], "x": q.x, "z": q.y, "found": false, "orb": orb, "beam": beam})
	# posadas en los caminos, con corral y caballos
	var inns = [[Vector2(-50, -150), "Posada del Paso Norte"], [Vector2(150, -45), "Posada del Río"], [Vector2(28, 190), "Posada de los Campos"]]
	for inn in inns:
		var q: Vector2 = find_site(inn[0] + Vector2(16, 10), 9.0)
		if q.x == INF:
			continue
		var y := H(q.x, q.y)
		var a := r.randf() * TAU
		solid_box(Vector3(12, 5, 8), Color("#efe4cc"), Vector3(q.x, y + 2.5, q.y), a)
		var roof := cyl(0.01, 8.5, 3.5, Color("#9b4d2e"), Vector3(q.x, y + 6.7, q.y), world, 4)
		roof.rotation.y = a + PI / 4
		roof.scale = Vector3(1.0, 1.0, 0.7)
		for k in 2:
			var bx := q + Vector2(cos(a), -sin(a)) * (k * 8.0 - 4.0) + Vector2(sin(a), cos(a)) * 4.4
			box(Vector3(0.9, 1.4, 0.1), Color("#5b3a1e"), Vector3(bx.x, y + 1.0, bx.y), world).rotation.y = a
		var cor := q + Vector2(sin(a), cos(a)) * 13.0
		var fx := Vector2(cos(a), -sin(a))
		var fz := Vector2(sin(a), cos(a))
		var c4 = [cor - fx * 7 - fz * 4, cor + fx * 7 - fz * 4, cor + fx * 7 + fz * 4, cor - fx * 7 + fz * 4, cor - fx * 7 - fz * 4]
		for k in 4:
			if k == 0:
				fence_run(c4[0], c4[0] + fx * 4.0, "rustico", r)
				fence_run(c4[1] - fx * 4.0, c4[1], "rustico", r)
			else:
				fence_run(c4[k], c4[k + 1], "rustico", r)
		for k in 2:
			var hp := cor + fx * (k * 5.0 - 2.5)
			var horse := Node3D.new()
			horse.position = Vector3(hp.x, H(hp.x, hp.y), hp.y)
			horse.rotation.y = r.randf() * TAU
			world.add_child(horse)
			var hc: Color = [Color("#7a4a2a"), Color("#e8e0d0"), Color("#2e2620")][r.randi() % 3]
			box(Vector3(0.8, 0.9, 2.2), hc, Vector3(0, 1.5, 0), horse)
			var neck := box(Vector3(0.45, 1.2, 0.5), hc, Vector3(0, 2.2, 1.0), horse)
			neck.rotation.x = 0.5
			box(Vector3(0.4, 0.45, 0.8), hc.darkened(0.1), Vector3(0, 2.75, 1.45), horse)
			for lx in [-0.3, 0.3]:
				for lz in [-0.85, 0.85]:
					box(Vector3(0.18, 1.1, 0.18), hc.darkened(0.25), Vector3(lx, 0.55, lz), horse)
		pois.append({"name": inn[1], "x": q.x, "z": q.y, "r": 30.0})
	# puentes donde los caminos cruzan el río
	for cxp in Terrain.CROSSINGS:
		var best: Vector2 = cxp
		var dir := Vector2.ZERO
		for road in Terrain.ROADS:
			for i in road.size() - 1:
				if Geometry2D.get_closest_point_to_segment(best, road[i], road[i + 1]).distance_to(best) < 0.5:
					dir = (road[i + 1] - road[i]).normalized()
		if dir == Vector2.ZERO:
			continue
		var rot := atan2(dir.x, dir.y)
		# largo: hasta que las dos orillas queden por encima del agua
		var hl := 8.0
		while hl < 26.0 and (terrain.height(best.x + dir.x * hl, best.y + dir.y * hl) < 1.0 or terrain.height(best.x - dir.x * hl, best.y - dir.y * hl) < 1.0):
			hl += 1.0
		var y0: float = max(terrain.height(best.x + dir.x * hl, best.y + dir.y * hl), terrain.height(best.x - dir.x * hl, best.y - dir.y * hl))
		y0 = max(y0, 1.2)
		var deck := box(Vector3(5.0, 0.5, hl * 2.0 + 1.0), Color("#8a6a45"), Vector3(best.x, y0, best.y), world)
		deck.rotation.y = rot
		bridges.append({"c": best, "dir": dir, "hl": hl + 0.5, "y": y0})
		for sgn in [-1.0, 1.0]:
			var side: Vector2 = best + Vector2(dir.y, -dir.x) * 2.4 * sgn
			var rail: MeshInstance3D = box(Vector3(0.2, 0.9, hl * 2.0), Color("#6b4f33"), Vector3(side.x, y0 + 0.7, side.y), world)
			rail.rotation.y = rot
			var e := -hl + 0.5
			while e <= hl:
				var pp: Vector2 = side + dir * e
				cyl(0.18, 0.18, y0 + 3.5, Color("#5b3a1e"), Vector3(pp.x, (y0 + 1.2 - 2.3) / 2.0, pp.y), world, 6)
				e += 5.0
	# carteles en los caminos con hacia dónde va cada uno
	var signs = [[Vector2(-60, 12), "← Sapientia   Lumen →"], [Vector2(-14, -60), "↑ Cordillera   Lumen ↓"], [Vector2(65, 6), "← Lumen   Bosque del Este →"], [Vector2(4, 70), "↑ Lumen   Campos del Sur ↓"],
		[Vector2(-300, 52), "← Cañadón   Sapientia →"]]
	for sg in signs:
		var q: Vector2 = sg[0]
		var off := Vector2(4.0, 4.0)
		q = free_spot(q + off, 0.8)
		var y := H(q.x, q.y)
		cyl(0.12, 0.14, 2.6, Color("#5b3a1e"), Vector3(q.x, y + 1.3, q.y), world, 6)
		var board := box(Vector3(2.6, 0.5, 0.1), Color("#a07a4e"), Vector3(q.x, y + 2.3, q.y), world)
		var lb := Label3D.new()
		lb.text = sg[1]
		lb.font_size = 40
		lb.pixel_size = 0.01
		lb.modulate = Color("#2b1d10")
		lb.outline_size = 0
		lb.position = Vector3(q.x, y + 2.3, q.y + 0.07)
		world.add_child(lb)
		var lb2: Label3D = lb.duplicate()
		lb2.position = Vector3(q.x, y + 2.3, q.y - 0.07)
		lb2.rotation.y = PI
		world.add_child(lb2)
	# arcos de piedra y columnas en el campo (puntos de referencia)
	for i in 7:
		var q := find_site(Vector2(r.randf_range(-400, 400), r.randf_range(-260, 400)), 6.0)
		if q.x == INF:
			continue
		var a := r.randf() * TAU
		var dx := Vector2(cos(a), -sin(a))
		var stone := Color("#b8ab92").darkened(r.randf() * 0.15)
		var hh := r.randf_range(8.0, 13.0)
		for sgn in [-1.0, 1.0]:
			var pc: Vector2 = q + dx * 4.5 * sgn
			solid_box(Vector3(2.4, hh, 2.4), stone, Vector3(pc.x, H(pc.x, pc.y) + hh / 2.0 - 0.5, pc.y), a)
		var top := box(Vector3(12.0, 2.0, 2.6), stone.lightened(0.05), Vector3(q.x, H(q.x, q.y) + hh + 0.3, q.y), world)
		top.rotation.y = a
		var moss := box(Vector3(11.0, 0.4, 2.7), Color("#6f8f48"), Vector3(q.x, H(q.x, q.y) + hh + 1.45, q.y), world)
		moss.rotation.y = a
	# fogatas de viajeros con troncos para sentarse y una olla
	for i in 6:
		var road: Array = Terrain.ROADS[i % Terrain.ROADS.size()]
		var base: Vector2 = road[min(road.size() - 1, 1 + i / 4)].lerp(road[min(road.size() - 1, 2 + i / 4)], 0.5)
		var q: Vector2 = find_site(base + Vector2(9, -7), 3.0)
		if q.x == INF:
			continue
		var y := H(q.x, q.y)
		for k in 7:
			var a := TAU * k / 7.0
			sphere(0.25, Color("#7d776c"), Vector3(q.x + cos(a) * 0.9, y + 0.1, q.y + sin(a) * 0.9), world)
		var fl := sphere(0.45, Color("#ff9b50"), Vector3(q.x, y + 0.4, q.y), world)
		fl.material_override = glow_mat(Color("#ff8a3a"), 1.8)
		cyl(0.45, 0.35, 0.5, Color("#2f2f33"), Vector3(q.x, y + 0.9, q.y), world, 8)
		for sgn in [-1.0, 1.0]:
			var lg: MeshInstance3D = cyl(0.25, 0.25, 2.0, Color("#6b4f33"), Vector3(q.x + 2.2 * sgn, y + 0.25, q.y), world, 6)
			lg.rotation.x = PI / 2
		pois.append({"name": "Fogata (se puede cocinar)", "x": q.x, "z": q.y, "r": 10.0})
	# cofres: escondidos por el mapa, y uno en cada campamento que se abre al vaciarlo
	for i in camps.size():
		var cp: Dictionary = camps[i]
		var back: Vector2 = cp.pos - (Vector2.ZERO - cp.pos).normalized() * 6.0
		var q: Vector2 = free_spot(back, 0.9)
		add_chest(q, int(cp.tier), i)
	var placed := 0
	var tries := 0
	while placed < 18 and tries < 2000:
		tries += 1
		var q := Vector2(r.randf_range(-460, 460), r.randf_range(-460, 460))
		if not site_ok(q.x, q.y, 2.0):
			continue
		add_chest(q, max(0, zone_at(q.x, q.y).tier), -1)
		placed += 1
	# bandadas de pájaros que dan vueltas
	for i in 12:
		var fl := Node3D.new()
		var cx := r.randf_range(-420, 420)
		var cz := r.randf_range(-420, 420)
		fl.position = Vector3(cx, H(cx, cz) + r.randf_range(18, 32), cz)
		world.add_child(fl)
		var rad := r.randf_range(12, 26)
		for k in 7:
			var b := Node3D.new()
			b.position = Vector3(rad + r.randf_range(-3, 3), r.randf_range(-2, 2), r.randf_range(-3, 3))
			fl.add_child(b)
			for sgn in [-1.0, 1.0]:
				var w: MeshInstance3D = box(Vector3(0.7, 0.05, 0.25), Color("#2e2e33"), Vector3(0.3 * sgn, 0, 0), b)
				w.rotation.z = 0.35 * sgn
				w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			b.rotation.y = PI / 2
		flocks.append({"node": fl, "spd": r.randf_range(0.25, 0.5) * (1.0 if r.randf() < 0.5 else -1.0)})
	# viajeros que van y vienen por los caminos
	var who = [["Mercader ambulante", Color("#8a5a3a")], ["Peregrina", Color("#d9d2bf")], ["Cartógrafo", Color("#3d5f9e")], ["Cazadora", Color("#4f6b3a")]]
	for i in who.size():
		var road: Array = Terrain.ROADS[i % Terrain.ROADS.size()]
		var nd := Node3D.new()
		world.add_child(nd)
		cyl(0.38, 0.45, 1.3, who[i][1], Vector3(0, 0.85, 0), nd, 8)
		sphere(0.3, Color("#d9a77c"), Vector3(0, 1.75, 0), nd)
		cyl(0.01, 0.45, 0.35, who[i][1].darkened(0.3), Vector3(0, 2.1, 0), nd, 8)
		if i == 0:
			box(Vector3(0.8, 0.9, 0.5), Color("#6b4f33"), Vector3(0, 1.2, -0.45), nd)
		travelers.append({"name": who[i][0], "road": road, "seg": 1, "t": 0.2, "dir": 1, "node": nd, "x": 0.0, "z": 0.0})

func add_chest(q: Vector2, tier: int, camp: int) -> void:
	var y := H(q.x, q.y)
	var nd := Node3D.new()
	nd.position = Vector3(q.x, y, q.y)
	nd.rotation.y = randf() * TAU
	world.add_child(nd)
	var wood := Color("#7a5634") if tier < 2 else Color("#3e3326")
	box(Vector3(1.2, 0.7, 0.8), wood, Vector3(0, 0.35, 0), nd)
	var lid := Node3D.new()
	lid.position = Vector3(0, 0.7, -0.4)
	nd.add_child(lid)
	box(Vector3(1.24, 0.3, 0.84), wood.lightened(0.08), Vector3(0, 0.15, 0.4), lid)
	box(Vector3(1.26, 0.12, 0.2), Color("#d9b44a"), Vector3(0, 0.15, 0.4), lid)
	chests.append({"x": q.x, "z": q.y, "tier": tier, "camp": camp, "open": false, "lid": lid, "warned": 0.0})

func open_chest(c: Dictionary) -> void:
	c.open = true
	var loot := []
	var pool: Array = [["Pedernal", "Hierro", "Ámbar"], ["Hierro", "Plata", "Cuarzo solar"], ["Plata", "Cuarzo solar", "Luminita"], ["Mithril", "Luminita", "Cuarzo solar"]][clamp(c.tier, 0, 3)]
	for k in 2:
		var it: String = pool[randi() % pool.size()]
		var n := randi_range(1, 3)
		minerals[it] = int(minerals.get(it, 0)) + n
		loot.append("+%d %s" % [n, it])
	if randf() < 0.3:
		var fid: String = ["Rubí ígneo", "Obsidiana del vacío", "Jade de viento", "Perla de marea"][randi() % 4]
		if c.tier >= 2:
			minerals[fid] = int(minerals.get(fid, 0)) + 1
			loot.append("+1 " + fid)
	add_text(Vector3(c.x, 2.4, c.z), "Cofre: " + "  ".join(loot), Color("#f2cc60"), 14)
	flash_fx("ring", c.x, c.z, 1.6, Vector2(0, 1), Color("#f2cc60"))

func update_world_life(dt: float) -> void:
	# santuarios: descubrir al acercarse
	for sh in shrines:
		if not sh.found and d2(P.x, P.z, sh.x, sh.z) < 6.0:
			sh.found = true
			sh.orb.material_override = glow_mat(Color("#7ec8ff"), 1.2)
			sh.beam.visible = false
			toast("%s descubierto · viaje rápido desde el minimapa" % sh.name)
	# cofres
	for c in chests:
		if c.open:
			c.lid.rotation.x = lerp(c.lid.rotation.x, -1.9, 0.12)
			continue
		c.warned = max(0.0, c.warned - dt)
		if d2(P.x, P.z, c.x, c.z) < 2.0:
			var locked := false
			if c.camp >= 0:
				for m in mobs:
					if m.camp == c.camp and m.dead <= 0:
						locked = true
			if locked:
				if c.warned <= 0:
					add_text(Vector3(c.x, 2.0, c.z), "Cerrado: vaciá el campamento", Color("#c9d1d9"), 13)
					c.warned = 3.0
			else:
				open_chest(c)
	# viajeros
	for tv in travelers:
		var road: Array = tv.road
		var a: Vector2 = road[tv.seg - 1]
		var b: Vector2 = road[tv.seg]
		var L: float = max(1.0, a.distance_to(b))
		tv.t += dt * 2.0 / L * tv.dir
		if tv.t > 1.0:
			if tv.seg < road.size() - 1:
				tv.seg += 1
				tv.t = 0.0
			else:
				tv.dir = -1
				tv.t = 1.0
		elif tv.t < 0.0:
			if tv.seg > 1:
				tv.seg -= 1
				tv.t = 1.0
			else:
				tv.dir = 1
				tv.t = 0.0
		var p: Vector2 = (road[tv.seg - 1] as Vector2).lerp(road[tv.seg], clamp(tv.t, 0.0, 1.0))
		var side: Vector2 = (b - a).normalized()
		p += Vector2(side.y, -side.x) * 1.4 * tv.dir
		tv.x = p.x
		tv.z = p.y
		tv.node.position = Vector3(p.x, H(p.x, p.y), p.y)
		tv.node.rotation.y = atan2(side.x * tv.dir, side.y * tv.dir)
	for fl in flocks:
		fl.node.rotation.y += fl.spd * dt

# viaje rápido: clic en un santuario descubierto (o una ciudad) del minimapa
func try_fast_travel(pos: Vector2) -> bool:
	var vw := get_viewport().get_visible_rect().size.x
	var sz := 190.0
	var o := Vector2(vw - sz - 12, 52)
	if not Rect2(o, Vector2(sz, sz)).has_point(pos):
		return false
	var targets := []
	for sh in shrines:
		if sh.found:
			targets.append([sh.name, Vector2(sh.x, sh.z)])
	for k in CITIES:
		targets.append([CITIES[k].name, CITIES[k].spawn])
	for t in targets:
		var mp: Vector2 = o + Vector2((t[1].x + Terrain.HALF) / Terrain.SIZE, (t[1].y + Terrain.HALF) / Terrain.SIZE) * sz
		if mp.distance_to(pos) < 8.0:
			var q: Vector2 = free_spot(t[1] + Vector2(0, 4), 1.0)
			P.x = q.x
			P.z = q.y
			cam_x = P.x
			cam_z = P.z
			for m in mobs:
				calm(m)
			toast("Viajaste a %s (en el juego final cuesta un poco de Oro)" % t[0])
			return true
	return true

# ----------------------------------------------------------------- flora recolectable y decoración por bioma
var flora_parts := {}        # especie -> [[MultiMesh, Transform3D local], ...]
var flora: Array = []        # {sp, x, z, idx, base: Transform3D, taken, regrow}
var flora_grid := {}

func part(mesh: Mesh, c: Color, xf: Transform3D, glow := false) -> Array:
	return [mesh, c, xf, glow]

func pmesh_box(sz: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = sz
	return m

func pmesh_sphere(r: float, h := -1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0 if h < 0 else h
	m.radial_segments = 8
	m.rings = 4
	return m

func pmesh_cyl(top: float, bot: float, h: float, seg := 6) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bot
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m

func T(pos: Vector3, rot := Vector3.ZERO, sc := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot).scaled(sc), pos)

func flora_shape(sp: String) -> Array:
	var leaf := Color("#4f8f3a")
	match sp:
		"hierba_dulce":
			return [part(pmesh_box(Vector3(0.08, 0.5, 0.08)), leaf, T(Vector3(0, 0.25, 0), Vector3(0.2, 0, 0.1))),
				part(pmesh_box(Vector3(0.08, 0.45, 0.08)), leaf, T(Vector3(0.1, 0.22, 0.05), Vector3(-0.2, 0, -0.2))),
				part(pmesh_sphere(0.09), Color("#f2d64b"), T(Vector3(0.03, 0.52, 0.02)))]
		"hierba_vida":
			return [part(pmesh_box(Vector3(0.3, 0.06, 0.12)), leaf, T(Vector3(0, 0.25, 0), Vector3(0, 0, 0.5))),
				part(pmesh_box(Vector3(0.3, 0.06, 0.12)), leaf, T(Vector3(0, 0.25, 0), Vector3(0, 1.6, -0.5))),
				part(pmesh_cyl(0.02, 0.02, 0.5), leaf, T(Vector3(0, 0.25, 0))),
				part(pmesh_sphere(0.1), Color("#e0405a"), T(Vector3(0, 0.52, 0)), true)]
		"bayas":
			return [part(pmesh_sphere(0.4, 0.55), Color("#3f7a35"), T(Vector3(0, 0.28, 0))),
				part(pmesh_sphere(0.07), Color("#7b3fb8"), T(Vector3(0.25, 0.45, 0.2))),
				part(pmesh_sphere(0.07), Color("#7b3fb8"), T(Vector3(-0.2, 0.4, 0.25))),
				part(pmesh_sphere(0.07), Color("#7b3fb8"), T(Vector3(0.05, 0.55, -0.28)))]
		"hongo":
			return [part(pmesh_cyl(0.06, 0.08, 0.3), Color("#efe6d2"), T(Vector3(0, 0.15, 0))),
				part(pmesh_sphere(0.2, 0.18), Color("#9a5a32"), T(Vector3(0, 0.33, 0)))]
		"hongo_luz":
			return [part(pmesh_cyl(0.05, 0.07, 0.35), Color("#e6f4ff"), T(Vector3(0, 0.17, 0))),
				part(pmesh_sphere(0.18, 0.16), Color("#5fe0ff"), T(Vector3(0, 0.38, 0)), true)]
		"zanahoria":
			return [part(pmesh_cyl(0.09, 0.02, 0.25), Color("#f08a2c"), T(Vector3(0, 0.08, 0))),
				part(pmesh_box(Vector3(0.05, 0.4, 0.05)), Color("#5fae3e"), T(Vector3(0, 0.38, 0), Vector3(0.3, 0, 0))),
				part(pmesh_box(Vector3(0.05, 0.4, 0.05)), Color("#5fae3e"), T(Vector3(0, 0.38, 0), Vector3(-0.3, 0, 0.2)))]
		"calabaza":
			return [part(pmesh_sphere(0.38, 0.55), Color("#e8822a"), T(Vector3(0, 0.27, 0))),
				part(pmesh_cyl(0.04, 0.05, 0.18), Color("#5b7a2a"), T(Vector3(0, 0.6, 0))),
				part(pmesh_box(Vector3(0.5, 0.03, 0.3)), leaf, T(Vector3(0.4, 0.05, 0), Vector3(0, 0.6, 0)))]
		"trigo":
			return [part(pmesh_box(Vector3(0.04, 0.9, 0.04)), Color("#d9c16a"), T(Vector3(0, 0.45, 0), Vector3(0.1, 0, 0))),
				part(pmesh_box(Vector3(0.04, 0.85, 0.04)), Color("#d9c16a"), T(Vector3(0.12, 0.42, 0.05), Vector3(-0.15, 0, -0.1))),
				part(pmesh_box(Vector3(0.09, 0.22, 0.09)), Color("#e8cf72"), T(Vector3(0.0, 0.95, 0.04)))]
		"tuna":
			return [part(pmesh_cyl(0.2, 0.22, 0.8, 8), Color("#4f8a4a"), T(Vector3(0, 0.4, 0))),
				part(pmesh_sphere(0.1), Color("#e0507a"), T(Vector3(0.12, 0.85, 0)), false),
				part(pmesh_sphere(0.1), Color("#e0507a"), T(Vector3(-0.1, 0.82, 0.08)), false)]
		"pimiento":
			return [part(pmesh_sphere(0.25, 0.35), Color("#4f8f3a"), T(Vector3(0, 0.18, 0))),
				part(pmesh_cyl(0.07, 0.02, 0.22), Color("#e23b2e"), T(Vector3(0.15, 0.35, 0), Vector3(0, 0, 0.6))),
				part(pmesh_cyl(0.07, 0.02, 0.22), Color("#e23b2e"), T(Vector3(-0.12, 0.33, 0.1), Vector3(0.3, 0, -0.5)))]
		"menta":
			return [part(pmesh_sphere(0.25, 0.3), Color("#a8e0b8"), T(Vector3(0, 0.15, 0))),
				part(pmesh_sphere(0.18, 0.25), Color("#c4f0d0"), T(Vector3(0.1, 0.3, 0.05)))]
		"flor_escarcha":
			return [part(pmesh_cyl(0.02, 0.02, 0.4), Color("#7fa8c0"), T(Vector3(0, 0.2, 0))),
				part(pmesh_box(Vector3(0.35, 0.03, 0.12)), Color("#dff4ff"), T(Vector3(0, 0.42, 0), Vector3(0, 0, 0)), true),
				part(pmesh_box(Vector3(0.35, 0.03, 0.12)), Color("#dff4ff"), T(Vector3(0, 0.42, 0), Vector3(0, 1.57, 0)), true),
				part(pmesh_sphere(0.06), Color("#7ec8ff"), T(Vector3(0, 0.45, 0)), true)]
		"coco":
			return [part(pmesh_sphere(0.2), Color("#6b4a2e"), T(Vector3(0, 0.18, 0))),
				part(pmesh_sphere(0.2), Color("#5e4026"), T(Vector3(0.3, 0.18, 0.1)))]
		"alga":
			return [part(pmesh_box(Vector3(0.12, 0.6, 0.04)), Color("#2f6b4a"), T(Vector3(0, 0.3, 0), Vector3(0, 0, 0.25))),
				part(pmesh_box(Vector3(0.12, 0.5, 0.04)), Color("#3b7a52"), T(Vector3(0.1, 0.25, 0), Vector3(0, 0.8, -0.3))),
				part(pmesh_box(Vector3(0.12, 0.55, 0.04)), Color("#2f6b4a"), T(Vector3(-0.08, 0.27, 0.06), Vector3(0, 2.0, 0.2)))]
	return []

func make_parts_mm(shape: Array, count: int) -> Array:
	var out := []
	for pt in shape:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = pt[0]
		mm.instance_count = count
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		var m := mat(pt[1])
		if pt[3]:
			m.emission_enabled = true
			m.emission = pt[1]
			m.emission_energy_multiplier = 0.9
		mi.material_override = m
		mi.visibility_range_end = 120.0
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(mi)
		out.append([mm, pt[2]])
	return out

func set_flora_xf(f: Dictionary, base: Transform3D) -> void:
	for pp in flora_parts[f.sp]:
		pp[0].set_instance_transform(f.idx, base * pp[1])

func flora_spot_ok(sp: String, x: float, z: float) -> bool:
	var bi: String = Terrain.biome_at(x, z)
	if not bi in Data.FLORA[sp].biomes:
		return false
	var h: float = terrain.height(x, z)
	if sp == "alga":
		return h > -0.4 and h < 0.9 and not in_city(x, z, 5.0)
	if h < 1.0 or in_city(x, z, 5.0) or terrain.road_dist(Vector2(x, z)) < 3.0 or blocked(x, z, 0.6):
		return false
	return true

func build_flora() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 6060
	for sp in Data.FLORA:
		var want: int = int(Data.FLORA[sp].n * 2.5)
		var pts := []
		var tries := 0
		while pts.size() < want and tries < want * 60:
			tries += 1
			var cx := r.randf_range(-490.0, 490.0)
			var cz := r.randf_range(-490.0, 490.0)
			if not flora_spot_ok(sp, cx, cz):
				continue
			# en matas, como en BotW: varias juntas
			for k in r.randi_range(3, 6):
				var q := Vector2(cx, cz) + Vector2(r.randf_range(-3.5, 3.5), r.randf_range(-3.5, 3.5))
				if flora_spot_ok(sp, q.x, q.y):
					pts.append(q)
		flora_parts[sp] = make_parts_mm(flora_shape(sp), pts.size())
		for i in pts.size():
			var q: Vector2 = pts[i]
			var base := Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(1.2, 1.6)), Vector3(q.x, H(q.x, q.y) - 0.03, q.y))
			var f := {"sp": sp, "x": q.x, "z": q.y, "idx": i, "base": base, "taken": false, "regrow": 0.0}
			set_flora_xf(f, base)
			flora.append(f)
			var k := Vector2i(int(floor(q.x / 8.0)), int(floor(q.y / 8.0)))
			if not flora_grid.has(k):
				flora_grid[k] = []
			flora_grid[k].append(f)
	build_biome_decor(r)

# decoración que no se recolecta: cactus en el desierto, palmeras en la playa, rocas de nieve
func build_biome_decor(r: RandomNumberGenerator) -> void:
	var cactus := [part(pmesh_cyl(0.45, 0.5, 3.2, 8), Color("#4f8a4a"), T(Vector3(0, 1.6, 0))),
		part(pmesh_cyl(0.3, 0.3, 1.4, 8), Color("#4f8a4a"), T(Vector3(0.75, 2.0, 0))),
		part(pmesh_cyl(0.3, 0.3, 0.9, 8), Color("#4f8a4a"), T(Vector3(0.45, 1.45, 0), Vector3(0, 0, 1.57))),
		part(pmesh_cyl(0.28, 0.28, 1.1, 8), Color("#4f8a4a"), T(Vector3(-0.7, 2.4, 0))),
		part(pmesh_cyl(0.28, 0.28, 0.8, 8), Color("#4f8a4a"), T(Vector3(-0.42, 1.95, 0), Vector3(0, 0, 1.57)))]
	var palm := [part(pmesh_cyl(0.2, 0.32, 6.5, 6), Color("#8a6a45"), T(Vector3(0.6, 3.2, 0), Vector3(0, 0, -0.18)))]
	for k in 7:
		var a := TAU * k / 7.0
		palm.append(part(pmesh_box(Vector3(3.2, 0.08, 0.7)), Color("#4f9a45"), T(Vector3(1.2 + cos(a) * 1.5, 6.3, sin(a) * 1.5), Vector3(0, -a, -0.35))))
	var sets = [[cactus, 140, ["desierto", "canadon"]], [palm, 45, ["playa"]]]
	for st in sets:
		var pts := []
		var tries := 0
		while pts.size() < int(st[1]) and tries < 20000:
			tries += 1
			var x := r.randf_range(-490.0, 490.0)
			var z := r.randf_range(-490.0, 490.0)
			if not Terrain.biome_at(x, z) in st[2]:
				continue
			if terrain.height(x, z) < 1.2 or in_city(x, z, 8.0) or terrain.road_dist(Vector2(x, z)) < 4.0 or blocked(x, z, 1.5):
				continue
			pts.append(Vector2(x, z))
		var parts := make_parts_mm(st[0], pts.size())
		for i in pts.size():
			var q: Vector2 = pts[i]
			var base := Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.8, 1.3)), Vector3(q.x, H(q.x, q.y) - 0.1, q.y))
			for pp in parts:
				pp[0].set_instance_transform(i, base * pp[1])
			add_collider(q, Vector2(0.6, 0.6), 0.0)

func update_flora(dt: float) -> void:
	var k0 := Vector2i(int(floor(P.x / 8.0)), int(floor(P.z / 8.0)))
	for gx in range(k0.x - 1, k0.x + 2):
		for gz in range(k0.y - 1, k0.y + 2):
			var k := Vector2i(gx, gz)
			if not flora_grid.has(k):
				continue
			for f in flora_grid[k]:
				if f.taken or d2(P.x, P.z, f.x, f.z) > 1.4:
					continue
				f.taken = true
				f.regrow = 180.0                    # vuelve a crecer a los 3 minutos
				set_flora_xf(f, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(f.x, -50, f.z)))
				var nm: String = Data.FLORA[f.sp].name
				ingredients[nm] = int(ingredients.get(nm, 0)) + 1
				add_text(Vector3(f.x, 1.6, f.z), "+1 %s (%s)" % [nm, Data.FLORA[f.sp].use], Color("#7ee787"), 13)
	for f in flora:
		if f.taken:
			f.regrow -= dt
			if f.regrow <= 0 and d2(P.x, P.z, f.x, f.z) > 4.0:
				f.taken = false
				set_flora_xf(f, f.base)

# ----------------------------------------------------------------- vetas de mineral
# cada bioma tiene sus vetas; el Imperio no tiene todos los minerales (los otros vienen de la frontera o del comercio)
func ore_region_ok(kind: String, x: float, z: float) -> bool:
	var bi: String = Terrain.biome_at(x, z)
	var t: int = zone_at(x, z).tier
	match kind:
		"piedra":
			return bi in ["pradera", "campos", "canadon"]
		"cobre":
			return bi in ["bosque", "pradera"]
		"hierro":
			return t == 1 and bi != "playa"
		"azufre":
			return bi in ["canadon", "desierto"]
		"sal":
			return bi == "playa" or bi == "desierto"
		"cuarzo":
			return bi in ["pradera", "montana", "campos"]
		"luminita":
			return bi == "montana"
		"plata":
			return t == 2
		"hielo":
			return bi == "nieve"
		"mithril":
			return bi == "nieve" and t == 3
		"frontera":
			return abs(x) > 420.0 or abs(z) > 420.0
	return true

func build_ores() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	var plan = [["piedra", 45], ["cobre", 28], ["hierro", 25], ["azufre", 24], ["sal", 18], ["cuarzo", 30], ["luminita", 20],
		["plata", 22], ["hielo", 18], ["mithril", 14], ["frontera", 10]]
	for pl in plan:
		var made := 0
		var tries := 0
		while made < int(pl[1]) and tries < 5000:
			tries += 1
			var x := r.randf_range(-480.0, 480.0)
			var z := r.randf_range(-480.0, 480.0)
			if not ore_region_ok(pl[0], x, z):
				continue
			if in_city(x, z, 15.0) or terrain.road_dist(Vector2(x, z)) < 4.0 or terrain.river_dist(Vector2(x, z)) < 5.0:
				continue
			var h: float = terrain.height(x, z)
			if h < 1.5 or blocked(x, z, 2.5):
				continue
			if abs(terrain.height(x + 2, z) - terrain.height(x - 2, z)) + abs(terrain.height(x, z + 2) - terrain.height(x, z - 2)) > 3.5:
				continue
			add_ore(pl[0], x, z, r)
			made += 1

func add_ore(kind: String, x: float, z: float, r: RandomNumberGenerator) -> void:
	var d: Dictionary = Data.ORES[kind]
	var node := Node3D.new()
	node.position = Vector3(x, H(x, z), z)
	node.rotation.y = r.randf() * TAU
	world.add_child(node)
	var sc := r.randf_range(1.3, 1.7)
	node.scale = Vector3.ONE * sc
	for k in 3:
		var rk := box(Vector3(r.randf_range(1.0, 1.6), r.randf_range(0.8, 1.4), r.randf_range(1.0, 1.5)), d.rock.darkened(r.randf() * 0.15),
			Vector3(r.randf_range(-0.5, 0.5), 0.4, r.randf_range(-0.5, 0.5)), node)
		rk.rotation = Vector3(r.randf_range(-0.3, 0.3), r.randf() * TAU, r.randf_range(-0.3, 0.3))
	for k in 8:
		var a := r.randf() * TAU
		var g := box(Vector3(0.32, r.randf_range(0.6, 1.1), 0.32), d.gem, Vector3(cos(a) * 0.7, r.randf_range(0.8, 1.3), sin(a) * 0.7), node)
		g.rotation = Vector3(r.randf_range(-0.6, 0.6), r.randf() * TAU, r.randf_range(-0.6, 0.6))
		if d.glow:
			g.material_override.emission_enabled = true
			g.material_override.emission = d.gem
			g.material_override.emission_energy_multiplier = 0.8
	for ch in node.get_children():
		if ch is GeometryInstance3D:
			ch.visibility_range_end = 140.0
	add_collider(Vector2(x, z), Vector2(1.0, 1.0) * sc, 0.0)
	ores.append({"kind": kind, "x": x, "z": z, "hp": d.hp, "max": d.hp, "node": node, "col": last_col, "regrow": 0.0, "sc": sc})

func damage_ores(x: float, z: float, r: float, dmg: float, once = null, blast := false) -> void:
	# golpes pesados y explosiones rompen la roca más rápido; la magia, más lento
	var wt: String = weapon.get("wtype", "")
	if blast or wt in ["mandoble", "escudo"]:
		dmg *= 2.0
	elif not Data.WTYPES.get(wt, {"phys": true}).phys:
		dmg *= 0.5
	for o in ores:
		if o.regrow > 0:
			continue
		if Vector2(o.x - x, o.z - z).length() > r + 1.2 * o.sc:
			continue
		if once != null:
			if once.has(o.node):
				continue
			once[o.node] = true
		o.hp -= dmg
		add_text(Vector3(o.x, 2.4, o.z), str(int(dmg)), Color("#c9d1d9"), 13)
		if o.hp <= 0:
			break_ore(o)

func break_ore(o: Dictionary) -> void:
	var d: Dictionary = Data.ORES[o.kind]
	o.regrow = 300.0                 # vuelve a aparecer a los 5 minutos
	o.node.visible = false
	o.col.off = true
	flash_fx("ring", o.x, o.z, 2.2, Vector2(0, 1), d.gem)
	var got := []
	var drops: Array = d.drops
	if o.kind == "frontera":
		drops = [[d.drops[randi() % d.drops.size()][0], 1.0]]
	for dr in drops:
		if randf() < float(dr[1]):
			var n := 1 + (1 if randf() < 0.3 else 0)
			minerals[dr[0]] = int(minerals.get(dr[0], 0)) + n
			got.append("+%d %s" % [n, dr[0]])
	if got.is_empty():
		var first: String = d.drops[0][0]
		minerals[first] = int(minerals.get(first, 0)) + 1
		got.append("+1 " + first)
	add_text(Vector3(o.x, 3.2, o.z), "  ".join(got), d.gem.lightened(0.3), 14)
	# escombros
	for k in 4:
		var frag := box(Vector3(0.4, 0.3, 0.4), d.rock, Vector3(o.x + randf_range(-1, 1), H(o.x, o.z) + 0.15, o.z + randf_range(-1, 1)), world)
		frag.rotation.y = randf() * TAU
		o["frags"] = o.get("frags", []) + [frag]

func update_ores(dt: float) -> void:
	for o in ores:
		if o.regrow > 0:
			o.regrow -= dt
			if o.regrow <= 0 and d2(P.x, P.z, o.x, o.z) > 3.0:
				o.hp = o.max
				o.node.visible = true
				o.col.off = false
				for f in o.get("frags", []):
					f.queue_free()
				o["frags"] = []
			elif o.regrow <= 0:
				o.regrow = 1.0           # esperá a que te corras

func update_trees(dt: float) -> void:
	for i in range(falling.size() - 1, -1, -1):
		var f: Dictionary = falling[i]
		f.t += dt
		var ang: float = min(PI / 2.0, f.t * f.t * 3.2)
		var n: MeshInstance3D = f.node
		var shrink: float = 1.0 - clamp((f.t - 1.3) / 0.5, 0.0, 1.0)
		n.transform = Transform3D(Basis(f.axis, ang) * f.basis.scaled(Vector3.ONE * max(0.001, shrink)), f.pos)
		if f.t > 1.8:
			flash_fx("ring", f.pos.x, f.pos.z, 2.0, Vector2(0, 1), Color("#9ccf6a"))
			n.queue_free()
			falling.remove_at(i)
	for i in range(regrowing.size() - 1, -1, -1):
		var t: TreeObj = regrowing[i]
		if not t.alive:
			t.regrow -= dt
			if t.regrow <= 0:
				t.alive = true
				t.hp = t.max_hp
				t.grow = 0.15
				stump_mm.set_instance_transform(t.id, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(t.x, -50, t.z)))
		else:
			t.grow = min(1.0, t.grow + dt * 0.5)          # vuelve a crecer de a poco
			tree_mms[t.sp].set_instance_transform(t.idx, tree_xform(t))
			if t.grow >= 1.0:
				regrowing.remove_at(i)

func build_aim_indicator() -> void:
	aim_root = Node3D.new()
	world.add_child(aim_root)
	aim_root.visible = false
	aim_ring = MeshInstance3D.new()
	aim_ring.mesh = ring_mesh
	aim_ring.material_override = ind_mat(Color.WHITE, 0.55)
	aim_root.add_child(aim_ring)
	aim_sector = MeshInstance3D.new()
	aim_sector.material_override = ind_mat(Color("#7fd3ff"), 0.3)
	aim_root.add_child(aim_sector)
	aim_disc = MeshInstance3D.new()
	aim_disc.mesh = disc_mesh()
	aim_disc.material_override = ind_mat(Color("#7fd3ff"), 0.25)
	aim_root.add_child(aim_disc)
	aim_target = MeshInstance3D.new()
	aim_target.mesh = disc_mesh()
	aim_target.material_override = ind_mat(Color("#7fd3ff"), 0.35)
	world.add_child(aim_target)
	aim_target.visible = false
	aim_rect = line_holder(1, 1, Color("#7fd3ff"), 0.3, aim_root)
	aim_mats = [aim_ring.material_override, aim_sector.material_override, aim_disc.material_override, aim_target.material_override, aim_rect.get_child(0).material_override]

func update_aim_indicator() -> void:
	var on := aim_slot != "" and running and P != null and P.dead <= 0
	aim_root.visible = on
	aim_target.visible = false
	if not on:
		return
	aim_line.visible = false
	var s: Dictionary = weapon[aim_slot]
	var ready: bool = P.cds[aim_slot] <= 0
	var col := Color("#7fd3ff") if ready else Color("#ff6b6b")
	for i in aim_mats.size():
		var m: StandardMaterial3D = aim_mats[i]
		var a := 0.55 if i == 0 else (0.35 if i == 3 else 0.28)
		m.albedo_color = Color(col.r, col.g, col.b, a) if i != 0 else Color(1, 1, 1, a)
	var aim := resolve_aim(s, true)
	var d: Vector2 = aim[0]
	var dd: float = aim[1]
	aim_root.position = Vector3(P.x, H(P.x, P.z) + 0.08, P.z)
	aim_root.rotation.y = atan2(d.x, d.y)
	var rr: float = s.get("range", s.get("radius", 3.0))
	aim_ring.scale = Vector3(rr, 0.05, rr)
	aim_ring.visible = true
	aim_sector.visible = false
	aim_disc.visible = false
	aim_rect.visible = false
	match s.type:
		"cone":
			aim_sector.mesh = sector_mesh(s.angle)
			aim_sector.scale = Vector3(s.range, 1, s.range)
			aim_sector.visible = true
		"dash", "proj", "line":
			aim_rect.scale = Vector3(max(0.6, s.get("width", 0.6)), 1, s.range)
			aim_rect.visible = true
		"blast", "leap", "blink":
			var r: float = s.get("radius", 1.2)
			aim_target.position = Vector3(P.x + d.x * dd, H(P.x + d.x * dd, P.z + d.y * dd) + 0.09, P.z + d.y * dd)
			aim_target.scale = Vector3(r, 1, r)
			aim_target.visible = true
		"buff":
			aim_ring.scale = Vector3(1.5, 0.05, 1.5)
		_:
			aim_disc.scale = Vector3(rr, 1, rr)
			aim_disc.visible = true

func spawn_mobs() -> void:
	for m in mobs:
		m.node.queue_free()
		if m.tele:
			m.tele.queue_free()
		if m.slam:
			m.slam.node.queue_free()
	mobs.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 5
	# campamentos por franja de nivel
	for cp in camps:
		for entry in cp.roster:
			for i in int(entry[1]):
				var lv := r.randi_range(int(cp.lvl[0]), int(cp.lvl[1]))
				var q := free_spot(cp.pos + Vector2(r.randf_range(-5, 5), r.randf_range(-5, 5)), 1.0)
				var m := make_mob(entry[0], q.x, q.y, lv)
				m.tier = int(cp.tier)
				m.camp = camps.find(cp)
				m.orbit = 1.0 if r.randf() < 0.5 else -1.0
				var tp: String = m.d.temper
				if tp == "dormant":
					m.init_state = "dormant"
				elif tp in ["camp", "coward"]:
					if m.d.ai == "ranged" and not cp.has("vigia"):
						cp["vigia"] = true
						m.sentinel = true          # el vigía ve más lejos
					elif r.randf() < 0.5:
						m.init_state = "rest"      # duerme junto al fuego
				m.state = m.init_state
				mobs.append(m)

func make_mob(type: String, x: float, z: float, lvl := 5) -> Mob:
	var m := Mob.new()
	m.type = type
	m.lvl = lvl
	m.d = Data.MOBDEF[type].duplicate(true)
	# el nivel escala vida, daño y maestría (curva suave: la habilidad sigue importando)
	m.mult = 1.0 + 0.025 * (lvl - 5)
	m.d.hp = m.d.hp * (1.0 + 0.03 * (lvl - 5))
	m.d.dmg = m.d.dmg * m.mult
	m.d.xp = int(round(m.d.xp * (1.0 + 0.02 * (lvl - 5))))
	m.x = x
	m.z = z
	m.sx = x
	m.sz = z
	m.hp = m.d.hp
	m.max_hp = m.d.hp
	m.atk_cd = randf()
	m.special = 2.5 + randf() * 2
	m.node = Node3D.new()
	world.add_child(m.node)
	var parts := []
	var col: Color = m.d.color
	var acc: Color = m.d.get("accent", col.darkened(0.3))
	var s: float = m.d.get("size", 1.0)
	match String(m.d.get("body", "brute")):
		"quad":
			parts.append(box(Vector3(0.8, 0.8, 1.8) * s, col, Vector3(0, 0.75 * s, 0), m.node))
			parts.append(box(Vector3(0.62, 0.6, 0.7) * s, col.darkened(0.15), Vector3(0, 1.05 * s, 1.1 * s), m.node))
			for lx in [-0.28, 0.28]:
				for lz in [-0.6, 0.6]:
					box(Vector3(0.2, 0.5, 0.2) * s, col.darkened(0.3), Vector3(lx * s, 0.25 * s, lz * s), m.node)
			if type == "conejo":
				var horn := cyl(0.01, 0.09, 0.6, acc, Vector3(0, 1.55 * s, 1.25 * s), m.node, 6)
				horn.rotation.x = 0.5
				for ex in [-0.15, 0.15]:
					box(Vector3(0.1, 0.55, 0.12) * s, col, Vector3(ex * s, 1.55 * s, 0.95 * s), m.node)
			elif type == "jabali":
				for tx in [-0.22, 0.22]:
					var tusk := cyl(0.01, 0.06, 0.35, acc, Vector3(tx * s, 0.9 * s, 1.5 * s), m.node, 5)
					tusk.rotation.x = -1.0
				box(Vector3(0.12, 0.25, 1.2) * s, col.darkened(0.4), Vector3(0, 1.25 * s, 0), m.node)
			elif type == "oso":
				box(Vector3(0.3, 0.3, 0.3) * s, acc, Vector3(0, 1.0 * s, 1.5 * s), m.node)
				for ex in [-0.2, 0.2]:
					sphere(0.12 * s, col, Vector3(ex * s, 1.42 * s, 1.0 * s), m.node)
			else:
				for ex in [-0.18, 0.18]:
					box(Vector3(0.12, 0.3, 0.1) * s, acc, Vector3(ex * s, 1.45 * s, 0.95 * s), m.node)
		"biped":
			var ghost := type == "espectro"
			if not ghost:
				for lx in [-0.18, 0.18]:
					box(Vector3(0.22, 0.6, 0.24) * s, col.darkened(0.35), Vector3(lx * s, 0.3 * s, 0), m.node)
			var torso := cyl(0.42 * s, 0.5 * s, 1.2 * s, col, Vector3(0, (1.6 if ghost else 1.15) * s, 0), m.node, 8)
			parts.append(torso)
			box(Vector3(0.95, 0.2, 0.95) * s, acc, Vector3(0, (1.3 if ghost else 0.9) * s, 0), m.node)
			var skin := Color("#d9a77c")
			if type in ["goblin", "hondero"]:
				skin = Color("#8fbf4f")
			elif type == "orco":
				skin = Color("#7f9a62")
			elif ghost:
				skin = Color("#e6e1ff")
			var head := sphere(0.34 * s, skin, Vector3(0, (2.45 if ghost else 2.0) * s, 0), m.node)
			parts.append(head)
			if type in ["goblin", "hondero"]:
				for ex in [-1.0, 1.0]:
					var ear := box(Vector3(0.45, 0.1, 0.15) * s, skin, Vector3(ex * 0.4 * s, 2.05 * s, 0), m.node)
					ear.rotation.z = ex * -0.4
			if type == "orco":
				for tx in [-0.1, 0.1]:
					box(Vector3(0.06, 0.16, 0.06) * s, Color("#f0ead6"), Vector3(tx * s, 1.9 * s, 0.3 * s), m.node)
			if type in ["bandido", "arquero", "jefe"]:
				box(Vector3(0.7, 0.18, 0.7) * s, acc, Vector3(0, 1.75 * s, 0), m.node)      # pañuelo
			if ghost:
				torso.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				torso.material_override.emission_enabled = true
				torso.material_override.emission = col
				torso.material_override.emission_energy_multiplier = 0.6
				var tail := cyl(0.5 * s, 0.05, 1.1 * s, col, Vector3(0, 0.6 * s, 0), m.node, 8)
				tail.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				tail.material_override.albedo_color.a = 0.6
			match String(m.d.get("weapon", "")):
				"espada", "daga":
					var bl := box(Vector3(0.08, 0.9 if m.d.weapon == "espada" else 0.5, 0.18) * s, Color("#c9ccd1"), Vector3(0.55 * s, 1.2 * s, 0.4 * s), m.node)
					bl.rotation.x = 0.8
				"arco":
					box(Vector3(0.1, 1.2, 0.1) * s, Color("#5b3a1e"), Vector3(0.45 * s, 1.3 * s, 0.4 * s), m.node)
				"honda":
					sphere(0.12 * s, Color("#8a8a82"), Vector3(0.45 * s, 1.5 * s, 0.3 * s), m.node)
				"hacha":
					var hd := cyl(0.06 * s, 0.08 * s, 1.4 * s, Color("#4a3a2a"), Vector3(0.6 * s, 1.3 * s, 0.4 * s), m.node, 6)
					hd.rotation.x = 0.6
					box(Vector3(0.1, 0.45, 0.5) * s, Color("#9aa0a6"), Vector3(0.6 * s, 1.85 * s, 0.75 * s), m.node)
		_:
			parts.append(box(Vector3(2.4, 2.6, 1.8) * s, col, Vector3(0, 1.7 * s, 0), m.node))
			parts.append(box(Vector3(1.2, 1.1, 1.1) * s, acc if type == "ogro" else col.darkened(0.15), Vector3(0, 3.5 * s, 0), m.node))
			for ax in [-1.0, 1.0]:
				parts.append(box(Vector3(0.7, 2.2, 0.7) * s, col.darkened(0.1), Vector3(ax * 1.55 * s, 1.6 * s, 0), m.node))
			if type == "golem":
				for ax in [-1.0, 1.0]:
					box(Vector3(0.9, 0.3, 0.9) * s, acc, Vector3(ax * 1.55 * s, 2.8 * s, 0), m.node)       # musgo
				var eye := box(Vector3(0.8, 0.15, 0.1) * s, Color("#7ee7ff"), Vector3(0, 3.6 * s, 0.56 * s), m.node)
				eye.material_override.emission_enabled = true
				eye.material_override.emission = Color("#7ee7ff")
			elif type == "troll":
				box(Vector3(1.0, 0.5, 0.4) * s, Color("#e8f0f8"), Vector3(0, 4.15 * s, 0), m.node)
			else:
				var club := cyl(0.3, 0.5, 2.6, Color("#4a3a2a"), Vector3(1.6 * s, 1.6 * s, 0.6 * s), m.node, 6)
				club.rotation.x = 0.6
	for p in parts:
		m.mats.append(p.material_override)
		m.base_colors.append(p.material_override.albedo_color)
	m.node.position = Vector3(x, H(x, z), z)
	return m

func spawn_player() -> void:
	P = Player.new()
	var city: Dictionary = CITIES[weapon.get("start", "lumen")]
	var sp := free_spot(city.spawn, 1.0)
	P.x = sp.x
	P.z = sp.y
	P.hp = weapon.hp
	P.max_hp = weapon.hp
	P.speed = weapon.speed
	recompute_gear()
	P.hp = P.max_hp
	if pnode:
		pnode.queue_free()
	pnode = Node3D.new()
	world.add_child(pnode)
	pmats.clear()
	hero_model = null
	hero_anim = null
	hero_cur = ""
	act_t = 0.0
	var hero_path := "res://assets/heroes/%s.glb" % weapon.id
	if ResourceLoader.exists(hero_path):
		build_hero(hero_path)
		cam_x = P.x
		cam_z = P.z
		return
	var body := cyl(0.55, 0.65, 1.6, weapon.color, Vector3(0, 1.0, 0), pnode)
	var head := sphere(0.42, Color("#f1c9a5"), Vector3(0, 2.1, 0), pnode)
	var wpn := box(Vector3(0.18, 0.18, 1.5), Color("#dddddd"), Vector3(0.75, 1.2, 0.6), pnode)
	var nose := box(Vector3(0.25, 0.12, 0.3), Color("#222222"), Vector3(0, 2.15, 0.4), pnode)
	for p in [body, head, wpn, nose]:
		pmats.append(p.material_override)
	cam_x = P.x
	cam_z = P.z

func hero_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.35
	m.roughness = 0.45
	m.rim_enabled = true
	m.rim = 0.5
	m.rim_tint = 0.5
	return m

func build_hero(path: String) -> void:
	hero_model = load(path).instantiate()
	hero_model.scale = Vector3.ONE * HERO_SCALE
	pnode.add_child(hero_model)
	# material estilizado: armadura clara con un toque del color de la clase y borde de luz
	var armor := hero_material(Color("#b9b2a2").lerp(weapon.color, 0.3))
	pmats.append(armor)
	for mi in hero_model.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = armor
	var aps := hero_model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		hero_anim = aps[0]
		for n in ["idle", "run", "strafe"]:
			if hero_anim.has_animation(n):
				hero_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		hero_anim.play("idle")
		hero_cur = "idle"
	# armas agarradas a los huesos de las manos (se cambian solas, como en el diseño)
	var sks := hero_model.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return
	var sk: Skeleton3D = sks[0]
	var gold := hero_material(Color("#e8b84a"))
	var steel := hero_material(Color("#dfe6ee"))
	var cloth := hero_material(weapon.color)
	pmats.append_array([gold, steel, cloth])
	# el esqueleto de Mixamo viene en centímetros: compensamos la escala para trabajar en metros
	var k: float = HERO_SCALE / max(0.0001, sk.global_transform.basis.get_scale().x)
	var rh := BoneAttachment3D.new()
	rh.bone_name = "mixamorig_RightHand"
	sk.add_child(rh)
	var rhs := Node3D.new()
	rhs.scale = Vector3.ONE * k
	rh.add_child(rhs)
	var sword := Node3D.new()
	sword.position = SWORD_POS
	sword.rotation_degrees = SWORD_ROT
	rhs.add_child(sword)
	var blade := box(Vector3(0.07, 0.75, 0.02), Color.WHITE, Vector3(0, 0.45, 0), sword)
	blade.material_override = steel
	var guard := box(Vector3(0.26, 0.05, 0.06), Color.WHITE, Vector3(0, 0.06, 0), sword)
	guard.material_override = gold
	var grip := box(Vector3(0.045, 0.16, 0.045), Color.WHITE, Vector3(0, -0.04, 0), sword)
	grip.material_override = gold
	var lh := BoneAttachment3D.new()
	lh.bone_name = "mixamorig_LeftHand"
	sk.add_child(lh)
	var lhs := Node3D.new()
	lhs.scale = Vector3.ONE * k
	lh.add_child(lhs)
	var shield := Node3D.new()
	shield.position = SHIELD_POS
	shield.rotation_degrees = SHIELD_ROT
	lhs.add_child(shield)
	var face := box(Vector3(0.5, 0.7, 0.05), Color.WHITE, Vector3(0, 0, 0.09), shield)
	face.material_override = steel
	var rim := box(Vector3(0.56, 0.76, 0.03), Color.WHITE, Vector3(0, 0, 0.07), shield)
	rim.material_override = gold
	var emblem := box(Vector3(0.2, 0.2, 0.03), Color.WHITE, Vector3(0, 0.05, 0.125), shield)
	emblem.material_override = gold
	emblem.rotation_degrees.z = 45
	var band := box(Vector3(0.5, 0.08, 0.055), Color.WHITE, Vector3(0, -0.2, 0.095), shield)
	band.material_override = cloth

func play_action(n: String, dur: float, spd: float) -> void:
	if hero_anim == null or not hero_anim.has_animation(n):
		return
	act_name = n
	act_t = dur
	hero_anim.play(n, 0.08, spd)
	hero_anim.seek(0.0, true)
	hero_cur = n

func update_hero_anim(dt: float) -> void:
	if hero_anim == null:
		return
	act_t = max(0.0, act_t - dt)
	var target := "idle"
	var spd := 1.0
	if P.dead > 0:
		target = "death"
	elif act_t > 0:
		return
	elif moving:
		target = "run" if hero_anim.has_animation("run") else "strafe"
		spd = 1.1
	if target != hero_cur:
		hero_anim.play(target, 0.15, spd)
		hero_cur = target
	# el paso lateral se gira para que las piernas vayan hacia donde corre
	hero_model.rotation.y = PI / 2 if target == "strafe" else 0.0

# ================================================================= MUNDO VIVO
# Reglas simples sobre una grilla: el pasto se quema y propaga el fuego; el agua conduce el rayo.
func build_living_world() -> void:
	# pasto alto: esconde al que está adentro y se puede quemar
	var r := RandomNumberGenerator.new()
	r.seed = 31
	for cp in camps:
		var camp: Vector2 = cp.pos
		for k in 2:
			var a := r.randf() * TAU
			var d := r.randf_range(10, 22)
			add_grass(camp.x + cos(a) * d, camp.y + sin(a) * d, r.randi_range(5, 9), r.randi_range(4, 7))
	# a los costados de los caminos, cerca de la capital
	for spot in [Vector2(-70, 30), Vector2(70, -30), Vector2(30, 80), Vector2(-30, -85), Vector2(120, 10), Vector2(-120, -10), Vector2(10, 140), Vector2(-90, -60)]:
		add_grass(spot.x, spot.y, r.randi_range(5, 8), r.randi_range(4, 6))
	finish_grass()
	add_puddle(150, -95, 4)
	add_puddle(-82, -122, 4)
	add_puddle(80, 132, 4)
	add_puddle(-160, 72, 3.5)
	add_puddle(60, 40, 3)

func ck(i: int, j: int) -> String:
	return "%d,%d" % [i, j]

func add_grass(cx: float, cz: float, w: int, h: int) -> void:
	var i0 := int(floor(cx / CELL - w / 2.0))
	var j0 := int(floor(cz / CELL - h / 2.0))
	for i in range(i0, i0 + w):
		for j in range(j0, j0 + h):
			if cells.has(ck(i, j)):
				continue
			var c := Cell.new()
			c.i = i
			c.j = j
			c.x = i * CELL + CELL / 2
			c.z = j * CELL + CELL / 2
			var p := Vector2(c.x, c.z)
			if terrain.height(c.x, c.z) < 0.8 or in_city(c.x, c.z, 3.0) or terrain.road_dist(p) < 2.5 or blocked(c.x, c.z, 0.3):
				continue
			c.base_y = terrain.height(c.x, c.z)
			c.tint = Color("#3f8a2e").lerp(Color("#5aa83c"), randf())
			c.idx = cell_list.size()
			cell_list.append(c)
			cells[ck(i, j)] = c

func add_puddle(x: float, z: float, r: float) -> void:
	var pd := Puddle.new()
	pd.x = x
	pd.z = z
	pd.r = r
	pd.node = MeshInstance3D.new()
	pd.node.mesh = disc_mesh()
	pd.mat = ind_mat(Color("#3d7cc9"), 0.85)
	pd.node.material_override = pd.mat
	pd.node.scale = Vector3(r, 1, r)
	pd.node.position = Vector3(x, H(x, z) + 0.06, z)
	pd.mat.no_depth_test = false
	world.add_child(pd.node)
	puddles.append(pd)

# mata de pasto: varias hojas finas, más oscuras abajo y claras arriba (el color lo pone cada instancia)
func tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rr := RandomNumberGenerator.new()
	rr.seed = 5
	for k in 14:
		var bx := rr.randf_range(-0.95, 0.95)
		var bz := rr.randf_range(-0.95, 0.95)
		var hgt := rr.randf_range(1.0, 1.6)
		var lean := Vector3(rr.randf_range(-0.3, 0.3), 0, rr.randf_range(-0.3, 0.3))
		var a := rr.randf() * TAU
		var side := Vector3(cos(a), 0, sin(a)) * 0.22
		var base := Vector3(bx, 0, bz)
		var tip := base + Vector3(0, hgt, 0) + lean
		for tri in [[base - side, base + side, tip]]:
			st.set_color(Color(0.55, 0.55, 0.55))
			st.add_vertex(tri[0])
			st.set_color(Color(0.55, 0.55, 0.55))
			st.add_vertex(tri[1])
			st.set_color(Color(1.15, 1.15, 1.15))
			st.add_vertex(tri[2])
	st.generate_normals()
	return st.commit()

func finish_grass() -> void:
	grass_mm = MultiMesh.new()
	grass_mm.transform_format = MultiMesh.TRANSFORM_3D
	grass_mm.use_colors = true
	grass_mm.mesh = tuft_mesh()
	grass_mm.instance_count = cell_list.size()
	for c in cell_list:
		set_cell(c, "grass")
	var gm := StandardMaterial3D.new()
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.roughness = 0.9
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = grass_mm
	mi.material_override = gm
	world.add_child(mi)

func cell_at(x: float, z: float) -> Cell:
	return cells.get(ck(int(floor(x / CELL)), int(floor(z / CELL))))

func set_cell(c: Cell, st: String) -> void:
	c.st = st
	var sy := 1.0
	var col := c.tint
	if st == "fire":
		sy = 1.1
		col = Color("#ff7a1a")
	elif st == "burnt":
		sy = 0.18
		col = Color("#3a2e24")
	elif st == "cut":
		sy = 0.22
		col = c.tint.lightened(0.15)
	var b := Basis(Vector3.UP, float(c.idx % 7)).scaled(Vector3(1.05, sy, 1.05))
	grass_mm.set_instance_transform(c.idx, Transform3D(b, Vector3(c.x, c.base_y - 0.05, c.z)))
	grass_mm.set_instance_color(c.idx, col)

func ignite(c) -> void:
	if c and c.st == "grass":
		set_cell(c, "fire")
		c.t = 3.2
		c.spread = 0.5

# cortar el pasto alto con ataques de espada (deja al descubierto al que se escondía)
func cut_grass(x: float, z: float, r: float) -> void:
	var n := 0
	for i in range(int(floor((x - r) / CELL)), int(floor((x + r) / CELL)) + 1):
		for j in range(int(floor((z - r) / CELL)), int(floor((z + r) / CELL)) + 1):
			var c = cells.get(ck(i, j))
			if c and c.st == "grass" and Vector2(c.x - x, c.z - z).length() <= r + CELL * 0.6:
				set_cell(c, "cut")
				c.t = 60.0
				n += 1
	if n > 0:
		flash_fx("ring", x, z, r, Vector2(0, 1), Color("#9ccf6a"))

func electrify(pd: Puddle) -> void:
	if pd.cool > 0:
		return
	pd.elec = 0.8
	pd.cool = 1.2
	flash_fx("ring", pd.x, pd.z, pd.r, Vector2(0, 1), Color("#fff27a"))
	var n := 0
	for m in mobs:
		if m.dead <= 0 and Vector2(m.x - pd.x, m.z - pd.z).length() < pd.r + m.d.r * 0.5:
			env_hit(m, 60, 1.0, Color("#fff27a"))
			n += 1
	if P and P.dead <= 0 and Vector2(P.x - pd.x, P.z - pd.z).length() < pd.r:
		hurt_player(35, "env")
	add_text(Vector3(pd.x, 2.5, pd.z), ("¡Electrocutados ×%d!" % n) if n > 0 else "¡Agua electrificada!", Color("#fff27a"), 16)

func element_at(x: float, z: float, el, r := 0.0) -> void:
	if el == "fuego":
		var i0 := int(floor((x - r) / CELL))
		var i1 := int(floor((x + r) / CELL))
		var j0 := int(floor((z - r) / CELL))
		var j1 := int(floor((z + r) / CELL))
		for i in range(i0, i1 + 1):
			for j in range(j0, j1 + 1):
				var c = cells.get(ck(i, j))
				if c and Vector2(c.x - x, c.z - z).length() <= r + CELL * 0.75:
					ignite(c)
	elif el == "rayo":
		for pd in puddles:
			if Vector2(pd.x - x, pd.z - z).length() < pd.r + r:
				electrify(pd)

func env_hit(m: Mob, dmg: float, stun: float, color: Color) -> void:
	if m.dead > 0:
		return
	dmg = round(dmg)
	m.hp -= dmg
	m.flash = 0.12
	m.hit_t = 0.0
	if stun > 0:
		m.stun_t = max(m.stun_t, stun)
		m.wind = 0
		clear_tele(m)
		if m.slam:
			m.slam.node.queue_free()
			m.slam = null
			m.special = 3
	add_text(Vector3(m.x, m.d.r * 2 + 1.6, m.z), str(int(dmg)), color, 14)
	if m.hp <= 0:
		kill(m)

func update_living(dt: float) -> void:
	var any_fire := false
	for c in cells.values():
		if c.st == "fire":
			any_fire = true
			c.t -= dt
			c.spread -= dt
			grass_mm.set_instance_color(c.idx, Color.from_hsv(0.03 + randf() * 0.06, 1.0, 1.0) * 1.3)
			if c.spread <= 0:
				c.spread = 99.0
				for dd in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					ignite(cells.get(ck(c.i + dd[0], c.j + dd[1])))
			if c.t <= 0:
				set_cell(c, "burnt")
				c.t = 40.0
		elif c.st == "burnt" or c.st == "cut":
			c.t -= dt
			if c.t <= 0:
				set_cell(c, "grass")          # el pasto vuelve a crecer
	if any_fire:
		for m in mobs:
			if m.dead > 0:
				continue
			var c = cell_at(m.x, m.z)
			if c and c.st == "fire":
				m.burn_acc += 40 * dt
				if m.burn_acc >= 12:
					var d: float = m.burn_acc
					m.burn_acc = 0
					env_hit(m, d, 0, Color("#ffa657"))
		if P and P.dead <= 0:
			var c = cell_at(P.x, P.z)
			if c and c.st == "fire":
				P.burn_t = 0.4
				P.burn_acc += 30 * dt
				if P.burn_acc >= 10:
					var d := P.burn_acc
					P.burn_acc = 0
					hurt_player(d, "env")
	if P:
		P.burn_t = max(0.0, P.burn_t - dt)
	for pd in puddles:
		pd.cool = max(0.0, pd.cool - dt)
		if pd.elec > 0:
			pd.elec -= dt
			pd.mat.albedo_color = Color(1, 0.95, 0.48, 0.9) if randf() < 0.5 else Color(0.6, 0.82, 1, 0.9)
		else:
			pd.mat.albedo_color = Color(0.24, 0.49, 0.79, 0.85)

func reset_living() -> void:
	for c in cells.values():
		set_cell(c, "grass")
	for pd in puddles:
		pd.elec = 0
		pd.cool = 0

# ================================================================= INTERFAZ
func flat_style(c: Color, radius := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = Color("#30363d")
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

func mk_label(text: String, size := 13, color := Color("#e6edf3")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func mk_button(text: String, cb: Callable, size := 13) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", flat_style(Color(0.13, 0.15, 0.18, 0.92)))
	b.add_theme_stylebox_override("hover", flat_style(Color(0.2, 0.22, 0.26, 0.95)))
	b.add_theme_stylebox_override("pressed", flat_style(Color(0.3, 0.27, 0.15, 0.95)))
	b.add_theme_stylebox_override("disabled", flat_style(Color(0.1, 0.1, 0.12, 0.6)))
	b.pressed.connect(cb)
	return b

func mk_bar(fill: Color) -> Array:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 15)
	bar.show_percentage = false
	bar.max_value = 100
	bar.add_theme_stylebox_override("background", flat_style(Color(0.09, 0.11, 0.13, 0.85), 7))
	var f := StyleBoxFlat.new()
	f.bg_color = fill
	f.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("fill", f)
	var l := mk_label("", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(l)
	return [bar, l]

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(draw_overlay)
	ui.add_child(overlay)
	# HUD
	var hud := VBoxContainer.new()
	hud.position = Vector2(12, 10)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("separation", 4)
	ui.add_child(hud)
	name_lbl = mk_label("", 17)
	sub_lbl = mk_label("", 11, Color(0.85, 0.88, 0.9))
	var hb = mk_bar(Color("#e5534b"))
	hp_bar = hb[0]
	hp_lbl = hb[1]
	var mb = mk_bar(Color("#d4a72c"))
	m_bar = mb[0]
	m_lbl = mb[1]
	chips_lbl = mk_label("", 11, Color("#f2cc60"))
	for n in [name_lbl, sub_lbl, hp_bar, m_bar, chips_lbl]:
		hud.add_child(n)
	# barra superior
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top.position += Vector2(-10, 10)
	ui.add_child(top)
	btn_pts = mk_button("Puntos (P)", open_pts)
	btn_oil = mk_button("Aceite: — (O)", cycle_oil)
	btn_xp = mk_button("XP ×%d" % xp_mult, cycle_xp)
	for b in [mk_button("Menú (I)", open_menu), btn_pts, btn_oil, btn_xp, mk_button("Cámara", reset_cam), mk_button("Clase", show_picker)]:
		top.add_child(b)
	# botones de habilidades
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.position += Vector2(-12, -12)
	ui.add_child(bar)
	for slot in ACT:
		var b := mk_button("", cast_from_button.bind(slot), 11)
		b.custom_minimum_size = Vector2(168, 58)
		b.clip_text = true
		skill_btns[slot] = b
		bar.add_child(b)
	# aviso
	toast_lbl = mk_label("", 16, Color("#f2cc60"))
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_lbl.position.y = 170
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.add_theme_stylebox_override("normal", flat_style(Color(0.09, 0.11, 0.13, 0.92)))
	toast_lbl.visible = false
	ui.add_child(toast_lbl)
	build_pts_panel()
	build_picker()
	menu = Menu.new()
	ui.add_child(menu)
	menu.setup(self)

func toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_lbl.visible = true
	toast_lbl.reset_size()
	toast_lbl.position.x = (get_viewport().get_visible_rect().size.x - toast_lbl.size.x) / 2
	toast_t = 2.4

func refresh_mastery() -> void:
	var p := pct(sk())
	var f := free_pts()
	m_bar.value = p
	m_lbl.text = "Maestría %.1f%%" % p + ("  ·  %d punto(s) libre(s)" % f if f > 0 else "")
	btn_pts.text = ("Puntos (%d)" % f) if f > 0 else "Puntos (P)"
	btn_pts.add_theme_color_override("font_color", Color("#f2cc60") if f > 0 else Color("#e6edf3"))

func update_ui() -> void:
	hp_bar.value = P.hp / P.max_hp * 100.0
	if P.dead > 0:
		hp_lbl.text = "Reaparecés en %d s" % ceil(P.dead)
	else:
		hp_lbl.text = "%d / %d" % [ceil(P.hp), P.max_hp] + ("  (+%d escudo)" % ceil(P.shield) if P.shield > 0 else "")
	var st := ""
	if P.camo:
		st = "Camuflado"
	elif P.hunt_t > 0:
		st = "Cacería ×%d" % P.hunt
	elif P.lifesteal_t > 0:
		st = "Robo de vida"
	elif P.burn_t > 0:
		st = "¡Te quemás!"
	elif P.hidden:
		st = "En el pasto: oculto"
	var ning := 0
	for f in ingredients:
		ning += int(ingredients[f])
	var nmin := 0
	for f in minerals:
		nmin += int(minerals[f])
	chips_lbl.text = "%s ✓   %s   Madera: %d   Ingredientes: %d   Minerales: %d   %s" % [weapon.passive.name, "Tejido ●" if P.weave > 0 else "Tejido ○", wood, ning, nmin, st]
	for slot in ACT:
		var b: Button = skill_btns[slot]
		var r := int(R()[slot])
		var lock := not unlocked(slot)
		var cd: float = P.cds[slot]
		var line2 := ""
		if lock:
			line2 = "🔒 75%" if (slot == "ult" and pct(sk()) < 75) else "🔒 asigná punto"
		elif cd > 0.05:
			line2 = "%.1f s" % cd
		else:
			line2 = "listo"
		b.text = "[%s] %s\nrango %d/%d · %s" % [KEYNAME[slot], weapon[slot].name, r, MAXR[slot], line2]
		b.modulate = Color(1, 1, 1, 0.5) if (lock or cd > 0.05) else Color(1, 1, 1, 1)

func cycle_oil() -> void:
	oil = "fuego" if oil == null else ("rayo" if oil == "fuego" else null)
	btn_oil.text = "Aceite: " + ("🔥 Fuego" if oil == "fuego" else ("⚡ Rayo" if oil == "rayo" else "—")) + " (O)"

func cycle_xp() -> void:
	xp_mult = 5 if xp_mult == 1 else (20 if xp_mult == 5 else 1)
	btn_xp.text = "XP ×%d" % xp_mult
	save_progress()

func reset_cam() -> void:
	if P:
		cam_yaw = atan2(-P.fx, -P.fz)
	cam_pitch = 0.95
	cam_dist = 20.0

# ----- panel de puntos
func build_pts_panel() -> void:
	pts_panel = PanelContainer.new()
	pts_panel.add_theme_stylebox_override("panel", flat_style(Color(0.09, 0.11, 0.13, 0.98), 14))
	pts_panel.custom_minimum_size = Vector2(460, 0)
	pts_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pts_panel.visible = false
	ui.add_child(pts_panel)
	pts_box = VBoxContainer.new()
	pts_box.add_theme_constant_override("separation", 8)
	pts_panel.add_child(pts_box)

func open_pts() -> void:
	if weapon.is_empty() or pick_panel.visible:
		return
	if pts_panel.visible:
		close_pts()
		return
	pts_was_running = running
	running = false
	basic_held = false
	pts_panel.visible = true
	render_pts()

func close_pts() -> void:
	pts_panel.visible = false
	running = pts_was_running
	refresh_mastery()

func render_pts() -> void:
	for c in pts_box.get_children():
		c.queue_free()
	var p := pct(sk())
	var r := R()
	pts_box.add_child(mk_label("Puntos de habilidad", 18))
	pts_box.add_child(mk_label("%s · %s · Maestría %.1f%% · Puntos libres: %d de %d" % [weapon.cls, weapon.style, p, free_pts(), total_pts(p)], 12, Color(0.8, 0.83, 0.86)))
	pts_box.add_child(mk_label("%s (pasiva): activa desde el 0%%." % weapon.passive.name, 12, Color("#f2cc60")))
	for k in ACT:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var cap := cap_for(k, p)
		var pips := ""
		for i in MAXR[k]:
			pips += "■" if i < int(r[k]) else ("□" if i < cap else "·")
		var why := ""
		if k == "ult":
			why = "se habilita al 75%" if p < 75 else "próximos rangos al 90% y 100%"
		else:
			why = "tope actual %d" % cap
		var bonus := ("  +%d%% daño" % round((rank_mult(k) - 1) * 100)) if int(r[k]) > 1 else ""
		var info := mk_label("%s: %s\n%s  rango %d/%d · %s%s" % [SLOTNAME[k], weapon[k].name, pips, int(r[k]), MAXR[k], why, bonus], 13)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var plus := mk_button("+", add_point.bind(k), 20)
		plus.custom_minimum_size = Vector2(44, 44)
		plus.disabled = not can_add(k)
		row.add_child(plus)
		pts_box.add_child(row)
	var foot := HBoxContainer.new()
	var rb := mk_button("Reiniciar reparto", reset_points)
	var cb := mk_button("Cerrar", close_pts)
	rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(rb)
	foot.add_child(cb)
	pts_box.add_child(foot)
	var note := mk_label("Cada 5% de maestría da 1 punto (21 en total). H1 llega a rango 8, H2 a 6, H3 a 4 y la definitiva a 3 (al 75%, 90% y 100%). Tope de las normales: 1 rango cada 12,5% de maestría. En el juego, el reparto se rehace cada 5 niveles; acá es libre para probar.", 11, Color(0.75, 0.78, 0.8))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(440, 0)
	pts_box.add_child(note)
	center_pts.call_deferred()

func center_pts() -> void:
	pts_panel.reset_size()
	pts_panel.position = (get_viewport().get_visible_rect().size - pts_panel.size) / 2.0

func add_point(k: String) -> void:
	if can_add(k):
		R()[k] = int(R()[k]) + 1
		save_progress()
		render_pts()

func reset_points() -> void:
	ranks_all[sk()] = {"s1": 1, "s2": 0, "s3": 0, "ult": 0}
	save_progress()
	render_pts()

# ----- selector de clase y arma
func build_picker() -> void:
	pick_panel = Panel.new()
	pick_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.07, 0.09, 0.96)
	pick_panel.add_theme_stylebox_override("panel", bg)
	ui.add_child(pick_panel)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24
	scroll.offset_top = 18
	scroll.offset_right = -24
	scroll.offset_bottom = -18
	pick_panel.add_child(scroll)
	pick_box = VBoxContainer.new()
	pick_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick_box.add_theme_constant_override("separation", 8)
	scroll.add_child(pick_box)

func show_picker() -> void:
	aim_slot = ""
	running = false
	basic_held = false
	pts_panel.visible = false
	pick_panel.visible = true
	for c in pick_box.get_children():
		c.queue_free()
	pick_box.add_child(mk_label("Demo de combate — MMORPG táctico", 22))
	var lead := mk_label("Vista estilo Metin2 con apuntado. El KIT sale de facción + clase + rareza (acá, Imperio · Inicial). El TIPO DE ARMA solo define el ataque básico: podés llevar cualquiera de tu facción, pero la natural de tu clase rinde mejor. La maestría es del estilo, no del arma.", 13, Color(0.8, 0.83, 0.86))
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pick_box.add_child(lead)
	pick_box.add_child(mk_label("FACCIÓN", 12, Color(0.6, 0.65, 0.7)))
	var fr := HFlowContainer.new()
	for f in Data.FACTIONS:
		var fl := mk_label(f.name + ("" if f.on else " · próximamente"), 13, Color("#f2cc60") if f.on else Color(0.5, 0.5, 0.5))
		fr.add_child(fl)
		fr.add_child(mk_label("   ", 13))
	pick_box.add_child(fr)
	pick_box.add_child(mk_label("ARMA (define el ataque básico)", 12, Color(0.6, 0.65, 0.7)))
	var wr := HFlowContainer.new()
	wr.add_theme_constant_override("h_separation", 6)
	var nb := mk_button(("● " if pick_w == null else "") + "Natural de cada clase", set_pick_w.bind(""))
	wr.add_child(nb)
	for k in Data.WTYPES:
		wr.add_child(mk_button(("● " if pick_w == k else "") + Data.WTYPES[k].name, set_pick_w.bind(k)))
	pick_box.add_child(wr)
	pick_box.add_child(mk_label("CLASE (define el kit) — tocá una para jugar", 12, Color(0.6, 0.65, 0.7)))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for c in Data.CLASSES:
		var wt: String = pick_w if pick_w != null else c.natural
		var nat: bool = wt == c.natural
		var r := ranks_of(c.id)
		var txt := "%s — %s\nInicial · Maestría %d%% · Empieza en %s\nArma: %s%s\n\nPasiva: %s\nH1 %s · r%d/8\nH2 %s · r%d/6\nH3 %s · r%d/4\nDef. %s · r%d/3" % [
			c.cls.to_upper(), c.style, int(pct(style_key(c.id))), CITIES[c.start].name, Data.WTYPES[wt].name, "" if nat else " (no natural: básico −40%)",
			c.passive.name, c.s1.name, r.s1, c.s2.name, r.s2, c.s3.name, r.s3, c.ult.name, r.ult]
		var b := mk_button(txt, choose.bind(c.id, wt), 12)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(300, 190)
		b.add_theme_color_override("font_color", c.color)
		grid.add_child(b)
	pick_box.add_child(grid)
	var help := mk_label("PC: WASD para moverte · clic izquierdo o Espacio = básico · mantené 1 2 3 4 (o Q E R F) para ver el indicador, apuntá con el mouse y soltá para lanzar (clic derecho cancela) · clic derecho y arrastrar = girar cámara · rueda = zoom · flechas = girar cámara · P = puntos · O = aceite.\nCombate: todo se puede esquivar. Los lobos avisan antes de morder, los arqueros marcan una línea roja y el ogro un círculo o un cono. Tras una habilidad, tu próximo básico pega +50% (Tejido).\nPasto alto: si estás adentro los enemigos no te ven (atacar te revela un momento). Muros: bloquean el paso, pero los dash, saltos y teletransportes los atraviesan.\nMundo vivo: el pasto alto se prende fuego, el fuego se propaga y quema a quien esté adentro (a vos también). Los charcos conducen el rayo y aturden a todos los que estén en el agua. Llevá a los lobos al pasto o al agua.", 12, Color(0.85, 0.85, 0.8))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pick_box.add_child(help)

func set_pick_w(k: String) -> void:
	pick_w = null if k == "" else k
	show_picker()

func choose(id: String, wt: String) -> void:
	var c: Dictionary = {}
	for cc in Data.CLASSES:
		if cc.id == id:
			c = cc
	var w: Dictionary = Data.WTYPES[wt]
	var nat_type: bool = w.phys == c.phys
	weapon = c.duplicate(true)
	weapon["wtype"] = wt
	weapon["wname"] = w.name
	weapon["natural"] = wt == c.natural
	weapon["basic"] = w.basic.duplicate(true)
	weapon.basic["dmg"] = round(float(w.basic.dmg) * (1.0 if nat_type else 0.6))
	spawn_player()
	spawn_mobs()
	reset_living()
	clear_effects()
	pick_panel.visible = false
	running = true
	name_lbl.text = "%s · %s" % [weapon.cls, weapon.style]
	name_lbl.add_theme_color_override("font_color", weapon.color)
	sub_lbl.text = "Imperio de la Luz · %s · Inicial · %s%s" % [CITIES[weapon.start].name, weapon.wname, "" if weapon.natural else " (no natural: básico −40%)"]
	refresh_mastery()
	if free_pts() > 0:
		toast("Tenés %d punto(s) para repartir (P)" % free_pts())

func clear_effects() -> void:
	for arr in [projs, blasts, zones, fxs]:
		for o in arr:
			if o.node:
				o.node.queue_free()
		arr.clear()
	texts.clear()

# ================================================================= ENTRADA
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and aim_slot != "":
				aim_slot = ""          # clic derecho cancela el apuntado
				return
			cam_drag = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and running and P and try_fast_travel(event.position):
				return
			basic_held = event.pressed and running
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_dist = clamp(cam_dist * 0.9, 8.0, 34.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_dist = clamp(cam_dist * 1.1, 8.0, 34.0)
	elif event is InputEventMouseMotion and cam_drag:
		cam_yaw -= event.relative.x * 0.006
		cam_pitch = clamp(cam_pitch + event.relative.y * 0.005, 0.35, 1.45)
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE:
			basic_held = event.pressed and running
			return
		if SLOT_KEYS.has(event.keycode):
			var slot: String = SLOT_KEYS[event.keycode]
			if event.echo:
				return
			if event.pressed:
				start_aim(slot)
			elif aim_slot == slot:
				aim_slot = ""
				cast_skill(slot, true)
			return
		if not event.pressed or event.echo:
			return
		match event.keycode:
			KEY_I, KEY_TAB:
				open_menu()
			KEY_P:
				open_pts()
			KEY_O:
				cycle_oil()
			KEY_ESCAPE:
				if pts_panel.visible:
					close_pts()

func start_aim(slot: String) -> void:
	if not running or P == null or P.dead > 0:
		return
	if not unlocked(slot):
		cast_skill(slot, true)        # muestra el aviso de bloqueada
		return
	aim_slot = slot

# no se puede entrar al agua profunda ni subir paredes de roca
func can_walk(x0: float, z0: float, x1: float, z1: float) -> bool:
	if blocked(x1, z1) and not blocked(x0, z0):
		return false
	var h1: float = terrain.height(x1, z1)
	if h1 < Terrain.WATER - 1.2 and bridge_top(x1, z1) == -INF:
		return false
	var rise: float = H(x1, z1) - H(x0, z0)
	var run: float = max(0.001, Vector2(x1 - x0, z1 - z0).length())
	return rise / run < 1.3

func cast_from_button(slot: String) -> void:
	cast_skill(slot, false)

func mouse_world() -> Vector2:
	# rayo desde la cámara hasta tocar el relieve
	var mp := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mp)
	var dir := camera.project_ray_normal(mp)
	var t := 0.0
	var prev := 0.0
	while t < 600.0:
		var q := from + dir * t
		if q.y <= H(q.x, q.z):
			var lo := prev
			var hi := t
			for k in 8:
				var mid := (lo + hi) * 0.5
				var qm := from + dir * mid
				if qm.y <= H(qm.x, qm.z):
					hi = mid
				else:
					lo = mid
			var hit := from + dir * hi
			return Vector2(hit.x, hit.z)
		prev = t
		t += 1.5 if t < 80.0 else 4.0
	return Vector2(P.x, P.z) if P else Vector2.ZERO

func cam_forward() -> Vector2:
	return Vector2(-sin(cam_yaw), -cos(cam_yaw))

# ================================================================= COMBATE: JUGADOR
func d2(ax: float, az: float, bx: float, bz: float) -> float:
	return Vector2(ax - bx, az - bz).length()

func nearest_mob(rng_: float, fx := INF, fz := INF) -> Mob:
	if fx == INF:
		fx = P.x
		fz = P.z
	var best: Mob = null
	var bd := INF
	for m in mobs:
		if m.dead > 0:
			continue
		var d: float = d2(fx, fz, m.x, m.z) - m.d.r
		if d < rng_ and d < bd:
			bd = d
			best = m
	return best

func face(dx: float, dz: float) -> void:
	var n := Vector2(dx, dz).normalized()
	if n.length() > 0:
		P.fx = n.x
		P.fz = n.y

func basic_range() -> float:
	return float(weapon.basic.range) + (3.0 if P.range_buff > 0 else 0.0)

func try_basic() -> void:
	var b: Dictionary = weapon.basic
	if P.cds.basic > 0 or P.dash or P.leap or P.dead > 0:
		return
	var pa := passive()
	if pa.effect == "chase" and P.chase > 0:
		var tt := nearest_mob(6.5)
		if tt and d2(P.x, P.z, tt.x, tt.z) - tt.d.r > b.range:
			var n := Vector2(tt.x - P.x, tt.z - P.z).normalized()
			var dd: float = d2(P.x, P.z, tt.x, tt.z) - tt.d.r - 1.2
			var ce := dash_end(P.x, P.z, P.x + n.x * dd, P.z + n.y * dd)
			start_dash(ce.x, ce.y, 0.14, {})
			P.chase = 0
			P.queued = tt
			return
	var t := nearest_mob(basic_range())
	if b.get("melee", false):
		if t == null:
			var mw := mouse_world()
			face(mw.x - P.x, mw.y - P.z)
			swing_fx()
			play_action("attack", 0.7, 2.6)
			damage_trees(P.x + P.fx * 1.6, P.z + P.fz * 1.6, b.range * 0.6, b.dmg)
			cut_grass(P.x + P.fx * 1.6, P.z + P.fz * 1.6, b.range * 0.6)
			if oil:
				element_at(P.x + P.fx * 2, P.z + P.fz * 2, oil, 1.2)
			P.cds.basic = b.cd
			return
		face(t.x - P.x, t.z - P.z)
		swing_fx()
		play_action("attack", 0.7, 2.6)
		hit_mob(t, b.dmg, {"basic": true, "el": oil})
		damage_trees(P.x + P.fx * 1.6, P.z + P.fz * 1.6, b.range * 0.6, b.dmg)
		cut_grass(P.x + P.fx * 1.6, P.z + P.fz * 1.6, b.range * 0.6)
	else:
		var d := Vector2.ZERO
		if t:
			d = Vector2(t.x - P.x, t.z - P.z).normalized()
		else:
			var mw := mouse_world()
			d = Vector2(mw.x - P.x, mw.y - P.z).normalized()
		face(d.x, d.y)
		var col := Color("#ff7a1a") if oil == "fuego" else (Color("#fff27a") if oil == "rayo" else Color.WHITE)
		fire_proj({"range": basic_range(), "speed": b.speed, "width": b.width, "dmg": b.dmg, "bounce_basic": b.get("bounce", false)}, d, {"basic": true, "el": oil, "color": col})
	P.cds.basic = b.cd / (1.3 if P.hunt_t > 0 else 1.0)

func resolve_aim(s: Dictionary, use_mouse: bool) -> Array:
	var Rr: float = s.get("range", s.get("radius", 6.0))
	if use_mouse:
		var mw := mouse_world()
		var v := Vector2(mw.x - P.x, mw.y - P.z)
		if v.length() > 0.3:
			return [v.normalized(), min(Rr, v.length())]
	var t := nearest_mob(Rr + 3)
	if t:
		var v := Vector2(t.x - P.x, t.z - P.z)
		return [v.normalized(), min(Rr, v.length())]
	return [Vector2(P.fx, P.fz), Rr]

func cast_skill(slot: String, use_mouse: bool) -> void:
	if not running or P == null or P.dead > 0:
		return
	var s: Dictionary = weapon[slot]
	if not unlocked(slot):
		toast(("%s: se habilita al 75%% de maestría" % s.name) if (slot == "ult" and pct(sk()) < 75) else ("%s: asigná un punto en Puntos (P)" % s.name))
		return
	if P.cds[slot] > 0 or P.dash or P.leap:
		return
	var aim := resolve_aim(s, use_mouse)
	var d: Vector2 = aim[0]
	var dd: float = aim[1]
	face(d.x, d.y)
	var opts := {"skill": true, "s": s}
	var col: Color = weapon.color
	var tdmg: float = float(s.get("dmg", 0)) * rank_mult(slot)
	match s.type:
		"cone":
			var half: float = deg_to_rad(s.angle) / 2.0
			var a0 := atan2(d.x, d.y)
			for m in mobs:
				if m.dead > 0:
					continue
				var vx: float = m.x - P.x
				var vz: float = m.z - P.z
				if Vector2(vx, vz).length() > s.range + m.d.r:
					continue
				if abs(angle_difference(atan2(vx, vz), a0)) <= half + 0.12:
					hit_mob(m, s.dmg, opts)
			flash_fx("sector:%d" % s.angle, P.x, P.z, s.range, d, col)
			damage_trees(P.x + d.x * s.range * 0.55, P.z + d.y * s.range * 0.55, s.range * 0.5, tdmg)
			if weapon.phys:
				cut_grass(P.x + d.x * s.range * 0.55, P.z + d.y * s.range * 0.55, s.range * 0.45)
			if s.has("el"):
				for pd in puddles:
					var L := d2(pd.x, pd.z, P.x, P.z)
					if L > s.range + pd.r:
						continue
					if abs(angle_difference(atan2(pd.x - P.x, pd.z - P.z), a0)) <= half + atan2(pd.r, max(1.0, L)):
						element_at(pd.x, pd.z, s.el, 0)
		"dash":
			var e := dash_end(P.x, P.z, P.x + d.x * s.range, P.z + d.y * s.range)
			start_dash(e.x, e.y, s.range / 40.0, s if s.dmg > 0 else {})
		"leap":
			var le := dash_end(P.x, P.z, P.x + d.x * dd, P.z + d.y * dd)
			var tx: float = le.x
			var tz: float = le.y
			P.leap = {"sx": P.x, "sz": P.z, "ex": tx, "ez": tz, "t": 0.0, "dur": 0.38, "s": s}
			var tel := telegraph(tx, tz, s.radius, 0.38, col)
			fxs.append(make_fx(tel, 0.38))
		"nova":
			for m in mobs:
				if m.dead <= 0 and d2(P.x, P.z, m.x, m.z) < s.radius + m.d.r:
					hit_mob(m, s.dmg, opts)
			flash_fx("disc", P.x, P.z, s.radius, d, col)
			damage_trees(P.x, P.z, s.radius, tdmg)
			if weapon.phys:
				cut_grass(P.x, P.z, s.radius)
		"line":
			var bl := Blast.new()
			bl.line = true
			bl.ox = P.x
			bl.oz = P.z
			bl.d = d
			bl.s = s
			bl.t = s.delay
			bl.node = telegraph_line(P.x, P.z, d, s.range, s.width, s.delay, col)
			blasts.append(bl)
			if s.get("buff", "") == "lifesteal":
				P.lifesteal = s.val
				P.lifesteal_t = s.dur
		"blast":
			var bl := Blast.new()
			bl.x = clamp(P.x + d.x * dd, -B, B)
			bl.z = clamp(P.z + d.y * dd, -B, B)
			bl.r = s.radius
			bl.s = s
			bl.t = s.delay
			bl.node = telegraph(bl.x, bl.z, s.radius, s.delay, col)
			blasts.append(bl)
		"proj":
			fire_proj(s, d, {"skill": true, "s": s, "color": col})
		"blink":
			var be := dash_end(P.x, P.z, P.x + d.x * dd, P.z + d.y * dd)
			var x: float = be.x
			var z: float = be.y
			flash_fx("ring", P.x, P.z, 1.5, d, col)
			P.x = x
			P.z = z
			flash_fx("ring", x, z, 1.5, d, col)
		"pull":
			for m in mobs:
				if m.dead <= 0 and d2(P.x, P.z, m.x, m.z) < s.radius + m.d.r:
					var n := Vector2(P.x - m.x, P.z - m.z).normalized()
					var dd2: float = max(0.0, d2(P.x, P.z, m.x, m.z) - m.d.r - 1.3)
					if not blocked(m.x + n.x * dd2, m.z + n.y * dd2, 0.3):
						m.x += n.x * dd2
						m.z += n.y * dd2
					hit_mob(m, s.dmg, opts)
			flash_fx("disc", P.x, P.z, s.radius, d, col)
			damage_trees(P.x, P.z, s.radius, tdmg)
		"smoke":
			var zn := Zone.new()
			zn.x = P.x
			zn.z = P.z
			zn.r = s.radius
			zn.t = s.dur
			zn.slow = s.slow
			var mi := ground_mesh(disc_mesh(), Color("#9aa0a6"), 0.45)
			mi.position = Vector3(P.x, H(P.x, P.z) + 0.07, P.z)
			mi.scale = Vector3(s.radius, 1, s.radius)
			zn.node = mi
			zn.mat = mi.material_override
			zones.append(zn)
		"auto3":
			var list := []
			for m in mobs:
				if m.dead <= 0 and d2(P.x, P.z, m.x, m.z) < s.range:
					list.append(m)
			list.sort_custom(func(a, b): return d2(P.x, P.z, a.x, a.z) < d2(P.x, P.z, b.x, b.z))
			list = list.slice(0, 3)
			for m in list:
				hit_mob(m, s.dmg, opts)
				beam_fx(P.x, P.z, m.x, m.z, Color("#fff2b3"))
			if list.is_empty():
				toast("No hay enemigos cerca")
		"buff":
			match s.buff:
				"shield":
					P.shield = s.val * rank_mult(slot)
					P.shield_t = s.dur
				"hunt":
					P.hunt = s.shots
					P.hunt_t = s.dur
					P.camo = true
				"heal":
					heal(P.max_hp * s.val * rank_mult(slot))
					P.speed_t = s.dur
			flash_fx("ring", P.x, P.z, 2.0, d, Color.WHITE)
	P.cds[slot] = skill_cd(slot)
	play_action("skill", 0.9, 2.0)
	P.weave = 3.0
	if passive().effect == "chase":
		P.chase = 3.0
	if not (s.type == "buff" and s.buff == "hunt"):
		break_camo()

func break_camo() -> void:
	if P.hunt_t > 0:
		return
	P.camo = false

func start_dash(ex: float, ez: float, dur: float, s: Dictionary) -> void:
	P.dash = {"sx": P.x, "sz": P.z, "ex": ex, "ez": ez, "t": 0.0, "dur": max(0.08, dur), "s": s, "hit": {}, "trees": {}}

func fire_proj(s: Dictionary, d: Vector2, o: Dictionary) -> void:
	var p := Proj.new()
	p.x = P.x
	p.z = P.z
	p.vx = d.x * s.speed
	p.vz = d.y * s.speed
	p.rng = s.range
	p.w = s.get("width", 0.5)
	p.s = s
	p.o = o
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = max(0.22, p.w * 0.5)
	sm.height = sm.radius * 2
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = o.get("color", Color.WHITE)
	mi.material_override = m
	mi.position = Vector3(p.x, H(p.x, p.z) + 1.2, p.z)
	world.add_child(mi)
	p.node = mi
	projs.append(p)

func heal(v: float) -> void:
	P.hp = min(P.max_hp, P.hp + v)

func hit_mob(m: Mob, base, o: Dictionary) -> void:
	var dmg := float(base)
	# gemas: ataque o magia según el arma, más el daño a monstruos
	dmg *= 1.0 + (gear.get("atk", 0) if weapon.phys else gear.get("mag", 0)) / 100.0 + gear.get("pve", 0) / 100.0
	var special := false
	var pa := passive()
	if o.get("basic", false):
		if P.weave > 0:
			dmg *= 1.5
			P.weave = 0
			special = true
		if P.camo and pa.effect == "camo" and P.hunt_t <= 0:
			dmg *= 1.5
			m.stun_t = max(m.stun_t, 0.6)
			special = true
			P.camo = false
		if P.hunt_t > 0 and P.hunt > 0:
			dmg *= 2.5
			P.hunt -= 1
			special = true
			if P.hunt <= 0:
				P.hunt_t = 0
				P.camo = false
		if pa.effect == "far":
			var k: float = min(1.0, d2(P.x, P.z, m.x, m.z) / 15.0)
			dmg *= 1.0 + 0.4 * k
			if k > 0.6:
				special = true
	var s: Dictionary = o.get("s", {})
	if o.get("skill", false) and not s.is_empty():
		dmg *= rank_mult(slot_of(s))
		if pa.effect == "mark" and m.mark > 0 and s.type == "cone":
			dmg *= 1.4
			special = true
		if m.void_mark > 0 and not s.get("void_mark", false):
			m.stun_t = max(m.stun_t, 0.6)
			m.void_mark = 0
			special = true
		if s.has("stun"):
			m.stun_t = max(m.stun_t, s.stun)
		if s.has("slow"):
			m.slow_v = s.slow
			m.slow_t = s.get("slow_dur", 2.0)
		if s.get("void_mark", false):
			m.void_mark = 3
		if pa.effect == "mark":
			m.mark = 4
	if not m.aggroed and m.state != "flee":
		dmg *= 2.0                       # ataque sigiloso: no te había visto (o dormía)
		special = true
		add_text(Vector3(m.x, m.d.r * 2 + 3.0, m.z), "¡Ataque sigiloso!", Color("#f2cc60"), 14)
	dmg = round(dmg)
	m.hp -= dmg
	m.flash = 0.12
	m.hit_t = 0.0
	m.wake_t = 0.0
	if m.d.temper == "timid":
		start_flee(m, 3.5)
	elif not m.aggroed and m.state != "flee":
		m.state = "idle"
		provoke(m)
		m.wake_t = 0.0
		m.state = "alert"
		m.aggroed = true
	P.reveal_t = 1.0                 # atacar desde el pasto te revela un momento
	P.calm = 0
	if s.has("stun"):
		if m.slam:
			m.slam.node.queue_free()
			m.slam = null
			m.special = 3
			add_text(Vector3(m.x, 3.5, m.z), "¡Interrumpido!", Color("#79c0ff"), 14)
		m.wind = 0
		clear_tele(m)
	if P.lifesteal_t > 0:
		heal(dmg * P.lifesteal)
	var el = o.get("el", s.get("el", null))
	if el and not o.get("no_el", false):
		element_at(m.x, m.z, el, 0.8)
	add_text(Vector3(m.x, m.d.r * 2 + 1.6, m.z), str(int(dmg)), Color("#f2cc60") if special else Color.WHITE, 19 if special else 15)
	if m.hp <= 0:
		kill(m)

func kill(m: Mob) -> void:
	if m.dead > 0:
		return
	m.dead = 7.0
	m.node.visible = false
	if m.d.ai == "brute" and m.camp >= 0:
		for o in mobs:
			if o.camp == m.camp and o.dead <= 0 and o.d.temper == "coward":
				start_flee(o, 5.0)       # cayó el jefe: los goblins salen corriendo
	if m.slam:
		m.slam.node.queue_free()
		m.slam = null
	clear_tele(m)
	flash_fx("ring", m.x, m.z, m.d.r * 2, Vector2(0, 1), Color("#f2cc60"))
	if m.d.temper != "timid" and randf() < 0.35:
		ingredients["Colmillo de monstruo"] = int(ingredients.get("Colmillo de monstruo", 0)) + 1
	var food: String = m.d.get("food", "")
	if food != "" and randf() < 0.6:
		ingredients[food] = int(ingredients.get(food, 0)) + 1
		add_text(Vector3(m.x, m.d.r * 2 + 3.4, m.z), "+ " + food, Color("#7ee787"), 13)
	var k := sk()
	var before := pct(k)
	var pts_b := total_pts(before)
	mastery[k] = min(XP_MAX, float(mastery.get(k, 0.0)) + m.d.xp * xp_mult)
	save_progress()
	var after := pct(k)
	if after > before:
		add_text(Vector3(m.x, m.d.r * 2 + 2.6, m.z), "+%d maestría" % (m.d.xp * xp_mult), Color("#f2cc60"), 12)
	var gained := total_pts(after) - pts_b
	if before < 75 and after >= 75:
		toast("¡Definitiva habilitada! Asigná el punto en Puntos (P)")
	elif gained > 0:
		toast("+%d punto de habilidad · abrí Puntos (P)" % gained)
	if before < 100 and after >= 100:
		toast("Estilo dominado: %s" % weapon.style)
	refresh_mastery()

func hurt_player(dmg: float, kind := "") -> void:
	if P.dead > 0:
		return
	if kind != "boss" and kind != "env":
		for zn in zones:
			if d2(zn.x, zn.z, P.x, P.z) < zn.r:
				add_text(Vector3(P.x, 3, P.z), "Esquivado", Color("#9aa0a6"), 12)
				return
	var pa := passive()
	if pa.effect == "block" and kind != "env":
		P.hits += 1
		if P.hits % 4 == 0:
			add_text(Vector3(P.x, 3, P.z), "Bloqueado", Color("#79c0ff"), 13)
			return
	dmg *= 1.0 - min(0.6, gear.get("def", 0) / 100.0)
	dmg = round(dmg)
	if P.shield > 0:
		var a: float = min(P.shield, dmg)
		P.shield -= a
		dmg -= a
	P.hp -= dmg
	P.calm = 0
	P.camo = false
	if dmg > 0:
		add_text(Vector3(P.x, 3, P.z), str(int(dmg)), Color("#ffa657") if kind == "env" else Color("#ff7b72"), 15)
	if P.hp <= 0:
		P.hp = 0
		P.dead = 4.0
		P.dash = null
		P.leap = null
		pnode.visible = false
		if pa.effect == "deathburst":
			for m in mobs:
				if m.dead <= 0 and d2(P.x, P.z, m.x, m.z) < 6:
					hit_mob(m, 140, {})
			flash_fx("disc", P.x, P.z, 6, Vector2(0, 1), Color("#fff2b3"))
		toast("Caíste. La maestría no se pierde.")
		for m in mobs:
			m.aggroed = false

# ================================================================= EFECTOS
func make_fx(node: Node3D, t: float, base_a := 0.5) -> Fx:
	var f := Fx.new()
	f.node = node
	f.t = t
	f.mx = t
	f.base_a = base_a
	return f

func flash_fx(kind: String, x: float, z: float, sc: float, d: Vector2, c: Color) -> void:
	var mesh: Mesh
	if kind == "disc":
		mesh = disc_mesh()
	elif kind == "ring":
		mesh = ring_mesh
	else:
		mesh = sector_mesh(float(kind.split(":")[1]))
	var mi := ground_mesh(mesh, c, 0.5)
	mi.position = Vector3(x, H(x, z) + 0.08, z)
	mi.scale = Vector3(sc, 0.05 if kind == "ring" else 1.0, sc)
	orient(mi, d.x, d.y)
	var f := make_fx(mi, 0.3)
	f.mats = [mi.material_override]
	fxs.append(f)

func telegraph(x: float, z: float, r: float, dur: float, c: Color) -> Node3D:
	var g := Node3D.new()
	world.add_child(g)
	g.position = Vector3(x, H(x, z) + 0.07, z)
	for spec in [[disc_mesh(), 0.18, r], [disc_mesh(), 0.38, 0.01], [ring_mesh, 0.8, r]]:
		var mi := MeshInstance3D.new()
		mi.mesh = spec[0]
		mi.material_override = ind_mat(c, spec[1])
		mi.scale = Vector3(spec[2], 0.05 if spec[0] == ring_mesh else 1.0, spec[2])
		g.add_child(mi)
	g.set_meta("inner", g.get_child(1))
	g.set_meta("r", r)
	g.set_meta("dur", dur)
	g.set_meta("t", 0.0)
	g.set_meta("line", false)
	return g

func telegraph_line(ox: float, oz: float, d: Vector2, L: float, w: float, dur: float, c: Color) -> Node3D:
	var g := Node3D.new()
	world.add_child(g)
	g.position = Vector3(ox, H(ox, oz) + 0.07, oz)
	orient(g, d.x, d.y)
	line_holder(w, L, c, 0.2, g)
	var inner := line_holder(w, 0.01, c, 0.45, g)
	g.set_meta("inner", inner)
	g.set_meta("L", L)
	g.set_meta("w", w)
	g.set_meta("dur", dur)
	g.set_meta("t", 0.0)
	g.set_meta("line", true)
	return g

func tele_progress(g: Node3D, dt: float) -> void:
	var t: float = g.get_meta("t") + dt
	g.set_meta("t", t)
	var k: float = min(1.0, t / max(0.01, g.get_meta("dur")))
	var inner: Node3D = g.get_meta("inner")
	if g.get_meta("line"):
		inner.scale = Vector3(g.get_meta("w"), 1, max(0.01, g.get_meta("L") * k))
	else:
		var r: float = g.get_meta("r") * k
		inner.scale = Vector3(max(0.01, r), 1, max(0.01, r))

func clear_tele(m: Mob) -> void:
	if m.tele:
		m.tele.queue_free()
		m.tele = null

func swing_fx() -> void:
	var mi := ground_mesh(sector_mesh(100), Color.WHITE, 0.35)
	mi.position = Vector3(P.x, H(P.x, P.z) + 0.09, P.z)
	var r: float = weapon.basic.range
	mi.scale = Vector3(r, 1, r)
	orient(mi, P.fx, P.fz)
	var f := make_fx(mi, 0.15, 0.35)
	f.mats = [mi.material_override]
	fxs.append(f)

func beam_fx(x1: float, z1: float, x2: float, z2: float, c: Color) -> void:
	var g := Node3D.new()
	world.add_child(g)
	g.position = Vector3(x1, 0.1, z1)
	orient(g, x2 - x1, z2 - z1)
	var h := line_holder(0.35, d2(x1, z1, x2, z2), c, 0.8, g)
	var f := make_fx(g, 0.2, 0.8)
	f.mats = [h.get_child(0).material_override]
	fxs.append(f)

func add_text(pos: Vector3, s: String, c: Color, size := 14) -> void:
	var t := FloatText.new()
	t.pos = pos + Vector3(0, H(pos.x, pos.z), 0)
	t.s = s
	t.color = c
	t.size = size
	texts.append(t)

# ================================================================= BUCLE
func _process(dt: float) -> void:
	dt = min(dt, 0.05)
	if toast_t > 0:
		toast_t -= dt
		if toast_t <= 0:
			toast_lbl.visible = false
	if running and P:
		update_game(dt)
	render_frame()
	overlay.queue_redraw()

func update_game(dt: float) -> void:
	var zc_ := zone_at(P.x, P.z)
	if zc_.name != cur_zone:
		if cur_zone != "":
			if zc_.tier >= 0:
				toast("%s · %s Nv %d–%d" % [zc_.name, Data.TIERS[zc_.tier].name, Data.TIERS[zc_.tier].lvl[0], Data.TIERS[zc_.tier].lvl[1]])
			else:
				toast("Entrás a %s · zona segura" % zc_.name)
		cur_zone = zc_.name
	for k in P.cds:
		P.cds[k] = max(0.0, P.cds[k] - dt)
	P.weave = max(0.0, P.weave - dt)
	P.chase = max(0.0, P.chase - dt)
	P.range_buff = max(0.0, P.range_buff - dt)
	P.speed_t = max(0.0, P.speed_t - dt)
	if P.lifesteal_t > 0:
		P.lifesteal_t -= dt
		if P.lifesteal_t <= 0:
			P.lifesteal = 0
	if P.hunt_t > 0:
		P.hunt_t -= dt
		if P.hunt_t <= 0:
			P.hunt = 0
			P.camo = false
	if P.shield_t > 0:
		P.shield_t -= dt
		if P.shield_t <= 0:
			P.shield = 0
	P.calm += dt
	P.reveal_t = max(0.0, P.reveal_t - dt)
	var gc = cell_at(P.x, P.z)
	P.hidden = gc != null and gc.st == "grass" and P.reveal_t <= 0 and P.dead <= 0
	var pa := passive()
	if pa.effect == "camo" and P.calm > 3 and not P.camo and P.dead <= 0:
		P.camo = true

	if P.dead > 0:
		P.dead -= dt
		if P.dead <= 0:
			var keep: Dictionary = P.cds.duplicate()
			spawn_player()
			P.cds = keep
	else:
		if P.calm > 4:
			heal(P.max_hp * 0.05 * dt)
		if P.dash:
			var D: Dictionary = P.dash
			D.t += dt
			var k: float = min(1.0, D.t / D.dur)
			P.x = lerp(D.sx, D.ex, k)
			P.z = lerp(D.sz, D.ez, k)
			var ds: Dictionary = D.s
			if not ds.is_empty():
				for m in mobs:
					if m.dead <= 0 and not D.hit.has(m) and d2(P.x, P.z, m.x, m.z) < ds.width / 2.0 + m.d.r:
						D.hit[m] = true
						hit_mob(m, ds.dmg, {"skill": true, "s": ds})
				damage_trees(P.x, P.z, max(0.8, ds.width / 2.0), float(ds.dmg) * rank_mult(slot_of(ds)), D.trees)
				if weapon.phys:
					cut_grass(P.x, P.z, max(0.8, ds.width / 2.0))
			if k >= 1:
				P.dash = null
				if P.queued and P.queued.dead <= 0:
					var t: Mob = P.queued
					face(t.x - P.x, t.z - P.z)
					swing_fx()
					hit_mob(t, weapon.basic.dmg, {"basic": true, "el": oil})
					P.cds.basic = weapon.basic.cd
				P.queued = null
		elif P.leap:
			var L: Dictionary = P.leap
			L.t += dt
			var k: float = min(1.0, L.t / L.dur)
			P.x = lerp(L.sx, L.ex, k)
			P.z = lerp(L.sz, L.ez, k)
			P.y = sin(k * PI) * 3.0
			if k >= 1:
				P.y = 0
				P.leap = null
				for m in mobs:
					if m.dead <= 0 and d2(P.x, P.z, m.x, m.z) < L.s.radius + m.d.r:
						hit_mob(m, L.s.dmg, {"skill": true, "s": L.s})
				flash_fx("disc", P.x, P.z, L.s.radius, Vector2(0, 1), weapon.color)
				damage_trees(P.x, P.z, L.s.radius, float(L.s.dmg) * rank_mult(slot_of(L.s)))
				cut_grass(P.x, P.z, L.s.radius)
		else:
			var ix := 0.0
			var iy := 0.0
			if Input.is_physical_key_pressed(KEY_D):
				ix += 1
			if Input.is_physical_key_pressed(KEY_A):
				ix -= 1
			if Input.is_physical_key_pressed(KEY_S):
				iy += 1
			if Input.is_physical_key_pressed(KEY_W):
				iy -= 1
			if Input.is_physical_key_pressed(KEY_LEFT):
				cam_yaw += 1.8 * dt
			if Input.is_physical_key_pressed(KEY_RIGHT):
				cam_yaw -= 1.8 * dt
			if Input.is_physical_key_pressed(KEY_UP):
				cam_pitch = clamp(cam_pitch + dt, 0.35, 1.45)
			if Input.is_physical_key_pressed(KEY_DOWN):
				cam_pitch = clamp(cam_pitch - dt, 0.35, 1.45)
			var l := Vector2(ix, iy).length()
			moving = l > 0.15
			if l > 0.15:
				var f := cam_forward()
				var r := Vector2(-f.y, f.x)
				var w := (r * ix + f * (-iy)).normalized()
				var sp: float = P.speed * (1.4 if P.speed_t > 0 else 1.0) * (1.1 if P.camo else 1.0)
				var nx: float = clamp(P.x + w.x * sp * dt, -B, B)
				var nz: float = clamp(P.z + w.y * sp * dt, -B, B)
				if can_walk(P.x, P.z, nx, nz):
					P.x = nx
					P.z = nz
				elif can_walk(P.x, P.z, nx, P.z):
					P.x = nx
				elif can_walk(P.x, P.z, P.x, nz):
					P.z = nz
				if not basic_held:
					P.fx = w.x
					P.fz = w.y
		if basic_held:
			try_basic()

	update_mobs(dt)
	update_projs(dt)
	update_blasts(dt)
	update_living(dt)
	update_trees(dt)
	update_ores(dt)
	update_world_life(dt)
	update_flora(dt)
	for i in range(zones.size() - 1, -1, -1):
		var zn: Zone = zones[i]
		zn.t -= dt
		zn.mat.albedo_color.a = min(0.45, zn.t * 0.3)
		if zn.t <= 0:
			zn.node.queue_free()
			zones.remove_at(i)
	for i in range(fxs.size() - 1, -1, -1):
		var f: Fx = fxs[i]
		f.t -= dt
		for m in f.mats:
			m.albedo_color.a = f.base_a * max(0.0, f.t / f.mx)
		if f.node.has_meta("dur"):
			tele_progress(f.node, dt)
		if f.t <= 0:
			f.node.queue_free()
			fxs.remove_at(i)
	for i in range(texts.size() - 1, -1, -1):
		var t: FloatText = texts[i]
		t.t -= dt
		t.pos.y += 1.6 * dt
		if t.t <= 0:
			texts.remove_at(i)
	cam_x += (P.x - cam_x) * min(1.0, dt * 8)
	cam_z += (P.z - cam_z) * min(1.0, dt * 8)
	update_ui()

func update_mobs(dt: float) -> void:
	var in_safe := in_city(P.x, P.z)
	for m in mobs:
		if m.dead > 0:
			m.dead -= dt
			if m.dead <= 0:
				m.x = m.sx
				m.z = m.sz
				m.hp = m.max_hp
				m.aggroed = false
				m.stun_t = 0
				m.slow_t = 0
				m.mark = 0
				m.void_mark = 0
				m.state = m.init_state
				m.sus = 0
				m.charge = null
				m.node.visible = true
			continue
		m.flash = max(0.0, m.flash - dt)
		m.mark = max(0.0, m.mark - dt)
		m.void_mark = max(0.0, m.void_mark - dt)
		if m.slow_t > 0:
			m.slow_t -= dt
		var zone_slow := 0.0
		for zn in zones:
			if d2(zn.x, zn.z, m.x, m.z) < zn.r:
				zone_slow = 0.4
		if m.stun_t > 0:
			m.stun_t -= dt
			continue
		var dP := d2(m.x, m.z, P.x, P.z)
		var home := d2(m.x, m.z, m.sx, m.sz)
		m.hit_t += dt
		var spd: float = m.d.speed * (1.0 - max(m.slow_v if m.slow_t > 0 else 0.0, zone_slow))
		if not think(m, dt, dP, home, in_safe, spd):
			continue
		if true:
			var n := Vector2(P.x - m.x, P.z - m.z).normalized()
			m.fx = n.x
			m.fz = n.y
			# troll: se regenera si hace rato que no lo golpeás
			if m.d.temper == "regen" and m.hit_t > 4.0 and m.hp < m.max_hp:
				m.hp = min(m.max_hp, m.hp + m.max_hp * 0.03 * dt)
			# espectro: se teletransporta a tu alrededor
			if m.d.temper == "ghost" and m.wind <= 0:
				m.blink_t -= dt
				if m.blink_t <= 0:
					m.blink_t = 4.5 + randf() * 2.0
					var a := randf() * TAU
					var q := Vector2(P.x, P.z) + Vector2(cos(a), sin(a)) * randf_range(7.0, 10.0)
					if not blocked(q.x, q.y, 0.6):
						flash_fx("ring", m.x, m.z, 1.5, Vector2(0, 1), Color("#8b7fd6"))
						m.x = q.x
						m.z = q.y
						flash_fx("ring", m.x, m.z, 1.5, Vector2(0, 1), Color("#8b7fd6"))
			# jabalí: embestida en línea
			if m.d.temper == "neutral":
				if m.charge:
					m.charge.t -= dt
					if m.charge.t > 0:
						tele_progress(m.charge.node, dt)
						continue
					var step: float = 15.0 * dt
					mob_step(m, m.charge.d.x * step, m.charge.d.y * step)
					m.charge.left -= step
					if not m.charge.hit and d2(m.x, m.z, P.x, P.z) < m.d.r + 1.0:
						m.charge.hit = true
						hurt_player(m.d.dmg * 1.6)
					if m.charge.left <= 0:
						m.charge.node.queue_free()
						m.charge = null
						m.atk_cd = 2.5
					continue
				m.atk_cd -= dt
				if m.atk_cd <= 0 and dP > 3.5 and dP < 12.0:
					m.charge = {"d": n, "t": 0.6, "left": 12.0, "hit": false, "node": telegraph_line(m.x, m.z, n, 12.0, 1.6, 0.6, Color("#f85149"))}
					continue
			# lobos: rodean y entran de a uno
			if m.d.temper == "pack" and m.wind <= 0 and m.atk_cd > 0:
				m.atk_cd -= dt
				var tang: Vector2 = Vector2(-n.y, n.x) * m.orbit
				var want: float = (dP - 5.0) * 0.6
				var mv: Vector2 = (tang + n * want).normalized()
				mob_step(m, mv.x * spd * 0.8 * dt, mv.y * spd * 0.8 * dt)
				continue
			if m.d.ai == "brute":
				if m.slam:
					m.slam.t -= dt
					tele_progress(m.slam.node, dt)
					if m.slam.t <= 0:
						if m.slam.kind == "circle" and dP < m.slam.r + 0.5:
							hurt_player(75 * m.mult, "boss")
						if m.slam.kind == "cone":
							if dP < m.slam.r + 0.5 and abs(angle_difference(atan2(P.x - m.x, P.z - m.z), m.slam.a)) < 0.6:
								hurt_player(45 * m.mult, "boss")
						flash_fx("disc" if m.slam.kind == "circle" else "sector:70", m.x, m.z, m.slam.r, Vector2(sin(m.slam.a), cos(m.slam.a)), Color("#f85149"))
						m.slam.node.queue_free()
						m.slam = null
						m.special = 3.5
					continue
				m.special -= dt
				if m.special <= 0 and dP < 9:
					if randf() < 0.5:
						m.slam = {"kind": "circle", "r": 5.5, "t": 1.15, "a": 0.0, "node": telegraph(m.x, m.z, 5.5, 1.15, Color("#f85149"))}
					else:
						var a := atan2(n.x, n.y)
						var g := Node3D.new()
						world.add_child(g)
						g.position = Vector3(m.x, H(m.x, m.z) + 0.07, m.z)
						orient(g, n.x, n.y)
						var outer := MeshInstance3D.new()
						outer.mesh = sector_mesh(70)
						outer.material_override = ind_mat(Color("#f85149"), 0.25)
						outer.scale = Vector3(7, 1, 7)
						g.add_child(outer)
						var inner := MeshInstance3D.new()
						inner.mesh = sector_mesh(70)
						inner.material_override = ind_mat(Color("#f85149"), 0.45)
						inner.scale = Vector3(0.01, 1, 0.01)
						g.add_child(inner)
						g.set_meta("inner", inner)
						g.set_meta("r", 7.0)
						g.set_meta("dur", 0.75)
						g.set_meta("t", 0.0)
						g.set_meta("line", false)
						m.slam = {"kind": "cone", "r": 7.0, "a": a, "t": 0.75, "node": g}
					continue
			if m.d.ai == "ranged":
				if m.wind > 0:
					m.wind -= dt
					if m.tele:
						tele_progress(m.tele, dt)
					if m.wind <= 0:
						enemy_shot(m, m.wind_dir)
						clear_tele(m)
						m.atk_cd = m.d.cd
					continue
				m.atk_cd -= dt
				if dP < m.d.range and m.atk_cd <= 0:
					m.wind = m.d.wind
					m.wind_dir = n
					m.tele = telegraph_line(m.x, m.z, n, m.d.range, 1.0, m.d.wind, Color("#f85149"))
				elif dP < 6:
					mob_step(m, -n.x * spd * dt, -n.y * spd * dt)
				elif dP > m.d.range - 1:
					mob_step(m, n.x * spd * dt, n.y * spd * dt)
				continue
			var reach: float = m.d.r + 0.7 + m.d.reach * 0.5
			if m.wind > 0:
				m.wind -= dt
				if m.wind <= 0:
					if d2(m.x, m.z, P.x, P.z) < reach + 0.8:
						hurt_player(m.d.dmg)
					m.atk_cd = m.d.cd + (randf_range(1.0, 2.5) if m.d.temper == "pack" else 0.0)
				continue
			m.atk_cd -= dt
			if dP < reach:
				if m.atk_cd <= 0:
					m.wind = m.d.wind
			else:
				mob_step(m, n.x * spd * dt, n.y * spd * dt)
	# separación entre enemigos
	for i in mobs.size():
		for j in range(i + 1, mobs.size()):
			var a: Mob = mobs[i]
			var b: Mob = mobs[j]
			if a.dead > 0 or b.dead > 0:
				continue
			var dx := b.x - a.x
			var dz := b.z - a.z
			var dd := Vector2(dx, dz).length()
			var mn: float = a.d.r + b.d.r
			if dd > 0 and dd < mn:
				var p := (mn - dd) / 2.0
				a.x -= dx / dd * p
				a.z -= dz / dd * p
				b.x += dx / dd * p
				b.z += dz / dd * p

# ----------------------------------------------------------------- comportamiento (estilo BotW)
# devuelve true si el bicho está en combate; si no, se ocupa de él (pasear, dormir, huir, buscar)
func think(m: Mob, dt: float, dP: float, home: float, in_safe: bool, spd: float) -> bool:
	var tp: String = m.d.temper
	# se fue muy lejos de casa, moriste o entraste a una ciudad: vuelve
	if m.aggroed and (P.dead > 0 or in_safe or home > 34.0):
		calm(m)
	# huir (animales tímidos, goblins y lobos heridos, jabalí casi muerto)
	if m.state == "flee":
		m.flee_t -= dt
		var away := Vector2(m.x - P.x, m.z - P.z).normalized()
		if home > 28.0:
			away = (away + Vector2(m.sx - m.x, m.sz - m.z).normalized()).normalized()
		mob_step(m, away.x * spd * 1.25 * dt, away.y * spd * 1.25 * dt)
		m.fx = away.x
		m.fz = away.y
		if m.flee_t <= 0:
			if tp == "timid" or m.hp < m.max_hp * 0.25:
				calm(m)
			else:
				m.state = "alert"         # se recompone y vuelve a la pelea
				m.aggroed = true
		return false
	if m.aggroed:
		# herido: algunos huyen
		if (tp == "coward" and m.hp < m.max_hp * 0.3) or (tp in ["pack", "neutral"] and m.hp < m.max_hp * 0.2):
			start_flee(m, 3.0)
			return false
		# te perdió en el pasto: va a buscarte adonde te vio por última vez
		if P.hidden and dP > 3.0:
			m.aggroed = false
			m.state = "search"
			m.search_t = 5.0
			m.last_seen = Vector2(P.x, P.z)
			add_text(Vector3(m.x, m.d.r * 2 + 2.0, m.z), "?", Color("#c9d1d9"), 18)
			return false
		m.last_seen = Vector2(P.x, P.z)
		return true
	if m.tele:
		clear_tele(m)
		m.wind = 0
	if m.charge:
		m.charge.node.queue_free()
		m.charge = null
	# despertando (gólem saliendo de la roca, campamento sobresaltado)
	if m.wake_t > 0:
		m.wake_t -= dt
		if m.wake_t <= 0:
			m.state = "alert"
			m.aggroed = true
		return false
	# percepción: rango según estado, pasto, camuflaje y si te acercás por la espalda
	var rad: float = m.d.aggro * (1.4 if m.sentinel else 1.0)
	match m.state:
		"rest":
			rad *= 0.35
		"dormant":
			rad = 6.0
		"search":
			rad *= 1.2
	if P.hidden:
		rad = min(rad, 2.5)
	if P.camo or P.dead > 0 or in_safe:
		rad = 0.0
	var toP := Vector2(P.x - m.x, P.z - m.z).normalized()
	if m.state != "dormant" and toP.dot(Vector2(m.fx, m.fz)) < -0.3:
		rad *= 0.6                           # de espaldas te ve menos
	if tp == "timid":
		if dP < rad:
			start_flee(m, 3.5)
		else:
			wander(m, dt, spd, home)
		return false
	if dP < rad:
		var gain: float = 1.2 + (1.0 - dP / maxf(rad, 0.1)) * 3.5
		if tp == "neutral":
			gain = 0.0                       # el jabalí te mira, pero no ataca si no lo provocás
			m.fx = toP.x
			m.fz = toP.y
		m.sus = min(1.0, m.sus + gain * dt)
	else:
		m.sus = max(0.0, m.sus - 0.5 * dt)
	if m.sus >= 1.0:
		provoke(m)
		return false
	match m.state:
		"rest", "dormant":
			pass
		"search":
			m.search_t -= dt
			var tgt := m.last_seen - Vector2(m.x, m.z)
			if tgt.length() > 1.0:
				var nn := tgt.normalized()
				mob_step(m, nn.x * spd * 0.7 * dt, nn.y * spd * 0.7 * dt)
				m.fx = nn.x
				m.fz = nn.y
			else:
				var a := m.search_t * 2.0           # mira para todos lados
				m.fx = sin(a)
				m.fz = cos(a)
			if m.search_t <= 0:
				calm(m)
		_:
			wander(m, dt, spd, home)
	return false

func wander(m: Mob, dt: float, spd: float, home: float) -> void:
	if home > 9.0:
		var nh := Vector2(m.sx - m.x, m.sz - m.z).normalized()
		mob_step(m, nh.x * spd * 1.2 * dt, nh.y * spd * 1.2 * dt)
		m.fx = nh.x
		m.fz = nh.y
		m.hp = min(m.max_hp, m.hp + m.max_hp * 0.25 * dt)
		return
	m.hp = min(m.max_hp, m.hp + m.max_hp * 0.25 * dt)
	m.wander_t -= dt
	if m.wander_t <= 0:
		m.wander_t = randf_range(3.0, 7.0)
		var a := randf() * TAU
		m.wx = m.sx + cos(a) * randf_range(0.0, 6.0)
		m.wz = m.sz + sin(a) * randf_range(0.0, 6.0)
	var d := Vector2(m.wx - m.x, m.wz - m.z)
	if d.length() > 0.6 and m.wander_t < 5.0:
		var nn := d.normalized()
		mob_step(m, nn.x * spd * 0.3 * dt, nn.y * spd * 0.3 * dt)
		m.fx = lerp(m.fx, nn.x, 0.1)
		m.fz = lerp(m.fz, nn.y, 0.1)

func calm(m: Mob) -> void:
	m.aggroed = false
	m.sus = 0.0
	m.state = "dormant" if m.init_state == "dormant" else "idle"
	m.flee_t = 0.0

func start_flee(m: Mob, t: float) -> void:
	if m.state != "flee":
		add_text(Vector3(m.x, m.d.r * 2 + 2.0, m.z), "¡!" if m.d.temper == "timid" else "¡Huye!", Color("#c9d1d9"), 14)
	m.state = "flee"
	m.flee_t = t
	m.aggroed = false

# te descubrió: "!" y, si vive en campamento o manada, avisa a los suyos
func provoke(m: Mob, chain := true) -> void:
	if m.aggroed or m.state == "flee" or m.wake_t > 0 or m.dead > 0:
		return
	m.sus = 1.0
	if m.d.temper == "timid":
		start_flee(m, 3.5)
		return
	if m.state == "dormant":
		m.wake_t = 1.4
		m.state = "waking"
		add_text(Vector3(m.x, m.d.r * 2 + 3.0, m.z), "¡%s despierta!" % m.d.name, Color("#f85149"), 16)
		return
	if m.state == "rest":
		m.wake_t = 0.8                     # se levanta medio dormido
		m.state = "waking"
		add_text(Vector3(m.x, m.d.r * 2 + 2.4, m.z), "¡!", Color("#f85149"), 20)
	else:
		m.state = "alert"
		m.aggroed = true
		add_text(Vector3(m.x, m.d.r * 2 + 2.4, m.z), "¡GRRR!" if m.d.temper == "territorial" else "!", Color("#f85149"), 22)
	if chain and m.camp >= 0 and m.d.temper in ["pack", "camp", "coward"]:
		if m.d.temper != "pack":
			add_text(Vector3(m.x, m.d.r * 2 + 3.6, m.z), "¡Alerta!", Color("#ff9b50"), 13)
		for o in mobs:
			if o != m and o.camp == m.camp and o.dead <= 0 and d2(o.x, o.z, m.x, m.z) < 35.0:
				provoke(o, false)

# los enemigos también chocan con muros: si no pueden pasar, se deslizan por el costado
func mob_step(m: Mob, dx: float, dz: float) -> void:
	var r: float = m.d.r * 0.6
	if not blocked(m.x + dx, m.z + dz, r):
		m.x += dx
		m.z += dz
	elif not blocked(m.x + dx, m.z, r):
		m.x += dx
	elif not blocked(m.x, m.z + dz, r):
		m.z += dz

func enemy_shot(m: Mob, d: Vector2) -> void:
	var p := Proj.new()
	p.enemy = true
	p.x = m.x
	p.z = m.z
	p.vx = d.x * 16
	p.vz = d.y * 16
	p.rng = m.d.range + 1
	p.dmg = m.d.dmg
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.6
	mi.mesh = sm
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = Color("#ff5544")
	mi.material_override = mt
	mi.position = Vector3(p.x, H(p.x, p.z) + 1.2, p.z)
	world.add_child(mi)
	p.node = mi
	projs.append(p)

func update_projs(dt: float) -> void:
	for i in range(projs.size() - 1, -1, -1):
		var p: Proj = projs[i]
		var sx := p.vx * dt
		var sz := p.vz * dt
		p.x += sx
		p.z += sz
		p.trav += Vector2(sx, sz).length()
		p.node.position = Vector3(p.x, H(p.x, p.z) + 1.2, p.z)
		var dead := p.trav >= p.rng
		if p.enemy:
			if P.dead <= 0 and d2(p.x, p.z, P.x, P.z) < 0.9:
				hurt_player(p.dmg)
				dead = true
		else:
			for m in mobs:
				if m.dead > 0 or p.hit.has(m):
					continue
				if d2(p.x, p.z, m.x, m.z) < m.d.r + p.w / 2.0:
					p.hit[m] = true
					var was_marked: bool = m.mark > 0
					var el = p.o.get("el", p.s.get("el", null))
					if p.s.has("explode"):
						var oo: Dictionary = p.o.duplicate()
						oo["no_el"] = true
						for o2 in mobs:
							if o2.dead <= 0 and d2(o2.x, o2.z, m.x, m.z) < p.s.explode:
								hit_mob(o2, p.s.dmg, oo)
						flash_fx("disc", m.x, m.z, p.s.explode, Vector2(0, 1), weapon.color)
						damage_trees(m.x, m.z, p.s.explode, p.s.dmg, null, true)
						if el:
							element_at(m.x, m.z, el, p.s.explode)
					else:
						hit_mob(m, p.s.dmg, p.o)
					if p.s.get("bounce_basic", false):
						var best: Mob = null
						var bd := 6.0
						for o2 in mobs:
							if o2.dead <= 0 and o2 != m and d2(o2.x, o2.z, m.x, m.z) < bd:
								bd = d2(o2.x, o2.z, m.x, m.z)
								best = o2
						if best:
							var ob: Dictionary = p.o.duplicate()
							ob["basic"] = false
							hit_mob(best, round(p.s.dmg * 0.5), ob)
							beam_fx(m.x, m.z, best.x, best.z, Color("#cfd8ff"))
					if p.s.get("range_buff", false):
						P.range_buff = 4
						P.speed_t = max(P.speed_t, 1.2)
					if p.s.get("bounce", false) and was_marked:
						var c := 0
						for o2 in mobs:
							if c >= 3:
								break
							if o2.dead <= 0 and o2 != m and d2(o2.x, o2.z, m.x, m.z) < 6:
								hit_mob(o2, p.s.dmg * 0.6, p.o)
								beam_fx(m.x, m.z, o2.x, o2.z, Color("#f6b26b"))
								c += 1
					dead = true
					break
			if not dead:
				var tr = tree_at(p.x, p.z)
				if tr:
					if p.s.has("explode"):
						damage_trees(p.x, p.z, p.s.explode, p.s.dmg, null, true)
						flash_fx("disc", p.x, p.z, p.s.explode, Vector2(0, 1), weapon.color)
					else:
						damage_trees(tr.x, tr.z, 0.1, p.s.dmg)
					dead = true
			if dead and p.hit.is_empty():
				var el2 = p.o.get("el", p.s.get("el", null))
				if el2:
					element_at(p.x, p.z, el2, p.s.get("explode", 0.8))
		if dead:
			p.node.queue_free()
			projs.remove_at(i)

func update_blasts(dt: float) -> void:
	for i in range(blasts.size() - 1, -1, -1):
		var b: Blast = blasts[i]
		b.t -= dt
		tele_progress(b.node, dt)
		if b.t > 0:
			continue
		if b.line:
			for m in mobs:
				if m.dead > 0:
					continue
				var vx: float = m.x - b.ox
				var vz: float = m.z - b.oz
				var along: float = vx * b.d.x + vz * b.d.y
				var perp: float = abs(vx * b.d.y - vz * b.d.x)
				if along > -1 and along < b.s.range + m.d.r and perp < b.s.width / 2.0 + m.d.r:
					hit_mob(m, b.s.dmg, {"skill": true, "s": b.s, "no_el": true})
			if b.s.has("el"):
				var t := 0.0
				while t <= b.s.range:
					element_at(b.ox + b.d.x * t, b.oz + b.d.y * t, b.s.el, b.s.width / 2.0)
					t += 1.5
			var once := {}
			var tl := 0.0
			while tl <= b.s.range:
				damage_trees(b.ox + b.d.x * tl, b.oz + b.d.y * tl, b.s.width / 2.0, float(b.s.dmg) * rank_mult(slot_of(b.s)), once)
				tl += 1.5
		else:
			var hits := []
			for m in mobs:
				if m.dead <= 0 and d2(b.x, b.z, m.x, m.z) < b.r + m.d.r:
					hits.append(m)
			for m in hits:
				var marked: bool = m.mark > 0
				hit_mob(m, b.s.dmg, {"skill": true, "s": b.s})
				if b.s.get("chain", false) and marked:
					var c := 0
					for o2 in mobs:
						if c >= 2:
							break
						if o2.dead <= 0 and o2 != m and d2(o2.x, o2.z, m.x, m.z) < 7:
							hit_mob(o2, b.s.dmg * 0.5, {"skill": true, "s": b.s})
							beam_fx(m.x, m.z, o2.x, o2.z, Color("#f6b26b"))
							c += 1
			flash_fx("disc", b.x, b.z, b.r, Vector2(0, 1), weapon.color)
			damage_trees(b.x, b.z, b.r, float(b.s.dmg) * rank_mult(slot_of(b.s)))
			if b.s.has("el"):
				element_at(b.x, b.z, b.s.el, b.r)
		b.node.queue_free()
		blasts.remove_at(i)

# ================================================================= DIBUJO
func render_frame() -> void:
	if P == null:
		camera.position = Vector3(30, 30, 30)
		camera.look_at(Vector3.ZERO)
		return
	pnode.position = Vector3(P.x, H(P.x, P.z) + P.y, P.z)
	pnode.rotation.y = atan2(P.fx, P.fz)
	pnode.visible = P.dead <= 0 or hero_model != null
	if running:
		update_hero_anim(get_process_delta_time())
	if hero_model:
		hero_model.visible = true
	var ghost: bool = P.camo or P.hidden
	for m in pmats:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if ghost else BaseMaterial3D.TRANSPARENCY_DISABLED
		m.albedo_color.a = (0.35 if P.camo else 0.55) if ghost else 1.0
	var aspas = world.get_node_or_null("Aspas")
	if aspas:
		aspas.rotation.z += get_process_delta_time() * 0.8
	var eng = world.get_node_or_null("Engranaje")
	if eng:
		eng.rotation.z += get_process_delta_time() * 0.4
	var aguja = world.get_node_or_null("AgujaReloj")
	if aguja:
		aguja.rotation.z -= get_process_delta_time() * 0.2
	for m in mobs:
		if m.dead > 0:
			continue
		m.node.position = Vector3(m.x, H(m.x, m.z), m.z)
		var sy := 1.0
		if m.state == "rest":
			sy = 0.72                    # sentado/durmiendo
		elif m.state == "dormant":
			sy = 0.55                    # hecho roca
		elif m.state == "waking":
			sy = lerp(1.0, 0.6, clamp(m.wake_t / 1.4, 0.0, 1.0))
		m.node.scale.y = lerp(m.node.scale.y, sy, 0.15)
		if m.d.temper == "ghost":
			var al: float = 0.85 if (m.aggroed or d2(P.x, P.z, m.x, m.z) < 11.0) else 0.12
			for mt in m.mats:
				mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mt.albedo_color.a = lerp(mt.albedo_color.a, al, 0.1)
		m.node.rotation.y = atan2(m.fx, m.fz)
		for i in m.mats.size():
			var base: Color = m.base_colors[i]
			base.a = m.mats[i].albedo_color.a
			if m.flash > 0:
				m.mats[i].albedo_color = base.lerp(Color.WHITE, 0.6)
			elif m.wind > 0 or m.slam:
				m.mats[i].albedo_color = base.lerp(Color("#ff3b30"), 0.35)
			else:
				m.mats[i].albedo_color = base
	var cx := cam_x + sin(cam_yaw) * cos(cam_pitch) * cam_dist
	var gy := H(cam_x, cam_z)
	var cy: float = max(gy + sin(cam_pitch) * cam_dist + 1.0, H(cam_x + sin(cam_yaw) * cos(cam_pitch) * cam_dist, cam_z + cos(cam_yaw) * cos(cam_pitch) * cam_dist) + 2.0)
	var cz := cam_z + cos(cam_yaw) * cos(cam_pitch) * cam_dist
	camera.position = Vector3(cx, cy, cz)
	camera.look_at(Vector3(cam_x, gy + 1.2, cam_z))
	# línea de apuntado hacia el cursor
	if running and P.dead <= 0:
		var mw := mouse_world()
		var v := Vector2(mw.x - P.x, mw.y - P.z)
		aim_line.visible = v.length() > 0.5
		aim_line.position = Vector3(P.x, H(P.x, P.z) + 0.06, P.z)
		aim_line.scale = Vector3(0.12, 1, min(v.length(), 25.0))
		orient(aim_line, v.x, v.y)
	else:
		aim_line.visible = false
	update_aim_indicator()

func draw_overlay() -> void:
	if P == null or pick_panel.visible:
		return
	var font := ThemeDB.fallback_font
	draw_minimap(font)
	for m in mobs:
		if m.dead > 0:
			continue
		var dpm: float = d2(P.x, P.z, m.x, m.z)
		var near: bool = dpm < 24.0
		if m.state == "dormant" or (m.d.temper == "ghost" and not m.aggroed and dpm > 11.0):
			continue                     # parece una roca / no se ve
		if dpm < 30.0 and not m.aggroed:
			var ip := Vector3(m.x, H(m.x, m.z) + m.d.r * 2 + 2.2, m.z)
			if not camera.is_position_behind(ip):
				var q := camera.unproject_position(ip)
				if m.state == "rest":
					overlay.draw_string_outline(font, q + Vector2(-20, -14), "Zzz", HORIZONTAL_ALIGNMENT_CENTER, 40, 13, 3, Color(0, 0, 0, 0.7))
					overlay.draw_string(font, q + Vector2(-20, -14), "Zzz", HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color("#c9d1d9"))
				if m.sus > 0.02:
					overlay.draw_rect(Rect2(q.x - 9, q.y - 40, 18, 22), Color(0, 0, 0, 0.55))
					overlay.draw_rect(Rect2(q.x - 9, q.y - 40 + 22 * (1.0 - m.sus), 18, 22 * m.sus), Color(0.95, 0.8, 0.38, 0.85))
					overlay.draw_string(font, Vector2(q.x - 9, q.y - 23), "?", HORIZONTAL_ALIGNMENT_CENTER, 18, 16, Color.WHITE)
		if m.hp >= m.max_hp and m.d.ai != "brute" and m.mark <= 0 and m.stun_t <= 0 and not near:
			continue
		var wp := Vector3(m.x, H(m.x, m.z) + m.d.r * 2 + 1.3, m.z)
		if camera.is_position_behind(wp):
			continue
		var p := camera.unproject_position(wp)
		var w := 70.0 if m.d.ai == "brute" else 38.0
		var tcol: Color = Data.TIERS[m.tier].color
		overlay.draw_string_outline(font, Vector2(p.x - 80, p.y - 6), "%s · Nv %d" % [m.d.name, m.lvl], HORIZONTAL_ALIGNMENT_CENTER, 160, 11, 3, Color(0, 0, 0, 0.8))
		overlay.draw_string(font, Vector2(p.x - 80, p.y - 6), "%s · Nv %d" % [m.d.name, m.lvl], HORIZONTAL_ALIGNMENT_CENTER, 160, 11, tcol)
		overlay.draw_rect(Rect2(p.x - w / 2, p.y, w, 5), Color(0, 0, 0, 0.6))
		overlay.draw_rect(Rect2(p.x - w / 2, p.y, w * max(0.0, m.hp) / m.max_hp, 5), Color("#f85149"))
		var tag := ""
		if m.stun_t > 0:
			tag += "✦ "
		if m.mark > 0:
			tag += "⚡"
		if m.void_mark > 0:
			tag += "◆"
		if tag != "":
			overlay.draw_string(font, Vector2(p.x - 50, p.y - 20), tag, HORIZONTAL_ALIGNMENT_CENTER, 100, 12, Color("#f2cc60"))
	var named := []
	for po in pois:
		named.append([po.name, po.x, po.z, po.r, 4.0, Color("#f0e6d2")])
	for sh in shrines:
		named.append([sh.name, sh.x, sh.z, 30.0, 5.0, Color("#7ec8ff") if sh.found else Color("#ffb070")])
	for tv in travelers:
		named.append([tv.name, tv.x, tv.z, 16.0, 2.6, Color("#f0e6d2")])
	for nm in named:
		if d2(P.x, P.z, nm[1], nm[2]) > nm[3]:
			continue
		var wp3 := Vector3(nm[1], H(nm[1], nm[2]) + nm[4], nm[2])
		if camera.is_position_behind(wp3):
			continue
		var q3 := camera.unproject_position(wp3)
		overlay.draw_string_outline(font, q3 + Vector2(-100, 0), nm[0], HORIZONTAL_ALIGNMENT_CENTER, 200, 13, 4, Color(0, 0, 0, 0.8))
		overlay.draw_string(font, q3 + Vector2(-100, 0), nm[0], HORIZONTAL_ALIGNMENT_CENTER, 200, 13, nm[5])
	for o in ores:
		if o.regrow > 0 or d2(P.x, P.z, o.x, o.z) > 14.0:
			continue
		var op := Vector3(o.x, H(o.x, o.z) + 2.3 * o.sc, o.z)
		if camera.is_position_behind(op):
			continue
		var q := camera.unproject_position(op)
		var od: Dictionary = Data.ORES[o.kind]
		overlay.draw_string_outline(font, q + Vector2(-70, 0), od.name, HORIZONTAL_ALIGNMENT_CENTER, 140, 11, 3, Color(0, 0, 0, 0.8))
		overlay.draw_string(font, q + Vector2(-70, 0), od.name, HORIZONTAL_ALIGNMENT_CENTER, 140, 11, od.gem.lightened(0.2))
		if o.hp < o.max:
			overlay.draw_rect(Rect2(q.x - 19, q.y + 4, 38, 4), Color(0, 0, 0, 0.6))
			overlay.draw_rect(Rect2(q.x - 19, q.y + 4, 38 * max(0.0, o.hp) / o.max, 4), od.gem)
	for t in texts:
		if camera.is_position_behind(t.pos):
			continue
		var p := camera.unproject_position(t.pos)
		var a: float = clamp(t.t * 2.0, 0.0, 1.0)
		var c: Color = t.color
		c.a = a
		overlay.draw_string_outline(font, Vector2(p.x - 100, p.y), t.s, HORIZONTAL_ALIGNMENT_CENTER, 200, t.size, 4, Color(0, 0, 0, a))
		overlay.draw_string(font, Vector2(p.x - 100, p.y), t.s, HORIZONTAL_ALIGNMENT_CENTER, 200, t.size, c)
	if in_city(P.x, P.z):
		var vw := get_viewport().get_visible_rect().size.x
		overlay.draw_string(font, Vector2(vw / 2 - 100, 120), "ZONA SEGURA", HORIZONTAL_ALIGNMENT_CENTER, 200, 13, Color("#58a6ff"))

func draw_minimap(font: Font) -> void:
	if minimap_tex == null:
		return
	var vw := get_viewport().get_visible_rect().size.x
	var sz := 190.0
	var o := Vector2(vw - sz - 12, 52)
	overlay.draw_rect(Rect2(o - Vector2(3, 3), Vector2(sz + 6, sz + 6)), Color(0.05, 0.07, 0.09, 0.85))
	overlay.draw_texture_rect(minimap_tex, Rect2(o, Vector2(sz, sz)), false)
	var to_map := func(x: float, z: float) -> Vector2:
		return o + Vector2((x + Terrain.HALF) / Terrain.SIZE, (z + Terrain.HALF) / Terrain.SIZE) * sz
	for cp in camps:
		overlay.draw_circle(to_map.call(cp.pos.x, cp.pos.y), 2.5, Data.TIERS[cp.tier].color)
	for sh in shrines:
		if sh.found:
			var sp: Vector2 = to_map.call(sh.x, sh.z)
			overlay.draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -5), sp + Vector2(4.5, 3.5), sp + Vector2(-4.5, 3.5)]), Color("#7ec8ff"))
	for m in mobs:
		if m.dead <= 0 and m.d.ai == "brute":
			overlay.draw_circle(to_map.call(m.x, m.z), 3.5, Color("#f85149"))
	for k in CITIES:
		var cc: Dictionary = CITIES[k]
		var c: Vector2 = to_map.call(cc.pos.x, cc.pos.y)
		overlay.draw_string(font, c + Vector2(-40, -8), cc.name, HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color.WHITE)
	var zn := zone_at(P.x, P.z)
	var ztxt: String = zn.name
	var zc := Color.WHITE
	if zn.tier >= 0:
		var T: Dictionary = Data.TIERS[zn.tier]
		ztxt = "%s · Nv %d–%d" % [zn.name, T.lvl[0], T.lvl[1]]
		zc = T.color
	overlay.draw_string_outline(font, Vector2(o.x, o.y + sz + 18), ztxt, HORIZONTAL_ALIGNMENT_CENTER, sz, 12, 3, Color(0, 0, 0, 0.8))
	overlay.draw_string(font, Vector2(o.x, o.y + sz + 18), ztxt, HORIZONTAL_ALIGNMENT_CENTER, sz, 12, zc)
	var pp: Vector2 = to_map.call(P.x, P.z)
	overlay.draw_circle(pp, 4.0, Color("#f2cc60"))
	overlay.draw_line(pp, pp + Vector2(P.fx, P.fz) * 9.0, Color("#f2cc60"), 2.0)

# acceso para pruebas automáticas
func debug_state() -> Dictionary:
	return {"hp": P.hp if P else 0, "free": free_pts() if not weapon.is_empty() else 0, "mobs": mobs.size(), "cells": cells.size()}
