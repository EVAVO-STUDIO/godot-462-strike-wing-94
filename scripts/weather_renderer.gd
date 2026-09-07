extends Node
const WeatherRules = preload("res://scripts/weather_rules.gd")
const ContentCatalog = preload("res://scripts/content_catalog.gd")
const RAIN_AUDIO = preload("res://assets/runtime/audio/weather/rain_loop.wav")
const STORM_AUDIO = preload("res://assets/runtime/audio/weather/storm_loop.wav")
const SNOW_AUDIO = preload("res://assets/runtime/audio/weather/snow_wind_loop.wav")
const RAIN_VISIBILITY := {"drizzle":1.18, "rain":1.34, "storm":1.48}
const RAIN_COLOUR := Color(0.64, 0.72, 0.76, 1.0)
const SNOW_COLOUR := Color(0.88, 0.92, 0.94, 1.0)

class WeatherSurface extends Control:
	var renderer: Node
	var near_band := false
	func _draw() -> void: renderer.draw_weather(self, near_band)

var _placement: Dictionary = {}
var _rain: Dictionary = {}
var _snow: Array = []
var _surfaces: Array[Control] = []
var _profile := "clear"
var _weight := 0.0
var _time := 0.0
var _travel := 0.0
var _reduced := false
var _rain_player: AudioStreamPlayer
var _storm_player: AudioStreamPlayer
var _snow_player: AudioStreamPlayer
var _rain_gain := 0.0
var _storm_gain := 0.0
var _snow_gain := 0.0

func _ready() -> void:
	process_priority = 50
	_placement = ContentCatalog.load_json("res://data/weather/placement.json")
	for id in ["drizzle", "rain", "storm"]:
		_rain[id] = ContentCatalog.load_json("res://data/weather/%s_plan.json" % id).get("particles", [])
	_snow = ContentCatalog.load_json("res://data/weather/snow_states.json").get("frames", [])
	_rain_player = _make_loop_player(RAIN_AUDIO)
	_storm_player = _make_loop_player(STORM_AUDIO)
	_snow_player = _make_loop_player(SNOW_AUDIO)
	for index in 2:
		var canvas := CanvasLayer.new()
		canvas.layer = 8 if index == 0 else 18
		add_child(canvas)
		var surface := WeatherSurface.new()
		surface.renderer = self
		surface.near_band = index == 1
		var clip := Control.new()
		clip.position = Vector2(0,34)
		clip.size = Vector2(640,304)
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surface.size = Vector2(640,304)
		surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(clip)
		clip.add_child(surface)
		_surfaces.append(surface)

func profile_for(mission: Dictionary) -> String:
	var id := str(mission.get("id", ""))
	if id in _placement.get("orbital_exclusions", []) or str(mission.get("environment", "")) == "orbital":
		return "clear"
	return str(_placement.get("missions", {}).get(id, "clear"))

func _process(_delta: float) -> void:
	_weight = 0.0
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_active_mission") and int(scene.get("phase")) == 1:
		_profile = profile_for(scene.call("_active_mission"))
		_weight = WeatherRules.altitude_weight(get_parent().call("_altitude_state"), _placement.get("altitude_weights", WeatherRules.ALTITUDE_WEIGHTS))
		_time = float(scene.get("mission_time"))
		_travel = float(get_parent().call("_world_distance", scene))
		var settings := get_node_or_null("/root/SettingsDirector")
		_reduced = settings != null and settings.has_method("reduced_flashes") and bool(settings.call("reduced_flashes"))
	_update_weather_audio(_delta)
	for surface in _surfaces: surface.queue_redraw()

func _make_loop_player(source: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := source.duplicate(true) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream
	player.volume_db = -80.0
	add_child(player)
	player.play()
	return player

func _update_weather_audio(delta: float) -> void:
	var craft := get_node_or_null("/root/CraftFormDirector")
	var speed := float(craft.call("world_speed_multiplier")) if craft != null and craft.has_method("world_speed_multiplier") else 1.0
	var mix := WeatherRules.audio_mix(_profile, _weight, speed)
	_rain_gain = move_toward(_rain_gain, float(mix.rain), maxf(0.0,delta) * 0.16)
	_storm_gain = move_toward(_storm_gain, float(mix.storm), maxf(0.0,delta) * 0.16)
	_snow_gain = move_toward(_snow_gain, float(mix.snow), maxf(0.0,delta) * 0.16)
	var settings := get_node_or_null("/root/SettingsDirector")
	var user_gain := 0.60
	if settings != null and settings.has_method("master_level") and settings.has_method("sfx_level"):
		user_gain = float(settings.call("master_level")) * float(settings.call("sfx_level")) / 10000.0
	_apply_weather_player(_rain_player, _rain_gain * user_gain, float(mix.pitch))
	_apply_weather_player(_storm_player, _storm_gain * user_gain, float(mix.pitch))
	_apply_weather_player(_snow_player, _snow_gain * user_gain, float(mix.pitch))

func _apply_weather_player(player: AudioStreamPlayer, gain: float, pitch: float) -> void:
	if player == null: return
	player.volume_db = -80.0 if gain <= 0.0001 else linear_to_db(gain)
	player.pitch_scale = pitch

func draw_weather(surface: CanvasItem, near_band: bool) -> void:
	if _weight <= 0.001 or _profile == "clear": return
	var opacity := _weight * (0.55 if _reduced else 1.0)
	if _profile == "storm" and near_band:
		var flash := WeatherRules.storm_flash(_time) * opacity
		if flash > 0.001:
			surface.draw_rect(Rect2(0,0,640,304), Color(0.64,0.74,0.82,flash), true)
	if _profile == "snow":
		if _snow.is_empty(): return
		var sample: Array = _snow[posmod(int(floor(_time * 24.0)), _snow.size())]
		for p in sample:
			if (str(p.layer) == "near") != near_band: continue
			var position := WeatherRules.snow_position(p, _travel, _time).round()
			var radius := maxf(0.7, float(p.size) * (0.54 if near_band else 0.47))
			var alpha := clampf(float(p.alpha) * opacity * (1.32 if near_band else 1.14), 0.0, 0.78)
			# A one-pixel underside keeps pale flakes readable over snowfields while
			# the cool top face remains visible against sea, cloud and refinery art.
			if near_band and radius >= 1.65:
				var flake := PackedVector2Array([Vector2(0,-radius),Vector2(radius*0.74,0),Vector2(0,radius),Vector2(-radius*0.74,0)])
				var shadow_flake := PackedVector2Array()
				for point in flake: shadow_flake.append(position + point + Vector2(1,1))
				var face_flake := PackedVector2Array()
				for point in flake: face_flake.append(position + point)
				surface.draw_colored_polygon(shadow_flake, Color(0.12,0.16,0.19,alpha*0.38))
				surface.draw_colored_polygon(face_flake, Color(SNOW_COLOUR.r,SNOW_COLOUR.g,SNOW_COLOUR.b,alpha))
			else:
				surface.draw_circle(position + Vector2(1,1), radius, Color(0.12,0.16,0.19,alpha*0.38), true, -1, false)
				surface.draw_circle(position, radius, Color(SNOW_COLOUR.r,SNOW_COLOUR.g,SNOW_COLOUR.b,alpha), true, -1, false)
	else:
		for p in _rain.get(_profile, []):
			if (str(p.depthBand) == "foreground") != near_band: continue
			var state := WeatherRules.rain_drop(p, _time, _travel)
			var middle: Vector2 = Vector2(state.tail).lerp(state.head, 0.5)
			var alpha: float = clampf(float(state.opacity) * opacity * float(RAIN_VISIBILITY.get(_profile,1.0)) * (1.16 if near_band else 1.0), 0.0, 0.76)
			var width := 1.35 if near_band else 1.0
			surface.draw_line(state.tail, middle, Color(RAIN_COLOUR.r,RAIN_COLOUR.g,RAIN_COLOUR.b,alpha*0.46), width, false)
			surface.draw_line(middle, state.head, Color(RAIN_COLOUR.r,RAIN_COLOUR.g,RAIN_COLOUR.b,alpha), width, false)
