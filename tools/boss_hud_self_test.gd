extends SceneTree

const BossRules = preload("res://scripts/boss_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_expect(BossRules.phase_for(100, 100) == 1, "full-health boss should begin in phase one")
	_expect(BossRules.phase_for(50, 100) == 2, "damaged boss should expose phase two")
	_expect(BossRules.phase_for(20, 100) == 3, "critical boss should expose phase three")
	for phase_name in ["phase_1", "phase_2", "phase_3"]:
		var frame := load("res://assets/runtime/ui/hud/boss_phase_bar/%s.png" % phase_name)
		var fill := load("res://assets/runtime/ui/hud/boss_phase_bar/%s_fill.png" % phase_name)
		_expect(frame is Texture2D and frame.get_size() == Vector2(388, 28), "%s frame should retain reviewed HUD geometry" % phase_name)
		_expect(fill is Texture2D and fill.get_size() == Vector2(352, 5), "%s fill should retain reviewed HUD geometry" % phase_name)
	var source := FileAccess.get_file_as_string("res://scripts/pixel_ui_director.gd")
	_expect(source.contains("func _draw_boss") and source.contains("HUD_BOSS_PHASE_FRAMES") and source.contains("HUD_BOSS_PHASE_FILLS"), "live pixel UI should own the authored boss HUD")
	_expect(source.contains('boss.get("boss_phase", BossRules.phase_for') and source.contains('cue := " WEAK" if phase >= 3'), "boss HUD should expose authoritative phase and critical weak-point state")
	_expect(source.contains('replace("_", " ")') and source.contains('P%d%s  %d/%d'), "boss HUD should show readable identity, phase, and exact integrity")
	_expect(source.contains('clampf(float(hp) / float(max_hp), 0.0, 1.0)'), "boss integrity fill should remain safely clamped")
	_expect(not FileAccess.file_exists("res://scripts/boss_hud_rules.gd") and not FileAccess.file_exists("res://scripts/boss_hud_director.gd"), "obsolete competing boss HUD owners should remain removed")
	if failures.is_empty():
		print("HYPERSONIC integrated boss HUD self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
