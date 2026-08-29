extends CanvasLayer

const InterceptRouteSurface = preload("res://scripts/intercept_route_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")

var _surface: Control

func _ready() -> void:
	layer = 17
	_surface = InterceptRouteSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_intercept_routes(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft == null or not craft.has_method("current_altitude") or not craft.has_method("current_form"):
		return
	if str(craft.call("current_altitude")) != "high" or str(craft.call("current_form")) != "fighter":
		return
	var player: Vector2 = scene.get("player_position")
	var targets: Array = []
	for enemy in scene.get("enemies"):
		if typeof(enemy) != TYPE_DICTIONARY or not bool(enemy.get("intercept_priority", false)):
			continue
		targets.append(enemy)
	if targets.is_empty():
		return
	for enemy in targets:
		_draw_target(surface, player, enemy)
	PixelFont.draw_text(surface, "HIGH INTERCEPT  SHIFT AB", Vector2(448, 313), 1, Color(0.56,0.88,1.0,0.94), 1)

func _draw_target(surface: CanvasItem, player: Vector2, enemy: Dictionary) -> void:
	var p: Vector2 = enemy.get("position", Vector2.ZERO)
	var distance := p.distance_to(player)
	var bracket := Color(0.56,0.88,1.0,0.92)
	var half := 11.0
	var arm := 5.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner := p + Vector2(half * sx, half * sy)
			surface.draw_line(corner, corner + Vector2(-arm * sx, 0), bracket, 1.0)
			surface.draw_line(corner, corner + Vector2(0, -arm * sy), bracket, 1.0)
	var closure_ratio := clampf(1.0 - distance / 420.0, 0.0, 1.0)
	var closure_color := Color(0.42 + closure_ratio * 0.34, 0.72 + closure_ratio * 0.22, 1.0, 0.9)
	surface.draw_line(p + Vector2(-8, 15), p + Vector2(8, 15), closure_color, 1.0)
	surface.draw_line(p + Vector2(-8, 15), p + Vector2(-8 + roundf(16.0 * closure_ratio), 15), Color(0.92,0.96,1.0,0.96), 2.0)
	PixelFont.draw_text(surface, "INT %03d" % int(round(distance)), p + Vector2(-12, 19), 1, bracket, 1)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "player_position", "enemies"]:
		if not names.has(required):
			return false
	return true
