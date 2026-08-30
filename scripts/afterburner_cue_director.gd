extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const AfterburnerCueSurface = preload("res://scripts/afterburner_cue_surface.gd")

const PANEL := Color("070a0e")
const BORDER := Color("34414b")
const TEXT := Color("d9e0e5")
const FUEL := Color("e8ca6a")
const HOT := Color("e8894f")
const CORE := Color("d9e9ff")

var _surface: Control
var _boom_age := 99.0
var _last_hypersonic := false

func _ready() -> void:
	layer = 14
	_surface = AfterburnerCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_boom_age += maxf(0.0, delta)
	var craft := get_node_or_null("/root/CraftFormDirector")
	var active := craft != null and craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))
	if active and not _last_hypersonic:
		_boom_age = 0.0
	_last_hypersonic = active
	if _surface != null:
		_surface.queue_redraw()

func draw_afterburner(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	var craft := get_node_or_null("/root/CraftFormDirector")
	if scene == null or craft == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1:
		return
	if not craft.has_method("afterburner_ratio"):
		return
	var ratio := clampf(float(craft.call("afterburner_ratio")), 0.0, 1.0)
	_draw_meter(surface, ratio)
	if craft.has_method("afterburner_active") and bool(craft.call("afterburner_active")) and _has_property(scene, "player_position"):
		_draw_flame(surface, scene.get("player_position"), str(craft.call("current_form")) if craft.has_method("current_form") else "fighter")
	if _boom_age < 0.42 and _has_property(scene, "player_position"):
		var t := _boom_age / 0.42
		var radius := lerpf(10.0, 118.0, t)
		surface.draw_arc(scene.get("player_position"), radius, 0.0, TAU, 64, Color(0.75,0.88,1.0,1.0-t), 2.0)

func _draw_meter(surface: CanvasItem, ratio: float) -> void:
	surface.draw_rect(Rect2(14, 315, 92, 13), PANEL)
	surface.draw_rect(Rect2(14, 315, 92, 13), BORDER, false, 1.0)
	PixelFont.draw_text(surface, "AB", Vector2(19, 319), 1, TEXT, 1)
	surface.draw_rect(Rect2(39, 319, 61, 4), BORDER)
	surface.draw_rect(Rect2(39, 319, floorf(61.0 * ratio), 4), FUEL)

func _draw_flame(surface: CanvasItem, p: Vector2, form: String) -> void:
	# Gameplay VX-94 art uses engines at roughly +/-4 px from its registered centre.
	var span := 4.0 if form == "fighter" else 5.0
	for side in [-1.0, 1.0]:
		var x: float = p.x + span * side
		surface.draw_line(Vector2(x, p.y + 20), Vector2(x, p.y + 36), HOT, 3.0)
		surface.draw_line(Vector2(x, p.y + 20), Vector2(x, p.y + 31), CORE, 1.0)

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
