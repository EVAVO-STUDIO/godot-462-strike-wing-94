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
	var gaps := [44.0, 32.0, 22.0]
	for layer_index in range(3):
		for i in range(18):
			var y := fposmod(float(i) * gaps[layer_index] + t * speeds[layer_index], 340.0) + 54.0
			var x0 := 24.0 + float((i * (37 + layer_index * 11)) % 120)
			surface.draw_line(Vector2(x0, y), Vector2(620.0 - x0 * 0.25, y), tones[layer_index], 1.0)

func _draw_coast(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var scale := _ground_scale(state)
	if not _draw_ground_detail(state):
		return
	var land := _tone(profile, "near", 0.26)
	var shore := _tone(profile, "mid", 0.32)
	var width := 105.0 * scale
	for i in range(7):
		var y := fposmod(float(i) * 76.0 + t * 26.0, 330.0) + 54.0
		var left := 18.0 + sin(float(i) * 1.7) * 18.0
		surface.draw_colored_polygon(PackedVector2Array([Vector2(left,y-20),Vector2(left+width,y-14),Vector2(left+width+20,y+12),Vector2(left,y+20)]), land)
		surface.draw_line(Vector2(left+width,y-16),Vector2(left+width+20,y+14),shore,2.0)

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
	var count := int(round(10.0 * density))
	var cloud := Color("d7dfe0")
	cloud.a = 0.08 + density * 0.08
	for i in range(count):
		var x := float((i * 113 + 57) % 590) + 20.0
		var y := fposmod(float(i) * 67.0 + t * (8.0 + density * 18.0), 290.0) + 70.0
		var radius := 10.0 + float(i % 3) * 5.0
		surface.draw_circle(Vector2(x,y),radius,cloud)
		surface.draw_circle(Vector2(x+radius,y+2),radius*0.72,cloud)
