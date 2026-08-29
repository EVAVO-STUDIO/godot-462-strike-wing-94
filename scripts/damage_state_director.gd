extends CanvasLayer

const DamageStateSurface = preload("res://scripts/damage_state_surface.gd")
const TRANSFORM_VISUAL_SECONDS := 0.42

var _surface: Control
var _phase := 0.0
var _form_sweep := 0.0

func _ready() -> void:
	layer = 15
	_surface = DamageStateSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_phase = fposmod(_phase + maxf(0.0, delta) * 9.0, TAU)
	var target := 1.0 if _craft_form() == "bomber" else 0.0
	_form_sweep = move_toward(_form_sweep, target, maxf(0.0, delta) / TRANSFORM_VISUAL_SECONDS)
	if _surface != null:
		_surface.queue_redraw()

func _draw_damage_state(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var max_hull := _max_hull(scene)
	if max_hull <= 0:
		return
	var hull := clampi(int(scene.get("hull")), 0, max_hull)
	var damage_ratio := clampf(1.0 - float(hull) / float(max_hull), 0.0, 1.0)
	if damage_ratio < 0.20:
		return
	var p: Vector2 = scene.get("player_position")
	_draw_panel_scars(surface, p, damage_ratio)
	if damage_ratio >= 0.45:
		_draw_smoke(surface, p, damage_ratio)
	if damage_ratio >= 0.72:
		_draw_critical_sparks(surface, p, damage_ratio)

func _lerp_mount(fighter_offset: Vector2, bomber_offset: Vector2) -> Vector2:
	var t := smoothstep(0.0, 1.0, clampf(_form_sweep, 0.0, 1.0))
	var point := fighter_offset.lerp(bomber_offset, t)
	return Vector2(roundf(point.x), roundf(point.y))

func _draw_panel_scars(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var alpha := clampf(0.28 + ratio * 0.45, 0.0, 0.78)
	var color := Color(0.18,0.20,0.21,alpha)
	var fighter_offsets := [Vector2(-9,5),Vector2(8,7),Vector2(-4,-5),Vector2(5,-1)]
	var bomber_offsets := [Vector2(-20,4),Vector2(17,7),Vector2(-9,-5),Vector2(11,-2)]
	var count := clampi(int(ceil(ratio * float(fighter_offsets.size()))), 1, fighter_offsets.size())
	for i in range(count):
		var q := p + _lerp_mount(fighter_offsets[i], bomber_offsets[i])
		surface.draw_line(q + Vector2(-3,-1), q + Vector2(3,2), color, 1.0)
		surface.draw_rect(Rect2(roundf(q.x)-1, roundf(q.y)+2, 2, 1), color)

func _draw_smoke(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var origin := p + _lerp_mount(Vector2(-6,11), Vector2(-14,10))
	var drift := fposmod(_phase * 7.0, 18.0)
	var smoke := Color(0.36,0.38,0.37,0.16 + ratio * 0.22)
	for i in range(4):
		var y := origin.y + 5.0 + float(i) * 7.0 + drift * 0.25
		var x := origin.x - float(i) * 2.0 + sin(_phase + i) * 2.0
		var radius := 2.0 + float(i) * 1.5
		surface.draw_circle(Vector2(roundf(x), roundf(y)), radius, smoke)

func _draw_critical_sparks(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var flicker := sin(_phase * 2.4)
	if flicker < -0.15:
		return
	var origin := p + _lerp_mount(Vector2(6,7), Vector2(13,6))
	var spark := Color(1.0,0.72,0.26,0.72 + ratio * 0.24)
	var flame := Color(0.96,0.28,0.12,0.55)
	for i in range(4):
		var angle := -PI * 0.5 + (float(i) - 1.5) * 0.42 + sin(_phase + i) * 0.12
		var end := origin + Vector2.RIGHT.rotated(angle) * (5.0 + float(i) * 2.0)
		surface.draw_line(origin, end, spark, 1.0)
	if ratio >= 0.86:
		surface.draw_colored_polygon(PackedVector2Array([
			origin + Vector2(-2,2),
			origin + Vector2(0,10 + sin(_phase)*2.0),
			origin + Vector2(3,2)
		]), flame)

func _max_hull(scene: Object) -> int:
	if scene.has_method("_max_hull"):
		return maxi(1, int(scene.call("_max_hull")))
	return 100

func _craft_form() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_form"):
		return str(craft.call("current_form"))
	return "fighter"

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "hull", "player_position"]:
		if not names.has(required):
			return false
	return true
