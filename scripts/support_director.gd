extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const SupportRules = preload("res://scripts/support_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

var support_catalog: Array = []
var selected_index := 0
var unlocked_index := 0
var _cooldown := 0.0
var _magnetic_timer := 0.0
var _magnetic_support: Dictionary = {}
var _last_phase := -1

func _ready() -> void:
	process_priority = -5
	_load_catalog()
	_ensure_actions()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var phase := int(scene.get("phase"))
	if phase == 1 and _last_phase != 1:
		_reset_sortie_state()
	if phase == 0:
		_handle_title(scene)
	elif phase == 1:
		_update_emp_disruption(scene, delta)
		_update_magnetic_field(scene, delta)
		_update_hunter_projectiles(scene, delta)
		if Input.is_action_just_pressed("fire_support"):
			_activate(scene)
	else:
		_magnetic_timer = 0.0
	_last_phase = phase

func _reset_sortie_state() -> void:
	_cooldown = 0.0
	_magnetic_timer = 0.0
	_magnetic_support.clear()

func _load_catalog() -> void:
	var data = ContentCatalog.load_json("res://data/support_systems.json")
	if typeof(data) == TYPE_DICTIONARY:
		support_catalog = data.get("supports", [])
	unlocked_index = SupportRules.sanitize_unlock(unlocked_index, support_catalog.size())
	selected_index = SupportRules.sanitize_selected(selected_index, unlocked_index, support_catalog.size())

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "credits", "energy", "bullets", "enemy_bullets", "enemies", "player_position", "shots_fired", "status_text", "status_timer"]:
		if not names.has(required):
			return false
	return true

func current_support() -> Dictionary:
	if support_catalog.is_empty():
		return {}
	var index := SupportRules.sanitize_selected(selected_index, unlocked_index, support_catalog.size())
	var item = support_catalog[index]
	return item if typeof(item) == TYPE_DICTIONARY else {}

func current_support_name() -> String:
	return str(current_support().get("name", "NO SUPPORT"))

func support_state() -> Dictionary:
	return {"selected_index": SupportRules.sanitize_selected(selected_index, unlocked_index, support_catalog.size()),"unlocked_index": SupportRules.sanitize_unlock(unlocked_index, support_catalog.size())}

func restore_support_state(saved_selected: int, saved_unlocked: int) -> void:
	unlocked_index = SupportRules.sanitize_unlock(saved_unlocked, support_catalog.size())
	selected_index = SupportRules.sanitize_selected(saved_selected, unlocked_index, support_catalog.size())

func rearm_support() -> void:
	_cooldown = 0.0
	_magnetic_timer = 0.0
	var strike := get_node_or_null("/root/StrikeOrdnanceDirector")
	if strike != null and strike.has_method("rearm_full"):
		strike.call("rearm_full")
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("refuel_afterburner_full"):
		craft.call("refuel_afterburner_full")

func magnetic_active() -> bool:
	return _magnetic_timer > 0.0

func _handle_title(scene: Object) -> void:
	if Input.is_action_just_pressed("cycle_support"):
		selected_index = SupportRules.cycle_selected(selected_index, unlocked_index, support_catalog.size())
		_set_status(scene, "SUPPORT %s" % current_support_name().to_upper())
	elif Input.is_action_just_pressed("upgrade_support"):
		_buy_next_support(scene)

func _buy_next_support(scene: Object) -> void:
	if support_catalog.is_empty(): return
	var next_index := clampi(unlocked_index + 1, 0, maxi(0, support_catalog.size() - 1))
	if next_index == unlocked_index:
		_set_status(scene, "ALL SUPPORT SYSTEMS UNLOCKED")
		return
	var next_support: Dictionary = support_catalog[next_index]
	var required_era := str(next_support.get("unlock_tech_era", "advanced_conventional"))
	var current_era := _current_tech_era()
	if not TechProgressionRules.can_unlock(required_era, current_era):
		_set_status(scene, "TECH LOCK - %s" % TechProgressionRules.era_name(required_era))
		return
	var result := ProgressionRules.next_weapon_index(unlocked_index, support_catalog, int(scene.get("credits")))
	if bool(result.get("changed", false)):
		unlocked_index = int(result.get("index", unlocked_index))
		selected_index = unlocked_index
		scene.set("credits", int(result.get("credits", scene.get("credits"))))
		_set_status(scene, "SUPPORT UNLOCKED %s" % current_support_name().to_upper())
	else:
		_set_status(scene, "SUPPORT NEEDS %d CREDITS" % int(next_support.get("cost", 0)))

func _current_tech_era() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("mission_context"):
		var context = director.call("mission_context")
		if typeof(context) == TYPE_DICTIONARY:
			return str(context.get("tech_era", "advanced_conventional"))
	return "advanced_conventional"

func _craft_energy_multiplier() -> float:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("support_energy_multiplier"):
		return clampf(float(director.call("support_energy_multiplier")), 0.25, 2.0)
	return 1.0

func _activate(scene: Object) -> void:
	var support := current_support()
	if support.is_empty(): return
	var kind := SupportRules.support_type(support)
	var defence_indices: Array[int] = []
	var emp_indices: Array[int] = []
	if kind == "defence": defence_indices = SupportRules.defence_indices(scene.get("enemy_bullets"), scene.get("player_position"), support)
	elif kind == "emp": emp_indices = SupportRules.autonomous_enemy_indices(scene.get("enemies"), scene.get("player_position"), support)
	var has_target := true
	if kind == "defence": has_target = not defence_indices.is_empty()
	elif kind == "emp": has_target = not emp_indices.is_empty()
	var effective_support := support.duplicate(true)
	var effective_energy_cost := SupportRules.energy_cost(support) * _craft_energy_multiplier()
	effective_support["energy_cost"] = effective_energy_cost
	if not SupportRules.can_activate(float(scene.get("energy")), _cooldown, effective_support, has_target):
		if kind == "defence" and not has_target: _set_status(scene, "POINT DEFENCE - NO THREAT")
		elif kind == "emp" and not has_target: _set_status(scene, "EMP - NO AUTONOMOUS TARGET")
		return
	scene.set("energy", maxf(0.0, float(scene.get("energy")) - effective_energy_cost))
	_cooldown = SupportRules.cooldown(support)
	match kind:
		"rockets", "crossfire": _fire_projectiles(scene, support, false)
		"hunter": _fire_projectiles(scene, support, true)
		"defence": _apply_point_defence(scene, defence_indices)
		"emp": _apply_emp(scene, emp_indices, support)
		"magnetic":
			_magnetic_support = support.duplicate(true)
			_magnetic_timer = SupportRules.duration(support, 2.4)
	_set_status(scene, current_support_name().to_upper())

func _fire_projectiles(scene: Object, support: Dictionary, homing: bool) -> void:
	var bullets: Array = scene.get("bullets")
	var origin: Vector2 = scene.get("player_position") + Vector2(0, -15)
	var speed := maxf(40.0, float(support.get("projectile_speed", 320.0)))
	var damage := maxi(1, int(support.get("damage", 1)))
	var angles := SupportRules.projectile_angles(support)
	for angle in angles:
		var bullet := {"position":origin,"velocity":Vector2.UP.rotated(float(angle))*speed,"damage":damage,"support":true,"support_id":str(support.get("id","support")),"strategic_support":bool(support.get("strategic",false))}
		if homing:
			bullet["support_homing"] = true
			bullet["turn_rate"] = maxf(0.1, float(support.get("turn_rate", 2.4)))
			bullet["life"] = maxf(0.2, float(support.get("life", 4.0)))
		bullets.append(bullet)
	scene.set("bullets", bullets)
	scene.set("shots_fired", int(scene.get("shots_fired")) + angles.size())

func _apply_emp(scene: Object, indices: Array[int], support: Dictionary) -> void:
	var enemies: Array = scene.get("enemies")
	var base_duration := SupportRules.duration(support, 2.8)
	for index in indices:
		if index < 0 or index >= enemies.size(): continue
		var enemy: Dictionary = enemies[index]
		var resistance := SupportRules.emp_resistance(enemy)
		var effective_duration := SupportRules.emp_effective_duration(base_duration, resistance)
		enemy["emp_timer"] = maxf(float(enemy.get("emp_timer", 0.0)), effective_duration)
		if not bool(enemy.get("boss", false)):
			if not enemy.has("emp_base_speed"): enemy["emp_base_speed"] = float(enemy.get("speed", 0.0))
			enemy["emp_slow_scale"] = SupportRules.emp_speed_scale(resistance)
			enemy["speed"] = maxf(4.0, float(enemy["emp_base_speed"]) * float(enemy["emp_slow_scale"]))
		enemies[index] = enemy
	scene.set("enemies", enemies)

func _update_emp_disruption(scene: Object, delta: float) -> void:
	var enemies: Array = scene.get("enemies"); var changed := false
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY or not enemy.has("emp_timer"): continue
		var timer := maxf(0.0, float(enemy.get("emp_timer", 0.0)) - delta)
		enemy["emp_timer"] = timer
		if timer > 0.0:
			enemy["fire_timer"] = maxf(float(enemy.get("fire_timer", 0.0)), 0.35)
			if enemy.has("emp_base_speed") and not bool(enemy.get("boss", false)):
				var slow_scale := clampf(float(enemy.get("emp_slow_scale", 0.35)), 0.25, 1.0)
				enemy["speed"] = maxf(4.0, float(enemy["emp_base_speed"]) * slow_scale)
		else:
			if enemy.has("emp_base_speed"):
				enemy["speed"] = float(enemy["emp_base_speed"])
				enemy.erase("emp_base_speed")
			enemy.erase("emp_slow_scale")
			enemy.erase("emp_timer")
		enemies[i] = enemy; changed = true
	if changed: scene.set("enemies", enemies)

func _update_magnetic_field(scene: Object, delta: float) -> void:
	if _magnetic_timer <= 0.0: return
	_magnetic_timer = maxf(0.0, _magnetic_timer - delta)
	var bullets: Array = scene.get("enemy_bullets"); var player_position: Vector2 = scene.get("player_position")
	var indices := SupportRules.defence_indices(bullets, player_position, _magnetic_support)
	for index in indices:
		if index < 0 or index >= bullets.size(): continue
		var bullet = bullets[index]
		if typeof(bullet) != TYPE_DICTIONARY: continue
		var position: Vector2 = bullet.get("position", Vector2.ZERO); var velocity: Vector2 = bullet.get("velocity", Vector2.DOWN * 100.0)
		var away := player_position.direction_to(position)
		if away.length_squared() < 0.001: away = Vector2.DOWN
		bullet["velocity"] = away.normalized() * maxf(40.0, velocity.length())
		bullet["homing"] = false; bullets[index] = bullet
	scene.set("enemy_bullets", bullets)

func _update_hunter_projectiles(scene: Object, delta: float) -> void:
	var bullets: Array = scene.get("bullets"); var enemies: Array = scene.get("enemies")
	if bullets.is_empty() or enemies.is_empty(): return
	var changed := false
	for i in range(bullets.size()):
		var bullet = bullets[i]
		if typeof(bullet) != TYPE_DICTIONARY or not bool(bullet.get("support_homing", false)): continue
		var life := float(bullet.get("life", 0.0)) - delta; bullet["life"] = life
		if life <= 0.0:
			bullet.erase("support_homing"); bullets[i] = bullet; changed = true; continue
		var bullet_position: Vector2 = bullet.get("position", Vector2.ZERO); var target = _nearest_enemy_position(enemies, bullet_position)
		if target != null:
			var velocity: Vector2 = bullet.get("velocity", Vector2.UP * 200.0); var desired := bullet_position.direction_to(target)
			if desired.length_squared() > 0.001 and velocity.length_squared() > 0.001:
				var turn := clampf(velocity.normalized().angle_to(desired), -float(bullet.get("turn_rate", 2.4))*delta, float(bullet.get("turn_rate", 2.4))*delta)
				bullet["velocity"] = velocity.rotated(turn)
		bullets[i] = bullet; changed = true
	if changed: scene.set("bullets", bullets)

func _nearest_enemy_position(enemies: Array, origin: Vector2):
	var found := false; var best_position := Vector2.ZERO; var best_distance := INF
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0: continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO); var distance := position.distance_squared_to(origin)
		if distance < best_distance: best_distance = distance; best_position = position; found = true
	return best_position if found else null

func _apply_point_defence(scene: Object, indices: Array[int]) -> void:
	var enemy_bullets: Array = scene.get("enemy_bullets")
	for index in indices:
		if index >= 0 and index < enemy_bullets.size(): enemy_bullets.remove_at(index)
	scene.set("enemy_bullets", enemy_bullets)

func _set_status(scene: Object, text: String) -> void:
	scene.set("status_text", text); scene.set("status_timer", 1.8)

func _ensure_actions() -> void:
	_add_key_action("fire_support", KEY_Z); _add_key_action("cycle_support", KEY_C); _add_key_action("upgrade_support", KEY_V)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	var event := InputEventKey.new(); event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
