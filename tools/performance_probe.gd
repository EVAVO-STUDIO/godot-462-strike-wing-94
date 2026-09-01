extends Node

const WARMUP_SECONDS := 2.0
const SAMPLE_SECONDS := 6.0
const STRESS_ENEMIES := 14
const STRESS_PLAYER_SHOTS := 16
const STRESS_HOSTILE_SHOTS := 64
const STRESS_PICKUPS := 4

var scene: Node
var elapsed := 0.0
var frame_times_ms: Array[float] = []
var draw_calls: Array[float] = []
var max_enemies := 0
var max_player_shots := 0
var max_hostile_shots := 0
var density := "stress"
var isolate := "none"
var target_enemies := STRESS_ENEMIES
var target_player_shots := STRESS_PLAYER_SHOTS
var target_hostile_shots := STRESS_HOSTILE_SHOTS
var target_pickups := STRESS_PICKUPS

func _ready() -> void:
	process_priority = -100
	density = _argument_value("--performance-density=", "stress")
	isolate = _argument_value("--performance-isolate=", "none")
	if density == "baseline":
		target_enemies = 0
		target_player_shots = 0
		target_hostile_shots = 0
		target_pickups = 0
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_prepare_profile")

func _prepare_profile() -> void:
	scene = get_parent()
	await get_tree().process_frame
	await get_tree().process_frame
	if scene == null or not scene.has_method("_prepare_mission"):
		_fail("production main scene was not available")
		return
	scene.set("mission_index", 27)
	scene.call("_prepare_mission", 27)
	scene.call("_start_mission")
	scene.set("mission_duration", 999.0)
	scene.set("current_objectives", [{"id":"stress_survive","type":"survive","seconds":999.0,"required":true}])
	scene.set("objective_progress", {"stress_survive":0})
	scene.set("hull", 999999)
	scene.set("shield", 999999)
	_apply_isolation()
	_seed_stress_state()

func _apply_isolation() -> void:
	if isolate == "environment":
		_disable_node(get_node_or_null("/root/EnvironmentDirector"))
	elif isolate == "projectiles":
		_disable_node(get_node_or_null("/root/ProjectileCueDirector"))
	elif isolate == "combat_art":
		_disable_node(get_node_or_null("/root/CombatArtDirector"))
	elif isolate == "combat_fx":
		_disable_node(get_node_or_null("/root/CombatFxDirector"))
	elif isolate == "hud":
		_disable_node(get_node_or_null("/root/PixelUiDirector"))
		_disable_node(get_node_or_null("/root/AfterburnerCueDirector"))
	elif isolate == "presentation":
		for child in get_tree().root.get_children():
			if child is CanvasLayer: _disable_node(child)
	elif isolate in ["core", "auxiliary"]:
		var core_layers := ["EnvironmentDirector", "CombatArtDirector", "ProjectileCueDirector", "CombatFxDirector", "PixelUiDirector"]
		for child in get_tree().root.get_children():
			if child is CanvasLayer:
				var is_core := str(child.name) in core_layers
				if (isolate == "core" and is_core) or (isolate == "auxiliary" and not is_core): _disable_node(child)

func _disable_node(node: Node) -> void:
	if node == null: return
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasLayer: node.visible = false

func _process(delta: float) -> void:
	if scene == null or not is_instance_valid(scene) or int(scene.get("phase")) != 1:
		return
	elapsed += delta
	_maintain_stress_state()
	if elapsed >= WARMUP_SECONDS:
		frame_times_ms.append(delta * 1000.0)
		draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		max_enemies = maxi(max_enemies, scene.get("enemies").size())
		max_player_shots = maxi(max_player_shots, scene.get("bullets").size())
		max_hostile_shots = maxi(max_hostile_shots, scene.get("enemy_bullets").size())
	if elapsed >= WARMUP_SECONDS + SAMPLE_SECONDS:
		_finish_profile()

func _seed_stress_state() -> void:
	for enemy_id in ["phase_interceptor", "orbital_sentry", "drone_hunter", "security_patrol_mech"]:
		var archetype: Dictionary = scene.call("_find_enemy_archetype", enemy_id)
		for _i in range(4): scene.call("_spawn_enemy", archetype)
	_maintain_stress_state()

func _maintain_stress_state() -> void:
	var enemies: Array = scene.get("enemies")
	if enemies.size() > target_enemies: enemies.resize(target_enemies)
	while enemies.size() < target_enemies:
		var archetype: Dictionary = scene.call("_find_enemy_archetype", "phase_interceptor")
		scene.call("_spawn_enemy", archetype)
		enemies = scene.get("enemies")
	var arranged_enemies: Array = enemies
	for index in range(arranged_enemies.size()):
		var enemy: Dictionary = arranged_enemies[index]
		enemy["position"] = Vector2(54 + (index % 7) * 88, 72 + int(index / 7) * 48)
		enemy["speed"] = 0.0
		enemy["hp"] = 99999
		enemy["max_hp"] = 99999
		enemy["fire_timer"] = maxf(0.04, float(enemy.get("fire_timer", 0.4)))
		arranged_enemies[index] = enemy
	scene.set("enemies", arranged_enemies)

	var player_shots: Array = scene.get("bullets")
	if player_shots.size() > target_player_shots: player_shots.resize(target_player_shots)
	while player_shots.size() < target_player_shots:
		var index := player_shots.size()
		player_shots.append({"position":Vector2(30 + (index % 16) * 36, 92 + int(index / 16) * 48),"velocity":Vector2(0,-8),"damage":1,"weapon_id":"profile","pierce_remaining":4})
	scene.set("bullets", player_shots)

	var hostile_shots: Array = scene.get("enemy_bullets")
	if hostile_shots.size() > target_hostile_shots: hostile_shots.resize(target_hostile_shots)
	while hostile_shots.size() < target_hostile_shots:
		var index := hostile_shots.size()
		hostile_shots.append({"position":Vector2(24 + (index % 24) * 25, 64 + int(index / 24) * 38),"velocity":Vector2(0,8),"damage":1})
	scene.set("enemy_bullets", hostile_shots)

	var pickups: Array = scene.get("pickups")
	if pickups.size() > target_pickups: pickups.resize(target_pickups)
	while pickups.size() < target_pickups:
		var index := pickups.size()
		pickups.append({"position":Vector2(70 + index * 110, 108 + (index % 2) * 90),"kind":"shield"})
	scene.set("pickups", pickups)

func _finish_profile() -> void:
	set_process(false)
	frame_times_ms.sort()
	draw_calls.sort()
	var average_frame_ms := _average(frame_times_ms)
	var report := {
		"profile":"HYPERSONIC_NATIVE_PRODUCTION_RUNTIME",
		"density":density,
		"isolate":isolate,
		"viewport":"1280x720",
		"target_fps":60,
		"warmup_seconds":WARMUP_SECONDS,
		"sample_seconds":SAMPLE_SECONDS,
		"sample_frames":frame_times_ms.size(),
		"average_fps":1000.0 / maxf(0.001, average_frame_ms),
		"average_frame_ms":average_frame_ms,
		"p95_frame_ms":_percentile(frame_times_ms, 0.95),
		"p99_frame_ms":_percentile(frame_times_ms, 0.99),
		"max_frame_ms":frame_times_ms.back() if not frame_times_ms.is_empty() else 0.0,
		"p95_draw_calls":_percentile(draw_calls, 0.95),
		"max_enemies":max_enemies,
		"max_player_projectiles":max_player_shots,
		"max_hostile_projectiles":max_hostile_shots,
		"production_layers":true
	}
	print("HYPERSONIC_PERFORMANCE %s" % JSON.stringify(report))
	var report_path := _argument_value("--performance-report=", "")
	if not report_path.is_empty():
		var file := FileAccess.open(ProjectSettings.globalize_path(report_path), FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report, "  "))
	var passed := float(report["average_fps"]) >= 60.0 and float(report["p95_frame_ms"]) <= 16.67
	get_tree().quit(0 if passed else 1)

func _argument_value(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return fallback

func _average(values: Array[float]) -> float:
	if values.is_empty(): return 0.0
	var total := 0.0
	for value in values: total += value
	return total / float(values.size())

func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty(): return 0.0
	return values[clampi(int(ceil(float(values.size()) * ratio)) - 1, 0, values.size() - 1)]

func _fail(reason: String) -> void:
	push_error("HYPERSONIC performance probe failed: %s." % reason)
	get_tree().quit(1)
