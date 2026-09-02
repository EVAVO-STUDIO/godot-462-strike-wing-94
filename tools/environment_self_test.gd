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
	_expect(EnvironmentRules.high_atmosphere_mix("high") > EnvironmentRules.high_atmosphere_mix("mid"), "high-altitude motion depth should peak in the high band")
	var blended_atmosphere := EnvironmentRules.blended_high_atmosphere_mix("mid", "high", 0.5)
	_expect(blended_atmosphere > EnvironmentRules.high_atmosphere_mix("mid") and blended_atmosphere < EnvironmentRules.high_atmosphere_mix("high"), "cirrus and contrail depth should blend through altitude transitions")
	_expect(not EnvironmentRules.should_draw_ground_detail("orbital"), "orbital presentation should not use normal ground-detail motifs")
	var coast_ground := EnvironmentRules.surface_spawn_x("coast", "", "ground", 0.5, 0.0, 100.0)
	var coast_sea := EnvironmentRules.surface_spawn_x("coast", "", "sea", 0.5, 0.0, 100.0)
	_expect(coast_ground < 50.0 and coast_sea > 60.0, "coastal surface targets should separate land and navigable-water lanes")
	var river_ship := EnvironmentRules.surface_spawn_x("open_water", "river", "sea", 0.5, 0.0, 100.0)
	var river_left_bank := EnvironmentRules.surface_spawn_x("open_water", "river", "ground", 0.2, 0.0, 100.0)
	var river_right_bank := EnvironmentRules.surface_spawn_x("open_water", "river", "ground", 0.8, 0.0, 100.0)
	_expect(river_ship > 35.0 and river_ship < 65.0 and river_left_bank < 30.0 and river_right_bank > 70.0, "river targets should place ships in-channel and ground forces on either bank")
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
	var secret_data = ContentCatalog.load_json("res://data/secret_missions.json")
	_expect(typeof(secret_data) == TYPE_DICTIONARY, "secret mission catalogue should load for environment identity checks")
	if typeof(secret_data) == TYPE_DICTIONARY:
		var secret_missions: Array = secret_data.get("missions", [])
		for secret in secret_missions:
			if typeof(secret) == TYPE_DICTIONARY:
				_expect(not EnvironmentRules.profile_for(data.get("profiles", []), str(secret.get("environment", ""))).is_empty(), "secret sortie should resolve a registered environment profile: %s" % str(secret.get("id", "")))
		if secret_missions.size() > 3:
			var seed_manifest: Dictionary = secret_missions[3]
			_expect(str(seed_manifest.get("environment_variant", "")) == "city_outskirts", "Seed Manifest should consume the authored city geography stack")
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
		_expect(source.contains("ORBITAL_STARFIELD_TILE") and source.contains("EARTH_LIMB_V2"), "upper atmosphere and orbital space should use authored sparse stars and a low near-Earth curvature layer")
		_expect(not source.contains("draw_arc") and not source.contains("var star :=") and not source.contains("draw_rect(Rect2(roundf(x)"), "orbital presentation should not regress to perfect vector arcs or one-pixel stars")
		var gameplay_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
		_expect(gameplay_file != null and gameplay_file.get_as_text().contains("fposmod(-mission_time * 12.0"), "neutral depth fallback should preserve forward world travel during environment handoff")
		_expect(source.contains("COAST_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence"), "coastal benchmark should assemble registered authored geography chunks")
		_expect(source.contains("REFINERY_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence"), "industrial benchmark should assemble registered authored refinery geography chunks")
		_expect(source.contains("SEA_DEEP_ANIMATION") and source.contains("SEA_SURFACE_ANIMATION") and source.contains("SEA_FOAM_ANIMATION"), "open-water benchmark should use independent temporal material families")
		_expect(source.contains("DESERT_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence"), "desert benchmark should assemble registered authored battlefield geography chunks")
		_expect(source.contains("RIVER_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence"), "river benchmark should assemble registered authored floodplain geography chunks")
		_expect(source.contains("MOUNTAIN_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence(surface, MOUNTAIN_GEOGRAPHY_CHUNKS"), "mountain benchmark should use three forward-scrolling authored districts")
		_expect(source.contains("HARBOR_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence"), "harbor benchmark should assemble registered authored naval-port geography chunks")
		_expect(source.contains("CLOUD_TOP_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence(surface, CLOUD_TOP_GEOGRAPHY_CHUNKS"), "high-altitude benchmark should use three forward-scrolling authored cloud districts")
		_expect(source.contains("ORBITAL_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence(surface, ORBITAL_GEOGRAPHY_CHUNKS"), "orbital benchmark should use three forward-scrolling authored infrastructure districts")
		_expect(source.contains("CITY_GEOGRAPHY_CHUNKS") and source.contains("_draw_vertical_chunk_sequence(surface, CITY_GEOGRAPHY_CHUNKS"), "city belt should use three forward-scrolling authored districts")
		_expect(source.contains("MACHINE_FURNACE"), "machine-war reveal should use its authored autonomous-foundry raster master")
		_expect(source.contains("_draw_vertical_loop"), "coastal benchmark should scroll its authored plate without exposed seams")
		_expect(source.contains("Restrained moving wakes"), "coastal benchmark should retain subdued open-water motion cues")
		for cloud_family in ["CLOUD_LOW", "CLOUD_MID", "CLOUD_HIGH"]:
			_expect(source.contains(cloud_family), "environment renderer should retain authored %s family" % cloud_family)
		_expect(source.contains("CIRRUS_FAR") and source.contains("CONTRAIL_NEAR") and source.contains("ANVIL_SHADOW") and source.contains("_draw_high_atmosphere_far") and source.contains("_draw_high_atmosphere_near"), "high-altitude environments should retain independent authored far-weather and near-speed layers")
		var atmosphere_sizes := {"cirrus_a":Vector2(192,48),"cirrus_b":Vector2(192,48),"contrail_long":Vector2(12,112),"contrail_short":Vector2(10,88),"contrail_broken":Vector2(12,104),"anvil_shadow":Vector2(192,80)}
		for atmosphere_asset in atmosphere_sizes:
			var atmosphere_texture := load("res://assets/runtime/environments/high_atmosphere_motion/%s.png" % atmosphere_asset)
			_expect(atmosphere_texture is Texture2D and atmosphere_texture.get_size() == atmosphere_sizes[atmosphere_asset], "high-atmosphere motion sprite should retain registered geometry: %s" % atmosphere_asset)
		_expect(FileAccess.file_exists("res://assets/source/environments/high_atmosphere_motion_manifest.json"), "high-atmosphere motion source/runtime manifest should exist")
		_expect(not source.substr(source.find("func _draw_clouds"), source.length() - source.find("func _draw_clouds")).contains("draw_colored_polygon"), "foreground clouds should not regress to polygon lozenges")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/coast/coastal_strike_zone_loop_v1.png"), "coastal runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/coast_chunks/coast_geography_manifest.json"), "coast geography source/build/assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_coast_geography_art.ps1") and FileAccess.file_exists("res://tools/test_environment_seams.ps1"), "coast geography should retain reproducible build and seam-gate tooling")
		var coast_geography_manifest = ContentCatalog.load_json("res://assets/source/environments/coast_chunks/coast_geography_manifest.json")
		_expect(typeof(coast_geography_manifest) == TYPE_DICTIONARY and coast_geography_manifest.get("chunks", []).size() == 3, "coast geography manifest should register three distinct 1024px sections")
		var coast_geography_names := ["seawall_run", "defended_inlet", "reef_cliffs"]
		var coast_geography_images: Array[Image] = []
		for chunk_name in coast_geography_names:
			var geography_texture := load("res://assets/runtime/environments/coast_chunks/%s.png" % chunk_name) as Texture2D
			_expect(geography_texture != null and geography_texture.get_size() == Vector2(640,1024), "coast geography chunk should retain native 640x1024 registration: %s" % chunk_name)
			if geography_texture != null:
				coast_geography_images.append(geography_texture.get_image())
		for chunk_index in range(coast_geography_images.size()):
			var outgoing: Image = coast_geography_images[chunk_index]
			var incoming: Image = coast_geography_images[(chunk_index + 1) % coast_geography_images.size()]
			for sample_x in range(0,640,16):
				_expect(outgoing.get_pixel(sample_x,1023).is_equal_approx(incoming.get_pixel(sample_x,0)), "adjacent coast chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		_expect(FileAccess.file_exists("res://assets/source/environments/modular_coast/modular_coast_kit_manifest.json"), "modular coast kit should register finite chunks, continuous loops and edge-animation families")
		var modular_coast_kit = ContentCatalog.load_json("res://assets/source/environments/modular_coast/modular_coast_kit_manifest.json")
		_expect(typeof(modular_coast_kit) == TYPE_DICTIONARY and str(modular_coast_kit.get("status", "")).contains("runtime_v1_complete"), "modular coast source contract should identify its completed runtime instead of advertising stale pending work")
		var modular_coast_source := load("res://assets/source/environments/modular_coast/coast_construction_kit_source_v1.png")
		_expect(modular_coast_source is Texture2D and modular_coast_source.get_size() == Vector2(1536,1024), "modular coast source sheet should retain registered production geometry")
		if modular_coast_source is Texture2D:
			var coast_source_image: Image = modular_coast_source.get_image()
			_expect(coast_source_image.detect_alpha() != Image.ALPHA_NONE, "modular coast source sheet must retain genuine transparent alpha")
		var coast_runtime_manifest = ContentCatalog.load_json("res://assets/source/environments/modular_coast/modular_coast_runtime_manifest.json")
		_expect(typeof(coast_runtime_manifest) == TYPE_DICTIONARY, "modular coast runtime manifest should load")
		if typeof(coast_runtime_manifest) == TYPE_DICTIONARY:
			var coast_chunks: Array = coast_runtime_manifest.get("finite_chunks", [])
			_expect(coast_chunks.size() == 24, "modular coast kit should expose 24 finite authored chunk families")
			for chunk_name in coast_chunks:
				var chunk_texture := load("res://assets/runtime/environments/modular_coast/%s.png" % chunk_name)
				_expect(chunk_texture is Texture2D, "modular coast runtime chunk should load: %s" % chunk_name)
				if chunk_texture is Texture2D:
					_expect(chunk_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "modular coast chunk must retain transparency: %s" % chunk_name)
		for frame_index in range(3):
			var shore_frame := load("res://assets/runtime/environments/modular_coast/shore_wash_%d.png" % frame_index)
			_expect(shore_frame is Texture2D and shore_frame.get_size() == Vector2(288,80), "shore-wash animation frame should retain 288x80 registration: %d" % frame_index)
			var vertical_shore_frame := load("res://assets/runtime/environments/modular_coast/shore_wash_vertical_v2_%d.png" % frame_index)
			_expect(vertical_shore_frame is Texture2D and vertical_shore_frame.get_size() == Vector2(16,288), "vertical shore-wash animation frame should retain a narrow one-sided 16x288 coastline registration: %d" % frame_index)
		for frame_index in range(4):
			var impact_frame := load("res://assets/runtime/environments/modular_coast/breakwater_impact_%d.png" % frame_index)
			_expect(impact_frame is Texture2D and impact_frame.get_size() == Vector2(120,120), "breakwater-impact animation frame should retain 120x120 registration: %d" % frame_index)
		_expect(source.contains("COAST_FINITE_CHUNKS") and source.contains("_draw_modular_coast_pass"), "coastal renderer should compose finite registered construction chunks over the continuous terrain bed")
		_expect(source.contains('"role": "land"') and source.contains('"role": "shore"') and source.contains('var texture_index := int(slot["chunk"])'), "coastal detail slots should declare deliberate land and shore roles")
		_expect(not source.contains('int(slot["chunk"]) + seed'), "mission seed must not substitute incompatible coast construction assets into registered slots")
		_expect(is_zero_approx(EnvironmentRules.high_atmosphere_mix("mid")) and is_equal_approx(EnvironmentRules.high_atmosphere_mix("high"), 1.0), "stratospheric cirrus should enter through the high-altitude transition instead of reading as flat streaks in the mid-altitude combat lane")
		_expect(source.contains("shore_wash_vertical_v2_0.png") and source.contains("COAST_SHORE_WASH") and source.contains("floor(t * 6.0)"), "coastal renderer should consume held six-fps shoreline wash aligned with the vertical coast")
		_expect(source.contains("COAST_BREAKWATER_IMPACT") and source.contains("floor(t * 8.0)"), "coastal renderer should consume held eight-fps breakwater impact animation")
		_expect(source.contains("cycle := 1960.0"), "finite coast modules should use a long authored world cycle instead of obvious screen-height wallpaper repetition")
		_expect(source.contains("_draw_texture_rect_clipped") and source.contains("destination.intersection(clip_rect)"), "finite coast sprites and edge animation must clip cleanly beneath the HUD viewport")
		_expect(FileAccess.file_exists("res://tools/build_modular_coast_art.ps1"), "modular coast runtime crops should remain reproducible through the registered builder")
		_expect(FileAccess.file_exists("res://assets/source/environments/coast_asset_manifest.json"), "coastal source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/cloud_asset_manifest.json"), "cloud source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/industrial/refinery_night_loop_v1.png"), "industrial runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/refinery_chunks/refinery_geography_manifest.json"), "refinery geography source/build/assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_refinery_geography_art.ps1"), "refinery geography should retain a reproducible registered builder")
		var refinery_geography_manifest = ContentCatalog.load_json("res://assets/source/environments/refinery_chunks/refinery_geography_manifest.json")
		_expect(typeof(refinery_geography_manifest) == TYPE_DICTIONARY and refinery_geography_manifest.get("chunks", []).size() == 3, "refinery geography manifest should register three distinct 1024px sections")
		var refinery_geography_names := ["tank_farm", "cracking_corridor", "rail_loading"]
		var refinery_geography_images: Array[Image] = []
		for chunk_name in refinery_geography_names:
			var geography_texture := load("res://assets/runtime/environments/refinery_chunks/%s.png" % chunk_name) as Texture2D
			_expect(geography_texture != null and geography_texture.get_size() == Vector2(640,1024), "refinery geography chunk should retain native 640x1024 registration: %s" % chunk_name)
			if geography_texture != null:
				refinery_geography_images.append(geography_texture.get_image())
		for chunk_index in range(refinery_geography_images.size()):
			var outgoing: Image = refinery_geography_images[chunk_index]
			var incoming: Image = refinery_geography_images[(chunk_index + 1) % refinery_geography_images.size()]
			for sample_x in range(0,640,16):
				_expect(outgoing.get_pixel(sample_x,1023).is_equal_approx(incoming.get_pixel(sample_x,0)), "adjacent refinery chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		_expect(FileAccess.file_exists("res://assets/source/environments/industrial_asset_manifest.json"), "industrial source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/modular_refinery/modular_refinery_manifest.json"), "modular refinery RAW_ART, clean source and runtime contract should exist")
		_expect(FileAccess.file_exists("res://tools/build_modular_refinery_art.ps1"), "modular refinery runtime extraction should remain reproducible")
		var refinery_raw := load("res://assets/source/environments/modular_refinery/refinery_construction_kit_raw_v1.png") as Texture2D
		var refinery_clean := load("res://assets/source/environments/modular_refinery/refinery_construction_kit_source_v1.png") as Texture2D
		_expect(refinery_raw != null and refinery_clean != null and refinery_raw.get_size() == Vector2(1672,941) and refinery_clean.get_size() == Vector2(1672,941), "modular refinery RAW_ART and clean source should retain identical registered geometry")
		if refinery_raw != null and refinery_clean != null:
			_expect(refinery_raw.get_image().detect_alpha() == Image.ALPHA_NONE, "untouched refinery RAW_ART should preserve the generated baked background for provenance")
			_expect(refinery_clean.get_image().detect_alpha() != Image.ALPHA_NONE, "finished refinery source should replace fake checkerboard with genuine RGBA transparency")
		for refinery_chunk in ["tank_cluster_quad", "cracking_tower_b", "pipe_rack_long", "generator_house", "cooling_bank", "transformer_yard", "maintenance_gantry", "oil_stains"]:
			var refinery_texture := load("res://assets/runtime/environments/modular_refinery/%s.png" % refinery_chunk) as Texture2D
			_expect(refinery_texture != null and refinery_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "modular refinery finite chunk should retain genuine alpha: %s" % refinery_chunk)
		for refinery_sequence in {"steam":6,"flare":5,"smoke":5}:
			for frame_index in range(int({"steam":6,"flare":5,"smoke":5}[refinery_sequence])):
				var refinery_frame := load("res://assets/runtime/environments/modular_refinery/%s_%d.png" % [refinery_sequence,frame_index]) as Texture2D
				_expect(refinery_frame != null and refinery_frame.get_size() == Vector2(96,140), "modular refinery animation should retain shared registration: %s %d" % [refinery_sequence,frame_index])
		_expect(source.contains("REFINERY_FINITE_CHUNKS") and source.contains("_draw_modular_refinery_pass"), "industrial renderer should compose physical finite refinery machinery")
		_expect(source.contains("REFINERY_STEAM") and source.contains("floor(t * 5.0)") and source.contains("REFINERY_FLARE") and source.contains("floor(t * 8.0)") and source.contains("REFINERY_SMOKE") and source.contains("floor(t * 4.0)"), "industrial renderer should consume deliberate held steam, flare and heavy-smoke animation")
		_expect(not source.substr(source.find("func _draw_industrial"), source.find("func _draw_water") - source.find("func _draw_industrial")).contains("REFINERY_DETAIL_TILE"), "industrial gameplay should not regress to schematic circuit-line overlays")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/water/storm_sea_loop_v1.png"), "open-water runtime master should exist")
		_expect(not source.contains("STORM_SEA") and not source.contains("master_scroll"), "open-water renderer must not hide a recognizable 720px painting beneath the material stack")
		_expect(FileAccess.file_exists("res://assets/source/environments/open_water/open_water_runtime_manifest.json"), "open-water v3 source/runtime assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_open_water_art.ps1"), "open-water temporal and finite sprite build should remain reproducible")
		var open_water_manifest = ContentCatalog.load_json("res://assets/source/environments/open_water/open_water_runtime_manifest.json")
		_expect(typeof(open_water_manifest) == TYPE_DICTIONARY and open_water_manifest.get("finite_events", []).size() == 12, "open-water manifest should register twelve sparse finite event families")
		for water_family in {"deep":4,"surface":4,"foam":6}:
			for frame_index in range(int({"deep":4,"surface":4,"foam":6}[water_family])):
				var water_frame := load("res://assets/runtime/environments/open_water_animation/%s_%d.png" % [water_family,frame_index]) as Texture2D
				_expect(water_frame != null and water_frame.get_size() == Vector2(640,512), "temporal water frame should retain seamless 640x512 registration: %s %d" % [water_family,frame_index])
				if water_frame != null:
					var water_image := water_frame.get_image()
					for sample_x in range(0,640,32):
						_expect(water_image.get_pixel(sample_x,0).is_equal_approx(water_image.get_pixel(sample_x,511)), "temporal water frame must close its vertical seam: %s %d x=%d" % [water_family,frame_index,sample_x])
		for finite_name in open_water_manifest.get("finite_events", []):
			var finite_texture := load("res://assets/runtime/environments/open_water_finite/%s.png" % finite_name) as Texture2D
			_expect(finite_texture != null and finite_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "finite open-water event must retain genuine transparency: %s" % finite_name)
		_expect(source.contains("_draw_open_water_finite") and source.contains("cycle := 2380.0"), "open-water finite events should use a mission-seeded cycle independent from water materials")
		_expect(source.contains("floor(t * 4.0)") and source.contains("floor(t * 6.0)") and source.contains("floor(t * 8.0)"), "deep swell, surface chop and foam should retain deliberate held temporal exposure rates")
		_expect(FileAccess.file_exists("res://assets/source/environments/water_asset_manifest.json"), "open-water source manifest should exist")
		for layer_path in [
			"sea_deep_tile.png", "sea_surface_tile.png", "sea_foam_tile.png", "coast_surface_tile.png", "cloud_shadow_tile.png", "cloud_mist_tile.png",
			"refinery_detail_tile.png", "desert_dust_tile.png", "river_current_tile.png", "mountain_weather_tile.png",
			"harbor_reflection_tile.png", "city_light_tile.png", "furnace_activity_tile.png", "orbital_debris_tile.png"
		]:
			var layer_texture := load("res://assets/runtime/environments/layers/%s" % layer_path)
			_expect(layer_texture is Texture2D and layer_texture.get_height() == 512, "seamless environment layer should retain 512px vertical registration: %s" % layer_path)
			if layer_texture is Texture2D:
				var layer_image: Image = layer_texture.get_image()
				for sample_x in range(0,layer_image.get_width(),32):
					_expect(layer_image.get_pixel(sample_x,0).is_equal_approx(layer_image.get_pixel(sample_x,layer_image.get_height()-1)), "environment tile must close its vertical seam exactly: %s x=%d" % [layer_path,sample_x])
		_expect(source.contains("SEA_DEEP_ANIMATION") and source.contains("SEA_SURFACE_ANIMATION") and source.contains("SEA_FOAM_ANIMATION"), "environment renderer should use independent authored temporal sea depth layers")
		_expect(source.contains("_draw_cloud_bank_shadow") and source.contains("t * wind"), "discrete cloud banks should retain registered undercast shadows and independent wind shear")
		_expect(not source.contains("CLOUD_SHADOW_TILE") and not source.contains("CLOUD_MIST_TILE"), "cloud depth should not regress to opaque full-field plates that reveal horizontal bands at hypersonic speed")
		for biome_layer in ["REFINERY_DETAIL_TILE", "DESERT_DUST_GUST", "RIVER_CURRENT_ANIMATION", "MOUNTAIN_WEATHER_ANIMATION", "HARBOR_REFLECTION_ANIMATION", "CITY_ACTIVITY_ANIMATION", "FURNACE_ACTIVITY_TILE", "ORBITAL_DEBRIS_ANIMATION"]:
			_expect(source.contains(biome_layer), "environment renderer should use authored biome detail layer %s" % biome_layer)
		_expect(source.contains("deep_scroll") and source.contains("surface_scroll") and source.contains("foam_scroll"), "environment sea depth layers should scroll independently")
		_expect(source.contains("PARALLAX_ACCENTS") and source.contains("COAST_WAKE") and source.contains("RAIN_ACCENTS"), "environment motion should use authored depth glints, wakes and weather sprites")
		_expect(source.contains("LANDMARKS") and source.contains("_draw_landmarks") and source.contains("_mission_seed"), "environment renderer should layer sparse deterministic mission landmarks over seamless biome plates")
		_expect(source.contains("LANDMARK_FX_FRAMES") and source.contains("floor(t * 4.0)"), "mission landmarks should consume deliberate four-fps held sprite animation")
		var landmark_names := ["coastal_battery", "refinery_stack", "storm_platform", "desert_airstrip", "river_bridge", "mountain_radar", "harbor_cranes", "city_rail_hub", "machine_gantry", "weather_relay", "orbital_truss"]
		for landmark_name in landmark_names:
			var landmark := load("res://assets/runtime/environments/landmarks/%s.png" % landmark_name)
			_expect(landmark is Texture2D and landmark.get_size() == Vector2(128,160), "mission landmark should retain registered 128x160 sprite geometry: %s" % landmark_name)
			if landmark is Texture2D:
				var landmark_image: Image = landmark.get_image()
				var landmark_palette: Dictionary = {}
				var binary_alpha := true
				for sample_y in range(landmark_image.get_height()):
					for sample_x in range(landmark_image.get_width()):
						var pixel := landmark_image.get_pixel(sample_x, sample_y)
						landmark_palette[pixel.to_rgba32()] = true
						if pixel.a > 0.0 and pixel.a < 1.0:
							binary_alpha = false
				_expect(landmark_palette.size() <= 31, "mission landmark should retain a disciplined VGA-size palette: %s" % landmark_name)
				_expect(binary_alpha, "mission landmark should retain crisp binary alpha edges: %s" % landmark_name)
		var storm_platform_v2 := load("res://assets/runtime/environments/landmarks/storm_platform_v2.png") as Texture2D
		_expect(storm_platform_v2 != null and storm_platform_v2.get_size() == Vector2(128,160), "open-water landmark should use the registered v2 offshore platform sprite")
		_expect(source.contains('"water": preload("res://assets/runtime/environments/landmarks/storm_platform_v2.png")') and source.contains('family == "water"'), "water landmark should select its physically engineered v2 art and world-scale treatment")
		_expect(FileAccess.file_exists("res://assets/source/environments/landmark_asset_manifest.json"), "mission landmark source/runtime manifest should exist")
		for landmark_family in ["coast", "industrial", "water", "desert_front", "river_corridor", "mountain_radar", "night_harbor", "city_outskirts", "machine_furnace", "cloud_top", "orbital"]:
			for frame_index in range(4):
				var landmark_fx := load("res://assets/runtime/environments/landmark_animation/%s_%d.png" % [landmark_family, frame_index])
				_expect(landmark_fx is Texture2D and landmark_fx.get_size() == Vector2(128,160), "landmark FX frame should retain 128x160 registration: %s %d" % [landmark_family, frame_index])
		var parallax_section := source.substr(source.find("func _draw_parallax"), source.find("func _coast_x") - source.find("func _draw_parallax"))
		var coast_section := source.substr(source.find("func _draw_coast"), source.find("func _draw_vertical_loop") - source.find("func _draw_coast"))
		var water_section := source.substr(source.find("func _draw_water"), source.find("func _draw_desert_front") - source.find("func _draw_water"))
		_expect(not parallax_section.contains("draw_line") and not coast_section.contains("draw_line") and not water_section.contains("draw_line"), "surface motion should not regress to one-pixel procedural lines")
		var motion_sizes := {"parallax_far":Vector2(32,8),"parallax_mid":Vector2(48,8),"parallax_near":Vector2(64,8),"coast_wake":Vector2(40,10),"rain_a":Vector2(16,24),"rain_b":Vector2(16,24)}
		for motion_name in motion_sizes:
			var motion_texture := load("res://assets/runtime/environments/motion/%s.png" % motion_name)
			_expect(motion_texture is Texture2D and motion_texture.get_size() == motion_sizes[motion_name], "environment motion sprite should retain registered geometry: %s" % motion_name)
		_expect(FileAccess.file_exists("res://assets/source/environments/motion_accent_manifest.json"), "environment motion source/runtime manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/layered_scroll_asset_manifest.json"), "layered scrolling environment manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/desert/desert_front_loop_v1.png"), "desert runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/desert_asset_manifest.json"), "desert source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/desert_chunks/desert_geography_manifest.json"), "desert geography source/build/assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_desert_geography_art.ps1"), "desert geography should retain a reproducible registered builder")
		var desert_geography_manifest = ContentCatalog.load_json("res://assets/source/environments/desert_chunks/desert_geography_manifest.json")
		_expect(typeof(desert_geography_manifest) == TYPE_DICTIONARY and desert_geography_manifest.get("chunks", []).size() == 3, "desert geography manifest should register three distinct 1024px sections")
		var desert_geography_names := ["armour_approach", "wadi_crossing", "logistics_belt"]
		var desert_geography_images: Array[Image] = []
		for chunk_name in desert_geography_names:
			var geography_texture := load("res://assets/runtime/environments/desert_chunks/%s.png" % chunk_name) as Texture2D
			_expect(geography_texture != null and geography_texture.get_size() == Vector2(640,1024), "desert geography chunk should retain native 640x1024 registration: %s" % chunk_name)
			if geography_texture != null:
				desert_geography_images.append(geography_texture.get_image())
		for chunk_index in range(desert_geography_images.size()):
			var outgoing: Image = desert_geography_images[chunk_index]
			var incoming: Image = desert_geography_images[(chunk_index + 1) % desert_geography_images.size()]
			for sample_x in range(0,640,16):
				_expect(outgoing.get_pixel(sample_x,1023).is_equal_approx(incoming.get_pixel(sample_x,0)), "adjacent desert chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var dust_frame := load("res://assets/runtime/environments/desert_dust_animation/gust_%d.png" % frame_index) as Texture2D
			_expect(dust_frame != null and dust_frame.get_size() == Vector2(160,96), "desert dust gust should retain shared 160x96 registration: %d" % frame_index)
			if dust_frame != null:
				_expect(dust_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "desert dust gust must retain genuine alpha: %d" % frame_index)
		_expect(source.contains("DESERT_DUST_GUST") and source.contains("floor(t * 6.0)") and source.contains("1420.0"), "desert renderer should use sparse held dust-gust animation on a non-screen-height world cycle")
		_expect(not source.contains("_draw_vertical_loop(surface, DESERT_DUST_TILE"), "desert presentation must not regress to full-screen ruler-line dust tiling")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/river/river_corridor_loop_v1.png"), "river runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/river_asset_manifest.json"), "river source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/river_chunks/river_geography_manifest.json"), "river geography/current source and assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_river_geography_art.ps1"), "river geography should retain a reproducible registered builder")
		_expect(FileAccess.file_exists("res://tools/build_river_bridge_art.ps1"), "river bridge should retain a reproducible source finisher")
		var river_manifest = ContentCatalog.load_json("res://assets/source/environments/river_chunks/river_geography_manifest.json")
		_expect(typeof(river_manifest) == TYPE_DICTIONARY and river_manifest.get("chunks", []).size() == 3, "river manifest should register three distinct 1024px sections")
		var river_names := ["floodplain", "defended_crossing", "industrial_bend"]
		var river_images: Array[Image] = []
		for chunk_name in river_names:
			var river_texture := load("res://assets/runtime/environments/river_chunks/%s.png" % chunk_name) as Texture2D
			_expect(river_texture != null and river_texture.get_size() == Vector2(640,1024), "river chunk should retain native 640x1024 registration: %s" % chunk_name)
			if river_texture != null: river_images.append(river_texture.get_image())
		for chunk_index in range(river_images.size()):
			for sample_x in range(0,640,16):
				_expect(river_images[chunk_index].get_pixel(sample_x,1023).is_equal_approx(river_images[(chunk_index+1)%river_images.size()].get_pixel(sample_x,0)), "adjacent river chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var current_frame := load("res://assets/runtime/environments/river_current_animation/current_%d.png" % frame_index) as Texture2D
			_expect(current_frame != null and current_frame.get_size() == Vector2(112,220), "river current should retain shared 112x220 registration: %d" % frame_index)
			if current_frame != null: _expect(current_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "river current frame must retain genuine alpha: %d" % frame_index)
		_expect(source.contains("RIVER_CURRENT_ANIMATION") and source.contains("floor(t * 6.0)") and source.contains('float(slot["y"]) + scroll'), "river current should use held frames registered to forward-moving geography world coordinates")
		_expect(not source.contains("_draw_vertical_loop(surface, RIVER_CURRENT_TILE"), "river presentation must not regress to full-screen straight-line current tiling")
		_expect(not source.contains('family in ["coast", "industrial", "river_corridor"'), "river geography should allow its complete bridge landmark to remain a separate layer")
		_expect(source.contains("_draw_registered_river_bridge"), "river bridge should use geography-registered placement")
		_expect(source.contains("crossing_world_y := 1594.0"), "river bridge should align to defended-crossing abutments")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/mountain/mountain_radar_loop_v1.png"), "mountain runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/mountain_asset_manifest.json"), "mountain source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/mountain_chunks/mountain_geography_manifest.json"), "mountain geography/weather/layered-radar manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_mountain_geography_art.ps1"), "mountain geography should retain a reproducible registered builder")
		_expect(FileAccess.file_exists("res://tools/build_mountain_radar_art.ps1"), "layered mountain radar should retain a reproducible source finisher")
		var mountain_manifest = ContentCatalog.load_json("res://assets/source/environments/mountain_chunks/mountain_geography_manifest.json")
		_expect(typeof(mountain_manifest) == TYPE_DICTIONARY and mountain_manifest.get("chunks", []).size() == 3, "mountain manifest should register three distinct 1024px pass districts")
		var mountain_names := ["switchback_pass", "radar_service_valley", "ice_cliff_corridor"]
		var mountain_images: Array[Image] = []
		for chunk_name in mountain_names:
			var mountain_texture := load("res://assets/runtime/environments/mountain_chunks/%s.png" % chunk_name) as Texture2D
			_expect(mountain_texture != null and mountain_texture.get_size() == Vector2(640,1024), "mountain chunk should retain native 640x1024 registration: %s" % chunk_name)
			if mountain_texture != null: mountain_images.append(mountain_texture.get_image())
		for chunk_index in range(mountain_images.size()):
			for sample_x in range(0,640,16):
				_expect(mountain_images[chunk_index].get_pixel(sample_x,1023).is_equal_approx(mountain_images[(chunk_index+1)%mountain_images.size()].get_pixel(sample_x,0)), "adjacent mountain chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var shear_frame := load("res://assets/runtime/environments/mountain_weather_animation/shear_%d.png" % frame_index) as Texture2D
			_expect(shear_frame != null and shear_frame.get_size() == Vector2(224,144), "mountain weather should retain shared 224x144 registration: %d" % frame_index)
			if shear_frame != null: _expect(shear_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "mountain weather frame must retain genuine alpha: %d" % frame_index)
		var radar_component_sizes := {"radar_base":Vector2(144,160), "radar_dish":Vector2(128,144)}
		for component_name in radar_component_sizes:
			var component := load("res://assets/runtime/environments/mountain_radar_layered/%s.png" % component_name) as Texture2D
			_expect(component != null and component.get_size() == radar_component_sizes[component_name], "mountain radar component should retain registered geometry: %s" % component_name)
			if component != null:
				var component_image := component.get_image()
				var component_palette := {}
				var binary_component_alpha := true
				for y in range(component_image.get_height()):
					for x in range(component_image.get_width()):
						var pixel := component_image.get_pixel(x,y)
						component_palette[Color(pixel.r,pixel.g,pixel.b,1.0).to_html(false)] = true
						if pixel.a > 0.0 and pixel.a < 1.0: binary_component_alpha = false
				_expect(component_palette.size() <= 31, "mountain radar component should retain disciplined palette: %s" % component_name)
				_expect(binary_component_alpha, "mountain radar component should retain binary alpha: %s" % component_name)
		_expect(source.contains("MOUNTAIN_WEATHER_ANIMATION") and source.contains("floor(t * 6.0)") and source.contains('float(slot["y"]) + scroll'), "mountain snow shear should use held frames registered to forward-moving geography coordinates")
		_expect(not source.contains("_draw_vertical_loop(surface, MOUNTAIN_WEATHER_TILE"), "mountain presentation must not regress to a full-screen schematic weather tile")
		_expect(source.contains("_draw_registered_mountain_radar") and source.contains("radar_world_y := 1288.0") and source.contains("surface.draw_set_transform(center.round(), t * 0.32"), "mountain radar should use a registered stationary base and independently tracking dish")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/harbor/night_harbor_loop_v1.png"), "harbor runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/harbor_asset_manifest.json"), "harbor source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/harbor_chunks/harbor_geography_manifest.json"), "harbor geography/reflection source and assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_harbor_geography_art.ps1"), "harbor geography should retain a reproducible registered builder")
		_expect(FileAccess.file_exists("res://tools/build_harbor_crane_art.ps1"), "harbor crane should retain a reproducible source finisher")
		var harbor_manifest = ContentCatalog.load_json("res://assets/source/environments/harbor_chunks/harbor_geography_manifest.json")
		_expect(typeof(harbor_manifest) == TYPE_DICTIONARY and harbor_manifest.get("chunks", []).size() == 3, "harbor manifest should register three distinct 1024px port districts")
		var harbor_names := ["outer_breakwater", "repair_basin", "command_docks"]
		var harbor_images: Array[Image] = []
		for chunk_name in harbor_names:
			var harbor_texture := load("res://assets/runtime/environments/harbor_chunks/%s.png" % chunk_name) as Texture2D
			_expect(harbor_texture != null and harbor_texture.get_size() == Vector2(640,1024), "harbor chunk should retain native 640x1024 registration: %s" % chunk_name)
			if harbor_texture != null: harbor_images.append(harbor_texture.get_image())
		for chunk_index in range(harbor_images.size()):
			for sample_x in range(0,640,16):
				_expect(harbor_images[chunk_index].get_pixel(sample_x,1023).is_equal_approx(harbor_images[(chunk_index+1)%harbor_images.size()].get_pixel(sample_x,0)), "adjacent harbor chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var reflection_frame := load("res://assets/runtime/environments/harbor_reflection_animation/reflection_%d.png" % frame_index) as Texture2D
			_expect(reflection_frame != null and reflection_frame.get_size() == Vector2(128,224), "harbor reflection should retain shared 128x224 registration: %d" % frame_index)
			if reflection_frame != null: _expect(reflection_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "harbor reflection frame must retain genuine alpha: %d" % frame_index)
		_expect(source.contains("HARBOR_REFLECTION_ANIMATION") and source.contains("floor(t * 6.0)") and source.contains('float(slot["y"]) + scroll'), "harbor reflections should use held frames registered to forward-moving geography world coordinates")
		_expect(not source.contains("_draw_vertical_loop(surface, HARBOR_REFLECTION_TILE"), "harbor presentation must not regress to full-screen schematic reflection tiling")
		_expect(source.contains("_draw_registered_harbor_crane") and source.contains("crane_world_y := 1500.0"), "harbor crane should align to the repair-basin quay")
		_expect(source.contains("fposmod(-source_y") and source.contains("_world_speed_multiplier()"), "positive world speed should move tiled and chunked geography downward past the player")
		_expect(source.contains("t * 21.0 * world_scale") and source.contains("t * speed * world_scale"), "coastal wakes and discrete cloud banks should accelerate with hypersonic world travel")
		_expect(not source.contains("density * 8.0) * world_scale") and not source.contains("density * 14.0) * world_scale"), "opaque full-field cloud plates should stay retired instead of accelerating into visible bands")
		_expect(source.contains("lerpf(1.0, 3.6, hypersonic_ratio)"), "hypersonic environment presentation should stretch authored motion accents without blurring combat readability")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/high_atmosphere/stratospheric_cloud_deck_loop_v1.png"), "stratospheric runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/high_atmosphere_asset_manifest.json"), "stratospheric source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/cloud_top_chunks/cloud_top_geography_manifest.json"), "cloud-top geography/turbulence assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_cloud_top_geography_art.ps1"), "cloud-top geography should retain a reproducible registered builder")
		var cloud_top_manifest = ContentCatalog.load_json("res://assets/source/environments/cloud_top_chunks/cloud_top_geography_manifest.json")
		_expect(typeof(cloud_top_manifest) == TYPE_DICTIONARY and cloud_top_manifest.get("chunks", []).size() == 3, "cloud-top manifest should register three distinct 1024px atmospheric districts")
		var cloud_top_names := ["anvil_wells", "silver_breaks", "frontal_boundary"]
		var cloud_top_images: Array[Image] = []
		for chunk_name in cloud_top_names:
			var cloud_top_texture := load("res://assets/runtime/environments/cloud_top_chunks/%s.png" % chunk_name) as Texture2D
			_expect(cloud_top_texture != null and cloud_top_texture.get_size() == Vector2(640,1024), "cloud-top chunk should retain native 640x1024 registration: %s" % chunk_name)
			if cloud_top_texture != null: cloud_top_images.append(cloud_top_texture.get_image())
		for chunk_index in range(cloud_top_images.size()):
			for sample_x in range(0,640,16):
				_expect(cloud_top_images[chunk_index].get_pixel(sample_x,1023).is_equal_approx(cloud_top_images[(chunk_index+1)%cloud_top_images.size()].get_pixel(sample_x,0)), "adjacent cloud-top chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var turbulence_frame := load("res://assets/runtime/environments/cloud_top_turbulence_animation/shear_%d.png" % frame_index) as Texture2D
			_expect(turbulence_frame != null and turbulence_frame.get_size() == Vector2(256,128), "cloud-top turbulence should retain shared 256x128 registration: %d" % frame_index)
			if turbulence_frame != null: _expect(turbulence_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "cloud-top turbulence frame must retain genuine alpha: %d" % frame_index)
		_expect(source.contains("CLOUD_TOP_TURBULENCE_ANIMATION") and source.contains("floor(t * 6.0)") and source.contains('float(slot["y"]) + scroll'), "cloud-top turbulence should use held frames registered to forward-moving cloud geography coordinates")
		_expect(source.contains("t * 20.0 * _world_speed_multiplier()"), "cloud-top geography should accelerate with the shared hypersonic world-speed contract")
		_expect(source.contains("transition_mix > 0.02") and source.contains("maxf(_horizon_glow(state), transition_mix)"), "planetary curvature should appear during orbital transition rather than cutting across ordinary high-cloud combat")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/orbital/black_sky_station_loop_v1.png"), "orbital runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/orbital_asset_manifest.json"), "orbital source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/orbital_chunks/orbital_geography_manifest.json"), "orbital geography/debris/Earth-limb assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_orbital_geography_art.ps1"), "orbital geography should retain a reproducible registered builder")
		var orbital_manifest = ContentCatalog.load_json("res://assets/source/environments/orbital_chunks/orbital_geography_manifest.json")
		_expect(typeof(orbital_manifest) == TYPE_DICTIONARY and orbital_manifest.get("chunks", []).size() == 3, "orbital manifest should register three distinct 1024px infrastructure districts")
		var orbital_names := ["dead_lattice", "kinetic_rail_platform", "ark_industrial_approach"]
		var orbital_images: Array[Image] = []
		for chunk_name in orbital_names:
			var orbital_texture := load("res://assets/runtime/environments/orbital_chunks/%s.png" % chunk_name) as Texture2D
			_expect(orbital_texture != null and orbital_texture.get_size() == Vector2(640,1024), "orbital chunk should retain native 640x1024 registration: %s" % chunk_name)
			if orbital_texture != null: orbital_images.append(orbital_texture.get_image())
		for chunk_index in range(orbital_images.size()):
			for sample_x in range(0,640,16):
				_expect(orbital_images[chunk_index].get_pixel(sample_x,1023).is_equal_approx(orbital_images[(chunk_index+1)%orbital_images.size()].get_pixel(sample_x,0)), "adjacent orbital chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var debris_frame := load("res://assets/runtime/environments/orbital_debris_animation/debris_%d.png" % frame_index) as Texture2D
			_expect(debris_frame != null and debris_frame.get_size() == Vector2(144,144), "orbital debris should retain shared 144x144 registration: %d" % frame_index)
			if debris_frame != null: _expect(debris_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "orbital debris frame must retain genuine alpha: %d" % frame_index)
		var earth_limb_v2 := load("res://assets/runtime/environments/orbital/earth_limb_v2.png") as Texture2D
		_expect(earth_limb_v2 != null and earth_limb_v2.get_size() == Vector2(640,324), "near-Earth limb should retain full playfield registration")
		if earth_limb_v2 != null: _expect(earth_limb_v2.get_image().detect_alpha() != Image.ALPHA_NONE, "near-Earth limb must retain transparent black space above the planet")
		_expect(source.contains("ORBITAL_DEBRIS_ANIMATION") and source.contains("floor(t * 6.0)") and source.contains('float(slot["y"]) + scroll'), "orbital debris should use held frames registered to forward-moving infrastructure coordinates")
		_expect(not source.contains("_draw_vertical_loop(surface, ORBITAL_DEBRIS_TILE"), "orbital debris must not regress to a full-screen schematic tile")
		_expect(source.contains("t * 12.0 * speed_scale") and source.contains("_world_speed_multiplier()"), "orbital infrastructure should accelerate with the shared hypersonic world-speed contract")
		var orbital_layer_sizes := {"starfield_tile":Vector2(640,512),"high_atmosphere_rim":Vector2(640,208),"orbital_rim":Vector2(640,208),"earth_limb_v2":Vector2(640,324)}
		for orbital_layer in orbital_layer_sizes:
			var orbital_texture := load("res://assets/runtime/environments/orbital/%s.png" % orbital_layer)
			_expect(orbital_texture is Texture2D and orbital_texture.get_size() == orbital_layer_sizes[orbital_layer], "orbital atmosphere layer should retain registered geometry: %s" % orbital_layer)
		var starfield := load("res://assets/runtime/environments/orbital/starfield_tile.png") as Texture2D
		if starfield != null:
			var star_image := starfield.get_image()
			for sample_x in range(0,640,32):
				_expect(star_image.get_pixel(sample_x,0).is_equal_approx(star_image.get_pixel(sample_x,511)), "orbital starfield must close its vertical seam: x=%d" % sample_x)
		_expect(FileAccess.file_exists("res://assets/source/environments/orbital_atmosphere_manifest.json"), "orbital atmosphere source/runtime manifest should exist")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/city/city_outskirts_loop_v1.png"), "city runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/city_asset_manifest.json"), "city source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/city_chunks/city_geography_manifest.json"), "city geography/activity source and assembly manifest should exist")
		_expect(FileAccess.file_exists("res://tools/build_city_geography_art.ps1"), "city geography should retain a reproducible registered builder")
		_expect(FileAccess.file_exists("res://tools/build_city_rail_hub_art.ps1"), "city rail hub should retain a reproducible source finisher")
		var city_manifest = ContentCatalog.load_json("res://assets/source/environments/city_chunks/city_geography_manifest.json")
		_expect(typeof(city_manifest) == TYPE_DICTIONARY and city_manifest.get("chunks", []).size() == 3, "city manifest should register three distinct 1024px districts")
		var city_names := ["freight_belt", "flooded_underpass", "machine_foundations"]
		var city_images: Array[Image] = []
		for chunk_name in city_names:
			var city_texture := load("res://assets/runtime/environments/city_chunks/%s.png" % chunk_name) as Texture2D
			_expect(city_texture != null and city_texture.get_size() == Vector2(640,1024), "city chunk should retain native 640x1024 registration: %s" % chunk_name)
			if city_texture != null: city_images.append(city_texture.get_image())
		for chunk_index in range(city_images.size()):
			for sample_x in range(0,640,16):
				_expect(city_images[chunk_index].get_pixel(sample_x,1023).is_equal_approx(city_images[(chunk_index+1)%city_images.size()].get_pixel(sample_x,0)), "adjacent city chunks must close without a hypersonic seam: %d x=%d" % [chunk_index,sample_x])
		for frame_index in range(6):
			var activity_frame := load("res://assets/runtime/environments/city_activity_animation/activity_%d.png" % frame_index) as Texture2D
			_expect(activity_frame != null and activity_frame.get_size() == Vector2(144,208), "city activity should retain shared 144x208 registration: %d" % frame_index)
			if activity_frame != null: _expect(activity_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "city activity frame must retain genuine alpha: %d" % frame_index)
		_expect(source.contains("CITY_ACTIVITY_ANIMATION") and source.contains("floor(t * 6.0)") and source.contains('float(slot["y"]) + scroll'), "city utility activity should use held frames registered to forward-moving geography coordinates")
		_expect(not source.contains("_draw_vertical_loop(surface, CITY_LIGHT_TILE"), "city presentation must not regress to a full-screen schematic light tile")
		_expect(source.contains("_draw_registered_city_rail_hub") and source.contains("hub_world_y := 540.0"), "city rail hub should occupy one registered freight-belt coordinate")
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
		for cloud_asset in ["low_wisp_a", "low_wisp_b", "low_wisp_c", "low_wisp_d", "mid_broken_a", "mid_broken_b", "mid_broken_c", "mid_broken_d", "high_mass_a", "high_mass_b", "high_mass_c", "high_mass_d"]:
			_expect(FileAccess.file_exists("res://assets/runtime/environments/clouds/cloud_bank_%s.png" % cloud_asset), "missing authored cloud sprite %s" % cloud_asset)
		for variant_function in ["_draw_desert_front", "_draw_river_corridor", "_draw_mountain_radar", "_draw_night_harbor", "_draw_city_outskirts", "_draw_machine_furnace"]:
			_expect(source.contains(variant_function), "Sector I environment identity missing %s" % variant_function)
		_expect(not source.substr(source.find("func _draw_cloud_top"), source.find("func _draw_high_atmosphere_horizon") - source.find("func _draw_cloud_top")).contains("draw_circle"), "cloud-top renderer should use hand-shaped banks instead of circular placeholders")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('EnvironmentDirector="*res://scripts/environment_director.gd"'), "environment director should remain autoloaded")
	var gameplay_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(gameplay_file != null, "main gameplay renderer should be readable for environment fallback checks")
	if gameplay_file != null:
		var gameplay_source := gameplay_file.get_as_text()
		var gameplay_start := gameplay_source.find("func _draw_gameplay")
		var gameplay_environment_section := gameplay_source.substr(gameplay_start, gameplay_source.length() - gameplay_start)
		_expect(gameplay_environment_section.contains("NEUTRAL_DEPTH_TILE") and gameplay_environment_section.contains("draw_texture_rect_region"), "gameplay fallback should use the authored seamless neutral depth plate")
		_expect(not gameplay_environment_section.contains("draw_line"), "gameplay fallback must not regress to a scrolling programmer grid")
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
