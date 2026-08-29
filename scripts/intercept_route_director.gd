extends CanvasLayer

const InterceptRouteSurface = preload("res://scripts/intercept_route_surface.gd")
const InterceptRouteRules = preload("res://scripts/intercept_route_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")

var _surface: Control
var _previous_targets: Dictionary = {}
var _last_score := 0
var _chain := 0
var _chain_timer := 0.0

func _ready() -> void:
	layer = 17
	_surface = InterceptRouteSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_chain_timer = maxf(0.0, _chain_timer - maxf(0.0, delta))
	if _chain_timer <= 0.0:
		_chain = 0
	_observe_route_kills()
	if _surface != null:
		_surface.queue_redraw()

func _observe_route_kills() -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1 or not _high_fighter_active():
		_previous_targets.clear()
		_last_score = int(scene.get("score")) if scene != null and _has_property(scene, "score") else 0
		_chain = 0
		_chain_timer = 0.0
		return
	var current_score := int(scene.get("score"))
	var score_delta := maxi(0, current_score - _last_score)
	var current: Dictionary = {}
	for enemy in scene.get("enemies"):
		if typeof(enemy) != TYPE_DICTIONARY or not bool(enemy.get("intercept_priority", false)):
			continue
		var key := _target_key(enemy)
		current[key] = Vector2(enemy.get("position", Vector2.ZERO))
	for key in _previous_targets.keys():
		if current.has(key):
			continue
		var previous_position: Vector2 = _previous_targets[key]
		if InterceptRouteRules.likely_destroyed(previous_position, score_delta):
			_chain = InterceptRouteRules.next_chain(_chain, _chain_timer, true)
			_chain_timer = InterceptRouteRules.next_timer(true)
			break
	_previous_targets = current
	_last_score = current_score

func _target_key(enemy: Dictionary) -> String:
	var id := str(enemy.get("id", "enemy"))
	var route := str(enemy.get("route_bonus_id", "route"))
	var position: Vector2 = enemy.get("position", Vector2.ZERO)
	return "%s:%s:%d:%d" % [route, id, int(round(position.x / 12.0)), int(round(position.y / 12.0))]

func _high_fighter_active() -> bool:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft == null or not craft.has_method("current_altitude") or not craft.has_method("current_form"):
		return false
	return str(craft.call("current_altitude")) == "high" and str(craft.call("current_form")) == "fighter"

func _draw_intercept_routes(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1 or not _high_fighter_active():
		return
	var player: Vector2 = scene.get("player_position")
	var targets: Array = []
	for enemy in scene.get("enemies"):
		if typeof(enemy) != TYPE_DICTIONARY or not bool(enemy.get("intercept_priority", false)):
			continue
		targets.append(enemy)
	if targets.is_empty() and not InterceptRouteRules.active(_chain, _chain_timer):
		return
	for enemy in targets:
		_draw_target(surface, player, enemy)
	PixelFont.draw_text(surface, "HIGH INTERCEPT  SHIFT AB", Vector2(448, 313), 1, Color(0.56,0.88,1.0,0.94), 1)
	if InterceptRouteRules.active(_chain, _chain_timer):
		var ratio := clampf(_chain_timer / InterceptRouteRules.CHAIN_SECONDS, 0.0, 1.0)
		var color := Color(0.78,0.96,1.0,0.94)
		PixelFont.draw_text(surface, InterceptRouteRules.label(_chain), Vector2(448, 300), 1, color, 1)
		surface.draw_rect(Rect2(448, 309, roundf(84.0 * ratio), 2), color)

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
	for required in ["phase", "player_position", "enemies", "score"]:
		if not names.has(required):
			return false
	return true

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
