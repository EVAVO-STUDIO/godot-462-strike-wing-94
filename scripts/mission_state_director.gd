extends Node

const MissionStateRules = preload("res://scripts/mission_state_rules.gd")

var _scene_id := 0
var _last_phase := -1

func _ready() -> void:
	process_priority = 100

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	if scene_id != _scene_id:
		_scene_id = scene_id
		_last_phase = int(scene.get("phase"))

	var phase := int(scene.get("phase"))
	if phase == 1:
		var mission := _active_mission(scene)
		var campaign := _campaign_config(scene)
		if _last_phase != 1:
			scene.set("hull", MissionStateRules.starting_hull(campaign, int(scene.get("hull"))))
			scene.set("shield", MissionStateRules.starting_shield(campaign, int(scene.get("shield"))))
		scene.set("wave", MissionStateRules.live_wave(mission, float(scene.get("mission_time"))))
	_last_phase = phase

func _supports(scene: Object) -> bool:
	var required := ["phase", "mission_index", "mission_time", "mission_catalog", "campaign", "hull", "shield", "wave"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _active_mission(scene: Object) -> Dictionary:
	var missions = scene.get("mission_catalog")
	if typeof(missions) != TYPE_ARRAY or missions.is_empty():
		return {}
	var index := clampi(int(scene.get("mission_index")), 0, missions.size() - 1)
	var mission = missions[index]
	return mission if typeof(mission) == TYPE_DICTIONARY else {}

func _campaign_config(scene: Object) -> Dictionary:
	var data = scene.get("campaign")
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var nested = data.get("campaign", data)
	return nested if typeof(nested) == TYPE_DICTIONARY else {}
