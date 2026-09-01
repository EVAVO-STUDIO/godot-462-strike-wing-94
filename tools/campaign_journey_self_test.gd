extends SceneTree

const EXPECTED_CORE_MISSIONS := 30
const EXPECTED_ROUTE_MISSIONS := 27
const BRANCH_COMBINATIONS := 8

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect("--campaign-journey" in OS.get_cmdline_user_args(), "campaign journey must run in isolated no-save mode")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main gameplay scene should load for campaign journey validation")
	if packed == null:
		_finish_test()
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var catalog: Array = scene.get("mission_catalog")
	_expect(catalog.size() == EXPECTED_CORE_MISSIONS, "campaign journey should retain thirty ordered core missions")
	var all_ids: Dictionary = {}
	for mission in catalog:
		if typeof(mission) == TYPE_DICTIONARY:
			all_ids[str(mission.get("id", ""))] = true
	var visited_union: Dictionary = {}
	for combination in range(BRANCH_COMBINATIONS):
		_run_route(scene, combination, visited_union)
	_expect(visited_union.size() == all_ids.size(), "all eight branch routes should collectively visit every authored core mission")
	for mission_id in all_ids:
		_expect(visited_union.has(mission_id), "campaign journey never reached authored mission %s" % mission_id)
	scene.queue_free()
	await process_frame
	_finish_test()

func _run_route(scene: Node, combination: int, visited_union: Dictionary) -> void:
	_reset_route(scene)
	var route_ids: Array[String] = []
	var branch_index := 0
	while route_ids.size() <= EXPECTED_CORE_MISSIONS:
		var mission: Dictionary = scene.call("_active_mission")
		var mission_id := str(mission.get("id", ""))
		_expect(not mission_id.is_empty(), "route %d should always resolve an active mission" % combination)
		if mission_id.is_empty() or mission_id in route_ids:
			_expect(false, "route %d looped at %s" % [combination, mission_id])
			return
		route_ids.append(mission_id)
		visited_union[mission_id] = true
		_scene_success_metrics(scene, route_ids.size())
		scene.set("phase", 1)
		scene.call("_finish_mission", true)
		_expect(int(scene.get("phase")) == 2 and bool(scene.get("mission_success")), "route %d mission %s should reach a successful report" % [combination, mission_id])
		if bool(scene.call("_is_final_campaign_mission")):
			_complete_and_verify_ending(scene, combination)
			break
		var pending: Dictionary = scene.call("_pending_branch")
		if not pending.is_empty():
			var choice := (combination >> branch_index) & 1
			var choices: Array = pending.get("choices", [])
			var expected_target := str(choices[choice].get("mission_id", "")) if choices.size() == 2 else ""
			scene.call("_open_branch_choice", pending)
			scene.call("_commit_branch_choice", choice)
			_expect(str(scene.call("_active_mission").get("id", "")) == expected_target, "route %d branch %d should enter its selected authored mission" % [combination, branch_index])
			branch_index += 1
		else:
			scene.call("_advance_campaign_mission")
	_expect(route_ids.size() == EXPECTED_ROUTE_MISSIONS, "route %d should visit 27 missions after three controlled branch choices" % combination)
	_expect(branch_index == 3 and scene.get("branch_decisions").size() == 3, "route %d should commit all three campaign decisions" % combination)
	_expect(str(route_ids[0]) == "m01_coastal_intercept" and str(route_ids[-1]) == "m12_machine_ark", "route %d should span Coastal Intercept through Machine Ark" % combination)
	_expect(int(scene.get("career_statistics").get("sorties_cleared", 0)) == EXPECTED_ROUTE_MISSIONS, "route %d should record every successful campaign sortie" % combination)

func _reset_route(scene: Node) -> void:
	var cinematic := root.get_node_or_null("CampaignCinematicDirector")
	if cinematic != null:
		cinematic.set("_seen", {})
		cinematic.set("_active", {})
	var credits := root.get_node_or_null("CreditsDirector")
	if credits != null and credits.has_method("finish") and bool(credits.call("credits_active")):
		credits.call("finish")
	scene.set("game_mode", "campaign")
	scene.set("mission_index", 0)
	scene.set("branch_decisions", {})
	scene.set("current_branch", {})
	scene.set("credits", 2500)
	scene.set("campaign_completed", false)
	scene.set("campaign_completions", 0)
	scene.set("campaign_completion_committed", false)
	scene.set("completed_difficulties", [])
	scene.set("career_statistics", {})
	scene.set("active_secret_mission_id", "")
	scene.call("_prepare_mission", 0)

func _scene_success_metrics(scene: Node, ordinal: int) -> void:
	scene.set("score", 12000 + ordinal * 100)
	scene.set("shots_fired", 100)
	scene.set("shots_hit", 78)
	scene.set("targets_destroyed", 20)
	scene.set("damage_taken", 4)
	scene.set("hull", maxi(1, int(scene.call("_max_hull")) - 4))
	scene.set("shield", int(scene.call("_max_shield")))

func _complete_and_verify_ending(scene: Node, combination: int) -> void:
	scene.call("_complete_campaign")
	_expect(bool(scene.get("campaign_completed")) and int(scene.get("campaign_completions")) == 1, "route %d should commit campaign completion exactly once" % combination)
	_expect("combat" in scene.get("completed_difficulties"), "route %d should persist its cleared difficulty" % combination)
	var cinematic := root.get_node_or_null("CampaignCinematicDirector")
	_expect(cinematic != null and bool(cinematic.call("cinematic_active")), "route %d should enter the Machine Ark ending cinematic" % combination)
	if cinematic != null and cinematic.has_method("_finish"):
		cinematic.call("_finish")
	var credits := root.get_node_or_null("CreditsDirector")
	_expect(credits != null and bool(credits.call("credits_active")), "route %d ending should hand off directly to credits" % combination)
	if credits != null and credits.has_method("finish"):
		credits.call("finish")
	_expect(str(scene.get("front_end_screen")) == "main_menu" and int(scene.get("phase")) == 0, "route %d credits should return to the HYPERSONIC front door" % combination)

func _finish_test() -> void:
	if failures.is_empty():
		print("HYPERSONIC campaign journey self-test passed: 8 branch routes, 216 successful sorties, all 30 core missions, ending and credits.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
