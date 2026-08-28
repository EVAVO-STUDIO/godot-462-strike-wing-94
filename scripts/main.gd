extends Node2D

const PLAYER_SPEED := 220.0
const SHOT_COOLDOWN := 0.11
const BULLET_SPEED := 430.0
const ENEMY_BASE_SPEED := 72.0
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
var bullets: Array = []
var enemies: Array = []

func _ready() -> void:
	_configure_input()
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
		bullets[i]["position"].y -= BULLET_SPEED * delta
		if bullets[i]["position"].y < PLAYFIELD.position.y - 12.0:
			bullets.remove_at(i)

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		enemy["age"] += delta
		enemy["position"].y += enemy["speed"] * delta
		enemy["position"].x += sin(enemy["age"] * enemy["turn_rate"] + enemy["phase"]) * enemy["drift"] * delta
		enemy["position"].x = clampf(enemy["position"].x, PLAYFIELD.position.x + 12.0, PLAYFIELD.end.x - 12.0)
		if enemy["position"].y > PLAYFIELD.end.y + 22.0:
			enemies.remove_at(i)

func _resolve_combat() -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var bullet_hit := false
		for enemy_index in range(enemies.size() - 1, -1, -1):
			if bullets[bullet_index]["position"].distance_squared_to(enemies[enemy_index]["position"]) <= 196.0:
				enemies[enemy_index]["hp"] -= bullets[bullet_index]["damage"]
				bullet_hit = true
				if enemies[enemy_index]["hp"] <= 0:
					score += enemies[enemy_index]["value"]
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
	var hp := 1 + int(wave / 4)
	var x := randf_range(PLAYFIELD.position.x + 24.0, PLAYFIELD.end.x - 24.0)
	enemies.append({
		"position": Vector2(x, PLAYFIELD.position.y - 18.0),
		"speed": ENEMY_BASE_SPEED + float(wave) * 5.0 + randf_range(-8.0, 18.0),
		"drift": randf_range(10.0, 34.0),
		"turn_rate": randf_range(1.1, 2.4),
		"phase": randf_range(0.0, TAU),
		"age": 0.0,
		"hp": hp,
		"value": 100 + wave * 20
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
		draw_colored_polygon(PackedVector2Array([
			e + Vector2(0, 11), e + Vector2(-13, -8), e + Vector2(0, -4), e + Vector2(13, -8)
		]), Color("a84c43"))

	var p := player_position
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -18), p + Vector2(-16, 13), p + Vector2(0, 8), p + Vector2(16, 13)
	]), Color("d8dde2"))

	draw_rect(Rect2(8, 8, 624, 38), Color("080b0f"))
	draw_string(ThemeDB.fallback_font, Vector2(16, 31), "STRIKE WING '94  H%03d S%03d  B%01d  W%02d  %08d" % [hull, shield, bombs, wave, score], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e3e6e8"))
