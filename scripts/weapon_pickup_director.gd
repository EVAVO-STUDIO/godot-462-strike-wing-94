extends Node

const WeaponPickupRules = preload("res://scripts/weapon_pickup_rules.gd")

var _scene_id := 0
var _last_phase := -1
var _permanent_index := 0
var _last_seen_index := 0

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	var phase := int(scene.get("phase"))
	var current_index := int(scene.get("weapon_index"))
	if scene_id != _scene_id:
		_scene_id = scene_id
		_permanent_index = current_index
		_last_seen_index = current_index
		_last_phase = phase
		return

	if phase != 1:
		if _last_phase == 1 and current_index != _permanent_index:
			scene.set("weapon_index", _permanent_index)
			current_index = _permanent_index
		elif current_index != _last_seen_index:
			_permanent_index = current_index
	else:
		if _last_phase != 1:
			_permanent_index = current_index

	_last_seen_index = current_index
	_last_phase = phase

func permanent_index(scene: Object) -> int:
	if scene == null or not _supports(scene):
		return 0
	var count := _primary_weapon_count(scene)
	return WeaponPickupRules.saved_index(_permanent_index, count)

func temporary_boost(scene: Object) -> int:
	if scene == null or not _supports(scene):
		return 0
	return WeaponPickupRules.temporary_boost_for_indices(_permanent_index, int(scene.get("weapon_index")))

func _primary_weapon_count(scene: Object) -> int:
	var catalog = scene.get("weapon_catalog")
	if typeof(catalog) != TYPE_ARRAY:
		return 1
	var count := 0
	for weapon in catalog:
		if typeof(weapon) == TYPE_DICTIONARY and str(weapon.get("slot", "")) == "primary":
			count += 1
	return maxi(1, count)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("weapon_index") and names.has("weapon_catalog")
