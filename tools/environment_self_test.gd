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
		_expect(EnvironmentRules.parallax_speed(coast, "low", "near") > EnvironmentRules.parallax_speed(coast, "high", "near"), "low-altitude terrain parallax should move faster than high-altitude terrain")
	_expect(EnvironmentRules.ground_detail_scale("low") > EnvironmentRules.ground_detail_scale("high"), "ground detail should shrink with altitude")
	_expect(EnvironmentRules.cloud_density("high") > EnvironmentRules.cloud_density("mid"), "high altitude should carry the densest cloud treatment")
	_expect(EnvironmentRules.horizon_glow("orbital") > EnvironmentRules.horizon_glow("high"), "orbital environment should expose strongest atmospheric horizon glow")
	_expect(not EnvironmentRules.should_draw_ground_detail("orbital"), "orbital presentation should not use normal ground-detail motifs")
	var director_file := FileAccess.open("res://scripts/environment_director.gd", FileAccess.READ)
	_expect(director_file != null, "environment_director.gd should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains('layer = 2'), "environment overlay should remain below combat-support/projectile/UI layers")
		_expect(source.contains('"coast": _draw_coast') and source.contains('"industrial": _draw_industrial') and source.contains('"water": _draw_water'), "environment renderer should retain ground/naval motifs")
		_expect(source.contains('"cloud_top": _draw_cloud_top') and source.contains('"orbital": _draw_orbital'), "environment renderer should retain high/orbital motifs")
		_expect(source.contains('EnvironmentRules.cloud_density'), "environment renderer should derive clouds from altitude rules")
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
