extends Node

const ANALOG_DEADZONE := 0.18
const SETTINGS_PATH := "user://hypersonic_options.cfg"

const KEYBOARD_BINDINGS := [
	{"action":"move_left", "label":"MANEUVER LEFT", "default":KEY_A},
	{"action":"move_right", "label":"MANEUVER RIGHT", "default":KEY_D},
	{"action":"move_up", "label":"MANEUVER UP", "default":KEY_W},
	{"action":"move_down", "label":"MANEUVER DOWN", "default":KEY_S},
	{"action":"fire_primary", "label":"PRIMARY FIRE", "default":KEY_SPACE},
	{"action":"fire_secondary", "label":"SCREEN BOMB", "default":KEY_X},
	{"action":"transform_craft", "label":"WING GEOMETRY", "default":KEY_Q},
	{"action":"afterburner", "label":"AFTERBURNER", "default":KEY_SHIFT},
	{"action":"evasive_roll", "label":"EVASIVE ROLL", "default":KEY_C},
	{"action":"deploy_countermeasure", "label":"CHAFF / FLARE", "default":KEY_V},
	{"action":"fire_missile", "label":"AIM-9 MISSILE", "default":KEY_M},
	{"action":"fire_support", "label":"TACTICAL SYSTEM", "default":KEY_Z},
	{"action":"call_battlefield_support", "label":"ALLIED SUPPORT", "default":KEY_F},
	{"action":"altitude_up", "label":"ALTITUDE UP", "default":KEY_PAGEUP},
	{"action":"altitude_down", "label":"ALTITUDE DOWN", "default":KEY_PAGEDOWN},
	{"action":"drop_strike_ordnance", "label":"STRIKE ORDNANCE", "default":KEY_E},
	{"action":"throttle_up", "label":"THROTTLE INCREASE", "default":KEY_T},
	{"action":"throttle_down", "label":"THROTTLE DECREASE", "default":KEY_G}
]

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

func _ready() -> void:
	apply_saved_keyboard_bindings()

func _configure_controller() -> void:
	_add_axis_action("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis_action("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis_action("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis_action("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_axis_action("deploy_countermeasure", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_axis_action("fire_missile", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_axis_action("throttle_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_axis_action("throttle_down", JOY_AXIS_RIGHT_Y, 1.0)
	for action in BUTTON_BINDINGS:
		_add_button_action(StringName(action), int(BUTTON_BINDINGS[action]))

func binding_count() -> int:
	return KEYBOARD_BINDINGS.size()

func binding_label(index: int) -> String:
	return str(KEYBOARD_BINDINGS[clampi(index, 0, KEYBOARD_BINDINGS.size() - 1)].label)

func binding_action(index: int) -> StringName:
	return StringName(KEYBOARD_BINDINGS[clampi(index, 0, KEYBOARD_BINDINGS.size() - 1)].action)

func binding_key_name(index: int) -> String:
	var key := _keyboard_key_for(binding_action(index))
	return OS.get_keycode_string(key).to_upper() if key != KEY_NONE else "UNBOUND"

func apply_saved_keyboard_bindings() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(SETTINGS_PATH) == OK
	for binding in KEYBOARD_BINDINGS:
		var action := StringName(binding.action)
		var key: Key = int(config.get_value("bindings", str(action), int(binding.default))) if loaded else int(binding.default)
		_replace_keyboard_event(action, key)

func rebind(index: int, key: Key, persist: bool = true) -> bool:
	if key == KEY_NONE or index < 0 or index >= KEYBOARD_BINDINGS.size():
		return false
	var target := binding_action(index)
	var old_key := _keyboard_key_for(target)
	for other_index in range(KEYBOARD_BINDINGS.size()):
		if other_index == index:
			continue
		var other := binding_action(other_index)
		if _keyboard_key_for(other) == key:
			_replace_keyboard_event(other, old_key)
	_replace_keyboard_event(target, key)
	if persist:
		_save_keyboard_bindings()
	return true

func restore_keyboard_defaults(persist: bool = true) -> void:
	for binding in KEYBOARD_BINDINGS:
		_replace_keyboard_event(StringName(binding.action), int(binding.default))
	if persist:
		_save_keyboard_bindings()

func _keyboard_key_for(action: StringName) -> Key:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	return KEY_NONE

func _replace_keyboard_event(action: StringName, key: Key) -> void:
	_ensure_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var replacement := InputEventKey.new()
	replacement.physical_keycode = key
	InputMap.action_add_event(action, replacement)

func _save_keyboard_bindings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	for index in range(KEYBOARD_BINDINGS.size()):
		config.set_value("bindings", str(binding_action(index)), int(_keyboard_key_for(binding_action(index))))
	config.save(SETTINGS_PATH)

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
