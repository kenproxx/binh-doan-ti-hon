extends Control

signal tapped(world: Vector2)
signal camera_changed
var sim
var camera: Vector2 = Vector2(144, 620)
var zoom: float = 1.0
var press_pos: Vector2
var last_pos: Vector2
var dragging: bool = false
var pressed: bool = false
var marker: Vector2 = Vector2(-1, -1)
var preview_radius: float = 0.0
const WORLD: Vector2 = Vector2(768, 1152)
const INK: Color = Color("172c37")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_clamp_camera)

func set_sim(value) -> void:
	sim = value
	center_on(Vector2(384, 880))

func center_on(pos: Vector2) -> void:
	camera = pos - size / (2.0 * zoom)
	_clamp_camera()

func _clamp_camera() -> void:
	camera.x = clampf(camera.x, 0, maxf(0, WORLD.x - size.x / zoom))
	camera.y = clampf(camera.y, 0, maxf(0, WORLD.y - size.y / zoom))
	queue_redraw()
	camera_changed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.position, event.pressed)
	elif event is InputEventScreenTouch:
		_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and pressed:
		_motion(event.position)
	elif event is InputEventScreenDrag and pressed:
		_motion(event.position)

func _pointer(pos: Vector2, down: bool) -> void:
	if down:
		pressed = true
		dragging = false
		press_pos = pos
		last_pos = pos
	else:
		if pressed and not dragging and sim != null:
			var world: Vector2 = pos / zoom + camera
			marker = world
			# Simulation supplies the precise refusal reason to the UI.
			tapped.emit(world)
		pressed = false
	accept_event()

func _motion(pos: Vector2) -> void:
	if pos.distance_to(press_pos) > 12:
		dragging = true
	if dragging:
		camera -= (pos - last_pos) / zoom
		_clamp_camera()
	last_pos = pos
	accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("334d3b"))
	if sim == null:
		return
	draw_set_transform(-camera * zoom, 0, Vector2.ONE * zoom)
	for y in range(36):
		for x in range(24):
			var cell: Vector2i = Vector2i(x, y)
			var rect: Rect2 = Rect2(Vector2(x * 32, y * 32), Vector2(32, 32))
			if not Rect2(camera, size / zoom).intersects(rect):
				continue
			var chapter: int = int(sim.stage.get("chapter", 1))
			var palettes: Array = [["63874d", "5d8048"], ["768176", "6d766b"], ["c0a16e", "b59764"]]
			var colors: Array = palettes[clampi(chapter - 1, 0, 2)]
			var color: Color = Color(colors[(x + y) % 2])
			draw_rect(rect, color)
			if sim.map.bridge_cells.has(cell):
				draw_rect(rect.grow(-1), Color("a78353"))
				draw_line(rect.position + Vector2(0, 7), rect.position + Vector2(32, 7), Color("725437"), 3)
				draw_line(rect.position + Vector2(0, 25), rect.position + Vector2(32, 25), Color("725437"), 3)
			elif sim.map.blocked(cell):
				if sim.map.is_water(cell):
					draw_rect(rect, Color("337f96"))
					draw_line(rect.position + Vector2(5, 12), rect.position + Vector2(23, 12), Color("62b4bd"), 2)
				else:
					draw_rect(rect.grow(-5), Color("635f55") if chapter > 1 else Color("3d573d"))
					draw_rect(rect.grow(-9), Color("819077"))
			else:
				if (x * 7 + y * 13) % 11 == 0:
					draw_rect(Rect2(rect.position + Vector2(8, 19), Vector2(3, 5)), Color("85a860"))
	for team in range(2):
		var pos: Vector2 = sim.map.base_positions[team]
		var color: Color = Color("4fd0ce") if team == 0 else Color("f18e66")
		if team == 0:
			draw_arc(pos, 180, 0, TAU, 64, Color(0.5, 1, 1, 0.32), 2)
		_base(pos, color, sim.base_hp[team] / sim.base_max[team])
	for point in sim.captures:
		var pos: Vector2 = point.pos
		var owner: int = int(point.owner)
		var color: Color = Color("e3c875") if owner == -1 else (Color("50d5d2") if owner == 0 else Color("f39168"))
		draw_circle(pos, 34, Color("3d573d"))
		draw_arc(pos, 36, -PI / 2, -PI / 2 + TAU * clampf(float(point.progress) / 5.0, 0, 1), 32, color, 4)
		draw_rect(Rect2(pos + Vector2(-2, -25), Vector2(4, 44)), INK)
		draw_rect(Rect2(pos + Vector2(2, -25), Vector2(23, 15)), color)
		if owner == 0:
			draw_arc(pos, 100, 0, TAU, 48, Color(0.5, 1, 1, 0.3), 2)
	for unit in sim.units:
		_draw_unit(unit)
	for effect in sim.effects:
		var pos: Vector2 = effect.get("pos", Vector2.ZERO)
		var kind: String = str(effect.get("kind", "hit"))
		var radius: float = float(effect.get("radius", 16))
		if kind in ["projectile", "arrow", "shot"]:
			var end: Vector2 = effect.get("end", pos)
			draw_line(pos, end, Color("ffe4a1"), 3)
		elif kind == "death":
			draw_rect(Rect2(pos - Vector2(10, 4), Vector2(20, 8)), Color("ffd4aa"))
			draw_line(pos - Vector2(15, 15), pos + Vector2(15, 15), Color(1, .8, .6, .4), 2)
		elif kind == "heal":
			draw_arc(pos, maxf(12, radius), 0, TAU, 32, Color("8aefc2"), 4)
			draw_line(pos - Vector2(0, 8), pos + Vector2(0, 8), Color("d1ffe5"), 4)
			draw_line(pos - Vector2(8, 0), pos + Vector2(8, 0), Color("d1ffe5"), 4)
		else:
			var end: Vector2 = effect.get("end", pos)
			if end != pos:
				draw_line(pos, end, Color("ffe3a4"), 2)
			draw_circle(pos, minf(96, maxf(7, radius)), Color(1, 0.68, 0.3, 0.35))
			draw_arc(pos, maxf(7, radius), 0, TAU, 24, Color("ffdb88"), 3)
	if marker.x >= 0:
		draw_arc(marker, maxf(12, preview_radius), 0, TAU, 48, Color("fff0b5"), 3)
	draw_set_transform(Vector2.ZERO)

func _base(pos: Vector2, color: Color, hp: float) -> void:
	draw_rect(Rect2(pos + Vector2(-43, -26), Vector2(86, 59)), INK)
	draw_rect(Rect2(pos + Vector2(-38, -21), Vector2(76, 49)), Color("b1ad84"))
	for x in [-33, -9, 15]:
		draw_rect(Rect2(pos + Vector2(x, -35), Vector2(18, 20)), color)
	draw_rect(Rect2(pos + Vector2(-11, 4), Vector2(22, 28)), Color("344750"))
	draw_rect(Rect2(pos + Vector2(-44, -48), Vector2(88, 7)), INK)
	draw_rect(Rect2(pos + Vector2(-44, -48), Vector2(88 * maxf(0, hp), 7)), color)

func _draw_unit(unit: Dictionary) -> void:
	var pos: Vector2 = unit.pos
	var type: String = str(unit.type)
	var state: String = str(unit.get("state", "idle"))
	var color: Color = Color("60d8d4") if int(unit.team) == 0 else Color("ef976d")
	if float(unit.get("flash", 0)) > 0:
		color = Color("fff8d7")
	var tick: float = float(Time.get_ticks_msec()) / 150.0 + float(unit.uid)
	var bob: float = roundf(sin(tick)) if state in ["walk", "moving", "move"] else 0
	if state in ["dead", "death"]:
		draw_rect(Rect2(pos - Vector2(9, 3), Vector2(18, 6)), color)
		return
	draw_ellipse_shadow(pos)
	pos.y += bob
	draw_rect(Rect2(pos + Vector2(-6, -5), Vector2(12, 13)), INK)
	draw_rect(Rect2(pos + Vector2(-5, -4), Vector2(10, 10)), color)
	draw_rect(Rect2(pos + Vector2(-5, -13), Vector2(10, 8)), Color("f1d9ad"))
	draw_rect(Rect2(pos + Vector2(-6, -15), Vector2(12, 4)), INK)
	var stride: float = 3 if state in ["walk", "moving", "move"] and sin(tick) > 0 else 0
	draw_rect(Rect2(pos + Vector2(-5, 7 + stride), Vector2(4, 5)), INK)
	draw_rect(Rect2(pos + Vector2(2, 10 - stride), Vector2(4, 5)), INK)
	match type:
		"blade":
			draw_line(pos + Vector2(8, 4), pos + Vector2(13, -16 if state == "attack" else -8), Color("e0e9d8"), 4)
		"guard":
			draw_rect(Rect2(pos + Vector2(-12, -4), Vector2(8, 16)), Color("ded8ad"))
			draw_rect(Rect2(pos + Vector2(-10, -2), Vector2(4, 12)), color)
		"archer":
			draw_arc(pos + Vector2(10, -2), 8, -PI / 2, PI / 2, 8, Color("e4c385"), 3)
			draw_line(pos + Vector2(10, -10), pos + Vector2(10, 6), Color("faf0cf"), 1)
		"bomber":
			draw_circle(pos + Vector2(10, 2), 6, INK)
			draw_rect(Rect2(pos + Vector2(9, -7), Vector2(3, 4)), Color("ffcd68"))
		"medic":
			draw_rect(Rect2(pos + Vector2(-3, -3), Vector2(6, 3)), Color("fff4d0"))
			draw_rect(Rect2(pos + Vector2(-1, -5), Vector2(2, 7)), Color("fff4d0"))
		"siege":
			draw_rect(Rect2(pos + Vector2(-12, -3), Vector2(24, 13)), Color("b79360"))
			draw_line(pos + Vector2(-9, -3), pos + Vector2(10, -16), INK, 5)
			draw_circle(pos + Vector2(-9, 12), 4, INK)
			draw_circle(pos + Vector2(9, 12), 4, INK)
	var hp: float = maxf(0, float(unit.hp) / float(unit.max_hp))
	draw_rect(Rect2(pos + Vector2(-10, -21), Vector2(20, 3)), INK)
	draw_rect(Rect2(pos + Vector2(-10, -21), Vector2(20 * hp, 3)), Color("b9ee92"))

func draw_ellipse_shadow(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-10, 9), Vector2(21, 5)), Color(0.1, 0.2, 0.15, 0.35))
