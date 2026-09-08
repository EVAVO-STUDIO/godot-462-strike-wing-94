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
	if DisplayServer.get_name() != "headless":
		_surface = ControllerMenuContextSurface.new()
		_surface.director = self
		_surface.position = Vector2.ZERO
		_surface.size = Vector2(640, 360)
		_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		# Confirm/A is deliberately removed from the keyboard-rebind screen. The
		# page is inspectable with a pad, but rebinding itself remains a keyboard
		# operation and cannot trap a controller-only player in key-listen mode.
		set_meta(&"qa_controls_confirm_suppressed", true)
		get_viewport().set_input_as_handled()
	elif _context == "options" and event is InputEventJoypadButton and event.pressed:
		var button := int((event as InputEventJoypadButton).button_index)
		if button == JOY_BUTTON_X: set_meta(&"qa_options_next_category", true)
		elif button == JOY_BUTTON_Y: set_meta(&"qa_options_previous_category", true)
		elif button == JOY_BUTTON_B: set_meta(&"qa_options_back", true)

func _exit_tree() -> void:
	_restore_universal_buttons()

func _wanted_context() -> String:
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
	if _context == "options":
		# Keyboard X remains fire_secondary. For pad navigation B must remain BACK,
		# so temporarily move the secondary-action pad event from B to X. Main's
		# existing options handler then reads Y=previous category, X=next category.
		_remove_button(&"fire_secondary", JOY_BUTTON_B)
		_add_button(&"fire_secondary", JOY_BUTTON_X)
		set_meta(&"qa_options_context_configured", true)
	elif _context == "controls":
		# The control station edits keyboard assignments only. Prevent controller A
		# from entering a listener that accepts only InputEventKey.
		_remove_button(&"confirm", JOY_BUTTON_A)
		set_meta(&"qa_controls_context_configured", true)

func _restore_universal_buttons() -> void:
	# Restore the fixed in-flight/universal controller map exactly. Only joypad
	# button events are touched; keyboard bindings and analogue axes are untouched.
	_remove_button(&"fire_secondary", JOY_BUTTON_X)
	_add_button(&"fire_secondary", JOY_BUTTON_B)
	_add_button(&"confirm", JOY_BUTTON_A)

func draw_context_hint(surface: CanvasItem) -> void:
	if _context.is_empty() or not _controller_recent_or_connected():
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
