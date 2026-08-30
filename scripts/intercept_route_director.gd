extends CanvasLayer

const InterceptRouteSurface = preload("res://scripts/intercept_route_surface.gd")
const InterceptRouteRules = preload("res://scripts/intercept_route_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const TARGET_FRAME := preload("res://assets/runtime/ui/hud/intercept_route/target_frame.png")
const CLOSURE_TROUGH := preload("res://assets/runtime/ui/hud/intercept_route/closure_trough.png")
const CLOSURE_FILL := preload("res://assets/runtime/ui/hud/intercept_route/closure_fill.png")
const CHAIN_TROUGH := preload("res://assets/runtime/ui/hud/intercept_route/chain_trough.png")
const CHAIN_FILL := preload("res://assets/runtime/ui/hud/intercept_route/chain_fill.png")

var _surface: Control
var _previous_targets: Dictionary = {}
var _last_score := 0
var _chain := 0
var _best_chain := 0
var _chain_timer := 0.0
var _last_phase := -1

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
	var scene := get_tree().current_scene
	var phase := int(scene.get("phase")) if scene != null and _has_property(scene, "phase") else -1
	if phase == 1 and _last_phase != 1:
		_chain = 0
		_best_chain = 0
		_chain_timer = 0.0
		_previous_targets.clear()
		_last_score = int(scene.get("score")) if _has_property(scene, "score") else 0
	_chain_timer = maxf(0.0, _chain_timer - maxf(0.0, delta))
	if _chain_timer <= 0.0:
		_chain = 0
	_observe_route_kills()
	_last_phase = phase
	if _surface != null:
		_surface.queue_redraw()

func best_chain() -> int:
	return _best_chain

func current_chain() -> int:
	return _chain

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
			_best_chain = maxi(_best_chain, _chain)
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
		surface.draw_texture(CHAIN_TROUGH, Vector2(448, 309))
		_draw_clipped_fill(surface, CHAIN_FILL, Vector2(448, 309), ratio)

func _draw_target(surface: CanvasItem, player: Vector2, enemy: Dictionary) -> void:
	var p: Vector2 = enemy.get("position", Vector2.ZERO)
	var distance := p.distance_to(player)
	var bracket := Color(0.56,0.88,1.0,0.92)
	surface.draw_texture(TARGET_FRAME, (p - Vector2(16,16)).round())
	var closure_ratio := clampf(1.0 - distance / 420.0, 0.0, 1.0)
	var gauge_position := (p + Vector2(-8, 15)).round()
	surface.draw_texture(CLOSURE_TROUGH, gauge_position)
	_draw_clipped_fill(surface, CLOSURE_FILL, gauge_position, closure_ratio)
	PixelFont.draw_text(surface, "INT %03d" % int(round(distance)), p + Vector2(-12, 19), 1, bracket, 1)

func _draw_clipped_fill(surface: CanvasItem, texture: Texture2D, position: Vector2, ratio: float) -> void:
	var width := floorf(float(texture.get_width()) * clampf(ratio, 0.0, 1.0))
	if width > 0.0:
		surface.draw_texture_rect_region(texture, Rect2(position, Vector2(width, texture.get_height())), Rect2(0, 0, width, texture.get_height()))

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
