extends SceneTree
const Camera = preload("res://scripts/flight_camera_rules.gd")
const Speed = preload("res://scripts/flight_speed_rules.gd")
const Airspace = preload("res://scripts/lateral_airspace_rules.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		push_error("Camera fixture requires --capture-gameplay to isolate saves"); quit(1); return
	var craft: Node = load("res://scripts/craft_form_director.gd").new()
	root.add_child(craft)
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
	check(absf(coarse - fine) < 0.005, "Camera response must remain perceptually frame-rate independent while enforcing forward travel")
	var slow_y := Camera.ANCHOR_Y + Camera.target_offset(0.62)
	var cruise_y := Camera.ANCHOR_Y + Camera.target_offset(1.0)
	var military_y := Camera.ANCHOR_Y + Camera.target_offset(1.36)
	var hypersonic_y := Camera.ANCHOR_Y + Camera.target_offset(4.4)
	check(slow_y > cruise_y and cruise_y > military_y and military_y > hypersonic_y, "Acceleration must move the aircraft visibly forward through the camera")
	check(slow_y <= 292.0 and hypersonic_y >= 102.0 and slow_y - hypersonic_y >= 175.0, "Camera follow envelope must use most of the playable depth without entering the HUD")
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
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("player_position.y = FlightCameraRules.ANCHOR_Y + flight_camera_offset"), "Live player position must follow speed-derived camera offset")
	var lateral := Speed.advance_lateral_velocity(0.0,1.0,220.0,0.10)
	check(lateral>0.0 and lateral<220.0, "VX-94 should build lateral velocity rather than snap to full speed")
	var neutral := Speed.advance_lateral_velocity(lateral,0.0,220.0,0.10)
	check(absf(neutral)<absf(lateral), "neutral controls should damp lateral velocity")
	var reversal := Speed.advance_lateral_velocity(lateral,-1.0,220.0,0.10)
	check(reversal<lateral and reversal>-220.0, "direction reversal should pass through bounded acceleration")
	check(main_source.contains("player_lateral_velocity = FlightSpeedRules.advance_lateral_velocity") and main_source.contains("func player_bank_input"), "live steering and bank art should share physical lateral velocity")
	check(main_source.contains('"--capture-steering=left"') and main_source.contains('"--capture-steering=right"'), "visual QA should expose velocity-driven bank without synthesizing input")
	var craft_source := FileAccess.get_file_as_string("res://scripts/craft_form_director.gd")
	check(craft_source.contains('active_scene.has_method("player_bank_input")') and craft_source.contains('active_scene.call("player_bank_input")'), "craft presentation should consume the live scene velocity ratio")
	var art_source := FileAccess.get_file_as_string("res://scripts/combat_art_director.gd")
	check(art_source.contains('active_scene.has_method("player_bank_input")') and art_source.contains('active_scene.call("player_bank_input")'), "visible bank poses should follow physical lateral velocity and coast back through neutral")
	check(art_source.contains("func _altitude_craft_scale") and art_source.contains("depth_pulse*0.11") and art_source.contains("depth_pulse*0.10"), "climb and dive art should carry readable opposing depth scale pulses")
	check(main_source.contains("_shift_camera_projection(Vector2(0.0, flight_camera_offset - previous_offset))"), "Contacts and projectiles must receive only the camera delta")
	check(main_source.contains("FlightCameraRules.camera_distance(environment_world_distance, flight_camera_offset)"), "Route travel must remain unbounded behind the screen projection")
	check(Airspace.side_for_x(42.0)=="left" and Airspace.side_for_x(598.0)=="right" and Airspace.side_for_x(52.0).is_empty() and Airspace.side_for_x(588.0).is_empty(), "lateral airspace should reserve only the final 18 pixels per side as recovery shoulders")
	var warning_time := Airspace.advance(0.0,42.0,3.0,-1.0)
	check(Airspace.seconds_remaining(warning_time)==1 and Airspace.warning_ratio(warning_time)>0.7, "off-course flight should provide a readable four-second abort countdown")
	check(Airspace.advance(warning_time,42.0,1.0,1.0)<warning_time and Airspace.advance(warning_time,320.0,1.0)<warning_time, "releasing outward steering or returning toward the mission route should actively clear the off-course timer")
	check(main_source.contains('"MISSION AIRSPACE VIOLATION"') and main_source.contains("lateral_airspace_timer"), "live flight should warn and abort sustained departure instead of presenting an unexplained edge clamp")
	var hud_source := FileAccess.get_file_as_string("res://scripts/pixel_ui_director.gd")
	check(hud_source.contains("for y in range(82,320,42)") and not hud_source.contains('"AIRSPACE LIMIT // TURN'), "airspace departure should use sparse directional edge cues and one shared status lane instead of duplicate warning banners")
	craft.queue_free(); await process_frame
	if failures.is_empty(): print("HYPERSONIC flight camera self-test passed.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
