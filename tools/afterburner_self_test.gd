extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_test_craft_source()
	_test_tanker_refuel_wiring()
	_test_presentation()
	if failures.is_empty():
		print("Strike Wing afterburner self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _test_craft_source() -> void:
	var file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	_expect(file != null, "craft form director should be readable")
	if file == null: return
	var source := file.get_as_text()
	_expect(source.contains("AFTERBURNER_CAPACITY := 8.0"), "afterburner should retain eight-second arcade reserve")
	_expect(source.contains("FIGHTER_AFTERBURNER_MULTIPLIER := 1.35"), "fighter should receive stronger afterburner burst")
	_expect(source.contains("BOMBER_AFTERBURNER_MULTIPLIER := 1.22"), "bomber should retain smaller usable afterburner burst")
	_expect(source.contains('Input.is_action_pressed("afterburner")'), "afterburner fuel should burn only while boost input is held")
	_expect(source.contains("afterburner_fuel = AFTERBURNER_CAPACITY"), "fresh sortie should start with full afterburner reserve")
	_expect(source.contains("func refuel_afterburner_full()"), "craft should expose explicit tanker refuel API")
	_expect(source.contains('_add_key_action("afterburner", KEY_SHIFT)'), "afterburner should bind to Shift")

func _test_tanker_refuel_wiring() -> void:
	var file := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(file != null, "support director should be readable for tanker refuel")
	if file == null: return
	var source := file.get_as_text()
	_expect(source.contains('get_node_or_null("/root/CraftFormDirector")'), "tactical rearm should resolve craft controller")
	_expect(source.contains('has_method("refuel_afterburner_full")'), "Atlas rearm should detect afterburner refuel API")
	_expect(source.contains('craft.call("refuel_afterburner_full")'), "Atlas rearm should refill afterburner reserve")

func _test_presentation() -> void:
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('AfterburnerCueDirector="*res://scripts/afterburner_cue_director.gd"'), "afterburner presentation should remain autoloaded")
	var cue := FileAccess.open("res://scripts/afterburner_cue_director.gd", FileAccess.READ)
	_expect(cue != null, "afterburner cue should be readable")
	if cue != null:
		var source := cue.get_as_text()
		_expect(source.contains('PixelFont.draw_text(surface, "AB"'), "afterburner cue should expose a compact fuel meter")
		_expect(source.contains("func _draw_flame"), "afterburner cue should expose engine flame while active")
		_expect(not source.contains("Label.new()") and not source.contains("ProgressBar.new()"), "afterburner presentation should remain pixel-canvas based")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
