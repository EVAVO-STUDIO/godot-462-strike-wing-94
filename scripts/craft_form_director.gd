extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")

var form := CraftFormRules.FIGHTER
var altitude := AltitudeRules.MID
var _cooldown := 0.0
var _world: Dictionary = {}
var _last_mission_index := -1

func _ready() -> void:
	process_priority = -8
	var data = ContentCatalog.load_json("res://data/campaign_world.json")
	if typeof(data) == TYPE_DICTIONARY:
		_world = data
	_ensure_action()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var mission_index := int(scene.get("mission_index"))
	if mission_index != _last_mission_index:
		_last_mission_index = mission_index
		_apply_mission_context(scene)
	if int(scene.get("phase")) != 1:
		return
	if Input.is_action_just_pressed("transform_craft"):
		_try_transform(scene)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "mission_index", "mission_catalog", "status_text", "status_timer"]:
		if not names.has(required):
			return false
	return true

func _active_mission_id(scene: Object) -> String:
	var missions = scene.get("mission_catalog")
	if typeof(missions) != TYPE_ARRAY or missions.is_empty():
		return ""
	var index := clampi(int(scene.get("mission_index")), 0, missions.size() - 1)
	var mission = missions[index]
	return str(mission.get("id", "")) if typeof(mission) == TYPE_DICTIONARY else ""

func _mission_context(scene: Object) -> Dictionary:
	var contexts = _world.get("mission_context", {})
	if typeof(contexts) != TYPE_DICTIONARY:
		return {}
	var value = contexts.get(_active_mission_id(scene), {})
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _apply_mission_context(scene: Object) -> void:
	var context := _mission_context(scene)
	altitude = AltitudeRules.sanitize(str(context.get("altitude", AltitudeRules.MID)))
	var recommended := CraftFormRules.sanitize(str(context.get("recommended_form", CraftFormRules.FIGHTER)))
	form = recommended if AltitudeRules.supports_form(altitude, recommended) else CraftFormRules.FIGHTER
	_cooldown = 0.0

func _try_transform(scene: Object) -> void:
	if _cooldown > 0.0:
		return
	var candidate := CraftFormRules.toggle(form)
	if not AltitudeRules.supports_form(altitude, candidate):
		_set_status(scene, "%s LOCKS %s CONFIG" % [AltitudeRules.display_name(altitude), CraftFormRules.display_name(form)])
		return
	form = candidate
	_cooldown = CraftFormRules.TRANSFORM_COOLDOWN
	_set_status(scene, "VARIABLE GEOMETRY - %s" % CraftFormRules.display_name(form))

func current_form() -> String:
	return form

func current_form_name() -> String:
	return CraftFormRules.display_name(form)

func current_altitude() -> String:
	return altitude

func current_altitude_name() -> String:
	return AltitudeRules.display_name(altitude)

func movement_multiplier() -> float:
	return CraftFormRules.movement_multiplier(form)

func collision_radius_sq() -> float:
	return CraftFormRules.collision_radius_sq(form)

func primary_spread_multiplier() -> float:
	return CraftFormRules.primary_spread_multiplier(form)

func primary_damage_multiplier() -> float:
	return CraftFormRules.primary_damage_multiplier(form)

func support_energy_multiplier() -> float:
	return CraftFormRules.support_energy_multiplier(form)

func target_damage_multiplier(enemy_class: String) -> float:
	var form_multiplier := CraftFormRules.ground_attack_multiplier(form) if enemy_class in ["ground", "sea"] else CraftFormRules.air_attack_multiplier(form)
	var altitude_multiplier := AltitudeRules.ground_target_multiplier(altitude) if enemy_class in ["ground", "sea"] else AltitudeRules.air_target_multiplier(altitude)
	return form_multiplier * altitude_multiplier

func mission_context() -> Dictionary:
	var contexts = _world.get("mission_context", {})
	if typeof(contexts) != TYPE_DICTIONARY:
		return {}
	return contexts.get(_context_id_for_index(_last_mission_index), {})

func _context_id_for_index(index: int) -> String:
	var order := ["m01_coastal_intercept", "m02_refinery_run", "m03_black_sea", "m04_breakwater", "m05_furnace_line", "m06_black_flag"]
	return order[clampi(index, 0, order.size() - 1)] if not order.is_empty() else ""

func _set_status(scene: Object, text: String) -> void:
	scene.set("status_text", text)
	scene.set("status_timer", 1.6)

func _ensure_action() -> void:
	if not InputMap.has_action("transform_craft"):
		InputMap.add_action("transform_craft")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_Q
	if not InputMap.action_has_event("transform_craft", event):
		InputMap.action_add_event("transform_craft", event)
