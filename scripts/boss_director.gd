extends Node

const BossRules = preload("res://scripts/boss_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
const HOMING_LIFETIME := 6.0

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	_update_bosses(scene, delta)
	_update_homing_shots(scene, delta)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["enemies", "enemy_bullets", "player_position"]:
		if not names.has(required):
			return false
	return true

func _update_bosses(scene: Object, delta: float) -> void:
	var enemies: Array = scene.get("enemies")
	var bullets: Array = scene.get("enemy_bullets")
	var target: Vector2 = scene.get("player_position")
	for i in range(enemies.size()):
		var boss: Dictionary = enemies[i]
		if not bool(boss.get("boss", false)):
			continue
		var hp := int(boss.get("hp", 1))
		var max_hp := int(boss.get("max_hp", hp))
		if not boss.has("max_hp"):
			max_hp = maxi(1, hp)
			boss["max_hp"] = max_hp
			boss["base_speed"] = float(boss.get("speed", 24.0))
			boss["base_drift"] = float(boss.get("drift", 28.0))
			boss["phase_salvo_timer"] = 1.4
			boss["last_hp"] = hp
			boss["last_reported_phase"] = 1

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

		var reported_phase := int(boss.get("last_reported_phase", 1))
		if phase > reported_phase:
			boss["last_reported_phase"] = phase
			_report_phase(scene, boss, phase)

		if phase >= 2 and float(boss["phase_salvo_timer"]) <= 0.0:
			_emit_phase_salvo(bullets, boss, target, phase)
			boss["phase_salvo_timer"] = 2.4 if phase == 2 else 1.55
		enemies[i] = boss

	scene.set("enemies", enemies)
	scene.set("enemy_bullets", bullets)

func _report_phase(scene: Object, boss: Dictionary, phase: int) -> void:
	var name := str(boss.get("id", "BOSS")).replace("_", " ").to_upper()
	if _has_property(scene, "status_text"):
		scene.set("status_text", "%s PHASE %d" % [name, phase])
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 1.8)

func _emit_phase_salvo(bullets: Array, boss: Dictionary, target: Vector2, phase: int) -> void:
	var origin: Vector2 = boss.get("position", Vector2.ZERO)
	var weapon_id := str(boss.get("weapon", "aimed_burst"))
	var count := BossRules.volley_count(weapon_id, phase)
	var spread := BossRules.volley_spread_radians(weapon_id, phase)
	var speed := ProjectileRules.enemy_projectile_speed(weapon_id)
	for i in range(count):
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var offset := lerpf(-spread, spread, t)
		var velocity := ProjectileRules.enemy_shot_velocity(origin, target, speed).rotated(offset)
		bullets.append({
			"position": origin,
			"velocity": velocity,
			"damage": 12 + phase * 2,
			"homing": weapon_id == "missile" or phase >= 3,
			"homing_speed": speed,
			"turn_rate": 1.6 + float(phase) * 0.45,
			"life": HOMING_LIFETIME
		})

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
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
