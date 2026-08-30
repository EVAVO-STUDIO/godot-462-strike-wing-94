extends Node

const SaveRecoveryRules = preload("res://scripts/save_recovery_rules.gd")
const SAVE_VERSION := 5
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
	var required := ["credits", "mission_index", "weapon_index", "generator_index", "service_hull", "service_shield"]
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

func _generator_count(scene: Object) -> int:
	var catalog = scene.get("generator_catalog")
	if typeof(catalog) == TYPE_ARRAY:
		return maxi(1, catalog.size())
	return 1

func _scene_max(scene: Object, method_name: String, fallback: int) -> int:
	return int(scene.call(method_name)) if scene.has_method(method_name) else fallback

func _support_state() -> Dictionary:
	var director := get_node_or_null("/root/SupportDirector")
	if director != null and director.has_method("support_state"):
		var state = director.call("support_state")
		return state if typeof(state) == TYPE_DICTIONARY else {}
	return {"selected_index":0,"unlocked_index":0}

func _airframe_state() -> Dictionary:
	var director := get_node_or_null("/root/AirframeDirector")
	if director != null and director.has_method("airframe_state"):
		var state = director.call("airframe_state")
		return state if typeof(state) == TYPE_DICTIONARY else {}
	return {"airframe_index":0}

func _snapshot(scene: Object) -> Dictionary:
	var max_hull := maxi(1, _scene_max(scene, "_max_hull", 100))
	var max_shield := maxi(0, _scene_max(scene, "_max_shield", 100))
	var support := _support_state()
	var airframe := _airframe_state()
	return {
		"version": SAVE_VERSION,
		"credits": clampi(int(scene.get("credits")), 0, MAX_CREDITS),
		"mission_index": clampi(int(scene.get("mission_index")), 0, _mission_count(scene) - 1),
		"weapon_index": clampi(int(scene.get("weapon_index")), 0, _primary_weapon_count(scene) - 1),
		"generator_index": clampi(int(scene.get("generator_index")), 0, _generator_count(scene) - 1),
		"airframe_index": maxi(0, int(airframe.get("airframe_index", 0))),
		"service_hull": clampi(int(scene.get("service_hull")), 1, max_hull),
		"service_shield": clampi(int(scene.get("service_shield")), 0, max_shield),
		"support_selected": maxi(0, int(support.get("selected_index", 0))),
		"support_unlocked": maxi(0, int(support.get("unlocked_index", 0)))
	}

func _signature(scene: Object) -> String:
	return JSON.stringify(_snapshot(scene))

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	return true

func _backup_current_primary() -> void:
	var current_text := _read_text(_save_path())
	if SaveRecoveryRules.parse_supported_json(current_text, 1, SAVE_VERSION).is_empty():
		return
	if not _write_text(_backup_path(), current_text):
		push_warning("HYPERSONIC save backup could not be written.")

func _save(scene: Object) -> void:
	var text := JSON.stringify(_snapshot(scene), "  ")
	_backup_current_primary()
	if not _write_text(_save_path(), text):
		push_warning("HYPERSONIC save could not be opened for writing.")

func _restore(scene: Object) -> void:
	var choice := SaveRecoveryRules.choose_primary_or_backup(_read_text(_save_path()), _read_text(_backup_path()), 1, SAVE_VERSION)
	if choice.get("data", {}).is_empty():
		choice = _legacy_save_choice()
	var parsed = choice.get("data", {})
	if typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty():
		return
	if str(choice.get("source", "")) == "backup":
		push_warning("HYPERSONIC recovered campaign state from backup save.")
	var airframe_director := get_node_or_null("/root/AirframeDirector")
	if airframe_director != null and airframe_director.has_method("restore_airframe_state"):
		airframe_director.call("restore_airframe_state", int(parsed.get("airframe_index", 0)))
	var mission_index := clampi(int(parsed.get("mission_index", scene.get("mission_index"))), 0, _mission_count(scene) - 1)
	var weapon_index := clampi(int(parsed.get("weapon_index", scene.get("weapon_index"))), 0, _primary_weapon_count(scene) - 1)
	var generator_index := clampi(int(parsed.get("generator_index", scene.get("generator_index"))), 0, _generator_count(scene) - 1)
	var credits := clampi(int(parsed.get("credits", scene.get("credits"))), 0, MAX_CREDITS)
	var max_hull := maxi(1, _scene_max(scene, "_max_hull", 100))
	var max_shield := maxi(0, _scene_max(scene, "_max_shield", 100))
	var service_hull := clampi(int(parsed.get("service_hull", scene.get("service_hull"))), 1, max_hull)
	var service_shield := clampi(int(parsed.get("service_shield", scene.get("service_shield"))), 0, max_shield)
	scene.set("credits", credits)
	scene.set("mission_index", mission_index)
	scene.set("weapon_index", weapon_index)
	scene.set("generator_index", generator_index)
	scene.set("service_hull", service_hull)
	scene.set("service_shield", service_shield)
	var support_director := get_node_or_null("/root/SupportDirector")
	if support_director != null and support_director.has_method("restore_support_state"):
		support_director.call("restore_support_state", int(parsed.get("support_selected", 0)), int(parsed.get("support_unlocked", 0)))
	if scene.has_method("_prepare_mission"):
		scene.call("_prepare_mission", mission_index)

func _identity() -> Node:
	return get_node_or_null("/root/ProductIdentity")

func _save_path() -> String:
	var identity := _identity()
	return str(identity.call("save_path")) if identity != null and identity.has_method("save_path") else "user://hypersonic_save.json"

func _backup_path() -> String:
	var identity := _identity()
	return str(identity.call("backup_save_path")) if identity != null and identity.has_method("backup_save_path") else "user://hypersonic_save.bak.json"

func _legacy_save_choice() -> Dictionary:
	var identity := _identity()
	if identity == null or not identity.has_method("legacy_save_paths"):
		return {}
	for path in identity.call("legacy_save_paths"):
		var parsed := SaveRecoveryRules.parse_supported_json(_read_text(str(path)), 1, SAVE_VERSION)
		if not parsed.is_empty():
			push_warning("HYPERSONIC migrated campaign state from legacy save namespace.")
			return {"source":"legacy", "data":parsed}
	return {}
