extends CanvasLayer

const CombatFxSurface = preload("res://scripts/combat_fx_surface.gd")

const MAX_EVENTS := 48
const HIT_SECONDS := 0.12
const EXPLOSION_SECONDS := 0.42
const BOSS_EXPLOSION_SECONDS := 0.68
const PLAYER_HIT_SECONDS := 0.18

var _surface: Control
var _events: Array = []
var _previous_enemies: Array = []
var _previous_hull := -1
var _previous_shield := -1
var _serial := 0

func _ready() -> void:
	layer = 16
	process_priority = 80
	_surface = CombatFxSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_update_events(delta)
	_observe_combat()
	if _surface != null:
		_surface.queue_redraw()

func _observe_combat() -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		_previous_enemies.clear()
		_previous_hull = -1
		_previous_shield = -1
		return

	var current: Array = []
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			current.append({
				"id": str(enemy.get("id", "enemy")),
				"position": Vector2(enemy.get("position", Vector2.ZERO)),
				"hp": int(enemy.get("hp", 0)),
				"boss": bool(enemy.get("boss", false))
			})

	var matched_current: Dictionary = {}
	for previous in _previous_enemies:
		var match_index := _nearest_match(previous, current, matched_current)
		if match_index >= 0:
			matched_current[match_index] = true
			var now: Dictionary = current[match_index]
			if int(now.get("hp", 0)) < int(previous.get("hp", 0)):
				_emit("hit", Vector2(now.get("position", Vector2.ZERO)), 8.0, HIT_SECONDS)
		else:
			var kind := "boss_explosion" if bool(previous.get("boss", false)) else "explosion"
			var duration := BOSS_EXPLOSION_SECONDS if kind == "boss_explosion" else EXPLOSION_SECONDS
			var size := 28.0 if kind == "boss_explosion" else 15.0
			_emit(kind, Vector2(previous.get("position", Vector2.ZERO)), size, duration)

	var hull := int(scene.get("hull"))
	var shield := int(scene.get("shield"))
	if (_previous_hull >= 0 and hull < _previous_hull) or (_previous_shield >= 0 and shield < _previous_shield):
		_emit("player_hit", Vector2(scene.get("player_position")), 13.0, PLAYER_HIT_SECONDS)
	_previous_hull = hull
	_previous_shield = shield
	_previous_enemies = current

func _nearest_match(previous: Dictionary, current: Array, used: Dictionary) -> int:
	var best := -1
	var best_distance := INF
	var previous_id := str(previous.get("id", ""))
	var previous_position: Vector2 = previous.get("position", Vector2.ZERO)
	for i in range(current.size()):
		if used.has(i):
			continue
		var candidate: Dictionary = current[i]
		if str(candidate.get("id", "")) != previous_id:
			continue
		var distance := previous_position.distance_squared_to(Vector2(candidate.get("position", Vector2.ZERO)))
		if distance < best_distance and distance <= 180.0 * 180.0:
			best_distance = distance
			best = i
	return best

func _emit(kind: String, position: Vector2, size: float, duration: float) -> void:
	_serial += 1
	_events.append({
		"kind": kind,
		"position": position,
		"size": size,
		"age": 0.0,
		"duration": duration,
		"serial": _serial
	})
	while _events.size() > MAX_EVENTS:
		_events.pop_front()

func _update_events(delta: float) -> void:
	for i in range(_events.size() - 1, -1, -1):
		var event: Dictionary = _events[i]
		event["age"] = float(event.get("age", 0.0)) + maxf(0.0, delta)
		if float(event["age"]) >= float(event.get("duration", 0.1)):
			_events.remove_at(i)
		else:
			_events[i] = event

func _draw_combat_fx(surface: CanvasItem) -> void:
	for event in _events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var kind := str(event.get("kind", "hit"))
		var position: Vector2 = event.get("position", Vector2.ZERO)
		var duration := maxf(0.001, float(event.get("duration", 0.1)))
		var ratio := clampf(float(event.get("age", 0.0)) / duration, 0.0, 1.0)
		match kind:
			"hit":
				_draw_hit(surface, position, ratio)
			"explosion":
				_draw_explosion(surface, position, ratio, float(event.get("size", 15.0)), int(event.get("serial", 0)), false)
			"boss_explosion":
				_draw_explosion(surface, position, ratio, float(event.get("size", 28.0)), int(event.get("serial", 0)), true)
			"player_hit":
				_draw_player_hit(surface, position, ratio)

func _draw_hit(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var alpha := 1.0 - ratio
	var outer := Color(1.0, 0.56, 0.22, 0.92 * alpha)
	var core := Color(1.0, 0.94, 0.62, 0.98 * alpha)
	var length := roundf(4.0 + ratio * 5.0)
	surface.draw_line(p + Vector2(-length, 0), p + Vector2(length, 0), outer, 1.0)
	surface.draw_line(p + Vector2(0, -length), p + Vector2(0, length), outer, 1.0)
	surface.draw_rect(Rect2(roundf(p.x)-1, roundf(p.y)-1, 3, 3), core)

func _draw_explosion(surface: CanvasItem, p: Vector2, ratio: float, max_size: float, serial: int, boss: bool) -> void:
	var eased := smoothstep(0.0, 1.0, ratio)
	var radius := maxf(2.0, max_size * eased)
	var fade := 1.0 - ratio
	var hot := Color(1.0, 0.82, 0.36, 0.92 * fade)
	var fire := Color(0.96, 0.33, 0.16, 0.76 * fade)
	var smoke := Color(0.42, 0.45, 0.44, 0.42 * fade)
	surface.draw_arc(p, radius, 0.0, TAU, 16 if boss else 10, fire, 2.0)
	if ratio < 0.52:
		surface.draw_circle(p, maxf(1.0, radius * 0.34), hot)
	for i in range(8 if boss else 5):
		var angle := float((serial * 37 + i * 71) % 360) * PI / 180.0
		var distance := radius * (0.38 + float((serial + i * 3) % 5) * 0.11)
		var point := p + Vector2.RIGHT.rotated(angle) * distance
		var pixel := 2.0 if boss and i % 2 == 0 else 1.0
		surface.draw_rect(Rect2(roundf(point.x), roundf(point.y), pixel, pixel), smoke if ratio > 0.45 else fire)

func _draw_player_hit(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var alpha := (1.0 - ratio) * 0.82
	var color := Color(0.42, 0.84, 0.96, alpha)
	var radius := 9.0 + ratio * 9.0
	surface.draw_arc(p, radius, 0.0, TAU, 14, color, 1.0)
	for offset in [Vector2(-8,-4), Vector2(8,-4), Vector2(-5,7), Vector2(5,7)]:
		surface.draw_rect(Rect2(roundf(p.x+offset.x), roundf(p.y+offset.y), 2, 2), color)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "enemies", "hull", "shield", "player_position"]:
		if not names.has(required):
			return false
	return true
