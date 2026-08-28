extends Node

const ServiceRules = preload("res://scripts/service_rules.gd")

var _scene_id := 0
var _last_phase := -1
var _service_hull := 100
var _service_shield := 100
var _initialized := false
var _restored := false

func _ready() -> void:
	process_priority = 200
	_ensure_actions()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var scene_id := scene.get_instance_id()
	if scene_id != _scene_id:
		_scene_id = scene_id
		_last_phase = int(scene.get("phase"))
		_initialize_from_campaign(scene)
		return

	var phase := int(scene.get("phase"))
	if phase == 2 and _last_phase == 1:
		_capture_success_state(scene)
	if phase == 1 and _last_phase != 1:
		scene.set("hull", clampi(_service_hull, 1, _max_hull(scene)))
		scene.set("shield", clampi(_service_shield, 0, _max_shield(scene)))
	if phase == 0:
		if _last_phase != 0 or float(scene.get("status_timer")) <= 0.0:
			scene.set("status_text", _service_status(scene))
			scene.set("status_timer", 999.0)
		_handle_service_input(scene)
	_last_phase = phase

func _supports(scene: Object) -> bool:
	var required := ["phase", "campaign", "credits", "hull", "shield", "result_text", "status_text", "status_timer"]
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for name in required:
		if not names.has(name):
			return false
	return true

func _campaign_config(scene: Object) -> Dictionary:
	var data = scene.get("campaign")
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var nested = data.get("campaign", data)
	return nested if typeof(nested) == TYPE_DICTIONARY else {}

func _max_hull(scene: Object) -> int:
	return maxi(1, int(_campaign_config(scene).get("starting_hull", 100)))

func _max_shield(scene: Object) -> int:
	return maxi(0, int(_campaign_config(scene).get("starting_shield", 100)))

func _initialize_from_campaign(scene: Object) -> void:
	if _initialized:
		return
	if not _restored:
		_service_hull = _max_hull(scene)
		_service_shield = _max_shield(scene)
	_initialized = true

func _capture_success_state(scene: Object) -> void:
	if not str(scene.get("result_text")).begins_with("MISSION COMPLETE"):
		return
	_service_hull = clampi(int(scene.get("hull")), 1, _max_hull(scene))
	_service_shield = clampi(int(scene.get("shield")), 0, _max_shield(scene))
	scene.set("status_text", _service_status(scene))
	scene.set("status_timer", 5.0)

func _handle_service_input(scene: Object) -> void:
	if Input.is_action_just_pressed("service_hull"):
		_service_hull_full(scene)
	elif Input.is_action_just_pressed("service_shield"):
		_service_shield_full(scene)

func _service_hull_full(scene: Object) -> void:
	var cfg := _campaign_config(scene)
	var result := ServiceRules.service_full(int(scene.get("credits")), _service_hull, _max_hull(scene), int(cfg.get("repair_cost_per_hull", 0)))
	if bool(result.get("changed", false)):
		_service_hull = int(result["value"])
		scene.set("credits", int(result["credits"]))
		scene.set("status_text", "HULL SERVICED -%d  %s" % [int(result["cost"]), _service_status(scene)])
	else:
		scene.set("status_text", _service_failure("HULL", result))
	scene.set("status_timer", 3.0)

func _service_shield_full(scene: Object) -> void:
	var cfg := _campaign_config(scene)
	var result := ServiceRules.service_full(int(scene.get("credits")), _service_shield, maxi(1, _max_shield(scene)), int(cfg.get("shield_recharge_cost_per_point", 0)))
	if bool(result.get("changed", false)):
		_service_shield = mini(_max_shield(scene), int(result["value"]))
		scene.set("credits", int(result["credits"]))
		scene.set("status_text", "SHIELD RECHARGED -%d  %s" % [int(result["cost"]), _service_status(scene)])
	else:
		scene.set("status_text", _service_failure("SHIELD", result))
	scene.set("status_timer", 3.0)

func _service_failure(label: String, result: Dictionary) -> String:
	var reason := str(result.get("reason", "NO_CHANGE"))
	if reason == "FULL":
		return "%s ALREADY FULL" % label
	if reason == "INSUFFICIENT_CREDITS":
		return "%s SERVICE NEEDS %d CREDITS" % [label, int(result.get("cost", 0))]
	return "%s SERVICE UNAVAILABLE" % label

func _service_status(scene: Object) -> String:
	var cfg := _campaign_config(scene)
	var hull_cost := ServiceRules.service_cost(_service_hull, _max_hull(scene), int(cfg.get("repair_cost_per_hull", 0)))
	var shield_cost := ServiceRules.service_cost(_service_shield, maxi(1, _max_shield(scene)), int(cfg.get("shield_recharge_cost_per_point", 0)))
	var hull_quote := "FULL" if hull_cost <= 0 else str(hull_cost)
	var shield_quote := "FULL" if shield_cost <= 0 else str(shield_cost)
	return "AIRFRAME H%03d S%03d  H REPAIR %s  J SHIELD %s" % [_service_hull, _service_shield, hull_quote, shield_quote]

func service_hull() -> int:
	return _service_hull

func service_shield() -> int:
	return _service_shield

func restore_service_state(hull_value: int, shield_value: int) -> void:
	_service_hull = maxi(1, hull_value)
	_service_shield = maxi(0, shield_value)
	_restored = true
	_initialized = true

func _ensure_actions() -> void:
	_add_key_action("service_hull", KEY_H)
	_add_key_action("service_shield", KEY_J)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
