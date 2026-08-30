extends CanvasLayer

const CombatFxSurface = preload("res://scripts/combat_fx_surface.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const EXPLOSION_FRAMES := [
	preload("res://assets/runtime/effects/explosion/explosion_0.png"),
	preload("res://assets/runtime/effects/explosion/explosion_1.png"),
	preload("res://assets/runtime/effects/explosion/explosion_2.png"),
	preload("res://assets/runtime/effects/explosion/explosion_3.png"),
	preload("res://assets/runtime/effects/explosion/explosion_4.png"),
	preload("res://assets/runtime/effects/explosion/explosion_5.png"),
	preload("res://assets/runtime/effects/explosion/explosion_6.png"),
	preload("res://assets/runtime/effects/explosion/explosion_7.png"),
]

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
var _hit_audio_cooldown := 0.0

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
	_hit_audio_cooldown = maxf(0.0, _hit_audio_cooldown - delta)
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
				"boss": bool(enemy.get("boss", false)),
				"category": str(enemy.get("category", "air")),
				"faction": str(enemy.get("faction", "mercenary"))
			})

	var matched_current: Dictionary = {}
	for previous in _previous_enemies:
		var match_index := _nearest_match(previous, current, matched_current)
		var now: Dictionary = current[match_index] if match_index >= 0 else {}
		var observation := _observation_kind(previous, now, match_index >= 0)
		if match_index >= 0:
			matched_current[match_index] = true
		if observation == "hit":
			_emit("hit", Vector2(now.get("position", Vector2.ZERO)), 8.0, HIT_SECONDS, {"category": str(now.get("category", "air"))})
		elif observation == "destroyed":
			var kind := "boss_explosion" if bool(previous.get("boss", false)) else "explosion"
			var duration := BOSS_EXPLOSION_SECONDS if kind == "boss_explosion" else EXPLOSION_SECONDS
			var size := 28.0 if kind == "boss_explosion" else 15.0
			_emit(kind, Vector2(previous.get("position", Vector2.ZERO)), size, duration, {
				"category": str(previous.get("category", "air")),
				"faction": str(previous.get("faction", "mercenary"))
			})

	var hull := int(scene.get("hull"))
	var shield := int(scene.get("shield"))
	if (_previous_hull >= 0 and hull < _previous_hull) or (_previous_shield >= 0 and shield < _previous_shield):
		_emit("player_hit", Vector2(scene.get("player_position")), 13.0, PLAYER_HIT_SECONDS, {"shield": _previous_shield >= 0 and shield < _previous_shield})
	_previous_hull = hull
	_previous_shield = shield
	_previous_enemies = current

func _observation_kind(previous: Dictionary, current: Dictionary, matched: bool) -> String:
	if not matched:
		return "destroyed"
	if int(current.get("hp", 0)) < int(previous.get("hp", 0)):
		return "hit"
	return ""

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

func _emit(kind: String, position: Vector2, size: float, duration: float, metadata := {}) -> void:
	_serial += 1
	var event := {
		"kind": kind,
		"position": position,
		"size": size,
		"age": 0.0,
		"duration": duration,
		"serial": _serial
	}
	if typeof(metadata) == TYPE_DICTIONARY:
		for key in metadata:
			event[key] = metadata[key]
	_events.append(event)
	while _events.size() > MAX_EVENTS:
		_events.pop_front()
	_play_audio_for(kind)

func _play_audio_for(kind: String) -> void:
	var event_id := ""
	match kind:
		"hit":
			if _hit_audio_cooldown > 0.0:
				return
			_hit_audio_cooldown = 0.035
			event_id = RetroSfxRules.HIT
		"explosion":
			event_id = RetroSfxRules.EXPLOSION
		"boss_explosion":
			event_id = RetroSfxRules.BOSS_EXPLOSION
		"player_hit":
			event_id = RetroSfxRules.PLAYER_HIT
	if event_id == "":
		return
	var audio := get_node_or_null("/root/RetroSfxDirector")
	if audio != null and audio.has_method("play_event"):
		audio.call("play_event", event_id)

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
				_draw_hit(surface, position, ratio, str(event.get("category", "air")))
			"explosion":
				_draw_explosion(surface, position, ratio, float(event.get("size", 15.0)), int(event.get("serial", 0)), false)
			"boss_explosion":
				_draw_explosion(surface, position, ratio, float(event.get("size", 28.0)), int(event.get("serial", 0)), true)
			"player_hit":
				_draw_player_hit(surface, position, ratio, bool(event.get("shield", true)))

func _draw_hit(surface: CanvasItem, p: Vector2, ratio: float, category: String) -> void:
	var family := "water_impact" if category == "sea" else "armor_hit"
	var texture := ImpactArtLibrary.frame_for_ratio(family, ratio)
	surface.draw_texture(texture, (p - Vector2(12, 12)).round())

func _draw_explosion(surface: CanvasItem, p: Vector2, ratio: float, max_size: float, serial: int, boss: bool) -> void:
	var frame_index := clampi(int(floor(ratio * float(EXPLOSION_FRAMES.size()))), 0, EXPLOSION_FRAMES.size() - 1)
	var frame: Texture2D = EXPLOSION_FRAMES[frame_index]
	var draw_size := roundf(max_size * (2.35 if boss else 2.20))
	surface.draw_texture_rect(frame, Rect2((p - Vector2.ONE * draw_size * 0.5).round(), Vector2.ONE * draw_size), false)
	var radius := maxf(2.0, max_size * smoothstep(0.0, 1.0, ratio))
	var debris := PersistentEffectArtLibrary.frame_for_ratio("debris", ratio)
	var debris_size := Vector2.ONE * maxf(24.0, radius * (2.4 if boss else 2.0))
	surface.draw_texture_rect(debris, Rect2((p - debris_size * 0.5).round(), debris_size), false, Color(1,1,1,1.0-ratio))

func _draw_player_hit(surface: CanvasItem, p: Vector2, ratio: float, shield: bool) -> void:
	var texture := ImpactArtLibrary.frame_for_ratio("shield_hit" if shield else "armor_hit", ratio)
	var size := Vector2.ONE * 34.0 if shield else Vector2.ONE * 26.0
	surface.draw_texture_rect(texture, Rect2((p - size * 0.5).round(), size), false)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "enemies", "hull", "shield", "player_position"]:
		if not names.has(required):
			return false
	return true
