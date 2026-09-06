extends SceneTree
const Weather = preload("res://scripts/weather_rules.gd")
const Catalog = preload("res://scripts/content_catalog.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		push_error("Weather fixture requires capture mode to isolate saves"); quit(1); return
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	await process_frame
	scene.set_process(false)
	root.get_node("StartupSequenceDirector").call("_complete")
	var environment := root.get_node("EnvironmentDirector")
	var renderer := environment.get_node("WeatherRenderer")
	var placement: Dictionary = Catalog.load_json("res://data/weather/placement.json")
	var campaign: Array = scene.get("mission_catalog")
	var secrets: Array = scene.get("secret_mission_catalog")
	check(placement.missions.size() == campaign.size() + secrets.size(), "Weather must cover all 30+6 sorties")
	for mission in campaign + secrets:
		check(placement.missions.has(mission.id), "Missing weather: " + str(mission.id))
		if mission.id in placement.orbital_exclusions:
			check(renderer.call("profile_for", mission) == "clear", "Orbital exclusion: " + str(mission.id))
	for mission in secrets:
		scene.set("active_secret_mission_id", mission.id)
		check(str(environment.call("_mission_variant", scene)) == str(mission.get("environment_variant", "")), "Secret environment variant must use its own mission")
		check(renderer.call("profile_for", scene.call("_active_mission")) == placement.missions[mission.id], "Secret weather must use its own mission")
	scene.set("active_secret_mission_id", "")
	check(is_zero_approx(Weather.altitude_weight({"current":"orbital"})), "No orbital precipitation")
	check(is_zero_approx(Weather.altitude_weight({"current":"high"})), "High altitude is above precipitation deck")
	check(is_equal_approx(Weather.altitude_weight({"transition":true,"from":"mid","to":"high","ratio":0.5}),0.3), "Altitude transition must fade smoothly")
	for id in ["drizzle", "rain", "storm"]:
		var plan: Dictionary = Catalog.load_json("res://data/weather/%s_plan.json" % id)
		for p in plan.particles:
			var start := Weather.rain_drop(p, 0.0, 0.0)
			var end := Weather.rain_drop(p, 8.0, 0.0)
			check(Vector2(start.head).distance_to(end.head) < 0.0001, "Rain time cycle closes")
			check(Vector2(start.head).distance_to(start.tail) <= 8.001, "Rain must remain shorter than bright combat tracers")
			var moved := Weather.rain_drop(p, 0.0, 0.001)
			check(Vector2(start.head).distance_to(moved.head) > 0.0, "Rain must respond to integrated travel without advancing wind time")
	var snow: Dictionary = Catalog.load_json("res://data/weather/snow_states.json")
	check(snow.frames.size() == 96, "Preserve all 96 Particle Studio exposures")
	for sample in snow.frames:
		for p in sample:
			var position := Weather.snow_position(p, 10000.0)
			check(position.y >= -8.0 and position.y < 312.0, "Snow wrapping must stay inside its offscreen margin")
	check(renderer.get("_surfaces").size() == 2, "Weather needs layers behind and ahead of aircraft")
	for surface in renderer.get("_surfaces"):
		check(surface.get_parent().clip_contents and surface.get_parent().size == Vector2(640,304), "Weather must clip before HUD and radio lanes")
	var renderer_source := FileAccess.get_file_as_string("res://scripts/weather_renderer.gd")
	check(renderer_source.contains("RAIN_VISIBILITY") and renderer_source.contains("RAIN_COLOUR"), "rain profiles should retain reviewed visibility and cool military palette")
	check(renderer_source.contains("SNOW_COLOUR") and renderer_source.contains("position + Vector2(1,1)"), "snow should retain its pale face and contrast underside over mixed terrain")
	scene.queue_free(); await process_frame
	if failures.is_empty(): print("HYPERSONIC weather self-test passed: 36 mappings, altitude fades, motion, clipping and secret context.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
