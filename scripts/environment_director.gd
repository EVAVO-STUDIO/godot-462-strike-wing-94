extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EnvironmentRules = preload("res://scripts/environment_rules.gd")
const EnvironmentSurface = preload("res://scripts/environment_surface.gd")
const COAST_GEOGRAPHY_CHUNKS := [
	preload("res://assets/runtime/environments/coast_chunks/seawall_run.png"),
	preload("res://assets/runtime/environments/coast_chunks/defended_inlet.png"),
	preload("res://assets/runtime/environments/coast_chunks/reef_cliffs.png"),
]
const REFINERY_GEOGRAPHY_CHUNKS := [
	preload("res://assets/runtime/environments/refinery_chunks/tank_farm.png"),
	preload("res://assets/runtime/environments/refinery_chunks/cracking_corridor.png"),
	preload("res://assets/runtime/environments/refinery_chunks/rail_loading.png"),
]
const DESERT_GEOGRAPHY_CHUNKS := [
	preload("res://assets/runtime/environments/desert_chunks/armour_approach.png"),
	preload("res://assets/runtime/environments/desert_chunks/wadi_crossing.png"),
	preload("res://assets/runtime/environments/desert_chunks/logistics_belt.png"),
]
const RIVER_GEOGRAPHY_CHUNKS := [
	preload("res://assets/runtime/environments/river_chunks/floodplain.png"),
	preload("res://assets/runtime/environments/river_chunks/defended_crossing.png"),
	preload("res://assets/runtime/environments/river_chunks/industrial_bend.png"),
]
const MOUNTAIN_RADAR := preload("res://assets/runtime/environments/mountain/mountain_radar_loop_v1.png")
const HARBOR_GEOGRAPHY_CHUNKS := [
	preload("res://assets/runtime/environments/harbor_chunks/outer_breakwater.png"),
	preload("res://assets/runtime/environments/harbor_chunks/repair_basin.png"),
	preload("res://assets/runtime/environments/harbor_chunks/command_docks.png"),
]
const STRATOSPHERIC_CLOUD_DECK := preload("res://assets/runtime/environments/high_atmosphere/stratospheric_cloud_deck_loop_v1.png")
const BLACK_SKY_STATION := preload("res://assets/runtime/environments/orbital/black_sky_station_loop_v1.png")
const CITY_GEOGRAPHY_CHUNKS := [
	preload("res://assets/runtime/environments/city_chunks/freight_belt.png"),
	preload("res://assets/runtime/environments/city_chunks/flooded_underpass.png"),
	preload("res://assets/runtime/environments/city_chunks/machine_foundations.png"),
]
const MACHINE_FURNACE := preload("res://assets/runtime/environments/machine_furnace/machine_furnace_loop_v1.png")
const SEA_DEEP_ANIMATION := [
	preload("res://assets/runtime/environments/open_water_animation/deep_0.png"), preload("res://assets/runtime/environments/open_water_animation/deep_1.png"),
	preload("res://assets/runtime/environments/open_water_animation/deep_2.png"), preload("res://assets/runtime/environments/open_water_animation/deep_3.png"),
]
const SEA_SURFACE_ANIMATION := [
	preload("res://assets/runtime/environments/open_water_animation/surface_0.png"), preload("res://assets/runtime/environments/open_water_animation/surface_1.png"),
	preload("res://assets/runtime/environments/open_water_animation/surface_2.png"), preload("res://assets/runtime/environments/open_water_animation/surface_3.png"),
]
const SEA_FOAM_ANIMATION := [
	preload("res://assets/runtime/environments/open_water_animation/foam_0.png"), preload("res://assets/runtime/environments/open_water_animation/foam_1.png"),
	preload("res://assets/runtime/environments/open_water_animation/foam_2.png"), preload("res://assets/runtime/environments/open_water_animation/foam_3.png"),
	preload("res://assets/runtime/environments/open_water_animation/foam_4.png"), preload("res://assets/runtime/environments/open_water_animation/foam_5.png"),
]
const OPEN_WATER_FINITE := [
	preload("res://assets/runtime/environments/open_water_finite/nav_buoy_yellow.png"),
	preload("res://assets/runtime/environments/open_water_finite/nav_buoy_red.png"),
	preload("res://assets/runtime/environments/open_water_finite/sensor_buoy.png"),
	preload("res://assets/runtime/environments/open_water_finite/container_debris.png"),
	preload("res://assets/runtime/environments/open_water_finite/fuel_slick.png"),
	preload("res://assets/runtime/environments/open_water_finite/convoy_wake_narrow.png"),
	preload("res://assets/runtime/environments/open_water_finite/convoy_wake_wide.png"),
	preload("res://assets/runtime/environments/open_water_finite/platform_wake.png"),
	preload("res://assets/runtime/environments/open_water_finite/current_scar_a.png"),
	preload("res://assets/runtime/environments/open_water_finite/current_scar_b.png"),
	preload("res://assets/runtime/environments/open_water_finite/weather_raft.png"),
	preload("res://assets/runtime/environments/open_water_finite/mooring_field.png"),
]
const COAST_SURFACE_TILE := preload("res://assets/runtime/environments/layers/coast_surface_tile.png")
const CLOUD_SHADOW_TILE := preload("res://assets/runtime/environments/layers/cloud_shadow_tile.png")
const CLOUD_MIST_TILE := preload("res://assets/runtime/environments/layers/cloud_mist_tile.png")
const REFINERY_DETAIL_TILE := preload("res://assets/runtime/environments/layers/refinery_detail_tile.png")
const REFINERY_FINITE_CHUNKS := [
	preload("res://assets/runtime/environments/modular_refinery/cracking_tower_a.png"),
	preload("res://assets/runtime/environments/modular_refinery/cracking_tower_b.png"),
	preload("res://assets/runtime/environments/modular_refinery/pipe_rack_long.png"),
	preload("res://assets/runtime/environments/modular_refinery/pipe_rack_short.png"),
	preload("res://assets/runtime/environments/modular_refinery/hazard_lamps.png"),
	preload("res://assets/runtime/environments/modular_refinery/oil_stains.png"),
]
const REFINERY_STEAM := [
	preload("res://assets/runtime/environments/modular_refinery/steam_0.png"), preload("res://assets/runtime/environments/modular_refinery/steam_1.png"),
	preload("res://assets/runtime/environments/modular_refinery/steam_2.png"), preload("res://assets/runtime/environments/modular_refinery/steam_3.png"),
	preload("res://assets/runtime/environments/modular_refinery/steam_4.png"), preload("res://assets/runtime/environments/modular_refinery/steam_5.png"),
]
const REFINERY_FLARE := [
	preload("res://assets/runtime/environments/modular_refinery/flare_0.png"), preload("res://assets/runtime/environments/modular_refinery/flare_1.png"),
	preload("res://assets/runtime/environments/modular_refinery/flare_2.png"), preload("res://assets/runtime/environments/modular_refinery/flare_3.png"),
	preload("res://assets/runtime/environments/modular_refinery/flare_4.png"),
]
const REFINERY_SMOKE := [
	preload("res://assets/runtime/environments/modular_refinery/smoke_0.png"), preload("res://assets/runtime/environments/modular_refinery/smoke_1.png"),
	preload("res://assets/runtime/environments/modular_refinery/smoke_2.png"), preload("res://assets/runtime/environments/modular_refinery/smoke_3.png"),
	preload("res://assets/runtime/environments/modular_refinery/smoke_4.png"),
]
const DESERT_DUST_GUST := [
	preload("res://assets/runtime/environments/desert_dust_animation/gust_0.png"), preload("res://assets/runtime/environments/desert_dust_animation/gust_1.png"),
	preload("res://assets/runtime/environments/desert_dust_animation/gust_2.png"), preload("res://assets/runtime/environments/desert_dust_animation/gust_3.png"),
	preload("res://assets/runtime/environments/desert_dust_animation/gust_4.png"), preload("res://assets/runtime/environments/desert_dust_animation/gust_5.png"),
]
const RIVER_CURRENT_ANIMATION := [
	preload("res://assets/runtime/environments/river_current_animation/current_0.png"), preload("res://assets/runtime/environments/river_current_animation/current_1.png"),
	preload("res://assets/runtime/environments/river_current_animation/current_2.png"), preload("res://assets/runtime/environments/river_current_animation/current_3.png"),
	preload("res://assets/runtime/environments/river_current_animation/current_4.png"), preload("res://assets/runtime/environments/river_current_animation/current_5.png"),
]
const MOUNTAIN_WEATHER_TILE := preload("res://assets/runtime/environments/layers/mountain_weather_tile.png")
const HARBOR_REFLECTION_ANIMATION := [
	preload("res://assets/runtime/environments/harbor_reflection_animation/reflection_0.png"), preload("res://assets/runtime/environments/harbor_reflection_animation/reflection_1.png"),
	preload("res://assets/runtime/environments/harbor_reflection_animation/reflection_2.png"), preload("res://assets/runtime/environments/harbor_reflection_animation/reflection_3.png"),
	preload("res://assets/runtime/environments/harbor_reflection_animation/reflection_4.png"), preload("res://assets/runtime/environments/harbor_reflection_animation/reflection_5.png"),
]
const CITY_ACTIVITY_ANIMATION := [
	preload("res://assets/runtime/environments/city_activity_animation/activity_0.png"), preload("res://assets/runtime/environments/city_activity_animation/activity_1.png"),
	preload("res://assets/runtime/environments/city_activity_animation/activity_2.png"), preload("res://assets/runtime/environments/city_activity_animation/activity_3.png"),
	preload("res://assets/runtime/environments/city_activity_animation/activity_4.png"), preload("res://assets/runtime/environments/city_activity_animation/activity_5.png"),
]
const FURNACE_ACTIVITY_TILE := preload("res://assets/runtime/environments/layers/furnace_activity_tile.png")
const ORBITAL_DEBRIS_TILE := preload("res://assets/runtime/environments/layers/orbital_debris_tile.png")
const ORBITAL_STARFIELD_TILE := preload("res://assets/runtime/environments/orbital/starfield_tile.png")
const HIGH_ATMOSPHERE_RIM := preload("res://assets/runtime/environments/orbital/high_atmosphere_rim.png")
const ORBITAL_RIM := preload("res://assets/runtime/environments/orbital/orbital_rim.png")
const ENVIRONMENT_VIEW := Rect2(0, 36, 640, 324)
const PARALLAX_ACCENTS := [
	preload("res://assets/runtime/environments/motion/parallax_far.png"),
	preload("res://assets/runtime/environments/motion/parallax_mid.png"),
	preload("res://assets/runtime/environments/motion/parallax_near.png"),
]
const COAST_WAKE := preload("res://assets/runtime/environments/motion/coast_wake.png")
const COAST_SHORE_WASH := [
	preload("res://assets/runtime/environments/modular_coast/shore_wash_0.png"),
	preload("res://assets/runtime/environments/modular_coast/shore_wash_1.png"),
	preload("res://assets/runtime/environments/modular_coast/shore_wash_2.png"),
	preload("res://assets/runtime/environments/modular_coast/shore_wash_1.png"),
]
const COAST_BREAKWATER_IMPACT := [
	preload("res://assets/runtime/environments/modular_coast/breakwater_impact_0.png"),
	preload("res://assets/runtime/environments/modular_coast/breakwater_impact_1.png"),
	preload("res://assets/runtime/environments/modular_coast/breakwater_impact_2.png"),
	preload("res://assets/runtime/environments/modular_coast/breakwater_impact_3.png"),
	preload("res://assets/runtime/environments/modular_coast/breakwater_impact_2.png"),
	preload("res://assets/runtime/environments/modular_coast/breakwater_impact_1.png"),
]
const COAST_FINITE_CHUNKS := [
	preload("res://assets/runtime/environments/modular_coast/breakwater_straight.png"),
	preload("res://assets/runtime/environments/modular_coast/seawall_access.png"),
	preload("res://assets/runtime/environments/modular_coast/radar_bunker.png"),
	preload("res://assets/runtime/environments/modular_coast/weapon_revetment.png"),
	preload("res://assets/runtime/environments/modular_coast/tetrapod_cluster.png"),
	preload("res://assets/runtime/environments/modular_coast/utility_bunker.png"),
]
const RAIN_ACCENTS := [
	preload("res://assets/runtime/environments/motion/rain_a.png"),
	preload("res://assets/runtime/environments/motion/rain_b.png"),
]
const CLOUD_LOW := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_b.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_c.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_d.png"),
]
const CLOUD_MID := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_b.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_c.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_d.png"),
]
const CLOUD_HIGH := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_b.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_c.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_d.png"),
]
const CIRRUS_FAR := [
	preload("res://assets/runtime/environments/high_atmosphere_motion/cirrus_a.png"),
	preload("res://assets/runtime/environments/high_atmosphere_motion/cirrus_b.png"),
]
const CONTRAIL_NEAR := [
	preload("res://assets/runtime/environments/high_atmosphere_motion/contrail_long.png"),
	preload("res://assets/runtime/environments/high_atmosphere_motion/contrail_short.png"),
	preload("res://assets/runtime/environments/high_atmosphere_motion/contrail_broken.png"),
]
const ANVIL_SHADOW := preload("res://assets/runtime/environments/high_atmosphere_motion/anvil_shadow.png")
const LANDMARKS := {
	"coast": preload("res://assets/runtime/environments/landmarks/coastal_battery.png"),
	"industrial": preload("res://assets/runtime/environments/landmarks/refinery_stack.png"),
	"water": preload("res://assets/runtime/environments/landmarks/storm_platform_v2.png"),
	"desert_front": preload("res://assets/runtime/environments/landmarks/desert_airstrip.png"),
	"river_corridor": preload("res://assets/runtime/environments/landmarks/river_bridge.png"),
	"mountain_radar": preload("res://assets/runtime/environments/landmarks/mountain_radar.png"),
	"night_harbor": preload("res://assets/runtime/environments/landmarks/harbor_cranes.png"),
	"city_outskirts": preload("res://assets/runtime/environments/landmarks/city_rail_hub.png"),
	"machine_furnace": preload("res://assets/runtime/environments/landmarks/machine_gantry.png"),
	"cloud_top": preload("res://assets/runtime/environments/landmarks/weather_relay.png"),
	"orbital": preload("res://assets/runtime/environments/landmarks/orbital_truss.png"),
}
const LANDMARK_FX_FRAMES := {
	"coast": [preload("res://assets/runtime/environments/landmark_animation/coast_0.png"), preload("res://assets/runtime/environments/landmark_animation/coast_1.png"), preload("res://assets/runtime/environments/landmark_animation/coast_2.png"), preload("res://assets/runtime/environments/landmark_animation/coast_3.png")],
	"industrial": [preload("res://assets/runtime/environments/landmark_animation/industrial_0.png"), preload("res://assets/runtime/environments/landmark_animation/industrial_1.png"), preload("res://assets/runtime/environments/landmark_animation/industrial_2.png"), preload("res://assets/runtime/environments/landmark_animation/industrial_3.png")],
	"water": [preload("res://assets/runtime/environments/landmark_animation/water_0.png"), preload("res://assets/runtime/environments/landmark_animation/water_1.png"), preload("res://assets/runtime/environments/landmark_animation/water_2.png"), preload("res://assets/runtime/environments/landmark_animation/water_3.png")],
	"desert_front": [preload("res://assets/runtime/environments/landmark_animation/desert_front_0.png"), preload("res://assets/runtime/environments/landmark_animation/desert_front_1.png"), preload("res://assets/runtime/environments/landmark_animation/desert_front_2.png"), preload("res://assets/runtime/environments/landmark_animation/desert_front_3.png")],
	"river_corridor": [preload("res://assets/runtime/environments/landmark_animation/river_corridor_0.png"), preload("res://assets/runtime/environments/landmark_animation/river_corridor_1.png"), preload("res://assets/runtime/environments/landmark_animation/river_corridor_2.png"), preload("res://assets/runtime/environments/landmark_animation/river_corridor_3.png")],
	"mountain_radar": [preload("res://assets/runtime/environments/landmark_animation/mountain_radar_0.png"), preload("res://assets/runtime/environments/landmark_animation/mountain_radar_1.png"), preload("res://assets/runtime/environments/landmark_animation/mountain_radar_2.png"), preload("res://assets/runtime/environments/landmark_animation/mountain_radar_3.png")],
	"night_harbor": [preload("res://assets/runtime/environments/landmark_animation/night_harbor_0.png"), preload("res://assets/runtime/environments/landmark_animation/night_harbor_1.png"), preload("res://assets/runtime/environments/landmark_animation/night_harbor_2.png"), preload("res://assets/runtime/environments/landmark_animation/night_harbor_3.png")],
	"city_outskirts": [preload("res://assets/runtime/environments/landmark_animation/city_outskirts_0.png"), preload("res://assets/runtime/environments/landmark_animation/city_outskirts_1.png"), preload("res://assets/runtime/environments/landmark_animation/city_outskirts_2.png"), preload("res://assets/runtime/environments/landmark_animation/city_outskirts_3.png")],
	"machine_furnace": [preload("res://assets/runtime/environments/landmark_animation/machine_furnace_0.png"), preload("res://assets/runtime/environments/landmark_animation/machine_furnace_1.png"), preload("res://assets/runtime/environments/landmark_animation/machine_furnace_2.png"), preload("res://assets/runtime/environments/landmark_animation/machine_furnace_3.png")],
	"cloud_top": [preload("res://assets/runtime/environments/landmark_animation/cloud_top_0.png"), preload("res://assets/runtime/environments/landmark_animation/cloud_top_1.png"), preload("res://assets/runtime/environments/landmark_animation/cloud_top_2.png"), preload("res://assets/runtime/environments/landmark_animation/cloud_top_3.png")],
	"orbital": [preload("res://assets/runtime/environments/landmark_animation/orbital_0.png"), preload("res://assets/runtime/environments/landmark_animation/orbital_1.png"), preload("res://assets/runtime/environments/landmark_animation/orbital_2.png"), preload("res://assets/runtime/environments/landmark_animation/orbital_3.png")],
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
			"desert_front": _draw_desert_front(surface, scene, state, t)
			"river_corridor": _draw_river_corridor(surface, scene, state, t)
			"mountain_radar": _draw_mountain_radar(surface, state, t)
			"night_harbor": _draw_night_harbor(surface, scene, state, t)
			"city_outskirts": _draw_city_outskirts(surface, scene, state, t)
			"machine_furnace": _draw_machine_furnace(surface, state, t)
	else:
		match motif:
			"coast": _draw_coast(surface, scene, profile, state, t)
			"industrial": _draw_industrial(surface, scene, profile, state, t)
			"water": _draw_water(surface, scene, profile, state, t)
			"cloud_top": _draw_cloud_top(surface, profile, state, t)
			"orbital": _draw_orbital(surface, profile, state, t, 1.0)
	_draw_high_atmosphere_far(surface, state, t)
	_draw_landmarks(surface, scene, profile, state, t, variant if variant != "" else motif, orbital_mix)
	_draw_clouds(surface, profile, state, t)
	_draw_high_atmosphere_near(surface, state, t)

func _draw_landmarks(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float, family: String, orbital_mix: float) -> void:
	if not LANDMARKS.has(family):
		return
	# These restored masters already contain their mission-scale radar, bridge,
	# rail and coastal structures. Stacking the older simplified landmark cards
	# over them duplicates the same subject and reads as a prototype overlay.
	if family in ["coast", "industrial", "mountain_radar"]:
		return
	if family not in ["cloud_top", "orbital"] and not _draw_ground_detail(state):
		return
	var texture: Texture2D = LANDMARKS[family]
	if family == "river_corridor":
		_draw_registered_river_bridge(surface, scene, state, t, texture)
		return
	if family == "night_harbor":
		_draw_registered_harbor_crane(surface, scene, state, t, texture)
		return
	if family == "city_outskirts":
		_draw_registered_city_rail_hub(surface, scene, state, t, texture)
		return
	var speed := _parallax_speed(profile, state, "mid") * (0.18 if family == "orbital" else 0.28)
	var mission_seed := _mission_seed(scene)
	var cycle := 880.0 + float(mission_seed % 5) * 47.0
	var y := fposmod(t * speed + float(mission_seed % 719), cycle) - 168.0 + ENVIRONMENT_VIEW.position.y
	if y > 360.0:
		return
	var scale := 0.78 + _ground_scale(state) * 0.34
	if family == "cloud_top":
		scale = 0.86
	elif family == "orbital":
		scale = 0.82 + 0.16 * clampf(orbital_mix, 0.0, 1.0)
	elif family == "water":
		scale = 0.62
	var size := texture.get_size() * scale
	var x_span := maxf(1.0, 640.0 - size.x - 48.0)
	var x := 24.0 + fposmod(float(mission_seed * 73), x_span)
	var alpha := 0.88 if family not in ["cloud_top", "orbital"] else 0.74
	if family == "orbital":
		alpha *= clampf(orbital_mix, 0.0, 1.0)
	surface.draw_texture_rect(texture, Rect2(Vector2(x, y), size), false, Color(0.86, 0.89, 0.88, alpha))
	if LANDMARK_FX_FRAMES.has(family):
		var fx_frames: Array = LANDMARK_FX_FRAMES[family]
		var fx: Texture2D = fx_frames[posmod(int(floor(t * 4.0)), fx_frames.size())]
		surface.draw_texture_rect(fx, Rect2(Vector2(x, y), size), false, Color(1.0, 1.0, 1.0, alpha))

func _draw_registered_river_bridge(surface: CanvasItem, scene: Object, state: Dictionary, t: float, texture: Texture2D) -> void:
	# The complete span belongs over the matching abutments in the defended-
	# crossing chunk. Keeping the sprite separate still permits destruction and
	# animation, while this shared world coordinate prevents seeded dry-land drops.
	var scroll := t * 27.0 * _world_speed_multiplier() + float(_mission_seed(scene) % 3) * 1024.0
	var scale := 0.78 + _ground_scale(state) * 0.34
	var size := texture.get_size() * scale
	var crossing_world_y := 1594.0
	var center_y := fposmod(crossing_world_y + scroll, 3072.0) + ENVIRONMENT_VIEW.position.y
	var y := center_y - size.y * 0.5
	if y + size.y < ENVIRONMENT_VIEW.position.y or y > ENVIRONMENT_VIEW.end.y:
		return
	var x := 320.0 - size.x * 0.5
	var rect := Rect2(Vector2(x, y).round(), size.round())
	_draw_texture_rect_clipped(surface, texture, rect, ENVIRONMENT_VIEW, Color(0.86, 0.89, 0.88, 0.92))
	if LANDMARK_FX_FRAMES.has("river_corridor"):
		var fx_frames: Array = LANDMARK_FX_FRAMES["river_corridor"]
		var fx: Texture2D = fx_frames[posmod(int(floor(t * 4.0)), fx_frames.size())]
		_draw_texture_rect_clipped(surface, fx, rect, ENVIRONMENT_VIEW, Color(1.0, 1.0, 1.0, 0.92))

func _draw_registered_harbor_crane(surface: CanvasItem, scene: Object, state: Dictionary, t: float, texture: Texture2D) -> void:
	# The crane base stays on the repair-basin quay while its boom reaches over the
	# authored water channel. It remains a separate target/event layer rather than
	# being baked into repeating geography or dropped at a random seeded X.
	var scroll := t * 29.0 * _world_speed_multiplier() + float(_mission_seed(scene) % 3) * 1024.0
	var scale := 0.78 + _ground_scale(state) * 0.34
	var size := texture.get_size() * scale
	var crane_world_y := 1500.0
	var center_y := fposmod(crane_world_y + scroll, 3072.0) + ENVIRONMENT_VIEW.position.y
	var y := center_y - size.y * 0.5
	if y + size.y < ENVIRONMENT_VIEW.position.y or y > ENVIRONMENT_VIEW.end.y:
		return
	var rect := Rect2(Vector2(118.0, y).round(), size.round())
	_draw_texture_rect_clipped(surface, texture, rect, ENVIRONMENT_VIEW, Color(0.82, 0.86, 0.86, 0.94))

func _draw_registered_city_rail_hub(surface: CanvasItem, scene: Object, state: Dictionary, t: float, texture: Texture2D) -> void:
	# This complete switching hub occupies one authored freight-belt coordinate.
	# It remains separable for destruction and never repeats at screen height.
	var scroll := t * 38.0 * _world_speed_multiplier() + float(_mission_seed(scene) % 3) * 1024.0
	var scale := 0.78 + _ground_scale(state) * 0.34
	var size := texture.get_size() * scale
	var hub_world_y := 540.0
	var center_y := fposmod(hub_world_y + scroll, 3072.0) + ENVIRONMENT_VIEW.position.y
	var y := center_y - size.y * 0.5
	if y + size.y < ENVIRONMENT_VIEW.position.y or y > ENVIRONMENT_VIEW.end.y:
		return
	var rect := Rect2(Vector2(320.0 - size.x * 0.5, y).round(), size.round())
	_draw_texture_rect_clipped(surface, texture, rect, ENVIRONMENT_VIEW, Color(0.84, 0.87, 0.86, 0.96))

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
	return SceneContractCache.has_property(subject, property_name)

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "current_environment", "mission_time"])

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
	var forward_scale := _world_speed_multiplier()
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_parallax_speed(
			profile,
			str(state.get("from", "mid")),
			str(state.get("to", "mid")),
			float(state.get("ratio", 1.0)),
			layer_name
		) * forward_scale
	return EnvironmentRules.parallax_speed(profile, str(state.get("current", "mid")), layer_name) * forward_scale

func _world_speed_multiplier() -> float:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("world_speed_multiplier"):
		return maxf(0.0, float(craft.call("world_speed_multiplier")))
	return 1.0

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

func _high_atmosphere_mix(state: Dictionary) -> float:
	if bool(state.get("transition", false)):
		return EnvironmentRules.blended_high_atmosphere_mix(str(state.get("from", "mid")), str(state.get("to", "mid")), float(state.get("ratio", 1.0)))
	return EnvironmentRules.high_atmosphere_mix(str(state.get("current", "mid")))

func _draw_high_atmosphere_far(surface: CanvasItem, state: Dictionary, t: float) -> void:
	var mix := _high_atmosphere_mix(state)
	if mix <= 0.08: return
	for i in range(4):
		var texture: Texture2D = CIRRUS_FAR[i % CIRRUS_FAR.size()]
		var x := float((i * 181 + 29) % 760) - 80.0
		var y := fposmod(float(i) * 91.0 + t * (5.0 + float(i % 2) * 1.4), 330.0) + 82.0
		var scale := 0.86 + float(i % 3) * 0.14
		var size := texture.get_size() * scale
		surface.draw_texture_rect(texture, Rect2(Vector2(x,y) - size * 0.5, size), false, Color(0.78,0.86,0.89,0.10 + mix * 0.14))
	for i in range(2):
		var x := float((i * 337 + 73) % 690) - 40.0
		var y := fposmod(float(i) * 191.0 + t * (8.0 + float(i) * 1.5), 350.0) + 100.0
		var size := ANVIL_SHADOW.get_size() * (0.86 + float(i) * 0.12)
		surface.draw_texture_rect(ANVIL_SHADOW, Rect2(Vector2(x,y) - size * 0.5, size), false, Color(0.58,0.67,0.71,0.08 + mix * 0.14))

func _draw_high_atmosphere_near(surface: CanvasItem, state: Dictionary, t: float) -> void:
	var mix := _high_atmosphere_mix(state)
	if mix <= 0.20: return
	var count := maxi(1, int(round(5.0 * mix)))
	for i in range(count):
		var texture: Texture2D = CONTRAIL_NEAR[i % CONTRAIL_NEAR.size()]
		var x := 42.0 + float((i * 139 + 47) % 550)
		var y := fposmod(float(i) * 107.0 + t * (48.0 + float(i % 3) * 7.0), 410.0) + ENVIRONMENT_VIEW.position.y
		var alpha := (0.18 + float(i % 2) * 0.05) * mix
		surface.draw_texture(texture, Vector2(x,y), Color(0.82,0.90,0.92,alpha))

func _draw_parallax(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var forward_scale := _world_speed_multiplier()
	var hypersonic_ratio := clampf((forward_scale - 1.0) / 2.4, 0.0, 1.0)
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
			# At hypersonic speed the authored glints stretch into held raster streaks.
			# This creates directionally correct speed exposure without a full-screen
			# shader blur that would erase enemies, projectiles and terrain landmarks.
			var length := (7.0 + float((i * 13 + layer_index * 7) % 28)) * lerpf(1.0, 3.6, hypersonic_ratio)
			var accent: Texture2D = PARALLAX_ACCENTS[layer_index]
			surface.draw_texture_rect(accent, Rect2(Vector2(x0,y-4),Vector2(minf(length,622.0-x0),8)), false, tones[layer_index])

func _coast_x(world_y: float, scale: float) -> float:
	return 148.0 * scale + sin(world_y * 0.018) * 35.0 * scale + sin(world_y * 0.047 + 1.3) * 13.0 * scale

func _draw_coast(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state):
		return
	var scroll := t * _parallax_speed(profile, state, "mid") * 0.32
	_draw_vertical_chunk_sequence(surface, COAST_GEOGRAPHY_CHUNKS, scroll + float(_mission_seed(scene) % 3) * 1024.0, ENVIRONMENT_VIEW)
	var surface_scroll := fposmod(t * _parallax_speed(profile, state, "near") * 0.41, 512.0)
	_draw_vertical_loop(surface, COAST_SURFACE_TILE, surface_scroll, Rect2(300,ENVIRONMENT_VIEW.position.y,340,ENVIRONMENT_VIEW.size.y), Color(1,1,1,0.18))
	_draw_modular_coast_pass(surface, scene, profile, state, t)
	# Restrained moving wakes prevent the authored plate from reading as a static
	# illustration while preserving projectile contrast over the open water.
	var foam := _tone(profile, "foam", 0.34)
	for i in range(7):
		var sy := fposmod(float(i) * 53.0 + t * 21.0, 332.0) + ENVIRONMENT_VIEW.position.y
		var sx := 440.0 + float((i * 73) % 150)
		var wake_width := 18.0 + float(i % 3) * 7.0
		surface.draw_texture_rect(COAST_WAKE, Rect2(Vector2(sx,sy-5),Vector2(wake_width,10)), false, foam)

func _draw_modular_coast_pass(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float) -> void:
	# Finite authored modules use a long world-space cycle instead of wallpaper
	# tiling. The source master remains the continuous terrain bed; these pieces
	# provide separately registered structures and animated shoreline edges.
	var speed := _parallax_speed(profile, state, "mid") * 0.32
	var world_scroll := t * speed
	var seed := _mission_seed(scene)
	var scale := 0.46 + 0.18 * _ground_scale(state)
	var cycle := 1480.0
	var slots := [
		{"x": 354.0, "y": 112.0, "chunk": 0},
		{"x": 184.0, "y": 438.0, "chunk": 2},
		{"x": 72.0, "y": 776.0, "chunk": 3},
		{"x": 310.0, "y": 1090.0, "chunk": 1},
		{"x": 404.0, "y": 1262.0, "chunk": 4},
	]
	for slot_index in range(slots.size()):
		var slot: Dictionary = slots[slot_index]
		var texture_index := posmod(int(slot["chunk"]) + seed, COAST_FINITE_CHUNKS.size())
		var texture: Texture2D = COAST_FINITE_CHUNKS[texture_index]
		var y := fposmod(float(slot["y"]) + world_scroll + float(seed % 97), cycle) - 190.0 + ENVIRONMENT_VIEW.position.y
		var size := (texture.get_size() * scale).round()
		if y + size.y < ENVIRONMENT_VIEW.position.y or y > ENVIRONMENT_VIEW.end.y:
			continue
		var x := clampf(float(slot["x"]) + float((seed + slot_index * 31) % 29) - 14.0, 8.0, 632.0 - size.x)
		_draw_texture_rect_clipped(surface, texture, Rect2(Vector2(x, y).round(), size), ENVIRONMENT_VIEW, Color(0.78, 0.84, 0.84, 0.68))

	# Shore wash is a temporal loop but not a spatial wallpaper. Two registered
	# edge events pass through the coast at different phases and never cover the
	# open-water combat lane together.
	var wash_frame: Texture2D = COAST_SHORE_WASH[posmod(int(floor(t * 6.0)), COAST_SHORE_WASH.size())]
	for wash_index in range(2):
		var wash_y := fposmod(world_scroll + float(wash_index * 706 + seed % 181), cycle) - 120.0 + ENVIRONMENT_VIEW.position.y
		var wash_size := (wash_frame.get_size() * Vector2(0.58, 0.42)).round()
		if wash_y >= ENVIRONMENT_VIEW.position.y and wash_y + wash_size.y <= ENVIRONMENT_VIEW.end.y:
			var edge_fade := minf(clampf((wash_y - ENVIRONMENT_VIEW.position.y) / 24.0, 0.0, 1.0), clampf((ENVIRONMENT_VIEW.end.y - wash_y - wash_size.y) / 24.0, 0.0, 1.0))
			_draw_texture_rect_clipped(surface, wash_frame, Rect2(Vector2(316.0 + wash_index * 42.0, wash_y).round(), wash_size), ENVIRONMENT_VIEW, Color(0.86, 0.94, 0.96, 0.34 * edge_fade))

	var impact_frame: Texture2D = COAST_BREAKWATER_IMPACT[posmod(int(floor(t * 8.0)), COAST_BREAKWATER_IMPACT.size())]
	var impact_y := fposmod(world_scroll + 360.0 + float(seed % 239), cycle) - 100.0 + ENVIRONMENT_VIEW.position.y
	if impact_y + 66.0 >= ENVIRONMENT_VIEW.position.y and impact_y <= ENVIRONMENT_VIEW.end.y:
		_draw_texture_rect_clipped(surface, impact_frame, Rect2(Vector2(374, impact_y).round(), Vector2(66,66)), ENVIRONMENT_VIEW, Color(0.90,0.96,0.98,0.48))

func _draw_texture_rect_clipped(surface: CanvasItem, texture: Texture2D, destination: Rect2, clip_rect: Rect2, modulate := Color.WHITE) -> void:
	var clipped := destination.intersection(clip_rect)
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
		return
	var scale := texture.get_size() / destination.size
	var source := Rect2((clipped.position - destination.position) * scale, clipped.size * scale)
	surface.draw_texture_rect_region(texture, clipped, source, modulate)

func _draw_vertical_loop(surface: CanvasItem, texture: Texture2D, source_y: float, destination: Rect2, modulate := Color.WHITE) -> void:
	var remaining := destination.size.y
	var draw_y := destination.position.y
	# Positive world travel means scenery enters at the top and passes downward.
	# Sampling the texture in the opposite direction is the standard scrolling-
	# background transform; using +source_y made the world visibly run backward.
	var sample_y := fposmod(-source_y, float(texture.get_height()))
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

func _draw_vertical_chunk_sequence(surface: CanvasItem, chunks: Array, source_y: float, destination: Rect2, modulate := Color.WHITE) -> void:
	if chunks.is_empty():
		return
	var chunk_height := float((chunks[0] as Texture2D).get_height())
	var cycle_height := chunk_height * float(chunks.size())
	var sample_world_y := fposmod(-source_y, cycle_height)
	var remaining := destination.size.y
	var draw_y := destination.position.y
	while remaining > 0.0:
		var chunk_index := int(floor(sample_world_y / chunk_height)) % chunks.size()
		var sample_y := fposmod(sample_world_y, chunk_height)
		var segment := minf(remaining, chunk_height - sample_y)
		var texture: Texture2D = chunks[chunk_index]
		surface.draw_texture_rect_region(
			texture,
			Rect2(destination.position.x, draw_y, destination.size.x, segment),
			Rect2(0, sample_y, float(texture.get_width()), segment),
			modulate
		)
		remaining -= segment
		draw_y += segment
		sample_world_y = fposmod(sample_world_y + segment, cycle_height)

func _draw_industrial(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state):
		return
	var scroll := t * _parallax_speed(profile, state, "mid") * 0.30
	_draw_vertical_chunk_sequence(surface, REFINERY_GEOGRAPHY_CHUNKS, scroll + float(_mission_seed(scene) % 3) * 1024.0, ENVIRONMENT_VIEW)
	_draw_modular_refinery_pass(surface, scene, profile, state, t)

func _draw_modular_refinery_pass(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float) -> void:
	var speed := _parallax_speed(profile, state, "mid") * 0.30
	var world_scroll := t * speed
	var seed := _mission_seed(scene)
	var cycle := 1800.0
	var scale := 0.42 + 0.15 * _ground_scale(state)
	var slots := [
		{"x":104.0,"y":210.0,"chunk":3,"alpha":0.74},
		{"x":424.0,"y":810.0,"chunk":2,"alpha":0.70},
		{"x":230.0,"y":1420.0,"chunk":5,"alpha":0.30},
	]
	for slot_index in range(slots.size()):
		var slot: Dictionary = slots[slot_index]
		var texture: Texture2D = REFINERY_FINITE_CHUNKS[int(slot["chunk"])]
		var y := fposmod(float(slot["y"]) + world_scroll + float(seed % 83), cycle) - 170.0 + ENVIRONMENT_VIEW.position.y
		var size := (texture.get_size() * scale).round()
		var x := clampf(float(slot["x"]) + float((seed + slot_index * 19) % 23), 8.0, 632.0 - size.x)
		_draw_texture_rect_clipped(surface, texture, Rect2(Vector2(x,y).round(), size), ENVIRONMENT_VIEW, Color(0.76,0.80,0.78,float(slot["alpha"])))

	var steam: Texture2D = REFINERY_STEAM[posmod(int(floor(t * 5.0)), REFINERY_STEAM.size())]
	var steam_y := fposmod(world_scroll + 510.0 + float(seed % 97), cycle) - 120.0 + ENVIRONMENT_VIEW.position.y
	_draw_texture_rect_clipped(surface, steam, Rect2(Vector2(438,steam_y).round(),Vector2(46,68)),ENVIRONMENT_VIEW,Color(0.74,0.79,0.78,0.38))
	var flare: Texture2D = REFINERY_FLARE[posmod(int(floor(t * 8.0)), REFINERY_FLARE.size())]
	var flare_y := fposmod(world_scroll + 1010.0 + float(seed % 113), cycle) - 120.0 + ENVIRONMENT_VIEW.position.y
	_draw_texture_rect_clipped(surface, flare, Rect2(Vector2(104,flare_y).round(),Vector2(42,62)),ENVIRONMENT_VIEW,Color(0.92,0.78,0.58,0.62))
	var smoke: Texture2D = REFINERY_SMOKE[posmod(int(floor(t * 4.0)), REFINERY_SMOKE.size())]
	var smoke_y := fposmod(world_scroll + 1510.0 + float(seed % 131), cycle) - 120.0 + ENVIRONMENT_VIEW.position.y
	_draw_texture_rect_clipped(surface, smoke, Rect2(Vector2(512,smoke_y).round(),Vector2(48,70)),ENVIRONMENT_VIEW,Color(0.68,0.72,0.72,0.34))

func _draw_water(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float) -> void:
	var speed := _parallax_speed(profile, state, "near")
	var deep_scroll := fposmod(t * speed * 0.17, 512.0)
	var surface_scroll := fposmod(t * speed * 0.33, 512.0)
	var foam_scroll := fposmod(t * speed * 0.51, 512.0)
	var deep: Texture2D = SEA_DEEP_ANIMATION[posmod(int(floor(t * 4.0)), SEA_DEEP_ANIMATION.size())]
	var surface_chop: Texture2D = SEA_SURFACE_ANIMATION[posmod(int(floor(t * 6.0)), SEA_SURFACE_ANIMATION.size())]
	var foam: Texture2D = SEA_FOAM_ANIMATION[posmod(int(floor(t * 8.0)), SEA_FOAM_ANIMATION.size())]
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.018, 0.045, 0.068, 1.0))
	_draw_vertical_loop(surface, deep, deep_scroll, ENVIRONMENT_VIEW, Color(0.72,0.80,0.84,0.82))
	_draw_vertical_loop(surface, surface_chop, surface_scroll, ENVIRONMENT_VIEW, Color(0.78,0.86,0.88,0.46))
	_draw_open_water_finite(surface, scene, profile, state, t)
	_draw_vertical_loop(surface, foam, foam_scroll, ENVIRONMENT_VIEW, Color(0.72,0.84,0.86,0.40))
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.01, 0.025, 0.045, 0.12))
	for i in range(14):
		var x := float((i * 109 + 31) % 690) - 20.0
		var y := fposmod(float(i) * 43.0 + t * (42.0 + float(i % 3) * 4.0), 340.0) + 48.0
		var rain_texture: Texture2D = RAIN_ACCENTS[i % RAIN_ACCENTS.size()]
		surface.draw_texture(rain_texture, Vector2(x-8,y), Color(1,1,1,0.30))

func _draw_open_water_finite(surface: CanvasItem, scene: Object, profile: Dictionary, state: Dictionary, t: float) -> void:
	var world_scroll := t * _parallax_speed(profile, state, "mid") * 0.24
	var seed := _mission_seed(scene)
	var cycle := 2380.0
	var scale := 0.58 + 0.14 * _ground_scale(state)
	var slots := [
		{"x":76.0, "y":120.0, "asset":10, "alpha":0.72},
		{"x":428.0, "y":410.0, "asset":0, "alpha":0.76},
		{"x":205.0, "y":690.0, "asset":5, "alpha":0.44},
		{"x":470.0, "y":980.0, "asset":3, "alpha":0.58},
		{"x":112.0, "y":1290.0, "asset":11, "alpha":0.68},
		{"x":382.0, "y":1620.0, "asset":4, "alpha":0.38},
		{"x":238.0, "y":1940.0, "asset":2, "alpha":0.76},
		{"x":514.0, "y":2180.0, "asset":9, "alpha":0.40},
	]
	for slot_index in range(slots.size()):
		var slot: Dictionary = slots[slot_index]
		var asset_index := posmod(int(slot["asset"]) + seed % 3, OPEN_WATER_FINITE.size())
		var texture: Texture2D = OPEN_WATER_FINITE[asset_index]
		var y := fposmod(float(slot["y"]) + world_scroll + float(seed % 173), cycle) - 220.0 + ENVIRONMENT_VIEW.position.y
		var size := (texture.get_size() * scale).round()
		if y + size.y < ENVIRONMENT_VIEW.position.y or y > ENVIRONMENT_VIEW.end.y:
			continue
		var x := clampf(float(slot["x"]) + float((seed + slot_index * 41) % 47) - 23.0, 8.0, 632.0 - size.x)
		_draw_texture_rect_clipped(surface, texture, Rect2(Vector2(x,y).round(), size), ENVIRONMENT_VIEW, Color(0.80,0.86,0.88,float(slot["alpha"])))

func _draw_desert_front(surface: CanvasItem, scene: Object, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := t * 30.0 * _world_speed_multiplier()
	_draw_vertical_chunk_sequence(surface, DESERT_GEOGRAPHY_CHUNKS, scroll + float(_mission_seed(scene) % 3) * 1024.0, ENVIRONMENT_VIEW)
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.075, 0.045, 0.025, 0.18))
	var gust: Texture2D = DESERT_DUST_GUST[posmod(int(floor(t * 6.0)), DESERT_DUST_GUST.size())]
	var seed := _mission_seed(scene)
	for gust_index in range(2):
		var gust_y := fposmod(scroll + float(gust_index * 690 + seed % 223), 1420.0) - 120.0 + ENVIRONMENT_VIEW.position.y
		var gust_x := 48.0 + float((seed + gust_index * 271) % 420)
		_draw_texture_rect_clipped(surface, gust, Rect2(Vector2(gust_x,gust_y).round(),Vector2(160,96)),ENVIRONMENT_VIEW,Color(0.84,0.76,0.62,0.26))

func _draw_river_corridor(surface: CanvasItem, scene: Object, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := t * 27.0 * _world_speed_multiplier() + float(_mission_seed(scene) % 3) * 1024.0
	_draw_vertical_chunk_sequence(surface, RIVER_GEOGRAPHY_CHUNKS, scroll, ENVIRONMENT_VIEW)
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.015, 0.035, 0.032, 0.13))
	var current_slots := [
		{"x":292.0,"y":110.0}, {"x":370.0,"y":610.0}, {"x":264.0,"y":1110.0},
		{"x":310.0,"y":1600.0}, {"x":344.0,"y":2110.0}, {"x":338.0,"y":2630.0},
	]
	for slot_index in range(current_slots.size()):
		var slot: Dictionary = current_slots[slot_index]
		var current: Texture2D = RIVER_CURRENT_ANIMATION[posmod(int(floor(t * 6.0)) + slot_index * 2,RIVER_CURRENT_ANIMATION.size())]
		var y := fposmod(float(slot["y"]) + scroll,3072.0) + ENVIRONMENT_VIEW.position.y
		_draw_texture_rect_clipped(surface,current,Rect2(Vector2(float(slot["x"]),y).round(),Vector2(112,220)),ENVIRONMENT_VIEW,Color(0.62,0.72,0.78,0.18))

func _draw_mountain_radar(surface: CanvasItem, state: Dictionary, t: float) -> void:
	var scroll := fposmod(t * 15.0 * _world_speed_multiplier(), 720.0)
	_draw_vertical_loop(surface, MOUNTAIN_RADAR, scroll, ENVIRONMENT_VIEW)
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.015, 0.025, 0.045, 0.14))
	var weather_scroll := fposmod(t * 27.0 * _world_speed_multiplier(), 512.0)
	_draw_vertical_loop(surface, MOUNTAIN_WEATHER_TILE, weather_scroll, ENVIRONMENT_VIEW, Color(1,1,1,0.80))

func _draw_night_harbor(surface: CanvasItem, scene: Object, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := t * 29.0 * _world_speed_multiplier() + float(_mission_seed(scene) % 3) * 1024.0
	_draw_vertical_chunk_sequence(surface, HARBOR_GEOGRAPHY_CHUNKS, scroll, ENVIRONMENT_VIEW)
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.008, 0.018, 0.032, 0.12))
	var reflection_slots := [
		{"x":286.0,"y":130.0}, {"x":340.0,"y":620.0}, {"x":304.0,"y":1110.0},
		{"x":330.0,"y":1580.0}, {"x":292.0,"y":2130.0}, {"x":346.0,"y":2650.0},
	]
	for slot_index in range(reflection_slots.size()):
		var slot: Dictionary = reflection_slots[slot_index]
		var reflection: Texture2D = HARBOR_REFLECTION_ANIMATION[posmod(int(floor(t * 6.0)) + slot_index * 2,HARBOR_REFLECTION_ANIMATION.size())]
		var y := fposmod(float(slot["y"]) + scroll,3072.0) + ENVIRONMENT_VIEW.position.y
		_draw_texture_rect_clipped(surface,reflection,Rect2(Vector2(float(slot["x"]),y).round(),Vector2(128,224)),ENVIRONMENT_VIEW,Color(0.72,0.80,0.82,0.34))

func _draw_city_outskirts(surface: CanvasItem, scene: Object, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := t * 38.0 * _world_speed_multiplier() + float(_mission_seed(scene) % 3) * 1024.0
	_draw_vertical_chunk_sequence(surface, CITY_GEOGRAPHY_CHUNKS, scroll, ENVIRONMENT_VIEW)
	surface.draw_rect(ENVIRONMENT_VIEW, Color(0.018, 0.023, 0.026, 0.12))
	var activity_slots := [
		{"x":202.0,"y":210.0}, {"x":330.0,"y":690.0}, {"x":248.0,"y":1130.0},
		{"x":324.0,"y":1650.0}, {"x":216.0,"y":2160.0}, {"x":344.0,"y":2680.0},
	]
	for slot_index in range(activity_slots.size()):
		var slot: Dictionary = activity_slots[slot_index]
		var activity: Texture2D = CITY_ACTIVITY_ANIMATION[posmod(int(floor(t * 6.0)) + slot_index * 2, CITY_ACTIVITY_ANIMATION.size())]
		var y := fposmod(float(slot["y"]) + scroll, 3072.0) + ENVIRONMENT_VIEW.position.y
		_draw_texture_rect_clipped(surface, activity, Rect2(Vector2(float(slot["x"]), y).round(), Vector2(144,208)), ENVIRONMENT_VIEW, Color(0.84,0.88,0.86,0.30))

func _draw_machine_furnace(surface: CanvasItem, state: Dictionary, t: float) -> void:
	if not _draw_ground_detail(state): return
	var scroll := fposmod(t * 34.0 * _world_speed_multiplier(), 720.0)
	_draw_vertical_loop(surface, MACHINE_FURNACE, scroll, ENVIRONMENT_VIEW, Color(0.80, 0.80, 0.78, 0.94))
	var activity_scroll := fposmod(t * 28.0 * _world_speed_multiplier(), 512.0)
	var activity_pulse := 0.68 + 0.22 * (0.5 + 0.5 * sin(t * 1.7))
	_draw_vertical_loop(surface, FURNACE_ACTIVITY_TILE, activity_scroll, ENVIRONMENT_VIEW, Color(1,1,1,activity_pulse))

func _draw_cloud_top(surface: CanvasItem, profile: Dictionary, state: Dictionary, t: float) -> void:
	var density := _cloud_density(state)
	var scroll := fposmod(t * 14.0, 720.0)
	_draw_vertical_loop(surface, STRATOSPHERIC_CLOUD_DECK, scroll, ENVIRONMENT_VIEW, Color(0.78, 0.86, 0.91, 0.66))
	_draw_high_atmosphere_horizon(surface, profile, _horizon_glow(state))
	# Sparse moving banks preserve depth without hiding the authored cloud-deck structure.
	var count := maxi(4, int(round(8.0 * maxf(0.42, density))))
	for i in range(count):
		var texture: Texture2D = CLOUD_HIGH[i % CLOUD_HIGH.size()]
		var x := float((i * 137 + 43) % 720) - 40.0
		var scale := 0.72 + float(i % 3) * 0.13
		var size := Vector2(texture.get_size()) * scale
		var y := fposmod(float(i) * 71.0 + t * 14.0, ENVIRONMENT_VIEW.size.y) + ENVIRONMENT_VIEW.position.y + size.y * 0.5
		surface.draw_texture_rect(texture, Rect2(Vector2(x, y) - size * 0.5, size), false, Color(0.82, 0.87, 0.90, 0.24 + density * 0.22))

func _draw_high_atmosphere_horizon(surface: CanvasItem, _profile: Dictionary, glow: float) -> void:
	surface.draw_texture(HIGH_ATMOSPHERE_RIM, Vector2(0,152), Color(1,1,1,0.26 + 0.74 * glow))

func _draw_orbital(surface: CanvasItem, _profile: Dictionary, state: Dictionary, t: float, orbital_mix: float) -> void:
	var mix := clampf(orbital_mix, 0.0, 1.0)
	if mix <= 0.01:
		return
	var scroll := fposmod(t * 8.0, 720.0)
	_draw_vertical_loop(surface, BLACK_SKY_STATION, scroll, ENVIRONMENT_VIEW, Color(0.76, 0.82, 0.88, 0.88 * mix))
	var debris_scroll := fposmod(t * 15.0, 512.0)
	_draw_vertical_loop(surface, ORBITAL_DEBRIS_TILE, debris_scroll, ENVIRONMENT_VIEW, Color(1,1,1,0.78*mix))
	# The authored sparse tile drifts independently without becoming star wallpaper.
	var star_scroll := fposmod(t * 2.0, 512.0)
	_draw_vertical_loop(surface, ORBITAL_STARFIELD_TILE, star_scroll, ENVIRONMENT_VIEW, Color(1,1,1,0.82*mix))
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
		_draw_vertical_loop(surface,CLOUD_SHADOW_TILE,shadow_scroll,ENVIRONMENT_VIEW,Color(1,1,1,clampf(density*0.52,0.0,0.58)))
	for i in range(count):
		var texture: Texture2D = family[i % family.size()]
		var speed := 10.0 + density * 20.0 + float(i % 3) * 2.0
		var wind := 2.4 + float(i % 4) * 0.8
		var x := fposmod(float(i * 149 + 61) + t * wind, 800.0) - 80.0
		var scale := 0.72 + float((i * 5) % 4) * 0.12
		var size := Vector2(texture.get_size()) * scale
		var y := fposmod(float(i) * 97.0 + t * speed, ENVIRONMENT_VIEW.size.y) + ENVIRONMENT_VIEW.position.y + size.y * 0.5
		_draw_cloud_bank_shadow(surface, texture, Vector2(x, y), size, band, density, i)
		surface.draw_texture_rect(texture, Rect2(Vector2(x, y) - size * 0.5, size), false, Color(0.78, 0.84, 0.88, alpha))
	if density >= 0.32:
		var mist_scroll := fposmod(t * (18.0 + density * 14.0), 512.0)
		_draw_vertical_loop(surface,CLOUD_MIST_TILE,mist_scroll,ENVIRONMENT_VIEW,Color(1,1,1,clampf(density*0.34,0.0,0.42)))

func _draw_cloud_bank_shadow(surface: CanvasItem, texture: Texture2D, center: Vector2, size: Vector2, band: String, density: float, index: int) -> void:
	# The shadow reuses the authored bank alpha so every visible cloud has a
	# registered undercast shape. A small deterministic offset implies the low
	# late-day light used throughout the campaign without adding soft filtering.
	var distance := 7.0 if band == "low" else (11.0 if band == "mid" else 15.0)
	var offset := Vector2(distance + float(index % 2) * 2.0, distance * 0.62)
	var shadow_alpha := clampf(0.055 + density * 0.12, 0.06, 0.18)
	if band == "high" or band == "orbital":
		shadow_alpha *= 0.68
	var shadow_size := size * Vector2(1.04, 0.94)
	surface.draw_texture_rect(
		texture,
		Rect2(center + offset - shadow_size * 0.5, shadow_size),
		false,
		Color(0.075, 0.10, 0.13, shadow_alpha)
	)
