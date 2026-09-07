extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data := _json("res://data/intelligence.json")
	var entries: Array = data.get("entries", [])
	_expect(entries.size() >= 15, "intelligence database should contain a substantial initial technical library")
	var categories: Dictionary = {}
	var ids: Dictionary = {}
	for entry in entries:
		var id := str(entry.get("id", ""))
		_expect(not id.is_empty() and not ids.has(id), "intelligence IDs should be stable and unique")
		ids[id] = true
		categories[str(entry.get("category", ""))] = true
		_expect(not str(entry.get("name", "")).is_empty() and not str(entry.get("summary", "")).is_empty(), "%s should contain authored technical copy" % id)
		var illustration := str(entry.get("illustration", ""))
		_expect(ResourceLoader.exists(illustration), "%s should reference governed production art" % id)
		_expect(int(entry.get("unlock_mission_index", -1)) >= 0 or not str(entry.get("required_secret_id", "")).is_empty(), "%s should have an explicit unlock condition" % id)
	for required in ["AIRCRAFT","WEAPON","GENERATOR","AIRFRAME","SUPPORT","THREAT","SHIP","ARMOUR","MACHINE","BOSS","EVENT"]:
		_expect(categories.has(required), "intelligence database should cover %s files" % required)
	var main_script := load("res://scripts/main.gd") as Script
	var scene = main_script.new()
	scene.call("_load_content")
	scene.set("mission_index", 0)
	scene.call("_prepare_mission", 0)
	_expect(scene.get("intelligence_unlocked_ids").size() >= 4, "new campaign should release core VX-94 technical files")
	scene.set("mission_index", 29)
	scene.call("_prepare_mission", 29)
	_expect("machine_ark" in scene.get("intelligence_unlocked_ids"), "final operation should release Machine Ark intelligence")
	_expect(not "black_wake" in scene.get("intelligence_unlocked_ids"), "secret signal file should remain encrypted without its vector")
	var secrets: Array = scene.get("discovered_secret_ids")
	secrets.append("m03_black_sea:hidden_intercept")
	scene.set("discovered_secret_ids", secrets)
	scene.call("_refresh_intelligence_unlocks")
	_expect("black_wake" in scene.get("intelligence_unlocked_ids"), "recovering the Black Wake vector should release its secret intelligence file")
	scene.free()
	var ui := _source("res://scripts/pixel_ui_director.gd")
	_expect(ui.contains("EVAVO TACTICAL INTELLIGENCE DATABASE") and ui.contains("TECHNICAL FILE"), "front door should expose a dedicated period military database")
	_expect(ui.contains('load(str(selected.get("illustration"') and ui.contains("UiSpriteRenderer.draw_nine_slice"), "database should display governed illustrations inside authored UI chrome")
	_expect(ui.contains('Color("142831") if selected_row else Color("09151c")') and ui.contains('GOLD if selected_row else Color("294652")'), "database rows should separate the active gold command from subdued released files")
	var save := _source("res://scripts/campaign_save.gd")
	_expect(save.contains('SAVE_VERSION := 12') and save.contains('"intelligence_unlocked_ids"'), "intelligence unlocks should persist in save schema v12")
	if failures.is_empty():
		print("HYPERSONIC intelligence database self-test passed.")
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
