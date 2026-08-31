extends Node

const SAVE_PATH := "user://hypersonic_options.cfg"
const MOVE_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]
const LEVELS := [0, 25, 50, 75, 100]
const DEADZONE_LEVELS := [0.12, 0.18, 0.24, 0.30]
const DIFFICULTY_IDS := ["cadet", "combat", "veteran", "ace"]
const CATEGORY_NAMES := ["VIDEO", "AUDIO", "CONTROLS", "ACCESS", "GAMEPLAY"]
const CATEGORY_SETTINGS := [[0,1,2],[3,4,5,6],[7],[8,9,10],[11]]

var _fullscreen := false
var _integer_scaling := true
var _shake_level := 75
var _master_level := 80
var _music_level := 65
var _sfx_level := 75
var _radio_level := 80
var _deadzone := 0.18
var _reduced_shake := false
var _reduced_flashes := false
var _enhanced_projectiles := false
var _difficulty_id := "combat"

func _ready() -> void:
	_load_settings(); _apply_capture_override(OS.get_cmdline_user_args()); _apply_all()

func adjust_setting(index: int, direction: int) -> void:
	match index:
		0: _fullscreen = not _fullscreen
		1: _integer_scaling = not _integer_scaling
		2: _shake_level = _cycle_level(_shake_level,direction)
		3: _master_level = _cycle_level(_master_level,direction)
		4: _music_level = _cycle_level(_music_level,direction)
		5: _sfx_level = _cycle_level(_sfx_level,direction)
		6: _radio_level = _cycle_level(_radio_level,direction)
		7: _deadzone = DEADZONE_LEVELS[posmod(_nearest_deadzone_index()+direction,DEADZONE_LEVELS.size())]
		8: _reduced_shake = not _reduced_shake
		9: _reduced_flashes = not _reduced_flashes
		10: _enhanced_projectiles = not _enhanced_projectiles
		11: _difficulty_id = DIFFICULTY_IDS[posmod(DIFFICULTY_IDS.find(_difficulty_id)+direction,DIFFICULTY_IDS.size())]
	_apply_all(); _save_settings()

func setting_label(index: int) -> String:
	return ["FULLSCREEN","INTEGER SCALING","SCREEN SHAKE","MASTER LEVEL","MUSIC LEVEL","SFX LEVEL","RADIO / UI LEVEL","STICK DEADZONE","REDUCED SHAKE","REDUCED FLASHES","PROJECTILE CONTRAST","CAMPAIGN DIFFICULTY"][clampi(index,0,11)]
func setting_value(index: int) -> String:
	match index:
		0: return "ON" if _fullscreen else "OFF"
		1: return "PIXEL LOCK" if _integer_scaling else "FLEXIBLE"
		2: return "%03d%%" % _shake_level
		3: return "%03d%%" % _master_level
		4: return "%03d%%" % _music_level
		5: return "%03d%%" % _sfx_level
		6: return "%03d%%" % _radio_level
		7: return "%02d%%" % int(round(_deadzone*100.0))
		8: return "ON" if _reduced_shake else "OFF"
		9: return "ON" if _reduced_flashes else "OFF"
		10: return "ENHANCED" if _enhanced_projectiles else "AUTHENTIC"
		11: return _difficulty_id.to_upper()
	return "--"
func setting_ratio(index: int) -> float:
	match index:
		0: return 1.0 if _fullscreen else 0.0
		1: return 1.0 if _integer_scaling else 0.0
		2: return float(_shake_level)/100.0
		3: return float(_master_level)/100.0
		4: return float(_music_level)/100.0
		5: return float(_sfx_level)/100.0
		6: return float(_radio_level)/100.0
		7: return inverse_lerp(DEADZONE_LEVELS[0],DEADZONE_LEVELS[-1],_deadzone)
		8: return 1.0 if _reduced_shake else 0.0
		9: return 1.0 if _reduced_flashes else 0.0
		10: return 1.0 if _enhanced_projectiles else 0.0
		11: return float(DIFFICULTY_IDS.find(_difficulty_id))/float(DIFFICULTY_IDS.size()-1)
	return 0.0

func category_count()->int:return CATEGORY_NAMES.size()
func category_name(index:int)->String:return CATEGORY_NAMES[clampi(index,0,CATEGORY_NAMES.size()-1)]
func category_setting_count(index:int)->int:return CATEGORY_SETTINGS[clampi(index,0,CATEGORY_SETTINGS.size()-1)].size()
func category_global_index(category:int,row:int)->int:
	var entries:Array=CATEGORY_SETTINGS[clampi(category,0,CATEGORY_SETTINGS.size()-1)]
	return int(entries[clampi(row,0,entries.size()-1)])
func setting_count()->int:return 12
func sfx_level()->int:return _sfx_level
func master_level()->int:return _master_level
func music_level()->int:return _music_level
func radio_level()->int:return _radio_level
func screen_shake_ratio()->float:return float(_shake_level)/100.0*(0.35 if _reduced_shake else 1.0)
func reduced_flashes()->bool:return _reduced_flashes
func enhanced_projectile_contrast()->bool:return _enhanced_projectiles
func difficulty_id()->String:return _difficulty_id

func _apply_capture_override(arguments:PackedStringArray)->void:
	for argument in arguments:
		if argument.begins_with("--capture-difficulty="):
			var requested:=argument.trim_prefix("--capture-difficulty=").to_lower()
			if requested in DIFFICULTY_IDS:_difficulty_id=requested
func _apply_all()->void:
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		var tree:=Engine.get_main_loop() as SceneTree
		if tree!=null:tree.root.content_scale_stretch=Window.CONTENT_SCALE_STRETCH_INTEGER if _integer_scaling else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	for action in MOVE_ACTIONS:
		if InputMap.has_action(action):InputMap.action_set_deadzone(action,_deadzone)
	var audio:=get_node_or_null("/root/RetroSfxDirector")
	if audio!=null and audio.has_method("set_mix_levels"):audio.call("set_mix_levels",_master_level,_sfx_level,_radio_level)
	elif audio!=null and audio.has_method("set_output_level"):audio.call("set_output_level",int(round(float(_master_level*_sfx_level)/100.0)))
	var music:=get_node_or_null("/root/RetroMusicDirector")
	if music!=null and music.has_method("set_mix_levels"):music.call("set_mix_levels",_master_level,_music_level)
func _cycle_level(value:int,direction:int)->int:
	var nearest:=0;var distance:=INF
	for i in range(LEVELS.size()):
		if absf(float(LEVELS[i]-value))<distance:distance=absf(float(LEVELS[i]-value));nearest=i
	return LEVELS[posmod(nearest+direction,LEVELS.size())]
func _nearest_deadzone_index()->int:
	var nearest:=0;var distance:=INF
	for i in range(DEADZONE_LEVELS.size()):
		if absf(DEADZONE_LEVELS[i]-_deadzone)<distance:distance=absf(DEADZONE_LEVELS[i]-_deadzone);nearest=i
	return nearest
func _load_settings()->void:
	var config:=ConfigFile.new()
	if config.load(SAVE_PATH)!=OK:return
	_fullscreen=bool(config.get_value("video","fullscreen",_fullscreen));_integer_scaling=bool(config.get_value("video","integer_scaling",_integer_scaling));_shake_level=clampi(int(config.get_value("video","shake_level",_shake_level)),0,100)
	_master_level=clampi(int(config.get_value("audio","master_level",_master_level)),0,100);_music_level=clampi(int(config.get_value("audio","music_level",_music_level)),0,100);_sfx_level=clampi(int(config.get_value("audio","sfx_level",_sfx_level)),0,100);_radio_level=clampi(int(config.get_value("audio","radio_level",_radio_level)),0,100)
	_deadzone=clampf(float(config.get_value("controls","deadzone",_deadzone)),DEADZONE_LEVELS[0],DEADZONE_LEVELS[-1])
	_reduced_shake=bool(config.get_value("accessibility","reduced_shake",_reduced_shake));_reduced_flashes=bool(config.get_value("accessibility","reduced_flashes",_reduced_flashes));_enhanced_projectiles=bool(config.get_value("accessibility","enhanced_projectiles",_enhanced_projectiles))
	var loaded:=str(config.get_value("gameplay","difficulty",_difficulty_id)).to_lower();_difficulty_id=loaded if loaded in DIFFICULTY_IDS else "combat"
func _save_settings()->void:
	var config:=ConfigFile.new()
	config.set_value("video","fullscreen",_fullscreen);config.set_value("video","integer_scaling",_integer_scaling);config.set_value("video","shake_level",_shake_level)
	config.set_value("audio","master_level",_master_level);config.set_value("audio","music_level",_music_level);config.set_value("audio","sfx_level",_sfx_level);config.set_value("audio","radio_level",_radio_level);config.set_value("controls","deadzone",_deadzone)
	config.set_value("accessibility","reduced_shake",_reduced_shake);config.set_value("accessibility","reduced_flashes",_reduced_flashes);config.set_value("accessibility","enhanced_projectiles",_enhanced_projectiles)
	config.set_value("gameplay","difficulty",_difficulty_id);config.save(SAVE_PATH)
