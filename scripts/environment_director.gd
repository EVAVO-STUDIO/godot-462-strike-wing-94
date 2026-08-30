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
	var state := _altitude_state()
	var band := str(state.get("current", "mid"))
	var t := float(scene.get("mission_time"))
	var motif := str(profile.get("motif", environment_id))
	_draw_parallax(surface, profile, state, t)

	# Orbital-profile missions can begin in atmosphere and cross the boundary visibly.
	var orbital_mix := _orbital_mix(state)
	if motif == "orbital" and orbital_mix < 0.98:
		_draw_cloud_top(surface, profile, state, t)
		_draw_high_atmosphere_horizon(surface, profile, _horizon_glow(state))
		if orbital_mix > 0.02:
			_draw_orbital(surface, profile, state, t, orbital_mix)
	else:
		match motif:
			"coast": _draw_coast(surface, profile, state, t)
			"industrial": _draw_industrial(surface, profile, state, t)
			"water": _draw_water(surface, profile, state, t)
			"cloud_top": _draw_cloud_top(surface, profile, state, t)
			"orbital": _draw_orbital(surface, profile, state, t, 1.0)
	_draw_clouds(surface, profile, state, t)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("current_environment") and names.has("mission_time")

func _altitude_state() -> Dictionary:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft == null:
		return {"current":"mid","from":"mid","to":"mid","ratio":1.0,"transition":false}
	var current := str(craft.call("current_altitude")) if craft.has_method("current_altitude") else "mid"
	if craft.has_method("altitude_transition_active") and bool(craft.call("altitude_transition_active")):
		return {
			"current": current,
			"from": str(craft.call("altitude_transition_from")),
			"to": str(craft.call("altitude_transition_to")),
			"ratio": float(craft.call("altitude_transition_ratio")),
			"transition": true
		}
	return {"current":current,"from":current,"to":current,"ratio":1.0,"transition":false}

func _tone(profile: Dictionary, key: String, alpha: float) -> Color:
	var color := Color(str(profile.get(key, "ffffff")))
	color.a = alpha
	return color

func _parallax_speed(profile: Dictionary, state: Dictionary, layer_name: String) -> float:
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_parallax_speed(
			profile,
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0)),
			layer_name
		)
	return EnvironmentRules.parallax_speed(profile, str(state.get("current", "mid")), layer_name)

func _ground_scale(state: Dictionary) -> float:
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_ground_detail_scale(
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0))
		)
	return EnvironmentRules.ground_detail_scale(str(state.get("current", "mid")))

func _draw_ground_detail(state: Dictionary) -> bool:
	if bool(state.get("transition", false)):
		return EnvironmentRules.should_draw_ground_detail_blended(
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0))
		)
	return EnvironmentRules.should_draw_ground_detail(str(state.get("current", "mid")))

func _cloud_density(state: Dictionary) -> float:
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_cloud_density(
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0))
		)
	return EnvironmentRules.cloud_density(str(state.get("current", "mid")))

func _horizon_glow(state: Dictionary) -> float:
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_horizon_glow(
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0))
		)
	return EnvironmentRules.horizon_glow(str(state.get("current", "mid")))

func _orbital_mix(state: Dictionary) -> float:
	var current := str(state.get("current", "mid"))
	if not bool(state.get("transition", false)):
		return 1.0 if current == "orbital" else 0.0
	var from_band := str(state.get("from", "mid"))
	var to_band := str(state.get("to", "mid"))
	var ratio := smoothstep(0.0, 1.0, clampf(float(state.get("ratio", 1.0)), 0.0, 1.0))
	if from_band == "orbital":
		return 1.0 - ratio
	if to_band == "orbital":
		return ratio
	return 0.0

func _draw_parallax(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var speeds := [
		_parallax_speed(profile, state, "far"),
		_parallax_speed(profile, state, "mid"),
		_parallax_speed(profile, state, "near")
	]
	var tones := [_tone(profile, "far", 0.18), _tone(profile, "mid", 0.20), _tone(profile, "near", 0.22)]
	var gaps := [47.0, 34.0, 25.0]
	for layer_index in range(3):
		for i in range(16):
			var y := fposmod(float(i) * gaps[layer_index] + t * speeds[layer_index], 340.0) + 54.0
			var x0 := 18.0 + float((i * (83 + layer_index * 19)) % 520)
			var length := 7.0 + float((i * 13 + layer_index * 7) % 28)
			surface.draw_line(Vector2(x0, y), Vector2(minf(622.0, x0 + length), y), tones[layer_index], 1.0)

func _coast_x(world_y: float, scale: float) -> float:
	return 148.0 * scale + sin(world_y * 0.018) * 35.0 * scale + sin(world_y * 0.047 + 1.3) * 13.0 * scale

func _draw_coast(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var scale := _ground_scale(state)
	if not _draw_ground_detail(state):
		return
	var scroll := t * _parallax_speed(profile, state, "mid")
	var land := _tone(profile, "land", 0.72)
	var inland := _tone(profile, "inland", 0.46)
	var sand := _tone(profile, "sand", 0.60)
	var foam := _tone(profile, "foam", 0.58)
	var road := _tone(profile, "road", 0.52)
	var coast_points := PackedVector2Array([Vector2(8, 60)])
	var shore_points: Array[Vector2] = []
	for y in range(60, 369, 8):
		var coast_x := _coast_x(float(y) - scroll, scale)
		shore_points.append(Vector2(coast_x, float(y)))
		coast_points.append(Vector2(coast_x, float(y)))
	coast_points.append(Vector2(8, 368))
	surface.draw_colored_polygon(coast_points, land)
	for index in range(shore_points.size() - 1):
		var a := shore_points[index]
		var b := shore_points[index + 1]
		surface.draw_line(a, b, sand, 5.0)
		surface.draw_line(a + Vector2(7, 0), b + Vector2(7, 0), foam, 1.0)
		surface.draw_line(a + Vector2(13, 0), b + Vector2(13, 0), Color(foam, foam.a * 0.48), 1.0)
	for y in range(66, 366, 24):
		var world_y := float(y) - scroll
		var edge := _coast_x(world_y, scale)
		surface.draw_line(Vector2(10, y), Vector2(maxf(12.0, edge - 31.0 * scale), y), inland, 1.0)
		var road_x := maxf(23.0, edge - 48.0 * scale)
		surface.draw_rect(Rect2(roundf(road_x), y, 2, 12), road)
	for landmark in range(3):
		var ly := fposmod(116.0 + landmark * 174.0 + scroll, 522.0) + 48.0
		var lx := _coast_x(ly - scroll, scale)
		if ly < 350.0:
			surface.draw_rect(Rect2(28, roundf(ly), maxf(34.0, lx - 74.0), 8), road)
			surface.draw_line(Vector2(34, ly + 4), Vector2(maxf(42.0, lx - 48.0), ly + 4), foam, 1.0)
			surface.draw_rect(Rect2(roundf(lx - 20.0), roundf(ly + 18.0), 42, 3), road)
			surface.draw_rect(Rect2(roundf(lx + 17.0), roundf(ly + 18.0), 3, 15), road)
	# Sandbars and wakes break up the open water without competing with bullets.
	for i in range(9):
		var sy := fposmod(float(i) * 61.0 + scroll * 1.18, 310.0) + 62.0
		var sx := 240.0 + float((i * 97) % 340)
		surface.draw_line(Vector2(sx, sy), Vector2(sx + 18.0 + float(i % 3) * 8.0, sy), Color(foam, foam.a * 0.42), 1.0)

func _draw_industrial(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var scale := _ground_scale(state)
	if not _draw_ground_detail(state):
		return
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

func _draw_water(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var near := _tone(profile, "near", 0.28)
	var mid := _tone(profile, "mid", 0.22)
	var speed := _parallax_speed(profile, state, "near")
	for i in range(22):
		var y := fposmod(float(i) * 19.0 + t * speed, 330.0) + 54.0
		var offset := float((i * 41) % 90)
		surface.draw_line(Vector2(24+offset,y),Vector2(104+offset,y),near,1.0)
		surface.draw_line(Vector2(330+offset*0.4,y+7),Vector2(430+offset*0.4,y+7),mid,1.0)

func _draw_cloud_top(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var tone := _tone(profile, "near", 0.26)
	var density := _cloud_density(state)
	var count := maxi(4, int(round(11.0 * maxf(0.32, density))))
	for i in range(count):
		var x := float((i * 79 + 41) % 610) + 15.0
		var y := fposmod(float(i) * 49.0 + t * 14.0, 300.0) + 72.0
		var r := 13.0 + float(i % 4) * 4.0
		surface.draw_circle(Vector2(x,y),r,tone)
		surface.draw_circle(Vector2(x+r*0.8,y+3),r*0.72,tone)

func _draw_high_atmosphere_horizon(surface: CanvasItem, profile: Dictionary, glow: float) -> void:
	var atmosphere := _tone(profile, "mid", 0.12 + 0.18 * glow)
	surface.draw_arc(Vector2(320, 438), 286, PI, TAU, 64, atmosphere, 7.0)
	var upper := Color("5d86a0")
	upper.a = 0.05 + 0.12 * glow
	surface.draw_arc(Vector2(320, 442), 294, PI, TAU, 64, upper, 2.0)

func _draw_orbital(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float, orbital_mix: float) -> void:
	var mix := clampf(orbital_mix, 0.0, 1.0)
	if mix <= 0.01:
		return
	var star := _tone(profile, "near", 0.65 * mix)
	for i in range(42):
		var x := float((i * 97 + 31) % 604) + 18.0
		var y := float((i * 53 + int(t * 2.0)) % 272) + 66
		surface.draw_rect(Rect2(roundf(x), roundf(y), 1, 1), star)
	var glow := _horizon_glow(state) * mix
	if glow > 0.0:
		var atmosphere := Color("4f86aa")
		atmosphere.a = 0.20 * glow
		surface.draw_arc(Vector2(320, 420), 270, PI, TAU, 64, atmosphere, 8.0)
		var station := _tone(profile, "mid", 0.34 * mix)
		var sx := 520.0 + sin(t * 0.08) * 22.0
		surface.draw_rect(Rect2(sx-28,118,56,6),station)
		surface.draw_rect(Rect2(sx-4,98,8,46),station)

func _draw_clouds(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var density := _cloud_density(state)
	if density <= 0.08:
		return
	var count := int(round(8.0 * density))
	var cloud := Color("d7dfe0")
	cloud.a = 0.07 + density * 0.07
	for i in range(count):
		var x := float((i * 113 + 57) % 590) + 20.0
		var y := fposmod(float(i) * 67.0 + t * (8.0 + density * 18.0), 290.0) + 70.0
		var width := 24.0 + float(i % 3) * 9.0
		var bank := PackedVector2Array([
			Vector2(x - width, y + 5), Vector2(x - width * 0.72, y - 3),
			Vector2(x - width * 0.28, y - 8), Vector2(x + width * 0.18, y - 5),
			Vector2(x + width * 0.63, y - 1), Vector2(x + width, y + 6),
			Vector2(x + width * 0.45, y + 9), Vector2(x - width * 0.5, y + 10)
		])
		surface.draw_colored_polygon(bank, cloud)
		surface.draw_line(Vector2(x - width * 0.75, y + 11), Vector2(x + width * 0.55, y + 11), Color(cloud, cloud.a * 0.55), 1.0)
