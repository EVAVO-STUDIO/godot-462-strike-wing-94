extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EnvironmentRules = preload("res://scripts/environment_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/environment_profiles.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "environment profile catalogue should load")
	if typeof(data) == TYPE_DICTIONARY:
		var profiles: Array = data.get("profiles", [])
		for required in ["coast","industrial","open_water","high_cloud","orbital"]:
			_expect(not EnvironmentRules.profile_for(profiles, required).is_empty(), "missing environment profile %s" % required)
		var coast := EnvironmentRules.profile_for(profiles, "coast")
		for palette_key in ["land", "inland", "sand", "foam", "road"]:
			_expect(coast.has(palette_key), "coastal benchmark palette should define %s" % palette_key)
		var low_speed := EnvironmentRules.parallax_speed(coast, "low", "near")
		var high_speed := EnvironmentRules.parallax_speed(coast, "high", "near")
		var blended_speed := EnvironmentRules.blended_parallax_speed(coast, "low", "high", 0.5, "near")
		_expect(low_speed > high_speed, "low-altitude terrain parallax should move faster than high-altitude terrain")
		_expect(blended_speed < low_speed and blended_speed > high_speed, "altitude transition parallax should interpolate instead of snapping")
	_expect(EnvironmentRules.ground_detail_scale("low") > EnvironmentRules.ground_detail_scale("high"), "ground detail should shrink with altitude")
	var blended_ground := EnvironmentRules.blended_ground_detail_scale("low", "high", 0.5)
	_expect(blended_ground < EnvironmentRules.ground_detail_scale("low") and blended_ground > EnvironmentRules.ground_detail_scale("high"), "ground-detail scale should interpolate through altitude changes")
	var blended_clouds := EnvironmentRules.blended_cloud_density("mid", "high", 0.5)
	_expect(blended_clouds > EnvironmentRules.cloud_density("mid") and blended_clouds < EnvironmentRules.cloud_density("high"), "cloud density should blend between altitude lanes")
	var blended_glow := EnvironmentRules.blended_horizon_glow("high", "orbital", 0.5)
	_expect(blended_glow > EnvironmentRules.horizon_glow("high") and blended_glow < EnvironmentRules.horizon_glow("orbital"), "atmospheric glow should blend into orbital presentation")
	_expect(not EnvironmentRules.should_draw_ground_detail("orbital"), "orbital presentation should not use normal ground-detail motifs")
	var mission_data = ContentCatalog.load_json("res://data/missions.json")
	_expect(typeof(mission_data) == TYPE_DICTIONARY, "mission catalogue should load for environment identity checks")
	if typeof(mission_data) == TYPE_DICTIONARY:
		var city_assignments: Dictionary = {}
		for mission in mission_data.get("missions", []):
			if typeof(mission) == TYPE_DICTIONARY and str(mission.get("id", "")) in ["s2_m06_ghost_convoy", "s2_m09_silent_city"]:
				city_assignments[str(mission.get("id", ""))] = str(mission.get("environment_variant", ""))
		_expect(city_assignments.get("s2_m06_ghost_convoy", "") == "city_outskirts", "Ghost Convoy should use the authored city belt")
		_expect(city_assignments.get("s2_m09_silent_city", "") == "city_outskirts", "Silent City should use the authored city belt")
		var furnace_assignments: Dictionary = {}
		for mission in mission_data.get("missions", []):
			if typeof(mission) == TYPE_DICTIONARY and str(mission.get("id", "")) in ["m08_machine_furnace", "s2_m04_dead_factory"]:
				furnace_assignments[str(mission.get("id", ""))] = str(mission.get("environment_variant", ""))
		_expect(furnace_assignments.get("m08_machine_furnace", "") == "machine_furnace", "Machine Furnace should use the authored autonomous foundry")
		_expect(furnace_assignments.get("s2_m04_dead_factory", "") == "machine_furnace", "Dead Factory should use the authored autonomous foundry")
	var director_file := FileAccess.open("res://scripts/environment_director.gd", FileAccess.READ)
	_expect(director_file != null, "environment_director.gd should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains('layer = 2'), "environment overlay should remain below combat-support/projectile/UI layers")
		_expect(source.contains("_altitude_state()"), "environment renderer should consume live transition state")
		_expect(source.contains("blended_parallax_speed"), "environment renderer should blend parallax speed")
		_expect(source.contains("blended_cloud_density"), "environment renderer should blend cloud density")
		_expect(source.contains("_orbital_mix"), "orbital starfield should fade through the atmospheric transition")
		_expect(source.contains("_draw_high_atmosphere_horizon"), "orbital ascent should retain atmospheric curvature during transition")
		_expect(source.contains("COASTAL_STRIKE_ZONE"), "coastal benchmark should use its authored raster master")
		_expect(source.contains("REFINERY_NIGHT"), "industrial benchmark should use its authored refinery raster master")
		_expect(source.contains("STORM_SEA"), "open-water benchmark should use its authored storm-sea raster master")
		_expect(source.contains("DESERT_FRONT"), "desert benchmark should use its authored battlefield raster master")
		_expect(source.contains("RIVER_CORRIDOR"), "river benchmark should use its authored corridor raster master")
		_expect(source.contains("MOUNTAIN_RADAR"), "mountain benchmark should use its authored radar-zone raster master")
		_expect(source.contains("NIGHT_HARBOR"), "harbor benchmark should use its authored naval-port raster master")
		_expect(source.contains("STRATOSPHERIC_CLOUD_DECK"), "high-altitude benchmark should use its authored stratospheric raster master")
		_expect(source.contains("BLACK_SKY_STATION"), "orbital benchmark should use its authored station raster master")
		_expect(source.contains("CITY_OUTSKIRTS"), "city-belt benchmark should use its authored urban raster master")
		_expect(source.contains("MACHINE_FURNACE"), "machine-war reveal should use its authored autonomous-foundry raster master")
		_expect(source.contains("_draw_vertical_loop"), "coastal benchmark should scroll its authored plate without exposed seams")
		_expect(source.contains("Restrained moving wakes"), "coastal benchmark should retain subdued open-water motion cues")
		for cloud_family in ["CLOUD_LOW", "CLOUD_MID", "CLOUD_HIGH"]:
			_expect(source.contains(cloud_family), "environment renderer should retain authored %s family" % cloud_family)
		_expect(not source.substr(source.find("func _draw_clouds"), source.length() - source.find("func _draw_clouds")).contains("draw_colored_polygon"), "foreground clouds should not regress to polygon lozenges")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/coast/coastal_strike_zone_loop_v1.png"), "coastal runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/coast_asset_manifest.json"), "coastal source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/cloud_asset_manifest.json"), "cloud source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/industrial/refinery_night_loop_v1.png"), "industrial runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/industrial_asset_manifest.json"), "industrial source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/water/storm_sea_loop_v1.png"), "open-water runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/water_asset_manifest.json"), "open-water source manifest should exist")
		for layer_path in [
			"sea_deep_tile.png", "sea_surface_tile.png", "coast_surface_tile.png", "cloud_shadow_tile.png", "cloud_mist_tile.png",
			"refinery_detail_tile.png", "desert_dust_tile.png", "river_current_tile.png", "mountain_weather_tile.png",
			"harbor_reflection_tile.png", "city_light_tile.png", "furnace_activity_tile.png", "orbital_debris_tile.png"
		]:
			var layer_texture := load("res://assets/runtime/environments/layers/%s" % layer_path)
			_expect(layer_texture is Texture2D and layer_texture.get_height() == 512, "seamless environment layer should retain 512px vertical registration: %s" % layer_path)
			if layer_texture is Texture2D:
				var layer_image: Image = layer_texture.get_image()
				for sample_x in range(0,layer_image.get_width(),32):
					_expect(layer_image.get_pixel(sample_x,0).is_equal_approx(layer_image.get_pixel(sample_x,layer_image.get_height()-1)), "environment tile must close its vertical seam exactly: %s x=%d" % [layer_path,sample_x])
		_expect(source.contains("SEA_DEEP_TILE") and source.contains("SEA_SURFACE_TILE") and source.contains("CLOUD_SHADOW_TILE") and source.contains("CLOUD_MIST_TILE"), "environment renderer should use independent authored sea and cloud depth layers")
		for biome_layer in ["REFINERY_DETAIL_TILE", "DESERT_DUST_TILE", "RIVER_CURRENT_TILE", "MOUNTAIN_WEATHER_TILE", "HARBOR_REFLECTION_TILE", "CITY_LIGHT_TILE", "FURNACE_ACTIVITY_TILE", "ORBITAL_DEBRIS_TILE"]:
			_expect(source.contains(biome_layer), "environment renderer should use authored biome detail layer %s" % biome_layer)
		_expect(source.contains("deep_scroll") and source.contains("surface_scroll") and source.contains("shadow_scroll") and source.contains("mist_scroll"), "environment depth layers should scroll independently")
		_expect(FileAccess.file_exists("res://assets/source/environments/layered_scroll_asset_manifest.json"), "layered scrolling environment manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/desert/desert_front_loop_v1.png"), "desert runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/desert_asset_manifest.json"), "desert source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/river/river_corridor_loop_v1.png"), "river runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/river_asset_manifest.json"), "river source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/mountain/mountain_radar_loop_v1.png"), "mountain runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/mountain_asset_manifest.json"), "mountain source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/harbor/night_harbor_loop_v1.png"), "harbor runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/harbor_asset_manifest.json"), "harbor source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/high_atmosphere/stratospheric_cloud_deck_loop_v1.png"), "stratospheric runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/high_atmosphere_asset_manifest.json"), "stratospheric source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/orbital/black_sky_station_loop_v1.png"), "orbital runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/orbital_asset_manifest.json"), "orbital source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/city/city_outskirts_loop_v1.png"), "city runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/city_asset_manifest.json"), "city source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/machine_furnace/machine_furnace_loop_v1.png"), "machine furnace runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/machine_furnace_asset_manifest.json"), "machine furnace source manifest should exist")
		var master_paths := [
			"coast/coastal_strike_zone_loop_v1.png", "industrial/refinery_night_loop_v1.png", "water/storm_sea_loop_v1.png",
			"desert/desert_front_loop_v1.png", "river/river_corridor_loop_v1.png", "mountain/mountain_radar_loop_v1.png",
			"harbor/night_harbor_loop_v1.png", "high_atmosphere/stratospheric_cloud_deck_loop_v1.png", "orbital/black_sky_station_loop_v1.png",
			"city/city_outskirts_loop_v1.png", "machine_furnace/machine_furnace_loop_v1.png"
		]
		for master_path in master_paths:
			var master_texture := load("res://assets/runtime/environments/%s" % master_path) as Texture2D
			_expect(master_texture != null and master_texture.get_size() == Vector2(640,720), "environment master should retain 640x720 scroll geometry: %s" % master_path)
			if master_texture != null:
				var master_image: Image = master_texture.get_image()
				for sample_x in range(0,640,64):
					_expect(master_image.get_pixel(sample_x,0).is_equal_approx(master_image.get_pixel(sample_x,719)), "environment master must close its vertical seam: %s x=%d" % [master_path,sample_x])
		for cloud_asset in ["low_wisp_a", "low_wisp_b", "mid_broken_a", "mid_broken_b", "high_mass_a", "high_mass_b"]:
			_expect(FileAccess.file_exists("res://assets/runtime/environments/clouds/cloud_bank_%s.png" % cloud_asset), "missing authored cloud sprite %s" % cloud_asset)
		for variant_function in ["_draw_desert_front", "_draw_river_corridor", "_draw_mountain_radar", "_draw_night_harbor", "_draw_city_outskirts", "_draw_machine_furnace"]:
			_expect(source.contains(variant_function), "Sector I environment identity missing %s" % variant_function)
		_expect(not source.substr(source.find("func _draw_cloud_top"), source.find("func _draw_high_atmosphere_horizon") - source.find("func _draw_cloud_top")).contains("draw_circle"), "cloud-top renderer should use hand-shaped banks instead of circular placeholders")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('EnvironmentDirector="*res://scripts/environment_director.gd"'), "environment director should remain autoloaded")
	var transition_file := FileAccess.open("res://scripts/altitude_transition_director.gd", FileAccess.READ)
	_expect(transition_file != null, "altitude transition renderer should be readable")
	if transition_file != null:
		var transition_source := transition_file.get_as_text()
		_expect(transition_source.contains("TRANSITION_CLOUDS"), "altitude sweep should use authored cloud sprites")
		_expect(not transition_source.contains("draw_circle"), "altitude sweep should not regress to circular cloud placeholders")
		_expect(transition_source.contains("LANE_PANEL") and transition_source.contains("CLOUD_SHADOW") and transition_source.contains("CLIMB_LEFT") and transition_source.contains("DIVE_RIGHT"), "altitude transitions should use authored HUD, cloud-shadow and motion sprites")
		_expect(not transition_source.contains("draw_rect") and not transition_source.contains("draw_line"), "altitude transition presentation should not regress to vector boxes or speed lines")
	var transition_sizes := {"lane_panel":Vector2(32,32),"cloud_shadow":Vector2(96,8),"climb_left":Vector2(32,216),"climb_right":Vector2(32,216),"dive_left":Vector2(32,216),"dive_right":Vector2(32,216)}
	for transition_asset in transition_sizes:
		var transition_texture := load("res://assets/runtime/ui/hud/altitude_transition/%s.png" % transition_asset)
		_expect(transition_texture is Texture2D and transition_texture.get_size() == transition_sizes[transition_asset], "altitude transition asset should retain registered geometry: %s" % transition_asset)
	_expect(FileAccess.file_exists("res://assets/source/ui/hud/altitude_transition_manifest.json"), "altitude transition source/runtime manifest should exist")
	if failures.is_empty():
		print("Strike Wing environment self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
