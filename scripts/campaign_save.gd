extends Node

const SaveRecoveryRules = preload("res://scripts/save_recovery_rules.gd")
const SAVE_VERSION := 12
const SAVE_INTERVAL := 1.0
const MAX_CREDITS := 99999999
const LEGACY_V5_MISSION_IDS := [
	"m01_coastal_intercept", "m02_refinery_run", "m03_black_sea", "m04_breakwater",
	"m05_furnace_line", "m06_black_flag", "m07_ghost_sky", "m08_machine_furnace",
	"m09_black_horizon", "m10_blue_fire", "m11_cold_station", "m12_machine_ark"
]

var _restored_scene_id := 0
var _timer := 0.0
var _last_signature := ""

func _process(delta: float) -> void:
	if _capture_mode():
		return
	var scene := get_tree().current_scene
	if scene == null or not _supports_campaign_state(scene):
		return
	if not _campaign_mode(scene):
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
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _capture_mode():
		var scene := get_tree().current_scene
		if scene != null and _supports_campaign_state(scene) and _campaign_mode(scene):
			_save(scene)

func _capture_mode() -> bool:
	var arguments := OS.get_cmdline_user_args()
	return "--capture-gameplay" in arguments or "--campaign-journey" in arguments

func _supports_campaign_state(scene: Object) -> bool:
	var required := ["credits", "mission_index", "weapon_index", "generator_index", "service_hull", "service_shield"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _campaign_mode(scene: Object) -> bool:
	for property in scene.get_property_list():
		if str(property.get("name", "")) == "game_mode":
			return str(scene.get("game_mode")) == "campaign"
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
		"mission_id": _mission_id_at(scene, int(scene.get("mission_index"))),
		"campaign_completed": bool(scene.get("campaign_completed")) if _has_property(scene, "campaign_completed") else false,
		"campaign_completions": maxi(0, int(scene.get("campaign_completions"))) if _has_property(scene, "campaign_completions") else 0,
		"completed_difficulties": _string_array(scene.get("completed_difficulties")) if _has_property(scene, "completed_difficulties") else [],
		"discovered_secret_ids": _string_array(scene.get("discovered_secret_ids")) if _has_property(scene, "discovered_secret_ids") else [],
		"mode_records": _mode_records(scene.get("mode_records")) if _has_property(scene, "mode_records") else {},
		"branch_decisions": _string_dictionary(scene.get("branch_decisions")) if _has_property(scene, "branch_decisions") else {},
		"intelligence_unlocked_ids": _string_array(scene.get("intelligence_unlocked_ids")) if _has_property(scene, "intelligence_unlocked_ids") else [],
		"completed_secret_mission_ids": _string_array(scene.get("completed_secret_mission_ids")) if _has_property(scene, "completed_secret_mission_ids") else [],
		"career_statistics": _career_statistics(scene.get("career_statistics")) if _has_property(scene, "career_statistics") else {},
		"weapon_index": clampi(int(scene.get("weapon_index")), 0, _primary_weapon_count(scene) - 1),
		"generator_index": clampi(int(scene.get("generator_index")), 0, _generator_count(scene) - 1),
		"airframe_index": maxi(0, int(airframe.get("airframe_index", 0))),
		"service_hull": clampi(int(scene.get("service_hull")), 1, max_hull),
		"service_shield": clampi(int(scene.get("service_shield")), 0, max_shield),
		"support_selected": maxi(0, int(support.get("selected_index", 0))),
		"support_unlocked": maxi(0, int(support.get("unlocked_index", 0)))
	}

func _has_property(scene: Object, property_name: String) -> bool:
	for property in scene.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		var text := str(item).strip_edges().to_lower()
		if not text.is_empty() and not text in result:
			result.append(text)
	return result

func _mode_records(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for raw_id in value.keys():
		var mode_id := str(raw_id).strip_edges().to_lower()
		var raw_record = value[raw_id]
		if mode_id.is_empty() or typeof(raw_record) != TYPE_DICTIONARY:
			continue
		result[mode_id] = {
			"attempts": maxi(0, int(raw_record.get("attempts", 0))),
			"clears": maxi(0, int(raw_record.get("clears", 0))),
			"best_route": maxi(0, int(raw_record.get("best_route", 0))),
			"route_total": maxi(0, int(raw_record.get("route_total", 0))),
			"best_score": maxi(0, int(raw_record.get("best_score", 0))),
			"cleared": bool(raw_record.get("cleared", false))
		}
	return result

func _career_statistics(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for key in ["sorties_attempted", "sorties_cleared", "shots_fired", "shots_hit", "targets_destroyed", "damage_taken", "secrets_discovered", "credits_earned", "best_score", "best_accuracy_per_mille"]:
		result[key] = maxi(0, int(value.get(key, 0)))
	result["sorties_cleared"] = mini(int(result["sorties_cleared"]), int(result["sorties_attempted"]))
	result["shots_hit"] = mini(int(result["shots_hit"]), int(result["shots_fired"]))
	result["best_accuracy_per_mille"] = mini(int(result["best_accuracy_per_mille"]), 1000)
	return result

func _string_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	for raw_key in value.keys():
		var key := str(raw_key).strip_edges().to_lower()
		var item := str(value[raw_key]).strip_edges().to_lower()
		if not key.is_empty() and not item.is_empty():
			result[key] = item
	return result

func _mission_id_at(scene: Object, index: int) -> String:
	var catalog = scene.get("mission_catalog")
	if typeof(catalog) != TYPE_ARRAY or catalog.is_empty():
		return ""
	var mission = catalog[clampi(index, 0, catalog.size() - 1)]
	return str(mission.get("id", "")) if typeof(mission) == TYPE_DICTIONARY else ""

func _mission_index_for_id(scene: Object, mission_id: String) -> int:
	var catalog = scene.get("mission_catalog")
	if typeof(catalog) != TYPE_ARRAY:
		return -1
	for index in range(catalog.size()):
		var mission = catalog[index]
		if typeof(mission) == TYPE_DICTIONARY and str(mission.get("id", "")) == mission_id:
			return index
	return -1

func _restored_mission_index(scene: Object, parsed: Dictionary) -> int:
	var stable_id := str(parsed.get("mission_id", ""))
	var stable_index := _mission_index_for_id(scene, stable_id)
	if stable_index >= 0:
		return stable_index
	var saved_index := int(parsed.get("mission_index", scene.get("mission_index")))
	if int(parsed.get("version", SAVE_VERSION)) <= 5 and saved_index >= 0 and saved_index < LEGACY_V5_MISSION_IDS.size():
		var legacy_index := _mission_index_for_id(scene, LEGACY_V5_MISSION_IDS[saved_index])
		if legacy_index >= 0:
			return legacy_index
	return clampi(saved_index, 0, _mission_count(scene) - 1)

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
	var mission_index := _restored_mission_index(scene, parsed)
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
	if _has_property(scene, "campaign_completed"):
		scene.set("campaign_completed", bool(parsed.get("campaign_completed", false)))
	if _has_property(scene, "campaign_completions"):
		scene.set("campaign_completions", maxi(0, int(parsed.get("campaign_completions", 0))))
	if _has_property(scene, "completed_difficulties"):
		scene.set("completed_difficulties", _string_array(parsed.get("completed_difficulties", [])))
	if _has_property(scene, "discovered_secret_ids"):
		scene.set("discovered_secret_ids", _string_array(parsed.get("discovered_secret_ids", [])))
	if _has_property(scene, "mode_records"):
		scene.set("mode_records", _mode_records(parsed.get("mode_records", {})))
	if _has_property(scene, "branch_decisions"):
		scene.set("branch_decisions", _string_dictionary(parsed.get("branch_decisions", {})))
	if _has_property(scene, "intelligence_unlocked_ids"):
		scene.set("intelligence_unlocked_ids", _string_array(parsed.get("intelligence_unlocked_ids", [])))
	if _has_property(scene, "completed_secret_mission_ids"):
		scene.set("completed_secret_mission_ids", _string_array(parsed.get("completed_secret_mission_ids", [])))
	if _has_property(scene, "career_statistics"):
		scene.set("career_statistics", _career_statistics(parsed.get("career_statistics", {})))
	var support_director := get_node_or_null("/root/SupportDirector")
	if support_director != null and support_director.has_method("restore_support_state"):
		support_director.call("restore_support_state", int(parsed.get("support_selected", 0)), int(parsed.get("support_unlocked", 0)))
	if scene.has_method("_prepare_mission"):
		scene.call("_prepare_mission", mission_index)

func save_now(scene: Object) -> void:
	if scene == null or not _supports_campaign_state(scene) or not _campaign_mode(scene) or _capture_mode():
		return
	_save(scene)
	_last_signature = _signature(scene)

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
