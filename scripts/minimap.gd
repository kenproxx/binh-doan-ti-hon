extends Control
var field
var sim
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed or event is InputEventScreenTouch and event.pressed:
		field.center_on(event.position / size * Vector2(768, 1152))
		accept_event()
func _draw() -> void:
	if sim == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("203e43"))
	var scale_v: Vector2 = size / Vector2(768, 1152)
	for unit in sim.units:
		draw_circle(unit.pos * scale_v, 2, Color("72e3df") if unit.team == 0 else Color("ff9c70"))
	for point in sim.captures:
		draw_circle(point.pos * scale_v, 3, Color("f2d690"))
	for team in range(2):
		draw_rect(Rect2(sim.map.base_positions[team] * scale_v - Vector2(4, 4), Vector2(8, 8)), Color("72e3df") if team == 0 else Color("ff9c70"))
	draw_rect(Rect2(field.camera * scale_v, field.size / field.zoom * scale_v), Color("fff2c7"), false, 1)
