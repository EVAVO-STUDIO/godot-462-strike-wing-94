extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var settings: Node = load("res://scripts/settings_director.gd").new()
	settings.set("_fullscreen", false)
	settings.set("_sfx_level", 75)
	settings.set("_master_level",80)
	settings.set("_music_level",65)
	settings.set("_radio_level",80)
	settings.set("_integer_scaling",true)
	settings.set("_shake_level",75)
	settings.set("_deadzone", 0.18)
	settings.set("_reduced_shake",false)
	settings.set("_reduced_flashes",false)
	settings.set("_enhanced_projectiles", false)
	settings.set("_subtitles", true)
	settings.set("_difficulty_id", "combat")
	_expect(settings.call("setting_label", 0) == "FULLSCREEN", "video option should identify fullscreen")
	_expect(settings.call("setting_value",1)=="PIXEL LOCK","integer scaling should expose authentic pixel-lock presentation")
	_expect(settings.call("setting_value",4)=="065%","music option should expose exact output level")
	_expect(settings.call("setting_value",5)=="075%","SFX option should expose exact output level")
	_expect(settings.call("setting_value",6)=="080%","radio/UI option should expose exact output level")
	_expect(settings.call("setting_value",7)=="18%","controller option should expose exact deadzone")
	_expect(settings.call("setting_value",10)=="AUTHENTIC","projectile contrast should default to authentic presentation")
	_expect(settings.call("setting_label",11)=="SUBTITLES" and settings.call("setting_value",11)=="ON","cinematic captions should default to accessible presentation")
	_expect(settings.call("setting_label",12)=="CAMPAIGN DIFFICULTY" and settings.call("setting_value",12)=="COMBAT","options should expose persistent campaign difficulty")
	_expect(int(settings.call("setting_count"))==13 and int(settings.call("category_count"))==5,"front-end and tactical-pause options should share complete category metadata")
	_expect(settings.call("category_name",3)=="ACCESS" and int(settings.call("category_global_index",3,3))==11,"accessibility page should map its rows canonically")
	_expect(absf(float(settings.call("setting_ratio",5))-0.75)<0.001,"SFX meter ratio should match saved level")
	_expect(absf(float(settings.call("screen_shake_ratio"))-0.75)<0.001,"screen feedback should consume configured shake strength")
	settings.free()
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('SettingsDirector="*res://scripts/settings_director.gd"'), "persistent settings should be a project autoload")
	var main := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main != null and main.get_as_text().contains("func _update_front_end_options"), "front end should own controller-navigable option input")
	var projectile := FileAccess.open("res://scripts/projectile_cue_director.gd", FileAccess.READ)
	_expect(projectile != null and projectile.get_as_text().contains("enhanced_projectile_contrast"), "enhanced contrast should alter projectile presentation")
	var cinematic := FileAccess.open("res://scripts/campaign_cinematic_director.gd", FileAccess.READ)
	_expect(cinematic != null and cinematic.get_as_text().contains("_subtitles_enabled()"), "subtitle preference should govern cinematic caption rendering")
	var sfx := FileAccess.open("res://scripts/retro_sfx_director.gd", FileAccess.READ)
	_expect(sfx != null and sfx.get_as_text().contains("func set_mix_levels"), "master and SFX settings should compose into real output gain")
	_expect(sfx != null and sfx.get_as_text().contains('_radio_gain if event_id in'),"warning and avionics cues should use the separate radio/UI gain path")
	var sizes := {"row_idle":Vector2(440,28),"row_selected":Vector2(440,28),"value_trough":Vector2(88,6),"value_fill":Vector2(84,2),"toggle_off":Vector2(12,12),"toggle_on":Vector2(12,12)}
	for asset_name in sizes:
		var texture := load("res://assets/runtime/ui/menu/system_options/%s.png" % asset_name)
		_expect(texture is Texture2D and texture.get_size() == sizes[asset_name], "system-options sprite should retain registered geometry: %s" % asset_name)
	if failures.is_empty():
		print("HYPERSONIC settings self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
