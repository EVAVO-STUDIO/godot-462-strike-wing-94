extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const RunSeedRules = preload("res://scripts/run_seed_rules.gd")
const BombRules = preload("res://scripts/bomb_rules.gd")
const MissionStateRules = preload("res://scripts/mission_state_rules.gd")
const WeaponPickupRules = preload("res://scripts/weapon_pickup_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_content()
	_test_combat()
	_test_projectiles()
	_test_progression()
	_test_objectives()
	_test_bosses()
	_test_run_seeds()
	_test_bombs()
	_test_mission_state()
	_test_direct_runtime_ownership()
	_test_weapon_pickups()
	if failures.is_empty():
		print("Strike Wing runtime self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_content() -> void:
	var weapons = ContentCatalog.load_json("res://data/weapons.json")
	var generators = ContentCatalog.load_json("res://data/generators.json")
	var enemies = ContentCatalog.load_json("res://data/enemies.json")
	var missions = ContentCatalog.load_json("res://data/missions.json")
	var profiles = ContentCatalog.load_json("res://data/spawn_profiles.json")
	var campaign = ContentCatalog.load_json("res://data/campaign.json")
	_expect(typeof(weapons) == TYPE_DICTIONARY and not weapons.get("weapons", []).is_empty(), "weapons catalogue should load through ContentCatalog")
	_expect(typeof(generators) == TYPE_DICTIONARY and not generators.get("generators", []).is_empty(), "generator catalogue should load through ContentCatalog")
	_expect(typeof(enemies) == TYPE_DICTIONARY and not enemies.get("enemies", []).is_empty(), "enemy catalogue should load through ContentCatalog")
	_expect(typeof(missions) == TYPE_DICTIONARY and not missions.get("missions", []).is_empty(), "mission catalogue should load through ContentCatalog")
	_expect(typeof(profiles) == TYPE_DICTIONARY and not profiles.get("profiles", []).is_empty(), "spawn profiles should load through ContentCatalog")
	_expect(typeof(campaign) == TYPE_DICTIONARY and typeof(campaign.get("campaign", {})) == TYPE_DICTIONARY, "campaign catalogue should load through ContentCatalog")

func _test_combat() -> void:
	var absorbed := CombatRules.apply_shielded_damage(100, 20, 15)
	_expect(int(absorbed["hull"]) == 100 and int(absorbed["shield"]) == 5, "shield should absorb damage before hull")
	var overflow := CombatRules.apply_shielded_damage(100, 10, 25)
	_expect(int(overflow["hull"]) == 85 and int(overflow["shield"]) == 0, "overflow damage should reach hull")
	_expect(CombatRules.wave_for_time(0.0) == 1, "wave should start at one")
	_expect(CombatRules.wave_for_time(40.0) == 3, "wave progression should advance every twenty seconds")
	_expect(CombatRules.enemy_spawn_interval(999) >= 0.28, "spawn interval must retain a safe lower bound")

func _test_projectiles() -> void:
	var velocity := ProjectileRules.enemy_shot_velocity(Vector2.ZERO, Vector2(0, 10), 100.0)
	_expect(absf(velocity.length() - 100.0) < 0.01, "enemy shot velocity should preserve requested speed")
	_expect(velocity.y > 0.0, "enemy shot should aim toward target")
	_expect(ProjectileRules.enemy_projectile_speed("missile") > 0.0, "missile speed must be positive")
	_expect(ProjectileRules.enemy_fire_interval("twin_burst", 20) >= 0.55, "enemy fire interval must retain a safe lower bound")

func _test_progression() -> void:
	_expect(ProgressionRules.mission_reward(5000) == 1500, "mission reward should include score conversion")
	var purchase := ProgressionRules.purchase(1000, 400)
	_expect(bool(purchase["ok"]) and int(purchase["credits"]) == 600, "valid purchase should deduct credits")
	var weapons := [{"cost":0}, {"cost":400}, {"cost":900}]
	var upgrade := ProgressionRules.next_weapon_index(0, weapons, 500)
	_expect(bool(upgrade["changed"]) and int(upgrade["index"]) == 1 and int(upgrade["credits"]) == 100, "weapon progression should purchase the next affordable tier")

func _test_objectives() -> void:
	var objectives := [
		{"id":"survive","type":"survive","seconds":10,"required":true},
		{"id":"ace","type":"destroy_enemy","enemy_id":"ace","count":1,"required":true},
		{"id":"bonus","type":"destroy_count","count":2,"required":false,"bonus_credits":250}
	]
	var progress := ObjectiveRules.make_progress(objectives)
	ObjectiveRules.update_survival(objectives, progress, 10.0)
	ObjectiveRules.register_destroy(objectives, progress, "ace")
	ObjectiveRules.register_destroy(objectives, progress, "other")
	_expect(ObjectiveRules.required_complete(objectives, progress), "required objective set should complete after survival and target kill")
	_expect(ObjectiveRules.bonus_credits(objectives, progress) == 250, "completed bonus objective should award configured credits")

func _test_bosses() -> void:
	_expect(BossRules.phase_for(100, 100) == 1, "healthy boss should begin in phase one")
	_expect(BossRules.phase_for(60, 100) == 2, "boss should enter phase two below two-thirds health")
	_expect(BossRules.phase_for(20, 100) == 3, "boss should enter phase three below one-third health")
	_expect(BossRules.phase_fire_multiplier(3) < BossRules.phase_fire_multiplier(1), "later boss phases should fire faster")
	_expect(BossRules.volley_count("missile", 3) >= 3, "phase-three missile boss should emit a multi-shot salvo")
	_expect(BossRules.weak_point_multiplier(3) > 1.0, "phase-three weak point should increase damage")

func _test_run_seeds() -> void:
	var mission_zero := RunSeedRules.mission_seed(0)
	var mission_zero_retry := RunSeedRules.mission_seed(0)
	var mission_one := RunSeedRules.mission_seed(1)
	_expect(mission_zero == mission_zero_retry, "retrying the same mission should reproduce the same run seed")
	_expect(mission_one != mission_zero, "different missions should use distinct run seeds")
	_expect(RunSeedRules.mission_seed(-5) == mission_zero, "negative mission indices should clamp to mission zero")
	_expect(RunSeedRules.same_mission_reproducible(2, 2), "same-mission reproducibility helper should report true")
	_expect(RunSeedRules.missions_are_distinct(1, 2), "distinct mission helper should report different seeds")

func _test_bombs() -> void:
	_expect(BombRules.boss_bomb_damage(100) >= 6 and BombRules.boss_bomb_damage(100) <= 18, "boss bomb damage should remain bounded")
	_expect(BombRules.apply_nonlethal_boss_damage(100, 100) < 100, "bomb should damage a healthy boss")
	_expect(BombRules.apply_nonlethal_boss_damage(3, 100) == 1, "bomb must never destroy a mission boss")
	var strike_point := BombRules.strike_point(Vector2(320, 260))
	_expect(strike_point == Vector2(320, 188), "secondary bomb should land ahead of the VX-94")
	_expect(BombRules.in_strike_radius(strike_point + Vector2(40, 0), strike_point), "surface contact inside the localized blast should be hit")
	_expect(not BombRules.in_strike_radius(strike_point + Vector2(80, 0), strike_point), "distant contacts should survive a localized blast")
	_expect(BombRules.can_damage_category("ground") and BombRules.can_damage_category("sea") and not BombRules.can_damage_category("air"), "ordinary bombs should damage surface contacts without clearing aircraft")

func _test_mission_state() -> void:
	var campaign = {"starting_hull":92,"starting_shield":84}
	var mission = {"starting_wave":4}
	_expect(MissionStateRules.starting_hull(campaign) == 92, "campaign starting hull should be respected")
	_expect(MissionStateRules.starting_shield(campaign) == 84, "campaign starting shield should be respected")
	_expect(MissionStateRules.starting_wave(mission) == 4, "mission starting wave should be respected")
	_expect(MissionStateRules.live_wave(mission, 0.0) == 4, "mission should begin on authored starting wave")
	_expect(MissionStateRules.live_wave(mission, 40.0) == 6, "mission wave progression should advance relative to starting wave")

func _test_direct_runtime_ownership() -> void:
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for direct runtime ownership checks")
	if main_file != null:
		var text := main_file.get_as_text()
		_expect(text.contains("MissionStateRules.live_wave(_active_mission(), route_progress_seconds())"), "authored wave progression should follow route distance, not punish slower flight")
		_expect(text.contains("MissionStateRules.starting_wave(_active_mission())"), "main should own authored starting wave")
		_expect(text.contains("hull = clampi(service_hull") and text.contains("shield = clampi(service_shield"), "main should initialize sortie condition from scene-owned serviced airframe state")
		_expect(text.contains("BombRules.apply_nonlethal_boss_damage"), "main bomb loop should apply nonlethal boss damage directly")
		_expect(text.contains("survivors.append(boss)"), "main bomb loop should keep bosses in the enemy array")
		_expect(not text.contains("enemies.clear(); enemy_bullets.clear()"), "screen bomb must not blanket-clear bosses")
		_expect(text.contains("var protected_contacts: Array") and text.contains("_seed_protected_contacts()") and text.contains("_update_protected_contacts(delta)"), "live missions should carry protected civilian contacts through route travel")
		_expect(text.contains("ROE VIOLATION // PROTECTED SITE HIT -2500") and text.contains("_apply_bomb_collateral"), "cannon and bomb damage should impose visible collateral consequences")
		_expect(text.contains("var shots_fired := 0") and text.contains("var shots_hit := 0"), "main should own exact sortie accuracy counters")
		_expect(text.contains("shots_fired += count"), "player projectile creation should increment shots fired at source")
		_expect(text.contains("shots_hit += 1"), "player bullet collision should increment shots hit at source")
		_expect(text.contains("RewardRules.extra_success_bonus") and text.contains("credits += total_reward"), "main should apply complete mission reward at source")
		_expect(text.contains("EnergyRules.recharge") and text.contains("EnergyRules.can_fire") and text.contains("EnergyRules.consume"), "main should own generator energy lifecycle")
		_expect(text.contains('mission_catalog = _ordered_missions(mission_catalog, cfg.get("missions", []))'), "runtime should honor authored campaign order instead of raw JSON order")
		_expect(text.contains("return ordered if ordered.size() == source.size() else source"), "campaign ordering should fail safely when the order catalogue is incomplete")
		_expect(text.count("if phase != GamePhase.PLAYING:") >= 2, "lethal damage paths should stop before mutating combat arrays cleared by mission failure")
		_expect(text.contains("if i < enemy_bullets.size():"), "enemy projectile cleanup should remain bounds-safe after damage callbacks")
		_expect(text.contains('"--capture-invulnerable" in OS.get_cmdline_user_args()'), "long visual QA captures should expose an explicit test-only invulnerability flag")
		_expect(text.contains('"SHIELDS DOWN // HULL EXPOSED"') and text.contains('"HULL CRITICAL"'), "authoritative damage resolution should publish distinct shield-collapse and critical-hull warnings")
		_expect(text.contains('front_end_screen := "main_menu"') and text.contains("func _update_front_end_menu()"), "startup should enter a real main menu before the sortie console")
		_expect(text.contains("PLAYER_FLIGHT_MIN := Vector2(34.0, 76.0)") and text.contains("PLAYER_FLIGHT_MAX := Vector2(606.0, 288.0)"), "player flight envelope should keep the full 64x72 VX-94 and afterburner clear of top and bottom instrumentation")
		_expect(text.contains("PLAYER_SORTIE_START := Vector2(320.0, FlightCameraRules.ANCHOR_Y)") and text.contains("player_position = PLAYER_SORTIE_START"), "sorties should begin at the camera projection anchor")
		_expect(text.contains("PLAYER_FLIGHT_MIN.x") and text.contains("FlightCameraRules.advance_offset") and not text.get_slice("func _update_player", 1).get_slice("func _update_weapons", 0).contains("player_position.y = clampf"), "lateral steering should retain bounds while forward flight uses camera projection")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable for removed reconciliation checks")
	if project != null:
		var project_text := project.get_as_text()
		for obsolete in ["MissionStateDirector","BombGuardDirector","AccuracyDirector","RewardDirector","ServiceDirector"]:
			_expect(not project_text.contains(obsolete), "obsolete reconciliation autoload should stay removed: %s" % obsolete)
	for obsolete_file in ["accuracy_director.gd","reward_director.gd","service_director.gd"]:
		_expect(not FileAccess.file_exists("res://scripts/%s" % obsolete_file), "obsolete director file should remain deleted: %s" % obsolete_file)

func _test_weapon_pickups() -> void:
	_expect(WeaponPickupRules.temporary_boost_for_indices(1, 2) == 1, "sortie pickup should register as temporary boost over permanent tier")
	_expect(WeaponPickupRules.saved_index(1, 3) == 1, "campaign save should preserve permanent paid tier")
	_expect(WeaponPickupRules.effective_index(1, 1, 3) == 2, "temporary pickup should allow stronger sortie weapon")
	_expect(WeaponPickupRules.effective_index(2, 2, 3) == 2, "temporary pickup should clamp at maximum weapon tier")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for temporary weapon ownership checks")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("var temporary_weapon_boost := 0"), "main should own explicit sortie-only weapon boost state")
		_expect(source.contains("WeaponPickupRules.effective_index(") and source.contains("weapon_index,") and source.contains("temporary_weapon_boost,"), "active weapon should combine permanent tier and temporary boost explicitly")
		_expect(source.contains("temporary_weapon_boost = mini(") and source.contains("temporary_weapon_boost + 1"), "weapon pickup should increase only temporary boost")
		_expect(source.contains("temporary_weapon_boost = 0"), "sortie cleanup should clear temporary weapon boost")
	var save_file := FileAccess.open("res://scripts/campaign_save.gd", FileAccess.READ)
	_expect(save_file != null, "campaign_save.gd should be readable for permanent weapon persistence checks")
	if save_file != null:
		var save_source := save_file.get_as_text()
		_expect(save_source.contains('"weapon_index"') and save_source.contains('"generator_index"'), "campaign save should persist permanent weapon and generator tiers")
		_expect(not save_source.contains("WeaponPickupDirector"), "campaign save must not depend on weapon pickup reconciliation")
	_expect(not FileAccess.file_exists("res://scripts/weapon_pickup_director.gd"), "obsolete weapon pickup director file should remain deleted")
