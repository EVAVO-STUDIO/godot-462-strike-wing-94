extends SceneTree

const GameModeRules = preload("res://scripts/game_mode_rules.gd")

class ModeScene extends Node:
	var game_mode := "campaign"
	var mode_name := "CAMPAIGN"
	var mode_rule_summary := ""
	var mode_route_index := 0
	var mode_route_total := 0
	var mode_lives := 0
	var mode_total_score := 0
	var credits := 4200
	var mission_index := 3
	var weapon_index := 1
	var generator_index := 1
	var service_hull := 80
	var service_shield := 70
	var phase := 0
	var front_end_screen := "modes"
	var mission_catalog: Array = []
	var mode_records: Dictionary = {}
	var campaign_completed := false
	var prepared_index := -1
	func _prepare_mission(index: int) -> void: prepared_index = index
	func _max_hull() -> int: return 100
	func _max_shield() -> int: return 100

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var data := _load_json("res://data/game_modes.json")
	var missions_data := _load_json("res://data/missions.json")
	var mission_ids: Array[String] = []
	for mission in missions_data.get("missions", []):
		mission_ids.append(str(mission.get("id", "")))
	var modes := GameModeRules.sanitize_modes(data.get("modes", []),mission_ids)
	_expect(modes.size() == 4,"four authored alternate modes should validate",failures)
	var ids: Array[String] = []
	for mode in modes:
		ids.append(str(mode.get("id", "")))
		_expect(mode.get("missions", []).size() >= 7,"each mode should provide a substantial authored route",failures)
		_expect(int(mode.get("lives", 0)) >= 1,"each mode should define a real one-credit airframe allowance",failures)
		_expect(float(mode.get("score_multiplier", 0.0)) > 1.0,"each mode should reward its higher stakes",failures)
	_expect(ids == ["arcade_assault","boss_rush","hypersonic_trial","strike_mastery"],"mode identity/order should remain canonical",failures)
	_expect(bool(modes[1].get("requires_campaign_clear", false)),"Boss Rush should be the authored BLACK SKY completion unlock",failures)
	_expect(GameModeRules.scaled_hp(10,modes[1]) == 12,"Boss Rush should apply authored armour scaling",failures)
	_expect(GameModeRules.scaled_score(100,modes[3]) == 200,"Strike Mastery should double canonical target score",failures)
	for emblem in ["arcade","boss","hypersonic","strike"]:
		var texture := load("res://assets/runtime/ui/modes/%s.png" % emblem) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(64,64),"mode emblem should retain registered 64x64 canvas: %s" % emblem,failures)
	var run_frame := load("res://assets/runtime/ui/modes/mode_run_frame.png") as Texture2D
	_expect(run_frame != null and run_frame.get_size() == Vector2(212,18),"mode run-state frame should retain its compact registered canvas",failures)
	_expect(FileAccess.file_exists("res://assets/source/ui/modes/mode_art_manifest.json"),"mode art production manifest should exist",failures)
	_expect(FileAccess.file_exists("res://tools/build_mode_art.ps1"),"mode emblems should be deterministically rebuildable",failures)
	var director := root.get_node_or_null("GameModeDirector")
	_expect(director != null and int(director.call("mode_count")) == 4,"game mode director should own four validated modes",failures)
	if director != null:
		var scene := ModeScene.new()
		for mission in missions_data.get("missions",[]): scene.mission_catalog.append(mission)
		root.add_child(scene)
		_expect(not bool(director.call("is_unlocked",scene,1)),"Boss Rush should remain locked before campaign completion",failures)
		_expect(not bool(director.call("start_selected",scene,1)),"director should enforce the Boss Rush gate independently of UI",failures)
		_expect(bool(director.call("start_selected",scene,0)),"Arcade Assault should start against the canonical mission catalogue",failures)
		_expect(scene.game_mode == "arcade_assault" and scene.mode_route_total == 12 and scene.mode_lives == 3,"Arcade Assault should publish route and airframe state",failures)
		_expect(scene.prepared_index >= 0 and scene.front_end_screen == "sortie","alternate mode should prepare its first real sortie",failures)
		director.call("record_result",scene,false,1250)
		_expect(scene.mode_lives == 2 and scene.mode_total_score == 1250,"failed alternate sortie should consume one airframe and bank run score",failures)
		director.call("_record_run",scene,5,false)
		_expect(int(scene.mode_records.get("arcade_assault",{}).get("attempts",0)) == 1 and int(scene.mode_records.get("arcade_assault",{}).get("best_score",0)) == 1250,"alternate run should persist attempts, route progress and best score",failures)
		director.call("_end_run",scene)
		_expect(scene.game_mode == "campaign" and scene.credits == 4200 and scene.mission_index == 3,"ending a mode should restore isolated campaign state",failures)
		scene.campaign_completed = true
		_expect(bool(director.call("is_unlocked",scene,1)),"campaign completion should unlock Boss Rush",failures)
		scene.queue_free()
	var main_source := _source("res://scripts/main.gd")
	_expect(main_source.contains("_mode_enemy_hp") and main_source.contains("_mode_enemy_speed") and main_source.contains("_mode_score_value"),"alternate modifiers should hook canonical combat spawn and score paths",failures)
	_expect(main_source.contains("_advance_mode_result") and main_source.contains("_update_front_end_modes"),"alternate routes should own real result and menu flow",failures)
	_expect(main_source.contains("--capture-game-mode=") and main_source.contains("--capture-mode-selection="),"mode board and live routes should expose deterministic visual QA capture",failures)
	_expect(main_source.contains('catalogue[i].get("requires_campaign_clear", false)') and main_source.contains("campaign_completed = true") and main_source.contains("_begin_capture_gameplay()"),"live mode capture should unlock QA-only postgame routes and honor captured mission time",failures)
	_expect(main_source.contains('"--capture-mode-records"') and main_source.contains('"best_score":284600'),"persistent mode records should expose deterministic front-door visual QA",failures)
	var save_source := _source("res://scripts/campaign_save.gd")
	_expect(save_source.contains("_campaign_mode(scene)"),"alternate modes should be isolated from persistent campaign saves",failures)
	var ui_source := _source("res://scripts/pixel_ui_director.gd")
	_expect(ui_source.contains("ARCADE / CHALLENGE OPERATIONS") and ui_source.contains("MODE_EMBLEMS"),"front end should expose a dedicated authored mode board",failures)
	_expect(ui_source.contains("_draw_mode_run_state") and ui_source.contains("MODE_RUN_FRAME"),"live alternate sorties should expose route, airframes, and banked run score",failures)
	_expect(ui_source.contains('BEST %08d  CLEAR %02d') and ui_source.contains('scene.get("mode_records")'),"mode board should expose persistent best score and clear history",failures)
	_expect(ui_source.contains("LOCKED // CLEAR BLACK SKY") and ui_source.contains("CAMPAIGN CLEAR REQUIRED"),"mode board should communicate the post-game unlock gate",failures)
	if failures.is_empty():
		print("HYPERSONIC arcade/challenge modes self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_source(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _source(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _expect(condition: bool,message: String,failures: Array[String]) -> void:
	if not condition: failures.append(message)
