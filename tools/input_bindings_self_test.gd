extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var bindings: Node = load("res://scripts/input_bindings.gd").new()
	bindings.call("_configure_controller")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	var project_source := project.get_as_text() if project != null else ""
	_expect(project != null and project_source.contains('InputBindings="*res://scripts/input_bindings.gd"'), "InputBindings should be a project autoload")
	_expect(project != null and project_source.contains('ControllerSortieBayDirector="*res://scripts/controller_sortie_bay_director.gd"'), "contextual controller sortie-bay router should be a project autoload")
	_expect(project != null and project_source.contains('ControllerMenuContextDirector="*res://scripts/controller_menu_context_director.gd"'), "controller options/controls context owner should be a project autoload")
	_expect(project != null and project_source.contains('FirstSortieGuidanceDirector="*res://scripts/first_sortie_guidance_director.gd"'), "Mission 1 contextual guidance should be a project autoload")
	for action in ["move_left","move_right","move_up","move_down","fire_primary","fire_secondary","fire_support","transform_craft","afterburner","evasive_roll","deploy_countermeasure","fire_missile","call_battlefield_support","altitude_up","altitude_down","drop_strike_ordnance","throttle_up","throttle_down","confirm","cancel"]:
		_expect(InputMap.has_action(action), "missing input action: %s" % action)
	_expect(_has_axis("move_left", JOY_AXIS_LEFT_X, -1.0), "left-stick negative X should move left")
	_expect(_has_axis("move_right", JOY_AXIS_LEFT_X, 1.0), "left-stick positive X should move right")
	_expect(_has_axis("move_up", JOY_AXIS_LEFT_Y, -1.0), "left-stick negative Y should move up")
	_expect(_has_axis("move_down", JOY_AXIS_LEFT_Y, 1.0), "left-stick positive Y should move down")
	_expect(absf(InputMap.action_get_deadzone("move_left") - 0.18) < 0.001, "analogue movement should use the authored deadzone")
	_expect(_has_button("fire_primary", JOY_BUTTON_A), "south face button should fire primary")
	_expect(_has_button("fire_secondary", JOY_BUTTON_B), "east face button should trigger screen bomb")
	_expect(_has_button("fire_support", JOY_BUTTON_X), "west face button should fire tactical support")
	_expect(_has_button("transform_craft", JOY_BUTTON_Y), "north face button should transform the VX-94")
	_expect(_has_button("afterburner", JOY_BUTTON_LEFT_SHOULDER), "left shoulder should control afterburner")
	_expect(_has_button("evasive_roll", JOY_BUTTON_LEFT_STICK), "left-stick press should commit an evasive roll in the held lateral direction")
	_expect(_has_axis("deploy_countermeasure", JOY_AXIS_TRIGGER_LEFT, 1.0), "left trigger should release the chaff/flare cassette")
	_expect(_has_axis("fire_missile", JOY_AXIS_TRIGGER_RIGHT, 1.0), "right trigger should fire the selected AIM-9")
	_expect(_has_axis("throttle_up", JOY_AXIS_RIGHT_Y, -1.0) and _has_axis("throttle_down", JOY_AXIS_RIGHT_Y, 1.0), "right-stick Y should command persistent forward throttle")

	# Campaign maintenance buttons are deliberately not global InputMap aliases.
	# Their physical buttons have combat meanings and are interpreted only by the
	# screen-gated ControllerSortieBayDirector while the sortie bay is visible.
	for pair in [
		["upgrade", JOY_BUTTON_X],
		["upgrade_generator", JOY_BUTTON_Y],
		["service_hull", JOY_BUTTON_LEFT_SHOULDER],
		["service_shield", JOY_BUTTON_RIGHT_SHOULDER],
		["upgrade_airframe", JOY_BUTTON_LEFT_STICK],
		["upgrade_support", JOY_BUTTON_RIGHT_STICK],
		["cycle_support", JOY_BUTTON_DPAD_LEFT],
		["cycle_battlefield_support", JOY_BUTTON_DPAD_RIGHT]
	]:
		_expect(not _has_button(StringName(pair[0]), int(pair[1])), "sortie-only controller action leaked into global InputMap: %s" % pair[0])

	var sortie_router_script := load("res://scripts/controller_sortie_bay_director.gd") as Script
	_expect(sortie_router_script != null, "controller sortie-bay router should load")
	if sortie_router_script != null:
		var sortie_router: Node = sortie_router_script.new()
		var summary: Dictionary = sortie_router.call("binding_summary")
		_expect(str(summary.get("x", "")) == "BUY PRIMARY", "X should buy the next primary only in the sortie bay")
		_expect(str(summary.get("y", "")) == "BUY GENERATOR", "Y should buy the next generator only in the sortie bay")
		_expect(str(summary.get("lb", "")) == "SERVICE HULL" and str(summary.get("rb", "")) == "RECHARGE SHIELD", "shoulders should service the aircraft only in the sortie bay")
		_expect(str(summary.get("l3", "")) == "BUY AIRFRAME" and str(summary.get("r3", "")) == "BUY TACTICAL", "stick clicks should own the remaining progression purchases")
		_expect(str(summary.get("dpad_left", "")) == "SELECT TACTICAL" and str(summary.get("dpad_right", "")) == "SELECT BATTLEFIELD", "sortie-bay d-pad should select support without global menu leakage")
		sortie_router.free()
	var router_source := FileAccess.get_file_as_string("res://scripts/controller_sortie_bay_director.gd")
	_expect(router_source.contains('front_end_screen') and router_source.contains('"sortie"') and router_source.contains('StartupSequenceDirector'), "controller maintenance router should be gated to the visible campaign sortie bay after startup")
	_expect(router_source.contains('_try_buy_next_weapon') and router_source.contains('_try_buy_next_generator') and router_source.contains('_service_hull_full') and router_source.contains('_service_shield_full'), "controller maintenance router should reach the four main campaign service commands")
	_expect(router_source.contains('_buy_next_airframe') and router_source.contains('_buy_next_support'), "controller maintenance router should reach airframe and tactical progression")

	# Menu contexts reuse fixed combat buttons only while their relevant screen is
	# visible. Prove the temporary mapping and exact restoration without changing
	# the universal/in-flight controller contract.
	var menu_context_script := load("res://scripts/controller_menu_context_director.gd") as Script
	_expect(menu_context_script != null, "controller menu context director should load")
	if menu_context_script != null:
		var menu_context: Node = menu_context_script.new()
		menu_context.call("_set_context", "options")
		_expect(_has_button("confirm", JOY_BUTTON_A), "Options should retain A/confirm for value adjustment")
		_expect(_has_button("fire_secondary", JOY_BUTTON_X) and not _has_button("fire_secondary", JOY_BUTTON_B), "Options should use X for next category while preserving B as back")
		menu_context.call("_set_context", "controls")
		_expect(not _has_button("confirm", JOY_BUTTON_A), "Flight Controls should suppress pad A so a controller cannot enter keyboard-only key listening")
		_expect(_has_button("fire_secondary", JOY_BUTTON_B) and not _has_button("fire_secondary", JOY_BUTTON_X), "leaving Options should restore B as the universal secondary-fire button")
		menu_context.call("_set_context", "")
		_expect(_has_button("confirm", JOY_BUTTON_A), "leaving Flight Controls should restore A/confirm")
		_expect(_has_button("fire_secondary", JOY_BUTTON_B) and not _has_button("fire_secondary", JOY_BUTTON_X), "universal secondary-fire mapping should be exactly restored after menu context")
		menu_context.free()
	var menu_context_source := FileAccess.get_file_as_string("res://scripts/controller_menu_context_director.gd")
	_expect(menu_context_source.contains('"options"') and menu_context_source.contains('"controls"') and menu_context_source.contains('JOY_BUTTON_B') and menu_context_source.contains('JOY_BUTTON_X'), "controller menu context should own the Options B/X conflict explicitly")
	_expect(menu_context_source.contains('qa_controls_confirm_suppressed') and menu_context_source.contains('PAD VIEW ONLY') and menu_context_source.contains('PAD Y/X CATEGORY'), "controller menu context should expose native QA receipts and discoverable pad hints")

	bindings.call("restore_keyboard_defaults", false)
	_expect(int(bindings.call("binding_count")) == 18, "flight keyboard station should expose all eighteen combat and propulsion bindings")
	_expect(str(bindings.call("binding_label", 6)) == "WING GEOMETRY", "binding catalogue should expose player-facing action labels")
	_expect(str(bindings.call("binding_key_name", 6)) == "Q", "binding catalogue should expose the active physical key")
	_expect(bool(bindings.call("rebind", 6, KEY_T, false)), "keyboard control should accept a live replacement key")
	_expect(_has_key("transform_craft", KEY_T) and not _has_key("transform_craft", KEY_Q), "rebinding should replace the gameplay action event")
	_expect(_has_button("transform_craft", JOY_BUTTON_Y), "keyboard rebinding must preserve controller input")
	_expect(bool(bindings.call("rebind", 7, KEY_T, false)), "binding conflicts should be resolved instead of rejected")
	_expect(_has_key("afterburner", KEY_T) and _has_key("transform_craft", KEY_SHIFT), "a conflict should swap keys so both flight actions remain reachable")
	bindings.call("restore_keyboard_defaults", false)
	_expect(_has_key("transform_craft", KEY_Q), "defaults restore should recover the authored keyboard layout")
	_expect(_has_key("throttle_up", KEY_T) and _has_key("throttle_down", KEY_G), "defaults should expose a dedicated keyboard throttle axis")
	var main := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main != null and main.get_as_text().contains("control_listening") and main.get_as_text().contains("KEY RESERVED FOR CONTROL STATION"), "front end should own safe live keyboard capture")
	_expect(main != null and main.get_as_text().contains("--capture-control-selection="), "visual QA should expose the complete scrollable binding catalogue")
	var ui := FileAccess.open("res://scripts/pixel_ui_director.gd", FileAccess.READ)
	_expect(ui != null and ui.get_as_text().contains("FLIGHT CONTROL ASSIGNMENT") and ui.get_as_text().contains("PRESS NEW KEY"), "flight-control screen should render the live assignment state")
	_expect(ui != null and ui.get_as_text().contains("KEYBOARD COMMANDS // %s"), "flight-control page header should use a concise command range instead of an inaccurate controller-active label")
	_expect(ui != null and ui.get_as_text().contains('"%02d-%02d / %02d"') and ui.get_as_text().contains("UP / DOWN SELECT"), "flight-control station should identify the visible binding range and scrolling navigation")
	var overlay_source := FileAccess.get_file_as_string("res://scripts/progression_cost_director.gd")
	_expect(overlay_source.contains("PAD X WPN") and overlay_source.contains("L3 FRAME") and overlay_source.contains("RB SHLD") and overlay_source.contains("RT SELECT"), "sortie bay should expose a compact controller maintenance legend")
	_expect(overlay_source.contains("FORM IN FLIGHT"), "sortie bay should not advertise a nonfunctional hangar wing-sweep command")
	var airframe_source := FileAccess.get_file_as_string("res://scripts/airframe_director.gd")
	_expect(airframe_source.contains("_sortie_bay_active") and airframe_source.contains('front_end_screen'), "airframe upgrades should be gated to the actual sortie bay")

	var guidance_script := load("res://scripts/first_sortie_guidance_director.gd") as Script
	_expect(guidance_script != null, "first-sortie guidance director should load")
	if guidance_script != null:
		var guidance: Node = guidance_script.new()
		_expect(str(guidance.call("_forced_guidance", "steer_fire").get("text", "")).contains("A-D/LS STEER"), "Mission 1 should teach steering and primary fire without a modal tutorial")
		_expect(str(guidance.call("_forced_guidance", "power_geometry").get("text", "")).contains("Q/Y GEOMETRY"), "Mission 1 should introduce throttle and VX-94 geometry")
		_expect(str(guidance.call("_forced_guidance", "altitude").get("text", "")).contains("PGUP-PGDN / D-PAD"), "Mission 1 should expose altitude controls before egress")
		_expect(str(guidance.call("_forced_guidance", "countermeasure").get("text", "")).contains("V / LT COUNTERMEASURE"), "first real missile threat should expose countermeasure input")
		_expect(str(guidance.call("_forced_guidance", "egress_climb").get("text", "")).contains("D-PAD UP -> HIGH"), "Mission 1 egress should name the climb input")
		_expect(str(guidance.call("_forced_guidance", "egress_burn").get("text", "")).contains("SHIFT / LB AFTERBURNER"), "Mission 1 egress should name the afterburner input")
		guidance.free()
	var guidance_source := FileAccess.get_file_as_string("res://scripts/first_sortie_guidance_director.gd")
	_expect(guidance_source.contains('int(scene.get("mission_index")) != 0') and guidance_source.contains('str(scene.get("game_mode")) != "campaign"'), "first-sortie prompts must stay limited to Mission 1 campaign play")
	_expect(guidance_source.contains('active_secret_mission_id') and guidance_source.contains('egress_active') and guidance_source.contains('ThreatWarningRules.homing_count'), "guidance should exclude secret sorties and react to real egress/threat state")
	_expect(guidance_source.contains('InputMap.action_get_events') and guidance_source.contains('_keyboard_label'), "Mission 1 guidance should follow live rebound keyboard assignments")

	bindings.free()
	if failures.is_empty():
		print("HYPERSONIC controller input, menu context and first-sortie guidance self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _has_button(action: StringName, button: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func _has_axis(action: StringName, axis: int, value: float) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false

func _has_key(action: StringName, key: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
