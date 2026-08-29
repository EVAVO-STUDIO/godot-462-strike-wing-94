extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")

var form := CraftFormRules.FIGHTER
var altitude := AltitudeRules.MID
var _cooldown := 0.0
var _world: Dictionary = {}
var _last_mission_index := -1
var _last_phase := -1
var _current_context: Dictionary = {}
var _next_altitude_transition := 0

func _ready() -> void:
	process_priority = -8
	var data = ContentCatalog.load_json("res://data/campaign_world.json")
	if typeof(data) == TYPE_DICTIONARY:
		_world = data
	ProgressionRules.set_current_tech_era("advanced_conventional")
	_ensure_action()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	_publish_generator_context(scene)
	var mission_index := int(scene.get("mission_index"))
	var phase := int(scene.get("phase"))
	if mission_index != _last_mission_index:
		_last_mission_index = mission_index
		_apply_mission_context(scene)
	if phase == 1 and _last_phase != 1:
		_apply_mission_context(scene)
	if phase == 1:
		_apply_due_altitude_transitions(scene)
		if Input.is_action_just_pressed("transform_craft"):
			_try_transform(scene)
	_last_phase = phase

func _publish_generator_context(scene: Object) -> void:
	if scene.has_method("_active_generator"):
		var generator = scene.call("_active_generator")
		if typeof(generator) == TYPE_DICTIONARY:
			EnergyRules.set_active_generator(generator)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "mission_index", "mission_catalog", "mission_time", "status_text", "status_timer"]:
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
	_current_context = _mission_context(scene).duplicate(true)
	altitude = AltitudeRules.sanitize(str(_current_context.get("altitude", AltitudeRules.MID)))
	var recommended := CraftFormRules.sanitize(str(_current_context.get("recommended_form", CraftFormRules.FIGHTER)))
	form = recommended if AltitudeRules.supports_form(altitude, recommended) else CraftFormRules.FIGHTER
	ProgressionRules.set_current_tech_era(str(_current_context.get("tech_era", "advanced_conventional")))
	_cooldown = 0.0
	_next_altitude_transition = 0

func _apply_due_altitude_transitions(scene: Object) -> void:
	var transitions = _current_context.get("altitude_transitions", [])
	if typeof(transitions) != TYPE_ARRAY:
		return
	while _next_altitude_transition < transitions.size():
		var transition = transitions[_next_altitude_transition]
		if typeof(transition) != TYPE_DICTIONARY:
			_next_altitude_transition += 1
			continue
		var at := maxf(0.0, float(transition.get("at_seconds", 0.0)))
		if float(scene.get("mission_time")) + 0.0001 < at:
			return
		var next_altitude := AltitudeRules.sanitize(str(transition.get("altitude", altitude)))
		altitude = next_altitude
		if not AltitudeRules.supports_form(altitude, form):
			form = CraftFormRules.FIGHTER
			_cooldown = CraftFormRules.TRANSFORM_COOLDOWN
			_apply_weapon_interlock(scene)
		var label := str(transition.get("label", AltitudeRules.display_name(altitude))).strip_edges().to_upper()
		_set_status(scene, "ALTITUDE SHIFT - %s  %s" % [label, CraftFormRules.display_name(form)])
		_next_altitude_transition += 1

func _try_transform(scene: Object) -> void:
	if _cooldown > 0.0:
		return
	var candidate := CraftFormRules.toggle(form)
	if not AltitudeRules.supports_form(altitude, candidate):
		_set_status(scene, "%s LOCKS %s CONFIG" % [AltitudeRules.display_name(altitude), CraftFormRules.display_name(form)])
		return
	form = candidate
	_cooldown = CraftFormRules.TRANSFORM_COOLDOWN
	_apply_weapon_interlock(scene)
	_set_status(scene, "VARIABLE GEOMETRY - %s" % CraftFormRules.display_name(form))

func _apply_weapon_interlock(scene: Object) -> void:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	if names.has("fire_timer"):
		scene.set("fire_timer", maxf(float(scene.get("fire_timer")), CraftFormRules.TRANSFORM_WEAPON_INTERLOCK))
	if names.has("secondary_timer"):
		scene.set("secondary_timer", maxf(float(scene.get("secondary_timer")), CraftFormRules.TRANSFORM_WEAPON_INTERLOCK))

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

func projectile_hit_radius_sq() -> float:
	return CraftFormRules.projectile_hit_radius_sq(form)

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
	return _current_context.duplicate(true)

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
