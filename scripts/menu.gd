extends Control
# Menú de inventario al estilo BotW: pestañas arriba, grilla de objetos a la izquierda,
# el héroe en el centro, tus stats a la derecha y la descripción abajo.
# Se abre con I o Tab; Q/E (o las flechas) cambian de pestaña; Esc cierra.

const Data = preload("res://scripts/data.gd")
const GOLD := Color("#f2cc60")
const BG := Color(0.03, 0.05, 0.08, 0.95)
const SLOT_BG := Color(0.1, 0.12, 0.15, 0.85)

const TABS = ["Armas", "Equipo", "Gemas", "Oficio", "Materiales", "Comida"]

var m                      # el script principal (main.gd)
var tab := 1
var sel := 0
var items: Array = []      # lo que muestra la grilla en la pestaña actual
var tab_lbls: Array = []
var grid: GridContainer
var desc_title: Label
var desc_sub: Label
var desc_body: Label
var actions: HBoxContainer
var stats_box: VBoxContainer
var preview_vp: SubViewport
var preview_root: Node3D
var preview_anim: AnimationPlayer
var picking_slot := ""     # si estás eligiendo qué engarzar en una pieza
var prof_view := ""        # oficio que se muestra en la pestaña Oficio
var pot: Array = []        # olla del Cocinero (hasta 5 ingredientes)
var prof_bar: HBoxContainer

# ----------------------------------------------------------------- íconos dibujados
class Icon extends Control:
	var shape := "gema"
	var col := Color.WHITE
	var count := 0
	var mark := ""
	func _draw() -> void:
		var c := size / 2.0
		var r: float = min(size.x, size.y) * 0.32
		match shape:
			"gema":
				var pts := PackedVector2Array([c + Vector2(0, -r * 1.2), c + Vector2(r, -r * 0.2), c + Vector2(0, r * 1.2), c + Vector2(-r, -r * 0.2)])
				draw_colored_polygon(pts, col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 1.2), c + Vector2(r, -r * 0.2), c + Vector2(0, -r * 0.1)]), col.lightened(0.45))
				draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.6), 1.5)
			"piedra":
				var pts := PackedVector2Array()
				for k in 6:
					var a := TAU * k / 6.0 + 0.5
					pts.append(c + Vector2(cos(a), sin(a)) * r * 0.85)
				draw_colored_polygon(pts, col.darkened(0.15))
				draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.4), 1.5)
				draw_circle(c + Vector2(-r * 0.2, -r * 0.2), r * 0.18, col.lightened(0.5))
			"mineral":
				var pts := PackedVector2Array([c + Vector2(-r, r * 0.6), c + Vector2(-r * 0.6, -r * 0.5), c + Vector2(0, -r * 0.9), c + Vector2(r * 0.8, -r * 0.3), c + Vector2(r, r * 0.6)])
				draw_colored_polygon(pts, Color("#5f5a52"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, r * 0.2), c + Vector2(0, -r * 0.7), c + Vector2(r * 0.35, r * 0.2)]), col)
			"planta":
				draw_circle(c + Vector2(-r * 0.3, 0), r * 0.55, col)
				draw_circle(c + Vector2(r * 0.3, -r * 0.2), r * 0.5, col.lightened(0.15))
				draw_line(c + Vector2(0, r * 0.2), c + Vector2(0, r * 1.1), Color("#4f8f3a"), 3.0)
			"pieza":
				var pts := PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r * 0.9, r * 0.3), c + Vector2(0, r * 1.1), c + Vector2(-r * 0.9, r * 0.3)])
				draw_colored_polygon(pts, Color("#8a8070"))
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#d9cfb8"), 1.5)
				if col.a > 0:
					var g := PackedVector2Array([c + Vector2(0, -r * 0.6), c + Vector2(r * 0.4, 0), c + Vector2(0, r * 0.6), c + Vector2(-r * 0.4, 0)])
					draw_colored_polygon(g, col)
			"plato":
				draw_circle(c + Vector2(0, -r * 0.1), r * 0.85, col)
				draw_rect(Rect2(c + Vector2(-r, 0), Vector2(r * 2, r * 0.7)), Color("#6b4f33"))
				draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.25, col.lightened(0.3))
			"frasco":
				draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 1.1), Vector2(r * 0.4, r * 0.5)), Color("#d9cfb8"))
				draw_circle(c + Vector2(0, r * 0.25), r * 0.75, col)
				draw_circle(c + Vector2(-r * 0.25, 0), r * 0.18, Color(1, 1, 1, 0.6))
			"herramienta":
				draw_line(c + Vector2(-r, r), c + Vector2(r * 0.4, -r * 0.4), Color("#8a6a45"), 5.0)
				draw_rect(Rect2(c + Vector2(r * 0.1, -r * 1.0), Vector2(r * 0.9, r * 0.6)), col)
			"caballo":
				draw_circle(c + Vector2(0, r * 0.1), r * 0.7, col)
				draw_rect(Rect2(c + Vector2(r * 0.2, -r * 1.0), Vector2(r * 0.5, r * 0.9)), col)
				draw_rect(Rect2(c + Vector2(r * 0.1, -r * 1.0), Vector2(r * 0.12, r * 0.9)), col.darkened(0.4))
			"oficio":
				var pts := PackedVector2Array()
				for k in 10:
					var a := TAU * k / 10.0 - PI / 2
					pts.append(c + Vector2(cos(a), sin(a)) * (r * 1.1 if k % 2 == 0 else r * 0.5))
				draw_colored_polygon(pts, col)
			"arma":
				draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Color("#dfe6ee"), 5.0)
				draw_line(c + Vector2(-r * 0.6, r * 0.2), c + Vector2(-r * 0.2, r * 0.6), Color("#e8b84a"), 5.0)
		if count > 0:
			draw_string(get_theme_default_font(), Vector2(size.x - 26, size.y - 6), "×%d" % count, HORIZONTAL_ALIGNMENT_RIGHT, 22, 12, Color.WHITE)
		if mark != "":
			draw_string(get_theme_default_font(), Vector2(5, 15), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f2cc60"))

# ----------------------------------------------------------------- armado
func setup(main) -> void:
	m = main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	# pestañas
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 26)
	root.add_child(tabs)
	tabs.add_child(lbl("◀ Q", 13, Color(0.6, 0.65, 0.7)))
	for i in TABS.size():
		var b := Button.new()
		b.text = TABS[i]
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func(): set_tab(i))
		tabs.add_child(b)
		tab_lbls.append(b)
	tabs.add_child(lbl("E ▶", 13, Color(0.6, 0.65, 0.7)))
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.15)
	line.custom_minimum_size = Vector2(0, 1)
	root.add_child(line)
	# centro: grilla | héroe | stats
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(470, 0)
	left.add_theme_constant_override("separation", 8)
	mid.add_child(left)
	prof_bar = HBoxContainer.new()
	prof_bar.add_theme_constant_override("separation", 4)
	left.add_child(prof_bar)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var pv := SubViewportContainer.new()
	pv.stretch = true
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(pv)
	preview_vp = SubViewport.new()
	preview_vp.own_world_3d = true
	preview_vp.transparent_bg = true
	pv.add_child(preview_vp)
	build_preview_world()
	stats_box = VBoxContainer.new()
	stats_box.custom_minimum_size = Vector2(250, 0)
	stats_box.add_theme_constant_override("separation", 6)
	mid.add_child(stats_box)
	# descripción
	var dp := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0.45)
	st.set_corner_radius_all(6)
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	dp.add_theme_stylebox_override("panel", st)
	dp.custom_minimum_size = Vector2(0, 150)
	root.add_child(dp)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	dp.add_child(dv)
	desc_title = lbl("", 20, GOLD)
	desc_sub = lbl("", 13, Color(0.7, 0.75, 0.8))
	desc_body = lbl("", 14)
	desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	for n in [desc_title, desc_sub, desc_body, actions]:
		dv.add_child(n)
	visible = false

func lbl(t: String, sz := 14, c := Color("#e6edf3")) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	return l

func build_preview_world() -> void:
	preview_root = Node3D.new()
	preview_vp.add_child(preview_root)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.4, 4.4)
	cam.rotation.x = -0.12
	cam.fov = 40
	preview_root.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.3
	preview_root.add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.85)
	env.ambient_light_energy = 0.7
	we.environment = env
	preview_root.add_child(we)
	# pedestal con luz, como el fondo del menú de BotW
	var ped := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.1
	cm.height = 0.12
	ped.mesh = cm
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.15, 0.2, 0.28)
	pm.emission_enabled = true
	pm.emission = Color("#3a6fa0")
	pm.emission_energy_multiplier = 0.6
	ped.material_override = pm
	ped.position.y = -0.06
	preview_root.add_child(ped)

func refresh_preview() -> void:
	var old := preview_root.get_node_or_null("Heroe")
	if old:
		old.free()
	var holder := Node3D.new()
	holder.name = "Heroe"
	preview_root.add_child(holder)
	preview_anim = null
	var path := "res://assets/heroes/%s.glb" % m.weapon.id
	if ResourceLoader.exists(path):
		var h: Node3D = load(path).instantiate()
		h.scale = Vector3.ONE * 1.3
		holder.add_child(h)
		var mt: StandardMaterial3D = m.hero_material(Color("#b9b2a2").lerp(m.weapon.color, 0.3))
		for mi in h.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = mt
		var aps := h.find_children("*", "AnimationPlayer", true, false)
		if aps.size() > 0:
			preview_anim = aps[0]
			if preview_anim.has_animation("idle"):
				preview_anim.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
				preview_anim.play("idle")
	else:
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.4
		cap.height = 1.8
		body.mesh = cap
		var bm := StandardMaterial3D.new()
		bm.albedo_color = m.weapon.color
		body.material_override = bm
		body.position.y = 0.9
		holder.add_child(body)
	# las gemas engarzadas brillan alrededor del héroe
	var k := 0
	for sl in Data.SLOTS:
		var it = m.equipped.get(sl.id)
		if it:
			var g := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.08
			sm.height = 0.16
			g.mesh = sm
			var gm := StandardMaterial3D.new()
			var c: Color = item_color(it)
			gm.albedo_color = c
			gm.emission_enabled = true
			gm.emission = c
			gm.emission_energy_multiplier = 1.5
			g.material_override = gm
			var a := TAU * k / 6.0
			g.position = Vector3(cos(a) * 0.9, 1.0 + sin(a * 2.0) * 0.3, sin(a) * 0.9)
			holder.add_child(g)
		k += 1

func _process(dt: float) -> void:
	if not visible:
		return
	var h := preview_root.get_node_or_null("Heroe")
	if h:
		h.rotation.y += dt * 0.5

# ----------------------------------------------------------------- abrir / cerrar
func open() -> void:
	visible = true
	picking_slot = ""
	refresh_preview()
	set_tab(tab)

func close() -> void:
	visible = false
	m.menu_closed()

func open_prof(id: String) -> void:
	prof_view = id
	set_tab(3)

func set_tab(i: int) -> void:
	tab = wrapi(i, 0, TABS.size())
	picking_slot = ""
	sel = 0
	pot.clear()
	for j in tab_lbls.size():
		var b: Button = tab_lbls[j]
		b.add_theme_color_override("font_color", GOLD if j == tab else Color(0.75, 0.78, 0.82))
		b.add_theme_color_override("font_hover_color", GOLD)
		b.text = ("◆ " + TABS[j]) if j == tab else TABS[j]
	rebuild()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_I, KEY_TAB:
				if picking_slot != "" and event.keycode == KEY_ESCAPE:
					picking_slot = ""
					rebuild()
				else:
					close()
			KEY_Q:
				set_tab(tab - 1)
			KEY_E:
				set_tab(tab + 1)
			KEY_LEFT, KEY_A:
				move_sel(-1)
			KEY_RIGHT, KEY_D:
				move_sel(1)
			KEY_UP, KEY_W:
				move_sel(-grid.columns)
			KEY_DOWN, KEY_S:
				move_sel(grid.columns)
		get_viewport().set_input_as_handled()

func move_sel(d: int) -> void:
	if items.is_empty():
		return
	sel = clampi(sel + d, 0, items.size() - 1)
	highlight()
	describe()

# ----------------------------------------------------------------- contenido por pestaña
func item_color(it: Dictionary) -> Color:
	if it.kind == "piedra":
		return Data.CAT_COLORS.get(Data.PIEDRAS[it.id].cat, Color.WHITE)
	if it.kind == "gema":
		return Data.CAT_COLORS.get(gem_def(it.id).cat, Color.WHITE)
	return Color.WHITE

func gem_def(name: String) -> Dictionary:
	for g in Data.GEMAS:
		if g.name == name:
			return g
	return {}

func gather_items() -> Array:
	var out := []
	match TABS[tab]:
		"Armas":
			out.append({"kind": "arma", "name": m.weapon.wname, "shape": "arma", "col": Color.WHITE, "count": 0, "mark": "E"})
		"Equipo":
			if picking_slot != "":
				for it in m.owned_items():
					if m.fits_slot(it, picking_slot):
						out.append(it)
			else:
				for sl in Data.SLOTS:
					var it = m.equipped.get(sl.id)
					out.append({"kind": "slot", "slot": sl.id, "name": m.piece_name(sl.id), "shape": "pieza", "col": item_color(it) if it else Color(0, 0, 0, 0), "count": 0, "mark": ""})
		"Gemas":
			for it in m.owned_items():
				out.append(it)
		"Oficio":
			if not m.account_gm and m.prof == "":
				for pid in Data.OFICIOS:
					out.append({"kind": "oficio", "id": pid})
				return out
			if prof_view == "" or not m.has_prof(prof_view):
				prof_view = m.prof if m.prof != "" else "cocinero"
			match prof_view:
				"cocinero":
					for k in m.ingredients:
						var left_n: int = int(m.ingredients[k]) - pot.count(k)
						if int(m.ingredients[k]) > 0 and Data.INGREDIENTES.has(k):
							out.append({"kind": "ing", "id": k, "count": left_n})
				"alquimista":
					for pid in Data.PIEDRAS:
						out.append({"kind": "piedra", "id": pid, "count": int(m.piedras.get(pid, 0)), "recipe": true})
					for dn in Data.DESTILADOS:
						out.append({"kind": "destilado", "id": dn, "count": int(m.destilados.get(dn, 0)), "recipe": true})
				"joyero":
					out.append({"kind": "lupa"})
					for g in Data.GEMAS:
						out.append({"kind": "gema", "id": g.name, "count": int(m.gemas.get(g.name, 0)), "craft": true})
				"armero":
					for i in Data.APARIENCIAS.size():
						out.append({"kind": "apariencia", "i": i})
				"criador":
					out.append({"kind": "silbato"})
					for i in m.horses_owned.size():
						out.append({"kind": "caballo", "i": i})
				"constructor":
					for cn in Data.CONSTRUCCIONES:
						out.append({"kind": "construccion", "id": cn})
		"Materiales":
			for k in m.minerals:
				if int(m.minerals[k]) > 0:
					out.append({"kind": "mineral", "id": k, "count": int(m.minerals[k])})
		"Comida":
			for k in m.platos:
				out.append({"kind": "plato", "id": k, "count": int(m.platos[k].n)})
			for k in m.ingredients:
				if int(m.ingredients[k]) > 0:
					out.append({"kind": "comida", "id": k, "count": int(m.ingredients[k])})
	return out

func rebuild() -> void:
	for c in grid.get_children():
		c.queue_free()
	items = gather_items()
	build_prof_bar()
	grid.columns = 3 if TABS[tab] == "Equipo" and picking_slot == "" else 5
	for i in items.size():
		var it: Dictionary = items[i]
		var cell := Button.new()
		cell.focus_mode = Control.FOCUS_NONE
		var big: bool = it.kind == "slot"
		cell.custom_minimum_size = Vector2(140, 120) if big else Vector2(84, 84)
		cell.add_theme_stylebox_override("normal", cell_style(false))
		cell.add_theme_stylebox_override("hover", cell_style(true))
		cell.add_theme_stylebox_override("pressed", cell_style(true))
		cell.pressed.connect(func(): click(i))
		cell.mouse_entered.connect(func():
			sel = i
			highlight()
			describe())
		var ic := Icon.new()
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.count = int(it.get("count", 0))
		match it.kind:
			"gema":
				ic.shape = "gema"
				ic.col = item_color(it)
				if it.get("craft", false):
					if m.can_combine(it.id):
						ic.mark = "+"
					elif ic.count == 0:
						ic.modulate = Color(1, 1, 1, 0.3)
			"piedra":
				ic.shape = "piedra"
				ic.col = item_color(it)
				if it.get("recipe", false) and ic.count == 0:
					ic.modulate = Color(1, 1, 1, 0.45 if m.can_carve(it.id) else 0.2)
				if it.get("recipe", false) and m.can_carve(it.id):
					ic.mark = "+"
			"mineral":
				ic.shape = "mineral"
				ic.col = Data.MINERAL_COLORS.get(it.id, Color.WHITE)
			"comida":
				ic.shape = "planta"
				ic.col = Color("#7ee787")
			"slot", "arma":
				ic.shape = it.shape
				ic.col = it.col
			"ing":
				ic.shape = "planta"
				ic.col = Color("#e8822a") if Data.INGREDIENTES[it.id].type == "carne" else Color("#7ee787")
				if ic.count <= 0:
					ic.modulate = Color(1, 1, 1, 0.3)
			"plato":
				ic.shape = "plato"
				ic.col = Color("#e8b84a")
			"destilado":
				ic.shape = "frasco"
				ic.col = {"Aceite de fuego": Color("#ff7b54"), "Aceite de rayo": Color("#f2cc60"), "Carga del frasco": Color("#ff6b8b")}[it.id]
				if m.has_all(Data.DESTILADOS[it.id].recipe):
					ic.mark = "+"
				elif ic.count == 0:
					ic.modulate = Color(1, 1, 1, 0.35)
			"lupa":
				ic.shape = "herramienta"
				ic.col = Color("#7ee7ff") if m.sense_ores else Color("#9aa0a6")
			"apariencia":
				var ap: Dictionary = Data.APARIENCIAS[it.i]
				ic.shape = "pieza"
				ic.col = Color(0, 0, 0, 0)
				if ap.name in m.wardrobe:
					ic.mark = "✓"
				elif m.has_all(ap.recipe):
					ic.mark = "+"
				else:
					ic.modulate = Color(1, 1, 1, 0.4)
			"silbato":
				ic.shape = "herramienta"
				ic.col = Color("#e8b84a")
			"caballo":
				ic.shape = "caballo"
				ic.col = Color(m.horses_owned[it.i].col)
			"construccion":
				ic.shape = "herramienta"
				ic.col = Color("#bdb39a")
				if m.has_all(Data.CONSTRUCCIONES[it.id].recipe):
					ic.mark = "+"
				else:
					ic.modulate = Color(1, 1, 1, 0.4)
			"oficio":
				ic.shape = "oficio"
				ic.col = GOLD
		cell.add_child(ic)
		if it.kind == "oficio":
			var ol := lbl(Data.OFICIOS[it.id].name, 12, GOLD)
			ol.position = Vector2(4, 62)
			cell.add_child(ol)
		if big:
			var nl := lbl(Data.SLOTS.filter(func(s): return s.id == it.slot)[0].name, 12, Color(0.75, 0.78, 0.82))
			nl.position = Vector2(8, 4)
			cell.add_child(nl)
			var eq = m.equipped.get(it.slot)
			var gl := lbl(item_name(eq) if eq else "— vacío —", 11, GOLD if eq else Color(0.5, 0.55, 0.6))
			gl.position = Vector2(8, 98)
			gl.size = Vector2(124, 18)
			gl.clip_text = true
			cell.add_child(gl)
		grid.add_child(cell)
	refresh_stats()
	await get_tree().process_frame
	highlight()
	describe()

func cell_style(on: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = SLOT_BG.lightened(0.08) if on else SLOT_BG
	s.set_corner_radius_all(4)
	s.set_border_width_all(2 if on else 1)
	s.border_color = GOLD if on else Color(1, 1, 1, 0.12)
	return s

func highlight() -> void:
	var cs := grid.get_children()
	for i in cs.size():
		var on := i == sel
		cs[i].add_theme_stylebox_override("normal", cell_style(on))

func item_name(it) -> String:
	if it == null:
		return ""
	match it.kind:
		"piedra":
			return Data.PIEDRAS[it.id].name
		"gema", "mineral", "comida":
			return it.id
	return str(it.get("name", ""))

func clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()

func act(text: String, cb: Callable, enabled := true) -> void:
	var b: Button = m.mk_button(text, cb, 14)
	b.disabled = not enabled
	actions.add_child(b)

func stats_text(st: Dictionary) -> String:
	var parts := []
	for k in st:
		parts.append("+%d%s %s" % [st[k], "" if k == "hp" else "%", Data.STAT_NAMES.get(k, k)])
	return ", ".join(parts)

func describe() -> void:
	clear_actions()
	desc_title.text = ""
	desc_sub.text = ""
	desc_body.text = ""
	if items.is_empty():
		match TABS[tab]:
			"Oficio":
				desc_body.text = "No tenés ingredientes. Juntá hierbas, verduras y hongos, o cazá monstruos que se comen."
			"Materiales":
				desc_body.text = "Todavía no tenés minerales. Rompé vetas con ataques (los golpes pesados y las explosiones rompen el doble)."
			"Comida":
				desc_body.text = "Todavía no juntaste nada. Pasá por encima de hierbas, hongos y verduras, o cazá monstruos que se comen."
			"Gemas":
				desc_body.text = "No tenés gemas ni piedras. En Alquimia tallás piedras con minerales; dos o tres piedras se combinan en una gema."
			"Equipo":
				desc_body.text = "No tenés nada que entre en esta pieza."
				act("Volver", func():
					picking_slot = ""
					rebuild())
		return
	var it: Dictionary = items[clampi(sel, 0, items.size() - 1)]
	match it.kind:
		"arma":
			desc_title.text = m.weapon.wname
			desc_sub.text = "%s · %s · %s" % [m.weapon.cls, m.weapon.style, "arma natural" if m.weapon.natural else "no natural: básico −40%"]
			desc_body.text = "Básico: %d de daño. El arma define tu ataque básico; las habilidades vienen del estilo. Cambiás de arma desde «Clase»." % m.weapon.basic.dmg
		"slot":
			var sl: Dictionary = Data.SLOTS.filter(func(s): return s.id == it.slot)[0]
			var eq = m.equipped.get(it.slot)
			desc_title.text = m.piece_name(it.slot)
			desc_sub.text = "%s · la pieza es solo apariencia; el poder está en lo que engarzás%s" % [sl.name, " · solo Movimiento" if it.slot == "pies" else ""]
			if eq:
				desc_body.text = "Engarzada: %s — %s" % [item_name(eq), stats_text(m.item_stats(eq))]
				act("Cambiar", pick.bind(it.slot))
				act("Quitar", func():
					m.unequip(it.slot)
					refresh_preview()
					rebuild())
			else:
				desc_body.text = "Sin gema. Engarzá una gema o una piedra suelta."
				act("Engarzar", pick.bind(it.slot))
			act("Cambiar apariencia", func():
				m.cycle_look(it.slot)
				rebuild())
		"piedra":
			var pd: Dictionary = Data.PIEDRAS[it.id]
			desc_title.text = pd.name
			desc_sub.text = "Piedra básica · %s · %s" % [pd.cat, stats_text(Data.STONE_STATS[it.id])]
			var rec := []
			for mn in pd.recipe:
				rec.append("%s (%d)" % [mn, m.material_count(mn)])
			desc_body.text = "Receta: " + " + ".join(rec) + ". Se puede engarzar suelta (sin pasiva) o combinar en una gema."
			if picking_slot != "":
				act("Engarzar", equip_here.bind(it))
			elif TABS[tab] == "Oficio":
				act("Tallar", func():
					m.carve(it.id)
					rebuild(), m.can_carve(it.id))
			else:
				act("Engarzar en…", func(): set_tab_equipo())
		"gema":
			var g := gem_def(it.id)
			desc_title.text = g.name
			var st: Dictionary = m.item_stats(it)
			desc_sub.text = "Gema · %s · %s" % [g.cat, stats_text(st)]
			var ps := []
			for pid in g.stones:
				ps.append("%s (%d)" % [Data.PIEDRAS[pid].name, int(m.piedras.get(pid, 0))])
			desc_body.text = "Pasiva: %s\nSe arma con: %s" % [g.passive, " + ".join(ps)]
			if picking_slot != "":
				act("Engarzar", equip_here.bind(it))
			elif TABS[tab] == "Oficio":
				act("Combinar", func():
					m.combine(g.name)
					rebuild(), m.can_combine(g.name))
			else:
				act("Engarzar en…", func(): set_tab_equipo())
		"mineral":
			desc_title.text = it.id
			desc_sub.text = "Mineral · tenés %d" % it.count
			var uses := []
			for pid in Data.PIEDRAS:
				if it.id in Data.PIEDRAS[pid].recipe:
					uses.append(Data.PIEDRAS[pid].name)
			desc_body.text = ("Sirve para: " + ", ".join(uses)) if uses.size() > 0 else "Catalizador: sirve para subir gemas de nivel (y lo usan otros oficios)."
		"comida":
			desc_title.text = it.id
			var ing: Dictionary = Data.INGREDIENTES.get(it.id, {})
			desc_sub.text = "Ingrediente · tenés %d%s" % [it.count, (" · cura %d" % ing.heal) if ing.has("heal") else ""]
			var fxt: String = ("Al cocinarlo: " + Data.FX_NAMES[ing.fx] + " (" + Data.FX_DESC[ing.fx] + ").") if ing.has("fx") else ""
			desc_body.text = fxt + (" " if fxt != "" else "") + "Crudo cura poco; asado en una fogata cura más; cocinado con otros (Cocinero) da efectos."
			if ing.has("heal"):
				act("Comer crudo", func():
					m.eat(it.id, true)
					rebuild())
				act("Asar", func():
					m.roast(it.id)
					rebuild(), m.near_fire())
		"plato":
			var pd: Dictionary = m.platos[it.id]
			desc_title.text = it.id
			desc_sub.text = "Plato · tenés %d · cura %d" % [it.count, pd.heal]
			desc_body.text = ("Efecto: %s, %s por %d s (solo PvE)." % [Data.FX_NAMES[pd.fx], Data.FX_DESC[pd.fx], int(pd.dur)]) if pd.fx != "" and pd.fx != "curacion" else "Sin efecto extra."
			act("Comer", func():
				m.eat(it.id)
				rebuild())
		"ing":
			var ing2: Dictionary = Data.INGREDIENTES[it.id]
			desc_title.text = "Olla de campaña"
			var pv: Dictionary = m.cook_preview(pot)
			desc_sub.text = "En la olla (%d/5): %s" % [pot.size(), ", ".join(pot) if pot.size() > 0 else "vacía — tocá ingredientes para agregarlos"]
			if pv.is_empty():
				desc_body.text = "%s: cura %d%s. Cocinar necesita estar en una fogata." % [it.id, ing2.heal, (" · efecto " + Data.FX_NAMES[ing2.fx]) if ing2.has("fx") else ""]
			else:
				desc_body.text = "Va a salir: %s (cura %d%s).%s" % [pv.name, pv.heal, (" · " + Data.FX_DESC[pv.fx]) if pv.fx != "" and pv.fx != "curacion" else "", " Dos efectos distintos se anulan." if pv.fail else ""]
			act("Cocinar", func():
				var made: String = m.cook(pot.duplicate())
				if made != "":
					m.toast("Cocinaste: " + made)
				pot.clear()
				rebuild(), m.near_fire() and pot.size() > 0)
			act("Vaciar la olla", func():
				pot.clear()
				rebuild(), pot.size() > 0)
			if not m.near_fire():
				desc_sub.text += "   ·   acercate a una fogata para cocinar"
		"destilado":
			var dd: Dictionary = Data.DESTILADOS[it.id]
			desc_title.text = it.id
			var rec := []
			for mn in dd.recipe:
				rec.append(mn)
			desc_sub.text = "Alquimia · tenés %d · receta: %s" % [it.count, " + ".join(rec)]
			desc_body.text = ("Le pone %s al ataque básico." % dd.oil) if dd.oil != "" else "Recupera el 40% de la vida."
			act("Destilar", func():
				m.distill(it.id)
				rebuild(), m.has_all(dd.recipe))
			act("Usar", func():
				m.use_distilled(it.id)
				rebuild(), it.count > 0)
		"lupa":
			desc_title.text = "Lupa de joyero"
			desc_sub.text = "Herramienta del Joyero"
			desc_body.text = "Sentís las vetas cercanas: aparecen en el minimapa (90 m alrededor)."
			act("Apagar" if m.sense_ores else "Sentir vetas", func():
				m.sense_ores = not m.sense_ores
				rebuild())
		"apariencia":
			var ap: Dictionary = Data.APARIENCIAS[it.i]
			desc_title.text = ap.name
			var sl_name: String = Data.SLOTS.filter(func(s): return s.id == ap.slot)[0].name
			desc_sub.text = "Apariencia · %s · receta: %s" % [sl_name, " + ".join(ap.recipe)]
			desc_body.text = "Ya la forjaste: cambiala desde Equipo." if ap.name in m.wardrobe else ("Solo cambia el look; la gema engarzada queda. " + ("" if m.in_forge() else "Necesitás la forja de una ciudad."))
			act("Forjar", func():
				m.forge(it.i)
				refresh_preview()
				rebuild(), m.in_forge() and m.has_all(ap.recipe) and not ap.name in m.wardrobe)
		"silbato":
			desc_title.text = "Lazo y silbato"
			desc_sub.text = "Herramienta del Criador · caballos: %d" % m.horses_owned.size()
			desc_body.text = "Domá caballos salvajes de las praderas acercándote con una zanahoria, calabaza o bayas (G). Llamá tu caballo con H."
			act("Bajarse" if m.mounted else "Llamar caballo (H)", func():
				m.toggle_mount()
				rebuild(), m.horses_owned.size() > 0)
		"caballo":
			var hh: Dictionary = m.horses_owned[it.i]
			desc_title.text = hh.name
			desc_sub.text = "Montura · en el establo"
			desc_body.text = "Corre un 60% más. Se puede atacar desde el caballo contra monstruos; en PvP la montura no hace daño y en duelos no se permite."
		"construccion":
			var cd: Dictionary = Data.CONSTRUCCIONES[it.id]
			desc_title.text = it.id
			desc_sub.text = "Constructor · receta: %s (madera: %d)" % [" + ".join(cd.recipe), m.wood]
			desc_body.text = cd.desc + " Se construye delante tuyo, fuera de las ciudades."
			act("Construir", func():
				m.build_thing(it.id)
				close(), m.has_all(cd.recipe) and not m.in_city(m.P.x, m.P.z))
		"oficio":
			var od: Dictionary = Data.OFICIOS[it.id]
			desc_title.text = od.name
			desc_sub.text = "Herramienta: %s · trabaja: %s" % [od.tool, od.where]
			desc_body.text = od.desc + "\nUna cuenta normal elige un solo oficio."
			act("Elegir este oficio", func():
				m.prof = it.id
				prof_view = it.id
				m.save_progress()
				rebuild())

func build_prof_bar() -> void:
	for c in prof_bar.get_children():
		c.queue_free()
	prof_bar.visible = TABS[tab] == "Oficio"
	if not prof_bar.visible:
		return
	for pid in Data.OFICIOS:
		if not m.has_prof(pid):
			continue
		var b := Button.new()
		b.text = Data.OFICIOS[pid].name
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", GOLD if pid == prof_view else Color(0.7, 0.74, 0.78))
		b.pressed.connect(func():
			prof_view = pid
			pot.clear()
			sel = 0
			rebuild())
		prof_bar.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prof_bar.add_child(sp)
	var gm := Button.new()
	gm.text = "Cuenta GM ✓" if m.account_gm else "Cuenta normal"
	gm.tooltip_text = "Para probar: la cuenta GM tiene todos los oficios; la normal elige uno"
	gm.focus_mode = Control.FOCUS_NONE
	gm.add_theme_font_size_override("font_size", 11)
	gm.pressed.connect(func():
		m.account_gm = not m.account_gm
		if not m.account_gm:
			m.prof = ""
		m.save_progress()
		prof_view = ""
		sel = 0
		rebuild())
	prof_bar.add_child(gm)

func set_tab_equipo() -> void:
	set_tab(1)

func pick(slot: String) -> void:
	picking_slot = slot
	sel = 0
	rebuild()
	desc_sub.text = "Elegí qué engarzar en %s (Esc para volver)" % Data.SLOTS.filter(func(s): return s.id == slot)[0].name

func equip_here(it: Dictionary) -> void:
	m.equip(picking_slot, it)
	picking_slot = ""
	refresh_preview()
	rebuild()

func click(i: int) -> void:
	sel = i
	highlight()
	describe()
	var it: Dictionary = items[i]
	if it.kind == "slot":
		pick(it.slot)
	elif it.kind == "ing" and pot.size() < 5 and int(it.count) > 0:
		pot.append(it.id)
		var keep := sel
		rebuild()
		sel = keep
	elif picking_slot != "" and it.kind in ["gema", "piedra"]:
		equip_here(it)

func refresh_stats() -> void:
	for c in stats_box.get_children():
		c.queue_free()
	stats_box.add_child(lbl(m.weapon.cls + " · " + m.weapon.style, 16, m.weapon.color))
	var g: Dictionary = m.gear
	var rows = [["Vida", "%d" % int(m.weapon.hp * (1.0 + g.get("hp", 0) / 100.0)), g.get("hp", 0)],
		["Ataque", "+%d%%" % g.get("atk", 0), g.get("atk", 0)], ["Magia", "+%d%%" % g.get("mag", 0), g.get("mag", 0)],
		["Defensa", "+%d%%" % g.get("def", 0), g.get("def", 0)], ["Velocidad", "+%d%%" % g.get("spd", 0), g.get("spd", 0)],
		["Enfriamiento", "−%d%%" % g.get("cdr", 0), g.get("cdr", 0)], ["Daño a monstruos", "+%d%%" % g.get("pve", 0), g.get("pve", 0)]]
	for r in rows:
		var h := HBoxContainer.new()
		var a := lbl(r[0], 14, Color(0.75, 0.78, 0.82))
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		h.add_child(lbl(r[1], 14, GOLD if r[2] > 0 else Color.WHITE))
		stats_box.add_child(h)
	var other := []
	for k in ["crit", "aspd", "mpen", "mdef", "pvels", "heal", "tenac"]:
		if g.get(k, 0) > 0:
			other.append("+%d%% %s" % [g[k], Data.STAT_NAMES[k]])
	if other.size() > 0:
		var o := lbl("\n".join(other), 12, Color(0.7, 0.75, 0.8))
		stats_box.add_child(o)
	stats_box.add_child(lbl("", 6))
	stats_box.add_child(lbl("Engarzado", 13, GOLD))
	for sl in Data.SLOTS:
		var it = m.equipped.get(sl.id)
		stats_box.add_child(lbl("%s: %s" % [sl.name, item_name(it) if it else "—"], 12, Color(0.85, 0.88, 0.9) if it else Color(0.5, 0.55, 0.6)))
