extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const CampaignCinematicSurface = preload("res://scripts/campaign_cinematic_surface.gd")

const PLATES := {
	"s2_dead_refinery": preload("res://assets/runtime/cinematics/plates/s2_dead_refinery.png"),
	"s2_factory_awakens": preload("res://assets/runtime/cinematics/plates/s2_factory_awakens.png"),
	"s2_city_warning": preload("res://assets/runtime/cinematics/plates/s2_city_warning.png"),
	"s3_weather_ceiling": preload("res://assets/runtime/cinematics/plates/s3_weather_ceiling.png"),
	"s3_phase_protocol": preload("res://assets/runtime/cinematics/plates/s3_phase_protocol.png"),
	"s3_ark_reveal": preload("res://assets/runtime/cinematics/plates/s3_ark_reveal.png"),
	"s3_authorized": preload("res://assets/runtime/cinematics/plates/s3_authorized.png"),
	"end_ark_fall": preload("res://assets/runtime/cinematics/plates/end_ark_fall.png"),
	"end_reentry": preload("res://assets/runtime/cinematics/plates/end_reentry.png"),
	"end_city_silence": preload("res://assets/runtime/cinematics/plates/end_city_silence.png"),
	"end_watch": preload("res://assets/runtime/cinematics/plates/end_watch.png"),
	"end_title_sky": preload("res://assets/runtime/cinematics/plates/end_title_sky.png"),
}
const SPRITES := {
	"salvage_mech": preload("res://assets/runtime/enemies/ground_mechs/autonomous_salvage_mech_idle.png"),
	"drone_hunter": preload("res://assets/runtime/enemies/machine_air/drone_hunter_idle.png"),
	"vx94_fighter": preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png"),
	"vx94_bomber": preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png"),
	"phase_array": preload("res://assets/runtime/enemies/orbital_boss/phase_control_array_idle_v2.png"),
	"machine_ark": preload("res://assets/runtime/enemies/orbital_boss/machine_ark_idle.png"),
}
const SUBJECT_FRAMES := {
	"salvage_mech": [
		preload("res://assets/runtime/cinematics/subjects/machine_war/salvage_mech_0.png"),
		preload("res://assets/runtime/cinematics/subjects/machine_war/salvage_mech_1.png"),
		preload("res://assets/runtime/cinematics/subjects/machine_war/salvage_mech_2.png"),
		preload("res://assets/runtime/cinematics/subjects/machine_war/salvage_mech_3.png"),
	],
	"drone_hunter": [
		preload("res://assets/runtime/cinematics/subjects/machine_war/drone_hunter_0.png"),
		preload("res://assets/runtime/cinematics/subjects/machine_war/drone_hunter_1.png"),
		preload("res://assets/runtime/cinematics/subjects/machine_war/drone_hunter_2.png"),
		preload("res://assets/runtime/cinematics/subjects/machine_war/drone_hunter_3.png"),
	],
}
const SUBJECT_OVERLAYS := {
	"phase_array": [
		preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_0.png"),
		preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_1.png"),
		preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_2.png"),
		preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_3.png"),
	],
	"machine_ark": [
		preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_0.png"),
		preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_1.png"),
		preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_2.png"),
		preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_3.png"),
	],
}
const BLACK_SKY_SUBJECT_FRAMES := {
	"vx94_fighter": [preload("res://assets/runtime/cinematics/subjects/black_sky/vx94_fighter_0.png")],
	"phase_array": [
		preload("res://assets/runtime/cinematics/subjects/black_sky/phase_array_0.png"), preload("res://assets/runtime/cinematics/subjects/black_sky/phase_array_1.png"),
		preload("res://assets/runtime/cinematics/subjects/black_sky/phase_array_2.png"), preload("res://assets/runtime/cinematics/subjects/black_sky/phase_array_3.png"),
	],
	"machine_ark": [
		preload("res://assets/runtime/cinematics/subjects/black_sky/machine_ark_0.png"), preload("res://assets/runtime/cinematics/subjects/black_sky/machine_ark_1.png"),
		preload("res://assets/runtime/cinematics/subjects/black_sky/machine_ark_2.png"), preload("res://assets/runtime/cinematics/subjects/black_sky/machine_ark_3.png"),
	],
}
const ENDING_SUBJECT_FRAMES := {
	"vx94_bomber": [preload("res://assets/runtime/cinematics/subjects/ending/vx94_bomber_0.png")],
	"vx94_fighter": [preload("res://assets/runtime/cinematics/subjects/ending/vx94_fighter_0.png")],
}
const SHOT_FX_FRAMES := {
	"s2_observation": [
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_observation_0.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_observation_1.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_observation_2.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_observation_3.png"),
	],
	"s2_anticipation": [
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_anticipation_0.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_anticipation_1.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_anticipation_2.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_anticipation_3.png"),
	],
	"s2_consequence": [
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_consequence_0.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_consequence_1.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_consequence_2.png"),
		preload("res://assets/runtime/cinematics/fx/machine_war/s2_consequence_3.png"),
	],
	"s3_observation": [
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_observation_0.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_observation_1.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_observation_2.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_observation_3.png"),
	],
	"s3_anticipation": [
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_anticipation_0.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_anticipation_1.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_anticipation_2.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_anticipation_3.png"),
	],
	"s3_action": [
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_action_0.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_action_1.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_action_2.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_action_3.png"),
	],
	"s3_consequence": [
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_consequence_0.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_consequence_1.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_consequence_2.png"),
		preload("res://assets/runtime/cinematics/fx/black_sky/s3_consequence_3.png"),
	],
	"end_consequence": [
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_0.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_1.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_2.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_3.png"),
	],
	"end_action": [
		preload("res://assets/runtime/cinematics/fx/ending/end_action_0.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_action_1.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_action_2.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_action_3.png"),
	],
	"end_observation": [
		preload("res://assets/runtime/cinematics/fx/ending/end_observation_0.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_observation_1.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_observation_2.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_observation_3.png"),
	],
	"end_consequence_final": [
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_final_0.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_final_1.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_final_2.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_consequence_final_3.png"),
	],
	"end_title": [
		preload("res://assets/runtime/cinematics/fx/ending/end_title_0.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_title_1.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_title_2.png"),
		preload("res://assets/runtime/cinematics/fx/ending/end_title_3.png"),
	],
}

var _sequences: Array = []
var _launch_by_mission: Dictionary = {}
var _ending_by_mission: Dictionary = {}
var _seen: Dictionary = {}
var _active: Dictionary = {}
var _shot_index := 0
var _shot_elapsed := 0.0
var _surface: Control

func _ready() -> void:
	layer = 90
	var data = ContentCatalog.load_json("res://data/cinematics.json")
	if typeof(data) == TYPE_DICTIONARY:
		_sequences = data.get("sequences", [])
	for sequence in _sequences:
		if typeof(sequence) == TYPE_DICTIONARY:
			var target := _ending_by_mission if str(sequence.get("trigger", "launch")) == "ending" else _launch_by_mission
			target[str(sequence.get("mission_id", ""))] = sequence
	_surface = CampaignCinematicSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640,360)
	_surface.custom_minimum_size = Vector2(640,360)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_surface)
	_surface.visible = false
	var capture_sequence := _capture_sequence_id()
	if not capture_sequence.is_empty():
		call_deferred("_begin_capture_sequence", capture_sequence)

func _process(delta: float) -> void:
	if _active.is_empty():
		return
	_shot_elapsed += maxf(0.0, delta)
	var shot := _current_shot()
	if shot.is_empty():
		_finish()
		return
	if Input.is_action_just_pressed("cancel"):
		_finish()
	elif Input.is_action_just_pressed("confirm") and _shot_elapsed >= 0.45:
		_advance()
	elif _shot_elapsed >= float(shot.get("duration", 2.0)):
		_advance()
	if _surface != null:
		_surface.queue_redraw()

func intercept_launch(mission_id: String) -> bool:
	return _intercept(mission_id, _launch_by_mission, "launch")

func intercept_ending(mission_id: String) -> bool:
	return _intercept(mission_id, _ending_by_mission, "ending")

func _intercept(mission_id: String, registry: Dictionary, trigger: String) -> bool:
	if not _active.is_empty():
		return true
	var seen_key := "%s:%s" % [trigger, mission_id]
	if _seen.has(seen_key) or not registry.has(mission_id):
		return false
	_active = registry[mission_id]
	_active["seen_key"] = seen_key
	_shot_index = 0
	_shot_elapsed = 0.0
	if _surface != null:
		_surface.visible = true
		_surface.queue_redraw()
	return true

func cinematic_active() -> bool:
	return not _active.is_empty()

func _capture_sequence_id() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-cinematic="):
			return argument.trim_prefix("--capture-cinematic=").to_lower()
	return ""

func _begin_capture_sequence(sequence_id: String) -> void:
	for sequence in _sequences:
		if typeof(sequence) == TYPE_DICTIONARY and str(sequence.get("id", "")).to_lower() == sequence_id:
			_active = sequence.duplicate(true)
			_active["seen_key"] = "capture:%s" % sequence_id
			_shot_index = 0
			_shot_elapsed = 0.0
			if _surface != null:
				_surface.visible = true
				_surface.queue_redraw()
			return

func draw_cinematic(surface: CanvasItem) -> void:
	if _active.is_empty():
		return
	var shot := _current_shot()
	if shot.is_empty():
		return
	var duration := maxf(0.1, float(shot.get("duration", 2.0)))
	var ratio := clampf(_shot_elapsed / duration, 0.0, 1.0)
	var fade := minf(clampf(ratio / 0.12, 0.0, 1.0), clampf((1.0-ratio) / 0.12, 0.0, 1.0))
	surface.draw_rect(Rect2(0,0,640,360), Color("020407"))
	_draw_plate(surface, shot, ratio, fade)
	_draw_shot_fx(surface, shot, fade)
	_draw_subject(surface, shot, ratio, fade)
	if str(shot.get("id", "")) == "end_title":
		PixelFont.draw_centered(surface, "HYPERSONIC", 320, 142, 3, Color(0.86,0.91,0.92,fade), 2)
		PixelFont.draw_centered(surface, "VX-94 VARIABLE STRIKE FIGHTER", 320, 178, 1, Color(0.42,0.64,0.78,fade), 1)
	surface.draw_rect(Rect2(0,0,640,24), Color("020407"))
	surface.draw_rect(Rect2(0,296,640,64), Color(0.008,0.014,0.02,0.96))
	PixelFont.draw_text(surface, str(_active.get("title", "HYPERSONIC")).to_upper(), Vector2(18,9), 1, Color("6aa4c8"), 1)
	PixelFont.draw_centered(surface, str(shot.get("caption", "")).to_upper(), 320, 313, 1, Color(0.93,0.82,0.44,fade), 1)
	PixelFont.draw_text(surface, "%02d / %02d" % [_shot_index+1, _active.get("shots", []).size()], Vector2(568,338), 1, Color("52636d"), 1)
	PixelFont.draw_text(surface, "ENTER ADVANCE   ESC SKIP", Vector2(18,338), 1, Color("52636d"), 1)

func _draw_plate(surface: CanvasItem, shot: Dictionary, ratio: float, alpha: float) -> void:
	var plate: Texture2D = PLATES.get(str(shot.get("plate", "")), null)
	if plate == null:
		return
	var camera := str(shot.get("camera", "locked"))
	var drift := 0.0
	if camera == "pan": drift = lerpf(80.0, 164.0, ratio)
	elif camera == "track": drift = lerpf(210.0, 128.0, ratio)
	else: drift = 132.0
	var source_y := clampf(drift, 0.0, maxf(0.0, plate.get_height()-272.0))
	surface.draw_texture_rect_region(plate, Rect2(0,24,640,272), Rect2(0,source_y,640,272), Color(0.84,0.88,0.90,alpha*0.94))
	surface.draw_rect(Rect2(0,24,640,272), Color(0.01,0.025,0.04,0.13*alpha))

func _draw_subject(surface: CanvasItem, shot: Dictionary, ratio: float, alpha: float) -> void:
	var sprite_id := str(shot.get("sprite", ""))
	var texture: Texture2D = SPRITES.get(sprite_id, null)
	if texture == null:
		return
	var animation_fps := float(shot.get("animation_fps", 0.0))
	var animation_index := 0
	if animation_fps > 0.0:
		animation_index = int(floor(_shot_elapsed * animation_fps))
	var shot_id := str(shot.get("id", ""))
	if shot_id.begins_with("end_") and ENDING_SUBJECT_FRAMES.has(sprite_id):
		var frames: Array = ENDING_SUBJECT_FRAMES[sprite_id]
		texture = frames[posmod(animation_index, frames.size())]
	elif shot_id.begins_with("s3_") and BLACK_SKY_SUBJECT_FRAMES.has(sprite_id):
		var frames: Array = BLACK_SKY_SUBJECT_FRAMES[sprite_id]
		texture = frames[posmod(animation_index, frames.size())]
	elif SUBJECT_FRAMES.has(sprite_id):
		var frames: Array = SUBJECT_FRAMES[sprite_id]
		texture = frames[posmod(animation_index, frames.size())]
	var raw = shot.get("sprite_position", [320,170])
	var position := Vector2(float(raw[0]), float(raw[1])) if typeof(raw) == TYPE_ARRAY and raw.size() >= 2 else Vector2(320,170)
	var camera := str(shot.get("camera", "locked"))
	if camera == "pan": position.x += lerpf(18.0,-18.0,ratio)
	elif camera == "track": position.y += lerpf(20.0,-18.0,ratio)
	var scale := float(shot.get("sprite_scale", 1.0))
	var size := texture.get_size() * scale
	surface.draw_texture_rect(texture, Rect2((position-size*0.5).round(),size.round()), false, Color(0.86,0.91,0.92,alpha))
	if not shot_id.begins_with("s3_") and not shot_id.begins_with("end_") and SUBJECT_OVERLAYS.has(sprite_id) and animation_fps > 0.0:
		var overlays: Array = SUBJECT_OVERLAYS[sprite_id]
		var overlay: Texture2D = overlays[posmod(animation_index, overlays.size())]
		var overlay_size := overlay.get_size() * scale
		surface.draw_texture_rect(overlay, Rect2((position-overlay_size*0.5).round(),overlay_size.round()), false, Color(0.90,0.94,0.95,alpha*0.72))

func _draw_shot_fx(surface: CanvasItem, shot: Dictionary, alpha: float) -> void:
	var shot_id := str(shot.get("id", ""))
	if not SHOT_FX_FRAMES.has(shot_id):
		return
	var frames: Array = SHOT_FX_FRAMES[shot_id]
	if frames.is_empty():
		return
	var fps := maxf(0.1, float(shot.get("fx_fps", 3.0)))
	var frame_index := posmod(int(floor(_shot_elapsed * fps)), frames.size())
	surface.draw_texture(frames[frame_index], Vector2(0, 24), Color(1.0, 1.0, 1.0, alpha))

func _current_shot() -> Dictionary:
	var shots: Array = _active.get("shots", [])
	if _shot_index < 0 or _shot_index >= shots.size():
		return {}
	return shots[_shot_index] if typeof(shots[_shot_index]) == TYPE_DICTIONARY else {}

func _advance() -> void:
	_shot_index += 1
	_shot_elapsed = 0.0
	if _shot_index >= _active.get("shots", []).size():
		_finish()

func _finish() -> void:
	if not _active.is_empty():
		_seen[str(_active.get("seen_key", "launch:%s" % str(_active.get("mission_id", ""))))] = true
	_active = {}
	_shot_index = 0
	_shot_elapsed = 0.0
	if _surface != null:
		_surface.visible = false
