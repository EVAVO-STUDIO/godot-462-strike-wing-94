extends Node2D

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
const RewardRules = preload("res://scripts/reward_rules.gd")
const RunSeedRules = preload("res://scripts/run_seed_rules.gd")
const MissionStateRules = preload("res://scripts/mission_state_rules.gd")
const MissionFlowRules = preload("res://scripts/mission_flow_rules.gd")
const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")
const EnvironmentRules = preload("res://scripts/environment_rules.gd")
const WeaponPickupRules = preload("res://scripts/weapon_pickup_rules.gd")
const BombRules = preload("res://scripts/bomb_rules.gd")
const ServiceRules = preload("res://scripts/service_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")
const HypersonicRules = preload("res://scripts/hypersonic_rules.gd")
const EvasiveRollRules = preload("res://scripts/evasive_roll_rules.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const NEUTRAL_DEPTH_TILE := preload("res://assets/runtime/environments/layers/sea_deep_tile.png")

const PLAYER_SPEED := 220.0
const PLAYFIELD := Rect2(18.0, 52.0, 604.0, 296.0)
const BOSS_OVERTIME_LIMIT_SECONDS := 45.0
const PLAYER_LOSS_SEQUENCE_SECONDS := 2.40

enum GamePhase { TITLE, PLAYING, RESULT }

var phase := GamePhase.TITLE
var front_end_screen := "main_menu"
var menu_selection := 0
var option_selection := 0
var option_category := 0
var control_selection := 0
var control_listening := false
var mode_selection := 0
var branch_selection := 0
var dossier_selection := 0
var secret_sortie_selection := 0
var game_mode := "campaign"
var mode_name := "CAMPAIGN"
var mode_rule_summary := "30-SORTIE AUTHORED WAR"
var mode_route_index := 0
var mode_route_total := 0
var mode_lives := 0
var mode_total_score := 0
var player_position := Vector2(320.0, 292.0)
var fire_timer := 0.0
var secondary_timer := 0.0
var enemy_spawn_timer := 0.5
var mission_time := 0.0
var mission_duration := 150.0
var score := 0
var hull := 100
var shield := 100
var service_hull := 100
var service_shield := 100
var wave := 1
var bombs := 3
var credits := 0
var mission_index := 0
var campaign_completed := false
var campaign_completions := 0
var completed_difficulties: Array = []
var campaign_completion_committed := false
var discovered_secret_ids: Array = []
var mode_records: Dictionary = {}
var branch_decisions: Dictionary = {}
var current_branch: Dictionary = {}
var intelligence_unlocked_ids: Array = []
var completed_secret_mission_ids: Array = []
var career_statistics: Dictionary = {}
var active_secret_mission_id := ""
var weapon_index := 0
var generator_index := 0
var temporary_weapon_boost := 0
var energy := 100.0
var shots_fired := 0
var shots_hit := 0
var targets_destroyed := 0
var damage_taken := 0
var secrets_discovered := 0
var mission_reward_earned := 0
var repair_cost := 0
var boss_spawned := false
var current_boss_id := ""
var current_environment := "coast"
var current_mission_name := "COASTAL INTERCEPT"
var current_briefing := ""
var current_objectives: Array = []
var objective_progress: Dictionary = {}
var result_text := ""
var mission_success := false
var status_text := ""
var status_timer := 0.0
var player_loss_timer := 0.0
var bullets: Array = []
var enemy_bullets: Array = []
var enemy_missiles_launched := 0
var enemies: Array = []
var pickups: Array = []
var enemy_catalog: Array = []
var weapon_catalog: Array = []
var generator_catalog: Array = []
var mission_catalog: Array = []
var secret_mission_catalog: Array = []
var spawn_profiles: Array = []
var campaign: Dictionary = {}
var mission_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_configure_input()
	var bindings := get_node_or_null("/root/InputBindings")
	if bindings != null and bindings.has_method("apply_saved_keyboard_bindings"):
		bindings.call("apply_saved_keyboard_bindings")
	_load_content()
	mission_index = _capture_mission_index(OS.get_cmdline_user_args(), mission_index, mission_catalog.size())
	_prepare_mission(mission_index)
	mode_selection = _capture_mode_selection(OS.get_cmdline_user_args(),mode_selection)
	option_selection = _capture_option_selection(OS.get_cmdline_user_args(),option_selection)
	option_category = _capture_option_category(OS.get_cmdline_user_args(),option_category)
	control_selection = _capture_control_selection(OS.get_cmdline_user_args(), control_selection)
	var capture_front_end := _capture_front_end(OS.get_cmdline_user_args())
	var capture_game_mode := _capture_game_mode(OS.get_cmdline_user_args())
	var capture_result := _capture_result_state(OS.get_cmdline_user_args())
	var capture_secret_mission := _capture_secret_mission(OS.get_cmdline_user_args())
	if "--capture-campaign-clear" in OS.get_cmdline_user_args() and "--capture-gameplay" in OS.get_cmdline_user_args():
		campaign_completed = true
		campaign_completions = 3
		completed_difficulties = ["cadet", "combat", "veteran"]
		discovered_secret_ids = ["m01_coastal_intercept:hidden_ace", "m03_black_sea:hidden_intercept", "m05_furnace_line:hidden_armoury", "m07_ghost_sky:hidden_signal", "s2_m06_ghost_convoy:seed_manifest", "s2_m08_swarm_sea:submerged_cradle", "s3_m07_dead_satellite:cold_antenna_route", "m12_machine_ark:hidden_core_vector"]
		completed_secret_mission_ids = ["sm01_black_wake", "sm02_furnace_vault", "sm03_dead_frequency"]
		mission_index = maxi(0, mission_catalog.size() - 1)
		_prepare_mission(mission_index)
	if "--capture-mode-records" in OS.get_cmdline_user_args() and "--capture-gameplay" in OS.get_cmdline_user_args():
		var mode_director := get_node_or_null("/root/GameModeDirector")
		var mode: Dictionary = mode_director.call("mode_at", mode_selection) if mode_director != null and mode_director.has_method("mode_at") else {}
		var mode_id := str(mode.get("id", "arcade_assault"))
		var route_total: int = mode.get("missions", []).size()
		mode_records[mode_id] = {"attempts":4,"clears":1,"best_route":route_total,"route_total":route_total,"best_score":284600,"cleared":true}
	if "--capture-branch" in OS.get_cmdline_user_args() and "--capture-gameplay" in OS.get_cmdline_user_args():
		var branches := _campaign_branches()
		current_branch = branches[0].duplicate(true) if not branches.is_empty() else {}
		branch_selection = 0
	if not capture_secret_mission.is_empty():
		active_secret_mission_id = capture_secret_mission
		_prepare_mission(mission_index)
	if not capture_result.is_empty():
		_begin_capture_result(capture_result)
	elif not capture_game_mode.is_empty():
		call_deferred("_begin_capture_game_mode",capture_game_mode)
	elif not capture_front_end.is_empty():
		front_end_screen = capture_front_end
	elif "--capture-gameplay" in OS.get_cmdline_user_args():
		call_deferred("_begin_capture_gameplay")
	if "--performance-profile" in OS.get_cmdline_user_args():
		add_child(preload("res://tools/performance_probe.gd").new())
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual-capture="):
			add_child(preload("res://tools/visual_capture_probe.gd").new())
			break
	if "--playtest-telemetry" in OS.get_cmdline_user_args():
		add_child(preload("res://tools/playtest_telemetry_probe.gd").new())
	queue_redraw()

func _capture_front_end(arguments: PackedStringArray) -> String:
	for argument in arguments:
		if argument.begins_with("--capture-front-end="):
			return argument.trim_prefix("--capture-front-end=").to_lower()
	return ""

func _capture_mode_selection(arguments: PackedStringArray, fallback: int) -> int:
	for argument in arguments:
		if argument.begins_with("--capture-mode-selection="):
			var value := argument.trim_prefix("--capture-mode-selection=")
			if value.is_valid_int(): return maxi(0,value.to_int())
	return fallback

func _capture_option_selection(arguments: PackedStringArray, fallback: int) -> int:
	for argument in arguments:
		if argument.begins_with("--capture-option-selection="):
			var value := argument.trim_prefix("--capture-option-selection=")
			if value.is_valid_int(): return maxi(0,value.to_int())
	return fallback

func _capture_option_category(arguments: PackedStringArray, fallback: int) -> int:
	for argument in arguments:
		if argument.begins_with("--capture-option-category="):
			var value:=argument.trim_prefix("--capture-option-category=")
			if value.is_valid_int():return maxi(0,value.to_int())
	return fallback

func _capture_control_selection(arguments: PackedStringArray, fallback: int) -> int:
	for argument in arguments:
		if argument.begins_with("--capture-control-selection="):
			var value := argument.trim_prefix("--capture-control-selection=")
			if value.is_valid_int():
				return maxi(0, value.to_int())
	return fallback

func _capture_game_mode(arguments: PackedStringArray) -> String:
	for argument in arguments:
		if argument.begins_with("--capture-game-mode="):
			return argument.trim_prefix("--capture-game-mode=").to_lower()
	return ""

func _capture_result_state(arguments: PackedStringArray) -> String:
	if not "--capture-gameplay" in arguments:
		return ""
	for argument in arguments:
		if argument.begins_with("--capture-result="):
			var value := argument.trim_prefix("--capture-result=").to_lower()
			return value if value in ["success", "failure"] else ""
	return ""

func _capture_secret_mission(arguments: PackedStringArray) -> String:
	if not "--capture-gameplay" in arguments:
		return ""
	for argument in arguments:
		if argument.begins_with("--capture-secret-mission="):
			var requested := argument.trim_prefix("--capture-secret-mission=").to_lower()
			for mission in secret_mission_catalog:
				if typeof(mission) == TYPE_DICTIONARY and str(mission.get("id", "")) == requested:
					return requested
	return ""

func _capture_time(arguments: PackedStringArray) -> float:
	for argument in arguments:
		if argument.begins_with("--capture-time="):
			var value := argument.trim_prefix("--capture-time=")
			if value.is_valid_float():
				return clampf(value.to_float(), 0.0, 240.0)
	return 0.0

func _begin_capture_gameplay() -> void:
	_start_mission()
	mission_time = minf(_capture_time(OS.get_cmdline_user_args()), maxf(0.0, mission_duration - 1.0))
	queue_redraw()

func _begin_capture_result(state: String) -> void:
	phase = GamePhase.RESULT
	mission_success = state == "success"
	score = 184260 if mission_success else 42780
	credits = 28640
	shots_fired = 164
	shots_hit = 129 if mission_success else 61
	targets_destroyed = 43 if mission_success else 17
	damage_taken = 18 if mission_success else 100
	secrets_discovered = 1 if mission_success else 0
	repair_cost = 520 if mission_success else 4800
	result_text = "MISSION COMPLETE  +6420  BOSS +1800  ACCURACY 79% +900" if mission_success else "AIRFRAME LOST  PRESS R TO RETRY"
	_clear_combat()
	queue_redraw()

func _begin_capture_game_mode(mode_id: String) -> void:
	var modes := get_node_or_null("/root/GameModeDirector")
	if modes == null or not modes.has_method("modes"): return
	var catalogue: Array = modes.call("modes")
	for i in range(catalogue.size()):
		if str(catalogue[i].get("id","")) == mode_id:
			mode_records[mode_id] = {"attempts":4,"clears":1,"best_route":catalogue[i].get("missions",[]).size(),"route_total":catalogue[i].get("missions",[]).size(),"best_score":284600,"cleared":true}
			modes.call("start_selected",self,i)
			_start_mission()
			return

func _capture_mission_index(arguments: PackedStringArray, fallback: int, mission_count: int) -> int:
	if not "--capture-gameplay" in arguments:
		return fallback
	for argument in arguments:
		if argument.begins_with("--capture-mission="):
			var value := argument.trim_prefix("--capture-mission=")
			if value.is_valid_int():
				return clampi(value.to_int(), 0, maxi(0, mission_count - 1))
	return fallback

func _process(delta: float) -> void:
	status_timer = maxf(0.0, status_timer - delta)
	match phase:
		GamePhase.TITLE:
			if front_end_screen != "sortie":
				_update_front_end_menu()
			elif Input.is_action_just_pressed("confirm"):
				if not _cinematic_blocks_launch():
					_start_mission()
			elif Input.is_action_just_pressed("cancel"):
				front_end_screen = "main_menu"
			elif Input.is_action_just_pressed("upgrade"):
				if not _mode_active(): _try_buy_next_weapon()
			elif Input.is_action_just_pressed("upgrade_generator"):
				if not _mode_active(): _try_buy_next_generator()
			elif Input.is_action_just_pressed("service_hull"):
				if not _mode_active(): _service_hull_full()
			elif Input.is_action_just_pressed("service_shield"):
				if not _mode_active(): _service_shield_full()
		GamePhase.PLAYING:
			_update_mission(delta)
			if Input.is_action_just_pressed("cancel"):
				var pause := get_node_or_null("/root/PauseDirector")
				if pause == null or not pause.has_method("pause_game") or not bool(pause.call("pause_game")):
					phase = GamePhase.TITLE
					front_end_screen = "sortie"
					_clear_combat()
		GamePhase.RESULT:
			if _credits_blocking():
				pass
			elif Input.is_action_just_pressed("confirm"):
				if _mode_active():
					_advance_mode_result()
					queue_redraw()
					return
				if not mission_success:
					_start_mission()
				elif not active_secret_mission_id.is_empty():
					_return_from_secret_sortie()
				elif _is_final_campaign_mission():
					_complete_campaign()
				elif not _pending_branch().is_empty():
					_open_branch_choice(_pending_branch())
				else:
					_advance_campaign_mission()
			elif Input.is_action_just_pressed("restart"):
				if _mode_active(): _advance_mode_result()
				elif mission_success and not active_secret_mission_id.is_empty(): _return_from_secret_sortie()
				else: _start_mission()
	queue_redraw()

func _update_front_end_menu() -> void:
	if front_end_screen == "branch":
		_update_branch_choice()
		return
	if front_end_screen == "modes":
		_update_front_end_modes()
		return
	if front_end_screen == "options":
		_update_front_end_options()
		return
	if front_end_screen == "dossier":
		_update_dossier()
		return
	if front_end_screen == "secret_sorties":
		_update_secret_sorties()
		return
	if front_end_screen == "controls":
		_update_front_end_controls()
		return
	if Input.is_action_just_pressed("move_up"):
		menu_selection = posmod(menu_selection - 1, 7)
	elif Input.is_action_just_pressed("move_down"):
		menu_selection = posmod(menu_selection + 1, 7)
	elif Input.is_action_just_pressed("confirm"):
		match menu_selection:
			0: front_end_screen = "sortie"
			1: front_end_screen = "modes"
			2: front_end_screen = "secret_sorties"
			3: front_end_screen = "options"
			4: front_end_screen = "controls"
			5: front_end_screen = "dossier"
			6: get_tree().quit()

func _unlocked_secret_missions() -> Array:
	var unlocked: Array = []
	for mission in secret_mission_catalog:
		if typeof(mission) == TYPE_DICTIONARY and str(mission.get("required_secret_id", "")) in discovered_secret_ids:
			unlocked.append(mission)
	return unlocked

func _update_secret_sorties() -> void:
	var unlocked := _unlocked_secret_missions()
	if Input.is_action_just_pressed("cancel"):
		front_end_screen = "main_menu"
	elif not unlocked.is_empty() and Input.is_action_just_pressed("move_up"):
		secret_sortie_selection = posmod(secret_sortie_selection - 1, unlocked.size())
	elif not unlocked.is_empty() and Input.is_action_just_pressed("move_down"):
		secret_sortie_selection = posmod(secret_sortie_selection + 1, unlocked.size())
	elif not unlocked.is_empty() and Input.is_action_just_pressed("confirm"):
		active_secret_mission_id = str(unlocked[clampi(secret_sortie_selection, 0, unlocked.size() - 1)].get("id", ""))
		_prepare_mission(mission_index)
		front_end_screen = "sortie"

func _active_secret_mission() -> Dictionary:
	if active_secret_mission_id.is_empty():
		return {}
	for mission in secret_mission_catalog:
		if typeof(mission) == TYPE_DICTIONARY and str(mission.get("id", "")) == active_secret_mission_id:
			return mission
	return {}

func _intelligence_entries() -> Array:
	var data = ContentCatalog.load_json("res://data/intelligence.json")
	return data.get("entries", []) if typeof(data) == TYPE_DICTIONARY else []

func _refresh_intelligence_unlocks() -> void:
	for entry in _intelligence_entries():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var unlock_index := int(entry.get("unlock_mission_index", -1))
		var secret_id := str(entry.get("required_secret_id", ""))
		var unlocked := unlock_index >= 0 and mission_index >= unlock_index
		if not secret_id.is_empty() and secret_id in discovered_secret_ids:
			unlocked = true
		var entry_id := str(entry.get("id", ""))
		if unlocked and not entry_id.is_empty() and not entry_id in intelligence_unlocked_ids:
			intelligence_unlocked_ids.append(entry_id)

func _update_dossier() -> void:
	_refresh_intelligence_unlocks()
	var count := maxi(1, intelligence_unlocked_ids.size())
	if Input.is_action_just_pressed("cancel"):
		front_end_screen = "main_menu"
	elif Input.is_action_just_pressed("move_up"):
		dossier_selection = posmod(dossier_selection - 1, count)
	elif Input.is_action_just_pressed("move_down"):
		dossier_selection = posmod(dossier_selection + 1, count)

func _campaign_branches() -> Array:
	var config := _campaign_config()
	var branches = config.get("branches", [])
	return branches if typeof(branches) == TYPE_ARRAY else []

func _branch_for_after(mission_id: String) -> Dictionary:
	for branch in _campaign_branches():
		if typeof(branch) == TYPE_DICTIONARY and str(branch.get("after_mission", "")) == mission_id:
			return branch
	return {}

func _pending_branch() -> Dictionary:
	var branch := _branch_for_after(str(_active_mission().get("id", "")))
	return branch if not branch.is_empty() and not branch_decisions.has(str(branch.get("id", ""))) else {}

func _open_branch_choice(branch: Dictionary) -> void:
	current_branch = branch.duplicate(true)
	branch_selection = 0
	phase = GamePhase.TITLE
	front_end_screen = "branch"

func _update_branch_choice() -> void:
	var choices: Array = current_branch.get("choices", [])
	if choices.is_empty():
		front_end_screen = "sortie"
		return
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left"):
		branch_selection = posmod(branch_selection - 1, choices.size())
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_right"):
		branch_selection = posmod(branch_selection + 1, choices.size())
	elif Input.is_action_just_pressed("confirm"):
		_commit_branch_choice(branch_selection)

func _commit_branch_choice(selection: int) -> void:
	var choices: Array = current_branch.get("choices", [])
	if choices.is_empty():
		return
	var choice: Dictionary = choices[clampi(selection, 0, choices.size() - 1)]
	var branch_id := str(current_branch.get("id", ""))
	branch_decisions[branch_id] = str(choice.get("id", ""))
	credits += maxi(0, int(choice.get("bonus_credits", 0)))
	var target_index := _mission_index_for_id(str(choice.get("mission_id", "")))
	current_branch = {}
	if target_index < 0:
		front_end_screen = "sortie"
		return
	mission_index = target_index
	_prepare_mission(mission_index)
	front_end_screen = "sortie"
	status_text = "OPERATIONS BRANCH COMMITTED"
	status_timer = 3.0

func _mission_index_for_id(mission_id: String) -> int:
	for index in range(mission_catalog.size()):
		if str(mission_catalog[index].get("id", "")) == mission_id:
			return index
	return -1

func _advance_campaign_mission() -> void:
	var current_id := str(_active_mission().get("id", ""))
	var target_id := ""
	var branch := _branch_for_after(current_id)
	if not branch.is_empty():
		var decision_id := str(branch_decisions.get(str(branch.get("id", "")), ""))
		for choice in branch.get("choices", []):
			if typeof(choice) == TYPE_DICTIONARY and str(choice.get("id", "")) == decision_id:
				target_id = str(choice.get("mission_id", ""))
	for candidate in _campaign_branches():
		if typeof(candidate) != TYPE_DICTIONARY:
			continue
		for choice in candidate.get("choices", []):
			if typeof(choice) == TYPE_DICTIONARY and str(choice.get("mission_id", "")) == current_id:
				target_id = str(candidate.get("reconverge_mission", ""))
	var target_index := _mission_index_for_id(target_id) if not target_id.is_empty() else mini(mission_index + 1, maxi(0, mission_catalog.size() - 1))
	mission_index = target_index if target_index >= 0 else mini(mission_index + 1, maxi(0, mission_catalog.size() - 1))
	_prepare_mission(mission_index)
	phase = GamePhase.TITLE
	front_end_screen = "sortie"

func _update_front_end_modes() -> void:
	var modes := get_node_or_null("/root/GameModeDirector")
	var count := int(modes.call("mode_count")) if modes != null and modes.has_method("mode_count") else 0
	if Input.is_action_just_pressed("cancel"):
		front_end_screen = "main_menu"
	elif count > 0 and Input.is_action_just_pressed("move_up"):
		mode_selection = posmod(mode_selection-1,count)
	elif count > 0 and Input.is_action_just_pressed("move_down"):
		mode_selection = posmod(mode_selection+1,count)
	elif count > 0 and Input.is_action_just_pressed("confirm") and modes.has_method("start_selected"):
		if not bool(modes.call("start_selected",self,mode_selection)):
			status_text = "LOCKED // CLEAR BLACK SKY CAMPAIGN"
			status_timer = 3.0

func _update_front_end_options() -> void:
	var settings := get_node_or_null("/root/SettingsDirector")
	var category_count:=int(settings.call("category_count")) if settings!=null and settings.has_method("category_count") else 1
	if Input.is_action_just_pressed("transform_craft"):
		option_category=posmod(option_category-1,category_count);option_selection=0;return
	if Input.is_action_just_pressed("fire_secondary"):
		option_category=posmod(option_category+1,category_count);option_selection=0;return
	var setting_count:=int(settings.call("category_setting_count",option_category)) if settings!=null and settings.has_method("category_setting_count") else 1
	if Input.is_action_just_pressed("cancel"):
		front_end_screen = "main_menu"
		return
	if Input.is_action_just_pressed("move_up"):
		option_selection = posmod(option_selection - 1, setting_count)
	elif Input.is_action_just_pressed("move_down"):
		option_selection = posmod(option_selection + 1, setting_count)
	var direction := 0
	if Input.is_action_just_pressed("move_left"): direction = -1
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("confirm"): direction = 1
	if direction != 0:
		if settings != null and settings.has_method("adjust_setting"):
			var global_index:=int(settings.call("category_global_index",option_category,option_selection)) if settings.has_method("category_global_index") else option_selection
			settings.call("adjust_setting",global_index,direction)

func _update_front_end_controls() -> void:
	if control_listening:
		return
	var bindings := get_node_or_null("/root/InputBindings")
	var count := int(bindings.call("binding_count")) if bindings != null and bindings.has_method("binding_count") else 1
	if Input.is_action_just_pressed("cancel"):
		front_end_screen = "main_menu"
	elif Input.is_action_just_pressed("move_up"):
		control_selection = posmod(control_selection - 1, count)
	elif Input.is_action_just_pressed("move_down"):
		control_selection = posmod(control_selection + 1, count)
	elif Input.is_action_just_pressed("confirm"):
		control_listening = true
	elif Input.is_physical_key_pressed(KEY_BACKSPACE) and bindings != null and bindings.has_method("restore_keyboard_defaults"):
		bindings.call("restore_keyboard_defaults")
		status_text = "FLIGHT CONTROLS RESTORED"
		status_timer = 2.0

func _input(event: InputEvent) -> void:
	if not control_listening or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	var key := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	if key == KEY_ESCAPE:
		control_listening = false
		get_viewport().set_input_as_handled()
		return
	if key in [KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE]:
		status_text = "KEY RESERVED FOR CONTROL STATION"
		status_timer = 2.0
		get_viewport().set_input_as_handled()
		return
	var bindings := get_node_or_null("/root/InputBindings")
	if bindings != null and bindings.has_method("rebind") and bool(bindings.call("rebind", control_selection, key)):
		status_text = "CONTROL ASSIGNED: %s" % OS.get_keycode_string(key).to_upper()
		status_timer = 2.0
	control_listening = false
	get_viewport().set_input_as_handled()

func _update_mission(delta: float) -> void:
	if player_loss_timer > 0.0:
		player_loss_timer = maxf(0.0, player_loss_timer - delta)
		if player_loss_timer <= 0.0:
			_finish_mission(false)
		return
	mission_time += delta
	ObjectiveRules.update_survival(current_objectives, objective_progress, mission_time)
	fire_timer = maxf(0.0, fire_timer - delta)
	secondary_timer = maxf(0.0, secondary_timer - delta)
	enemy_spawn_timer -= delta
	energy = EnergyRules.recharge(energy, _active_generator(), delta)
	wave = MissionStateRules.live_wave(_active_mission(), mission_time)
	_update_player(delta)
	var evasive := get_node_or_null("/root/EvasiveRollDirector")
	if evasive != null and evasive.has_method("update_maneuver"):
		evasive.call("update_maneuver", self, delta)
	_update_weapons()
	_update_bullets(delta)
	_update_enemy_bullets(delta)
	_update_pickups(delta)
	_update_enemies(delta)
	_resolve_combat()
	_try_spawn_boss()

	if ObjectiveRules.required_complete(current_objectives, objective_progress):
		_finish_mission(true)
		return

	if mission_time >= mission_duration:
		var hold_overtime := MissionFlowRules.should_hold_overtime(
			current_boss_id,
			current_objectives,
			objective_progress,
			enemies
		)
		if hold_overtime and mission_time < mission_duration + BOSS_OVERTIME_LIMIT_SECONDS:
			status_text = "OVERTIME - DESTROY THE BOSS"
			status_timer = 0.3
		elif hold_overtime:
			_finish_mission(false, "BOSS OVERTIME EXPIRED")
			return
		else:
			_finish_mission(false, "OBJECTIVES INCOMPLETE")
			return

	if enemy_spawn_timer <= 0.0 and not _boss_alive():
		_spawn_enemy()
		enemy_spawn_timer = _difficulty_spawn_interval(CombatRules.enemy_spawn_interval(wave))

func _load_content() -> void:
	var enemies_data = ContentCatalog.load_json("res://data/enemies.json")
	var weapons_data = ContentCatalog.load_json("res://data/weapons.json")
	var generators_data = ContentCatalog.load_json("res://data/generators.json")
	var missions_data = ContentCatalog.load_json("res://data/missions.json")
	var secret_missions_data = ContentCatalog.load_json("res://data/secret_missions.json")
	var spawn_data = ContentCatalog.load_json("res://data/spawn_profiles.json")
	var campaign_data = ContentCatalog.load_json("res://data/campaign.json")

	if typeof(enemies_data) == TYPE_DICTIONARY:
		enemy_catalog = enemies_data.get("enemies", [])
	if typeof(weapons_data) == TYPE_DICTIONARY:
		weapon_catalog = weapons_data.get("weapons", [])
	if typeof(generators_data) == TYPE_DICTIONARY:
		generator_catalog = generators_data.get("generators", [])
	if typeof(missions_data) == TYPE_DICTIONARY:
		mission_catalog = missions_data.get("missions", [])
	if typeof(secret_missions_data) == TYPE_DICTIONARY:
		secret_mission_catalog = secret_missions_data.get("missions", [])
	if typeof(spawn_data) == TYPE_DICTIONARY:
		spawn_profiles = spawn_data.get("profiles", [])
	if typeof(campaign_data) == TYPE_DICTIONARY:
		campaign = campaign_data
		var cfg := _campaign_config()
		mission_catalog = _ordered_missions(mission_catalog, cfg.get("missions", []))
		credits = int(cfg.get("starting_credits", 0))
		service_hull = MissionStateRules.starting_hull(cfg, 100)
		service_shield = MissionStateRules.starting_shield(cfg, 100)

func _ordered_missions(source: Array, authored_ids: Variant) -> Array:
	if typeof(authored_ids) != TYPE_ARRAY or authored_ids.is_empty():
		return source
	var by_id := ContentCatalog.by_id(source)
	var ordered: Array = []
	for mission_id in authored_ids:
		var mission = by_id.get(str(mission_id), {})
		if typeof(mission) == TYPE_DICTIONARY and not mission.is_empty():
			ordered.append(mission)
	return ordered if ordered.size() == source.size() else source

func _prepare_mission(index: int) -> void:
	if mission_catalog.is_empty():
		current_mission_name = "SCRAMBLE"
		current_briefing = "Intercept all incoming hostile aircraft."
		mission_duration = 150.0
		current_boss_id = ""
		current_environment = "coast"
		current_objectives = [
			{"id":"survive","type":"survive","seconds":150,"required":true}
		]
	else:
		var secret := _active_secret_mission()
		var mission: Dictionary = secret if not secret.is_empty() else mission_catalog[clampi(index, 0, mission_catalog.size() - 1)]
		current_mission_name = str(mission.get("name", "SCRAMBLE")).to_upper()
		current_briefing = str(mission.get("briefing", ""))
		mission_duration = float(mission.get("duration_seconds", 150.0))
		current_boss_id = str(mission.get("boss_id", ""))
		current_environment = str(mission.get("environment", "coast"))
		current_objectives = mission.get("objectives", [])
	objective_progress = ObjectiveRules.make_progress(current_objectives)
	_refresh_intelligence_unlocks()

func _active_mission() -> Dictionary:
	var secret := _active_secret_mission()
	if not secret.is_empty():
		return secret
	if mission_catalog.is_empty():
		return {}
	var mission = mission_catalog[clampi(mission_index, 0, mission_catalog.size() - 1)]
	return mission if typeof(mission) == TYPE_DICTIONARY else {}

func _campaign_config() -> Dictionary:
	if campaign.is_empty():
		return {}
	var nested = campaign.get("campaign", campaign)
	return nested if typeof(nested) == TYPE_DICTIONARY else {}

func _max_hull() -> int:
	return MissionStateRules.starting_hull(_campaign_config(), 100)

func _max_shield() -> int:
	return MissionStateRules.starting_shield(_campaign_config(), 100)

func _craft_float(method_name: String, fallback: float) -> float:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method(method_name):
		return float(director.call(method_name))
	return fallback

func _craft_primary_mount_offsets(weapon: Dictionary, projectile_count: int) -> Array[Vector2]:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("primary_mount_offsets"):
		var value = director.call("primary_mount_offsets", weapon, projectile_count)
		if typeof(value) == TYPE_ARRAY and value.size() == projectile_count:
			var result: Array[Vector2] = []
			for offset in value:
				result.append(offset if typeof(offset) == TYPE_VECTOR2 else Vector2(0, -16))
			return result
	var fallback: Array[Vector2] = []
	for _i in range(maxi(1, projectile_count)):
		fallback.append(Vector2(0, -16))
	return fallback

func _craft_form_name() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("current_form_name"):
		return str(director.call("current_form_name"))
	return "FIGHTER"

func _current_tech_era() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("mission_context"):
		var context = director.call("mission_context")
		if typeof(context) == TYPE_DICTIONARY:
			return str(context.get("tech_era", "advanced_conventional"))
	return "advanced_conventional"

func _target_damage_multiplier(enemy_class: String) -> float:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("target_damage_multiplier"):
		return maxf(0.1, float(director.call("target_damage_multiplier", enemy_class)))
	return 1.0

func _cinematic_blocks_launch() -> bool:
	var cinematic := get_node_or_null("/root/CampaignCinematicDirector")
	if cinematic == null or not cinematic.has_method("intercept_launch"):
		return false
	return bool(cinematic.call("intercept_launch", str(_active_mission().get("id", ""))))

func _cinematic_blocks_ending() -> bool:
	var cinematic := get_node_or_null("/root/CampaignCinematicDirector")
	if cinematic == null or not cinematic.has_method("intercept_ending"):
		return false
	return bool(cinematic.call("intercept_ending", str(_active_mission().get("id", ""))))

func _is_final_campaign_mission() -> bool:
	return active_secret_mission_id.is_empty() and not mission_catalog.is_empty() and mission_index >= mission_catalog.size() - 1

func _active_difficulty_id() -> String:
	var director := _difficulty()
	if director != null and director.has_method("active_profile"):
		var profile = director.call("active_profile")
		if typeof(profile) == TYPE_DICTIONARY:
			return str(profile.get("id", "combat"))
	return "combat"

func _complete_campaign() -> void:
	if campaign_completion_committed:
		return
	campaign_completion_committed = true
	campaign_completed = true
	campaign_completions += 1
	var difficulty_id := _active_difficulty_id()
	if not difficulty_id in completed_difficulties:
		completed_difficulties.append(difficulty_id)
	var save := get_node_or_null("/root/CampaignSave")
	if save != null and save.has_method("save_now"):
		save.call("save_now", self)
	if not _cinematic_blocks_ending():
		_return_from_credits()

func _return_from_credits() -> void:
	phase = GamePhase.TITLE
	front_end_screen = "main_menu"
	menu_selection = 0
	status_text = "BLACK SKY CLEAR // BOSS RUSH UNLOCKED"
	status_timer = 4.0

func _credits_blocking() -> bool:
	var credits_director := get_node_or_null("/root/CreditsDirector")
	return credits_director != null and credits_director.has_method("credits_active") and bool(credits_director.call("credits_active"))

func _mode_active() -> bool:
	return game_mode != "campaign"

func _advance_mode_result() -> void:
	var modes := get_node_or_null("/root/GameModeDirector")
	if modes != null and modes.has_method("advance_result"):
		modes.call("advance_result",self,mission_success)

func _start_mission() -> void:
	mission_rng.seed = RunSeedRules.mission_seed(mission_index)
	campaign_completion_committed = false
	phase = GamePhase.PLAYING
	mission_time = 0.0
	score = 0
	shots_fired = 0
	shots_hit = 0
	targets_destroyed = 0
	damage_taken = 0
	secrets_discovered = 0
	mission_reward_earned = 0
	repair_cost = 0
	mission_success = false
	hull = clampi(service_hull, 1, _max_hull())
	shield = clampi(service_shield, 0, _max_shield())
	bombs = 3
	wave = MissionStateRules.starting_wave(_active_mission())
	temporary_weapon_boost = 0
	energy = EnergyRules.capacity(_active_generator())
	boss_spawned = false
	enemy_spawn_timer = 0.35
	player_position = Vector2(320.0, 292.0)
	player_loss_timer = 0.0
	objective_progress = ObjectiveRules.make_progress(current_objectives)
	_clear_combat()

func _finish_mission(success: bool, failure_reason: String = "AIRFRAME LOST") -> void:
	if phase == GamePhase.RESULT:
		return
	phase = GamePhase.RESULT
	mission_success = success
	if success:
		_play_sfx(RetroSfxRules.REWARD_STINGER)
	if _mode_active():
		var modes := get_node_or_null("/root/GameModeDirector")
		if modes != null and modes.has_method("record_result"):
			modes.call("record_result",self,success,score)
		result_text = (
			"%s  ROUTE %02d/%02d  TOTAL %08d" % [mode_name,mode_route_index+1,mode_route_total,mode_total_score]
			if success else "%s  AIRFRAME LOST  %d REMAIN" % [mode_name,mode_lives]
		)
		repair_cost = 0
		_clear_combat()
		return
	if success:
		var base_reward := ProgressionRules.mission_reward(score)
		var objective_bonus := ObjectiveRules.bonus_credits(current_objectives, objective_progress)
		var progression: Dictionary = campaign.get("progression", {}) if typeof(campaign) == TYPE_DICTIONARY else {}
		var extras := RewardRules.extra_success_bonus(
			progression,
			hull,
			_max_hull(),
			current_boss_id,
			current_objectives,
			objective_progress,
			shots_fired,
			clampi(shots_hit, 0, shots_fired)
		)
		var total_reward := _difficulty_reward(base_reward + objective_bonus + int(extras.get("total", 0)))
		var secret_reward := maxi(0, int(_active_mission().get("reward_credits", 0))) if not active_secret_mission_id.is_empty() else 0
		mission_reward_earned = total_reward + secret_reward
		credits += total_reward + secret_reward
		if not active_secret_mission_id.is_empty():
			if not active_secret_mission_id in completed_secret_mission_ids:
				completed_secret_mission_ids.append(active_secret_mission_id)
		service_hull = clampi(hull, 1, _max_hull())
		service_shield = clampi(shield, 0, _max_shield())
		result_text = "MISSION COMPLETE  +%d" % total_reward
		var parts: Array[String] = []
		if objective_bonus > 0:
			parts.append("BONUS %d" % objective_bonus)
		if secret_reward > 0:
			parts.append("SECRET +%d" % secret_reward)
		if int(extras.get("no_damage", 0)) > 0:
			parts.append("NO DAMAGE +%d" % int(extras["no_damage"]))
		if int(extras.get("boss", 0)) > 0:
			parts.append("BOSS +%d" % int(extras["boss"]))
		if int(extras.get("accuracy", 0)) > 0:
			parts.append(
				"ACCURACY %d%% +%d" % [
					int(round(float(extras.get("accuracy_ratio", 0.0)) * 100.0)),
					int(extras["accuracy"])
				]
			)
		elif shots_fired > 0:
			parts.append(
				"ACCURACY %d%%" % int(round(float(extras.get("accuracy_ratio", 0.0)) * 100.0))
			)
		if not parts.is_empty():
			result_text += "  %s" % "  ".join(parts)
	else:
		result_text = "%s  PRESS R TO RETRY" % failure_reason
	repair_cost = ServiceRules.service_cost(hull, _max_hull(), int(_campaign_config().get("repair_cost_per_hull", 0)))
	_record_campaign_statistics(success)
	_clear_combat()

func _record_campaign_statistics(success: bool) -> void:
	var attempts := maxi(0, int(career_statistics.get("sorties_attempted", 0))) + 1
	var clears := maxi(0, int(career_statistics.get("sorties_cleared", 0))) + (1 if success else 0)
	var fired := maxi(0, shots_fired)
	var hits := clampi(shots_hit, 0, fired)
	career_statistics = {
		"sorties_attempted": attempts,
		"sorties_cleared": clears,
		"shots_fired": maxi(0, int(career_statistics.get("shots_fired", 0))) + fired,
		"shots_hit": maxi(0, int(career_statistics.get("shots_hit", 0))) + hits,
		"targets_destroyed": maxi(0, int(career_statistics.get("targets_destroyed", 0))) + maxi(0, targets_destroyed),
		"damage_taken": maxi(0, int(career_statistics.get("damage_taken", 0))) + maxi(0, damage_taken),
		"secrets_discovered": maxi(0, int(career_statistics.get("secrets_discovered", 0))) + maxi(0, secrets_discovered),
		"credits_earned": maxi(0, int(career_statistics.get("credits_earned", 0))) + maxi(0, mission_reward_earned),
		"best_score": maxi(maxi(0, int(career_statistics.get("best_score", 0))), maxi(0, score)),
		"best_accuracy_per_mille": maxi(
			maxi(0, int(career_statistics.get("best_accuracy_per_mille", 0))),
			int(round(1000.0 * float(hits) / float(fired))) if fired > 0 else 0
		)
	}

func _return_from_secret_sortie() -> void:
	active_secret_mission_id = ""
	_prepare_mission(mission_index)
	phase = GamePhase.TITLE
	front_end_screen = "secret_sorties"

func _clear_combat() -> void:
	bullets.clear()
	enemy_bullets.clear()
	enemies.clear()
	pickups.clear()
	temporary_weapon_boost = 0

func _primary_weapons() -> Array:
	var result: Array = []
	for weapon in weapon_catalog:
		if str(weapon.get("slot", "")) == "primary":
			result.append(weapon)
	return result

func _highest_available_primary_index(primaries: Array) -> int:
	var highest := 0
	var era := _current_tech_era()
	for i in range(primaries.size()):
		var required := str(primaries[i].get("unlock_tech_era", "advanced_conventional"))
		if TechProgressionRules.can_unlock(required, era):
			highest = i
	return highest

func _active_weapon() -> Dictionary:
	var primaries := _primary_weapons()
	if primaries.is_empty():
		return {
			"name":"Twin Cannon Mk I",
			"damage":1,
			"fire_interval":0.11,
			"projectile_speed":430.0,
			"projectiles":2,
			"spread_degrees":0.0,
			"energy_cost":0.0,
			"cost":0
		}
	var max_available := maxi(weapon_index, _highest_available_primary_index(primaries))
	var requested_index := WeaponPickupRules.effective_index(
		weapon_index,
		temporary_weapon_boost,
		primaries.size()
	)
	var effective_index := mini(requested_index, max_available)
	return primaries[effective_index]

func _active_generator() -> Dictionary:
	if generator_catalog.is_empty():
		return {
			"name":"Field Coil Mk I",
			"capacity":100.0,
			"recharge_per_second":26.0,
			"cost":0
		}
	return generator_catalog[clampi(generator_index, 0, generator_catalog.size() - 1)]

func _try_buy_next_weapon() -> void:
	var primaries := _primary_weapons()
	if primaries.is_empty():
		status_text = "NO PRIMARY LOADOUT"
		status_timer = 2.0
		return
	var next_index := clampi(weapon_index + 1, 0, primaries.size() - 1)
	if next_index == weapon_index:
		status_text = "MAXIMUM PRIMARY LOADOUT"
		status_timer = 2.0
		return
	var next_weapon: Dictionary = primaries[next_index]
	var required_era := str(next_weapon.get("unlock_tech_era", "advanced_conventional"))
	if not TechProgressionRules.can_unlock(required_era, _current_tech_era()):
		status_text = "TECH LOCK - %s" % TechProgressionRules.era_name(required_era)
		status_timer = 2.0
		return
	var result := ProgressionRules.next_weapon_index(weapon_index, primaries, credits)
	if bool(result["changed"]):
		weapon_index = int(result["index"])
		credits = int(result["credits"])
		status_text = "UPGRADE PURCHASED: %s" % str(_active_weapon().get("name", "WEAPON")).to_upper()
		_play_sfx(RetroSfxRules.UI_PURCHASE)
	else:
		status_text = "NEED %d CREDITS" % int(next_weapon.get("cost", 0))
	status_timer = 2.0

func _try_buy_next_generator() -> void:
	if generator_catalog.is_empty():
		status_text = "MAXIMUM GENERATOR"
		status_timer = 2.0
		return
	var next_index := clampi(generator_index + 1, 0, generator_catalog.size() - 1)
	if next_index == generator_index:
		status_text = "MAXIMUM GENERATOR"
		status_timer = 2.0
		return
	var next_generator: Dictionary = generator_catalog[next_index]
	var required_era := str(next_generator.get("unlock_tech_era", "advanced_conventional"))
	if not TechProgressionRules.can_unlock(required_era, _current_tech_era()):
		status_text = "TECH LOCK - %s" % TechProgressionRules.era_name(required_era)
		status_timer = 2.0
		return
	var result := ProgressionRules.next_weapon_index(generator_index, generator_catalog, credits)
	if bool(result["changed"]):
		generator_index = int(result["index"])
		credits = int(result["credits"])
		status_text = "GENERATOR PURCHASED: %s" % str(_active_generator().get("name", "GENERATOR")).to_upper()
		_play_sfx(RetroSfxRules.UI_PURCHASE)
	else:
		status_text = "GENERATOR NEEDS %d CREDITS" % int(next_generator.get("cost", 0))
	status_timer = 2.0

func _service_hull_full() -> void:
	var cfg := _campaign_config()
	var result := ServiceRules.service_full(
		credits,
		service_hull,
		_max_hull(),
		int(cfg.get("repair_cost_per_hull", 0))
	)
	if bool(result.get("changed", false)):
		service_hull = int(result["value"])
		credits = int(result["credits"])
		status_text = "HULL SERVICED -%d" % int(result["cost"])
		_play_sfx(RetroSfxRules.UI_SERVICE)
	else:
		status_text = _service_failure("HULL", result)
	status_timer = 3.0

func _service_shield_full() -> void:
	var cfg := _campaign_config()
	var result := ServiceRules.service_full(
		credits,
		service_shield,
		maxi(1, _max_shield()),
		int(cfg.get("shield_recharge_cost_per_point", 0))
	)
	if bool(result.get("changed", false)):
		service_shield = mini(_max_shield(), int(result["value"]))
		credits = int(result["credits"])
		status_text = "SHIELD RECHARGED -%d" % int(result["cost"])
		_play_sfx(RetroSfxRules.UI_SERVICE)
	else:
		status_text = _service_failure("SHIELD", result)
	status_timer = 3.0

func _service_failure(label: String, result: Dictionary) -> String:
	var reason := str(result.get("reason", "NO_CHANGE"))
	if reason == "FULL":
		return "%s ALREADY FULL" % label
	if reason == "INSUFFICIENT_CREDITS":
		return "%s SERVICE NEEDS %d CREDITS" % [label, int(result.get("cost", 0))]
	return "%s SERVICE UNAVAILABLE" % label

func _play_sfx(event_id: String) -> void:
	var audio := get_node_or_null("/root/RetroSfxDirector")
	if audio != null and audio.has_method("play_event"):
		audio.call("play_event", event_id)

func _service_status() -> String:
	var cfg := _campaign_config()
	var hull_cost := ServiceRules.service_cost(
		service_hull,
		_max_hull(),
		int(cfg.get("repair_cost_per_hull", 0))
	)
	var shield_cost := ServiceRules.service_cost(
		service_shield,
		maxi(1, _max_shield()),
		int(cfg.get("shield_recharge_cost_per_point", 0))
	)
	var hull_quote := "FULL" if hull_cost <= 0 else str(hull_cost)
	var shield_quote := "FULL" if shield_cost <= 0 else str(shield_cost)
	return "AIRFRAME H%03d S%03d  H REPAIR %s  J SHIELD %s" % [
		service_hull,
		service_shield,
		hull_quote,
		shield_quote
	]

func _update_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_mult := _craft_float("movement_multiplier", 1.0)
	player_position += movement * PLAYER_SPEED * speed_mult * delta
	player_position.x = clampf(
		player_position.x,
		PLAYFIELD.position.x + 12.0,
		PLAYFIELD.end.x - 12.0
	)
	player_position.y = clampf(
		player_position.y,
		PLAYFIELD.position.y + 16.0,
		PLAYFIELD.end.y - 12.0
	)

func _update_weapons() -> void:
	var weapon := _active_weapon()
	if (
		Input.is_action_pressed("fire_primary")
		and fire_timer <= 0.0
		and EnergyRules.can_fire(energy, weapon)
	):
		fire_timer = float(weapon.get("fire_interval", 0.11))
		energy = EnergyRules.consume(energy, weapon)
		var count := maxi(1, int(weapon.get("projectiles", 1)))
		shots_fired += count
		var spread := (
			float(weapon.get("spread_degrees", 0.0))
			* _craft_float("primary_spread_multiplier", 1.0)
		)
		var damage := maxi(
			1,
			int(round(
				float(weapon.get("damage", 1))
				* _craft_float("primary_damage_multiplier", 1.0)
			))
		)
		var mount_offsets := _craft_primary_mount_offsets(weapon, count)
		for i in range(count):
			var angle := 0.0
			if count > 1:
				angle = deg_to_rad(
					lerpf(-spread, spread, float(i) / float(count - 1))
				)
			var bullet := {
				"position": player_position + mount_offsets[i],
				"velocity": Vector2.UP.rotated(angle) * float(weapon.get("projectile_speed", 430.0)),
				"damage": damage,
				"weapon_id": str(weapon.get("id", "")),
				"pierce_remaining": clampi(int(weapon.get("pierce", 0)), 0, 4)
			}
			if int(bullet["pierce_remaining"]) > 0:
				bullet["kinetic"] = true
			bullets.append(bullet)

	if Input.is_action_just_pressed("fire_secondary") and secondary_timer <= 0.0 and bombs > 0:
		bombs -= 1
		secondary_timer = 1.0
		var survivors: Array = []
		var boss_damaged := false
		for enemy in enemies:
			if typeof(enemy) != TYPE_DICTIONARY:
				continue
			if bool(enemy.get("boss", false)):
				var boss: Dictionary = enemy.duplicate(true)
				var hp := maxi(1, int(boss.get("hp", 1)))
				var max_hp := maxi(hp, int(boss.get("max_hp", hp)))
				boss["hp"] = BombRules.apply_nonlethal_boss_damage(hp, max_hp)
				boss["max_hp"] = max_hp
				boss["last_hp"] = int(boss["hp"])
				survivors.append(boss)
				boss_damaged = true
			else:
				_register_destroy(enemy)
				score += _mode_score_value(75 + int(enemy.get("hp", 1)) * 25)
		enemies = survivors
		enemy_bullets.clear()
		if boss_damaged:
			status_text = "BOMB STRIKE - BOSS DAMAGED"
			status_timer = 1.5

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var position: Vector2 = bullet["position"]
		position += bullet.get("velocity", Vector2.UP * 430.0) * delta
		bullet["position"] = position
		bullets[i] = bullet
		if not PLAYFIELD.grow(24).has_point(position):
			bullets.remove_at(i)

func _update_enemy_bullets(delta: float) -> void:
	for i in range(enemy_bullets.size() - 1, -1, -1):
		var shot: Dictionary = enemy_bullets[i]
		var position: Vector2 = shot["position"]
		position += shot["velocity"] * delta
		shot["position"] = position
		enemy_bullets[i] = shot
		var projectile_hit_radius_sq := _craft_float("projectile_hit_radius_sq", 120.0) * _evasive_collision_multiplier()
		if position.distance_squared_to(player_position) <= projectile_hit_radius_sq:
			_apply_damage(int(shot.get("damage", 8)))
			if phase != GamePhase.PLAYING:
				return
			if i < enemy_bullets.size():
				enemy_bullets.remove_at(i)
		elif not PLAYFIELD.grow(32).has_point(position):
			enemy_bullets.remove_at(i)

func _update_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[i]
		var position: Vector2 = pickup["position"]
		position.y += 55.0 * delta
		pickup["position"] = position
		pickups[i] = pickup
		if position.distance_squared_to(player_position) <= 260.0:
			_apply_pickup(str(pickup["kind"]))
			pickups.remove_at(i)
		elif position.y > PLAYFIELD.end.y + 20:
			pickups.remove_at(i)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy["age"] = float(enemy["age"]) + delta
		enemy["fire_timer"] = float(enemy["fire_timer"]) - delta
		enemy["recoil_timer"] = maxf(0.0, float(enemy.get("recoil_timer", 0.0)) - delta)
		enemy["hit_timer"] = maxf(0.0, float(enemy.get("hit_timer", 0.0)) - delta)
		var position: Vector2 = enemy["position"]
		var previous_x := position.x
		var is_boss := bool(enemy.get("boss", false))
		var pursuit_charge := float(enemy.get("hypersonic_charge", 0.0))
		var player_hypersonic := _player_hypersonic_active()
		if bool(enemy.get("hypersonic_capable", false)) and player_hypersonic:
			pursuit_charge = minf(HypersonicRules.ENEMY_CHARGE_SECONDS, pursuit_charge + delta)
		else:
			pursuit_charge = maxf(0.0, pursuit_charge - delta * 1.8)
		var pursuit_ratio := HypersonicRules.enemy_pursuit_ratio(pursuit_charge)
		var pursuit_active := pursuit_ratio >= 0.999
		if pursuit_active and not bool(enemy.get("hypersonic_active", false)):
			enemy["hypersonic_boom_age"] = 0.0
		enemy["hypersonic_charge"] = pursuit_charge
		enemy["hypersonic_ratio"] = pursuit_ratio
		enemy["hypersonic_active"] = pursuit_active
		enemy["hypersonic_boom_age"] = float(enemy.get("hypersonic_boom_age", 99.0)) + delta

		if is_boss:
			if position.y < 105.0:
				position.y += float(enemy["speed"]) * delta
			position.x += (
				sin(float(enemy["age"]) * float(enemy["turn_rate"]) + float(enemy["phase"]))
				* float(enemy["drift"])
				* delta
			)
			position.x = clampf(
				position.x,
				PLAYFIELD.position.x + 18.0,
				PLAYFIELD.end.x - 18.0
			)
		elif pursuit_active:
			position.y = move_toward(position.y, player_position.y - 92.0, float(enemy["speed"]) * HypersonicRules.ENEMY_SPEED_MULTIPLIER * delta)
			position.x = move_toward(position.x, player_position.x, float(enemy["speed"]) * 0.72 * delta)
		else:
			position.y += float(enemy["speed"]) * delta
			var pattern := str(enemy.get("pattern", "sine_dive"))
			var anchor_x := float(enemy.get("pattern_anchor_x", position.x))
			enemy["pattern_anchor_x"] = anchor_x
			if pattern in MovementPatternRules.supported_patterns():
				position = MovementPatternRules.adjusted_position(
					pattern,
					position,
					player_position,
					float(enemy["age"]),
					delta,
					anchor_x
				)
			else:
				position.x += (
					sin(float(enemy["age"]) * float(enemy["turn_rate"]) + float(enemy["phase"]))
					* float(enemy["drift"])
					* delta
				)
			position = MovementPatternRules.clamp_x(
				position,
				PLAYFIELD.position.x + 18.0,
				PLAYFIELD.end.x - 18.0
			)

		enemy["position"] = position
		var lateral_delta := position.x - previous_x
		var bank_target := 0.0
		if absf(lateral_delta) > maxf(0.12, delta * 2.0):
			bank_target = signf(lateral_delta)
		enemy["visual_bank"] = move_toward(float(enemy.get("visual_bank", 0.0)), bank_target, delta * 5.0)
		var missile_lock_ready := true
		if str(enemy.get("weapon", "")) == "missile" and not is_boss:
			var in_envelope := position.distance_to(player_position) <= 430.0
			var lock_ratio := float(enemy.get("missile_lock_ratio", 0.0))
			lock_ratio = move_toward(lock_ratio, 1.0 if in_envelope else 0.0, delta / (0.82 if pursuit_active else 1.20))
			enemy["missile_lock_ratio"] = lock_ratio
			missile_lock_ready = lock_ratio >= 0.999
		if float(enemy["fire_timer"]) <= 0.0 and position.y > PLAYFIELD.position.y and missile_lock_ready:
			_fire_enemy_weapon(enemy)
			if str(enemy.get("weapon", "")) == "missile": enemy["missile_lock_ratio"] = 0.0
			enemy["fire_timer"] = _difficulty_fire_interval(ProjectileRules.enemy_fire_interval(
				str(enemy.get("weapon", "single_burst")),
				wave
			))
		enemies[i] = enemy
		if not is_boss and position.y > PLAYFIELD.end.y + 22:
			enemies.remove_at(i)

func _make_enemy_shot(
	origin: Vector2,
	velocity: Vector2,
	damage: int,
	homing := false
) -> Dictionary:
	var shot := {
		"position": origin,
		"velocity": velocity,
		"damage": damage
	}
	if homing:
		shot["homing"] = true
		shot["homing_speed"] = maxf(1.0, velocity.length())
		shot["turn_rate"] = 1.8
		shot["life"] = 5.0
	return shot

func _fire_enemy_weapon(enemy: Dictionary) -> void:
	enemy["recoil_timer"] = 0.10
	var origin: Vector2 = enemy["position"]
	var weapon_id := str(enemy.get("weapon", "single_burst"))
	var damage := 14 if bool(enemy.get("boss", false)) else 8
	var velocity := ProjectileRules.enemy_shot_velocity(
		origin,
		player_position,
		_difficulty_projectile_speed(ProjectileRules.enemy_projectile_speed(weapon_id))
	)
	var is_missile := weapon_id == "missile"
	enemy_bullets.append(_make_enemy_shot(origin, velocity, damage, is_missile))
	if weapon_id == "twin_burst":
		enemy_bullets.append(_make_enemy_shot(origin, velocity.rotated(0.16), damage))
		enemy_bullets.append(_make_enemy_shot(origin, velocity.rotated(-0.16), damage))
	elif is_missile:
		enemy_bullets.append(_make_enemy_shot(origin, velocity.rotated(0.08), damage + 3, true))
		_register_enemy_missile_launch(2)

func _register_enemy_missile_launch(count: int = 1) -> void:
	enemy_missiles_launched += maxi(0, count)

func _resolve_combat() -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var consume_bullet := false
		var bullet: Dictionary = bullets[bullet_index]
		for enemy_index in range(enemies.size() - 1, -1, -1):
			var radius_sq := 420.0 if bool(enemies[enemy_index].get("boss", false)) else 196.0
			if bullet["position"].distance_squared_to(enemies[enemy_index]["position"]) <= radius_sq:
				var enemy_class := str(enemies[enemy_index].get("category", "air"))
				var applied_damage := maxi(
					1,
					int(round(float(bullet["damage"]) * _target_damage_multiplier(enemy_class)))
				)
				enemies[enemy_index]["hp"] -= applied_damage
				enemies[enemy_index]["hit_timer"] = 0.14
				if not bool(bullet.get("accuracy_registered", false)):
					shots_hit += 1
					bullet["accuracy_registered"] = true
				if int(enemies[enemy_index]["hp"]) <= 0:
					var destroyed: Dictionary = enemies[enemy_index]
					_register_destroy(destroyed)
					score += _mode_score_value(int(destroyed["value"]))
					_maybe_drop_pickup(
						destroyed["position"],
						bool(destroyed.get("boss", false))
					)
					enemies.remove_at(enemy_index)

				var pierce_remaining := int(bullet.get("pierce_remaining", 0))
				if pierce_remaining > 0:
					bullet["pierce_remaining"] = pierce_remaining - 1
					var velocity: Vector2 = bullet.get("velocity", Vector2.UP * 430.0)
					if velocity.length_squared() > 0.001:
						bullet["position"] = (
							Vector2(bullet["position"])
							+ velocity.normalized() * 28.0
						)
					bullets[bullet_index] = bullet
					continue

				consume_bullet = true
				break

		if consume_bullet:
			bullets.remove_at(bullet_index)
		else:
			bullets[bullet_index] = bullet

	var player_contact_radius_sq := _craft_float("collision_radius_sq", 420.0) * _evasive_collision_multiplier()
	for enemy_index in range(enemies.size() - 1, -1, -1):
		if (
			enemies[enemy_index]["position"].distance_squared_to(player_position)
			<= player_contact_radius_sq
		):
			_apply_damage(24 if bool(enemies[enemy_index].get("boss", false)) else 18)
			if phase != GamePhase.PLAYING:
				return
			if not bool(enemies[enemy_index].get("boss", false)):
				enemies.remove_at(enemy_index)

func _register_destroy(enemy: Dictionary) -> void:
	targets_destroyed += 1
	ObjectiveRules.register_destroy(
		current_objectives,
		objective_progress,
		str(enemy.get("id", ""))
	)

func _maybe_drop_pickup(position: Vector2, guaranteed := false) -> void:
	var kind := "weapon" if guaranteed else ProjectileRules.pickup_kind_for_roll(_difficulty_pickup_roll(mission_rng.randf()))
	if kind != "":
		pickups.append({"position": position, "kind": kind})

func _apply_pickup(kind: String) -> void:
	match kind:
		"shield":
			shield = mini(_max_shield(), shield + 35)
		"repair":
			hull = mini(_max_hull(), hull + 25)
		"bomb":
			bombs = mini(5, bombs + 1)
		"weapon":
			var primaries := _primary_weapons()
			if not primaries.is_empty():
				var max_allowed := maxi(
					weapon_index,
					_highest_available_primary_index(primaries)
				)
				var max_boost := maxi(0, max_allowed - weapon_index)
				temporary_weapon_boost = mini(
					max_boost,
					temporary_weapon_boost + 1
				)

func _apply_damage(amount: int) -> void:
	if "--capture-invulnerable" in OS.get_cmdline_user_args():
		return
	var previous_integrity := hull + shield
	var previous_shield := shield
	var state := CombatRules.apply_shielded_damage(hull, shield, amount)
	hull = int(state["hull"])
	shield = int(state["shield"])
	damage_taken += maxi(0, previous_integrity - hull - shield)
	if previous_shield > 0 and shield <= 0:
		status_text = "SHIELDS DOWN // HULL EXPOSED"
		status_timer = 1.4
	elif hull > 0 and hull <= maxi(1, int(round(float(_max_hull()) * 0.25))):
		status_text = "HULL CRITICAL"
		status_timer = 1.0
	if hull <= 0:
		player_loss_timer = PLAYER_LOSS_SEQUENCE_SECONDS

func _find_enemy_archetype(id: String) -> Dictionary:
	for enemy in enemy_catalog:
		if str(enemy.get("id", "")) == id:
			return enemy
	return {}

func _spawn_candidates() -> Array:
	var allowed_ids: Array = []
	for profile in spawn_profiles:
		if (
			str(profile.get("environment", "")) == current_environment
			and wave >= int(profile.get("min_wave", 1))
			and wave <= int(profile.get("max_wave", 99))
		):
			allowed_ids = profile.get("enemy_ids", [])
			break
	if allowed_ids.is_empty():
		return []
	var candidates: Array = []
	for item in enemy_catalog:
		if bool(item.get("boss", false)):
			continue
		if str(item.get("id", "")) in allowed_ids:
			candidates.append(item)
	return candidates

func _spawn_enemy(archetype: Dictionary = {}) -> void:
	if archetype.is_empty():
		var candidates := _spawn_candidates()
		if candidates.is_empty():
			return
		var elite_pick := _difficulty_elite_index(candidates.size(),mission_rng.randf())
		if elite_pick >= 0:
			candidates.sort_custom(func(a: Dictionary,b: Dictionary): return int(a.get("value",0)) < int(b.get("value",0)))
			archetype = candidates[mission_rng.randi_range(elite_pick,candidates.size()-1)]
		else:
			archetype = candidates[mission_rng.randi_range(0, candidates.size() - 1)]

	var is_boss := bool(archetype.get("boss", false))
	var elite := not is_boss and mission_rng.randf() < _difficulty_elite_chance()
	var enemy_class := str(archetype.get("class", "air"))
	var hp := maxi(
		1,
		int(archetype.get("hp", 1)) + (0 if is_boss else int(wave / 5))
	)
	hp = _mode_enemy_hp(_difficulty_enemy_hp(hp,elite))
	var x := (
		PLAYFIELD.get_center().x
		if is_boss
		else EnvironmentRules.surface_spawn_x(
			current_environment,
			str(mission_catalog[mission_index].get("environment_variant", "")) if mission_index >= 0 and mission_index < mission_catalog.size() else "",
			enemy_class,
			mission_rng.randf(),
			PLAYFIELD.position.x + 24,
			PLAYFIELD.end.x - 24
		)
	)
	var speed_bias := 0.0
	if enemy_class == "air":
		speed_bias = 10.0
	elif enemy_class == "sea":
		speed_bias = -8.0
	var drift := 28.0
	if not is_boss:
		drift = 10.0 if enemy_class == "ground" else mission_rng.randf_range(16, 38)

	enemies.append({
		"id": str(archetype.get("id", "bogey")),
		"category": enemy_class,
		"faction": str(archetype.get("faction", "mercenary")),
		"position": Vector2(x, PLAYFIELD.position.y - 18),
		"speed": _mode_enemy_speed(_difficulty_enemy_speed(float(archetype.get("speed", 72)) + speed_bias + (0.0 if is_boss else float(wave) * 4.0))),
		"drift": drift,
		"turn_rate": 0.75 if is_boss else mission_rng.randf_range(1.1, 2.4),
		"phase": mission_rng.randf_range(0, TAU),
		"age": 0.0,
		"hp": hp,
		"max_hp": hp,
		"value": _difficulty_elite_value(CombatRules.destroy_value(int(archetype.get("value", 100)), wave)) if elite else CombatRules.destroy_value(int(archetype.get("value", 100)), wave),
		"elite": elite,
		"weapon": str(archetype.get("weapon", "single_burst")),
		"hypersonic_capable": HypersonicRules.enemy_can_pursue(archetype),
		"hypersonic_charge": 0.0,
		"hypersonic_ratio": 0.0,
		"hypersonic_active": false,
		"hypersonic_boom_age": 99.0,
		"pattern": str(archetype.get("pattern", "sine_dive")),
		"pattern_anchor_x": x,
		"fire_timer": mission_rng.randf_range(0.5, 1.6),
		"recoil_timer": 0.0,
		"boss": is_boss
	})

func _player_hypersonic_active() -> bool:
	var craft := get_node_or_null("/root/CraftFormDirector")
	return craft != null and craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))

func _mode_enemy_hp(base_hp: int) -> int:
	var modes := get_node_or_null("/root/GameModeDirector")
	return int(modes.call("enemy_hp",base_hp)) if modes != null and modes.has_method("enemy_hp") else base_hp

func _mode_enemy_speed(base_speed: float) -> float:
	var modes := get_node_or_null("/root/GameModeDirector")
	return float(modes.call("enemy_speed",base_speed)) if modes != null and modes.has_method("enemy_speed") else base_speed

func _mode_score_value(base_score: int) -> int:
	var modes := get_node_or_null("/root/GameModeDirector")
	return int(modes.call("score_value",base_score)) if modes != null and modes.has_method("score_value") else base_score

func _difficulty() -> Node: return get_node_or_null("/root/DifficultyDirector")
func _difficulty_enemy_hp(base: int, elite: bool) -> int:
	var director := _difficulty(); return int(director.call("enemy_hp",base,elite)) if director != null else base
func _difficulty_enemy_speed(base: float) -> float:
	var director := _difficulty(); return float(director.call("enemy_speed",base)) if director != null else base
func _difficulty_spawn_interval(base: float) -> float:
	var director := _difficulty(); return float(director.call("spawn_interval",base)) if director != null else base
func _difficulty_fire_interval(base: float) -> float:
	var director := _difficulty(); return float(director.call("fire_interval",base)) if director != null else base
func _difficulty_projectile_speed(base: float) -> float:
	var director := _difficulty(); return float(director.call("projectile_speed",base)) if director != null else base
func _difficulty_pickup_roll(roll: float) -> float:
	var director := _difficulty(); return float(director.call("pickup_roll",roll)) if director != null else roll
func _difficulty_reward(base: int) -> int:
	var director := _difficulty(); return int(director.call("reward",base)) if director != null else base
func _difficulty_elite_index(count: int, roll: float) -> int:
	var director := _difficulty(); return int(director.call("elite_index",count,roll)) if director != null else -1
func _difficulty_elite_chance() -> float:
	var director := _difficulty(); return float(director.call("active_profile").get("elite_chance",0.0)) if director != null else 0.0
func _difficulty_elite_value(base: int) -> int:
	var director := _difficulty(); return int(director.call("elite_value",base)) if director != null else base

func _try_spawn_boss() -> void:
	if boss_spawned or current_boss_id == "" or mission_time < mission_duration * 0.72:
		return
	var boss := _find_enemy_archetype(current_boss_id)
	if not boss.is_empty():
		boss_spawned = true
		_spawn_enemy(boss)

func _boss_alive() -> bool:
	for enemy in enemies:
		if bool(enemy.get("boss", false)):
			return true
	return false

func _configure_input() -> void:
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_up", KEY_UP)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_down", KEY_DOWN)
	_add_key_action("fire_primary", KEY_SPACE)
	_add_key_action("fire_secondary", KEY_X)
	_add_key_action("confirm", KEY_ENTER)
	_add_key_action("cancel", KEY_ESCAPE)
	_add_key_action("restart", KEY_R)
	_add_key_action("upgrade", KEY_U)
	_add_key_action("upgrade_generator", KEY_G)
	_add_key_action("service_hull", KEY_H)
	_add_key_action("service_shield", KEY_J)
	_add_key_action("evasive_roll", KEY_C)

func _evasive_collision_multiplier() -> float:
	var evasive := get_node_or_null("/root/EvasiveRollDirector")
	var minimum_squared := EvasiveRollRules.MIN_HIT_PROFILE * EvasiveRollRules.MIN_HIT_PROFILE
	return clampf(float(evasive.call("collision_multiplier")), minimum_squared, 1.0) if evasive != null and evasive.has_method("collision_multiplier") else 1.0

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("10151b"))
	if phase == GamePhase.PLAYING:
		_draw_gameplay()

func _draw_gameplay() -> void:
	_draw_neutral_depth_fallback()
	# CombatArtDirector and ProjectileCueDirector are the sole production
	# presentation owners for craft, enemies and projectiles. Simulation and
	# collision stay here, but duplicate prototype geometry must not bleed
	# through altitude-scaled silhouettes or weapon-specific cues.
	# Pickup simulation stays here; CombatArtDirector owns the authored
	# recovery-pod sprites and their held-frame acquisition pulse.

func _draw_neutral_depth_fallback() -> void:
	# EnvironmentDirector normally covers this layer with the mission's authored
	# biome stack. Keep a seamless, production-authored depth plate underneath so
	# scene startup and altitude/profile transitions can never expose a debug grid.
	var source_y := fposmod(-mission_time * 12.0, float(NEUTRAL_DEPTH_TILE.get_height()))
	var first_height := minf(PLAYFIELD.size.y, float(NEUTRAL_DEPTH_TILE.get_height()) - source_y)
	draw_texture_rect_region(
		NEUTRAL_DEPTH_TILE,
		Rect2(PLAYFIELD.position, Vector2(PLAYFIELD.size.x, first_height)),
		Rect2(Vector2(PLAYFIELD.position.x, source_y), Vector2(PLAYFIELD.size.x, first_height))
	)
	var remaining_height := PLAYFIELD.size.y - first_height
	if remaining_height > 0.0:
		draw_texture_rect_region(
			NEUTRAL_DEPTH_TILE,
			Rect2(Vector2(PLAYFIELD.position.x, PLAYFIELD.position.y + first_height), Vector2(PLAYFIELD.size.x, remaining_height)),
			Rect2(Vector2(PLAYFIELD.position.x, 0.0), Vector2(PLAYFIELD.size.x, remaining_height))
		)
