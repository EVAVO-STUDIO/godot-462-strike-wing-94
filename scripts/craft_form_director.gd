extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const HypersonicRules = preload("res://scripts/hypersonic_rules.gd")

const AFTERBURNER_CAPACITY := 8.0
const FIGHTER_AFTERBURNER_MULTIPLIER := 1.35
const BOMBER_AFTERBURNER_MULTIPLIER := 1.22

var form := CraftFormRules.FIGHTER
var altitude := AltitudeRules.MID
var afterburner_fuel := AFTERBURNER_CAPACITY
var _afterburner_active := false
var _hypersonic_active := false
var _hypersonic_charge := 0.0
var _hypersonic_damage_carry := 0.0
var _cooldown := 0.0
var _world: Dictionary = {}
var _base_spawn_profiles: Array = []
var _last_mission_index := -1
var _last_phase := -1
var _current_context: Dictionary = {}
var _next_altitude_transition := 0
var _altitude_transition_timer := 0.0
var _altitude_transition_from := AltitudeRules.MID
var _altitude_transition_to := AltitudeRules.MID
var _altitude_transition_direction := 0

func _ready() -> void:
	# Altitude/form context must publish before EncounterDirector (-20) and SupportDirector (-5).
	process_priority = -30
	var world_data = ContentCatalog.load_json("res://data/campaign_world.json")
	if typeof(world_data) == TYPE_DICTIONARY:
		_world = world_data
	var spawn_data = ContentCatalog.load_json("res://data/spawn_profiles.json")
	if typeof(spawn_data) == TYPE_DICTIONARY:
		_base_spawn_profiles = spawn_data.get("profiles", []).duplicate(true)
	ProgressionRules.set_current_tech_era("advanced_conventional")
	_ensure_actions()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_altitude_transition_timer = maxf(0.0, _altitude_transition_timer - delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		_afterburner_active = false
		_hypersonic_active = false
		_hypersonic_charge = 0.0
		return
	_publish_generator_context(scene)
	var mission_index := int(scene.get("mission_index"))
	var phase := int(scene.get("phase"))
	if mission_index != _last_mission_index:
		_last_mission_index = mission_index
		_apply_mission_context(scene)
	if phase == 1 and _last_phase != 1:
		_apply_mission_context(scene)
		afterburner_fuel = AFTERBURNER_CAPACITY
	if phase == 1:
		_update_afterburner(delta)
		_apply_due_altitude_transitions(scene)
		_handle_manual_altitude_input(scene)
		if Input.is_action_just_pressed("transform_craft"):
			_try_transform(scene)
	else:
		_afterburner_active = false
	_publish_altitude_spawn_profiles(scene)
	_last_phase = phase

func _update_afterburner(delta: float) -> void:
	_afterburner_active = Input.is_action_pressed("afterburner") and afterburner_fuel > 0.001
	var may_charge := HypersonicRules.can_charge(form, altitude_transition_active(), afterburner_fuel)
	if _afterburner_active and may_charge:
		_hypersonic_charge = minf(HypersonicRules.charge_seconds(altitude), _hypersonic_charge + maxf(0.0, delta))
		_hypersonic_active = _hypersonic_charge >= HypersonicRules.charge_seconds(altitude)
	else:
		_hypersonic_charge = maxf(0.0, _hypersonic_charge - maxf(0.0, delta) * 2.5)
		_hypersonic_active = false
	if _afterburner_active:
		var burn := _afterburner_burn_rate()
		if _hypersonic_active:
			burn *= HypersonicRules.fuel_burn_multiplier(altitude)
		afterburner_fuel = maxf(0.0, afterburner_fuel - maxf(0.0, delta) * burn)
		_apply_hypersonic_airframe_risk(delta)
		if afterburner_fuel <= 0.001:
			_afterburner_active = false
			_hypersonic_active = false

func _apply_hypersonic_airframe_risk(delta: float) -> void:
	if not _hypersonic_active:
		_hypersonic_damage_carry = 0.0
		return
	var damage_rate := HypersonicRules.structural_damage_per_second(altitude)
	if damage_rate <= 0.0:
		return
	_hypersonic_damage_carry += damage_rate * maxf(0.0, delta)
	var whole_damage := floori(_hypersonic_damage_carry)
	if whole_damage <= 0:
		return
	_hypersonic_damage_carry -= float(whole_damage)
	var scene := get_tree().current_scene
	if scene != null and _has_property(scene, "hull"):
		scene.set("hull", maxi(1, int(scene.get("hull")) - whole_damage))
		if _has_property(scene, "status_text"):
			scene.set("status_text", "OVERSPEED - AIRFRAME LOAD")
			scene.set("status_timer", 0.35)

func _afterburner_burn_rate() -> float:
	if form == CraftFormRules.BOMBER and altitude == AltitudeRules.LOW:
		return 1.35
	if form == CraftFormRules.FIGHTER and altitude == AltitudeRules.ORBITAL:
		return 0.82
	if form == CraftFormRules.FIGHTER and altitude == AltitudeRules.HIGH:
		return 0.90
	return 1.0

func refuel_afterburner_full() -> void:
	afterburner_fuel = AFTERBURNER_CAPACITY

func afterburner_ratio() -> float:
	return clampf(afterburner_fuel / AFTERBURNER_CAPACITY, 0.0, 1.0)

func afterburner_active() -> bool:
	return _afterburner_active

func hypersonic_active() -> bool:
	return _hypersonic_active

func hypersonic_charge_ratio() -> float:
	return clampf(_hypersonic_charge / HypersonicRules.charge_seconds(altitude), 0.0, 1.0)

func _publish_generator_context(scene: Object) -> void:
	if scene.has_method("_active_generator"):
		var generator = scene.call("_active_generator")
		if typeof(generator) == TYPE_DICTIONARY:
			EnergyRules.set_active_generator(generator)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "mission_index", "mission_catalog", "mission_time", "status_text", "status_timer", "spawn_profiles", "enemy_catalog"]:
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
	_altitude_transition_timer = 0.0
	_altitude_transition_from = altitude
	_altitude_transition_to = altitude
	_altitude_transition_direction = 0

func _publish_altitude_spawn_profiles(scene: Object) -> void:
	if _base_spawn_profiles.is_empty():
		return
	var catalog: Array = scene.get("enemy_catalog")
	var filtered: Array = []
	for source_profile in _base_spawn_profiles:
		if typeof(source_profile) != TYPE_DICTIONARY:
			continue
		var profile: Dictionary = source_profile.duplicate(true)
		var enemy_ids: Array = []
		for enemy_id in source_profile.get("enemy_ids", []):
			var archetype := _enemy_for_id(catalog, str(enemy_id))
			if not archetype.is_empty() and AltitudeRules.allows_enemy_archetype(altitude, archetype):
				enemy_ids.append(enemy_id)
		profile["enemy_ids"] = enemy_ids
		filtered.append(profile)
	scene.set("spawn_profiles", filtered)

func _enemy_for_id(catalog: Array, enemy_id: String) -> Dictionary:
	for enemy in catalog:
		if typeof(enemy) == TYPE_DICTIONARY and str(enemy.get("id", "")) == enemy_id:
			return enemy
	return {}

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
		_begin_altitude_transition(
			scene,
			next_altitude,
			str(transition.get("label", AltitudeRules.display_name(next_altitude))).strip_edges().to_upper()
		)
		_next_altitude_transition += 1

func _handle_manual_altitude_input(scene: Object) -> void:
	if _altitude_transition_timer > 0.0:
		return
	var direction := 0
	if Input.is_action_just_pressed("altitude_up"):
		direction = 1
	elif Input.is_action_just_pressed("altitude_down"):
		direction = -1
	if direction == 0:
		return
	_try_manual_altitude(scene, direction)

func _try_manual_altitude(scene: Object, direction: int) -> void:
	var window := _active_altitude_window(float(scene.get("mission_time")))
	if window.is_empty():
		_set_status(scene, "ALTITUDE LANE LOCKED")
		return
	var allowed := AltitudeRules.allowed_manual_bands(window)
	var candidate := AltitudeRules.adjacent_band(altitude, direction)
	if candidate == altitude or candidate not in allowed:
		_set_status(scene, "NO %s ALTITUDE LANE" % ("HIGHER" if direction > 0 else "LOWER"))
		return
	_begin_altitude_transition(scene, candidate, "PILOT SELECTED %s" % AltitudeRules.display_name(candidate))

func _active_altitude_window(mission_time: float) -> Dictionary:
	var windows = _current_context.get("altitude_choice_windows", [])
	if typeof(windows) != TYPE_ARRAY:
		return {}
	for window in windows:
		if typeof(window) != TYPE_DICTIONARY:
			continue
		var start := maxf(0.0, float(window.get("start_seconds", 0.0)))
		var end := maxf(start, float(window.get("end_seconds", start)))
		if mission_time >= start and mission_time <= end:
			return window
	return {}

func altitude_choice_available(mission_time: float) -> bool:
	return not _active_altitude_window(mission_time).is_empty()

func altitude_choice_bands(mission_time: float) -> Array[String]:
	return AltitudeRules.allowed_manual_bands(_active_altitude_window(mission_time))

func _begin_altitude_transition(scene: Object, next_altitude: String, label: String) -> void:
	var safe_next := AltitudeRules.sanitize(next_altitude)
	if safe_next == altitude:
		return
	_altitude_transition_from = altitude
	_altitude_transition_to = safe_next
	_altitude_transition_direction = AltitudeRules.transition_direction(altitude, safe_next)
	_altitude_transition_timer = AltitudeRules.TRANSITION_SECONDS
	altitude = safe_next
	if not AltitudeRules.supports_form(altitude, form):
		form = CraftFormRules.FIGHTER
		_cooldown = CraftFormRules.TRANSFORM_COOLDOWN
		_apply_weapon_interlock(scene)
	_set_status(scene, "ALTITUDE SHIFT - %s  %s" % [label, CraftFormRules.display_name(form)])

func altitude_transition_active() -> bool:
	return _altitude_transition_timer > 0.0

func altitude_transition_ratio() -> float:
	if _altitude_transition_timer <= 0.0:
		return 1.0
	return clampf(1.0 - _altitude_transition_timer / AltitudeRules.TRANSITION_SECONDS, 0.0, 1.0)

func altitude_transition_direction() -> int:
	return _altitude_transition_direction if altitude_transition_active() else 0

func altitude_transition_from() -> String:
	return _altitude_transition_from

func altitude_transition_to() -> String:
	return _altitude_transition_to

func _try_transform(scene: Object) -> void:
	if _altitude_transition_timer > 0.0:
		_set_status(scene, "GEOMETRY LOCK - ALTITUDE TRANSITION")
		return
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
	var base := CraftFormRules.movement_multiplier(form)
	if not _afterburner_active:
		return base
	var boost := FIGHTER_AFTERBURNER_MULTIPLIER if form == CraftFormRules.FIGHTER else BOMBER_AFTERBURNER_MULTIPLIER
	# Forward velocity belongs to world scroll; local arcade steering tightens at Mach transition.
	return base * boost * (HypersonicRules.TURN_SCALE if _hypersonic_active else 1.0)

func world_speed_multiplier() -> float:
	return HypersonicRules.SPEED_MULTIPLIER if _hypersonic_active else 1.0

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

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func primary_mount_offsets(weapon: Dictionary, projectile_count: int) -> Array[Vector2]:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	if mounts != null and mounts.has_method("primary_offsets"):
		var value = mounts.call("primary_offsets", form, weapon, projectile_count)
		if typeof(value) == TYPE_ARRAY and value.size() == maxi(1, projectile_count):
			var result: Array[Vector2] = []
			for offset in value:
				if typeof(offset) == TYPE_VECTOR2:
					result.append(offset)
			if result.size() == maxi(1, projectile_count):
				return result
	var fallback: Array[Vector2] = []
	for _i in range(maxi(1, projectile_count)):
		fallback.append(Vector2(0.0, -18.0))
	return fallback

func bomber_rotary_deployed(weapon: Dictionary) -> bool:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	if mounts != null and mounts.has_method("bomber_rotary_deployed"):
		return bool(mounts.call("bomber_rotary_deployed", form, weapon))
	if form != CraftFormRules.BOMBER:
		return false
	return str(weapon.get("archetype", "")) in ["balanced", "spread", "rapid", "burst", "heavy"]

func target_damage_multiplier(enemy_class: String) -> float:
	var form_multiplier := CraftFormRules.ground_attack_multiplier(form) if enemy_class in ["ground", "sea"] else CraftFormRules.air_attack_multiplier(form)
	var altitude_multiplier := AltitudeRules.ground_target_multiplier(altitude) if enemy_class in ["ground", "sea"] else AltitudeRules.air_target_multiplier(altitude)
	return form_multiplier * altitude_multiplier

func mission_context() -> Dictionary:
	return _current_context.duplicate(true)

func _set_status(scene: Object, text: String) -> void:
	scene.set("status_text", text)
	scene.set("status_timer", 1.6)

func _ensure_actions() -> void:
	_add_key_action("transform_craft", KEY_Q)
	_add_key_action("afterburner", KEY_SHIFT)
	_add_key_action("altitude_up", KEY_PAGEUP)
	_add_key_action("altitude_down", KEY_PAGEDOWN)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
