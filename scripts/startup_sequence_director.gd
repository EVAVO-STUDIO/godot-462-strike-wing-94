extends CanvasLayer

const StartupSequenceSurface = preload("res://scripts/startup_sequence_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const EVAVO_SPLASH := preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_splash_plate_v1.png")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v2.png")
const TITLE_SKY := preload("res://assets/runtime/environments/high_atmosphere/stratospheric_cloud_deck_loop_v1.png")
const TITLE_CLOUDS := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_b.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_b.png"),
]
const VX94_FIGHTER := preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png")
const VX94_BOMBER := preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png")
const VX94_TRANSFORM_FRAMES := [
	VX94_FIGHTER,
	preload("res://assets/runtime/craft/vx94/vx94_transform_01.png"),
	preload("res://assets/runtime/craft/vx94/vx94_transform_02.png"),
	preload("res://assets/runtime/craft/vx94/vx94_transform_03.png"),
	VX94_BOMBER,
]
const EVAVO_SPARKLE_FRAMES := [
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_00.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_01.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_02.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_03.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_04.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_05.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_06.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_07.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_08.png"),
	preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_corner_sparkle_09.png")
]

enum Stage { EVAVO, BLACK_PAUSE, HYPERSONIC, COMPLETE }

const EVAVO_READABLE_SECONDS := 1.0
const EVAVO_TOTAL_SECONDS := 2.28
const BLACK_PAUSE_SECONDS := 0.42
const TITLE_TOTAL_SECONDS := 9.2

var stage := Stage.EVAVO
var elapsed := 0.0
var _surface: Control

func _ready() -> void:
	layer = 100
	if DisplayServer.get_name() == "headless":
		# Rule tests load project autoloads but do not need GPU presentation.
		# Avoid constructing texture-backed surfaces during immediate headless
		# shutdown, which can destabilize some Windows Godot builds.
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		return
	_surface = StartupSequenceSurface.new()
	_surface.director = self
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_surface)
	set_process_input(true)
	set_process_unhandled_input(true)
	if _apply_capture_override(OS.get_cmdline_user_args()):
		return
	if "--capture-gameplay" in OS.get_cmdline_user_args():
		call_deferred("_complete")

func _apply_capture_override(arguments: PackedStringArray) -> bool:
	for argument in arguments:
		if not argument.begins_with("--capture-startup="):
			continue
		var fixture := argument.trim_prefix("--capture-startup=").to_lower()
		var fixtures := {
			"evavo_ident": {"stage":Stage.EVAVO, "elapsed":1.12},
			"vx94_transform": {"stage":Stage.HYPERSONIC, "elapsed":3.46},
			"title_prompt": {"stage":Stage.HYPERSONIC, "elapsed":7.24},
		}
		if not fixtures.has(fixture):
			return false
		var state: Dictionary = fixtures[fixture]
		stage = int(state.get("stage", Stage.EVAVO))
		elapsed = float(state.get("elapsed", 0.0))
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		_surface.queue_redraw()
		return true
	return false

func _process(delta: float) -> void:
	if stage == Stage.COMPLETE:
		return
	elapsed += delta
	if stage == Stage.EVAVO and elapsed >= EVAVO_TOTAL_SECONDS:
		_set_stage(Stage.BLACK_PAUSE)
	elif stage == Stage.BLACK_PAUSE and elapsed >= BLACK_PAUSE_SECONDS:
		_set_stage(Stage.HYPERSONIC)
	elif stage == Stage.HYPERSONIC and elapsed >= TITLE_TOTAL_SECONDS:
		_complete()
	_surface.queue_redraw()

func _input(event: InputEvent) -> void:
	if stage == Stage.COMPLETE or not _is_commit_input(event):
		return
	get_viewport().set_input_as_handled()
	if stage == Stage.EVAVO and elapsed >= EVAVO_READABLE_SECONDS:
		_set_stage(Stage.BLACK_PAUSE)
	elif stage == Stage.HYPERSONIC and elapsed >= 1.5:
		_complete()

func _unhandled_input(event: InputEvent) -> void:
	_input(event)

func _set_stage(next_stage: int) -> void:
	stage = next_stage
	elapsed = 0.0

func _complete() -> void:
	stage = Stage.COMPLETE
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	if _surface != null:
		_surface.queue_free()

func is_complete() -> bool:
	return stage == Stage.COMPLETE

func draw_startup_sequence(surface: CanvasItem) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), Color("03060a"))
	match stage:
		Stage.EVAVO:
			_draw_evavo(surface)
		Stage.BLACK_PAUSE:
			pass
		Stage.HYPERSONIC:
			_draw_hypersonic(surface)

func _draw_evavo(surface: CanvasItem) -> void:
	# Timing, plate geometry and sparkle placement are preserved from the
	# approved Battle Chess publisher-ident implementation on main.
	var wake := _range_progress(0.0, 0.34)
	if wake < 1.0:
		var half_height := maxf(1.0, 180.0 * wake)
		surface.draw_rect(Rect2(0, 180.0-half_height, 640, half_height*2.0), Color("0d0a18"))
		surface.draw_line(Vector2(0,180), Vector2(640,180), Color(0.94,0.84,0.60,1.0-wake), 2.0)
	var alpha := _range_progress(0.38, 1.18) * (1.0 - _range_progress(1.62, 2.04))
	if alpha > 0.0:
		surface.draw_texture_rect(EVAVO_SPLASH, Rect2(0,0,640,360), false, Color(1,1,1,alpha))
	var sparkle_index := int(floor((elapsed - 0.62) * 12.0))
	if sparkle_index >= 0 and sparkle_index < EVAVO_SPARKLE_FRAMES.size():
		surface.draw_texture_rect(EVAVO_SPARKLE_FRAMES[sparkle_index], Rect2(568,66,64,64), false)

func _draw_hypersonic(surface: CanvasItem) -> void:
	_draw_cloud_field(surface)
	var craft_t := _range_progress(0.65, 4.25)
	var craft_y := lerpf(392.0, 190.0, _ease_out(craft_t))
	var craft_scale := lerpf(0.38, 1.0, craft_t)
	var deploy := smoothstep(0.0, 1.0, _range_progress(3.15, 3.68))
	_draw_vx94_forms(surface, Vector2(320, craft_y), craft_scale, deploy)
	var flare := sin(clampf(_range_progress(3.72, 4.55), 0.0, 1.0) * PI)
	if flare > 0.0:
		var plume := PersistentEffectArtLibrary.frame_for_ratio("afterburner", flare)
		var plume_size := Vector2(30, 38) * craft_scale
		surface.draw_texture_rect(plume, Rect2(Vector2(320, craft_y+26.0*craft_scale) - Vector2(plume_size.x*0.5, 0), plume_size), false, Color(1,1,1,flare))
	var title_alpha := smoothstep(0.0, 1.0, _range_progress(4.35, 5.05))
	if title_alpha > 0.0:
		var identity := get_node_or_null("/root/ProductIdentity")
		var subtitle := str(identity.call("title_subtitle")) if identity != null else "VX-94 VARIABLE STRIKE FIGHTER"
		surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(70, 42, 500, 64), false, Color(1,1,1,title_alpha))
		PixelFont.draw_centered(surface, subtitle, 320, 116, 1, Color(0.52,0.72,0.82,title_alpha), 1)
	if elapsed >= 6.8:
		var pulse := 0.48 + 0.52 * absf(sin(elapsed * 3.2))
		PixelFont.draw_centered(surface, "PRESS FIRE / PRESS START", 320, 316, 1, Color(0.92,0.78,0.38,pulse), 1)

func _draw_cloud_field(surface: CanvasItem) -> void:
	var reveal := _range_progress(0.0, 1.2)
	_draw_vertical_loop(surface, TITLE_SKY, elapsed * 9.0, Rect2(0,0,640,360), Color(0.30,0.43,0.52,reveal * 0.78))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.035,0.055,0.36 * reveal))
	_draw_title_cloud(surface, TITLE_CLOUDS[0], Vector2(-74.0 + fposmod(elapsed * 13.0, 820.0), 226), 1.55, 0.34 * reveal)
	_draw_title_cloud(surface, TITLE_CLOUDS[1], Vector2(470.0 - fposmod(elapsed * 8.0, 880.0), 282), 1.30, 0.28 * reveal)
	_draw_title_cloud(surface, TITLE_CLOUDS[2], Vector2(162.0 + fposmod(elapsed * 7.0, 760.0), 154), 1.08, 0.25 * reveal)
	_draw_title_cloud(surface, TITLE_CLOUDS[3], Vector2(518.0 - fposmod(elapsed * 11.0, 900.0), 336), 1.22, 0.30 * reveal)

func _draw_title_cloud(surface: CanvasItem, texture: Texture2D, position: Vector2, scale: float, alpha: float) -> void:
	var size := texture.get_size() * scale
	surface.draw_texture_rect(texture, Rect2(position - size * 0.5, size), false, Color(0.62,0.74,0.80,alpha))

func _draw_vertical_loop(surface: CanvasItem, texture: Texture2D, source_y: float, destination: Rect2, modulate: Color) -> void:
	var remaining := destination.size.y
	var draw_y := destination.position.y
	# Positive flight speed must carry the cloud deck down past the aircraft,
	# matching the gameplay world's forward-scroll convention.
	var sample_y := fposmod(-source_y, float(texture.get_height()))
	while remaining > 0.0:
		var segment := minf(remaining, float(texture.get_height()) - sample_y)
		surface.draw_texture_rect_region(texture, Rect2(destination.position.x, draw_y, destination.size.x, segment), Rect2(0, sample_y, float(texture.get_width()), segment), modulate)
		remaining -= segment
		draw_y += segment
		sample_y = 0.0

func _draw_vx94_forms(surface: CanvasItem, p: Vector2, scale: float, deploy: float) -> void:
	var size := Vector2(64, 72) * scale
	var destination := Rect2(p - size * 0.5, size)
	var frame_index := clampi(int(round(deploy * float(VX94_TRANSFORM_FRAMES.size() - 1))), 0, VX94_TRANSFORM_FRAMES.size() - 1)
	surface.draw_texture_rect(VX94_TRANSFORM_FRAMES[frame_index], destination, false)

func _range_progress(start: float, finish: float) -> float:
	return clampf((elapsed-start)/maxf(0.001,finish-start),0.0,1.0)

func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0-clampf(value,0.0,1.0), 3.0)

func _is_commit_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	return false
