extends Node

const BombRules = preload("res://scripts/bomb_rules.gd")

var _scene_id := 0
var _held_bosses: Array = []
var _restore_pending := false

func _ready() -> void:
	process_priority = -50

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		_reset_state()
		return
	var scene_id := scene.get_instance_id()
	if scene_id != _scene_id:
		_scene_id = scene_id
		_reset_state()

	if _restore_pending:
		_restore_bosses(scene)

	if int(scene.get("phase")) != 1:
		return
	if not Input.is_action_just_pressed("fire_secondary"):
		return
	if int(scene.get("bombs")) <= 0 or float(scene.get("secondary_timer")) > 0.0:
		return
	_hold_bosses(scene)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "bombs", "secondary_timer", "enemies"]:
		if not names.has(required):
			return false
	return true

func _hold_bosses(scene: Object) -> void:
	var enemies: Array = scene.get("enemies")
	var survivors: Array = []
	_held_bosses.clear()
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			survivors.append(enemy)
			continue
		if not bool(enemy.get("boss", false)):
			survivors.append(enemy)
			continue
		var boss: Dictionary = enemy.duplicate(true)
		var hp := maxi(1, int(boss.get("hp", 1)))
		var max_hp := maxi(hp, int(boss.get("max_hp", hp)))
		boss["hp"] = BombRules.apply_nonlethal_boss_damage(hp, max_hp)
		boss["max_hp"] = max_hp
		boss["last_hp"] = int(boss["hp"])
		_held_bosses.append(boss)
	if _held_bosses.is_empty():
		return
	scene.set("enemies", survivors)
	_restore_pending = true

func _restore_bosses(scene: Object) -> void:
	var enemies: Array = scene.get("enemies")
	for boss in _held_bosses:
		enemies.append(boss)
	scene.set("enemies", enemies)
	if _has_property(scene, "status_text"):
		scene.set("status_text", "BOMB STRIKE - BOSS DAMAGED")
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 1.5)
	_held_bosses.clear()
	_restore_pending = false

func _reset_state() -> void:
	_held_bosses.clear()
	_restore_pending = false

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
