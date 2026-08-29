extends CanvasLayer

const AltitudeTransitionSurface = preload("res://scripts/altitude_transition_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")

var _surface: Control

func _ready() -> void:
	layer = 14
	_surface = AltitudeTransitionSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_altitude_transition_surface(surface: CanvasItem) -> void:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft == null or not craft.has_method("altitude_transition_active") or not bool(craft.call("altitude_transition_active")):
		return
	var ratio := clampf(float(craft.call("altitude_transition_ratio")), 0.0, 1.0)
	var direction := int(craft.call("altitude_transition_direction"))
	var from_band := str(craft.call("altitude_transition_from"))
	var to_band := str(craft.call("altitude_transition_to"))
	var eased := smoothstep(0.0, 1.0, ratio)
	_draw_cloud_sweep(surface, eased, direction)
	_draw_speed_brackets(surface, eased, direction)
	var label := "CLIMB" if direction > 0 else "DIVE"
	PixelFont.draw_text(surface, Vector2(278, 68), "%s  %s > %s" % [label, _code(from_band), _code(to_band)], 1, Color(0.78,0.9,0.94,0.94))

func _draw_cloud_sweep(surface: CanvasItem, ratio: float, direction: int) -> void:
	var travel := 160.0 * ratio
	var sign_dir := -1.0 if direction > 0 else 1.0
	var cloud := Color(0.78,0.84,0.86,0.13)
	var edge := Color(0.65,0.78,0.82,0.22)
	for i in range(7):
		var base_y := 86.0 + float(i) * 42.0
		var y := fposmod(base_y + sign_dir * travel, 330.0) + 36.0
		var x := 72.0 + float((i * 83) % 430)
		surface.draw_circle(Vector2(x,y), 16.0 + float(i % 3) * 5.0, cloud)
		surface.draw_circle(Vector2(x+18,y+2), 11.0 + float(i % 2) * 4.0, cloud)
		surface.draw_line(Vector2(x-22,y+10),Vector2(x+36,y+10),edge,1.0)

func _draw_speed_brackets(surface: CanvasItem, ratio: float, direction: int) -> void:
	var alpha := sin(ratio * PI) * 0.55
	if alpha <= 0.01:
		return
	var color := Color(0.42,0.72,0.82,alpha)
	var skew := 10.0 if direction > 0 else -10.0
	for x in [92.0,548.0]:
		for i in range(5):
			var y := 104.0 + i * 48.0
			surface.draw_line(Vector2(x,y),Vector2(x+skew,y+12),color,1.0)

func _code(band: String) -> String:
	match AltitudeRules.sanitize(band):
		AltitudeRules.LOW: return "LOW"
		AltitudeRules.MID: return "MID"
		AltitudeRules.HIGH: return "HIGH"
		AltitudeRules.ORBITAL: return "ORB"
	return "MID"
