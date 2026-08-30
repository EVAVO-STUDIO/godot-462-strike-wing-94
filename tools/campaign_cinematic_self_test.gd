extends SceneTree

const ALLOWED_ROLES := ["observation", "anticipation", "action", "consequence"]
const ALLOWED_CAMERAS := ["locked", "pan", "track"]
const ALLOWED_BRIDGES := ["environmental", "prelap", "carry", "hard silence"]
const PLATES := ["s2_dead_refinery", "s2_factory_awakens", "s2_city_warning", "s3_weather_ceiling", "s3_phase_protocol", "s3_ark_reveal", "s3_authorized", "end_ark_fall", "end_reentry", "end_city_silence", "end_watch", "end_title_sky"]
const SPRITES := ["salvage_mech", "drone_hunter", "vx94_fighter", "vx94_bomber", "phase_array", "machine_ark"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var cinematic := root.get_node_or_null("CampaignCinematicDirector")
	_expect(cinematic != null, "campaign cinematic autoload should exist", failures)
	if cinematic != null:
		_expect(not bool(cinematic.call("intercept_ending", "m01_coastal_intercept")), "ordinary mission results should not open the ending", failures)
		_expect(bool(cinematic.call("intercept_ending", "m12_machine_ark")), "Machine Ark result should open the campaign ending", failures)
		_expect(bool(cinematic.call("cinematic_active")), "campaign ending should remain active until completed or skipped", failures)
		cinematic.call("_finish")
		_expect(not bool(cinematic.call("intercept_ending", "m12_machine_ark")), "campaign ending should play once per session", failures)
	var data := _load_json("res://data/cinematics.json")
	var missions := _load_json("res://data/missions.json")
	var mission_ids: Array[String] = []
	for mission in missions.get("missions", []):
		if typeof(mission) == TYPE_DICTIONARY:
			mission_ids.append(str(mission.get("id", "")))
	var sequences: Array = data.get("sequences", [])
	_expect(sequences.size() == 3, "campaign should retain two sector transitions and an ending", failures)
	var triggers: Array[String] = []
	var used_plates: Dictionary = {}
	var animated_subject_shots := 0
	for sequence in sequences:
		_validate_sequence(sequence, mission_ids, failures)
		if typeof(sequence) == TYPE_DICTIONARY:
			triggers.append(str(sequence.get("trigger", "launch")))
			for shot in sequence.get("shots", []):
				if typeof(shot) == TYPE_DICTIONARY:
					used_plates[str(shot.get("plate", ""))] = true
					if float(shot.get("animation_fps", 0.0)) > 0.0:
						animated_subject_shots += 1
	_expect(triggers.count("launch") == 2 and triggers.count("ending") == 1, "cinematic schedule should contain two launch transitions and one ending", failures)
	_expect(used_plates.size() == 12, "each campaign cinematic beat should use its own authored editorial plate", failures)
	_expect(animated_subject_shots >= 5, "campaign cinematics should use restrained authored subject animation on mechanical story beats", failures)
	for plate_id in PLATES:
		var plate := load("res://assets/runtime/cinematics/plates/%s.png" % plate_id)
		_expect(plate is Texture2D and plate.get_size() == Vector2(640,320), "cinematic plate should preserve authored 640x320 composition: %s" % plate_id, failures)
	_expect(FileAccess.file_exists("res://assets/source/cinematics/cinematic_plate_asset_manifest.json"), "cinematic plate production manifest should exist", failures)
	var director_file := FileAccess.open("res://scripts/campaign_cinematic_director.gd", FileAccess.READ)
	var director_source := director_file.get_as_text() if director_file != null else ""
	_expect(director_source.contains("SUBJECT_FRAMES") and director_source.contains("SUBJECT_OVERLAYS") and director_source.contains("animation_fps"), "cinematic subjects should consume approved limited-animation frames and boss overlays", failures)
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main game source should be readable", failures)
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("_cinematic_blocks_launch()"), "mission launch should pass through the cinematic gate", failures)
		_expect(source.contains('get_node_or_null("/root/CampaignCinematicDirector")'), "mission launch should address the cinematic autoload", failures)
		_expect(source.contains("_cinematic_blocks_ending()"), "final mission result should pass through the ending cinematic gate", failures)
	if failures.is_empty():
		print("HYPERSONIC campaign cinematic self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _validate_sequence(sequence, mission_ids: Array[String], failures: Array[String]) -> void:
	_expect(typeof(sequence) == TYPE_DICTIONARY, "each cinematic sequence should be a dictionary", failures)
	if typeof(sequence) != TYPE_DICTIONARY:
		return
	var sequence_id := str(sequence.get("id", "unnamed"))
	_expect(mission_ids.has(str(sequence.get("mission_id", ""))), "%s should target a canonical mission" % sequence_id, failures)
	var shots: Array = sequence.get("shots", [])
	_expect(shots.size() >= 3, "%s should contain at least three editorial beats" % sequence_id, failures)
	var roles: Array[String] = []
	var locked_shots := 0
	var consecutive_action := 0
	for shot in shots:
		_expect(typeof(shot) == TYPE_DICTIONARY, "%s contains an invalid shot" % sequence_id, failures)
		if typeof(shot) != TYPE_DICTIONARY:
			continue
		var role := str(shot.get("role", ""))
		roles.append(role)
		_expect(ALLOWED_ROLES.has(role), "%s contains an invalid editorial role" % sequence_id, failures)
		var camera := str(shot.get("camera", ""))
		_expect(ALLOWED_CAMERAS.has(camera), "%s contains an invalid camera direction" % sequence_id, failures)
		if camera == "locked": locked_shots += 1
		var duration := float(shot.get("duration", 0.0))
		_expect(duration >= 1.0 and duration <= 5.0, "%s shot duration should remain readable and restrained" % sequence_id, failures)
		_expect(PLATES.has(str(shot.get("plate", ""))), "%s references an unregistered environment plate" % sequence_id, failures)
		var sprite_id := str(shot.get("sprite", ""))
		_expect(sprite_id.is_empty() or SPRITES.has(sprite_id), "%s references an unregistered subject sprite" % sequence_id, failures)
		_expect(ALLOWED_BRIDGES.has(str(shot.get("sound_bridge", ""))), "%s references an invalid sound bridge" % sequence_id, failures)
		consecutive_action = consecutive_action + 1 if role == "action" else 0
		_expect(consecutive_action <= 2, "%s should not become an unbroken action montage" % sequence_id, failures)
	_expect(roles.has("observation") and roles.has("consequence"), "%s should establish context and finish on consequence" % sequence_id, failures)
	_expect(locked_shots >= 1, "%s should include a held composition for late-90s editorial weight" % sequence_id, failures)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
