extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var bindings: Node = load("res://scripts/input_bindings.gd").new()
	bindings.call("_configure_controller")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('InputBindings="*res://scripts/input_bindings.gd"'), "InputBindings should be a project autoload")
	for action in ["move_left","move_right","move_up","move_down","fire_primary","fire_secondary","fire_support","transform_craft","afterburner","evasive_roll","deploy_countermeasure","fire_missile","call_battlefield_support","altitude_up","altitude_down","drop_strike_ordnance","confirm","cancel"]:
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
	bindings.call("restore_keyboard_defaults", false)
	_expect(int(bindings.call("binding_count")) == 16, "flight keyboard station should expose all sixteen combat bindings")
	_expect(str(bindings.call("binding_label", 6)) == "WING GEOMETRY", "binding catalogue should expose player-facing action labels")
	_expect(str(bindings.call("binding_key_name", 6)) == "Q", "binding catalogue should expose the active physical key")
	_expect(bool(bindings.call("rebind", 6, KEY_T, false)), "keyboard control should accept a live replacement key")
	_expect(_has_key("transform_craft", KEY_T) and not _has_key("transform_craft", KEY_Q), "rebinding should replace the gameplay action event")
	_expect(_has_button("transform_craft", JOY_BUTTON_Y), "keyboard rebinding must preserve controller input")
	_expect(bool(bindings.call("rebind", 7, KEY_T, false)), "binding conflicts should be resolved instead of rejected")
	_expect(_has_key("afterburner", KEY_T) and _has_key("transform_craft", KEY_SHIFT), "a conflict should swap keys so both flight actions remain reachable")
	bindings.call("restore_keyboard_defaults", false)
	_expect(_has_key("transform_craft", KEY_Q), "defaults restore should recover the authored keyboard layout")
	var main := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main != null and main.get_as_text().contains("control_listening") and main.get_as_text().contains("KEY RESERVED FOR CONTROL STATION"), "front end should own safe live keyboard capture")
	_expect(main != null and main.get_as_text().contains("--capture-control-selection="), "visual QA should expose the complete scrollable binding catalogue")
	var ui := FileAccess.open("res://scripts/pixel_ui_director.gd", FileAccess.READ)
	_expect(ui != null and ui.get_as_text().contains("FLIGHT CONTROL ASSIGNMENT") and ui.get_as_text().contains("PRESS NEW KEY"), "flight-control screen should render the live assignment state")
	_expect(ui != null and ui.get_as_text().contains('"%02d-%02d / %02d"') and ui.get_as_text().contains("UP / DOWN SELECT"), "flight-control station should identify the visible binding range and scrolling navigation")
	bindings.free()
	if failures.is_empty():
		print("HYPERSONIC controller input self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _has_button(action: StringName, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func _has_axis(action: StringName, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false

func _has_key(action: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
