extends Node

const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const MIX_RATE := 22050.0
const MAX_VOICES := 8
const ROTARY_RETRIGGER_SECONDS := 0.09

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array = []
var _last_shots_fired := 0
var _last_form := ""
var _last_altitude := ""
var _last_afterburner := false
var _last_hypersonic := false
var _last_missile_level := 0
var _last_strike_ordnance := -1
var _noise_state := 0x1345ABCD
var _rotary_cooldown := 0.0

func _ready() -> void:
	process_priority = 220
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.12
	_player = AudioStreamPlayer.new()
	_player.stream = generator
	_player.volume_db = -4.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	_rotary_cooldown = maxf(0.0, _rotary_cooldown - maxf(0.0, delta))
	_observe_gameplay()
	_fill_audio_buffer()

func play_event(event_id: String) -> void:
	_trigger(event_id)

func _observe_gameplay() -> void:
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase"):
		return
	var phase := int(scene.get("phase"))
	if phase != 1:
		_last_shots_fired = int(scene.get("shots_fired")) if _has_property(scene, "shots_fired") else 0
		_last_missile_level = 0
		_last_strike_ordnance = _strike_ordnance_count()
		_rotary_cooldown = 0.0
		return

	if _has_property(scene, "shots_fired"):
		var fired := int(scene.get("shots_fired"))
		if fired > _last_shots_fired:
			_trigger(_latest_shot_event(scene))
		_last_shots_fired = fired

	_observe_strike_release()

	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null:
		if craft.has_method("current_form"):
			var form := str(craft.call("current_form"))
			if _last_form != "" and form != _last_form:
				_trigger(RetroSfxRules.TRANSFORM)
			_last_form = form
		if craft.has_method("current_altitude"):
			var altitude := str(craft.call("current_altitude"))
			if _last_altitude != "" and altitude != _last_altitude:
				var direction := 0
				if craft.has_method("altitude_transition_direction"):
					direction = int(craft.call("altitude_transition_direction"))
				_trigger(RetroSfxRules.altitude_event(direction))
			_last_altitude = altitude
		if craft.has_method("afterburner_active"):
			var active := bool(craft.call("afterburner_active"))
			if active and not _last_afterburner:
				_trigger(RetroSfxRules.AFTERBURNER)
			_last_afterburner = active
		if craft.has_method("hypersonic_active"):
			var hypersonic := bool(craft.call("hypersonic_active"))
			if hypersonic and not _last_hypersonic:
				_trigger(RetroSfxRules.SONIC_BOOM)
			_last_hypersonic = hypersonic

	_observe_missile_threat(scene)

func _observe_strike_release() -> void:
	var count := _strike_ordnance_count()
	if count < 0:
		return
	if _last_strike_ordnance >= 0 and count < _last_strike_ordnance:
		_trigger(RetroSfxRules.STRIKE_RELEASE)
	_last_strike_ordnance = count

func _strike_ordnance_count() -> int:
	var strike := get_node_or_null("/root/StrikeOrdnanceDirector")
	if strike != null and strike.has_method("ordnance_count"):
		return int(strike.call("ordnance_count"))
	return -1

func _latest_shot_event(scene: Object) -> String:
	var fallback := _active_weapon_id(scene)
	var bomber_rotary := _bomber_rotary_deployed(scene)
	if _has_property(scene, "bullets"):
		var bullets = scene.get("bullets")
		if typeof(bullets) == TYPE_ARRAY and not bullets.is_empty():
			var latest = bullets[bullets.size() - 1]
			if typeof(latest) == TYPE_DICTIONARY:
				return RetroSfxRules.event_for_projectile(latest, fallback, bomber_rotary)
	return RetroSfxRules.event_for_primary(fallback, bomber_rotary)

func _bomber_rotary_deployed(scene: Object) -> bool:
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	var craft := get_node_or_null("/root/CraftFormDirector")
	if mounts == null or craft == null or not mounts.has_method("bomber_rotary_deployed") or not craft.has_method("current_form"):
		return false
	if scene.has_method("_active_weapon"):
		var weapon = scene.call("_active_weapon")
		if typeof(weapon) == TYPE_DICTIONARY:
			return bool(mounts.call("bomber_rotary_deployed", str(craft.call("current_form")), weapon))
	return false

func _observe_missile_threat(scene: Object) -> void:
	if not _has_property(scene, "enemy_bullets") or not _has_property(scene, "player_position"):
		return
	var bullets = scene.get("enemy_bullets")
	if typeof(bullets) != TYPE_ARRAY:
		return
	var count := ThreatWarningRules.homing_count(bullets)
	var distance := ThreatWarningRules.nearest_homing_distance(bullets, scene.get("player_position"))
	var level := ThreatWarningRules.warning_level(distance, count)
	if level > _last_missile_level:
		_trigger(RetroSfxRules.MISSILE_WARNING)
	_last_missile_level = level

func _active_weapon_id(scene: Object) -> String:
	if scene.has_method("_active_weapon"):
		var weapon = scene.call("_active_weapon")
		if typeof(weapon) == TYPE_DICTIONARY:
			return str(weapon.get("id", ""))
	return ""

func _trigger(event_id: String) -> void:
	if event_id == RetroSfxRules.FIRE_ROTARY:
		if _rotary_cooldown > 0.0:
			return
		_rotary_cooldown = ROTARY_RETRIGGER_SECONDS
	var spec := RetroSfxRules.voice(event_id)
	if not RetroSfxRules.valid_voice(spec):
		return
	if _voices.size() >= MAX_VOICES:
		_voices.pop_front()
	var voice := spec.duplicate(true)
	voice["elapsed"] = 0.0
	voice["phase"] = 0.0
	_voices.append(voice)

func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for _i in range(frames):
		var sample := 0.0
		for vi in range(_voices.size() - 1, -1, -1):
			var voice: Dictionary = _voices[vi]
			var duration := maxf(0.001, float(voice.get("duration", 0.1)))
			var elapsed := float(voice.get("elapsed", 0.0))
			if elapsed >= duration:
				_voices.remove_at(vi)
				continue
			var t := clampf(elapsed / duration, 0.0, 1.0)
			var frequency := lerpf(
				float(voice.get("frequency", 220.0)),
				float(voice.get("end_frequency", 220.0)),
				t
			)
			var phase := fposmod(float(voice.get("phase", 0.0)) + frequency / MIX_RATE, 1.0)
			voice["phase"] = phase
			voice["elapsed"] = elapsed + 1.0 / MIX_RATE
			var envelope := (1.0 - t) * (1.0 - t)
			var gain := float(voice.get("gain", 0.12)) * envelope
			sample += _wave_sample(str(voice.get("wave", "sine")), phase, t) * gain
			_voices[vi] = voice
		sample = clampf(sample, -0.85, 0.85)
		_playback.push_frame(Vector2(sample, sample))

func _wave_sample(kind: String, phase: float, progress: float) -> float:
	match kind:
		"square":
			return 1.0 if phase < 0.5 else -1.0
		"saw":
			return phase * 2.0 - 1.0
		"noise":
			return _noise_sample() * (0.65 + 0.35 * sin(progress * PI))
		"mechanical":
			return (1.0 if phase < 0.42 else -0.75) * (0.7 + 0.3 * _noise_sample())
		"rotary":
			var chop := 1.0 if fposmod(phase * 7.0, 1.0) < 0.42 else -0.75
			return chop * 0.62 + _noise_sample() * 0.38
		"blast":
			var low := sin(phase * TAU) * (0.55 + 0.25 * (1.0 - progress))
			var crack := _noise_sample() * (0.72 - progress * 0.35)
			return low + crack
	return sin(phase * TAU)

func _noise_sample() -> float:
	_noise_state = int((1103515245 * _noise_state + 12345) & 0x7fffffff)
	return (float(_noise_state) / 1073741823.5) - 1.0

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
