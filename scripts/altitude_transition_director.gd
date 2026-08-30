extends CanvasLayer

const AltitudeTransitionSurface = preload("res://scripts/altitude_transition_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const TRANSITION_CLOUDS := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_b.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_b.png"),
]

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
	if craft == null:
		return
	if craft.has_method("altitude_transition_active") and bool(craft.call("altitude_transition_active")):
		var ratio := clampf(float(craft.call("altitude_transition_ratio")), 0.0, 1.0)
		var direction := int(craft.call("altitude_transition_direction"))
		var from_band := str(craft.call("altitude_transition_from"))
		var to_band := str(craft.call("altitude_transition_to"))
		var eased := smoothstep(0.0, 1.0, ratio)
		_draw_cloud_sweep(surface, eased, direction)
		_draw_speed_brackets(surface, eased, direction)
		var label := "CLIMB" if direction > 0 else "DIVE"
		PixelFont.draw_text(surface, "%s  %s > %s" % [label, _code(from_band), _code(to_band)], Vector2(272, 68), 1, Color(0.78,0.9,0.94,0.94))
		return
	_draw_choice_prompt(surface, craft)

func _draw_choice_prompt(surface: CanvasItem, craft: Node) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1 or not _has_property(scene, "mission_time"):
		return
	if not craft.has_method("altitude_choice_available") or not bool(craft.call("altitude_choice_available", float(scene.get("mission_time")))):
		return
	var bands: Array = craft.call("altitude_choice_bands", float(scene.get("mission_time")))
	var current := str(craft.call("current_altitude")) if craft.has_method("current_altitude") else AltitudeRules.MID
	var higher := AltitudeRules.adjacent_band(current, 1)
	var lower := AltitudeRules.adjacent_band(current, -1)
	var parts: Array[String] = []
	if higher != current and higher in bands:
		parts.append("PGUP %s" % _code(higher))
	if lower != current and lower in bands:
		parts.append("PGDN %s" % _code(lower))
	if parts.is_empty():
		return
	var text := "ALTITUDE LANE  %s" % "  ".join(parts)
	var width := float(text.length() * 4 + 14)
	var x := roundf(320.0 - width * 0.5)
	surface.draw_rect(Rect2(x, 329, width, 18), Color(0.03,0.06,0.08,0.72))
	surface.draw_rect(Rect2(x, 329, width, 18), Color(0.34,0.58,0.68,0.68), false, 1.0)
	PixelFont.draw_text(surface, text, Vector2(x+7,335), 1, Color(0.76,0.88,0.92,0.92))

func _draw_cloud_sweep(surface: CanvasItem, ratio: float, direction: int) -> void:
	var travel := 160.0 * ratio
	var sign_dir := -1.0 if direction > 0 else 1.0
	var edge := Color(0.65,0.78,0.82,0.22)
	for i in range(7):
		var base_y := 86.0 + float(i) * 42.0
		var y := fposmod(base_y + sign_dir * travel, 330.0) + 36.0
		var x := 72.0 + float((i * 83) % 430)
		var texture: Texture2D = TRANSITION_CLOUDS[i % TRANSITION_CLOUDS.size()]
		var scale := 0.58 + float(i % 3) * 0.10
		var size := Vector2(texture.get_size()) * scale
		surface.draw_texture_rect(texture, Rect2(Vector2(x,y) - size * 0.5, size), false, Color(0.78,0.84,0.86,0.18))
		surface.draw_line(Vector2(x-size.x*0.38,y+size.y*0.32),Vector2(x+size.x*0.44,y+size.y*0.32),edge,1.0)

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

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
