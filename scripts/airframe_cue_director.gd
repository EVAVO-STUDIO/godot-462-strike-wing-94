extends CanvasLayer

const AirframeCueSurface = preload("res://scripts/airframe_cue_surface.gd")

const ARMOR := Color("9aa6ad")
const ARMOR_DARK := Color("4d5961")
const FIELD := Color("67c3a5")
const FIELD_DIM := Color(0.40, 0.76, 0.65, 0.58)
const COUPLED := Color("6aa4c8")

var _surface: Control

func _ready() -> void:
	layer = 13
	_surface = AirframeCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_airframe_cues(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var p: Vector2 = scene.get("player_position")
	match _airframe_id():
		"ceramic_titanium_frame":
			_draw_armor_strakes(surface, p, false)
		"reactive_alloy_frame":
			_draw_armor_strakes(surface, p, true)
		"magneto_composite_frame":
			_draw_armor_strakes(surface, p, true)
			_draw_magnetic_nodes(surface, p)
		"field_coupled_frame":
			_draw_armor_strakes(surface, p, true)
			_draw_magnetic_nodes(surface, p)
			_draw_field_lattice(surface, p)

func _draw_armor_strakes(surface: CanvasItem, p: Vector2, reactive: bool) -> void:
	var form := _craft_form()
	var wing_x := 21.0 if form == "bomber" else 12.0
	var wing_y := 7.0 if form == "bomber" else 8.0
	for side in [-1.0, 1.0]:
		var x: float = p.x + wing_x * side
		surface.draw_rect(Rect2(roundf(x - 2.0), roundf(p.y + wing_y), 4, 2), ARMOR)
		surface.draw_rect(Rect2(roundf(x - 1.0), roundf(p.y + wing_y + 2.0), 2, 2), ARMOR_DARK)
	if reactive:
		for side in [-1.0, 1.0]:
			var x: float = p.x + (15.0 if form == "bomber" else 8.0) * side
			surface.draw_rect(Rect2(roundf(x - 2.0), roundf(p.y + 2.0), 4, 3), ARMOR_DARK)

func _draw_magnetic_nodes(surface: CanvasItem, p: Vector2) -> void:
	var form := _craft_form()
	var span := 23.0 if form == "bomber" else 14.0
	for side in [-1.0, 1.0]:
		var node := p + Vector2(span * side, 5)
		surface.draw_rect(Rect2(roundf(node.x - 2), roundf(node.y - 2), 4, 4), FIELD)
		surface.draw_line(node + Vector2(-3,0), node + Vector2(3,0), FIELD_DIM, 1.0)

func _draw_field_lattice(surface: CanvasItem, p: Vector2) -> void:
	var form := _craft_form()
	var span := 26.0 if form == "bomber" else 17.0
	surface.draw_arc(p, span, deg_to_rad(205.0), deg_to_rad(335.0), 10, FIELD_DIM, 1.0)
	surface.draw_line(p + Vector2(-7,-2), p + Vector2(-span,7), COUPLED, 1.0)
	surface.draw_line(p + Vector2(7,-2), p + Vector2(span,7), COUPLED, 1.0)

func _airframe_id() -> String:
	var director := get_node_or_null("/root/AirframeDirector")
	if director != null and director.has_method("current_airframe"):
		var frame = director.call("current_airframe")
		if typeof(frame) == TYPE_DICTIONARY:
			return str(frame.get("id", "composite_frame_mk1"))
	return "composite_frame_mk1"

func _craft_form() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("current_form"):
		return str(director.call("current_form"))
	return "fighter"

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("player_position")
