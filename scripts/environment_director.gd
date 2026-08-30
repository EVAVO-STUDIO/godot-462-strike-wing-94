extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EnvironmentRules = preload("res://scripts/environment_rules.gd")
const EnvironmentSurface = preload("res://scripts/environment_surface.gd")
const COASTAL_STRIKE_ZONE := preload("res://assets/runtime/environments/coast/coastal_strike_zone_loop_v1.png")
const REFINERY_NIGHT := preload("res://assets/runtime/environments/industrial/refinery_night_loop_v1.png")
const STORM_SEA := preload("res://assets/runtime/environments/water/storm_sea_loop_v1.png")
const DESERT_FRONT := preload("res://assets/runtime/environments/desert/desert_front_loop_v1.png")
const RIVER_CORRIDOR := preload("res://assets/runtime/environments/river/river_corridor_loop_v1.png")
const MOUNTAIN_RADAR := preload("res://assets/runtime/environments/mountain/mountain_radar_loop_v1.png")
const NIGHT_HARBOR := preload("res://assets/runtime/environments/harbor/night_harbor_loop_v1.png")
const STRATOSPHERIC_CLOUD_DECK := preload("res://assets/runtime/environments/high_atmosphere/stratospheric_cloud_deck_loop_v1.png")
const BLACK_SKY_STATION := preload("res://assets/runtime/environments/orbital/black_sky_station_loop_v1.png")
const CITY_OUTSKIRTS := preload("res://assets/runtime/environments/city/city_outskirts_loop_v1.png")
const MACHINE_FURNACE := preload("res://assets/runtime/environments/machine_furnace/machine_furnace_loop_v1.png")
const SEA_DEEP_TILE := preload("res://assets/runtime/environments/layers/sea_deep_tile.png")
const SEA_SURFACE_TILE := preload("res://assets/runtime/environments/layers/sea_surface_tile.png")
const COAST_SURFACE_TILE := preload("res://assets/runtime/environments/layers/coast_surface_tile.png")
const CLOUD_SHADOW_TILE := preload("res://assets/runtime/environments/layers/cloud_shadow_tile.png")
const CLOUD_MIST_TILE := preload("res://assets/runtime/environments/layers/cloud_mist_tile.png")
const REFINERY_DETAIL_TILE := preload("res://assets/runtime/environments/layers/refinery_detail_tile.png")
const DESERT_DUST_TILE := preload("res://assets/runtime/environments/layers/desert_dust_tile.png")
const RIVER_CURRENT_TILE := preload("res://assets/runtime/environments/layers/river_current_tile.png")
const MOUNTAIN_WEATHER_TILE := preload("res://assets/runtime/environments/layers/mountain_weather_tile.png")
const HARBOR_REFLECTION_TILE := preload("res://assets/runtime/environments/layers/harbor_reflection_tile.png")
const CITY_LIGHT_TILE := preload("res://assets/runtime/environments/layers/city_light_tile.png")
const FURNACE_ACTIVITY_TILE := preload("res://assets/runtime/environments/layers/furnace_activity_tile.png")
const ORBITAL_DEBRIS_TILE := preload("res://assets/runtime/environments/layers/orbital_debris_tile.png")
const ORBITAL_STARFIELD_TILE := preload("res://assets/runtime/environments/orbital/starfield_tile.png")
const HIGH_ATMOSPHERE_RIM := preload("res://assets/runtime/environments/orbital/high_atmosphere_rim.png")
const ORBITAL_RIM := preload("res://assets/runtime/environments/orbital/orbital_rim.png")
const PARALLAX_ACCENTS := [
	preload("res://assets/runtime/environments/motion/parallax_far.png"),
	preload("res://assets/runtime/environments/motion/parallax_mid.png"),
	preload("res://assets/runtime/environments/motion/parallax_near.png"),
]
const COAST_WAKE := preload("res://assets/runtime/environments/motion/coast_wake.png")
const RAIN_ACCENTS := [
	preload("res://assets/runtime/environments/motion/rain_a.png"),
	preload("res://assets/runtime/environments/motion/rain_b.png"),
]
const CLOUD_LOW := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_b.png"),
]
const CLOUD_MID := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_b.png"),
]
const CLOUD_HIGH := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_b.png"),
]
const LANDMARKS := {
	"coast": preload("res://assets/runtime/environments/landmarks/coastal_battery.png"),
	"industrial": preload("res://assets/runtime/environments/landmarks/refinery_stack.png"),
	"water": preload("res://assets/runtime/environments/landmarks/storm_platform.png"),
	"desert_front": preload("res://assets/runtime/environments/landmarks/desert_airstrip.png"),
	"river_corridor": preload("res://assets/runtime/environments/landmarks/river_bridge.png"),
	"mountain_radar": preload("res://assets/runtime/environments/landmarks/mountain_radar.png"),
	"night_harbor": preload("res://assets/runtime/environments/landmarks/harbor_cranes.png"),
	"city_outskirts": preload("res://assets/runtime/environments/landmarks/city_rail_hub.png"),
	"machine_furnace": preload("res://assets/runtime/environments/landmarks/machine_gantry.png"),
	"cloud_top": preload("res://assets/runtime/environments/landmarks/weather_relay.png"),
	"orbital": preload("res://assets/runtime/environments/landmarks/orbital_truss.png"),
}

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
	var variant := _mission_variant(scene)
	_draw_parallax(surface, profile, state, t)

	# Orbital-profile missions can begin in atmosphere and cross the boundary visibly.
	var orbital_mix := _orbital_mix(state)
	if motif == "orbital" and orbital_mix < 0.98:
		_draw_cloud_top(surface, profile, state, t)
		if orbital_mix > 0.02:
			_draw_orbital(surface, profile, state, t, orbital_mix)
	elif variant != "":
		match variant:
			"desert_front": _draw_desert_front(surface, state, t)
			"river_corridor": _draw_river_corridor(surface, state, t)
			"mountain_radar": _draw_mountain_radar(surface, state, t)
			"night_harbor": _draw_night_harbor(surface, state, t)
			"city_outskirts": _draw_city_outskirts(surface, state, t)
			"machine_furnace": _draw_machine_furnace(surface, state, t)
	else:
		match motif:
			"coast": _draw_coast(surface, profile, state, t)
			"industrial": _draw_industrial(surface, profile, state, t)
			"water": _draw_water(surface, profile, state, t)
			"cloud_top": _draw_cloud_top(surface, profile, state, t)
			"orbital": _draw_orbital(surface, profile, state, t, 1.0)
	_draw_landmarks(surface, scene, profile, state, t, variant if variant != "" else motif, orbital_mix)
	_draw_clouds(surface, profile, state, t)

func _draw_landmarks(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float, family: String, orbital_mix: float) -> void:
	if not LANDMARKS.has(family):
		return
	if family not in ["cloud_top", "orbital"] and not _draw_ground_detail(state):
		return
	var texture: Texture2D = LANDMARKS[family]
	var speed := _parallax_speed(profile, state, "mid") * (0.18 if family == "orbital" else 0.28)
	var mission_seed := _mission_seed(scene)
	var cycle := 880.0 + float(mission_seed % 5) * 47.0
	var y := fposmod(t * speed + float(mission_seed % 719), cycle) - 168.0 + 58.0
	if y > 360.0:
		return
	var scale := 0.78 + _ground_scale(state) * 0.34
	if family == "cloud_top":
		scale = 0.86
	elif family == "orbital":
		scale = 0.82 + 0.16 * clampf(orbital_mix, 0.0, 1.0)
	var size := texture.get_size() * scale
	var x_span := maxf(1.0, 640.0 - size.x - 48.0)
	var x := 24.0 + fposmod(float(mission_seed * 73), x_span)
	var alpha := 0.88 if family not in ["cloud_top", "orbital"] else 0.74
	if family == "orbital":
		alpha *= clampf(orbital_mix, 0.0, 1.0)
	surface.draw_texture_rect(texture, Rect2(Vector2(x, y), size), false, Color(0.86, 0.89, 0.88, alpha))

func _mission_seed(scene: Object) -> int:
	var missions = scene.get("mission_catalog") if _has_property(scene, "mission_catalog") else []
	if typeof(missions) != TYPE_ARRAY or missions.is_empty() or not _has_property(scene, "mission_index"):
		return 17
	var mission = missions[clampi(int(scene.get("mission_index")), 0, missions.size() - 1)]
	var mission_id := str(mission.get("id", "environment")) if typeof(mission) == TYPE_DICTIONARY else "environment"
	var seed := 0
	for index in range(mission_id.length()):
		seed = posmod(seed * 31 + mission_id.unicode_at(index), 104729)
	return seed

func _mission_variant(scene: Object) -> String:
	var missions = scene.get("mission_catalog") if _has_property(scene, "mission_catalog") else []
	if typeof(missions) != TYPE_ARRAY or missions.is_empty() or not _has_property(scene, "mission_index"):
		return ""
	var mission = missions[clampi(int(scene.get("mission_index")), 0, missions.size() - 1)]
	return str(mission.get("environment_variant", "")) if typeof(mission) == TYPE_DICTIONARY else ""

func _has_property(subject: Object, property_name: String) -> bool:
	for property in subject.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

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
	var forward_scale := 1.0
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("world_speed_multiplier"):
		forward_scale = float(craft.call("world_speed_multiplier"))
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_parallax_speed(
			profile,
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0)),
			layer_name
		) * forward_scale
	return EnvironmentRules.parallax_speed(profile, str(state.get("current", "mid")), layer_name) * forward_scale

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
			var accent: Texture2D = PARALLAX_ACCENTS[layer_index]
			surface.draw_texture_rect(accent, Rect2(Vector2(x0,y-4),Vector2(minf(length,622.0-x0),8)), false, tones[layer_index])

func _coast_x(world_y: float, scale: float) -> float:
	return 148.0 * scale + sin(world_y * 0.018) * 35.0 * scale + sin(world_y * 0.047 + 1.3) * 13.0 * scale

func _draw_coast(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state):
		return
	var scroll := fposmod(t * _parallax_speed(profile, state, "mid") * 0.32, 720.0)
	_draw_vertical_loop(surface, COASTAL_STRIKE_ZONE, scroll, Rect2(0, 58, 640, 302))
	var surface_scroll := fposmod(t * _parallax_speed(profile, state, "near") * 0.41, 512.0)
	_draw_vertical_loop(surface, COAST_SURFACE_TILE, surface_scroll, Rect2(300,58,340,302))
	# Restrained moving wakes prevent the authored plate from reading as a static
	# illustration while preserving projectile contrast over the open water.
	var foam := _tone(profile, "foam", 0.34)
	for i in range(7):
		var sy := fposmod(float(i) * 53.0 + t * 21.0, 310.0) + 58.0
		var sx := 382.0 + float((i * 73) % 190)
		var wake_width := 18.0 + float(i % 3) * 7.0
		surface.draw_texture_rect(COAST_WAKE, Rect2(Vector2(sx,sy-5),Vector2(wake_width,10)), false, foam)

func _draw_vertical_loop(surface: CanvasItem, texture: Texture2D, source_y: float, destination: Rect2, modulate := Color.WHITE) -> void:
	var remaining := destination.size.y
	var draw_y := destination.position.y
	var sample_y := fposmod(source_y, float(texture.get_height()))
	while remaining > 0.0:
		var segment := minf(remaining, float(texture.get_height()) - sample_y)
		surface.draw_texture_rect_region(
			texture,
			Rect2(destination.position.x, draw_y, destination.size.x, segment),
			Rect2(0, sample_y, float(texture.get_width()), segment),
			modulate
		)
		remaining -= segment
		draw_y += segment
		sample_y = 0.0

func _draw_industrial(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state):
		return
	var scroll := fposmod(t * _parallax_speed(profile, state, "mid") * 0.30, 720.0)
	_draw_vertical_loop(surface, REFINERY_NIGHT, scroll, Rect2(0, 58, 640, 302))
	var detail_scroll := fposmod(t * _parallax_speed(profile, state, "near") * 0.42, 512.0)
	var pulse := 0.70 + 0.18 * (0.5 + 0.5 * sin(t * 2.1))
	_draw_vertical_loop(surface, REFINERY_DETAIL_TILE, detail_scroll, Rect2(0,58,640,302), Color(1,1,1,pulse))

func _draw_water(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var speed := _parallax_speed(profile, state, "near")
	var deep_scroll := fposmod(t * speed * 0.17, 512.0)
	var surface_scroll := fposmod(t * speed * 0.33, 512.0)
	_draw_vertical_loop(surface, SEA_DEEP_TILE, deep_scroll, Rect2(0,58,640,302))
	_draw_vertical_loop(surface, SEA_SURFACE_TILE, surface_scroll, Rect2(0,58,640,302))
	surface.draw_rect(Rect2(0, 58, 640, 302), Color(0.01, 0.025, 0.045, 0.16))
	for i in range(14):
		var x := float((i * 109 + 31) % 690) - 20.0
		var y := fposmod(float(i) * 43.0 + t * (42.0 + float(i % 3) * 4.0), 340.0) + 48.0
		var rain_texture: Texture2D = RAIN_ACCENTS[i % RAIN_ACCENTS.size()]
		surface.draw_texture(rain_texture, Vector2(x-8,y), Color(1,1,1,0.30))

func _draw_desert_front(surface: CanvasItem, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := fposmod(t * 30.0, 720.0)
	_draw_vertical_loop(surface, DESERT_FRONT, scroll, Rect2(0, 58, 640, 302))
	surface.draw_rect(Rect2(0, 58, 640, 302), Color(0.075, 0.045, 0.025, 0.18))
	var dust_scroll := fposmod(t * 24.0, 512.0)
	_draw_vertical_loop(surface, DESERT_DUST_TILE, dust_scroll, Rect2(0,58,640,302), Color(1,1,1,0.82))

func _draw_river_corridor(surface: CanvasItem, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := fposmod(t * 27.0, 720.0)
	_draw_vertical_loop(surface, RIVER_CORRIDOR, scroll, Rect2(0, 58, 640, 302))
	surface.draw_rect(Rect2(0, 58, 640, 302), Color(0.015, 0.035, 0.032, 0.13))
	var current_scroll := fposmod(t * 19.0, 512.0)
	_draw_vertical_loop(surface, RIVER_CURRENT_TILE, current_scroll, Rect2(0,58,640,302), Color(1,1,1,0.86))

func _draw_mountain_radar(surface: CanvasItem, state: Dictionary, t: float) -> void:
	var scroll := fposmod(t * 15.0, 720.0)
	_draw_vertical_loop(surface, MOUNTAIN_RADAR, scroll, Rect2(0, 58, 640, 302))
	surface.draw_rect(Rect2(0, 58, 640, 302), Color(0.015, 0.025, 0.045, 0.14))
	var weather_scroll := fposmod(t * 27.0, 512.0)
	_draw_vertical_loop(surface, MOUNTAIN_WEATHER_TILE, weather_scroll, Rect2(0,58,640,302), Color(1,1,1,0.80))

func _draw_night_harbor(surface: CanvasItem, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := fposmod(t * 29.0, 720.0)
	_draw_vertical_loop(surface, NIGHT_HARBOR, scroll, Rect2(0, 58, 640, 302))
	surface.draw_rect(Rect2(0, 58, 640, 302), Color(0.008, 0.018, 0.032, 0.12))
	var reflection_scroll := fposmod(t * 22.0, 512.0)
	_draw_vertical_loop(surface, HARBOR_REFLECTION_TILE, reflection_scroll, Rect2(0,58,640,302), Color(1,1,1,0.88))

func _draw_city_outskirts(surface: CanvasItem, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := fposmod(t * 38.0, 720.0)
	_draw_vertical_loop(surface, CITY_OUTSKIRTS, scroll, Rect2(0, 58, 640, 302), Color(0.82, 0.84, 0.82, 0.92))
	var light_scroll := fposmod(t * 31.0, 512.0)
	var light_pulse := 0.74 + 0.16 * (0.5 + 0.5 * sin(t * 1.3))
	_draw_vertical_loop(surface, CITY_LIGHT_TILE, light_scroll, Rect2(0,58,640,302), Color(1,1,1,light_pulse))

func _draw_machine_furnace(surface: CanvasItem, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := fposmod(t * 34.0, 720.0)
	_draw_vertical_loop(surface, MACHINE_FURNACE, scroll, Rect2(0, 58, 640, 302), Color(0.80, 0.80, 0.78, 0.94))
	var activity_scroll := fposmod(t * 28.0, 512.0)
	var activity_pulse := 0.68 + 0.22 * (0.5 + 0.5 * sin(t * 1.7))
	_draw_vertical_loop(surface, FURNACE_ACTIVITY_TILE, activity_scroll, Rect2(0,58,640,302), Color(1,1,1,activity_pulse))

func _draw_cloud_top(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var density := _cloud_density(state)
	var scroll := fposmod(t * 14.0, 720.0)
	_draw_vertical_loop(surface, STRATOSPHERIC_CLOUD_DECK, scroll, Rect2(0, 58, 640, 302), Color(0.78, 0.86, 0.91, 0.66))
	_draw_high_atmosphere_horizon(surface, profile, _horizon_glow(state))
	# Sparse moving banks preserve depth without hiding the authored cloud-deck structure.
	var count := maxi(4, int(round(8.0 * maxf(0.42, density))))
	for i in range(count):
		var texture: Texture2D = CLOUD_HIGH[i % CLOUD_HIGH.size()]
		var x := float((i * 137 + 43) % 720) - 40.0
		var y := fposmod(float(i) * 71.0 + t * 14.0, 380.0) + 48.0
		var scale := 0.72 + float(i % 3) * 0.13
		var size := Vector2(texture.get_size()) * scale
		surface.draw_texture_rect(texture, Rect2(Vector2(x, y) - size * 0.5, size), false, Color(0.82, 0.87, 0.90, 0.24 + density * 0.22))

func _draw_high_atmosphere_horizon(surface: CanvasItem, _profile: Dictionary, glow: float) -> void:
	surface.draw_texture(HIGH_ATMOSPHERE_RIM, Vector2(0,152), Color(1,1,1,0.26 + 0.74 * glow))

func _draw_orbital(surface: CanvasItem, _profile: Dictionary, state: Dictionary, t: float, orbital_mix: float) -> void:
	var mix := clampf(orbital_mix, 0.0, 1.0)
	if mix <= 0.01:
		return
	var scroll := fposmod(t * 8.0, 720.0)
	_draw_vertical_loop(surface, BLACK_SKY_STATION, scroll, Rect2(0, 58, 640, 302), Color(0.76, 0.82, 0.88, 0.88 * mix))
	var debris_scroll := fposmod(t * 15.0, 512.0)
	_draw_vertical_loop(surface, ORBITAL_DEBRIS_TILE, debris_scroll, Rect2(0,58,640,302), Color(1,1,1,0.78*mix))
	# The authored sparse tile drifts independently without becoming star wallpaper.
	var star_scroll := fposmod(t * 2.0, 512.0)
	_draw_vertical_loop(surface, ORBITAL_STARFIELD_TILE, star_scroll, Rect2(0,58,640,302), Color(1,1,1,0.82*mix))
	var glow := _horizon_glow(state) * mix
	if glow > 0.0:
		surface.draw_texture(ORBITAL_RIM, Vector2(0,150), Color(1,1,1,glow))

func _draw_clouds(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var density := _cloud_density(state)
	if density <= 0.08:
		return
	var band := str(state.get("current", "mid"))
	var family: Array = CLOUD_LOW if band == "low" else (CLOUD_HIGH if band in ["high", "orbital"] else CLOUD_MID)
	var count := maxi(2, int(round(6.0 * density)))
	var alpha := 0.12 + density * 0.18
	if band == "low": alpha *= 0.72
	if band == "high": alpha *= 1.18
	if density >= 0.22:
		var shadow_scroll := fposmod(t * (7.0 + density * 8.0), 512.0)
		_draw_vertical_loop(surface,CLOUD_SHADOW_TILE,shadow_scroll,Rect2(0,58,640,302),Color(1,1,1,clampf(density*0.52,0.0,0.58)))
	for i in range(count):
		var texture: Texture2D = family[i % family.size()]
		var x := float((i * 149 + 61) % 760) - 60.0
		var speed := 10.0 + density * 20.0 + float(i % 3) * 2.0
		var y := fposmod(float(i) * 97.0 + t * speed, 410.0) + 30.0
		var scale := 0.72 + float((i * 5) % 4) * 0.12
		var size := Vector2(texture.get_size()) * scale
		surface.draw_texture_rect(texture, Rect2(Vector2(x, y) - size * 0.5, size), false, Color(0.78, 0.84, 0.88, alpha))
	if density >= 0.32:
		var mist_scroll := fposmod(t * (18.0 + density * 14.0), 512.0)
		_draw_vertical_loop(surface,CLOUD_MIST_TILE,mist_scroll,Rect2(0,58,640,302),Color(1,1,1,clampf(density*0.34,0.0,0.42)))
