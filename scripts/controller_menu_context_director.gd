extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const ControllerMenuContextSurface = preload("res://scripts/controller_menu_context_surface.gd")

const BLUE := Color("6aa4c8")
const MUTED := Color("7f909b")
const PANEL := Color(0.02, 0.05, 0.07, 0.86)

var _context := ""
var _surface: Control
var _last_controller_msec := -100000

func _ready() -> void:
	layer = 39
	process_priority = -45
	# PauseDirector freezes the SceneTree. Context remapping still has to run so
	# B can remain BACK instead of also becoming the paused-options category key.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() != "headless":
		_surface = ControllerMenuContextSurface.new()
		_surface.director = self
		_surface.position = Vector2.ZERO
		_surface.size = Vector2(640, 360)
		_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_surface.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_surface)

func _process(_delta: float) -> void:
	var wanted := _wanted_context()
	if wanted != _context:
		_set_context(wanted)
	if _surface != null:
		_surface.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_last_controller_msec = Time.get_ticks_msec()
	if _context == "controls" and event is InputEventJoypadButton and event.pressed and int((event as InputEventJoypadButton).button_index) == JOY_BUTTON_A:
		set_meta(&"qa_controls_confirm_suppressed", true)
		get_viewport().set_input_as_handled()
	elif _context in ["options", "pause_options"] and event is InputEventJoypadButton and event.pressed:
		var button := int((event as InputEventJoypadButton).button_index)
		var prefix := "qa_pause_options_" if _context == "pause_options" else "qa_options_"
		if button == JOY_BUTTON_X:
			set_meta(StringName(prefix + "next_category"), true)
		elif button == JOY_BUTTON_Y:
			set_meta(StringName(prefix + "previous_category"), true)
		elif button == JOY_BUTTON_B:
			set_meta(StringName(prefix + "back"), true)

func _exit_tree() -> void:
	_restore_universal_buttons()

func _wanted_context() -> String:
	var pause := get_node_or_null("/root/PauseDirector")
	if pause != null and pause.has_method("pause_active") and bool(pause.call("pause_active")):
		var pause_context := str(pause.call("pause_context")) if pause.has_method("pause_context") else ""
		return "pause_options" if pause_context == "options" else ""
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 0:
		return ""
	if not _has_property(scene, "front_end_screen"):
		return ""
	var screen := str(scene.get("front_end_screen"))
	return screen if screen in ["options", "controls"] else ""

func _set_context(next_context: String) -> void:
	_restore_universal_buttons()
	_context = next_context
	if _context in ["options", "pause_options"]:
		_remove_button(&"fire_secondary", JOY_BUTTON_B)
		_add_button(&"fire_secondary", JOY_BUTTON_X)
		if _context == "pause_options":
			set_meta(&"qa_pause_options_context_configured", true)
		else:
			set_meta(&"qa_options_context_configured", true)
	elif _context == "controls":
		_remove_button(&"confirm", JOY_BUTTON_A)
		set_meta(&"qa_controls_context_configured", true)

func _restore_universal_buttons() -> void:
	_remove_button(&"fire_secondary", JOY_BUTTON_X)
	_add_button(&"fire_secondary", JOY_BUTTON_B)
	_add_button(&"confirm", JOY_BUTTON_A)

func draw_context_hint(surface: CanvasItem) -> void:
	if _context not in ["options", "controls"] or not _controller_recent_or_connected():
		return
	var text := "PAD Y/X CATEGORY  LS ADJUST  B BACK" if _context == "options" else "PAD VIEW ONLY  LS SCROLL  B BACK"
	var width := clampf(24.0 + float(text.length()) * 4.0, 220.0, 360.0)
	var x := floorf((640.0 - width) * 0.5)
	var rect := Rect2(x, 106, width, 14)
	surface.draw_rect(rect, PANEL)
	surface.draw_rect(rect, BLUE, false, 1.0)
	PixelFont.draw_centered(surface, text, 320, 109, 1, BLUE if _context == "options" else MUTED, 1)

func _controller_recent_or_connected() -> bool:
	if not Input.get_connected_joypads().is_empty():
		return true
	return Time.get_ticks_msec() - _last_controller_msec <= 10000

func _remove_button(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and int((event as InputEventJoypadButton).button_index) == button:
			InputMap.action_erase_event(action, event)

func _add_button(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and int((event as InputEventJoypadButton).button_index) == button:
			return
	var replacement := InputEventJoypadButton.new()
	replacement.button_index = button
	InputMap.action_add_event(action, replacement)

func context_id() -> String:
	return _context

func _has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for item in object.get_property_list():
		if str(item.get("name", "")) == property_name:
			return true
	return false
