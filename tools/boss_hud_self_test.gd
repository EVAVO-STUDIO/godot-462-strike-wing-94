extends SceneTree

const BossHudRules = preload("res://scripts/boss_hud_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_expect(absf(BossHudRules.health_ratio(50, 100) - 0.5) < 0.001, "boss health ratio should reflect current/max hp")
	_expect(BossHudRules.health_ratio(-10, 100) == 0.0, "boss health ratio should clamp low")
	_expect(BossHudRules.health_ratio(150, 100) == 1.0, "boss health ratio should clamp high")
	_expect(BossHudRules.boss_name("missile_cruiser") == "MISSILE CRUISER", "boss id should become readable HUD name")
	_expect(BossHudRules.phase_label(3) == "PHASE 3", "boss phase label should expose current phase")
	var text := BossHudRules.hud_text("gunship_alpha", 25, 55, 2)
	_expect(text.contains("GUNSHIP ALPHA") and text.contains("PHASE 2") and text.contains("25/55"), "boss HUD text should include name phase and exact HP")
	if failures.is_empty():
		print("Strike Wing boss HUD self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
