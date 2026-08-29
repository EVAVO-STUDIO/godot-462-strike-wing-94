extends Node

const RewardRules = preload("res://scripts/reward_rules.gd")

var _scene_id := 0
var _last_phase := -1
var _applied_key := ""

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	if scene_id != _scene_id:
		_scene_id = scene_id
		_last_phase = int(scene.get("phase"))
		_applied_key = ""
		return

	var phase := int(scene.get("phase"))
	if phase == 2 and _last_phase != 2:
		_apply_result_bonus(scene)
	_last_phase = phase

func _supports(scene: Object) -> bool:
	var required := ["phase", "mission_index", "credits", "hull", "campaign", "current_boss_id", "current_objectives", "objective_progress", "result_text", "shots_fired", "shots_hit"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _apply_result_bonus(scene: Object) -> void:
	var result_text := str(scene.get("result_text"))
	if not result_text.begins_with("MISSION COMPLETE"):
		return
	var key := "%d:%d" % [scene.get_instance_id(), int(scene.get("mission_index"))]
	if key == _applied_key:
		return
	var campaign_data = scene.get("campaign")
	if typeof(campaign_data) != TYPE_DICTIONARY:
		return
	var progression: Dictionary = campaign_data.get("progression", {})
	var campaign_cfg: Dictionary = campaign_data.get("campaign", {})
	var starting_hull := maxi(1, int(campaign_cfg.get("starting_hull", 100)))
	var shots_fired := maxi(0, int(scene.get("shots_fired")))
	var shots_hit := clampi(int(scene.get("shots_hit")), 0, shots_fired)
	var bonus := RewardRules.extra_success_bonus(
		progression,
		int(scene.get("hull")),
		starting_hull,
		str(scene.get("current_boss_id")),
		scene.get("current_objectives"),
		scene.get("objective_progress"),
		shots_fired,
		shots_hit
	)
	var total := int(bonus.get("total", 0))
	var parts: Array[String] = []
	if int(bonus.get("no_damage", 0)) > 0:
		parts.append("NO DAMAGE +%d" % int(bonus["no_damage"]))
	if int(bonus.get("boss", 0)) > 0:
		parts.append("BOSS +%d" % int(bonus["boss"]))
	if int(bonus.get("accuracy", 0)) > 0:
		parts.append("ACCURACY %d%% +%d" % [int(round(float(bonus.get("accuracy_ratio", 0.0)) * 100.0)), int(bonus["accuracy"])])
	elif shots_fired > 0:
		parts.append("ACCURACY %d%%" % int(round(float(bonus.get("accuracy_ratio", 0.0)) * 100.0)))
	if total > 0:
		scene.set("credits", int(scene.get("credits")) + total)
	if not parts.is_empty():
		scene.set("result_text", "%s  %s" % [result_text, "  ".join(parts)])
	_applied_key = key
