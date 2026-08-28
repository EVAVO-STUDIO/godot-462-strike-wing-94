extends Node2D

const PLAYER_SPEED := 220.0
const SHOT_COOLDOWN := 0.11

var player_position := Vector2(320.0, 285.0)
var fire_timer := 0.0
var score := 0
var hull := 100
var shield := 100
var mission_time := 0.0

func _ready() -> void:
	_configure_input()
	queue_redraw()

func _process(delta: float) -> void:
	mission_time += delta
	fire_timer = maxf(0.0, fire_timer - delta)

	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += movement * PLAYER_SPEED * delta
	player_position.x = clampf(player_position.x, 24.0, 616.0)
	player_position.y = clampf(player_position.y, 64.0, 336.0)

	if Input.is_action_pressed("fire_primary") and fire_timer <= 0.0:
		fire_timer = SHOT_COOLDOWN
		score += 10

	queue_redraw()

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
	# Temporary code-drawn prototype visuals. These are intentionally disposable;
	# production sprites, terrain and UI will replace them without changing the game loop.
	draw_rect(Rect2(0, 0, 640, 360), Color("10151b"))

	for i in range(18):
		var y := fposmod(float(i * 28) + mission_time * 48.0, 420.0) - 30.0
		draw_line(Vector2(0, y), Vector2(640, y), Color("18242d"), 1.0)

	var p := player_position
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -18),
		p + Vector2(-16, 13),
		p + Vector2(0, 8),
		p + Vector2(16, 13)
	]), Color("d8dde2"))

	draw_rect(Rect2(8, 8, 624, 38), Color("080b0f"))
	draw_string(ThemeDB.fallback_font, Vector2(18, 31), "STRIKE WING '94   HULL %03d   SHIELD %03d   SCORE %08d" % [hull, shield, score], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e3e6e8"))
