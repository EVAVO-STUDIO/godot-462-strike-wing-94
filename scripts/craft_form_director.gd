extends Node
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const HypersonicRules = preload("res://scripts/hypersonic_rules.gd")
const FlightSpeedRules = preload("res://scripts/flight_speed_rules.gd")

const AFTERBURNER_CAPACITY := 8.0
const FIGHTER_AFTERBURNER_MULTIPLIER := 1.35
const BOMBER_AFTERBURNER_MULTIPLIER := 1.22

var form := CraftFormRules.FIGHTER
var altitude := AltitudeRules.MID
var afterburner_fuel := AFTERBURNER_CAPACITY
var _afterburner_active := false
var _hypersonic_active := false
var _hypersonic_charge := 0.0
var _hypersonic_speed_ratio := 0.0
var _hypersonic_damage_carry := 0.0
var _dynamic_pressure_damage_carry := 0.0
var _throttle_ratio := FlightSpeedRules.DEFAULT_THROTTLE_RATIO
var _world_speed_multiplier_value := FlightSpeedRules.CRUISE_POWER_MULTIPLIER
var _cooldown := 0.0
var _transform_timer := 0.0
var _transform_ready_serial := 0
var _transform_from_form := CraftFormRules.FIGHTER
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
var _mount_bank_visual := 0.0

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
	_mount_bank_visual = move_toward(_mount_bank_visual, Input.get_axis("move_left", "move_right"), maxf(0.0, delta) * 5.5)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		_afterburner_active = false
		_hypersonic_active = false
		_hypersonic_charge = 0.0
		_hypersonic_speed_ratio = 0.0
		return
	_update_transform_settle(scene, delta)
	_publish_generator_context(scene)
	var mission_index := int(scene.get("mission_index"))
	var phase := int(scene.get("phase"))
	if mission_index != _last_mission_index:
		_last_mission_index = mission_index
		_apply_mission_context(scene)
	if phase == 1 and _last_phase != 1:
		_apply_mission_context(scene)
		afterburner_fuel = AFTERBURNER_CAPACITY
		_throttle_ratio = FlightSpeedRules.DEFAULT_THROTTLE_RATIO
		_world_speed_multiplier_value = FlightSpeedRules.CRUISE_POWER_MULTIPLIER
	if phase == 1:
		_update_throttle(delta)
		var was_hypersonic := _hypersonic_active
		_update_afterburner(delta)
		if was_hypersonic and not _hypersonic_active:
			_set_status(scene, "MACH RECOVERY // CONTROL AUTHORITY RETURNING")
		_apply_due_altitude_transitions(scene)
		_handle_manual_altitude_input(scene)
		if Input.is_action_just_pressed("transform_craft"):
			_try_transform(scene)
	else:
		_afterburner_active = false
		_hypersonic_active = false
	_update_hypersonic_speed_ratio(delta)
	_update_world_speed(delta)
	_publish_altitude_spawn_profiles(scene)
	_last_phase = phase

func _update_afterburner(delta: float) -> void:
	_afterburner_active = Input.is_action_pressed("afterburner") and afterburner_fuel > 0.001
	var may_charge := HypersonicRules.can_charge(form, altitude_transition_active() or transform_active(), afterburner_fuel)
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

func _update_throttle(delta: float) -> void:
	var command := clampf(Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down") + Input.get_action_strength("move_up") - Input.get_action_strength("move_down"), -1.0, 1.0)
	_throttle_ratio = clampf(_throttle_ratio + command * FlightSpeedRules.THROTTLE_CHANGE_PER_SECOND * maxf(0.0, delta), 0.0, 1.0)

func _update_world_speed(delta: float) -> void:
	var target := FlightSpeedRules.target_world_multiplier(throttle_ratio(), _afterburner_active, hypersonic_speed_ratio())
	_world_speed_multiplier_value = move_toward(_world_speed_multiplier_value, target, FlightSpeedRules.POWER_RESPONSE_PER_SECOND * maxf(0.0, delta))
	_apply_dynamic_pressure_risk(delta)

func _apply_dynamic_pressure_risk(delta: float) -> void:
	var damage_rate := FlightSpeedRules.dynamic_pressure_damage_per_second(altitude, _world_speed_multiplier_value)
	if damage_rate <= 0.0:
		_dynamic_pressure_damage_carry = 0.0
		return
	_dynamic_pressure_damage_carry += damage_rate * maxf(0.0, delta)
	var whole_damage := floori(_dynamic_pressure_damage_carry)
	if whole_damage <= 0:
		return
	_dynamic_pressure_damage_carry -= float(whole_damage)
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("_apply_structural_damage"):
		return
	scene.call("_apply_structural_damage", whole_damage)
	if _has_property(scene, "status_text") and int(scene.get("hull")) > 0:
		scene.set("status_text", "LOW ALT OVERSPEED // THROTTLE BACK OR CLIMB")
		scene.set("status_timer", 0.42)

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
	if scene == null or not scene.has_method("_apply_structural_damage"):
		return
	scene.call("_apply_structural_damage", whole_damage)
	if _has_property(scene, "status_text") and int(scene.get("hull")) > 0:
		scene.set("status_text", "OVERSPEED - AIRFRAME LOAD")
		scene.set("status_timer", 0.35)

func _update_hypersonic_speed_ratio(delta: float) -> void:
	var target := 1.0 if _hypersonic_active else 0.0
	var seconds := HypersonicRules.ENTRY_ACCEL_SECONDS if _hypersonic_active else HypersonicRules.EXIT_DECEL_SECONDS
	_hypersonic_speed_ratio = move_toward(_hypersonic_speed_ratio, target, maxf(0.0, delta) / seconds)

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
	if _capture_hypersonic():
		return 0.82
	return clampf(afterburner_fuel / AFTERBURNER_CAPACITY, 0.0, 1.0)

func afterburner_active() -> bool:
	if _capture_hypersonic():
		return true
	return _afterburner_active

func hypersonic_active() -> bool:
	if _capture_hypersonic():
		return true
	return _hypersonic_active

func hypersonic_charge_ratio() -> float:
	if _capture_hypersonic():
		return 1.0
	return clampf(_hypersonic_charge / HypersonicRules.charge_seconds(altitude), 0.0, 1.0)

func hypersonic_visual_ratio() -> float:
	return hypersonic_charge_ratio()

func hypersonic_speed_ratio() -> float:
	if _capture_hypersonic():
		return 1.0
	return clampf(_hypersonic_speed_ratio, 0.0, 1.0)

func throttle_ratio() -> float:
	var captured := _capture_throttle_ratio()
	return captured if captured >= 0.0 else clampf(_throttle_ratio, 0.0, 1.0)

func throttle_percent() -> int:
	return clampi(int(roundf(throttle_ratio() * 100.0)), 0, 100)

func _capture_throttle_ratio() -> float:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		return -1.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-throttle="):
			return clampf(float(argument.trim_prefix("--capture-throttle=")) / 100.0, 0.0, 1.0)
	return -1.0

func _capture_hypersonic() -> bool:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		return false
	return "--capture-flight=hypersonic" in OS.get_cmdline_user_args()

func _capture_altitude_override() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-altitude="):
			var requested := argument.trim_prefix("--capture-altitude=").to_lower()
			return requested if requested in AltitudeRules.BANDS else ""
	return ""

func _publish_generator_context(scene: Object) -> void:
	if scene.has_method("_active_generator"):
		var generator = scene.call("_active_generator")
		if typeof(generator) == TYPE_DICTIONARY:
			EnergyRules.set_active_generator(generator)

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "mission_index", "mission_catalog", "mission_time", "status_text", "status_timer", "spawn_profiles", "enemy_catalog"])

func _active_mission_id(scene: Object) -> String:
	if scene.has_method("_active_mission"):
		var active = scene.call("_active_mission")
		if typeof(active) == TYPE_DICTIONARY and not active.is_empty():
			return str(active.get("id", ""))
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
	var capture_altitude := _capture_altitude_override()
	if not capture_altitude.is_empty():
		altitude = capture_altitude
	var recommended := CraftFormRules.sanitize(str(_current_context.get("recommended_form", CraftFormRules.FIGHTER)))
	form = recommended if AltitudeRules.supports_form(altitude, recommended) else CraftFormRules.FIGHTER
	_transform_from_form = form
	ProgressionRules.set_current_tech_era(str(_current_context.get("tech_era", "advanced_conventional")))
	_cooldown = 0.0
	_transform_timer = 0.0
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
		if _route_progress(scene) + 0.0001 < at:
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
	var window := _active_altitude_window(_route_progress(scene))
	if window.is_empty() and not _hypersonic_active:
		_set_status(scene, "ALTITUDE CHANGE UNAVAILABLE")
		return
	# Both sources are runtime Variants loaded from canonical content/rules.
	# Keep the local container untyped so a valid Array returned by either path
	# cannot trigger a typed-array assignment error during live altitude input.
	var allowed: Array = AltitudeRules.BANDS.duplicate() if _hypersonic_active else AltitudeRules.allowed_manual_bands(window)
	var candidate := AltitudeRules.adjacent_band(altitude, direction)
	if candidate == altitude:
		_set_status(scene, "%s LIMIT" % ("CLIMB" if direction > 0 else "DESCENT"))
		return
	if candidate not in allowed:
		_set_status(scene, "%s UNAVAILABLE" % ("CLIMB" if direction > 0 else "DESCENT"))
		return
	_begin_altitude_transition(
		scene,
		candidate,
		"%s: %s ALTITUDE" % ["CLIMBING" if direction > 0 else "DESCENDING", AltitudeRules.display_name(candidate)]
	)

func _active_altitude_window(route_progress: float) -> Dictionary:
	var windows = _current_context.get("altitude_choice_windows", [])
	if typeof(windows) != TYPE_ARRAY:
		return {}
	for window in windows:
		if typeof(window) != TYPE_DICTIONARY:
			continue
		var start := maxf(0.0, float(window.get("start_seconds", 0.0)))
		var end := maxf(start, float(window.get("end_seconds", start)))
		if route_progress >= start and route_progress <= end:
			return window
	return {}

func altitude_choice_available(route_progress: float) -> bool:
	return not _active_altitude_window(route_progress).is_empty()

func altitude_choice_bands(route_progress: float) -> Array[String]:
	return AltitudeRules.allowed_manual_bands(_active_altitude_window(route_progress))

func _route_progress(scene: Object) -> float:
	if scene.has_method("route_progress_seconds"):
		return maxf(0.0, float(scene.call("route_progress_seconds")))
	return maxf(0.0, float(scene.get("mission_time")))

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
		_transform_from_form = form
		form = CraftFormRules.FIGHTER
		_cooldown = CraftFormRules.TRANSFORM_COOLDOWN
		_transform_timer = CraftFormRules.TRANSFORM_VISUAL_SECONDS
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
	_transform_from_form = form
	form = candidate
	_cooldown = CraftFormRules.TRANSFORM_COOLDOWN
	_transform_timer = CraftFormRules.TRANSFORM_VISUAL_SECONDS
	_apply_weapon_interlock(scene)
	_set_status(scene, "VARIABLE GEOMETRY - %s" % CraftFormRules.display_name(form))

func _update_transform_settle(scene: Object, delta: float) -> void:
	if _transform_timer <= 0.0:
		return
	_transform_timer = maxf(0.0, _transform_timer - maxf(0.0, delta))
	if _transform_timer <= 0.0:
		_transform_ready_serial += 1
		_set_status(scene, "%s CONFIGURATION READY" % CraftFormRules.display_name(form))

func transform_active() -> bool:
	return _transform_timer > 0.0

func transform_ratio() -> float:
	return clampf(1.0 - _transform_timer / CraftFormRules.TRANSFORM_VISUAL_SECONDS, 0.0, 1.0) if transform_active() else 1.0

func transform_ready_serial() -> int:
	return _transform_ready_serial

func form_blend_ratio() -> float:
	var destination := 1.0 if form == CraftFormRules.BOMBER else 0.0
	if not transform_active():
		return destination
	var source := 1.0 if _transform_from_form == CraftFormRules.BOMBER else 0.0
	return lerpf(source, destination, transform_ratio())

func _blended_form_value(fighter_value: float, bomber_value: float) -> float:
	return lerpf(fighter_value, bomber_value, form_blend_ratio())

func _apply_weapon_interlock(scene: Object) -> void:
	if SceneContractCache.has_property(scene, "fire_timer"):
		scene.set("fire_timer", maxf(float(scene.get("fire_timer")), CraftFormRules.TRANSFORM_WEAPON_INTERLOCK))
	if SceneContractCache.has_property(scene, "secondary_timer"):
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
	var base := _blended_form_value(
		CraftFormRules.movement_multiplier(CraftFormRules.FIGHTER),
		CraftFormRules.movement_multiplier(CraftFormRules.BOMBER)
	)
	var speed_ratio := hypersonic_speed_ratio()
	if not _afterburner_active and speed_ratio <= 0.0:
		return base
	var full_boost := _blended_form_value(FIGHTER_AFTERBURNER_MULTIPLIER, BOMBER_AFTERBURNER_MULTIPLIER)
	var boost := full_boost if _afterburner_active else lerpf(1.0, full_boost, speed_ratio)
	# Forward velocity belongs to world scroll; local arcade steering tightens at Mach transition.
	return base * boost * lerpf(1.0, HypersonicRules.TURN_SCALE, speed_ratio)

func world_speed_multiplier() -> float:
	if _capture_hypersonic():
		return FlightSpeedRules.HYPERSONIC_POWER_MULTIPLIER
	var captured := _capture_throttle_ratio()
	if captured >= 0.0:
		return FlightSpeedRules.target_world_multiplier(captured, afterburner_active(), hypersonic_speed_ratio())
	return maxf(FlightSpeedRules.MINIMUM_POWER_MULTIPLIER, _world_speed_multiplier_value)

func collision_radius_sq() -> float:
	return _blended_form_value(
		CraftFormRules.collision_radius_sq(CraftFormRules.FIGHTER),
		CraftFormRules.collision_radius_sq(CraftFormRules.BOMBER)
	)

func projectile_hit_radius_sq() -> float:
	return _blended_form_value(
		CraftFormRules.projectile_hit_radius_sq(CraftFormRules.FIGHTER),
		CraftFormRules.projectile_hit_radius_sq(CraftFormRules.BOMBER)
	)

func primary_spread_multiplier() -> float:
	return _blended_form_value(
		CraftFormRules.primary_spread_multiplier(CraftFormRules.FIGHTER),
		CraftFormRules.primary_spread_multiplier(CraftFormRules.BOMBER)
	)

func primary_damage_multiplier() -> float:
	return _blended_form_value(
		CraftFormRules.primary_damage_multiplier(CraftFormRules.FIGHTER),
		CraftFormRules.primary_damage_multiplier(CraftFormRules.BOMBER)
	)

func support_energy_multiplier() -> float:
	return _blended_form_value(
		CraftFormRules.support_energy_multiplier(CraftFormRules.FIGHTER),
		CraftFormRules.support_energy_multiplier(CraftFormRules.BOMBER)
	)

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)

func primary_mount_offsets(weapon: Dictionary, projectile_count: int) -> Array[Vector2]:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	if mounts != null and mounts.has_method("primary_offsets"):
		var value = mounts.call("primary_offsets", form, weapon, projectile_count)
		if typeof(value) == TYPE_ARRAY and value.size() == maxi(1, projectile_count):
			var result: Array[Vector2] = []
			for offset in value:
				if typeof(offset) == TYPE_VECTOR2:
					result.append(_project_mount_offset(offset))
			if result.size() == maxi(1, projectile_count):
				return result
	var fallback: Array[Vector2] = []
	for _i in range(maxi(1, projectile_count)):
		fallback.append(_project_mount_offset(Vector2(0.0, -18.0)))
	return fallback

func support_mount_offsets(support: Dictionary, projectile_count: int, alternating_side: bool = false) -> Array[Vector2]:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	if mounts != null and mounts.has_method("support_offsets"):
		var value = mounts.call("support_offsets", form, support, projectile_count, alternating_side)
		if typeof(value) == TYPE_ARRAY and not value.is_empty():
			var result: Array[Vector2] = []
			for offset in value:
				if typeof(offset) == TYPE_VECTOR2:
					result.append(_project_mount_offset(offset))
			if not result.is_empty():
				return result
	var fallback: Array[Vector2] = []
	for _i in range(maxi(1, projectile_count)):
		fallback.append(_project_mount_offset(Vector2(0.0, -10.0)))
	return fallback

func role_mount_offsets(role: String) -> Array[Vector2]:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	var result: Array[Vector2] = []
	if mounts != null and mounts.has_method("role_offsets"):
		var value = mounts.call("role_offsets", form, role)
		if typeof(value) == TYPE_ARRAY:
			for offset in value:
				if typeof(offset) == TYPE_VECTOR2:
					result.append(_project_mount_offset(offset))
	return result

func _project_mount_offset(offset: Vector2) -> Vector2:
	var bank_angle := deg_to_rad(_mount_bank_visual * 18.0)
	return offset.rotated(bank_angle).round() + presentation_pitch_offset()

func presentation_pitch_offset() -> Vector2:
	if not altitude_transition_active():
		return Vector2.ZERO
	return Vector2(0, -roundf(sin(altitude_transition_ratio() * PI) * 4.0 * float(altitude_transition_direction())))

func mount_bank_visual() -> float:
	return _mount_bank_visual

func bomber_rotary_deployed(weapon: Dictionary) -> bool:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	if mounts != null and mounts.has_method("bomber_rotary_deployed"):
		return bool(mounts.call("bomber_rotary_deployed", form, weapon))
	if form != CraftFormRules.BOMBER:
		return false
	return str(weapon.get("archetype", "")) in ["balanced", "spread", "rapid", "burst", "heavy"]

func target_damage_multiplier(enemy_class: String) -> float:
	var form_multiplier := _blended_form_value(
		CraftFormRules.ground_attack_multiplier(CraftFormRules.FIGHTER),
		CraftFormRules.ground_attack_multiplier(CraftFormRules.BOMBER)
	) if enemy_class in ["ground", "sea"] else _blended_form_value(
		CraftFormRules.air_attack_multiplier(CraftFormRules.FIGHTER),
		CraftFormRules.air_attack_multiplier(CraftFormRules.BOMBER)
	)
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
	_add_key_action("throttle_up", KEY_T)
	_add_key_action("throttle_down", KEY_G)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
