extends Node

const SAVE_PATH := "user://strike_wing_94_save.json"
const SAVE_VERSION := 1
const SAVE_INTERVAL := 1.0

var _restored := false
var _timer := 0.0
var _last_signature := ""

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports_campaign_state(scene):
		return
	if not _restored:
		_restore(scene)
		_restored = true
		_last_signature = _signature(scene)
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

func _snapshot(scene: Object) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"credits": maxi(0, int(scene.get("credits"))),
		"mission_index": maxi(0, int(scene.get("mission_index"))),
		"weapon_index": maxi(0, int(scene.get("weapon_index")))
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
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", -1)) != SAVE_VERSION:
		push_warning("Strike Wing save ignored because it is invalid or from an unsupported version.")
		return
	scene.set("credits", maxi(0, int(parsed.get("credits", scene.get("credits")))))
	scene.set("mission_index", maxi(0, int(parsed.get("mission_index", scene.get("mission_index")))))
	scene.set("weapon_index", maxi(0, int(parsed.get("weapon_index", scene.get("weapon_index")))))
	if scene.has_method("_prepare_mission"):
		var count := 1
		var catalog = scene.get("mission_catalog")
		if typeof(catalog) == TYPE_ARRAY:
			count = maxi(1, catalog.size())
		scene.call("_prepare_mission", int(scene.get("mission_index")) % count)
