extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EnvironmentRules = preload("res://scripts/environment_rules.gd")
const EnvironmentSurface = preload("res://scripts/environment_surface.gd")

var _profiles: Array = []
var _surface: Control

func _ready() -> void:
	layer = 2
	var data = ContentCatalog.load_json("res://data/environment_profiles.json")
	if typeof(data) == TYPE_DICTIONARY:
		_profiles = data.get("profiles", [])
	_surface = EnvironmentSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_environment_surface(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var environment_id := str(scene.get("current_environment"))
	var profile := EnvironmentRules.profile_for(_profiles, environment_id)
	if profile.is_empty():
		return
	var band := _altitude()
	var t := float(scene.get("mission_time"))
	var motif := str(profile.get("motif", environment_id))
	_draw_parallax(surface, profile, band, t)
	match motif:
		"coast": _draw_coast(surface, profile, band, t)
		"industrial": _draw_industrial(surface, profile, band, t)
		"water": _draw_water(surface, profile, band, t)
		"cloud_top": _draw_cloud_top(surface, profile, band, t)
		"orbital": _draw_orbital(surface, profile, band, t)
	_draw_clouds(surface, profile, band, t)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("current_environment") and names.has("mission_time")

func _altitude() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_altitude"):
		return str(craft.call("current_altitude"))
	return "mid"

func _tone(profile: Dictionary, key: String, alpha: float) -> Color:
	var color := Color(str(profile.get(key, "ffffff")))
	color.a = alpha
	return color

func _draw_parallax(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var speeds := [
		EnvironmentRules.parallax_speed(profile, band, "far"),
		EnvironmentRules.parallax_speed(profile, band, "mid"),
		EnvironmentRules.parallax_speed(profile, band, "near")
	]
	var tones := [_tone(profile, "far", 0.18), _tone(profile, "mid", 0.20), _tone(profile, "near", 0.22)]
	var gaps := [44.0, 32.0, 22.0]
	for layer_index in range(3):
		for i in range(18):
			var y := fposmod(float(i) * gaps[layer_index] + t * speeds[layer_index], 340.0) + 54.0
			var x0 := 24.0 + float((i * (37 + layer_index * 11)) % 120)
			surface.draw_line(Vector2(x0, y), Vector2(620.0 - x0 * 0.25, y), tones[layer_index], 1.0)

func _draw_coast(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var scale := EnvironmentRules.ground_detail_scale(band)
	if not EnvironmentRules.should_draw_ground_detail(band): return
	var land := _tone(profile, "near", 0.26)
	var shore := _tone(profile, "mid", 0.32)
	var width := 105.0 * scale
	for i in range(7):
		var y := fposmod(float(i) * 76.0 + t * 26.0, 330.0) + 54.0
		var left := 18.0 + sin(float(i) * 1.7) * 18.0
		surface.draw_colored_polygon(PackedVector2Array([Vector2(left,y-20),Vector2(left+width,y-14),Vector2(left+width+20,y+12),Vector2(left,y+20)]), land)
		surface.draw_line(Vector2(left+width,y-16),Vector2(left+width+20,y+14),shore,2.0)

func _draw_industrial(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var scale := EnvironmentRules.ground_detail_scale(band)
	if not EnvironmentRules.should_draw_ground_detail(band): return
	var tone := _tone(profile, "near", 0.25)
	var edge := _tone(profile, "mid", 0.32)
	var cell := maxf(18.0, 46.0 * scale)
	for row in range(7):
		var y := fposmod(float(row) * 58.0 + t * 30.0, 330.0) + 54.0
		for col in range(6):
			var x := 34.0 + col * 102.0 + float((row * 17) % 22)
			var rect := Rect2(roundf(x), roundf(y), roundf(cell), roundf(cell * 0.45))
			surface.draw_rect(rect, tone)
			surface.draw_rect(rect, edge, false, 1.0)

func _draw_water(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var near := _tone(profile, "near", 0.28)
	var mid := _tone(profile, "mid", 0.22)
	for i in range(22):
		var y := fposmod(float(i) * 19.0 + t * EnvironmentRules.parallax_speed(profile, band, "near"), 330.0) + 54.0
		var offset := float((i * 41) % 90)
		surface.draw_line(Vector2(24+offset,y),Vector2(104+offset,y),near,1.0)
		surface.draw_line(Vector2(330+offset*0.4,y+7),Vector2(430+offset*0.4,y+7),mid,1.0)

func _draw_cloud_top(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var tone := _tone(profile, "near", 0.26)
	for i in range(11):
		var x := float((i * 79 + 41) % 610) + 15.0
		var y := fposmod(float(i) * 49.0 + t * 14.0, 300.0) + 72.0
		var r := 13.0 + float(i % 4) * 4.0
		surface.draw_circle(Vector2(x,y),r,tone)
		surface.draw_circle(Vector2(x+r*0.8,y+3),r*0.72,tone)

func _draw_orbital(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var star := _tone(profile, "near", 0.65)
	for i in range(42):
		var x := float((i * 97 + 31) % 604) + 18.0
		var y := float((i * 53 + int(t * 2.0)) % 272) + 66
		surface.draw_rect(Rect2(roundf(x), roundf(y), 1, 1), star)
	var glow := EnvironmentRules.horizon_glow(band)
	if glow > 0.0:
		var atmosphere := Color("4f86aa"); atmosphere.a = 0.20 * glow
		surface.draw_arc(Vector2(320, 420), 270, PI, TAU, 64, atmosphere, 8.0)
		var station := _tone(profile, "mid", 0.34)
		var sx := 520.0 + sin(t * 0.08) * 22.0
		surface.draw_rect(Rect2(sx-28,118,56,6),station)
		surface.draw_rect(Rect2(sx-4,98,8,46),station)

func _draw_clouds(surface: CanvasItem, profile: Dictionary, band: String, t: float) -> void:
	var density := EnvironmentRules.cloud_density(band)
	if density <= 0.08: return
	var count := int(round(10.0 * density))
	var cloud := Color("d7dfe0"); cloud.a = 0.08 + density * 0.08
	for i in range(count):
		var x := float((i * 113 + 57) % 590) + 20.0
		var y := fposmod(float(i) * 67.0 + t * (8.0 + density * 18.0), 290.0) + 70.0
		var radius := 10.0 + float(i % 3) * 5.0
		surface.draw_circle(Vector2(x,y),radius,cloud)
		surface.draw_circle(Vector2(x+radius,y+2),radius*0.72,cloud)
