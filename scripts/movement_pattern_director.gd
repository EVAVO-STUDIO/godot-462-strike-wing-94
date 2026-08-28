extends Node

const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")
const MIN_X := 36.0
const MAX_X := 604.0

func _ready() -> void:
	process_priority = 50

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	if int(scene.get("phase")) != 1:
		return
	var enemies: Array = scene.get("enemies")
	var catalog: Array = scene.get("enemy_catalog")
	var player: Vector2 = scene.get("player_position")
	var changed := false
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if bool(enemy.get("boss", false)):
			continue
		var pattern := _pattern_for_id(catalog, str(enemy.get("id", "")))
		if pattern == "" or pattern not in MovementPatternRules.supported_patterns():
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var anchor_x := float(enemy.get("pattern_anchor_x", position.x))
		enemy["pattern_anchor_x"] = anchor_x
		position = MovementPatternRules.adjusted_position(
			pattern,
			position,
			player,
			float(enemy.get("age", 0.0)),
			delta,
			anchor_x
		)
		enemy["position"] = MovementPatternRules.clamp_x(position, MIN_X, MAX_X)
		enemies[i] = enemy
		changed = true
	if changed:
		scene.set("enemies", enemies)

func _supports(scene: Object) -> bool:
	var required := ["phase", "enemies", "enemy_catalog", "player_position"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _pattern_for_id(catalog: Array, enemy_id: String) -> String:
	for item in catalog:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == enemy_id:
			return str(item.get("pattern", ""))
	return ""
