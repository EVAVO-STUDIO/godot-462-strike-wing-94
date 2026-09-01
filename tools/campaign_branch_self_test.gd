extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var campaign: Dictionary = _json("res://data/campaign.json").get("campaign", {})
	var missions: Array = _json("res://data/missions.json").get("missions", [])
	var mission_ids: Array[String] = []
	for mission in missions:
		mission_ids.append(str(mission.get("id", "")))
	var branches: Array = campaign.get("branches", [])
	var save_metadata: Dictionary = _json("res://data/campaign.json").get("save", {})
	_expect(int(save_metadata.get("schema_version", 0)) == 11, "campaign metadata should advertise canonical save schema v11")
	_expect(not save_metadata.has("path") and str(save_metadata.get("namespace_authority", "")) == "data/product_identity.json", "campaign metadata must delegate current and legacy save paths to product identity")
	_expect(branches.size() == 3, "campaign should contain three controlled sector branch decisions")
	var branch_ids: Dictionary = {}
	var target_ids: Dictionary = {}
	for branch in branches:
		var branch_id := str(branch.get("id", ""))
		_expect(not branch_id.is_empty() and not branch_ids.has(branch_id), "branch IDs should be stable and unique")
		branch_ids[branch_id] = true
		_expect(str(branch.get("after_mission", "")) in mission_ids, "%s should follow a real authored mission" % branch_id)
		_expect(str(branch.get("reconverge_mission", "")) in mission_ids, "%s should reconverge on a real authored mission" % branch_id)
		var choices: Array = branch.get("choices", [])
		_expect(choices.size() == 2, "%s should provide exactly two readable crisis vectors" % branch_id)
		for choice in choices:
			var target := str(choice.get("mission_id", ""))
			_expect(target in mission_ids and not target_ids.has(target), "%s choice targets should be unique authored missions" % branch_id)
			target_ids[target] = true
			_expect(int(choice.get("bonus_credits", 0)) > 0, "%s choices should carry an explicit operational reward" % branch_id)
	var main := _source("res://scripts/main.gd")
	_expect(main.contains("_pending_branch()") and main.contains("_open_branch_choice") and main.contains("_commit_branch_choice"), "campaign result flow should open and commit branch decisions")
	_expect(main.contains("_advance_campaign_mission") and main.contains('candidate.get("reconverge_mission"'), "selected branch missions should reconverge through stable mission IDs")
	_expect(main.contains('"--capture-branch"'), "branch choice should expose deterministic visual QA")
	var ui := _source("res://scripts/pixel_ui_director.gd")
	_expect(ui.contains("_draw_front_end_branch") and ui.contains("OPERATIONAL BRANCH // COMMAND DECISION"), "branch choice should use a dedicated period-authentic operations screen")
	var save := _source("res://scripts/campaign_save.gd")
	_expect(save.contains('SAVE_VERSION := 11') and save.contains('"branch_decisions"'), "branch decisions should persist in save schema v11")
	_test_runtime_branch()
	if failures.is_empty():
		print("HYPERSONIC campaign branch self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_runtime_branch() -> void:
	var main_script := load("res://scripts/main.gd") as Script
	var scene = main_script.new()
	scene.call("_load_content")
	var breakwater_index := int(scene.call("_mission_index_for_id", "m04_breakwater"))
	scene.set("mission_index", breakwater_index)
	scene.call("_prepare_mission", breakwater_index)
	var pending: Dictionary = scene.call("_pending_branch")
	_expect(str(pending.get("id", "")) == "s1_breakwater_crisis", "Breakwater completion should expose the Sector I crisis decision")
	var starting_credits := int(scene.get("credits"))
	scene.call("_open_branch_choice", pending)
	_expect(str(scene.get("front_end_screen")) == "branch", "pending crisis should open the dedicated branch screen")
	scene.call("_commit_branch_choice", 0)
	_expect(str(scene.get("branch_decisions").get("s1_breakwater_crisis", "")) == "furnace", "committing the first vector should persist the stable Furnace decision")
	_expect(str(scene.call("_active_mission").get("id", "")) == "m05_furnace_line", "Furnace decision should prepare the authored Furnace Line sortie")
	_expect(int(scene.get("credits")) == starting_credits + 900, "Furnace decision should grant its exact command bounty once")
	scene.call("_advance_campaign_mission")
	_expect(str(scene.call("_active_mission").get("id", "")) == "s1_m07_desert_lance", "completed branch sortie should reconverge at Desert Lance and skip the unchosen route")
	scene.free()

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_source(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
