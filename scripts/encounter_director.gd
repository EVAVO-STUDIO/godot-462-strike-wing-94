extends Node

const EncounterRules = preload("res://scripts/encounter_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const FORMATION_MIN_X := 58.0
const FORMATION_MAX_X := 582.0

var _scene_id := 0
var _last_phase := -1
var _next_beat_index := 0

func _ready() -> void:
	process_priority = -20

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	var phase := int(scene.get("phase"))
	if scene_id != _scene_id:
		_scene_id = scene_id
		_last_phase = phase
		_next_beat_index = 0
		return
	if phase == 1 and _last_phase != 1:
		_next_beat_index = 0
	if phase == 1:
		_apply_due_beats(scene)
	_last_phase = phase

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "mission_time", "mission_index", "mission_catalog", "enemy_catalog", "enemies", "enemy_spawn_timer", "pickups", "status_text", "status_timer", "shots_fired", "shots_hit", "score", "bombs"]:
		if not names.has(required):
			return false
	return scene.has_method("_spawn_enemy")

func _active_mission(scene: Object) -> Dictionary:
	var missions: Array = scene.get("mission_catalog")
	if missions.is_empty():
		return {}
	var index := clampi(int(scene.get("mission_index")), 0, missions.size() - 1)
	var mission = missions[index]
	return mission if typeof(mission) == TYPE_DICTIONARY else {}

func _condition_state(scene: Object) -> Dictionary:
	return {
		"shots_fired": int(scene.get("shots_fired")),
		"shots_hit": int(scene.get("shots_hit")),
		"score": int(scene.get("score")),
		"bombs": int(scene.get("bombs")),
		"altitude": _current_altitude(),
		"form": _current_form()
	}

func _current_altitude() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_altitude"):
		return str(craft.call("current_altitude"))
	return AltitudeRules.MID

func _current_form() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_form"):
		return str(craft.call("current_form"))
	return "fighter"

func _apply_due_beats(scene: Object) -> void:
	var mission := _active_mission(scene)
	var beats := EncounterRules.beats_for_mission(mission)
	while _next_beat_index < beats.size():
		var beat := EncounterRules.due_beat(beats, _next_beat_index, float(scene.get("mission_time")))
		if beat.is_empty():
			return
		if EncounterRules.condition_met(beat, _condition_state(scene)):
			_apply_beat(scene, beat)
		_next_beat_index += 1

func _apply_beat(scene: Object, beat: Dictionary) -> void:
	var enemy_ids := EncounterRules.expanded_enemy_ids(beat)
	var altitude := _current_altitude()
	var eligible: Array[String] = []
	for enemy_id in enemy_ids:
		var archetype := _enemy_for_id(scene.get("enemy_catalog"), enemy_id)
		if archetype.is_empty() or bool(archetype.get("boss", false)):
			continue
		if AltitudeRules.allows_enemy_archetype(altitude, archetype):
			eligible.append(enemy_id)
	var points := EncounterRules.formation_points(beat, eligible.size())
	var strike_priority := EncounterRules.is_low_bomber_route(beat)
	var intercept_priority := EncounterRules.is_high_fighter_route(beat)
	for i in range(eligible.size()):
		var archetype := _enemy_for_id(scene.get("enemy_catalog"), eligible[i])
		if archetype.is_empty():
			continue
		scene.call("_spawn_enemy", archetype)
		_apply_latest_formation_point(
			scene,
			points[i] if i < points.size() else Vector2(0.5, 0.0),
			strike_priority,
			intercept_priority,
			str(beat.get("id", ""))
		)

	var pickup_kind := EncounterRules.reward_pickup(beat)
	if pickup_kind != "":
		var pickups: Array = scene.get("pickups")
		pickups.append({"position":Vector2(320.0, 74.0), "kind":pickup_kind})
		scene.set("pickups", pickups)

	var suppression := EncounterRules.suppression_seconds(beat)
	if suppression > 0.0:
		scene.set("enemy_spawn_timer", maxf(float(scene.get("enemy_spawn_timer")), suppression))

	var prefix := "SECRET - " if EncounterRules.is_secret(beat) else ""
	var suffix := "" if eligible.size() == enemy_ids.size() else "  ALTITUDE FILTER"
	if strike_priority:
		suffix += "  STRIKE TARGETS"
	elif intercept_priority:
		suffix += "  INTERCEPT TARGETS"
	scene.set("status_text", "%s%s%s" % [prefix, EncounterRules.label(beat), suffix])
	scene.set("status_timer", 2.4 if EncounterRules.is_secret(beat) else 2.2)

func _apply_latest_formation_point(scene: Object, point: Vector2, strike_priority: bool = false, intercept_priority: bool = false, route_id: String = "") -> void:
	var enemies: Array = scene.get("enemies")
	if enemies.is_empty():
		return
	var index := enemies.size() - 1
	var enemy = enemies[index]
	if typeof(enemy) != TYPE_DICTIONARY or bool(enemy.get("boss", false)):
		return
	var position: Vector2 = enemy.get("position", Vector2(320.0, 34.0))
	position.x = lerpf(FORMATION_MIN_X, FORMATION_MAX_X, clampf(point.x, 0.0, 1.0))
	position.y -= maxf(0.0, point.y)
	enemy["position"] = position
	enemy["pattern_anchor_x"] = position.x
	var category := str(enemy.get("category", "air"))
	if strike_priority and category in ["ground", "sea"]:
		enemy["strike_priority"] = true
		enemy["route_bonus_id"] = route_id
	if intercept_priority and category == "air":
		enemy["intercept_priority"] = true
		enemy["route_bonus_id"] = route_id
		enemy["value"] = int(enemy.get("value", 0)) + EncounterRules.HIGH_INTERCEPT_VALUE_BONUS
	enemies[index] = enemy
	scene.set("enemies", enemies)

func _enemy_for_id(catalog: Array, enemy_id: String) -> Dictionary:
	for enemy in catalog:
		if typeof(enemy) == TYPE_DICTIONARY and str(enemy.get("id", "")) == enemy_id:
			return enemy
	return {}
