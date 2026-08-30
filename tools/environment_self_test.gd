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
		_expect(source.contains("_draw_vertical_loop"), "coastal benchmark should scroll its authored plate without exposed seams")
		_expect(source.contains("Restrained moving wakes"), "coastal benchmark should retain subdued open-water motion cues")
		for cloud_family in ["CLOUD_LOW", "CLOUD_MID", "CLOUD_HIGH"]:
			_expect(source.contains(cloud_family), "environment renderer should retain authored %s family" % cloud_family)
		_expect(not source.substr(source.find("func _draw_clouds"), source.length() - source.find("func _draw_clouds")).contains("draw_colored_polygon"), "foreground clouds should not regress to polygon lozenges")
		_expect(FileAccess.file_exists("res://assets/runtime/environments/coast/coastal_strike_zone_loop_v1.png"), "coastal runtime master should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/coast_asset_manifest.json"), "coastal source manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/environments/cloud_asset_manifest.json"), "cloud source manifest should exist")
		for cloud_asset in ["low_wisp_a", "low_wisp_b", "mid_broken_a", "mid_broken_b", "high_mass_a", "high_mass_b"]:
			_expect(FileAccess.file_exists("res://assets/runtime/environments/clouds/cloud_bank_%s.png" % cloud_asset), "missing authored cloud sprite %s" % cloud_asset)
		for variant_function in ["_draw_desert_front", "_draw_river_corridor", "_draw_mountain_radar", "_draw_night_harbor"]:
			_expect(source.contains(variant_function), "Sector I environment identity missing %s" % variant_function)
		_expect(not source.substr(source.find("func _draw_cloud_top"), source.find("func _draw_high_atmosphere_horizon") - source.find("func _draw_cloud_top")).contains("draw_circle"), "cloud-top renderer should use hand-shaped banks instead of circular placeholders")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('EnvironmentDirector="*res://scripts/environment_director.gd"'), "environment director should remain autoloaded")
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
