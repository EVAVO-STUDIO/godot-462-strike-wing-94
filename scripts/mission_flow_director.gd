extends Node

const MissionFlowRules = preload("res://scripts/mission_flow_rules.gd")

func _ready() -> void:
	process_priority = -40

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	if not MissionFlowRules.should_hold_overtime(
		str(scene.get("current_boss_id")),
		scene.get("current_objectives"),
		scene.get("objective_progress"),
		scene.get("enemies")
	):
		return
	var duration := float(scene.get("mission_duration"))
	var mission_time := float(scene.get("mission_time"))
	if mission_time + delta < duration:
		return
	scene.set("mission_time", MissionFlowRules.safe_pre_frame_time(mission_time, duration, delta))
	if _has_property(scene, "status_text"):
		scene.set("status_text", "OVERTIME - DESTROY THE BOSS")
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 0.3)

func _supports(scene: Object) -> bool:
	var required := ["phase", "mission_time", "mission_duration", "current_boss_id", "current_objectives", "objective_progress", "enemies"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
