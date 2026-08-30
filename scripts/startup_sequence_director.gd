extends CanvasLayer

const StartupSequenceSurface = preload("res://scripts/startup_sequence_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const EVAVO_SPLASH := preload("res://assets/runtime/brand/front_door_raw_art_v1/evavo_splash_plate_v1.png")
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
	var craft_y := lerpf(392.0, 146.0, _ease_out(craft_t))
	var craft_scale := lerpf(0.38, 1.0, craft_t)
	var deploy := smoothstep(0.0, 1.0, _range_progress(3.15, 3.68))
	_draw_vx94_silhouette(surface, Vector2(320, craft_y), craft_scale, deploy)
	var flare := sin(clampf(_range_progress(3.72, 4.55), 0.0, 1.0) * PI)
	if flare > 0.0:
		surface.draw_circle(Vector2(320, craft_y+26.0*craft_scale), 5.0+flare*10.0, Color(1.0,0.48,0.18,flare*0.8))
	var title_alpha := smoothstep(0.0, 1.0, _range_progress(4.35, 5.05))
	if title_alpha > 0.0:
		var identity := get_node_or_null("/root/ProductIdentity")
		var title := str(identity.call("title_primary")) if identity != null else "HYPERSONIC"
		var subtitle := str(identity.call("title_subtitle")) if identity != null else "VX-94 VARIABLE STRIKE FIGHTER"
		PixelFont.draw_centered(surface, title, 320, 62, 5, Color(0.88,0.91,0.92,title_alpha), 2)
		PixelFont.draw_centered(surface, subtitle, 320, 96, 1, Color(0.42,0.68,0.80,title_alpha), 1)
	if elapsed >= 6.8:
		var pulse := 0.48 + 0.52 * absf(sin(elapsed * 3.2))
		PixelFont.draw_centered(surface, "PRESS FIRE / PRESS START", 320, 316, 1, Color(0.92,0.78,0.38,pulse), 1)

func _draw_cloud_field(surface: CanvasItem) -> void:
	var reveal := _range_progress(0.0, 1.2)
	surface.draw_rect(Rect2(0,0,640,360), Color(0.025,0.07,0.11,reveal))
	for i in range(14):
		var speed := 7.0 + float(i % 4) * 4.0
		var x := fposmod(float(i*79) + elapsed*speed, 760.0) - 60.0
		var y := 112.0 + float((i*47)%210)
		var radius := 24.0 + float(i%3)*12.0
		var cloud_alpha := (0.025 + float(i%4)*0.014) * reveal
		surface.draw_circle(Vector2(x,y), radius, Color(0.46,0.58,0.63,cloud_alpha))

func _draw_vx94_silhouette(surface: CanvasItem, p: Vector2, scale: float, deploy: float) -> void:
	var fighter_span := 22.0
	var bomber_span := 53.0
	var span := lerpf(fighter_span, bomber_span, deploy) * scale
	var sweep_y := lerpf(12.0, 2.0, deploy) * scale
	var body := Color("111a20")
	var edge := Color(0.35,0.48,0.54,0.72)
	var nose := p + Vector2(0,-34)*scale
	var tail := p + Vector2(0,30)*scale
	var left := p + Vector2(-span,sweep_y)
	var right := p + Vector2(span,sweep_y)
	surface.draw_colored_polygon(PackedVector2Array([nose,left,p+Vector2(-8,24)*scale,tail,p+Vector2(8,24)*scale,right]), body)
	surface.draw_polyline(PackedVector2Array([nose,left,p+Vector2(-8,24)*scale,tail,p+Vector2(8,24)*scale,right,nose]), edge, 1.0)
	surface.draw_line(p+Vector2(-4,-21)*scale, p+Vector2(-4,20)*scale, Color(0.28,0.39,0.44,0.72), 1.0)
	surface.draw_line(p+Vector2(4,-21)*scale, p+Vector2(4,20)*scale, Color(0.28,0.39,0.44,0.72), 1.0)

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
