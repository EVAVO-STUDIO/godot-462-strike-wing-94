extends CanvasLayer

const StartupSequenceSurface = preload("res://scripts/startup_sequence_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const EVAVO_SPLASH := preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_splash_plate_v1.png")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v1.png")
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
	if "--capture-gameplay" in OS.get_cmdline_user_args():
		call_deferred("_complete")

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
		surface.draw_circle(Vector2(320, craft_y+26.0*craft_scale), 5.0+flare*10.0, Color(1.0,0.48,0.18,flare*0.8))
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
	surface.draw_rect(Rect2(0,0,640,360), Color(0.025,0.07,0.11,reveal))
	_draw_cloud_wisp(surface, -90.0 + fposmod(elapsed * 5.0, 820.0), 178.0, 1.35, Color(0.20,0.31,0.38,0.17 * reveal))
	_draw_cloud_wisp(surface, 310.0 + fposmod(elapsed * 3.0, 880.0), 268.0, 1.7, Color(0.15,0.25,0.32,0.13 * reveal))
	_draw_cloud_wisp(surface, 78.0 - fposmod(elapsed * 7.0, 760.0), 318.0, 0.9, Color(0.31,0.41,0.45,0.10 * reveal))
	_draw_cloud_wisp(surface, 510.0 - fposmod(elapsed * 4.0, 900.0), 128.0, 0.72, Color(0.26,0.36,0.41,0.09 * reveal))

func _draw_cloud_wisp(surface: CanvasItem, x: float, y: float, scale: float, color: Color) -> void:
	var points := PackedVector2Array([
		Vector2(-118, 8), Vector2(-91, -3), Vector2(-63, -7), Vector2(-38, -17),
		Vector2(-10, -13), Vector2(18, -24), Vector2(49, -15), Vector2(74, -18),
		Vector2(101, -5), Vector2(126, 2), Vector2(91, 10), Vector2(54, 14),
		Vector2(17, 11), Vector2(-25, 18), Vector2(-66, 14), Vector2(-99, 16)
	])
	for index in range(points.size()):
		points[index] = Vector2(x, y) + points[index] * scale
	surface.draw_colored_polygon(points, color)

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
