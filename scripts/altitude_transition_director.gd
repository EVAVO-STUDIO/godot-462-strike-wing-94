extends CanvasLayer

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const AltitudeTransitionSurface = preload("res://scripts/altitude_transition_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const CLOUD_SHADOW := preload("res://assets/runtime/ui/hud/altitude_transition/cloud_shadow.png")
const ATMOSPHERIC_VEIL := preload("res://assets/runtime/ui/hud/altitude_transition/atmospheric_veil.png")
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
const CHOICE_REVEAL_SECONDS := 2.4
const CHOICE_REMINDER_SECONDS := 1.4
const FLIGHT_VIEW := Rect2(8, 34, 624, 304)

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
		and bool(craft.call("altitude_choice_available", _route_progress(scene)))
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
	return transition_active

func compact_choice_label() -> String:
	if not choice_prompt_visible():
		return ""
	var scene := get_tree().current_scene
	var craft := get_node_or_null("/root/CraftFormDirector")
	if scene == null or craft == null or not _has_property(scene, "phase") or int(scene.get("phase")) != 1 or not _has_property(scene, "mission_time"):
		return ""
	var route_progress := _route_progress(scene)
	if not craft.has_method("altitude_choice_available") or not bool(craft.call("altitude_choice_available", route_progress)):
		return ""
	var bands: Array = craft.call("altitude_choice_bands", route_progress)
	var current := str(craft.call("current_altitude")) if craft.has_method("current_altitude") else AltitudeRules.MID
	var higher := AltitudeRules.adjacent_band(current, 1)
	var lower := AltitudeRules.adjacent_band(current, -1)
	var higher_available := higher != current and higher in bands
	var lower_available := lower != current and lower in bands
	if higher_available and lower_available:
		return "%s<%s>%s" % [_code(lower), _code(current), _code(higher)]
	if higher_available:
		return "%s>%s" % [_code(current), _code(higher)]
	if lower_available:
		return "%s<%s" % [_code(lower), _code(current)]
	return ""

func _route_progress(scene: Object) -> float:
	if scene.has_method("route_progress_seconds"):
		return maxf(0.0, float(scene.call("route_progress_seconds")))
	return maxf(0.0, float(scene.get("mission_time")))

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
		_draw_layer_exposure(surface, eased, direction, from_band, to_band)
		_draw_cloud_sweep(surface, eased, direction)
		_draw_depth_rush(surface, eased, direction)
		_draw_speed_brackets(surface, eased, direction)
		return

func _draw_cloud_sweep(surface: CanvasItem, ratio: float, direction: int) -> void:
	var pulse := sin(ratio * PI)
	# Brief extinction makes the lane change read as passage through a physical
	# cloud boundary. It peaks at mid-transition and clears before control returns.
	var veil_tint := Color(0.72,0.82,0.88,0.34*pulse) if direction > 0 else Color(0.54,0.66,0.72,0.28*pulse)
	surface.draw_texture(ATMOSPHERIC_VEIL, Vector2(8,34), veil_tint)
	# A few independently timed masses follow the main ceiling. Their unequal
	# spacing and short lifetimes prevent the transition reading as tiled weather.
	var travel := smoothstep(0.0, 1.0, ratio)
	var cloud_centers := [
		Vector2(92.0, 0.18),
		Vector2(476.0, 0.31),
		Vector2(248.0, 0.58),
		Vector2(574.0, 0.76),
	]
	for i in range(cloud_centers.size()):
		var authored: Vector2 = cloud_centers[i]
		var local_phase := clampf(1.0-absf(travel-authored.y)/0.30, 0.0, 1.0)
		if local_phase <= 0.01:
			continue
		var direction_sign := -1.0 if direction > 0 else 1.0
		var crossing := (travel-authored.y)*430.0*direction_sign
		var y := 186.0+crossing+float((i%2)*22-11)
		var texture: Texture2D = TRANSITION_CLOUDS[(i+1) % TRANSITION_CLOUDS.size()]
		var depth := 0.35+float((i*7)%4)/5.0
		var scale := 0.52+depth*0.22+local_phase*0.20
		var size := Vector2(texture.get_size())*scale
		var tint := Color(0.78,0.84,0.86,(0.12+depth*0.09+local_phase*0.19)*pulse)
		surface.draw_texture_rect(texture, Rect2(Vector2(authored.x,y)-size*0.5,size), false, tint)
		var shadow_width := size.x*0.48
		surface.draw_texture_rect(CLOUD_SHADOW, Rect2(Vector2(authored.x-shadow_width*0.5,y+size.y*0.25),Vector2(shadow_width,5)), false, Color(1,1,1,local_phase*pulse*0.16))

func _draw_layer_exposure(surface: CanvasItem, ratio: float, direction: int, from_band: String, to_band: String) -> void:
	var pulse := sin(ratio * PI)
	var source := _band_tint(from_band)
	var destination := _band_tint(to_band)
	var atmosphere := source.lerp(destination, ratio)
	atmosphere.a = 0.05 + pulse * 0.09
	surface.draw_texture(ATMOSPHERIC_VEIL, FLIGHT_VIEW.position, atmosphere)
	# The cloud ceiling crosses the complete flight window as the aircraft passes
	# through it. Overlapping silhouettes keep the boundary physical rather than
	# reading as a rectangular HUD wipe over the terrain.
	var boundary_y := lerpf(48.0, 344.0, ratio) if direction > 0 else lerpf(344.0, 48.0, ratio)
	for i in range(5):
		var texture: Texture2D = TRANSITION_CLOUDS[(i + (1 if direction > 0 else 2)) % TRANSITION_CLOUDS.size()]
		var size := Vector2(texture.get_size()) * Vector2(1.15, 0.58)
		var center := Vector2(18.0 + float(i) * 151.0, boundary_y + float((i % 3) - 1) * 7.0)
		surface.draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, Color(0.80, 0.88, 0.91, 0.10 + pulse * 0.30))
		# Each cloud mass carries its own soft underside. A single 624-pixel shadow
		# line exposed the layer swap and made the climb look like a screen wipe.
		var shadow_size := Vector2(size.x * 0.58, 5.0)
		surface.draw_texture_rect(CLOUD_SHADOW, Rect2(center + Vector2(-shadow_size.x * 0.5, size.y * 0.18), shadow_size), false, Color(0.88, 0.95, 0.97, pulse * 0.13))

func _draw_depth_rush(surface: CanvasItem, ratio: float, direction: int) -> void:
	var pulse := sin(ratio * PI)
	if pulse <= 0.02:
		return
	var tint := Color(0.80, 0.90, 0.94, pulse * 0.30)
	var left_texture := CLIMB_LEFT if direction > 0 else DIVE_LEFT
	var right_texture := CLIMB_RIGHT if direction > 0 else DIVE_RIGHT
	for i in range(6):
		var texture: Texture2D = left_texture if i % 2 == 0 else right_texture
		var x := 34.0 + float(i) * 113.0
		var phase := fposmod(ratio * 328.0 + float((i * 61) % 173), 304.0)
		var y := 34.0 + (phase if direction > 0 else 304.0 - phase) - 108.0
		surface.draw_texture(texture, Vector2(x, y), tint)
		surface.draw_texture(texture, Vector2(x, y + (304.0 if direction > 0 else -304.0)), tint)

func _band_tint(band: String) -> Color:
	match AltitudeRules.sanitize(band):
		AltitudeRules.LOW: return Color(0.28, 0.22, 0.15, 1.0)
		AltitudeRules.MID: return Color(0.18, 0.28, 0.34, 1.0)
		AltitudeRules.HIGH: return Color(0.20, 0.35, 0.48, 1.0)
		AltitudeRules.ORBITAL: return Color(0.035, 0.075, 0.15, 1.0)
	return Color(0.18, 0.28, 0.34, 1.0)

func _draw_speed_brackets(surface: CanvasItem, ratio: float, direction: int) -> void:
	var alpha := sin(ratio * PI) * 0.38
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
