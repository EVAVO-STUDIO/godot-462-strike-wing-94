extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const PauseSurface = preload("res://scripts/pause_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v1.png")
const VX94_FIGHTER := preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_screen_9slice.png")
const OPERATIONS_BUTTON := preload("res://assets/runtime/ui/menu/operations_button_9slice.png")
const CONTROL_ROW := preload("res://assets/runtime/ui/menu/mission_intel/row_frame.png")
const CONTROL_ICONS := [
	preload("res://assets/runtime/ui/menu/mission_intel/icon_lanes.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_threat.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_routes.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_envelope.png"),
	preload("res://assets/runtime/ui/menu/mission_intel/icon_allied.png"),
]
const CONTROL_LINES := [
	"MOVE        ARROWS / WASD / LEFT STICK",
	"WEAPONS     SPACE PRIMARY   X SECONDARY",
	"GEOMETRY    Q SWEEP   SHIFT AFTERBURNER",
	"ALTITUDE    PGUP CLIMB   PGDN DIVE",
	"SUPPORT     C TACTICAL   F CALL   B CYCLE",
]

const TEXT := Color("d9e0e5")
const MUTED := Color("7f909b")
const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a")
const GREEN := Color("67c3a5")
const RED := Color("dc6655")

var _paused := false
var _surface: Control

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_surface = PauseSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	_surface.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_surface)
	_surface.visible = false

func _process(_delta: float) -> void:
	if not _paused:
		return
	if not get_tree().paused:
		_close_overlay()
		return
	if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("confirm"):
		resume_game()
	elif Input.is_action_just_pressed("restart"):
		restart_sortie()
	if _surface != null:
		_surface.queue_redraw()

func pause_game() -> bool:
	var scene := get_tree().current_scene
	if scene == null or not _supports_playing_scene(scene) or int(scene.get("phase")) != 1:
		return false
	var cinematic := get_node_or_null("/root/CampaignCinematicDirector")
	if cinematic != null and cinematic.has_method("cinematic_active") and bool(cinematic.call("cinematic_active")):
		return false
	_paused = true
	get_tree().paused = true
	if _surface != null:
		_surface.visible = true
		_surface.queue_redraw()
	return true

func resume_game() -> void:
	get_tree().paused = false
	_close_overlay()

func restart_sortie() -> void:
	var scene := get_tree().current_scene
	get_tree().paused = false
	_close_overlay()
	if scene != null and scene.has_method("_start_mission"):
		scene.call("_start_mission")

func pause_active() -> bool:
	return _paused

func draw_pause(surface: CanvasItem) -> void:
	if not _paused:
		return
	surface.draw_rect(Rect2(0, 0, 640, 360), Color(0.005, 0.01, 0.015, 0.78))
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_SCREEN, Rect2(54, 32, 532, 296), 8)
	surface.draw_texture_rect(VX94_FIGHTER, Rect2(76, 48, 72, 80), false, Color(0.82, 0.90, 0.94, 1.0))
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(188, 49, 264, 34), false)
	PixelFont.draw_centered(surface, "VX-94 FLIGHT CONTROL // TACTICAL HOLD", 344, 92, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "SIMULATION PAUSED", 344, 105, 1, GOLD, 1)
	for index in range(CONTROL_LINES.size()):
		var row_y := 124.0 + float(index * 23)
		surface.draw_texture(CONTROL_ROW, Vector2(80, row_y))
		surface.draw_texture(CONTROL_ICONS[index], Vector2(86, row_y + 2.0))
		PixelFont.draw_text(surface, CONTROL_LINES[index], Vector2(112, row_y + 7.0), 1, TEXT if index < 3 else GREEN, 1)
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_BUTTON, Rect2(80, 247, 480, 28), 6)
	PixelFont.draw_text(surface, ">>", Vector2(94, 257), 1, RED, 1)
	PixelFont.draw_centered(surface, "ENTER / ESC RESUME FLIGHT", 320, 257, 1, GOLD, 1)
	PixelFont.draw_centered(surface, "R RESTART SORTIE", 320, 290, 1, MUTED, 1)
	PixelFont.draw_centered(surface, "MISSION TIME AND ENCOUNTER STATE HELD", 320, 307, 1, BLUE, 1)

func _close_overlay() -> void:
	_paused = false
	if _surface != null:
		_surface.visible = false

func _supports_playing_scene(scene: Object) -> bool:
	for property in scene.get_property_list():
		if str(property.get("name", "")) == "phase":
			return true
	return false
