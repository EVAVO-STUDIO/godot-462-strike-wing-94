extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run()

func _run() -> void:
	var secrets: Array = _json("res://data/secret_missions.json").get("missions", [])
	var core: Array = _json("res://data/missions.json").get("missions", [])
	var enemies: Array = _json("res://data/enemies.json").get("enemies", [])
	var enemy_ids: Dictionary = {}
	var vector_ids: Dictionary = {}
	for enemy in enemies:
		enemy_ids[str(enemy.get("id", ""))] = true
	for mission in core:
		for beat in mission.get("encounter_beats", []):
			if bool(beat.get("secret", false)):
				vector_ids["%s:%s" % [mission.get("id", ""), beat.get("id", "")]] = true
	_expect(secrets.size() >= 6 and secrets.size() <= 10, "campaign should provide six to ten launchable secret missions")
	var ids: Dictionary = {}
	for mission in secrets:
		var id := str(mission.get("id", ""))
		_expect(not id.is_empty() and not ids.has(id), "secret mission IDs should be stable and unique")
		ids[id] = true
		_expect(vector_ids.has(str(mission.get("required_secret_id", ""))), "%s should unlock from a real authored secret vector" % id)
		_expect(float(mission.get("duration_seconds", 0.0)) >= 120.0, "%s should be a substantial playable sortie" % id)
		_expect(mission.get("encounter_beats", []).size() >= 3 and mission.get("objectives", []).size() >= 3, "%s should contain authored encounters and objectives" % id)
		_expect(enemy_ids.has(str(mission.get("boss_id", ""))), "%s boss should exist in the combat catalogue" % id)
		_expect(int(mission.get("reward_credits", 0)) > 0 and not str(mission.get("briefing", "")).is_empty(), "%s should provide authored briefing and reward" % id)
	var main_script := load("res://scripts/main.gd") as Script
	var scene = main_script.new()
	scene.call("_load_content")
	var original_index: int = scene.get("mission_index")
	_expect(scene.call("_unlocked_secret_missions").is_empty(), "secret board should begin encrypted")
	scene.set("discovered_secret_ids", [str(secrets[0].get("required_secret_id", ""))])
	_expect(scene.call("_unlocked_secret_missions").size() == 1, "recovering one vector should unlock exactly its sortie")
	scene.set("active_secret_mission_id", str(secrets[0].get("id", "")))
	scene.call("_prepare_mission", original_index)
	_expect(str(scene.get("current_mission_name")) == str(secrets[0].get("name", "")).to_upper(), "secret sortie should become the active authored mission")
	scene.call("_return_from_secret_sortie")
	_expect(int(scene.get("mission_index")) == original_index and str(scene.get("front_end_screen")) == "secret_sorties", "returning from a secret sortie should preserve core campaign position")
	scene.free()
	var ui := _source("res://scripts/pixel_ui_director.gd")
	_expect(ui.contains("ENCRYPTED OPTIONAL OPERATIONS") and ui.contains("MISSION FILE"), "front end should expose a dedicated secret-operations board")
	_expect(ui.contains("SECRET %02d / %02d") and ui.contains("_secret_sortie_header"), "secret briefings should identify their own classified route instead of impersonating core campaign missions")
	var main := _source("res://scripts/main.gd")
	_expect(main.contains("--capture-secret-mission=") and main.contains("_return_from_secret_sortie"), "secret sortie flow should expose deterministic presentation QA and an explicit campaign-safe return")
	var save := _source("res://scripts/campaign_save.gd")
	_expect(save.contains('SAVE_VERSION := 11') and save.contains('"completed_secret_mission_ids"'), "secret mission clears should persist in save schema v11")
	if failures.is_empty():
		print("HYPERSONIC secret missions self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_source(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
