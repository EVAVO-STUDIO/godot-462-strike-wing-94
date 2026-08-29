extends Node

const SaveRecoveryRules = preload("res://scripts/save_recovery_rules.gd")
const SAVE_PATH := "user://strike_wing_94_save.json"
const BACKUP_PATH := "user://strike_wing_94_save.bak.json"
const SAVE_VERSION := 3
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

func _campaign_max(scene: Object, field: String, fallback: int) -> int:
	var data = scene.get("campaign")
	if typeof(data) != TYPE_DICTIONARY:
		return fallback
	var cfg = data.get("campaign", data)
	if typeof(cfg) != TYPE_DICTIONARY:
		return fallback
	return int(cfg.get(field, fallback))

func _snapshot(scene: Object) -> Dictionary:
	var max_hull := maxi(1, _campaign_max(scene, "starting_hull", 100))
	var max_shield := maxi(0, _campaign_max(scene, "starting_shield", 100))
	return {
		"version": SAVE_VERSION,
		"credits": clampi(int(scene.get("credits")), 0, MAX_CREDITS),
		"mission_index": clampi(int(scene.get("mission_index")), 0, _mission_count(scene) - 1),
		"weapon_index": clampi(int(scene.get("weapon_index")), 0, _primary_weapon_count(scene) - 1),
		"generator_index": clampi(int(scene.get("generator_index")), 0, _generator_count(scene) - 1),
		"service_hull": clampi(int(scene.get("service_hull")), 1, max_hull),
		"service_shield": clampi(int(scene.get("service_shield")), 0, max_shield)
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
	var current_text := _read_text(SAVE_PATH)
	if SaveRecoveryRules.parse_supported_json(current_text, 1, SAVE_VERSION).is_empty():
		return
	if not _write_text(BACKUP_PATH, current_text):
		push_warning("Strike Wing save backup could not be written.")

func _save(scene: Object) -> void:
	var text := JSON.stringify(_snapshot(scene), "  ")
	_backup_current_primary()
	if not _write_text(SAVE_PATH, text):
		push_warning("Strike Wing save could not be opened for writing.")

func _restore(scene: Object) -> void:
	var choice := SaveRecoveryRules.choose_primary_or_backup(_read_text(SAVE_PATH), _read_text(BACKUP_PATH), 1, SAVE_VERSION)
	var parsed = choice.get("data", {})
	if typeof(parsed) != TYPE_DICTIONARY or parsed.is_empty():
		return
	if str(choice.get("source", "")) == "backup":
		push_warning("Strike Wing recovered campaign state from backup save.")
	var mission_index := clampi(int(parsed.get("mission_index", scene.get("mission_index"))), 0, _mission_count(scene) - 1)
	var weapon_index := clampi(int(parsed.get("weapon_index", scene.get("weapon_index"))), 0, _primary_weapon_count(scene) - 1)
	var generator_index := clampi(int(parsed.get("generator_index", scene.get("generator_index"))), 0, _generator_count(scene) - 1)
	var credits := clampi(int(parsed.get("credits", scene.get("credits"))), 0, MAX_CREDITS)
	var max_hull := maxi(1, _campaign_max(scene, "starting_hull", 100))
	var max_shield := maxi(0, _campaign_max(scene, "starting_shield", 100))
	var service_hull := clampi(int(parsed.get("service_hull", scene.get("service_hull"))), 1, max_hull)
	var service_shield := clampi(int(parsed.get("service_shield", scene.get("service_shield"))), 0, max_shield)
	scene.set("credits", credits)
	scene.set("mission_index", mission_index)
	scene.set("weapon_index", weapon_index)
	scene.set("generator_index", generator_index)
	scene.set("service_hull", service_hull)
	scene.set("service_shield", service_shield)
	if scene.has_method("_prepare_mission"):
		scene.call("_prepare_mission", mission_index)
