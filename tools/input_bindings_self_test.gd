extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var bindings: Node = load("res://scripts/input_bindings.gd").new()
	bindings.call("_configure_controller")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('InputBindings="*res://scripts/input_bindings.gd"'), "InputBindings should be a project autoload")
	for action in ["move_left","move_right","move_up","move_down","fire_primary","fire_secondary","fire_support","transform_craft","afterburner","evasive_roll","call_battlefield_support","altitude_up","altitude_down","drop_strike_ordnance","confirm","cancel"]:
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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
