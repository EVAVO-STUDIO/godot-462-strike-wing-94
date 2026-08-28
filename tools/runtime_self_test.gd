extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const RunSeedRules = preload("res://scripts/run_seed_rules.gd")
const BombRules = preload("res://scripts/bomb_rules.gd")

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
	var enemies = ContentCatalog.load_json("res://data/enemies.json")
	var missions = ContentCatalog.load_json("res://data/missions.json")
	var profiles = ContentCatalog.load_json("res://data/spawn_profiles.json")
	var campaign = ContentCatalog.load_json("res://data/campaign.json")
	_expect(typeof(weapons) == TYPE_DICTIONARY and not weapons.get("weapons", []).is_empty(), "weapons catalogue should load through ContentCatalog")
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
