extends Node

const EncounterRules = preload("res://scripts/encounter_rules.gd")

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
	for required in ["phase", "mission_time", "mission_index", "mission_catalog", "enemy_catalog", "enemy_spawn_timer", "pickups", "status_text", "status_timer", "shots_fired", "shots_hit", "score", "bombs"]:
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
		"bombs": int(scene.get("bombs"))
	}

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
	for enemy_id in EncounterRules.expanded_enemy_ids(beat):
		var archetype := _enemy_for_id(scene.get("enemy_catalog"), enemy_id)
		if not archetype.is_empty() and not bool(archetype.get("boss", false)):
			scene.call("_spawn_enemy", archetype)
	var pickup_kind := EncounterRules.reward_pickup(beat)
	if pickup_kind != "":
		var pickups: Array = scene.get("pickups")
		pickups.append({"position":Vector2(320.0, 74.0), "kind":pickup_kind})
		scene.set("pickups", pickups)
	var suppression := EncounterRules.suppression_seconds(beat)
	if suppression > 0.0:
		scene.set("enemy_spawn_timer", maxf(float(scene.get("enemy_spawn_timer")), suppression))
	var prefix := "SECRET - " if EncounterRules.is_secret(beat) else ""
	scene.set("status_text", "%s%s" % [prefix, EncounterRules.label(beat)])
	scene.set("status_timer", 2.4 if EncounterRules.is_secret(beat) else 2.2)

func _enemy_for_id(catalog: Array, enemy_id: String) -> Dictionary:
	for enemy in catalog:
		if typeof(enemy) == TYPE_DICTIONARY and str(enemy.get("id", "")) == enemy_id:
			return enemy
	return {}
