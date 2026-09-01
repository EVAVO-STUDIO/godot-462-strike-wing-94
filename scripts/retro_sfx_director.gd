extends Node

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

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
var _last_transform_ready_serial := 0
var _last_altitude := ""
var _last_afterburner := false
var _last_hypersonic := false
var _enemy_boom_latched := false
var _last_missile_level := 0
var _last_enemy_missiles_launched := 0
var _last_strike_ordnance := -1
var _noise_state := 0x1345ABCD
var _rotary_cooldown := 0.0
var _sfx_gain:=0.75
var _radio_gain:=0.80
var _propulsion_gain := 0.0
var _propulsion_target_gain := 0.0
var _propulsion_frequency := 58.0
var _propulsion_target_frequency := 58.0
var _propulsion_airflow := 0.0
var _propulsion_target_airflow := 0.0
var _propulsion_phase := 0.0

func _ready() -> void:
	process_priority = 220
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.12
	_player = AudioStreamPlayer.new()
	_player.stream = generator
	var settings := get_node_or_null("/root/SettingsDirector")
	set_mix_levels(int(settings.call("master_level")) if settings!=null and settings.has_method("master_level") else 80,int(settings.call("sfx_level")) if settings!=null and settings.has_method("sfx_level") else 75,int(settings.call("radio_level")) if settings!=null and settings.has_method("radio_level") else 80)
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback

func set_output_level(percent: int) -> void:
	var safe_percent := clampi(percent, 0, 100)
	if _player != null:
		_player.volume_db = -80.0 if safe_percent == 0 else linear_to_db(float(safe_percent) / 100.0)

func set_mix_levels(master_percent:int,sfx_percent:int,radio_percent:int=100)->void:
	set_output_level(master_percent);_sfx_gain=float(clampi(sfx_percent,0,100))/100.0;_radio_gain=float(clampi(radio_percent,0,100))/100.0

func _process(delta: float) -> void:
	_rotary_cooldown = maxf(0.0, _rotary_cooldown - maxf(0.0, delta))
	_observe_gameplay()
	_propulsion_gain = move_toward(_propulsion_gain, _propulsion_target_gain, maxf(0.0, delta) * 0.18)
	_propulsion_frequency = move_toward(_propulsion_frequency, _propulsion_target_frequency, maxf(0.0, delta) * 90.0)
	_propulsion_airflow = move_toward(_propulsion_airflow, _propulsion_target_airflow, maxf(0.0, delta) * 1.8)
	_fill_audio_buffer()

func play_event(event_id: String) -> void:
	_trigger(event_id)

func _observe_gameplay() -> void:
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase"):
		_set_propulsion_target({})
		return
	var phase := int(scene.get("phase"))
	if phase != 1:
		_set_propulsion_target({})
		_last_shots_fired = int(scene.get("shots_fired")) if _has_property(scene, "shots_fired") else 0
		_last_missile_level = 0
		_last_enemy_missiles_launched = int(scene.get("enemy_missiles_launched")) if _has_property(scene, "enemy_missiles_launched") else 0
		_last_strike_ordnance = _strike_ordnance_count()
		_rotary_cooldown = 0.0
		_enemy_boom_latched = false
		var idle_craft := get_node_or_null("/root/CraftFormDirector")
		_last_transform_ready_serial = int(idle_craft.call("transform_ready_serial")) if idle_craft != null and idle_craft.has_method("transform_ready_serial") else 0
		return

	if _has_property(scene, "shots_fired"):
		var fired := int(scene.get("shots_fired"))
		if fired > _last_shots_fired:
			_trigger(_latest_shot_event(scene))
		_last_shots_fired = fired

	_observe_strike_release()

	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null:
		_update_propulsion_target(craft)
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
		if craft.has_method("transform_ready_serial"):
			var ready_serial := int(craft.call("transform_ready_serial"))
			if ready_serial > _last_transform_ready_serial:
				_trigger(RetroSfxRules.TRANSFORM_READY)
			_last_transform_ready_serial = ready_serial
	else:
		_set_propulsion_target({})

	_observe_missile_threat(scene)
	_observe_enemy_missile_launch(scene)
	_observe_enemy_hypersonic_boom(scene)

func _update_propulsion_target(craft: Object) -> void:
	var afterburner := craft.has_method("afterburner_active") and bool(craft.call("afterburner_active"))
	var hypersonic := craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))
	var altitude := str(craft.call("current_altitude")) if craft.has_method("current_altitude") else "mid"
	var transition_direction := int(craft.call("altitude_transition_direction")) if craft.has_method("altitude_transition_direction") else 0
	_set_propulsion_target(RetroSfxRules.propulsion_bed(afterburner, hypersonic, altitude, transition_direction))

func _set_propulsion_target(spec: Dictionary) -> void:
	_propulsion_target_gain = float(spec.get("gain", 0.0))
	_propulsion_target_frequency = float(spec.get("frequency", 58.0))
	_propulsion_target_airflow = float(spec.get("airflow", 0.0))

func _observe_enemy_missile_launch(scene: Object) -> void:
	if not _has_property(scene, "enemy_missiles_launched"):
		return
	var launched := int(scene.get("enemy_missiles_launched"))
	if launched > _last_enemy_missiles_launched:
		_trigger(RetroSfxRules.MISSILE_LAUNCH)
	_last_enemy_missiles_launched = launched

func _observe_enemy_hypersonic_boom(scene: Object) -> void:
	var fresh_boom := false
	if _has_property(scene, "enemies"):
		var enemies = scene.get("enemies")
		if typeof(enemies) == TYPE_ARRAY:
			for enemy in enemies:
				if typeof(enemy) == TYPE_DICTIONARY and float(enemy.get("hypersonic_boom_age", 99.0)) < 0.12:
					fresh_boom = true
					break
	if fresh_boom and not _enemy_boom_latched:
		_trigger(RetroSfxRules.SONIC_BOOM)
	_enemy_boom_latched = fresh_boom

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
	voice["mix_gain"]=_radio_gain if event_id in [RetroSfxRules.MISSILE_WARNING,RetroSfxRules.ALTITUDE_SHIFT,RetroSfxRules.ALTITUDE_CLIMB,RetroSfxRules.ALTITUDE_DIVE,RetroSfxRules.RADIO_TX,RetroSfxRules.RADIO_ALERT] else _sfx_gain
	voice["elapsed"] = 0.0
	voice["phase"] = 0.0
	_voices.append(voice)

func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	for _i in range(frames):
		_propulsion_phase = fposmod(_propulsion_phase + _propulsion_frequency / MIX_RATE, 1.0)
		var turbine := sin(_propulsion_phase * TAU) * 0.62 + sin(_propulsion_phase * TAU * 2.03) * 0.20
		var airflow := _noise_sample() * _propulsion_airflow
		var sample := (turbine + airflow) * _propulsion_gain * _sfx_gain
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
			var gain := float(voice.get("gain",0.12))*float(voice.get("mix_gain",1.0))*envelope
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
		"radio":
			var carrier := 1.0 if phase < 0.38 else -0.82
			var gate := 1.0 if fposmod(progress * 9.0, 1.0) < 0.62 else 0.20
			return carrier * gate * 0.72 + _noise_sample() * 0.28
		"missile":
			var ignition := _noise_sample() * (0.78 if progress < 0.12 else 0.42)
			var motor := (phase * 2.0 - 1.0) * (0.28 + 0.38 * (1.0 - progress))
			return ignition + motor
		"service":
			var ratchet := 1.0 if fposmod(progress * 6.0, 1.0) < 0.24 else -0.38
			return ratchet * (0.72 - progress * 0.32) + _noise_sample() * 0.18
		"reward":
			var step: float = floor(progress * 4.0)
			return sin(fposmod(phase + step * 0.125, 1.0) * TAU) * (0.82 - progress * 0.18)
		"shield_break":
			var discharge := sin(phase * TAU) * (0.72 - progress * 0.38)
			return discharge + _noise_sample() * (0.56 - progress * 0.28)
	return sin(phase * TAU)

func _noise_sample() -> float:
	_noise_state = int((1103515245 * _noise_state + 12345) & 0x7fffffff)
	return (float(_noise_state) / 1073741823.5) - 1.0

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)
