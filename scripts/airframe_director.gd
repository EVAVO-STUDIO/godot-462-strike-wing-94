extends Node

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const AirframeRules = preload("res://scripts/airframe_rules.gd")
const MissionStateRules = preload("res://scripts/mission_state_rules.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

var airframe_catalog: Array = []
var airframe_index := 0

func _ready() -> void:
	process_priority = -7
	var data = ContentCatalog.load_json("res://data/airframes.json")
	if typeof(data) == TYPE_DICTIONARY:
		airframe_catalog = data.get("airframes", [])
	airframe_index = AirframeRules.sanitize_index(airframe_index, airframe_catalog.size())
	_publish_context()
	_ensure_action()

func _process(_delta: float) -> void:
	_publish_context()
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 0:
		return
	if Input.is_action_just_pressed("upgrade_airframe"):
		_buy_next_airframe(scene)

func current_airframe() -> Dictionary:
	return AirframeRules.active_frame(airframe_catalog, airframe_index)

func current_airframe_name() -> String:
	return AirframeRules.frame_name(current_airframe())

func airframe_state() -> Dictionary:
	return {"airframe_index": AirframeRules.sanitize_index(airframe_index, airframe_catalog.size())}

func restore_airframe_state(saved_index: int) -> void:
	airframe_index = AirframeRules.sanitize_index(saved_index, airframe_catalog.size())
	_publish_context()

func _buy_next_airframe(scene: Object) -> void:
	if airframe_catalog.is_empty():
		_set_status(scene, "AIRFRAME CATALOGUE UNAVAILABLE")
		return
	var next_index := clampi(airframe_index + 1, 0, airframe_catalog.size() - 1)
	if next_index == airframe_index:
		_set_status(scene, "MAXIMUM AIRFRAME")
		return
	var next_frame: Dictionary = airframe_catalog[next_index]
	var result := ProgressionRules.next_weapon_index(airframe_index, airframe_catalog, int(scene.get("credits")))
	if bool(result.get("changed", false)):
		airframe_index = int(result.get("index", airframe_index))
		scene.set("credits", int(result.get("credits", scene.get("credits"))))
		_publish_context()
		_set_status(scene, "AIRFRAME INSTALLED - %s" % current_airframe_name().to_upper())
		return
	var reason := str(result.get("reason", ""))
	if reason == "TECH_LOCK":
		_set_status(scene, "TECH LOCK - %s" % TechProgressionRules.era_name(str(result.get("required_tech_era", ""))))
	elif reason == "CREDITS":
		_set_status(scene, "AIRFRAME NEEDS %d CREDITS" % int(next_frame.get("cost", 0)))
	else:
		_set_status(scene, "AIRFRAME UPGRADE UNAVAILABLE")

func _publish_context() -> void:
	var frame := current_airframe()
	MissionStateRules.set_airframe_context(frame)
	CombatRules.set_incoming_damage_multiplier(AirframeRules.incoming_damage_multiplier(frame))

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "credits", "status_text", "status_timer"])

func _set_status(scene: Object, text: String) -> void:
	scene.set("status_text", text)
	scene.set("status_timer", 2.0)

func _ensure_action() -> void:
	if not InputMap.has_action("upgrade_airframe"):
		InputMap.add_action("upgrade_airframe")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_K
	if not InputMap.action_has_event("upgrade_airframe", event):
		InputMap.action_add_event("upgrade_airframe", event)
