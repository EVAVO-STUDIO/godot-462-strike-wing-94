extends Node

var _scene_id := 0
var _last_phase := -1
var _shots_fired := 0
var _shots_hit := 0
var _pending_hit_snapshot: Dictionary = {}
var _pending_bombs := 0

func _ready() -> void:
	process_priority = -100

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	if scene_id != _scene_id:
		_scene_id = scene_id
		_last_phase = int(scene.get("phase"))
		_reset_counts()
		return

	var phase := int(scene.get("phase"))
	if phase == 1 and _last_phase != 1:
		_reset_counts()
	if phase == 1:
		_count_fire_trigger(scene)
		_pending_hit_snapshot = _enemy_hp_snapshot(scene)
		_pending_bombs = int(scene.get("bombs"))
		call_deferred("_after_frame", scene_id)
	_last_phase = phase

func _supports(scene: Object) -> bool:
	var required := ["phase", "fire_timer", "bombs", "enemies", "weapon_catalog", "weapon_index"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _count_fire_trigger(scene: Object) -> void:
	if not Input.is_action_pressed("fire_primary") or float(scene.get("fire_timer")) > 0.0:
		return
	var weapon := _active_weapon(scene)
	_shots_fired += maxi(1, int(weapon.get("projectiles", 1)))

func _after_frame(expected_scene_id: int) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.get_instance_id() != expected_scene_id or int(scene.get("phase")) != 1:
		return
	if int(scene.get("bombs")) < _pending_bombs:
		return
	var after := _enemy_hp_snapshot(scene)
	for key in _pending_hit_snapshot.keys():
		var before_hp := int(_pending_hit_snapshot[key])
		if after.has(key) and int(after[key]) < before_hp:
			_shots_hit += 1
		elif not after.has(key):
			_shots_hit += 1

func _enemy_hp_snapshot(scene: Object) -> Dictionary:
	var result: Dictionary = {}
	var enemies = scene.get("enemies")
	if typeof(enemies) != TYPE_ARRAY:
		return result
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var key := "%s:%d" % [str(enemy.get("id", "enemy")), i]
		result[key] = int(enemy.get("hp", 0))
	return result

func _active_weapon(scene: Object) -> Dictionary:
	var primaries: Array = []
	var catalog = scene.get("weapon_catalog")
	if typeof(catalog) == TYPE_ARRAY:
		for weapon in catalog:
			if typeof(weapon) == TYPE_DICTIONARY and str(weapon.get("slot", "")) == "primary":
				primaries.append(weapon)
	if primaries.is_empty():
		return {"projectiles": 1}
	var index := clampi(int(scene.get("weapon_index")), 0, primaries.size() - 1)
	return primaries[index]

func _reset_counts() -> void:
	_shots_fired = 0
	_shots_hit = 0
	_pending_hit_snapshot.clear()

func shots_fired() -> int:
	return _shots_fired

func shots_hit() -> int:
	return mini(_shots_hit, _shots_fired)

func accuracy_ratio() -> float:
	if _shots_fired <= 0:
		return 0.0
	return clampf(float(shots_hit()) / float(_shots_fired), 0.0, 1.0)
