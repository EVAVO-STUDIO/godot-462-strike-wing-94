extends SceneTree
const Camera = preload("res://scripts/flight_camera_rules.gd")
const Speed = preload("res://scripts/flight_speed_rules.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		push_error("Camera fixture requires --capture-gameplay to isolate saves"); quit(1); return
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	await process_frame
	scene.set_process(false)
	root.get_node("StartupSequenceDirector").call("_complete")
	var craft: Node = root.get_node("CraftFormDirector")
	craft.set_process(false)
	craft.set("_throttle_ratio", Speed.DEFAULT_THROTTLE_RATIO)
	Input.action_press("move_up"); craft.call("_update_throttle", 2.0); Input.action_release("move_up")
	check(is_equal_approx(float(craft.get("_throttle_ratio")), 1.0), "Forward input commands military power")
	Input.action_press("move_down"); craft.call("_update_throttle", 2.0); Input.action_release("move_down")
	check(is_zero_approx(float(craft.get("_throttle_ratio"))), "Backward input commands minimum power")
	craft.set("_throttle_ratio", 0.0)
	Input.action_press("move_up"); Input.action_press("throttle_up")
	craft.call("_update_throttle", 0.1)
	Input.action_release("move_up"); Input.action_release("throttle_up")
	check(is_equal_approx(float(craft.get("_throttle_ratio")), 0.055), "Duplicate power bindings cannot double acceleration")
	var coarse := 0.0
	var fine := 0.0
	for i in 30: coarse = Camera.advance_offset(coarse, 1.78, 1.0 / 30.0)
	for i in 120: fine = Camera.advance_offset(fine, 1.78, 1.0 / 120.0)
	check(absf(coarse - fine) < 0.0001, "Camera response must be frame-rate independent")
	var travelled := 0.0
	var settling := Camera.target_offset(4.4)
	var previous_camera := Camera.camera_distance(travelled, settling)
	for i in 240:
		travelled += 0.62 / 60.0
		settling = Camera.advance_offset(settling, 0.62, 1.0 / 60.0)
		var projected := Camera.camera_distance(travelled, settling)
		check(projected > previous_camera, "Deceleration must never reverse terrain travel")
		previous_camera = projected
	check(Speed.world_closure_multiplier(0.62, "air") < 1.0, "Slowing must reduce airborne closure")
	scene.set("enemies", [{"position": Vector2(100, 100)}])
	scene.set("bullets", [{"position": Vector2(200, 200)}])
	scene.set("enemy_bullets", []); scene.set("pickups", [])
	craft.set("_world_speed_multiplier_value", 1.78)
	scene.call("_update_player", 0.5)
	var offset := float(scene.get("flight_camera_offset"))
	check(is_equal_approx(Vector2(scene.get("enemies")[0].position).y, 100.0 + offset), "Contact receives camera correction exactly once")
	check(is_equal_approx(Vector2(scene.get("bullets")[0].position).y, 200.0 + offset), "Projectile shares contact projection")
	var before := Vector2(scene.get("player_position")).y
	scene.set("environment_world_distance", 100000.0)
	check(float(scene.call("camera_route_distance")) > 100000.0, "Camera follows unbounded route travel")
	check(is_equal_approx(Vector2(scene.get("player_position")).y, before), "Travel distance does not push aircraft into a screen wall")
	scene.set("enemies", []); scene.set("bullets", [])
	scene.queue_free(); await process_frame
	if failures.is_empty(): print("HYPERSONIC flight camera self-test passed.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
