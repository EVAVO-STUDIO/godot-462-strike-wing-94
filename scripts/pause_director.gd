extends CanvasLayer

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const PixelFont = preload("res://scripts/pixel_font.gd")
const PauseSurface = preload("res://scripts/pause_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v3.png")
const VX94_FIGHTER := preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_modal_screen_9slice.png")
const FRONT_END_CURSOR := preload("res://assets/runtime/ui/menu/front_end/cursor.png")
const ROW_IDLE := preload("res://assets/runtime/ui/menu/system_options/row_idle.png")
const ROW_SELECTED := preload("res://assets/runtime/ui/menu/system_options/row_selected.png")
const VALUE_TROUGH := preload("res://assets/runtime/ui/menu/system_options/value_trough.png")
const VALUE_FILL := preload("res://assets/runtime/ui/menu/system_options/value_fill.png")
const TOGGLE_OFF := preload("res://assets/runtime/ui/menu/system_options/toggle_off.png")
const TOGGLE_ON := preload("res://assets/runtime/ui/menu/system_options/toggle_on.png")
const WARNING_FRAME := preload("res://assets/runtime/ui/menu/pause_command/warning_frame.png")
const COMMAND_ICONS := [
	preload("res://assets/runtime/ui/menu/pause_command/icon_resume.png"), preload("res://assets/runtime/ui/menu/pause_command/icon_options.png"),
	preload("res://assets/runtime/ui/menu/pause_command/icon_restart.png"), preload("res://assets/runtime/ui/menu/pause_command/icon_return.png")]
const WARNING_ICON := preload("res://assets/runtime/ui/menu/pause_command/icon_warning.png")
const COMMAND_LABELS := ["RESUME FLIGHT", "SYSTEM OPTIONS", "RESTART SORTIE", "RETURN TO MENU"]
const TEXT := Color("d9e0e5"); const MUTED := Color("7f909b"); const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a"); const GREEN := Color("67c3a5"); const RED := Color("dc6655")

var _paused := false
var _surface: Control
var _mode := "menu"
var _selection := 0
var _option_selection := 0
var _option_category := 0
var _capture_pending := ""

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_surface = PauseSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	_surface.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_surface)
	_surface.visible = false
	var capture := _capture_pause_state()
	if not capture.is_empty():
		_capture_pending = capture

func _capture_pause_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-pause="):
			var value := argument.trim_prefix("--capture-pause=").to_lower()
			return value if value in ["menu", "options", "confirm_restart", "confirm_return"] else ""
	return ""

func _process(_delta: float) -> void:
	if not _capture_pending.is_empty():
		var capture_scene := get_tree().current_scene
		if capture_scene != null and _has_property(capture_scene, "phase") and int(capture_scene.get("phase")) == 1:
			_paused = true
			_mode = _capture_pending
			_capture_pending = ""
			_surface.visible = true
			get_tree().paused = true
			_surface.queue_redraw()
		else:
			return
	if not _paused: return
	if not get_tree().paused:
		_close_overlay()
		return
	match _mode:
		"menu": _update_menu()
		"options": _update_options()
		_: _update_confirmation()
	if _surface != null: _surface.queue_redraw()

func _update_menu() -> void:
	if Input.is_action_just_pressed("cancel"):
		resume_game(); return
	if Input.is_action_just_pressed("move_up"): _selection = posmod(_selection - 1, COMMAND_LABELS.size())
	elif Input.is_action_just_pressed("move_down"): _selection = posmod(_selection + 1, COMMAND_LABELS.size())
	elif Input.is_action_just_pressed("restart"): _mode = "confirm_restart"
	elif Input.is_action_just_pressed("confirm"): _activate_menu_item(_selection)

func _update_options() -> void:
	var settings := get_node_or_null("/root/SettingsDirector")
	var category_count:=int(settings.call("category_count")) if settings!=null and settings.has_method("category_count") else 1
	if Input.is_action_just_pressed("transform_craft"):_option_category=posmod(_option_category-1,category_count);_option_selection=0;return
	if Input.is_action_just_pressed("fire_secondary"):_option_category=posmod(_option_category+1,category_count);_option_selection=0;return
	var setting_count:=int(settings.call("category_setting_count",_option_category)) if settings!=null and settings.has_method("category_setting_count") else 1
	if Input.is_action_just_pressed("cancel"):
		_mode = "menu"; return
	if Input.is_action_just_pressed("move_up"): _option_selection = posmod(_option_selection - 1, setting_count)
	elif Input.is_action_just_pressed("move_down"): _option_selection = posmod(_option_selection + 1, setting_count)
	var direction := 0
	if Input.is_action_just_pressed("move_left"): direction = -1
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("confirm"): direction = 1
	if direction != 0:
		if settings!=null and settings.has_method("adjust_setting"):settings.call("adjust_setting",int(settings.call("category_global_index",_option_category,_option_selection)),direction)

func _update_confirmation() -> void:
	if Input.is_action_just_pressed("cancel"): _mode = "menu"
	elif Input.is_action_just_pressed("confirm"):
		if _mode == "confirm_restart": restart_sortie()
		else: return_to_menu()

func _activate_menu_item(index: int) -> void:
	match index:
		0: resume_game()
		1: _mode = "options"
		2: _mode = "confirm_restart"
		3: _mode = "confirm_return"

func pause_game() -> bool:
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1: return false
	var cinematic := get_node_or_null("/root/CampaignCinematicDirector")
	if cinematic != null and cinematic.has_method("cinematic_active") and bool(cinematic.call("cinematic_active")): return false
	_paused = true; _mode = "menu"; _selection = 0
	get_tree().paused = true
	if _surface != null:
		_surface.visible = true; _surface.queue_redraw()
	return true

func resume_game() -> void:
	get_tree().paused = false
	_close_overlay()

func restart_sortie() -> void:
	var scene := get_tree().current_scene
	get_tree().paused = false
	_close_overlay()
	if scene != null and scene.has_method("_start_mission"): scene.call("_start_mission")

func return_to_menu() -> void:
	var scene := get_tree().current_scene
	get_tree().paused = false
	_close_overlay()
	if scene == null: return
	if scene.has_method("_clear_combat"): scene.call("_clear_combat")
	scene.set("phase", 0)
	if _has_property(scene, "front_end_screen"): scene.set("front_end_screen", "main_menu")
	if _has_property(scene, "menu_selection"): scene.set("menu_selection", 0)

func pause_active() -> bool: return _paused

func draw_pause(surface: CanvasItem) -> void:
	if not _paused: return
	surface.draw_rect(Rect2(0, 0, 640, 360), Color(0.005, 0.01, 0.015, 0.82))
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_SCREEN, Rect2(54, 24, 532, 312), 8)
	surface.draw_texture_rect(VX94_FIGHTER, Rect2(76, 40, 64, 72), false, Color(0.82, 0.90, 0.94, 1.0))
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(190, 37, 260, 42), false)
	PixelFont.draw_centered(surface, "VX-94 FLIGHT CONTROL // TACTICAL HOLD", 344, 84, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "SIMULATION PAUSED", 344, 98, 1, GOLD, 1)
	if _mode == "options": _draw_options(surface)
	elif _mode.begins_with("confirm_"): _draw_confirmation(surface)
	else: _draw_menu(surface)

func _draw_menu(surface: CanvasItem) -> void:
	for index in range(COMMAND_LABELS.size()):
		var position := Vector2(100, 120 + index * 38)
		surface.draw_texture(ROW_SELECTED if index == _selection else ROW_IDLE, position)
		if index == _selection: surface.draw_texture(FRONT_END_CURSOR, position + Vector2(-16, 6))
		surface.draw_texture(COMMAND_ICONS[index], position + Vector2(12, 6))
		PixelFont.draw_text(surface, COMMAND_LABELS[index], position + Vector2(40, 9), 1, GOLD if index == _selection else TEXT, 1)
	PixelFont.draw_centered(surface, "ENTER SELECT   ESC RESUME", 320, 290, 1, MUTED, 1)
	PixelFont.draw_centered(surface, "MISSION TIME AND ENCOUNTER STATE HELD", 320, 310, 1, BLUE, 1)

func _draw_options(surface: CanvasItem) -> void:
	var settings := get_node_or_null("/root/SettingsDirector")
	var count:=int(settings.call("category_setting_count",_option_category)) if settings!=null and settings.has_method("category_setting_count") else 1
	PixelFont.draw_centered(surface,"< %s >" % str(settings.call("category_name",_option_category)),320,108,1,GOLD,1)
	for index in range(count):
		var position:=Vector2(100,122+index*38)
		surface.draw_texture(ROW_SELECTED if index == _option_selection else ROW_IDLE, position)
		if index == _option_selection: surface.draw_texture(FRONT_END_CURSOR, position + Vector2(-16, 6))
		var global_index:=int(settings.call("category_global_index",_option_category,index)) if settings!=null else index
		var label:=str(settings.call("setting_label",global_index)) if settings!=null else "OPTION"
		var value:=str(settings.call("setting_value",global_index)) if settings!=null else "--"
		var ratio:=float(settings.call("setting_ratio",global_index)) if settings!=null else 0.0
		PixelFont.draw_text(surface, label, position + Vector2(18, 9), 1, GOLD if index == _option_selection else TEXT, 1)
		if global_index in [0,1,8,9,10,11]:surface.draw_texture(TOGGLE_ON if ratio>=0.5 else TOGGLE_OFF,position+Vector2(306,8))
		else:
			surface.draw_texture(VALUE_TROUGH, position + Vector2(286, 11))
			_draw_clipped_fill(surface, VALUE_FILL, position + Vector2(288, 13), ratio)
		PixelFont.draw_text(surface, value, position + Vector2(382 - PixelFont.text_width(value,1,1), 9), 1, GREEN if ratio >= 0.5 else MUTED, 1)
	PixelFont.draw_centered(surface, "LEFT / RIGHT ADJUST   ESC COMMANDS", 320, 294, 1, MUTED, 1)

func _draw_confirmation(surface: CanvasItem) -> void:
	var title := "RESTART CURRENT SORTIE?" if _mode == "confirm_restart" else "ABORT TO MAIN MENU?"
	surface.draw_texture(WARNING_FRAME, Vector2(120, 142))
	surface.draw_texture(WARNING_ICON, Vector2(144, 160))
	PixelFont.draw_centered(surface, title, 320, 157, 2, RED, 1)
	PixelFont.draw_centered(surface, "CURRENT MISSION PROGRESS WILL BE LOST", 320, 184, 1, GOLD, 1)
	PixelFont.draw_centered(surface, "ENTER CONFIRM   ESC CANCEL", 320, 202, 1, TEXT, 1)

func _draw_clipped_fill(surface: CanvasItem, texture: Texture2D, position: Vector2, ratio: float) -> void:
	var width := floorf(float(texture.get_width()) * clampf(ratio, 0.0, 1.0))
	if width > 0.0: surface.draw_texture_rect_region(texture, Rect2(position, Vector2(width, texture.get_height())), Rect2(0,0,width,texture.get_height()))

func _close_overlay() -> void:
	_paused = false; _mode = "menu"
	if _surface != null: _surface.visible = false

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)
