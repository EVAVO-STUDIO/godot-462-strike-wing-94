extends Node

const ANALOG_DEADZONE := 0.18

const BUTTON_BINDINGS := {
	"confirm": JOY_BUTTON_A,
	"cancel": JOY_BUTTON_B,
	"fire_primary": JOY_BUTTON_A,
	"fire_secondary": JOY_BUTTON_B,
	"fire_support": JOY_BUTTON_X,
	"transform_craft": JOY_BUTTON_Y,
	"afterburner": JOY_BUTTON_LEFT_SHOULDER,
	"evasive_roll": JOY_BUTTON_LEFT_STICK,
	"call_battlefield_support": JOY_BUTTON_RIGHT_SHOULDER,
	"cycle_support": JOY_BUTTON_DPAD_LEFT,
	"cycle_battlefield_support": JOY_BUTTON_DPAD_RIGHT,
	"altitude_up": JOY_BUTTON_DPAD_UP,
	"altitude_down": JOY_BUTTON_DPAD_DOWN,
	"drop_strike_ordnance": JOY_BUTTON_RIGHT_STICK,
	"toggle_mission_intel": JOY_BUTTON_BACK,
	"restart": JOY_BUTTON_X
}

func _enter_tree() -> void:
	_configure_controller()

func _configure_controller() -> void:
	_add_axis_action("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis_action("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis_action("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis_action("move_down", JOY_AXIS_LEFT_Y, 1.0)
	for action in BUTTON_BINDINGS:
		_add_button_action(StringName(action), int(BUTTON_BINDINGS[action]))

func _ensure_action(action: StringName, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)

func _add_button_action(action: StringName, button_index: int) -> void:
	_ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _add_axis_action(action: StringName, axis: int, axis_value: float) -> void:
	_ensure_action(action, ANALOG_DEADZONE)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
