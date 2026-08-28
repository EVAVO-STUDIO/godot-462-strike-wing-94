extends Node2D

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")
const PLAYER_SPEED := 220.0
const SHOT_COOLDOWN := 0.11
const BULLET_SPEED := 430.0
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
var current_mission_name := "COASTAL INTERCEPT"
var current_briefing := ""
var result_text := ""
var bullets: Array = []
var enemies: Array = []
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
	_update_enemies(delta)
	_resolve_combat()
	if enemy_spawn_timer <= 0.0:
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
		return
	var mission: Dictionary = mission_catalog[clampi(index, 0, mission_catalog.size() - 1)]
	current_mission_name = str(mission.get("name", "SCRAMBLE")).to_upper()
	current_briefing = str(mission.get("briefing", ""))
	mission_duration = float(mission.get("duration_seconds", 150.0))

func _start_mission() -> void:
	phase = GamePhase.PLAYING
	mission_time = 0.0
	score = 0
	hull = 100
	shield = 100
	bombs = 3
	wave = 1
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
	enemies.clear()

func _update_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += movement * PLAYER_SPEED * delta
	player_position.x = clampf(player_position.x, PLAYFIELD.position.x + 12.0, PLAYFIELD.end.x - 12.0)
	player_position.y = clampf(player_position.y, PLAYFIELD.position.y + 16.0, PLAYFIELD.end.y - 12.0)

func _update_weapons() -> void:
	if Input.is_action_pressed("fire_primary") and fire_timer <= 0.0:
		fire_timer = SHOT_COOLDOWN
		bullets.append({"position": player_position + Vector2(-7.0, -16.0), "damage": 1})
		bullets.append({"position": player_position + Vector2(7.0, -16.0), "damage": 1})
	if Input.is_action_just_pressed("fire_secondary") and secondary_timer <= 0.0 and bombs > 0:
		bombs -= 1
		secondary_timer = 1.0
		for enemy in enemies:
			score += 75 + int(enemy["hp"]) * 25
		enemies.clear()

func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var position: Vector2 = bullet["position"]
		position.y -= BULLET_SPEED * delta
		bullet["position"] = position
		bullets[i] = bullet
		if position.y < PLAYFIELD.position.y - 12.0:
			bullets.remove_at(i)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy["age"] = float(enemy["age"]) + delta
		var position: Vector2 = enemy["position"]
		position.y += float(enemy["speed"]) * delta
		position.x += sin(float(enemy["age"]) * float(enemy["turn_rate"]) + float(enemy["phase"])) * float(enemy["drift"]) * delta
		position.x = clampf(position.x, PLAYFIELD.position.x + 12.0, PLAYFIELD.end.x - 12.0)
		enemy["position"] = position
		enemies[i] = enemy
		if position.y > PLAYFIELD.end.y + 22.0:
			enemies.remove_at(i)

func _resolve_combat() -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var bullet_hit := false
		for enemy_index in range(enemies.size() - 1, -1, -1):
			if bullets[bullet_index]["position"].distance_squared_to(enemies[enemy_index]["position"]) <= 196.0:
				enemies[enemy_index]["hp"] -= bullets[bullet_index]["damage"]
				bullet_hit = true
				if enemies[enemy_index]["hp"] <= 0:
					score += int(enemies[enemy_index]["value"])
					enemies.remove_at(enemy_index)
				break
		if bullet_hit:
			bullets.remove_at(bullet_index)
	for enemy_index in range(enemies.size() - 1, -1, -1):
		if enemies[enemy_index]["position"].distance_squared_to(player_position) <= 420.0:
			_apply_damage(18)
			enemies.remove_at(enemy_index)

func _apply_damage(amount: int) -> void:
	var state := CombatRules.apply_shielded_damage(hull, shield, amount)
	hull = int(state["hull"])
	shield = int(state["shield"])
	if hull <= 0:
		_finish_mission(false)

func _spawn_enemy() -> void:
	var archetype: Dictionary = {}
	if not enemy_catalog.is_empty():
		archetype = enemy_catalog[randi() % enemy_catalog.size()]
	var base_hp := int(archetype.get("hp", 1))
	var hp := maxi(1, base_hp + int(wave / 5))
	var x := randf_range(PLAYFIELD.position.x + 24.0, PLAYFIELD.end.x - 24.0)
	var category := str(archetype.get("category", "air"))
	var speed_bias := 0.0 if category == "ground" else (10.0 if category == "air" else -8.0)
	var drift := 10.0 if category == "ground" else randf_range(16.0, 38.0)
	enemies.append({"id": str(archetype.get("id", "bogey")), "category": category, "position": Vector2(x, PLAYFIELD.position.y - 18.0), "speed": float(archetype.get("speed", 72.0)) + speed_bias + float(wave) * 4.0, "drift": drift, "turn_rate": randf_range(1.1, 2.4), "phase": randf_range(0.0, TAU), "age": 0.0, "hp": hp, "value": CombatRules.destroy_value(int(archetype.get("score", 100)), wave)})

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
		_draw_title()
		return
	if phase == GamePhase.RESULT:
		_draw_result()
		return
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
	for enemy in enemies:
		var e: Vector2 = enemy["position"]
		var tone := Color("a84c43") if enemy.get("category", "air") == "air" else Color("80745d")
		draw_colored_polygon(PackedVector2Array([e + Vector2(0, 11), e + Vector2(-13, -8), e + Vector2(0, -4), e + Vector2(13, -8)]), tone)
	var p := player_position
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -18), p + Vector2(-16, 13), p + Vector2(0, 8), p + Vector2(16, 13)]), Color("d8dde2"))
	draw_rect(Rect2(8, 8, 624, 38), Color("080b0f"))
	var remaining := maxi(0, int(ceil(mission_duration - mission_time)))
	draw_string(ThemeDB.fallback_font, Vector2(16, 27), "H%03d S%03d B%01d W%02d T%03d %08d" % [hull, shield, bombs, wave, remaining, score], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 44), current_mission_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8997a1"))
