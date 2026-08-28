extends Node2D

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PLAYER_SPEED := 220.0
const SHOT_COOLDOWN := 0.11
const BULLET_SPEED := 430.0
const PLAYFIELD := Rect2(18.0, 52.0, 604.0, 296.0)

var player_position := Vector2(320.0, 292.0)
var fire_timer := 0.0
var secondary_timer := 0.0
var enemy_spawn_timer := 0.5
var mission_time := 0.0
var score := 0
var hull := 100
var shield := 100
var wave := 1
var bombs := 3
var credits := 0
var current_mission_name := "SCRAMBLE"
var bullets: Array = []
var enemies: Array = []
var enemy_catalog: Array = []
var weapon_catalog: Array = []
var mission_catalog: Array = []
var campaign: Dictionary = {}

func _ready() -> void:
	_configure_input()
	_load_content()
	queue_redraw()

func _process(delta: float) -> void:
	mission_time += delta
	fire_timer = maxf(0.0, fire_timer - delta)
	secondary_timer = maxf(0.0, secondary_timer - delta)
	enemy_spawn_timer -= delta
	wave = 1 + int(mission_time / 20.0)

	_update_player(delta)
	_update_weapons()
	_update_bullets(delta)
	_update_enemies(delta)
	_resolve_combat()

	if enemy_spawn_timer <= 0.0:
		_spawn_enemy()
		enemy_spawn_timer = maxf(0.28, 1.05 - float(wave) * 0.055)

	queue_redraw()

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
		if not mission_catalog.is_empty():
			current_mission_name = str(mission_catalog[0].get("name", "SCRAMBLE")).to_upper()
	if typeof(campaign_data) == TYPE_DICTIONARY:
		campaign = campaign_data
		credits = int(campaign.get("starting_credits", 0))

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
	var remaining := amount
	if shield > 0:
		var absorbed := mini(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0:
		hull = maxi(0, hull - remaining)
	if hull <= 0:
		_restart_run()

func _restart_run() -> void:
	hull = 100
	shield = 100
	bombs = 3
	score = maxi(0, score - 1000)
	player_position = Vector2(320.0, 292.0)
	bullets.clear()
	enemies.clear()

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

	enemies.append({
		"id": str(archetype.get("id", "bogey")),
		"category": category,
		"position": Vector2(x, PLAYFIELD.position.y - 18.0),
		"speed": float(archetype.get("speed", 72.0)) + speed_bias + float(wave) * 4.0,
		"drift": drift,
		"turn_rate": randf_range(1.1, 2.4),
		"phase": randf_range(0.0, TAU),
		"age": 0.0,
		"hp": hp,
		"value": int(archetype.get("score", 100)) + wave * 15
	})

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

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("10151b"))
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
	draw_string(ThemeDB.fallback_font, Vector2(16, 27), "STRIKE WING '94  H%03d S%03d B%01d W%02d %08d" % [hull, shield, bombs, wave, score], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e3e6e8"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 44), "%s  CREDITS %06d" % [current_mission_name, credits], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8997a1"))
