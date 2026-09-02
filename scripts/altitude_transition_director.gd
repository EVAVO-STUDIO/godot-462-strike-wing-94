extends CanvasLayer

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const AltitudeTransitionSurface = preload("res://scripts/altitude_transition_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const LANE_PANEL := preload("res://assets/runtime/ui/hud/altitude_transition/lane_panel.png")
const CLOUD_SHADOW := preload("res://assets/runtime/ui/hud/altitude_transition/cloud_shadow.png")
const CLIMB_LEFT := preload("res://assets/runtime/ui/hud/altitude_transition/climb_left.png")
const CLIMB_RIGHT := preload("res://assets/runtime/ui/hud/altitude_transition/climb_right.png")
const DIVE_LEFT := preload("res://assets/runtime/ui/hud/altitude_transition/dive_left.png")
const DIVE_RIGHT := preload("res://assets/runtime/ui/hud/altitude_transition/dive_right.png")
const TRANSITION_CLOUDS := [
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_mid_broken_b.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_a.png"),
	preload("res://assets/runtime/environments/clouds/cloud_bank_high_mass_b.png"),
]
const LOWER_LEFT_KEEP_OUT := Rect2(0.0, 252.0, 244.0, 108.0)
const CHOICE_REVEAL_SECONDS := 4.0
const CHOICE_REMINDER_SECONDS := 2.4

var _surface: Control
var _choice_was_available := false
var _choice_reveal_timer := 0.0

func _ready() -> void:
	layer = 14
	_surface = AltitudeTransitionSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_update_choice_visibility(delta)
	if _surface != null:
		_surface.queue_redraw()

func _update_choice_visibility(delta: float) -> void:
	var scene := get_tree().current_scene
	var craft := get_node_or_null("/root/CraftFormDirector")
	var available := (
		scene != null
		and craft != null
		and _has_property(scene, "phase")
		and int(scene.get("phase")) == 1
		and _has_property(scene, "mission_time")
		and craft.has_method("altitude_choice_available")
		and bool(craft.call("altitude_choice_available", float(scene.get("mission_time"))))
	)
	if available and not _choice_was_available:
		_choice_reveal_timer = CHOICE_REVEAL_SECONDS
	elif available and (Input.is_action_just_pressed("altitude_up") or Input.is_action_just_pressed("altitude_down")):
		_choice_reveal_timer = CHOICE_REMINDER_SECONDS
	elif not available:
		_choice_reveal_timer = 0.0
	_choice_was_available = available
	_choice_reveal_timer = maxf(0.0, _choice_reveal_timer - delta)

func choice_prompt_visible() -> bool:
	return _choice_reveal_timer > 0.0

func occupies_status_lane() -> bool:
	var craft := get_node_or_null("/root/CraftFormDirector")
	var transition_active := craft != null and craft.has_method("altitude_transition_active") and bool(craft.call("altitude_transition_active"))
	return choice_prompt_visible() or transition_active

func _draw_altitude_transition_surface(surface: CanvasItem) -> void:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft == null:
		return
	if craft.has_method("altitude_transition_active") and bool(craft.call("altitude_transition_active")):
		var ratio := clampf(float(craft.call("altitude_transition_ratio")), 0.0, 1.0)
		var direction := int(craft.call("altitude_transition_direction"))
		var from_band := str(craft.call("altitude_transition_from"))
		var to_band := str(craft.call("altitude_transition_to"))
		var eased := smoothstep(0.0, 1.0, ratio)
		_draw_cloud_sweep(surface, eased, direction)
		_draw_speed_brackets(surface, eased, direction)
		var label := "CLIMB" if direction > 0 else "DIVE"
		PixelFont.draw_text(surface, "%s  %s > %s" % [label, _code(from_band), _code(to_band)], Vector2(272, 68), 1, Color(0.78,0.9,0.94,0.94))
		return
	_draw_choice_prompt(surface, craft)

func _draw_choice_prompt(surface: CanvasItem, craft: Node) -> void:
	if not choice_prompt_visible():
		return
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1 or not _has_property(scene, "mission_time"):
		return
	if not craft.has_method("altitude_choice_available") or not bool(craft.call("altitude_choice_available", float(scene.get("mission_time")))):
		return
	var bands: Array = craft.call("altitude_choice_bands", float(scene.get("mission_time")))
	var current := str(craft.call("current_altitude")) if craft.has_method("current_altitude") else AltitudeRules.MID
	var higher := AltitudeRules.adjacent_band(current, 1)
	var lower := AltitudeRules.adjacent_band(current, -1)
	var parts: Array[String] = []
	if higher != current and higher in bands:
		parts.append("CLIMB %s" % _code(higher))
	if lower != current and lower in bands:
		parts.append("DIVE %s" % _code(lower))
	if parts.is_empty():
		return
	var text := "ALT SELECT  %s" % "  ".join(parts)
	var width := float(text.length() * 4 + 14)
	var x := 16.0 if not _player_blocks_lower_left(scene) else 640.0 - width - 16.0
	UiSpriteRenderer.draw_nine_slice(surface, LANE_PANEL, Rect2(x, 294, width, 18), 6)
	PixelFont.draw_text(surface, text, Vector2(x+7,300), 1, Color(0.76,0.88,0.92,0.92))

func _player_blocks_lower_left(scene: Object) -> bool:
	if scene == null or not _has_property(scene, "player_position"):
		return false
	return LOWER_LEFT_KEEP_OUT.has_point(Vector2(scene.get("player_position")))

func _draw_cloud_sweep(surface: CanvasItem, ratio: float, direction: int) -> void:
	var travel := 160.0 * ratio
	var sign_dir := -1.0 if direction > 0 else 1.0
	for i in range(7):
		var base_y := 86.0 + float(i) * 42.0
		var y := fposmod(base_y + sign_dir * travel, 330.0) + 36.0
		var x := 72.0 + float((i * 83) % 430)
		var texture: Texture2D = TRANSITION_CLOUDS[i % TRANSITION_CLOUDS.size()]
		var scale := 0.58 + float(i % 3) * 0.10
		var size := Vector2(texture.get_size()) * scale
		surface.draw_texture_rect(texture, Rect2(Vector2(x,y) - size * 0.5, size), false, Color(0.78,0.84,0.86,0.18))
		var shadow_width := size.x * 0.82
		surface.draw_texture_rect(CLOUD_SHADOW, Rect2(Vector2(x - shadow_width * 0.5, y + size.y * 0.27), Vector2(shadow_width, 8)), false, Color(1,1,1,0.44))

func _draw_speed_brackets(surface: CanvasItem, ratio: float, direction: int) -> void:
	var alpha := sin(ratio * PI) * 0.55
	if alpha <= 0.01:
		return
	var left := CLIMB_LEFT if direction > 0 else DIVE_LEFT
	var right := CLIMB_RIGHT if direction > 0 else DIVE_RIGHT
	var tint := Color(1,1,1,alpha / 0.55)
	surface.draw_texture(left, Vector2(76, 94), tint)
	surface.draw_texture(right, Vector2(532, 94), tint)

func _code(band: String) -> String:
	match AltitudeRules.sanitize(band):
		AltitudeRules.LOW: return "LOW"
		AltitudeRules.MID: return "MID"
		AltitudeRules.HIGH: return "HIGH"
		AltitudeRules.ORBITAL: return "ORB"
	return "MID"

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)
