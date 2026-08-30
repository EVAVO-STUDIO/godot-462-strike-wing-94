extends Node

const SAVE_PATH := "user://hypersonic_options.cfg"
const MOVE_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]
const SFX_LEVELS := [0, 25, 50, 75, 100]
const DEADZONE_LEVELS := [0.12, 0.18, 0.24, 0.30]

var _fullscreen := false
var _sfx_level := 75
var _deadzone := 0.18
var _enhanced_projectiles := false

func _ready() -> void:
	_load_settings()
	_apply_all()

func adjust_setting(index: int, direction: int) -> void:
	match index:
		0: _fullscreen = not _fullscreen
		1: _sfx_level = SFX_LEVELS[posmod(SFX_LEVELS.find(_sfx_level) + direction, SFX_LEVELS.size())]
		2: _deadzone = DEADZONE_LEVELS[posmod(_nearest_deadzone_index() + direction, DEADZONE_LEVELS.size())]
		3: _enhanced_projectiles = not _enhanced_projectiles
	_apply_all()
	_save_settings()

func setting_label(index: int) -> String:
	match index:
		0: return "FULLSCREEN"
		1: return "SFX LEVEL"
		2: return "STICK DEADZONE"
		3: return "PROJECTILE CONTRAST"
	return "OPTION"

func setting_value(index: int) -> String:
	match index:
		0: return "ON" if _fullscreen else "OFF"
		1: return "%03d%%" % _sfx_level
		2: return "%02d%%" % int(round(_deadzone * 100.0))
		3: return "ENHANCED" if _enhanced_projectiles else "AUTHENTIC"
	return "--"

func setting_ratio(index: int) -> float:
	match index:
		0: return 1.0 if _fullscreen else 0.0
		1: return float(_sfx_level) / 100.0
		2: return inverse_lerp(DEADZONE_LEVELS[0], DEADZONE_LEVELS[-1], _deadzone)
		3: return 1.0 if _enhanced_projectiles else 0.0
	return 0.0

func sfx_level() -> int:
	return _sfx_level

func enhanced_projectile_contrast() -> bool:
	return _enhanced_projectiles

func _apply_all() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	for action in MOVE_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_set_deadzone(action, _deadzone)
	var audio := get_node_or_null("/root/RetroSfxDirector")
	if audio != null and audio.has_method("set_output_level"):
		audio.call("set_output_level", _sfx_level)

func _nearest_deadzone_index() -> int:
	var nearest := 0
	var distance := INF
	for index in range(DEADZONE_LEVELS.size()):
		var candidate := absf(float(DEADZONE_LEVELS[index]) - _deadzone)
		if candidate < distance:
			distance = candidate
			nearest = index
	return nearest

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_fullscreen = bool(config.get_value("video", "fullscreen", _fullscreen))
	_sfx_level = clampi(int(config.get_value("audio", "sfx_level", _sfx_level)), 0, 100)
	_deadzone = clampf(float(config.get_value("controls", "deadzone", _deadzone)), DEADZONE_LEVELS[0], DEADZONE_LEVELS[-1])
	_enhanced_projectiles = bool(config.get_value("accessibility", "enhanced_projectiles", _enhanced_projectiles))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", _fullscreen)
	config.set_value("audio", "sfx_level", _sfx_level)
	config.set_value("controls", "deadzone", _deadzone)
	config.set_value("accessibility", "enhanced_projectiles", _enhanced_projectiles)
	config.save(SAVE_PATH)
