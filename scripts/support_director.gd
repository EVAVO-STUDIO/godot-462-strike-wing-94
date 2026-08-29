extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const ProgressionRules = preload("res://scripts/progression_rules.gd")
const SupportRules = preload("res://scripts/support_rules.gd")

var support_catalog: Array = []
var selected_index := 0
var unlocked_index := 0
var _cooldown := 0.0

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
	if phase == 0:
		_handle_title(scene)
	elif phase == 1:
		_update_hunter_projectiles(scene, delta)
		if Input.is_action_just_pressed("fire_support"):
			_activate(scene)

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
	return {
		"selected_index": SupportRules.sanitize_selected(selected_index, unlocked_index, support_catalog.size()),
		"unlocked_index": SupportRules.sanitize_unlock(unlocked_index, support_catalog.size())
	}

func restore_support_state(saved_selected: int, saved_unlocked: int) -> void:
	unlocked_index = SupportRules.sanitize_unlock(saved_unlocked, support_catalog.size())
	selected_index = SupportRules.sanitize_selected(saved_selected, unlocked_index, support_catalog.size())

func rearm_support() -> void:
	_cooldown = 0.0
	var strike := get_node_or_null("/root/StrikeOrdnanceDirector")
	if strike != null and strike.has_method("rearm_full"):
		strike.call("rearm_full")

func _handle_title(scene: Object) -> void:
	if Input.is_action_just_pressed("cycle_support"):
		selected_index = SupportRules.cycle_selected(selected_index, unlocked_index, support_catalog.size())
		_set_status(scene, "SUPPORT %s" % current_support_name().to_upper())
	elif Input.is_action_just_pressed("upgrade_support"):
		_buy_next_support(scene)

func _buy_next_support(scene: Object) -> void:
	if support_catalog.is_empty():
		return
	var result := ProgressionRules.next_weapon_index(unlocked_index, support_catalog, int(scene.get("credits")))
	if bool(result.get("changed", false)):
		unlocked_index = int(result.get("index", unlocked_index))
		selected_index = unlocked_index
		scene.set("credits", int(result.get("credits", scene.get("credits"))))
		_set_status(scene, "SUPPORT UNLOCKED %s" % current_support_name().to_upper())
		return
	var next_index := clampi(unlocked_index + 1, 0, maxi(0, support_catalog.size() - 1))
	if next_index == unlocked_index:
		_set_status(scene, "ALL SUPPORT SYSTEMS UNLOCKED")
	else:
		_set_status(scene, "SUPPORT NEEDS %d CREDITS" % int(support_catalog[next_index].get("cost", 0)))

func _craft_energy_multiplier() -> float:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("support_energy_multiplier"):
		return clampf(float(director.call("support_energy_multiplier")), 0.25, 2.0)
	return 1.0

func _activate(scene: Object) -> void:
	var support := current_support()
	if support.is_empty():
		return
	var kind := SupportRules.support_type(support)
	var defence_indices: Array[int] = []
	if kind == "defence":
		defence_indices = SupportRules.defence_indices(scene.get("enemy_bullets"), scene.get("player_position"), support)
	var has_target := kind != "defence" or not defence_indices.is_empty()
	var effective_support := support.duplicate(true)
	var effective_energy_cost := SupportRules.energy_cost(support) * _craft_energy_multiplier()
	effective_support["energy_cost"] = effective_energy_cost
	if not SupportRules.can_activate(float(scene.get("energy")), _cooldown, effective_support, has_target):
		if kind == "defence" and not has_target:
			_set_status(scene, "POINT DEFENCE - NO THREAT")
		return
	scene.set("energy", maxf(0.0, float(scene.get("energy")) - effective_energy_cost))
	_cooldown = SupportRules.cooldown(support)
	match kind:
		"rockets", "crossfire":
			_fire_projectiles(scene, support, false)
		"hunter":
			_fire_projectiles(scene, support, true)
		"defence":
			_apply_point_defence(scene, defence_indices)
	_set_status(scene, current_support_name().to_upper())

func _fire_projectiles(scene: Object, support: Dictionary, homing: bool) -> void:
	var bullets: Array = scene.get("bullets")
	var origin: Vector2 = scene.get("player_position") + Vector2(0, -15)
	var speed := maxf(40.0, float(support.get("projectile_speed", 320.0)))
	var damage := maxi(1, int(support.get("damage", 1)))
	var angles := SupportRules.projectile_angles(support)
	for angle in angles:
		var bullet := {"position": origin,"velocity": Vector2.UP.rotated(float(angle)) * speed,"damage": damage,"support": true}
		if homing:
			bullet["support_homing"] = true
			bullet["turn_rate"] = maxf(0.1, float(support.get("turn_rate", 2.4)))
			bullet["life"] = maxf(0.2, float(support.get("life", 4.0)))
		bullets.append(bullet)
	scene.set("bullets", bullets)
	scene.set("shots_fired", int(scene.get("shots_fired")) + angles.size())

func _update_hunter_projectiles(scene: Object, delta: float) -> void:
	var bullets: Array = scene.get("bullets")
	var enemies: Array = scene.get("enemies")
	if bullets.is_empty() or enemies.is_empty(): return
	var changed := false
	for i in range(bullets.size()):
		var bullet = bullets[i]
		if typeof(bullet) != TYPE_DICTIONARY or not bool(bullet.get("support_homing", false)): continue
		var life := float(bullet.get("life", 0.0)) - delta
		bullet["life"] = life
		if life <= 0.0:
			bullet.erase("support_homing"); bullets[i] = bullet; changed = true; continue
		var bullet_position: Vector2 = bullet.get("position", Vector2.ZERO)
		var target = _nearest_enemy_position(enemies, bullet_position)
		if target != null:
			var velocity: Vector2 = bullet.get("velocity", Vector2.UP * 200.0)
			var desired := bullet_position.direction_to(target)
			if desired.length_squared() > 0.001 and velocity.length_squared() > 0.001:
				var turn := clampf(velocity.normalized().angle_to(desired), -float(bullet.get("turn_rate", 2.4)) * delta, float(bullet.get("turn_rate", 2.4)) * delta)
				bullet["velocity"] = velocity.rotated(turn)
		bullets[i] = bullet; changed = true
	if changed: scene.set("bullets", bullets)

func _nearest_enemy_position(enemies: Array, origin: Vector2):
	var found := false; var best_position := Vector2.ZERO; var best_distance := INF
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0: continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(origin)
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
