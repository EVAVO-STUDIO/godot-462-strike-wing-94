extends Node
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const BossRules = preload("res://scripts/boss_rules.gd")
const BossSignatureRules = preload("res://scripts/boss_signature_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
const HOMING_LIFETIME := 6.0

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	_update_bosses(scene, delta)
	_update_homing_shots(scene, delta)

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["enemies", "enemy_bullets", "player_position"])

func _catalog_max_hp(scene: Object, boss_id: String, fallback_hp: int) -> int:
	if not _has_property(scene, "enemy_catalog"):
		return maxi(1, fallback_hp)
	var catalog = scene.get("enemy_catalog")
	if typeof(catalog) != TYPE_ARRAY:
		return maxi(1, fallback_hp)
	for archetype in catalog:
		if str(archetype.get("id", "")) == boss_id:
			return maxi(1, int(archetype.get("hp", fallback_hp)))
	return maxi(1, fallback_hp)

func _update_bosses(scene: Object, delta: float) -> void:
	var enemies: Array = scene.get("enemies")
	var bullets: Array = scene.get("enemy_bullets")
	var target: Vector2 = scene.get("player_position")
	for i in range(enemies.size()):
		var boss: Dictionary = enemies[i]
		if not bool(boss.get("boss", false)):
			continue
		var hp := int(boss.get("hp", 1))
		var max_hp := int(boss.get("max_hp", 0))
		var boss_id := str(boss.get("id", ""))
		if max_hp <= 0:
			max_hp = _catalog_max_hp(scene, boss_id, hp)
			boss["max_hp"] = max_hp
			boss["base_speed"] = float(boss.get("speed", 24.0))
			boss["base_drift"] = float(boss.get("drift", 28.0))
			boss["phase_salvo_timer"] = minf(1.8, BossRules.phase_salvo_interval(boss_id, 1))
			boss["signature_timer"] = BossSignatureRules.interval(boss_id, 1)
			boss["signature_warning_timer"] = -1.0
			boss["last_hp"] = hp
			boss["last_reported_phase"] = BossRules.phase_for(hp, max_hp)
		if not bool(boss.get("entry_ready", true)):
			enemies[i] = boss
			continue

		var previous_hp := int(boss.get("last_hp", hp))
		var phase := BossRules.phase_for(hp, max_hp)
		if hp < previous_hp and phase >= 3:
			var raw_damage := previous_hp - hp
			var bonus_damage := int(round(float(raw_damage) * (BossRules.weak_point_multiplier(phase) - 1.0)))
			if bonus_damage > 0:
				hp = maxi(0, hp - bonus_damage)
				boss["hp"] = hp
		boss["last_hp"] = hp
		boss["boss_phase"] = phase
		boss["speed"] = float(boss.get("base_speed", 24.0)) * BossRules.phase_speed_multiplier(phase)
		boss["drift"] = float(boss.get("base_drift", 28.0)) * BossRules.phase_drift_multiplier(phase)
		boss["fire_timer"] = minf(float(boss.get("fire_timer", 1.0)), 1.4 * BossRules.phase_fire_multiplier(phase))
		boss["phase_salvo_timer"] = float(boss.get("phase_salvo_timer", 1.4)) - delta
		boss["signature_timer"] = float(boss.get("signature_timer", BossSignatureRules.interval(boss_id, phase))) - delta
		var warning_timer := float(boss.get("signature_warning_timer", -1.0))
		if warning_timer >= 0.0:
			boss["signature_warning_timer"] = warning_timer - delta

		var reported_phase := int(boss.get("last_reported_phase", phase))
		if phase > reported_phase:
			boss["last_reported_phase"] = phase
			_report_phase(scene, boss, phase)

		if BossRules.phase_salvo_enabled(boss_id, phase) and float(boss["phase_salvo_timer"]) <= 0.0:
			var bullets_before := bullets.size()
			_emit_phase_salvo(bullets, boss, target, phase)
			_register_new_missiles(scene, bullets, bullets_before)
			boss["phase_salvo_timer"] = BossRules.phase_salvo_interval(boss_id, phase)

		if BossSignatureRules.is_signature_boss(boss_id):
			if warning_timer >= 0.0 and float(boss["signature_warning_timer"]) <= 0.0:
				var bullets_before := bullets.size()
				_emit_signature_attack(bullets, boss, target, phase)
				_register_new_missiles(scene, bullets, bullets_before)
				boss["signature_warning_timer"] = -1.0
				boss["signature_timer"] = _difficulty_boss_interval(BossSignatureRules.interval(boss_id, phase))
			elif warning_timer < 0.0 and float(boss["signature_timer"]) <= 0.0:
				boss["signature_warning_timer"] = _difficulty_telegraph_seconds()
				_report_signature(scene, boss_id)
		enemies[i] = boss

	scene.set("enemies", enemies)
	scene.set("enemy_bullets", bullets)

func _register_new_missiles(scene: Object, bullets: Array, start_index: int) -> void:
	if not scene.has_method("_register_enemy_missile_launch"):
		return
	var count := 0
	for i in range(maxi(0, start_index), bullets.size()):
		if typeof(bullets[i]) == TYPE_DICTIONARY and bool(bullets[i].get("homing", false)):
			count += 1
	if count > 0:
		scene.call("_register_enemy_missile_launch", count)

func _report_phase(scene: Object, boss: Dictionary, phase: int) -> void:
	var name := str(boss.get("id", "BOSS")).replace("_", " ").to_upper()
	if _has_property(scene, "status_text"):
		scene.set("status_text", "%s PHASE %d" % [name, phase])
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 1.8)

func _report_signature(scene: Object, boss_id: String) -> void:
	if _has_property(scene, "status_text"):
		scene.set("status_text", BossSignatureRules.telegraph(boss_id))
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 1.2)

func _emit_phase_salvo(bullets: Array, boss: Dictionary, target: Vector2, phase: int) -> void:
	var origin: Vector2 = boss.get("position", Vector2.ZERO)
	var boss_id := str(boss.get("id", ""))
	var weapon_id := str(boss.get("weapon", "aimed_burst"))
	var count := BossRules.volley_count(weapon_id, phase)
	var origins := BossRules.volley_origins(boss_id, origin, count)
	var spread := BossRules.volley_spread_radians(weapon_id, phase)
	var speed := _difficulty_projectile_speed(ProjectileRules.enemy_projectile_speed(weapon_id))
	for i in range(count):
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var offset := lerpf(-spread, spread, t)
		var shot_origin: Vector2 = origins[i]
		var velocity := ProjectileRules.enemy_shot_velocity(shot_origin, target, speed).rotated(offset)
		bullets.append({
			"position": shot_origin,
			"velocity": velocity,
			"damage": 12 + phase * 2,
			"homing": weapon_id == "missile" or phase >= 3,
			"homing_speed": speed,
			"turn_rate": 1.6 + float(phase) * 0.45,
			"life": HOMING_LIFETIME
		})

func _emit_signature_attack(bullets: Array, boss: Dictionary, target: Vector2, phase: int) -> void:
	var boss_id := str(boss.get("id", ""))
	var origin: Vector2 = boss.get("position", Vector2.ZERO)
	var count := BossSignatureRules.shot_count(boss_id, phase)
	var spread := BossSignatureRules.spread_radians(boss_id, phase)
	var speed := _difficulty_projectile_speed(BossSignatureRules.projectile_speed(boss_id, phase))
	var damage := BossSignatureRules.damage(boss_id, phase)
	if count <= 0:
		return
	for i in range(count):
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var offset := lerpf(-spread, spread, t)
		var velocity := ProjectileRules.enemy_shot_velocity(origin, target, speed).rotated(offset)
		var shot := {
			"position": origin,
			"velocity": velocity,
			"damage": damage,
			"signature_boss": boss_id,
			"life": HOMING_LIFETIME
		}
		if boss_id in [BossSignatureRules.SWARM, BossSignatureRules.PHASE_ARRAY]:
			shot["homing"] = phase >= 2
			shot["homing_speed"] = speed
			shot["turn_rate"] = (1.35 if boss_id == BossSignatureRules.SWARM else 1.65) + float(phase) * 0.32
		elif boss_id in [BossSignatureRules.FORGE, BossSignatureRules.WARDEN]:
			shot["homing"] = true
			shot["homing_speed"] = speed
			shot["turn_rate"] = (1.0 if boss_id == BossSignatureRules.FORGE else 0.82) + float(phase) * 0.24
		elif boss_id in [BossSignatureRules.ORBITAL, BossSignatureRules.ARK]:
			shot["kinetic"] = true
		bullets.append(shot)

func _update_homing_shots(scene: Object, delta: float) -> void:
	var bullets: Array = scene.get("enemy_bullets")
	var target: Vector2 = scene.get("player_position")
	for i in range(bullets.size() - 1, -1, -1):
		var shot: Dictionary = bullets[i]
		if not bool(shot.get("homing", false)):
			continue
		var life := float(shot.get("life", HOMING_LIFETIME)) - delta
		if life <= 0.0:
			bullets.remove_at(i)
			continue
		shot["life"] = life
		var position: Vector2 = shot.get("position", Vector2.ZERO)
		var velocity: Vector2 = shot.get("velocity", Vector2.DOWN * 150.0)
		var desired := position.direction_to(target)
		if desired.length_squared() >= 0.001:
			var current_angle := velocity.angle()
			var target_angle := desired.angle()
			var next_angle := rotate_toward(current_angle, target_angle, float(shot.get("turn_rate", 2.0)) * delta)
			shot["velocity"] = Vector2.RIGHT.rotated(next_angle) * float(shot.get("homing_speed", velocity.length()))
		bullets[i] = shot
	scene.set("enemy_bullets", bullets)

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)

func _difficulty_projectile_speed(base: float) -> float:
	var director := get_node_or_null("/root/DifficultyDirector")
	return float(director.call("projectile_speed", base)) if director != null else base

func _difficulty_boss_interval(base: float) -> float:
	var director := get_node_or_null("/root/DifficultyDirector")
	return float(director.call("boss_interval", base)) if director != null else base

func _difficulty_telegraph_seconds() -> float:
	var director := get_node_or_null("/root/DifficultyDirector")
	return float(director.call("telegraph_seconds")) if director != null else 0.9
