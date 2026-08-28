extends Node2D

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
const PLAYER_SPEED := 220.0
const PLAYFIELD := Rect2(18.0, 52.0, 604.0, 296.0)

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
var wave := 1
var bombs := 3
var credits := 0
var mission_index := 0
var weapon_index := 0
var boss_spawned := false
var current_boss_id := ""
var current_mission_name := "COASTAL INTERCEPT"
var current_briefing := ""
var result_text := ""
var bullets: Array = []
var enemy_bullets: Array = []
var enemies: Array = []
var pickups: Array = []
var enemy_catalog: Array = []
var weapon_catalog: Array = []
var mission_catalog: Array = []
var campaign: Dictionary = {}

func _ready() -> void:
	_configure_input()
	_load_content()
	_prepare_mission(0)
	queue_redraw()

func _process(delta: float) -> void:
	if phase == GamePhase.TITLE:
		if Input.is_action_just_pressed("confirm"):
			_start_mission()
	elif phase == GamePhase.PLAYING:
		_update_mission(delta)
		if Input.is_action_just_pressed("cancel"):
			phase = GamePhase.TITLE
			_clear_combat()
	elif phase == GamePhase.RESULT:
		if Input.is_action_just_pressed("confirm"):
			mission_index = (mission_index + 1) % maxi(1, mission_catalog.size())
			_prepare_mission(mission_index)
			phase = GamePhase.TITLE
		elif Input.is_action_just_pressed("restart"):
			_start_mission()
	queue_redraw()

func _update_mission(delta: float) -> void:
	mission_time += delta
	if mission_time >= mission_duration:
		_finish_mission(true)
		return
	fire_timer = maxf(0.0, fire_timer - delta)
	secondary_timer = maxf(0.0, secondary_timer - delta)
	enemy_spawn_timer -= delta
	wave = CombatRules.wave_for_time(mission_time)
	_update_player(delta)
	_update_weapons()
	_update_bullets(delta)
	_update_enemy_bullets(delta)
	_update_pickups(delta)
	_update_enemies(delta)
	_resolve_combat()
	_try_spawn_boss()
	if enemy_spawn_timer <= 0.0 and not _boss_alive():
		_spawn_enemy()
		enemy_spawn_timer = CombatRules.enemy_spawn_interval(wave)

func _load_content() -> void:
	var enemies_data = ContentCatalog.load_json("res://data/enemies.json")
	var weapons_data = ContentCatalog.load_json("res://data/weapons.json")
	var missions_data = ContentCatalog.load_json("res://data/missions.json")
	var campaign_data = ContentCatalog.load_json("res://data/campaign.json")
	if typeof(enemies_data) == TYPE_DICTIONARY:
		enemy_catalog = enemies_data.get("enemies", [])
	if typeof(weapons_data) == TYPE_DICTIONARY:
		weapon_catalog = weapons_data.get("weapons", [])
	if typeof(missions_data) == TYPE_DICTIONARY:
		mission_catalog = missions_data.get("missions", [])
	if typeof(campaign_data) == TYPE_DICTIONARY:
		campaign = campaign_data
		credits = int(campaign.get("starting_credits", 0))

func _prepare_mission(index: int) -> void:
	if mission_catalog.is_empty():
		current_mission_name = "SCRAMBLE"
		current_briefing = "Intercept all incoming hostile aircraft."
		mission_duration = 150.0
		current_boss_id = ""
		return
	var mission: Dictionary = mission_catalog[clampi(index, 0, mission_catalog.size() - 1)]
	current_mission_name = str(mission.get("name", "SCRAMBLE")).to_upper()
	current_briefing = str(mission.get("briefing", ""))
	mission_duration = float(mission.get("duration_seconds", 150.0))
	current_boss_id = str(mission.get("boss_id", ""))

func _start_mission() -> void:
	phase = GamePhase.PLAYING
	mission_time = 0.0
	score = 0
	hull = 100
	shield = 100
	bombs = 3
	wave = 1
	weapon_index = 0
	boss_spawned = false
	enemy_spawn_timer = 0.35
	player_position = Vector2(320.0, 292.0)
	_clear_combat()

func _finish_mission(success: bool) -> void:
	phase = GamePhase.RESULT
	_clear_combat()
	if success:
		var reward := 1000 + score / 10
		credits += reward
		result_text = "MISSION COMPLETE  +%d CREDITS" % reward
	else:
		result_text = "AIRFRAME LOST  PRESS R TO RETRY"

func _clear_combat() -> void:
	bullets.clear()
	enemy_bullets.clear()
	enemies.clear()
	pickups.clear()

func _update_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += movement * PLAYER_SPEED * delta
	player_position.x = clampf(player_position.x, PLAYFIELD.position.x + 12.0, PLAYFIELD.end.x - 12.0)
	player_position.y = clampf(player_position.y, PLAYFIELD.position.y + 16.0, PLAYFIELD.end.y - 12.0)

func _active_weapon() -> Dictionary:
	var primaries: Array = []
	for weapon in weapon_catalog:
		if str(weapon.get("slot", "")) == "primary":
			primaries.append(weapon)
	if primaries.is_empty():
		return {"name":"Twin Cannon Mk I","damage":1,"fire_interval":0.11,"projectile_speed":430.0,"projectiles":2,"spread_degrees":0.0}
	return primaries[weapon_index % primaries.size()]

func _update_weapons() -> void:
	var weapon := _active_weapon()
	if Input.is_action_pressed("fire_primary") and fire_timer <= 0.0:
		fire_timer = float(weapon.get("fire_interval", 0.11))
		var projectile_count := maxi(1, int(weapon.get("projectiles", 1)))
		var spread := float(weapon.get("spread_degrees", 0.0))
		var speed := float(weapon.get("projectile_speed", 430.0))
		var damage := int(weapon.get("damage", 1))
		for i in range(projectile_count):
			var angle := 0.0
			if projectile_count > 1:
				angle = deg_to_rad(lerpf(-spread, spread, float(i) / float(projectile_count - 1)))
			bullets.append({"position": player_position + Vector2(0.0, -16.0), "velocity": Vector2.UP.rotated(angle) * speed, "damage": damage})
	if Input.is_action_just_pressed("fire_secondary") and secondary_timer <= 0.0 and bombs > 0:
		bombs -= 1
		secondary_timer = 1.0
		for enemy in enemies:
			score += 75 + int(enemy["hp"]) * 25
		enemies.clear()
		enemy_bullets.clear()

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var position: Vector2 = bullet["position"]
		position += Vector2(bullet.get("velocity", Vector2.UP * 430.0)) * delta
		bullet["position"] = position
		bullets[i] = bullet
		if not PLAYFIELD.grow(24.0).has_point(position):
			bullets.remove_at(i)

func _update_enemy_bullets(delta: float) -> void:
	for i in range(enemy_bullets.size() - 1, -1, -1):
		var shot: Dictionary = enemy_bullets[i]
		var position: Vector2 = shot["position"]
		position += Vector2(shot["velocity"]) * delta
		shot["position"] = position
		enemy_bullets[i] = shot
		if position.distance_squared_to(player_position) <= 120.0:
			_apply_damage(int(shot.get("damage", 8)))
			enemy_bullets.remove_at(i)
		elif not PLAYFIELD.grow(32.0).has_point(position):
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
		elif position.y > PLAYFIELD.end.y + 20.0:
			pickups.remove_at(i)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy["age"] = float(enemy["age"]) + delta
		enemy["fire_timer"] = float(enemy["fire_timer"]) - delta
		var position: Vector2 = enemy["position"]
		var is_boss := bool(enemy.get("boss", false))
		if is_boss and position.y < 105.0:
			position.y += float(enemy["speed"]) * delta
		elif not is_boss:
			position.y += float(enemy["speed"]) * delta
		position.x += sin(float(enemy["age"]) * float(enemy["turn_rate"]) + float(enemy["phase"])) * float(enemy["drift"]) * delta
		position.x = clampf(position.x, PLAYFIELD.position.x + 18.0, PLAYFIELD.end.x - 18.0)
		enemy["position"] = position
		if float(enemy["fire_timer"]) <= 0.0 and position.y > PLAYFIELD.position.y:
			_fire_enemy_weapon(enemy)
			enemy["fire_timer"] = ProjectileRules.enemy_fire_interval(str(enemy.get("weapon", "single_burst")), wave)
		enemies[i] = enemy
		if not is_boss and position.y > PLAYFIELD.end.y + 22.0:
			enemies.remove_at(i)

func _fire_enemy_weapon(enemy: Dictionary) -> void:
	var origin: Vector2 = enemy["position"]
	var weapon_id := str(enemy.get("weapon", "single_burst"))
	var speed := ProjectileRules.enemy_projectile_speed(weapon_id)
	var damage := 8 if not bool(enemy.get("boss", false)) else 14
	var velocity := ProjectileRules.enemy_shot_velocity(origin, player_position, speed)
	enemy_bullets.append({"position":origin,"velocity":velocity,"damage":damage})
	if weapon_id == "twin_burst":
		enemy_bullets.append({"position":origin,"velocity":velocity.rotated(0.16),"damage":damage})
		enemy_bullets.append({"position":origin,"velocity":velocity.rotated(-0.16),"damage":damage})

func _resolve_combat() -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var bullet_hit := false
		for enemy_index in range(enemies.size() - 1, -1, -1):
			if Vector2(bullets[bullet_index]["position"]).distance_squared_to(Vector2(enemies[enemy_index]["position"])) <= (420.0 if bool(enemies[enemy_index].get("boss", false)) else 196.0):
				enemies[enemy_index]["hp"] -= int(bullets[bullet_index]["damage"])
				bullet_hit = true
				if int(enemies[enemy_index]["hp"]) <= 0:
					var destroyed: Dictionary = enemies[enemy_index]
					score += int(destroyed["value"])
					_maybe_drop_pickup(Vector2(destroyed["position"]), bool(destroyed.get("boss", false)))
					enemies.remove_at(enemy_index)
				break
		if bullet_hit:
			bullets.remove_at(bullet_index)
	for enemy_index in range(enemies.size() - 1, -1, -1):
		if Vector2(enemies[enemy_index]["position"]).distance_squared_to(player_position) <= 420.0:
			_apply_damage(24 if bool(enemies[enemy_index].get("boss", false)) else 18)
			if not bool(enemies[enemy_index].get("boss", false)):
				enemies.remove_at(enemy_index)

func _maybe_drop_pickup(position: Vector2, guaranteed: bool = false) -> void:
	var kind := "weapon" if guaranteed else ProjectileRules.pickup_kind_for_roll(randf())
	if kind != "":
		pickups.append({"position":position,"kind":kind})

func _apply_pickup(kind: String) -> void:
	match kind:
		"shield": shield = mini(100, shield + 35)
		"repair": hull = mini(100, hull + 25)
		"bomb": bombs = mini(5, bombs + 1)
		"weapon":
			var primary_count := 0
			for weapon in weapon_catalog:
				if str(weapon.get("slot", "")) == "primary": primary_count += 1
			if primary_count > 0: weapon_index = (weapon_index + 1) % primary_count

func _apply_damage(amount: int) -> void:
	var state := CombatRules.apply_shielded_damage(hull, shield, amount)
	hull = int(state["hull"])
	shield = int(state["shield"])
	if hull <= 0:
		_finish_mission(false)

func _find_enemy_archetype(id: String) -> Dictionary:
	for enemy in enemy_catalog:
		if str(enemy.get("id", "")) == id:
			return enemy
	return {}

func _spawn_enemy(archetype: Dictionary = {}) -> void:
	if archetype.is_empty():
		var candidates: Array = []
		for item in enemy_catalog:
			if not bool(item.get("boss", false)):
				candidates.append(item)
		if not candidates.is_empty(): archetype = candidates[randi() % candidates.size()]
	var base_hp := int(archetype.get("hp", 1))
	var is_boss := bool(archetype.get("boss", false))
	var hp := maxi(1, base_hp + (0 if is_boss else int(wave / 5)))
	var x := PLAYFIELD.get_center().x if is_boss else randf_range(PLAYFIELD.position.x + 24.0, PLAYFIELD.end.x - 24.0)
	var enemy_class := str(archetype.get("class", "air"))
	var speed_bias := 0.0 if enemy_class == "ground" else (10.0 if enemy_class == "air" else -8.0)
	var drift := 28.0 if is_boss else (10.0 if enemy_class == "ground" else randf_range(16.0, 38.0))
	enemies.append({"id":str(archetype.get("id", "bogey")),"category":enemy_class,"position":Vector2(x, PLAYFIELD.position.y - 18.0),"speed":float(archetype.get("speed", 72.0)) + speed_bias + (0.0 if is_boss else float(wave) * 4.0),"drift":drift,"turn_rate":0.75 if is_boss else randf_range(1.1, 2.4),"phase":randf_range(0.0, TAU),"age":0.0,"hp":hp,"value":CombatRules.destroy_value(int(archetype.get("value", 100)), wave),"weapon":str(archetype.get("weapon", "single_burst")),"fire_timer":randf_range(0.5, 1.6),"boss":is_boss})

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
	_add_key_action("move_left", KEY_A); _add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D); _add_key_action("move_right", KEY_RIGHT)
	_add_key_action("move_up", KEY_W); _add_key_action("move_up", KEY_UP)
	_add_key_action("move_down", KEY_S); _add_key_action("move_down", KEY_DOWN)
	_add_key_action("fire_primary", KEY_SPACE)
	_add_key_action("fire_secondary", KEY_X)
	_add_key_action("confirm", KEY_ENTER)
	_add_key_action("cancel", KEY_ESCAPE)
	_add_key_action("restart", KEY_R)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	var event := InputEventKey.new(); event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("10151b"))
	if phase == GamePhase.TITLE:
		_draw_title(); return
	if phase == GamePhase.RESULT:
		_draw_result(); return
	_draw_gameplay()

func _draw_title() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(0, 95), "STRIKE WING '94", HORIZONTAL_ALIGNMENT_CENTER, 640, 30, Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 135), current_mission_name, HORIZONTAL_ALIGNMENT_CENTER, 640, 18, Color("f0d87a"))
	draw_string(ThemeDB.fallback_font, Vector2(80, 175), current_briefing, HORIZONTAL_ALIGNMENT_CENTER, 480, 13, Color("8997a1"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 245), "ENTER  LAUNCH", HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color("d8dde2"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 280), "CREDITS %06d" % credits, HORIZONTAL_ALIGNMENT_CENTER, 640, 12, Color("8997a1"))

func _draw_result() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(0, 120), result_text, HORIZONTAL_ALIGNMENT_CENTER, 640, 22, Color("f0d87a"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 165), "SCORE %08d   CREDITS %06d" % [score, credits], HORIZONTAL_ALIGNMENT_CENTER, 640, 15, Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 230), "ENTER  CONTINUE    R  RETRY", HORIZONTAL_ALIGNMENT_CENTER, 640, 13, Color("8997a1"))

func _draw_gameplay() -> void:
	draw_rect(PLAYFIELD, Color("121c23"))
	for i in range(18):
		var y := fposmod(float(i * 28) + mission_time * 48.0, 420.0) - 30.0
		draw_line(Vector2(PLAYFIELD.position.x, y), Vector2(PLAYFIELD.end.x, y), Color("1c2a34"), 1.0)
	for bullet in bullets:
		var b: Vector2 = bullet["position"]
		draw_rect(Rect2(b.x - 1.0, b.y - 6.0, 3.0, 9.0), Color("f0d87a"))
	for shot in enemy_bullets:
		var s: Vector2 = shot["position"]
		draw_circle(s, 3.0, Color("e8644f"))
	for pickup in pickups:
		var q: Vector2 = pickup["position"]
		draw_rect(Rect2(q.x - 5.0, q.y - 5.0, 10.0, 10.0), Color("72c7b2"), false, 2.0)
	for enemy in enemies:
		var e: Vector2 = enemy["position"]
		var is_boss := bool(enemy.get("boss", false))
		var tone := Color("d05b4f") if is_boss else (Color("a84c43") if enemy.get("category", "air") == "air" else Color("80745d"))
		var size := 1.65 if is_boss else 1.0
		draw_colored_polygon(PackedVector2Array([e + Vector2(0, 11) * size, e + Vector2(-13, -8) * size, e + Vector2(0, -4) * size, e + Vector2(13, -8) * size]), tone)
	var p := player_position
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -18), p + Vector2(-16, 13), p + Vector2(0, 8), p + Vector2(16, 13)]), Color("d8dde2"))
	draw_rect(Rect2(8, 8, 624, 38), Color("080b0f"))
	var remaining := maxi(0, int(ceil(mission_duration - mission_time)))
	var weapon_name := str(_active_weapon().get("name", "CANNON")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(16, 27), "H%03d S%03d B%01d W%02d T%03d %08d" % [hull, shield, bombs, wave, remaining, score], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 44), "%s  %s" % [current_mission_name, weapon_name], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8997a1"))
