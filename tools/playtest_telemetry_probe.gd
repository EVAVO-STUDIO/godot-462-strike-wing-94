extends Node

const DEFAULT_SIMULATION_SECONDS := 36.0
const TIME_SCALE := 3.0
const PULSE_ACTIONS := ["transform_craft", "altitude_up", "altitude_down", "evasive_roll", "deploy_countermeasure", "fire_support", "call_battlefield_support", "drop_strike_ordnance", "fire_secondary"]
const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]

var scene: Node
var elapsed := 0.0
var duration := DEFAULT_SIMULATION_SECONDS
var last_second := -1
var altitude_seconds: Dictionary = {}
var form_seconds: Dictionary = {}
var commands: Dictionary = {"transform":0, "altitude":0, "roll":0, "countermeasure":0, "tactical_support":0, "battlefield_support":0, "ordnance":0, "screen_bomb":0}
var accepted: Dictionary = {"tactical_support":0, "battlefield_support":0, "ordnance":0}
var maxima: Dictionary = {"enemies":0, "protected_contacts":0, "player_projectiles":0, "hostile_projectiles":0}
var starting: Dictionary = {}
var _support_active := false
var _battlefield_active := false
var _last_ordnance := -1
var _starting_countermeasures := -1
var _starting_world_distance := 0.0
var _minimum_world_speed := 99.0
var _maximum_world_speed := 0.0
var _minimum_throttle := 1.0
var _maximum_throttle := 0.0
var _minimum_camera_offset := 999.0
var _maximum_camera_offset := -999.0
var _passive_profile := false
var _stationary_fire_profile := false
var _boss_seen := false
var _boss_spawn_elapsed := -1.0
var _boss_destroyed_elapsed := -1.0
var _boss_spawn_integrity := -1

func _ready() -> void:
	process_priority = -100
	duration = clampf(_argument_float("--playtest-seconds=", DEFAULT_SIMULATION_SECONDS), 12.0, 120.0)
	_passive_profile = "--playtest-passive" in OS.get_cmdline_user_args()
	_stationary_fire_profile = "--playtest-stationary-fire" in OS.get_cmdline_user_args()
	Engine.time_scale = TIME_SCALE
	call_deferred("_prepare")

func _prepare() -> void:
	scene = get_parent()
	await get_tree().process_frame
	await get_tree().process_frame
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1:
		_fail("gameplay phase was not available")
		return
	starting = _snapshot_counters()
	_starting_world_distance = float(scene.get("environment_world_distance")) if _has_property(scene, "environment_world_distance") else 0.0
	var strike := get_node_or_null("/root/StrikeOrdnanceDirector")
	_last_ordnance = int(strike.get("ordnance")) if strike != null else -1
	var countermeasures := get_node_or_null("/root/CountermeasureDirector")
	_starting_countermeasures = int(countermeasures.call("charges_remaining")) if countermeasures != null and countermeasures.has_method("charges_remaining") else -1
	if not _passive_profile:
		Input.action_press("fire_primary")

func _process(delta: float) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if int(scene.get("phase")) != 1:
		if elapsed > 0.0:
			_finish()
		return
	elapsed += delta
	_sample_state(delta)
	var whole_second := int(floor(elapsed))
	if whole_second != last_second:
		last_second = whole_second
		_release_pulses()
		if not _passive_profile and not _stationary_fire_profile:
			_drive_movement(whole_second)
			_drive_commands(whole_second)
	if elapsed >= duration:
		_finish()

func _sample_state(delta: float) -> void:
	var craft := get_node_or_null("/root/CraftFormDirector")
	var altitude := str(craft.call("current_altitude")) if craft != null and craft.has_method("current_altitude") else "unknown"
	var form := str(craft.call("current_form")) if craft != null and craft.has_method("current_form") else "unknown"
	if craft != null and craft.has_method("world_speed_multiplier"):
		var world_speed := float(craft.call("world_speed_multiplier"))
		_minimum_world_speed = minf(_minimum_world_speed, world_speed)
		_maximum_world_speed = maxf(_maximum_world_speed, world_speed)
	if craft != null and craft.has_method("throttle_ratio"):
		var throttle := float(craft.call("throttle_ratio"))
		_minimum_throttle = minf(_minimum_throttle, throttle)
		_maximum_throttle = maxf(_maximum_throttle, throttle)
	if _has_property(scene, "flight_camera_offset"):
		var camera_offset := float(scene.get("flight_camera_offset"))
		_minimum_camera_offset = minf(_minimum_camera_offset, camera_offset)
		_maximum_camera_offset = maxf(_maximum_camera_offset, camera_offset)
	altitude_seconds[altitude] = float(altitude_seconds.get(altitude, 0.0)) + delta
	form_seconds[form] = float(form_seconds.get(form, 0.0)) + delta
	maxima["enemies"] = maxi(int(maxima["enemies"]), _array_size("enemies"))
	maxima["protected_contacts"] = maxi(int(maxima["protected_contacts"]), _array_size("protected_contacts"))
	maxima["player_projectiles"] = maxi(int(maxima["player_projectiles"]), _array_size("bullets"))
	maxima["hostile_projectiles"] = maxi(int(maxima["hostile_projectiles"]), _array_size("enemy_bullets"))
	_sample_boss_state()
	_sample_accepted_systems()

func _sample_boss_state() -> void:
	var alive := false
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY and bool(enemy.get("boss", false)) and int(enemy.get("hp", 0)) > 0:
			alive = true
			break
	if alive and not _boss_seen:
		_boss_seen = true
		_boss_spawn_elapsed = elapsed
		_boss_spawn_integrity = int(scene.get("hull")) + int(scene.get("shield"))
	elif _boss_seen and not alive and _boss_destroyed_elapsed < 0.0:
		_boss_destroyed_elapsed = elapsed

func _sample_accepted_systems() -> void:
	var support := get_node_or_null("/root/SupportDirector")
	var support_active := support != null and float(support.get("_cooldown")) > 0.0
	if support_active and not _support_active: accepted["tactical_support"] = int(accepted["tactical_support"]) + 1
	_support_active = support_active
	var battlefield := get_node_or_null("/root/BattlefieldSupportDirector")
	var battlefield_active := battlefield != null and float(battlefield.get("_visual_timer")) > 0.0
	if battlefield_active and not _battlefield_active: accepted["battlefield_support"] = int(accepted["battlefield_support"]) + 1
	_battlefield_active = battlefield_active
	var strike := get_node_or_null("/root/StrikeOrdnanceDirector")
	if strike != null:
		var current := int(strike.get("ordnance"))
		if _last_ordnance >= 0 and current < _last_ordnance: accepted["ordnance"] = int(accepted["ordnance"]) + (_last_ordnance - current)
		_last_ordnance = current

func _drive_movement(second: int) -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
	var avoidance := _contact_avoidance_direction()
	if avoidance != 0:
		Input.action_press("move_left" if avoidance < 0 else "move_right")
	else:
		match posmod(int(second / 3), 4):
			0: Input.action_press("move_left")
			1: Input.action_press("move_up")
			2: Input.action_press("move_right")
			3: Input.action_press("move_down")
	if second >= 5 and second < 9:
		Input.action_press("afterburner")
	else:
		Input.action_release("afterburner")
	if second < 4:
		Input.action_press("throttle_up")
		Input.action_release("throttle_down")
	elif second >= 10 and second < 14:
		Input.action_release("throttle_up")
		Input.action_press("throttle_down")
	else:
		Input.action_release("throttle_up")
		Input.action_release("throttle_down")

func _contact_avoidance_direction() -> int:
	var player: Vector2 = scene.get("player_position")
	var nearest_distance := 140.0
	var direction := 0
	for enemy in scene.get("enemies"):
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var offset: Vector2 = Vector2(enemy.get("position", Vector2.ZERO)) - player
		var distance := offset.length()
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		direction = -1 if offset.x >= 0.0 else 1
	return direction

func _drive_commands(second: int) -> void:
	if second in [4, 15, 26]: _pulse("transform_craft", "transform")
	if second in [8, 30]: _pulse("altitude_up", "altitude")
	if second in [19]: _pulse("altitude_down", "altitude")
	if second in [6, 17, 28]: _pulse("evasive_roll", "roll")
	if second in [9, 20, 32]: _pulse("deploy_countermeasure", "countermeasure")
	if second in [10, 24]: _pulse("fire_support", "tactical_support")
	if second in [13, 31]: _pulse("call_battlefield_support", "battlefield_support")
	if second in [12, 25]: _pulse("drop_strike_ordnance", "ordnance")
	if second in [16]: _pulse("fire_secondary", "screen_bomb")

func _pulse(action: String, metric: String) -> void:
	Input.action_press(action)
	commands[metric] = int(commands.get(metric, 0)) + 1

func _release_pulses() -> void:
	for action in PULSE_ACTIONS:
		Input.action_release(action)

func _snapshot_counters() -> Dictionary:
	return {
		"shots_fired":int(scene.get("shots_fired")),
		"shots_hit":int(scene.get("shots_hit")),
		"targets_destroyed":int(scene.get("targets_destroyed")),
		"collateral_strikes":int(scene.get("collateral_strikes")) if _has_property(scene, "collateral_strikes") else 0,
		"damage_taken":int(scene.get("damage_taken")),
		"score":int(scene.get("score")),
	}

func _finish() -> void:
	set_process(false)
	_release_all_input()
	Engine.time_scale = 1.0
	var ending := _snapshot_counters()
	var mission: Dictionary = scene.call("_active_mission") if scene.has_method("_active_mission") else {}
	var countermeasures := get_node_or_null("/root/CountermeasureDirector")
	var countermeasures_remaining := int(countermeasures.call("charges_remaining")) if countermeasures != null and countermeasures.has_method("charges_remaining") else -1
	var report := {
		"profile":"HYPERSONIC_PASSIVE_EXPOSURE" if _passive_profile else ("HYPERSONIC_STATIONARY_FIRE" if _stationary_fire_profile else "HYPERSONIC_BOUNDED_AUTOPILOT"),
		"mission_id":str(mission.get("id", "unknown")),
		"mission_name":str(mission.get("name", "UNKNOWN")),
		"simulation_seconds":elapsed,
		"time_scale":TIME_SCALE,
		"shots_fired":int(ending["shots_fired"]) - int(starting["shots_fired"]),
		"shots_hit":int(ending["shots_hit"]) - int(starting["shots_hit"]),
		"targets_destroyed":int(ending["targets_destroyed"]) - int(starting["targets_destroyed"]),
		"collateral_strikes":int(ending["collateral_strikes"]) - int(starting["collateral_strikes"]),
		"damage_taken":int(ending["damage_taken"]) - int(starting["damage_taken"]),
		"damage_sources":scene.get("damage_sources").duplicate(true) if _has_property(scene, "damage_sources") else {},
		"enemy_missiles_launched":int(scene.get("enemy_missiles_launched")) if _has_property(scene, "enemy_missiles_launched") else 0,
		"countermeasures_decoyed":int(scene.get("countermeasures_decoyed")) if _has_property(scene, "countermeasures_decoyed") else 0,
		"countermeasure_charges_spent":maxi(0, _starting_countermeasures - countermeasures_remaining) if _starting_countermeasures >= 0 and countermeasures_remaining >= 0 else 0,
		"score_earned":int(ending["score"]) - int(starting["score"]),
		"altitude_seconds":altitude_seconds,
		"form_seconds":form_seconds,
		"commands":commands,
		"accepted_system_uses":accepted,
		"maxima":maxima,
		"forward_flight":{
			"world_distance":float(scene.get("environment_world_distance")) - _starting_world_distance if _has_property(scene, "environment_world_distance") else 0.0,
			"camera_route_distance":float(scene.call("camera_route_distance")) if scene.has_method("camera_route_distance") else 0.0,
			"camera_offset_pixels":float(scene.get("flight_camera_offset")) if _has_property(scene, "flight_camera_offset") else 0.0,
			"minimum_camera_offset_pixels":_minimum_camera_offset,
			"maximum_camera_offset_pixels":_maximum_camera_offset,
			"camera_travel_span_pixels":_maximum_camera_offset - _minimum_camera_offset,
			"minimum_world_multiplier":_minimum_world_speed,
			"maximum_world_multiplier":_maximum_world_speed,
			"minimum_throttle":_minimum_throttle,
			"maximum_throttle":_maximum_throttle,
		},
		"command_contact":{
			"spawn_elapsed":_boss_spawn_elapsed,
			"destroyed_elapsed":_boss_destroyed_elapsed,
			"integrity_at_spawn":_boss_spawn_integrity,
			"alive_at_end":_boss_seen and _boss_destroyed_elapsed < 0.0,
		},
		"phase_at_end":int(scene.get("phase")),
	}
	var report_path := _argument_value("--playtest-report=", "")
	if not report_path.is_empty():
		var absolute := ProjectSettings.globalize_path(report_path)
		DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
		var file := FileAccess.open(absolute, FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report, "  "))
	print("HYPERSONIC_PLAYTEST %s" % JSON.stringify(report))
	get_tree().quit(0)

func _release_all_input() -> void:
	Input.action_release("fire_primary")
	Input.action_release("afterburner")
	Input.action_release("throttle_up")
	Input.action_release("throttle_down")
	_release_pulses()
	for action in MOVE_ACTIONS:
		Input.action_release(action)

func _array_size(property_name: String) -> int:
	var value = scene.get(property_name)
	return value.size() if typeof(value) == TYPE_ARRAY else 0

func _argument_value(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return fallback

func _argument_float(prefix: String, fallback: float) -> float:
	var value := _argument_value(prefix, "")
	return value.to_float() if value.is_valid_float() else fallback

func _has_property(object: Object, property_name: String) -> bool:
	for entry in object.get_property_list():
		if str(entry.get("name", "")) == property_name: return true
	return false

func _fail(reason: String) -> void:
	_release_all_input()
	Engine.time_scale = 1.0
	push_error("HYPERSONIC bounded playtest failed: %s." % reason)
	get_tree().quit(1)
