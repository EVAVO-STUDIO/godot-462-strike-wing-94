extends Node

const SAVE_PATH := "user://strike_wing_94_save.json"
const SAVE_VERSION := 2
const SAVE_INTERVAL := 1.0
const MAX_CREDITS := 99999999

var _restored_scene_id := 0
var _timer := 0.0
var _last_signature := ""

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports_campaign_state(scene):
		return
	var scene_id := scene.get_instance_id()
	if _restored_scene_id != scene_id:
		_restore(scene)
		_restored_scene_id = scene_id
		_last_signature = _signature(scene)
		_timer = 0.0
		return
	_timer += delta
	if _timer < SAVE_INTERVAL:
		return
	_timer = 0.0
	var signature := _signature(scene)
	if signature != _last_signature:
		_save(scene)
		_last_signature = signature

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var scene := get_tree().current_scene
		if scene != null and _supports_campaign_state(scene):
			_save(scene)

func _supports_campaign_state(scene: Object) -> bool:
	var required := ["credits", "mission_index", "weapon_index"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _mission_count(scene: Object) -> int:
	var catalog = scene.get("mission_catalog")
	if typeof(catalog) == TYPE_ARRAY:
		return maxi(1, catalog.size())
	return 1

func _primary_weapon_count(scene: Object) -> int:
	var catalog = scene.get("weapon_catalog")
	if typeof(catalog) != TYPE_ARRAY:
		return 1
	var count := 0
	for weapon in catalog:
		if typeof(weapon) == TYPE_DICTIONARY and str(weapon.get("slot", "")) == "primary":
			count += 1
	return maxi(1, count)

func _saved_weapon_index(scene: Object) -> int:
	var count := _primary_weapon_count(scene)
	var director := get_node_or_null("/root/WeaponPickupDirector")
	if director != null and director.has_method("permanent_index"):
		return clampi(int(director.call("permanent_index")), 0, count - 1)
	return clampi(int(scene.get("weapon_index")), 0, count - 1)

func _service_value(method_name: String, fallback: int) -> int:
	var director := get_node_or_null("/root/ServiceDirector")
	if director != null and director.has_method(method_name):
		return int(director.call(method_name))
	return fallback

func _snapshot(scene: Object) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"credits": clampi(int(scene.get("credits")), 0, MAX_CREDITS),
		"mission_index": clampi(int(scene.get("mission_index")), 0, _mission_count(scene) - 1),
		"weapon_index": _saved_weapon_index(scene),
		"service_hull": maxi(1, _service_value("service_hull", int(scene.get("hull")))),
		"service_shield": maxi(0, _service_value("service_shield", int(scene.get("shield"))))
	}

func _signature(scene: Object) -> String:
	return JSON.stringify(_snapshot(scene))

func _save(scene: Object) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Strike Wing save could not be opened for writing.")
		return
	file.store_string(JSON.stringify(_snapshot(scene), "  "))

func _restore(scene: Object) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Strike Wing save ignored because it is invalid.")
		return
	var version := int(parsed.get("version", -1))
	if version < 1 or version > SAVE_VERSION:
		push_warning("Strike Wing save ignored because it is from an unsupported version.")
		return
	var mission_index := clampi(int(parsed.get("mission_index", scene.get("mission_index"))), 0, _mission_count(scene) - 1)
	var weapon_index := clampi(int(parsed.get("weapon_index", scene.get("weapon_index"))), 0, _primary_weapon_count(scene) - 1)
	var credits := clampi(int(parsed.get("credits", scene.get("credits"))), 0, MAX_CREDITS)
	scene.set("credits", credits)
	scene.set("mission_index", mission_index)
	scene.set("weapon_index", weapon_index)
	var service_hull := int(parsed.get("service_hull", scene.get("hull")))
	var service_shield := int(parsed.get("service_shield", scene.get("shield")))
	var service_director := get_node_or_null("/root/ServiceDirector")
	if service_director != null and service_director.has_method("restore_service_state"):
		service_director.call("restore_service_state", service_hull, service_shield)
	if scene.has_method("_prepare_mission"):
		scene.call("_prepare_mission", mission_index)
