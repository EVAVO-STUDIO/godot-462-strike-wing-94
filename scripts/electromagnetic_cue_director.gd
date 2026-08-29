extends CanvasLayer

const ElectromagneticCueSurface = preload("res://scripts/electromagnetic_cue_surface.gd")

var _surface: Control

func _ready() -> void:
	layer = 15
	_surface = ElectromagneticCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_surface(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	_draw_magnetic(surface, scene)
	_draw_emp(surface, scene)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("player_position") and names.has("enemies")

func _draw_magnetic(surface: CanvasItem, scene: Object) -> void:
	var support := get_node_or_null("/root/SupportDirector")
	if support == null or not support.has_method("magnetic_active") or not bool(support.call("magnetic_active")):
		return
	var radius := 92.0
	if support.has_method("current_support"):
		var item = support.call("current_support")
		if typeof(item) == TYPE_DICTIONARY:
			radius = clampf(float(item.get("radius", radius)), 24.0, 240.0)
	var p: Vector2 = scene.get("player_position")
	var tone := Color(0.36, 0.82, 0.95, 0.55)
	surface.draw_arc(p, radius, 0.0, TAU, 32, tone, 1.0)
	surface.draw_arc(p, radius - 4.0, 0.2, TAU + 0.2, 24, Color(0.36, 0.82, 0.95, 0.24), 1.0)
	for i in range(8):
		var angle := float(i) / 8.0 * TAU
		var a := p + Vector2.RIGHT.rotated(angle) * (radius - 2.0)
		var b := p + Vector2.RIGHT.rotated(angle) * (radius + 3.0)
		surface.draw_line(a, b, tone, 1.0)

func _draw_emp(surface: CanvasItem, scene: Object) -> void:
	var enemies: Array = scene.get("enemies")
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY or float(enemy.get("emp_timer", 0.0)) <= 0.0:
			continue
		var p: Vector2 = enemy.get("position", Vector2.ZERO)
		var tone := Color(0.48, 0.82, 1.0, 0.72)
		surface.draw_line(p + Vector2(-8,-7), p + Vector2(-2,-1), tone, 1.0)
		surface.draw_line(p + Vector2(-2,-1), p + Vector2(-7,4), tone, 1.0)
		surface.draw_line(p + Vector2(7,-6), p + Vector2(2,0), tone, 1.0)
		surface.draw_line(p + Vector2(2,0), p + Vector2(7,5), tone, 1.0)
		surface.draw_arc(p, 12.0, 0.0, TAU, 12, Color(0.48, 0.82, 1.0, 0.30), 1.0)
