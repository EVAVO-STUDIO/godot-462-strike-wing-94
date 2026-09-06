extends CanvasLayer

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const PixelFont = preload("res://scripts/pixel_font.gd")
const MissionIntelRules = preload("res://scripts/mission_intel_rules.gd")
const MissionIntelSurface = preload("res://scripts/mission_intel_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const OPERATIONS_PANEL := preload("res://assets/runtime/ui/menu/operations_panel_9slice.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_modal_screen_9slice.png")
const INTEL_ROW_FRAME := preload("res://assets/runtime/ui/menu/mission_intel/row_frame.png")
const INTEL_READY_LAMP := preload("res://assets/runtime/ui/menu/mission_intel/ready_lamp.png")
const INTEL_ICONS := [
	preload("res://assets/runtime/ui/menu/mission_intel/icon_threat.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_envelope.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_profile.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_lanes.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_routes.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_boss.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_allied.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_advice.png"),
]

const BG := Color("070a0e")
const BORDER := Color("34414b")
const TEXT := Color("d9e0e5")
const MUTED := Color("7f909b")
const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a")
const GREEN := Color("67c3a5")
const RED := Color("dc6655")

var _surface: Control
var _open := false

func _ready() -> void:
	layer = 31
	_surface = MissionIntelSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_ensure_action()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != null and _sortie_front_end(scene):
		if Input.is_action_just_pressed("toggle_mission_intel"):
			_open = not _open
	else:
		_open = false
	if _surface != null:
		_surface.queue_redraw()

func draw_intel(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _sortie_front_end(scene):
		return
	if not _open:
		UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_PANEL, Rect2(548, 334, 78, 15), 5)
		PixelFont.draw_centered(surface, "I INTEL", 587, 339, 1, MUTED, 1)
		return
	var context := _mission_context()
	var mission := _active_mission(scene)
	var boss_id := str(mission.get("boss_id", "UNKNOWN"))
	var beats: Array = mission.get("encounter_beats", []) if typeof(mission) == TYPE_DICTIONARY else []
	var lines := MissionIntelRules.mission_lines(context, boss_id, beats)
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_SCREEN, Rect2(54, 68, 532, 254), 8)
	PixelFont.draw_centered(surface, "MISSION INTELLIGENCE", 320, 79, 2, GOLD, 1)
	PixelFont.draw_centered(surface, _mission_name(scene), 320, 101, 1, TEXT, 1)
	for i in range(lines.size()):
		var row_y := 116.0 + float(i * 21)
		surface.draw_texture(INTEL_ROW_FRAME, Vector2(80, row_y))
		if i < INTEL_ICONS.size():
			surface.draw_texture(INTEL_ICONS[i], Vector2(86, row_y + 2.0))
		var color := _row_color(i)
		PixelFont.draw_text(surface, _clip(lines[i], 74), Vector2(110, row_y + 7.0), 1, color, 1)
	surface.draw_texture(INTEL_READY_LAMP, Vector2(83, 295))
	PixelFont.draw_text(surface, "DOSSIER COMPLETE", Vector2(102, 299), 1, GREEN, 1)
	PixelFont.draw_centered(surface, "I CLOSE   ENTER AUTHORIZE LAUNCH", 398, 299, 1, MUTED, 1)

func _row_color(index: int) -> Color:
	match index:
		0: return RED
		5: return RED
		6: return GREEN
		7: return GOLD
	return BLUE

func _mission_context() -> Dictionary:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("mission_context"):
		var value = craft.call("mission_context")
		return value if typeof(value) == TYPE_DICTIONARY else {}
	return {}

func _active_mission(scene: Object) -> Dictionary:
	if not _has_property(scene, "mission_catalog") or not _has_property(scene, "mission_index"):
		return {}
	var catalog = scene.get("mission_catalog")
	if typeof(catalog) != TYPE_ARRAY or catalog.is_empty():
		return {}
	var index := clampi(int(scene.get("mission_index")), 0, catalog.size() - 1)
	var mission = catalog[index]
	return mission if typeof(mission) == TYPE_DICTIONARY else {}

func _mission_name(scene: Object) -> String:
	return str(scene.get("current_mission_name")).to_upper()

func _supports(scene: Object) -> bool:
	return _has_property(scene, "phase") and _has_property(scene, "current_mission_name")

func _sortie_front_end(scene: Object) -> bool:
	return _supports(scene) and int(scene.get("phase")) == 0 and (not _has_property(scene, "front_end_screen") or str(scene.get("front_end_screen")) == "sortie")

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)

func _clip(text: String, max_chars: int) -> String:
	var value := text.to_upper().replace("_", " ")
	return value if value.length() <= max_chars else value.substr(0, maxi(0, max_chars - 1)) + "."

func _ensure_action() -> void:
	if not InputMap.has_action("toggle_mission_intel"):
		InputMap.add_action("toggle_mission_intel")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_I
	if not InputMap.action_has_event("toggle_mission_intel", event):
		InputMap.action_add_event("toggle_mission_intel", event)
