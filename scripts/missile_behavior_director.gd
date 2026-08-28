extends Node

const MissileBehaviorRules = preload("res://scripts/missile_behavior_rules.gd")

func _ready() -> void:
	process_priority = 10

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var bullets = scene.get("enemy_bullets")
	var enemies = scene.get("enemies")
	if typeof(bullets) != TYPE_ARRAY or typeof(enemies) != TYPE_ARRAY:
		return
	var changed := false
	for i in range(bullets.size()):
		var shot = bullets[i]
		if typeof(shot) != TYPE_DICTIONARY or bool(shot.get("homing", false)):
			continue
		if not MissileBehaviorRules.missile_launcher_near(shot, enemies):
			continue
		bullets[i] = MissileBehaviorRules.apply_homing_metadata(shot)
		changed = true
	if changed:
		scene.set("enemy_bullets", bullets)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("enemy_bullets") and names.has("enemies")
