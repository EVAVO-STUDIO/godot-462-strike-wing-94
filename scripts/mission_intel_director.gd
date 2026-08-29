extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const MissionIntelRules = preload("res://scripts/mission_intel_rules.gd")
const MissionIntelSurface = preload("res://scripts/mission_intel_surface.gd")

const BG := Color("070a0e")
const BORDER := Color("34414b")
const TEXT := Color("d9e0e5")
const MUTED := Color("7f909b")
const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a")

var _surface: Control
var _open := false

func _ready() -> void:
	layer = 29
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
	if scene != null and _supports(scene) and int(scene.get("phase")) == 0:
		if Input.is_action_just_pressed("toggle_mission_intel"):
			_open = not _open
	else:
		_open = false
	if _surface != null:
		_surface.queue_redraw()

func draw_intel(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 0:
		return
	if not _open:
		surface.draw_rect(Rect2(548, 334, 78, 15), BG)
		surface.draw_rect(Rect2(548, 334, 78, 15), BORDER, false, 1.0)
		PixelFont.draw_centered(surface, "I INTEL", 587, 339, 1, MUTED, 1)
		return
	var context := _mission_context()
	var boss_id := _boss_id(scene)
	var lines := MissionIntelRules.mission_lines(context, boss_id)
	surface.draw_rect(Rect2(54, 82, 532, 226), BG)
	surface.draw_rect(Rect2(54, 82, 532, 226), BORDER, false, 1.0)
	surface.draw_rect(Rect2(58, 86, 524, 218), Color("10171d"), false, 1.0)
	PixelFont.draw_centered(surface, "MISSION INTELLIGENCE", 320, 96, 2, GOLD, 1)
	PixelFont.draw_centered(surface, _mission_name(scene), 320, 119, 1, TEXT, 1)
	for i in range(lines.size()):
		var color := BLUE if i in [0,1,2] else TEXT
		PixelFont.draw_text(surface, _clip(lines[i], 74), Vector2(78, 146 + i * 18), 1, color, 1)
	PixelFont.draw_centered(surface, "I CLOSE   ENTER LAUNCH", 320, 282, 1, MUTED, 1)

func _mission_context() -> Dictionary:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("mission_context"):
		var value = craft.call("mission_context")
		return value if typeof(value) == TYPE_DICTIONARY else {}
	return {}

func _mission_name(scene: Object) -> String:
	return str(scene.get("current_mission_name")).to_upper()

func _boss_id(scene: Object) -> String:
	if not _has_property(scene, "mission_catalog") or not _has_property(scene, "mission_index"):
		return "UNKNOWN"
	var catalog = scene.get("mission_catalog")
	if typeof(catalog) != TYPE_ARRAY or catalog.is_empty():
		return "UNKNOWN"
	var index := clampi(int(scene.get("mission_index")), 0, catalog.size() - 1)
	var mission = catalog[index]
	return str(mission.get("boss_id", "UNKNOWN")) if typeof(mission) == TYPE_DICTIONARY else "UNKNOWN"

func _supports(scene: Object) -> bool:
	return _has_property(scene, "phase") and _has_property(scene, "current_mission_name")

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

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
