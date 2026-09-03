extends CanvasLayer

const AttractModeSurface = preload("res://scripts/attract_mode_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const SKY := preload("res://assets/runtime/environments/high_atmosphere/stratospheric_cloud_deck_loop_v1.png")
const CLOUDS := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_c.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_b.png"),
]
const WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v2.png")
const VX94_FRAMES := [
	preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png"),
	preload("res://assets/runtime/craft/vx94/vx94_transform_03.png"),
	preload("res://assets/runtime/craft/vx94/vx94_transform_02.png"),
	preload("res://assets/runtime/craft/vx94/vx94_transform_01.png"),
	preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png"),
]
const ACE := preload("res://assets/runtime/enemies/mercenary_air/ace_interceptor_idle.png")
const DRONE := preload("res://assets/runtime/enemies/machine_air/drone_hunter_idle.png")
const MACHINE_ARK := preload("res://assets/runtime/enemies/orbital_boss/machine_ark_idle.png")
const PLAYER_SHOT := preload("res://assets/runtime/effects/projectiles/ballistic/1.png")
const ENEMY_SHOT := preload("res://assets/runtime/effects/projectiles/enemy_cannon/1.png")

const IDLE_SECONDS := 24.0
const SHOW_SECONDS := 15.0

var active := false
var elapsed := 0.0
var idle_elapsed := 0.0
var _surface: Control
var _capture_requested := false

func _ready() -> void:
	layer = 90
	_capture_requested = "--capture-attract" in OS.get_cmdline_user_args()
	if DisplayServer.get_name() == "headless" and not _capture_requested:
		set_process(false)
		return
	set_process_input(true)
	set_process_unhandled_input(true)
	if _capture_requested:
		call_deferred("_begin")

func _process(delta: float) -> void:
	if active:
		elapsed += delta
		if elapsed >= SHOW_SECONDS:
			_end()
		elif _surface != null:
			_surface.queue_redraw()
		return
	if not _front_door_is_idle():
		idle_elapsed = 0.0
		return
	idle_elapsed += delta
	if idle_elapsed >= IDLE_SECONDS:
		_begin()

func _input(event: InputEvent) -> void:
	if not _is_activity(event):
		return
	if active:
		get_viewport().set_input_as_handled()
		_end()
	else:
		idle_elapsed = 0.0

func _unhandled_input(event: InputEvent) -> void:
	_input(event)

func _begin() -> void:
	if active:
		return
	active = true
	elapsed = 0.0
	idle_elapsed = 0.0
	_surface = AttractModeSurface.new()
	_surface.director = self
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_surface)

func _end() -> void:
	active = false
	elapsed = 0.0
	idle_elapsed = 0.0
	if _surface != null:
		_surface.queue_free()
		_surface = null

func _front_door_is_idle() -> bool:
	var startup := get_node_or_null("/root/StartupSequenceDirector")
	if startup != null and startup.has_method("is_complete") and not bool(startup.call("is_complete")):
		return false
	var scene := get_tree().current_scene
	return scene != null and _property(scene, "phase", -1) == 0 and str(_property(scene, "front_end_screen", "")) == "main_menu"

func draw_attract_mode(surface: CanvasItem) -> void:
	_draw_background(surface)
	if elapsed < 4.8:
		_draw_intercept(surface)
	elif elapsed < 9.4:
		_draw_hypersonic_break(surface)
	elif elapsed < 13.2:
		_draw_boss_engagement(surface)
	else:
		_draw_return_card(surface)
	_draw_demo_bezel(surface)

func _draw_background(surface: CanvasItem) -> void:
	var speed := 32.0 if elapsed < 4.8 else (148.0 if elapsed < 9.4 else 54.0)
	_draw_vertical_loop(surface, SKY, elapsed * speed, Color(0.32, 0.48, 0.58, 1.0))
	surface.draw_rect(Rect2(0, 0, 640, 360), Color(0.01, 0.04, 0.07, 0.34))
	for i in range(CLOUDS.size()):
		var x := fposmod(80.0 + i * 223.0 + elapsed * (9.0 + i * 3.0), 780.0) - 70.0
		var y := fposmod(60.0 + i * 137.0 + elapsed * speed * (0.32 + i * 0.08), 430.0) - 55.0
		_draw_centered(surface, CLOUDS[i], Vector2(x, y), 0.82 + i * 0.17, Color(0.72, 0.82, 0.86, 0.30))

func _draw_intercept(surface: CanvasItem) -> void:
	var craft := Vector2(320.0 + sin(elapsed * 1.35) * 26.0, 292.0)
	_draw_centered(surface, VX94_FRAMES[0], craft, 1.15)
	for i in range(3):
		var enemy_pos := Vector2(176.0 + i * 144.0 + sin(elapsed * 1.8 + i) * 18.0, 82.0 + i % 2 * 28.0 + elapsed * 9.0)
		_draw_centered(surface, ACE, enemy_pos, 0.82)
	for i in range(8):
		var shot_y := 270.0 - fposmod(elapsed * 178.0 + i * 45.0, 235.0)
		_draw_centered(surface, PLAYER_SHOT, craft + Vector2(-7.0 if i % 2 == 0 else 7.0, shot_y - 292.0), 1.0)
	PixelFont.draw_text(surface, "TACTICAL FORM // BOMBER", Vector2(24, 324), 1, Color("d9c66a"), 1)

func _draw_hypersonic_break(surface: CanvasItem) -> void:
	var local := elapsed - 4.8
	var transform_ratio := clampf(local / 0.72, 0.0, 1.0)
	var frame := clampi(int(floor(transform_ratio * VX94_FRAMES.size())), 0, VX94_FRAMES.size() - 1)
	var craft_y := lerpf(278.0, 202.0, clampf((local - 0.65) / 3.2, 0.0, 1.0))
	var craft := Vector2(320.0, craft_y)
	if local > 0.58:
		var flare_ratio := 0.5 + 0.5 * sin(local * 12.0)
		_draw_centered(surface, PersistentEffectArtLibrary.frame_for_ratio("afterburner", flare_ratio), craft + Vector2(0, 42), 1.35)
	if local > 0.68 and local < 1.48:
		_draw_centered(surface, PersistentEffectArtLibrary.frame_for_ratio("sonic_boom", (local - 0.68) / 0.8), craft, 2.4, Color(0.82, 0.94, 1.0, 0.82))
	_draw_centered(surface, VX94_FRAMES[frame], craft, 1.22)
	for i in range(2):
		var pursuit := Vector2(210.0 + i * 220.0, 330.0 - local * (25.0 + i * 7.0))
		_draw_centered(surface, DRONE, pursuit, 0.86)
	PixelFont.draw_text(surface, "VARIABLE GEOMETRY // COMBAT SHIFT", Vector2(24, 324), 1, Color("70d4c0"), 1)

func _draw_boss_engagement(surface: CanvasItem) -> void:
	var local := elapsed - 9.4
	var boss := Vector2(320.0, lerpf(-48.0, 106.0, minf(1.0, local / 1.15)))
	_draw_centered(surface, MACHINE_ARK, boss, 1.18)
	var craft := Vector2(320.0 + sin(local * 2.5) * 76.0, 294.0)
	_draw_centered(surface, VX94_FRAMES[4], craft, 1.05)
	for i in range(10):
		var player_y := 278.0 - fposmod(local * 225.0 + i * 31.0, 190.0)
		_draw_centered(surface, PLAYER_SHOT, Vector2(craft.x + (-8 if i % 2 == 0 else 8), player_y), 1.0)
	for i in range(7):
		var angle := local * 0.8 + i * TAU / 7.0
		var radius := 34.0 + fposmod(local * 42.0 + i * 19.0, 155.0)
		_draw_centered(surface, ENEMY_SHOT, boss + Vector2(cos(angle), sin(angle)) * radius, 1.0)
	PixelFont.draw_text(surface, "BLACK SKY // MACHINE ARK", Vector2(24, 324), 1, Color("e06455"), 1)

func _draw_return_card(surface: CanvasItem) -> void:
	var fade := smoothstep(0.0, 1.0, (elapsed - 13.2) / 0.42)
	surface.draw_rect(Rect2(0, 0, 640, 360), Color(0.01, 0.02, 0.035, fade * 0.90))
	surface.draw_texture_rect(WORDMARK, Rect2(70, 94, 500, 64), false, Color(1, 1, 1, fade))
	PixelFont.draw_centered(surface, "VX-94 VARIABLE STRIKE FIGHTER", 320, 174, 1, Color(0.52, 0.72, 0.82, fade), 1)
	PixelFont.draw_centered(surface, "PRESS FIRE / PRESS START", 320, 250, 1, Color(0.92, 0.78, 0.38, fade), 1)

func _draw_demo_bezel(surface: CanvasItem) -> void:
	surface.draw_rect(Rect2(8, 8, 624, 344), Color(0.34, 0.48, 0.54, 0.92), false, 1.0)
	PixelFont.draw_text(surface, "DEMONSTRATION", Vector2(18, 18), 1, Color("b7c9ce"), 1)
	PixelFont.draw_text(surface, "NO CAMPAIGN DATA", Vector2(506, 18), 1, Color("71868e"), 1)

func _draw_centered(surface: CanvasItem, texture: Texture2D, position: Vector2, scale := 1.0, modulate := Color.WHITE) -> void:
	var size := texture.get_size() * scale
	surface.draw_texture_rect(texture, Rect2(position - size * 0.5, size), false, modulate)

func _draw_vertical_loop(surface: CanvasItem, texture: Texture2D, source_y: float, modulate: Color) -> void:
	var remaining := 360.0
	var draw_y := 0.0
	# The demonstration uses the same forward-flight convention as gameplay:
	# scenery enters above the VX-94 and travels toward the bottom of frame.
	var sample_y := fposmod(-source_y, float(texture.get_height()))
	while remaining > 0.0:
		var segment := minf(remaining, float(texture.get_height()) - sample_y)
		surface.draw_texture_rect_region(texture, Rect2(0, draw_y, 640, segment), Rect2(0, sample_y, float(texture.get_width()), segment), modulate)
		remaining -= segment
		draw_y += segment
		sample_y = 0.0

func _property(target: Object, name: String, fallback: Variant) -> Variant:
	for property in target.get_property_list():
		if str(property.get("name", "")) == name:
			return target.get(name)
	return fallback

func _is_activity(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		return event.relative.length_squared() > 1.0
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) > 0.35
	return false
