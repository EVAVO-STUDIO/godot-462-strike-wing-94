extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var settings: Node = load("res://scripts/settings_director.gd").new()
	settings.set("_fullscreen", false)
	settings.set("_sfx_level", 75)
	settings.set("_deadzone", 0.18)
	settings.set("_enhanced_projectiles", false)
	settings.set("_difficulty_id", "combat")
	_expect(settings.call("setting_label", 0) == "FULLSCREEN", "video option should identify fullscreen")
	_expect(settings.call("setting_value", 1) == "075%", "SFX option should expose exact output level")
	_expect(settings.call("setting_value", 2) == "18%", "controller option should expose exact deadzone")
	_expect(settings.call("setting_value", 3) == "AUTHENTIC", "projectile contrast should default to authentic presentation")
	_expect(settings.call("setting_label", 4) == "CAMPAIGN DIFFICULTY" and settings.call("setting_value", 4) == "COMBAT", "options should expose persistent campaign difficulty")
	_expect(int(settings.call("setting_count")) == 5, "front-end and tactical-pause options should share the full setting count")
	_expect(absf(float(settings.call("setting_ratio", 1)) - 0.75) < 0.001, "SFX meter ratio should match saved level")
	settings.free()
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('SettingsDirector="*res://scripts/settings_director.gd"'), "persistent settings should be a project autoload")
	var main := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main != null and main.get_as_text().contains("func _update_front_end_options"), "front end should own controller-navigable option input")
	var projectile := FileAccess.open("res://scripts/projectile_cue_director.gd", FileAccess.READ)
	_expect(projectile != null and projectile.get_as_text().contains("enhanced_projectile_contrast"), "enhanced contrast should alter projectile presentation")
	var sfx := FileAccess.open("res://scripts/retro_sfx_director.gd", FileAccess.READ)
	_expect(sfx != null and sfx.get_as_text().contains("func set_output_level"), "SFX setting should control real output gain")
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
