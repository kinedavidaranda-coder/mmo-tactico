# Terreno del corazón del Imperio de la Luz (1 × 1 km).
# Las alturas salen de ruido + rasgos dibujados a mano (montañas, río, lago, caminos, capital),
# así el mapa es siempre el mismo y el juego puede preguntar la altura de cualquier punto.
extends RefCounted

const SIZE := 1024.0            # metros por lado
const RES := 2.0                # metros entre vértices
const N := 513                  # vértices por lado (SIZE / RES + 1)
const HALF := SIZE / 2.0
const WATER := 0.0              # nivel del agua
const CHUNK := 64               # celdas por pedazo de malla (64 × 2 m = 128 m)

# Rasgos del mapa (x = este, z = sur; el norte es -z)
const CAPITAL := Vector2(0, 0)
const CAPITAL_R := 52.0
const SAPIENTIA := Vector2(-235, 40)      # ciudad del conocimiento, al oeste
const SAPIENTIA_R := 46.0
const LAKE := Vector2(300, 140)
const LAKE_R := 85.0
const RIVER = [Vector2(-90, -470), Vector2(-70, -330), Vector2(-20, -200), Vector2(60, -110), Vector2(110, -20), Vector2(170, 60), Vector2(240, 110), Vector2(300, 140)]
const ROADS = [
	[Vector2(0, 0), Vector2(-15, -120), Vector2(-40, -230), Vector2(-75, -340), Vector2(-95, -480)],   # norte, al paso de montaña
	[Vector2(0, 0), Vector2(120, -30), Vector2(230, -40), Vector2(360, -70), Vector2(500, -90)],        # este, al bosque
	[Vector2(0, 0), Vector2(-150, 25), Vector2(-280, 50), Vector2(-500, 70)],                          # oeste, al cañadón
	[Vector2(0, 0), Vector2(25, 150), Vector2(10, 300), Vector2(0, 500)],                              # sur, a los campos
]

var heights := PackedFloat32Array()
var colors := PackedColorArray()
var noise := FastNoiseLite.new()
var noise2 := FastNoiseLite.new()
var ridge := FastNoiseLite.new()

func _init() -> void:
	noise.seed = 11
	noise.frequency = 0.004
	noise.fractal_octaves = 4
	noise2.seed = 23
	noise2.frequency = 0.02
	noise2.fractal_octaves = 2
	ridge.seed = 37
	ridge.frequency = 0.007
	ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridge.fractal_octaves = 4
	generate()

# ----------------------------------------------------------------- utilidades
static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = clamp((p - a).dot(ab) / max(0.0001, ab.length_squared()), 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func poly_dist(p: Vector2, pts: Array) -> float:
	var d := INF
	for i in pts.size() - 1:
		d = min(d, seg_dist(p, pts[i], pts[i + 1]))
	return d

func road_dist(p: Vector2) -> float:
	var d := INF
	for r in ROADS:
		d = min(d, poly_dist(p, r))
	return d

func river_dist(p: Vector2) -> float:
	return poly_dist(p, RIVER)

# ----------------------------------------------------------------- altura base
func base_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var n := noise.get_noise_2d(x, z)          # -1..1, lomas suaves
	var h := 4.0 + n * 7.0 + noise2.get_noise_2d(x, z) * 0.8
	# montañas del norte (cordillera con picos nevados)
	var north: float = smoothstep(-160.0, -420.0, z)
	var r := (ridge.get_noise_2d(x, z) + 1.0) * 0.5
	h += north * north * (18.0 + r * 60.0) + north * 8.0
	# cañadón del oeste: mesetas con escalones
	var west: float = smoothstep(-200.0, -380.0, x) * (1.0 - north)
	var mesa: float = floor((noise.get_noise_2d(x * 1.7, z * 1.7) + 1.0) * 3.0) * 6.0
	h = lerp(h, 6.0 + mesa, west * 0.85)
	# campos del sur: más llanos
	var south: float = smoothstep(110.0, 220.0, z) * (1.0 - west)
	h = lerp(h, 3.5 + n * 1.5, south * 0.75)
	# lago
	var dl := p.distance_to(LAKE) + noise2.get_noise_2d(x, z) * 10.0
	if dl < LAKE_R + 40.0:
		var k: float = smoothstep(LAKE_R + 40.0, LAKE_R - 10.0, dl)
		h = lerp(h, -3.5, k)
	# río (cauce bajo el nivel del agua)
	var dr := river_dist(p)
	if dr < 22.0:
		var k: float = smoothstep(22.0, 5.0, dr)
		h = lerp(h, -2.0, k)
	# caminos: suavizan y se mantienen sobre el agua (vados en el río)
	var dd := road_dist(p)
	if dd < 10.0:
		var k: float = smoothstep(10.0, 3.0, dd)
		var flat: float = max(0.6, lerp(h, 3.0 + n * 3.0, 0.7)) if north < 0.5 else h
		h = lerp(h, flat, k * 0.85)
	# capital Lumen: meseta plana un poco elevada
	var dc := p.distance_to(CAPITAL)
	if dc < CAPITAL_R + 45.0:
		var k: float = smoothstep(CAPITAL_R + 45.0, CAPITAL_R, dc)
		h = lerp(h, 6.0, k)
	# Sapientia: meseta plana al borde del cañadón
	var ds := p.distance_to(SAPIENTIA)
	if ds < SAPIENTIA_R + 40.0:
		var k: float = smoothstep(SAPIENTIA_R + 40.0, SAPIENTIA_R, ds)
		h = lerp(h, 9.0, k)
	# bordes del mapa: suben para cerrar el mundo
	var edge: float = max(abs(x), abs(z))
	h += smoothstep(HALF - 60.0, HALF, edge) * 40.0
	return h

func generate() -> void:
	heights.resize(N * N)
	for j in N:
		var z := -HALF + j * RES
		for i in N:
			heights[j * N + i] = base_height(-HALF + i * RES, z)
	colors.resize(N * N)
	for j in N:
		for i in N:
			colors[j * N + i] = color_at(i, j)

# altura interpolada en cualquier punto (para personajes, enemigos y apuntado)
func height(x: float, z: float) -> float:
	var fx: float = clamp((x + HALF) / RES, 0.0, N - 1.001)
	var fz: float = clamp((z + HALF) / RES, 0.0, N - 1.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a := heights[j * N + i]
	var b := heights[j * N + i + 1]
	var c := heights[(j + 1) * N + i]
	var d := heights[(j + 1) * N + i + 1]
	return lerp(lerp(a, b, tx), lerp(c, d, tx), tz)

func ground(x: float, z: float) -> float:
	return max(height(x, z), WATER)

func slope_at(i: int, j: int) -> float:
	var i0: int = max(i - 1, 0)
	var i1: int = min(i + 1, N - 1)
	var j0: int = max(j - 1, 0)
	var j1: int = min(j + 1, N - 1)
	var dx := (heights[j * N + i1] - heights[j * N + i0]) / ((i1 - i0) * RES)
	var dz := (heights[j1 * N + i] - heights[j0 * N + i]) / ((j1 - j0) * RES)
	return Vector2(dx, dz).length()

func normal_at(i: int, j: int) -> Vector3:
	var i0: int = max(i - 1, 0)
	var i1: int = min(i + 1, N - 1)
	var j0: int = max(j - 1, 0)
	var j1: int = min(j + 1, N - 1)
	var dx := (heights[j * N + i1] - heights[j * N + i0]) / ((i1 - i0) * RES)
	var dz := (heights[j1 * N + i] - heights[j0 * N + i]) / ((j1 - j0) * RES)
	return Vector3(-dx, 1.0, -dz).normalized()

# ----------------------------------------------------------------- colores del suelo
func color_at(i: int, j: int) -> Color:
	var x := -HALF + i * RES
	var z := -HALF + j * RES
	var p := Vector2(x, z)
	var h := heights[j * N + i]
	var s := slope_at(i, j)
	var v := noise2.get_noise_2d(x * 2.0, z * 2.0) * 0.5 + 0.5
	var grass := Color("#6aa84f").lerp(Color("#93c45a"), v)
	var c := grass
	# cañadón oeste: pasto seco y tierra rojiza
	var west: float = smoothstep(-180.0, -330.0, x)
	c = c.lerp(Color("#c9a66b").lerp(Color("#b5764a"), v), west * 0.9)
	# campos del sur: parcelas de cultivo
	if z > 150.0 and abs(x) < 380.0:
		var cell := Vector2i(int(floor((x + 7.0) / 34.0)), int(floor((z + 3.0) / 26.0)))
		var pick := (cell.x * 73856093 ^ cell.y * 19349663) & 3
		var crops = [Color("#d9c16a"), Color("#8cbf4f"), Color("#b38d4e"), Color("#a6c96a")]
		var edge: float = smoothstep(150.0, 190.0, z)
		c = c.lerp(crops[pick].lerp(c, 0.15 + v * 0.2), edge * 0.85)
	# bosque del este: suelo más oscuro
	var forest: float = smoothstep(130.0, 200.0, x) * smoothstep(80.0, 20.0, z) * (1.0 - smoothstep(-260.0, -320.0, z))
	c = c.lerp(Color("#3d6b35").lerp(Color("#4f7a3a"), v), forest * 0.8)
	# altura: piedra y nieve en la cordillera
	if h > 28.0:
		c = c.lerp(Color("#76705f").lerp(Color("#8c8371"), v), smoothstep(28.0, 45.0, h))
	if h > 62.0:
		c = c.lerp(Color("#f2f4f7"), smoothstep(62.0, 72.0, h))
	# pendiente: roca a la vista
	c = c.lerp(Color("#6f6656").lerp(Color("#857a66"), v), smoothstep(0.55, 1.1, s))
	# orillas: arena
	if h < 1.4:
		c = c.lerp(Color("#d8c9a0"), smoothstep(1.4, 0.2, h))
	# caminos de tierra
	var dd := road_dist(p)
	if dd < 5.0:
		c = c.lerp(Color("#b99b6b").lerp(Color("#a8875a"), v), smoothstep(5.0, 2.5, dd))
	# capital: plaza de piedra clara
	if p.distance_to(CAPITAL) < CAPITAL_R:
		c = c.lerp(Color("#cfc6b4").lerp(Color("#bdb39f"), v), 0.9)
	# Sapientia: plaza de arenisca
	if p.distance_to(SAPIENTIA) < SAPIENTIA_R:
		c = c.lerp(Color("#d6bf95").lerp(Color("#c4a97c"), v), 0.9)
	return c

# ----------------------------------------------------------------- malla
func build_mesh(parent: Node3D, mat: Material) -> void:
	var cells := N - 1
	var cj := 0
	while cj < cells:
		var ci := 0
		while ci < cells:
			parent.add_child(make_chunk(ci, cj, min(CHUNK, cells - ci), min(CHUNK, cells - cj), mat))
			ci += CHUNK
		cj += CHUNK

func make_chunk(ci: int, cj: int, w: int, h: int, mat: Material) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for j in range(cj, cj + h + 1):
		for i in range(ci, ci + w + 1):
			verts.append(Vector3(-HALF + i * RES, heights[j * N + i], -HALF + j * RES))
			norms.append(normal_at(i, j))
			cols.append(colors[j * N + i])
	var row := w + 1
	for j in h:
		for i in w:
			var a := j * row + i
			var b := a + 1
			var c := a + row
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	return mi

# ----------------------------------------------------------------- dónde poner árboles
func tree_density(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var h := height(x, z)
	if h < 1.2 or h > 50.0:
		return 0.0
	if road_dist(p) < 8.0 or river_dist(p) < 14.0 or p.distance_to(CAPITAL) < CAPITAL_R + 25.0 or p.distance_to(SAPIENTIA) < SAPIENTIA_R + 22.0:
		return 0.0
	if z > 150.0 and abs(x) < 380.0:
		return 0.01           # campos: casi sin árboles
	var forest: float = smoothstep(130.0, 200.0, x) * smoothstep(80.0, 20.0, z) * (1.0 - smoothstep(-260.0, -320.0, z))
	var foothill: float = smoothstep(-120.0, -200.0, z) * (1.0 - smoothstep(30.0, 45.0, h))
	var west: float = smoothstep(-200.0, -330.0, x)
	var clumps: float = clamp(noise2.get_noise_2d(x * 0.6, z * 0.6) * 1.5 + 0.2, 0.0, 1.0)
	return clamp(0.05 + forest * 0.9 + foothill * 0.35 + clumps * 0.12 - west * 0.15, 0.0, 1.0)

# imagen chica para el minimapa
func minimap_image(px: int) -> Image:
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	for y in px:
		for x in px:
			var i := int(float(x) / px * (N - 1))
			var j := int(float(y) / px * (N - 1))
			var h := heights[j * N + i]
			var c: Color = colors[j * N + i]
			if h < WATER:
				c = Color("#3a7cc4")
			img.set_pixel(x, y, c)
	return img
