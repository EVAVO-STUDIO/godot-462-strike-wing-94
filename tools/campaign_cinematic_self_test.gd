extends SceneTree

const ALLOWED_ROLES := ["observation", "anticipation", "action", "consequence"]
const ALLOWED_CAMERAS := ["locked", "pan", "track"]
const ALLOWED_BRIDGES := ["environmental", "prelap", "carry", "hard silence"]
const PLATES := ["industrial", "machine_furnace", "city", "high_atmosphere", "orbital"]
const SPRITES := ["salvage_mech", "drone_hunter", "vx94_fighter", "phase_array", "machine_ark"]

func _initialize() -> void:
	var failures: Array[String] = []
	var cinematic := root.get_node_or_null("CampaignCinematicDirector")
	_expect(cinematic != null, "campaign cinematic autoload should exist", failures)
	var data := _load_json("res://data/cinematics.json")
	var missions := _load_json("res://data/missions.json")
	var mission_ids: Array[String] = []
	for mission in missions.get("missions", []):
		if typeof(mission) == TYPE_DICTIONARY:
			mission_ids.append(str(mission.get("id", "")))
	var sequences: Array = data.get("sequences", [])
	_expect(sequences.size() == 2, "campaign should retain its two sector-transition cinematics", failures)
	for sequence in sequences:
		_validate_sequence(sequence, mission_ids, failures)
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main game source should be readable", failures)
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("_cinematic_blocks_launch()"), "mission launch should pass through the cinematic gate", failures)
		_expect(source.contains('get_node_or_null("/root/CampaignCinematicDirector")'), "mission launch should address the cinematic autoload", failures)
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
