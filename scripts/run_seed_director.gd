extends Node

const RunSeedRules = preload("res://scripts/run_seed_rules.gd")

var _scene_id := 0
var _last_phase := -1
var _last_mission_index := -1
var current_mission_seed := RunSeedRules.mission_seed(0)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	if scene_id != _scene_id:
		_scene_id = scene_id
		_last_phase = int(scene.get("phase"))
		_last_mission_index = int(scene.get("mission_index"))
		_update_seed_for_scene(scene)
		return

	var phase := int(scene.get("phase"))
	var mission_index := int(scene.get("mission_index"))
	if phase != _last_phase and phase == 1:
		_update_seed_for_scene(scene)
	elif mission_index != _last_mission_index and phase != 1:
		_update_seed_for_scene(scene)
	_last_phase = phase
	_last_mission_index = mission_index

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "mission_index"]:
		if not names.has(required):
			return false
	return true

func _update_seed_for_scene(scene: Object) -> void:
	var mission_index := maxi(0, int(scene.get("mission_index")))
	current_mission_seed = RunSeedRules.mission_seed(mission_index)
	if _has_property(scene, "status_text") and int(scene.get("phase")) != 1:
		scene.set("status_text", "MISSION SEED %d" % current_mission_seed)
	if _has_property(scene, "status_timer") and int(scene.get("phase")) != 1:
		scene.set("status_timer", 1.2)

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
