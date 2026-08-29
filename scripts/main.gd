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
const WeaponPickupRules = preload("res://scripts/weapon_pickup_rules.gd")
const BombRules = preload("res://scripts/bomb_rules.gd")
const ServiceRules = preload("res://scripts/service_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")
const PLAYER_SPEED := 220.0
const PLAYFIELD := Rect2(18.0, 52.0, 604.0, 296.0)
const BOSS_OVERTIME_LIMIT_SECONDS := 45.0

enum GamePhase { TITLE, PLAYING, RESULT }

var phase := GamePhase.TITLE
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
var weapon_index := 0
var generator_index := 0
var temporary_weapon_boost := 0
var energy := 100.0
var shots_fired := 0
var shots_hit := 0
var boss_spawned := false
var current_boss_id := ""
var current_environment := "coast"
var current_mission_name := "COASTAL INTERCEPT"
var current_briefing := ""
var current_objectives: Array = []
var objective_progress: Dictionary = {}
var result_text := ""
var status_text := ""
var status_timer := 0.0
var bullets: Array = []
var enemy_bullets: Array = []
var enemies: Array = []
var pickups: Array = []
var enemy_catalog: Array = []
var weapon_catalog: Array = []
var generator_catalog: Array = []
var mission_catalog: Array = []
var spawn_profiles: Array = []
var campaign: Dictionary = {}
var mission_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_configure_input()
	_load_content()
	_prepare_mission(mission_index)
	queue_redraw()

func _process(delta: float) -> void:
	status_timer = maxf(0.0, status_timer - delta)
	match phase:
		GamePhase.TITLE:
			if Input.is_action_just_pressed("confirm"):
				_start_mission()
			elif Input.is_action_just_pressed("upgrade"):
				_try_buy_next_weapon()
			elif Input.is_action_just_pressed("upgrade_generator"):
				_try_buy_next_generator()
			elif Input.is_action_just_pressed("service_hull"):
				_service_hull_full()
			elif Input.is_action_just_pressed("service_shield"):
				_service_shield_full()
		GamePhase.PLAYING:
			_update_mission(delta)
			if Input.is_action_just_pressed("cancel"):
				phase = GamePhase.TITLE
				_clear_combat()
		GamePhase.RESULT:
			if Input.is_action_just_pressed("confirm"):
				mission_index = (mission_index + 1) % maxi(1, mission_catalog.size())
				_prepare_mission(mission_index)
				phase = GamePhase.TITLE
			elif Input.is_action_just_pressed("restart"):
				_start_mission()
	queue_redraw()

func _update_mission(delta: float) -> void:
	mission_time += delta
	ObjectiveRules.update_survival(current_objectives, objective_progress, mission_time)
	fire_timer = maxf(0.0, fire_timer - delta)
	secondary_timer = maxf(0.0, secondary_timer - delta)
	enemy_spawn_timer -= delta
	energy = EnergyRules.recharge(energy, _active_generator(), delta)
	wave = MissionStateRules.live_wave(_active_mission(), mission_time)
	_update_player(delta)
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
		var hold_overtime := MissionFlowRules.should_hold_overtime(current_boss_id, current_objectives, objective_progress, enemies)
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
		enemy_spawn_timer = CombatRules.enemy_spawn_interval(wave)

func _load_content() -> void:
	var enemies_data = ContentCatalog.load_json("res://data/enemies.json")
	var weapons_data = ContentCatalog.load_json("res://data/weapons.json")
	var generators_data = ContentCatalog.load_json("res://data/generators.json")
	var missions_data = ContentCatalog.load_json("res://data/missions.json")
	var spawn_data = ContentCatalog.load_json("res://data/spawn_profiles.json")
	var campaign_data = ContentCatalog.load_json("res://data/campaign.json")
	if typeof(enemies_data) == TYPE_DICTIONARY: enemy_catalog = enemies_data.get("enemies", [])
	if typeof(weapons_data) == TYPE_DICTIONARY: weapon_catalog = weapons_data.get("weapons", [])
	if typeof(generators_data) == TYPE_DICTIONARY: generator_catalog = generators_data.get("generators", [])
	if typeof(missions_data) == TYPE_DICTIONARY: mission_catalog = missions_data.get("missions", [])
	if typeof(spawn_data) == TYPE_DICTIONARY: spawn_profiles = spawn_data.get("profiles", [])
	if typeof(campaign_data) == TYPE_DICTIONARY:
		campaign = campaign_data
		var cfg := _campaign_config()
		credits = int(cfg.get("starting_credits", 0))
		service_hull = MissionStateRules.starting_hull(cfg, 100)
		service_shield = MissionStateRules.starting_shield(cfg, 100)

func _prepare_mission(index: int) -> void:
	if mission_catalog.is_empty():
		current_mission_name = "SCRAMBLE"
		current_briefing = "Intercept all incoming hostile aircraft."
		mission_duration = 150.0
		current_boss_id = ""
		current_environment = "coast"
		current_objectives = [{"id":"survive","type":"survive","seconds":150,"required":true}]
	else:
		var mission: Dictionary = mission_catalog[clampi(index, 0, mission_catalog.size() - 1)]
		current_mission_name = str(mission.get("name", "SCRAMBLE")).to_upper()
		current_briefing = str(mission.get("briefing", ""))
		mission_duration = float(mission.get("duration_seconds", 150.0))
		current_boss_id = str(mission.get("boss_id", ""))
		current_environment = str(mission.get("environment", "coast"))
		current_objectives = mission.get("objectives", [])
	objective_progress = ObjectiveRules.make_progress(current_objectives)

func _active_mission() -> Dictionary:
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

func _start_mission() -> void:
	mission_rng.seed = RunSeedRules.mission_seed(mission_index)
	phase = GamePhase.PLAYING
	mission_time = 0.0
	score = 0
	shots_fired = 0
	shots_hit = 0
	hull = clampi(service_hull, 1, _max_hull())
	shield = clampi(service_shield, 0, _max_shield())
	bombs = 3
	wave = MissionStateRules.starting_wave(_active_mission())
	temporary_weapon_boost = 0
	energy = EnergyRules.capacity(_active_generator())
	boss_spawned = false
	enemy_spawn_timer = 0.35
	player_position = Vector2(320.0, 292.0)
	objective_progress = ObjectiveRules.make_progress(current_objectives)
	_clear_combat()

func _finish_mission(success: bool, failure_reason: String = "AIRFRAME LOST") -> void:
	if phase == GamePhase.RESULT:
		return
	phase = GamePhase.RESULT
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
		var extra_total := int(extras.get("total", 0))
		var total_reward := base_reward + objective_bonus + extra_total
		credits += total_reward
		service_hull = clampi(hull, 1, _max_hull())
		service_shield = clampi(shield, 0, _max_shield())
		result_text = "MISSION COMPLETE  +%d" % total_reward
		var parts: Array[String] = []
		if objective_bonus > 0:
			parts.append("BONUS %d" % objective_bonus)
		if int(extras.get("no_damage", 0)) > 0:
			parts.append("NO DAMAGE +%d" % int(extras["no_damage"]))
		if int(extras.get("boss", 0)) > 0:
			parts.append("BOSS +%d" % int(extras["boss"]))
		if int(extras.get("accuracy", 0)) > 0:
			parts.append("ACCURACY %d%% +%d" % [int(round(float(extras.get("accuracy_ratio", 0.0)) * 100.0)), int(extras["accuracy"])])
		elif shots_fired > 0:
			parts.append("ACCURACY %d%%" % int(round(float(extras.get("accuracy_ratio", 0.0)) * 100.0)))
		if not parts.is_empty():
			result_text += "  %s" % "  ".join(parts)
	else:
		result_text = "%s  PRESS R TO RETRY" % failure_reason
	_clear_combat()

func _clear_combat() -> void:
	bullets.clear()
	enemy_bullets.clear()
	enemies.clear()
	pickups.clear()
	temporary_weapon_boost = 0

func _primary_weapons() -> Array:
	var result: Array = []
	for weapon in weapon_catalog:
		if str(weapon.get("slot", "")) == "primary": result.append(weapon)
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
	if primaries.is_empty(): return {"name":"Twin Cannon Mk I","damage":1,"fire_interval":0.11,"projectile_speed":430.0,"projectiles":2,"spread_degrees":0.0,"energy_cost":0.0,"cost":0}
	var max_available := maxi(weapon_index, _highest_available_primary_index(primaries))
	var requested_index := WeaponPickupRules.effective_index(weapon_index, temporary_weapon_boost, primaries.size())
	var effective_index := mini(requested_index, max_available)
	return primaries[effective_index]

func _active_generator() -> Dictionary:
	if generator_catalog.is_empty():
		return {"name":"Field Coil Mk I","capacity":100.0,"recharge_per_second":26.0,"cost":0}
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
		weapon_index = int(result["index"]); credits = int(result["credits"])
		status_text = "UPGRADE PURCHASED: %s" % str(_active_weapon().get("name", "WEAPON")).to_upper()
	else:
		status_text = "NEED %d CREDITS" % int(next_weapon.get("cost", 0))
	status_timer = 2.0

func _try_buy_next_generator() -> void:
	var result := ProgressionRules.next_weapon_index(generator_index, generator_catalog, credits)
	if bool(result["changed"]):
		generator_index = int(result["index"])
		credits = int(result["credits"])
		status_text = "GENERATOR PURCHASED: %s" % str(_active_generator().get("name", "GENERATOR")).to_upper()
	else:
		var next_index := clampi(generator_index + 1, 0, maxi(0, generator_catalog.size() - 1))
		status_text = "MAXIMUM GENERATOR" if generator_catalog.is_empty() or next_index == generator_index else "GENERATOR NEEDS %d CREDITS" % int(generator_catalog[next_index].get("cost", 0))
	status_timer = 2.0

func _service_hull_full() -> void:
	var cfg := _campaign_config()
	var result := ServiceRules.service_full(credits, service_hull, _max_hull(), int(cfg.get("repair_cost_per_hull", 0)))
	if bool(result.get("changed", false)):
		service_hull = int(result["value"])
		credits = int(result["credits"])
		status_text = "HULL SERVICED -%d" % int(result["cost"])
	else:
		status_text = _service_failure("HULL", result)
	status_timer = 3.0

func _service_shield_full() -> void:
	var cfg := _campaign_config()
	var result := ServiceRules.service_full(credits, service_shield, maxi(1, _max_shield()), int(cfg.get("shield_recharge_cost_per_point", 0)))
	if bool(result.get("changed", false)):
		service_shield = mini(_max_shield(), int(result["value"]))
		credits = int(result["credits"])
		status_text = "SHIELD RECHARGED -%d" % int(result["cost"])
	else:
		status_text = _service_failure("SHIELD", result)
	status_timer = 3.0

func _service_failure(label: String, result: Dictionary) -> String:
	var reason := str(result.get("reason", "NO_CHANGE"))
	if reason == "FULL": return "%s ALREADY FULL" % label
	if reason == "INSUFFICIENT_CREDITS": return "%s SERVICE NEEDS %d CREDITS" % [label, int(result.get("cost", 0))]
	return "%s SERVICE UNAVAILABLE" % label

func _service_status() -> String:
	var cfg := _campaign_config()
	var hull_cost := ServiceRules.service_cost(service_hull, _max_hull(), int(cfg.get("repair_cost_per_hull", 0)))
	var shield_cost := ServiceRules.service_cost(service_shield, maxi(1, _max_shield()), int(cfg.get("shield_recharge_cost_per_point", 0)))
	var hull_quote := "FULL" if hull_cost <= 0 else str(hull_cost)
	var shield_quote := "FULL" if shield_cost <= 0 else str(shield_cost)
	return "AIRFRAME H%03d S%03d  H REPAIR %s  J SHIELD %s" % [service_hull, service_shield, hull_quote, shield_quote]

func _update_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_mult := _craft_float("movement_multiplier", 1.0)
	player_position += movement * PLAYER_SPEED * speed_mult * delta
	player_position.x = clampf(player_position.x, PLAYFIELD.position.x + 12.0, PLAYFIELD.end.x - 12.0)
	player_position.y = clampf(player_position.y, PLAYFIELD.position.y + 16.0, PLAYFIELD.end.y - 12.0)

func _update_weapons() -> void:
	var weapon := _active_weapon()
	if Input.is_action_pressed("fire_primary") and fire_timer <= 0.0 and EnergyRules.can_fire(energy, weapon):
		fire_timer = float(weapon.get("fire_interval", 0.11))
		energy = EnergyRules.consume(energy, weapon)
		var count := maxi(1, int(weapon.get("projectiles", 1)))
		shots_fired += count
		var spread := float(weapon.get("spread_degrees", 0.0)) * _craft_float("primary_spread_multiplier", 1.0)
		var damage := maxi(1, int(round(float(weapon.get("damage", 1)) * _craft_float("primary_damage_multiplier", 1.0))))
		for i in range(count):
			var angle := 0.0 if count == 1 else deg_to_rad(lerpf(-spread, spread, float(i) / float(count - 1)))
			var bullet := {
				"position": player_position + Vector2(0,-16),
				"velocity": Vector2.UP.rotated(angle) * float(weapon.get("projectile_speed",430.0)),
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
				score += 75 + int(enemy.get("hp", 1)) * 25
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
		bullet["position"] = position; bullets[i] = bullet
		if not PLAYFIELD.grow(24).has_point(position): bullets.remove_at(i)

func _update_enemy_bullets(delta: float) -> void:
	for i in range(enemy_bullets.size() - 1, -1, -1):
		var shot: Dictionary = enemy_bullets[i]
		var position: Vector2 = shot["position"]
		position += shot["velocity"] * delta
		shot["position"] = position; enemy_bullets[i] = shot
		var projectile_hit_radius_sq := _craft_float("projectile_hit_radius_sq", 120.0)
		if position.distance_squared_to(player_position) <= projectile_hit_radius_sq:
			_apply_damage(int(shot.get("damage",8))); enemy_bullets.remove_at(i)
		elif not PLAYFIELD.grow(32).has_point(position): enemy_bullets.remove_at(i)

func _update_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var pickup: Dictionary = pickups[i]
		var position: Vector2 = pickup["position"]
		position.y += 55.0 * delta; pickup["position"] = position; pickups[i] = pickup
		if position.distance_squared_to(player_position) <= 260.0:
			_apply_pickup(str(pickup["kind"])); pickups.remove_at(i)
		elif position.y > PLAYFIELD.end.y + 20: pickups.remove_at(i)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy["age"] = float(enemy["age"]) + delta
		enemy["fire_timer"] = float(enemy["fire_timer"]) - delta
		var position: Vector2 = enemy["position"]
		var is_boss := bool(enemy.get("boss", false))
		if is_boss:
			if position.y < 105.0:
				position.y += float(enemy["speed"]) * delta
			position.x += sin(float(enemy["age"]) * float(enemy["turn_rate"]) + float(enemy["phase"])) * float(enemy["drift"]) * delta
			position.x = clampf(position.x, PLAYFIELD.position.x + 18.0, PLAYFIELD.end.x - 18.0)
		else:
			position.y += float(enemy["speed"]) * delta
			var pattern := str(enemy.get("pattern", "sine_dive"))
			var anchor_x := float(enemy.get("pattern_anchor_x", position.x))
			enemy["pattern_anchor_x"] = anchor_x
			if pattern in MovementPatternRules.supported_patterns():
				position = MovementPatternRules.adjusted_position(pattern, position, player_position, float(enemy["age"]), delta, anchor_x)
			else:
				position.x += sin(float(enemy["age"]) * float(enemy["turn_rate"]) + float(enemy["phase"])) * float(enemy["drift"]) * delta
			position = MovementPatternRules.clamp_x(position, PLAYFIELD.position.x + 18.0, PLAYFIELD.end.x - 18.0)
		enemy["position"] = position
		if float(enemy["fire_timer"]) <= 0.0 and position.y > PLAYFIELD.position.y:
			_fire_enemy_weapon(enemy)
			enemy["fire_timer"] = ProjectileRules.enemy_fire_interval(str(enemy.get("weapon","single_burst")), wave)
		enemies[i] = enemy
		if not is_boss and position.y > PLAYFIELD.end.y + 22:
			enemies.remove_at(i)

func _make_enemy_shot(origin: Vector2, velocity: Vector2, damage: int, homing := false) -> Dictionary:
	var shot := {"position":origin,"velocity":velocity,"damage":damage}
	if homing:
		shot["homing"] = true
		shot["homing_speed"] = maxf(1.0, velocity.length())
		shot["turn_rate"] = 1.8
		shot["life"] = 5.0
	return shot

func _fire_enemy_weapon(enemy: Dictionary) -> void:
	var origin: Vector2 = enemy["position"]
	var weapon_id := str(enemy.get("weapon","single_burst"))
	var damage := 14 if bool(enemy.get("boss",false)) else 8
	var velocity := ProjectileRules.enemy_shot_velocity(origin, player_position, ProjectileRules.enemy_projectile_speed(weapon_id))
	var is_missile := weapon_id == "missile"
	enemy_bullets.append(_make_enemy_shot(origin, velocity, damage, is_missile))
	if weapon_id == "twin_burst":
		enemy_bullets.append(_make_enemy_shot(origin, velocity.rotated(0.16), damage))
		enemy_bullets.append(_make_enemy_shot(origin, velocity.rotated(-0.16), damage))
	elif is_missile:
		enemy_bullets.append(_make_enemy_shot(origin, velocity.rotated(0.08), damage + 3, true))

func _resolve_combat() -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var consume_bullet := false
		var bullet: Dictionary = bullets[bullet_index]
		for enemy_index in range(enemies.size() - 1, -1, -1):
			var radius_sq := 420.0 if bool(enemies[enemy_index].get("boss",false)) else 196.0
			if bullet["position"].distance_squared_to(enemies[enemy_index]["position"]) <= radius_sq:
				var enemy_class := str(enemies[enemy_index].get("category", "air"))
				var applied_damage := maxi(1, int(round(float(bullet["damage"]) * _target_damage_multiplier(enemy_class))))
				enemies[enemy_index]["hp"] -= applied_damage
				if not bool(bullet.get("accuracy_registered", false)):
					shots_hit += 1
					bullet["accuracy_registered"] = true
				if int(enemies[enemy_index]["hp"]) <= 0:
					var destroyed: Dictionary = enemies[enemy_index]
					_register_destroy(destroyed)
					score += int(destroyed["value"])
					_maybe_drop_pickup(destroyed["position"], bool(destroyed.get("boss",false)))
					enemies.remove_at(enemy_index)
			var pierce_remaining := int(bullet.get("pierce_remaining", 0))
			if pierce_remaining > 0:
				bullet["pierce_remaining"] = pierce_remaining - 1
				var velocity: Vector2 = bullet.get("velocity", Vector2.UP * 430.0)
				if velocity.length_squared() > 0.001:
					bullet["position"] = Vector2(bullet["position"]) + velocity.normalized() * 28.0
				bullets[bullet_index] = bullet
				continue
			consume_bullet = true
			break
		if consume_bullet:
			bullets.remove_at(bullet_index)
		else:
			bullets[bullet_index] = bullet
	var player_contact_radius_sq := _craft_float("collision_radius_sq", 420.0)
	for enemy_index in range(enemies.size() - 1, -1, -1):
		if enemies[enemy_index]["position"].distance_squared_to(player_position) <= player_contact_radius_sq:
			_apply_damage(24 if bool(enemies[enemy_index].get("boss",false)) else 18)
			if not bool(enemies[enemy_index].get("boss",false)): enemies.remove_at(enemy_index)

func _register_destroy(enemy: Dictionary) -> void:
	ObjectiveRules.register_destroy(current_objectives, objective_progress, str(enemy.get("id","")))

func _maybe_drop_pickup(position: Vector2, guaranteed := false) -> void:
	var kind := "weapon" if guaranteed else ProjectileRules.pickup_kind_for_roll(mission_rng.randf())
	if kind != "": pickups.append({"position":position,"kind":kind})

func _apply_pickup(kind: String) -> void:
	match kind:
		"shield": shield = mini(_max_shield(), shield + 35)
		"repair": hull = mini(_max_hull(), hull + 25)
		"bomb": bombs = mini(5, bombs + 1)
		"weapon":
			var primaries := _primary_weapons()
			if not primaries.is_empty():
				var max_allowed := maxi(weapon_index, _highest_available_primary_index(primaries))
				var max_boost := maxi(0, max_allowed - weapon_index)
				temporary_weapon_boost = mini(max_boost, temporary_weapon_boost + 1)

func _apply_damage(amount: int) -> void:
	var state := CombatRules.apply_shielded_damage(hull, shield, amount)
	hull = int(state["hull"]); shield = int(state["shield"])
	if hull <= 0: _finish_mission(false)

func _find_enemy_archetype(id: String) -> Dictionary:
	for enemy in enemy_catalog:
		if str(enemy.get("id","")) == id: return enemy
	return {}

func _spawn_candidates() -> Array:
	var allowed_ids: Array = []
	for profile in spawn_profiles:
		if str(profile.get("environment","")) == current_environment and wave >= int(profile.get("min_wave",1)) and wave <= int(profile.get("max_wave",99)):
			allowed_ids = profile.get("enemy_ids", [])
			break
	if allowed_ids.is_empty():
		return []
	var candidates: Array = []
	for item in enemy_catalog:
		if bool(item.get("boss",false)):
			continue
		if str(item.get("id","")) in allowed_ids:
			candidates.append(item)
	return candidates

func _spawn_enemy(archetype: Dictionary = {}) -> void:
	if archetype.is_empty():
		var candidates := _spawn_candidates()
		if candidates.is_empty(): return
		archetype = candidates[mission_rng.randi_range(0, candidates.size() - 1)]
	var is_boss := bool(archetype.get("boss",false))
	var enemy_class := str(archetype.get("class","air"))
	var hp := maxi(1, int(archetype.get("hp",1)) + (0 if is_boss else int(wave / 5)))
	var x := PLAYFIELD.get_center().x if is_boss else mission_rng.randf_range(PLAYFIELD.position.x + 24, PLAYFIELD.end.x - 24)
	var speed_bias := 0.0 if enemy_class == "ground" else (10.0 if enemy_class == "air" else -8.0)
	var drift := 28.0 if is_boss else (10.0 if enemy_class == "ground" else mission_rng.randf_range(16,38))
	enemies.append({
		"id":str(archetype.get("id","bogey")),
		"category":enemy_class,
		"position":Vector2(x,PLAYFIELD.position.y-18),
		"speed":float(archetype.get("speed",72))+speed_bias+(0.0 if is_boss else float(wave)*4.0),
		"drift":drift,
		"turn_rate":0.75 if is_boss else mission_rng.randf_range(1.1,2.4),
		"phase":mission_rng.randf_range(0,TAU),
		"age":0.0,
		"hp":hp,
		"value":CombatRules.destroy_value(int(archetype.get("value",100)),wave),
		"weapon":str(archetype.get("weapon","single_burst")),
		"pattern":str(archetype.get("pattern","sine_dive")),
		"pattern_anchor_x":x,
		"fire_timer":mission_rng.randf_range(0.5,1.6),
		"boss":is_boss
	})

func _try_spawn_boss() -> void:
	if boss_spawned or current_boss_id == "" or mission_time < mission_duration * 0.72: return
	var boss := _find_enemy_archetype(current_boss_id)
	if not boss.is_empty(): boss_spawned = true; _spawn_enemy(boss)

func _boss_alive() -> bool:
	for enemy in enemies:
		if bool(enemy.get("boss",false)): return true
	return false

func _configure_input() -> void:
	_add_key_action("move_left",KEY_A); _add_key_action("move_left",KEY_LEFT); _add_key_action("move_right",KEY_D); _add_key_action("move_right",KEY_RIGHT)
	_add_key_action("move_up",KEY_W); _add_key_action("move_up",KEY_UP); _add_key_action("move_down",KEY_S); _add_key_action("move_down",KEY_DOWN)
	_add_key_action("fire_primary",KEY_SPACE); _add_key_action("fire_secondary",KEY_X); _add_key_action("confirm",KEY_ENTER); _add_key_action("cancel",KEY_ESCAPE); _add_key_action("restart",KEY_R); _add_key_action("upgrade",KEY_U)
	_add_key_action("upgrade_generator",KEY_G); _add_key_action("service_hull",KEY_H); _add_key_action("service_shield",KEY_J)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	var event:=InputEventKey.new(); event.physical_keycode=keycode
	if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)

func _objective_summary() -> String:
	var parts: Array[String] = []
	for objective in current_objectives:
		var prefix := "REQ" if bool(objective.get("required",true)) else "BONUS"
		parts.append("%s %s %s" % [prefix, str(objective.get("label",objective.get("id","OBJ"))).to_upper(), ObjectiveRules.progress_text(objective, objective_progress)])
	return "   ".join(parts)

func _draw() -> void:
	draw_rect(Rect2(0,0,640,360),Color("10151b"))
	if phase == GamePhase.TITLE: _draw_title(); return
	if phase == GamePhase.RESULT: _draw_result(); return
	_draw_gameplay()

func _draw_title() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(0,62),"STRIKE WING '94",HORIZONTAL_ALIGNMENT_CENTER,640,30,Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font,Vector2(0,103),current_mission_name,HORIZONTAL_ALIGNMENT_CENTER,640,18,Color("f0d87a"))
	draw_string(ThemeDB.fallback_font,Vector2(80,133),current_briefing,HORIZONTAL_ALIGNMENT_CENTER,480,13,Color("8997a1"))
	draw_string(ThemeDB.fallback_font,Vector2(24,170),_objective_summary(),HORIZONTAL_ALIGNMENT_CENTER,592,10,Color("a8b5bd"))
	draw_string(ThemeDB.fallback_font,Vector2(0,207),"ENTER LAUNCH   U WEAPON   G GENERATOR   H/J SERVICE",HORIZONTAL_ALIGNMENT_CENTER,640,11,Color("d8dde2"))
	var weapon := _active_weapon()
	var generator := _active_generator()
	draw_string(ThemeDB.fallback_font,Vector2(0,236),"%s   %s   CREDITS %06d" % [str(weapon.get("name","CANNON")).to_upper(),str(generator.get("name","GENERATOR")).to_upper(),credits],HORIZONTAL_ALIGNMENT_CENTER,640,10,Color("8997a1"))
	draw_string(ThemeDB.fallback_font,Vector2(0,260),_service_status(),HORIZONTAL_ALIGNMENT_CENTER,640,10,Color("8997a1"))
	if status_timer > 0: draw_string(ThemeDB.fallback_font,Vector2(0,306),status_text,HORIZONTAL_ALIGNMENT_CENTER,640,12,Color("72c7b2"))

func _draw_result() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(0,105),result_text,HORIZONTAL_ALIGNMENT_CENTER,640,21,Color("f0d87a"))
	draw_string(ThemeDB.fallback_font,Vector2(0,146),"SCORE %08d   CREDITS %06d" % [score,credits],HORIZONTAL_ALIGNMENT_CENTER,640,14,Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font,Vector2(24,182),_objective_summary(),HORIZONTAL_ALIGNMENT_CENTER,592,10,Color("a8b5bd"))
	draw_string(ThemeDB.fallback_font,Vector2(0,236),"ENTER CONTINUE    R RETRY",HORIZONTAL_ALIGNMENT_CENTER,640,13,Color("8997a1"))

func _draw_gameplay() -> void:
	draw_rect(PLAYFIELD,Color("121c23"))
	for i in range(18):
		var y := fposmod(float(i*28)+mission_time*48.0,420.0)-30.0
		draw_line(Vector2(PLAYFIELD.position.x,y),Vector2(PLAYFIELD.end.x,y),Color("1c2a34"),1)
	for bullet in bullets:
		var b: Vector2 = bullet["position"]; draw_rect(Rect2(b.x-1,b.y-6,3,9),Color("f0d87a"))
	for shot in enemy_bullets:
		var s: Vector2 = shot["position"]; draw_circle(s,3,Color("e8644f"))
	for pickup in pickups:
		var q: Vector2 = pickup["position"]; draw_rect(Rect2(q.x-5,q.y-5,10,10),Color("72c7b2"),false,2)
	for enemy in enemies:
		var e: Vector2 = enemy["position"]; var is_boss := bool(enemy.get("boss",false)); var size := 1.65 if is_boss else 1.0
		var tone := Color("d05b4f") if is_boss else (Color("a84c43") if enemy.get("category","air") == "air" else Color("80745d"))
		draw_colored_polygon(PackedVector2Array([e+Vector2(0,11)*size,e+Vector2(-13,-8)*size,e+Vector2(0,-4)*size,e+Vector2(13,-8)*size]),tone)
	var p := player_position
	if _craft_form_name() == "BOMBER":
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-16),p+Vector2(-26,7),p+Vector2(-16,13),p+Vector2(0,7),p+Vector2(16,13),p+Vector2(26,7)]),Color("d8dde2"))
		draw_rect(Rect2(p.x-3,p.y-10,6,18),Color("8997a1"))
	else:
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-19),p+Vector2(-11,12),p+Vector2(0,7),p+Vector2(11,12)]),Color("d8dde2"))
		draw_line(p+Vector2(-7,5),p+Vector2(-16,12),Color("8997a1"),2)
		draw_line(p+Vector2(7,5),p+Vector2(16,12),Color("8997a1"),2)
	draw_rect(Rect2(8,8,624,52),Color("080b0f"))
	var remaining := maxi(0,int(ceil(mission_duration-mission_time)))
	var energy_pct := int(round(EnergyRules.normalized(energy, _active_generator()) * 100.0))
	draw_string(ThemeDB.fallback_font,Vector2(16,26),"H%03d S%03d E%03d B%01d W%02d T%03d %08d" % [hull,shield,energy_pct,bombs,wave,remaining,score],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font,Vector2(16,43),"%s  %s  %s" % [current_mission_name,str(_active_weapon().get("name","CANNON")).to_upper(),str(_active_generator().get("name","GENERATOR")).to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("8997a1"))
	draw_string(ThemeDB.fallback_font,Vector2(16,57),_objective_summary(),HORIZONTAL_ALIGNMENT_LEFT,608,9,Color("a8b5bd"))
