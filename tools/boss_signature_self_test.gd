extends SceneTree

const BossSignatureRules = preload("res://scripts/boss_signature_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_signature_roles()
	_test_escalation()
	_test_source_wiring()
	if failures.is_empty():
		print("Strike Wing boss signature self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_signature_roles() -> void:
	_expect(BossSignatureRules.is_signature_boss("swarm_controller"), "Swarm Controller should own a signature attack")
	_expect(BossSignatureRules.is_signature_boss("ai_forge_core"), "AI Forge Core should own a signature attack")
	_expect(BossSignatureRules.is_signature_boss("orbital_command_node"), "Orbital Command Node should own a signature attack")
	_expect(not BossSignatureRules.is_signature_boss("gunship_alpha"), "opening mercenary boss should not be routed through autonomous signature rules")
	_expect(BossSignatureRules.telegraph("swarm_controller").contains("SWARM"), "swarm signature should have readable telegraph")
	_expect(BossSignatureRules.telegraph("ai_forge_core").contains("MISSILE"), "forge signature should telegraph missile battery")
	_expect(BossSignatureRules.telegraph("orbital_command_node").contains("KINETIC"), "orbital signature should telegraph kinetic lane")

func _test_escalation() -> void:
	for id in ["swarm_controller", "ai_forge_core", "orbital_command_node"]:
		_expect(BossSignatureRules.interval(id, 3) < BossSignatureRules.interval(id, 1), "%s signature should accelerate by phase 3" % id)
		_expect(BossSignatureRules.shot_count(id, 3) > BossSignatureRules.shot_count(id, 1), "%s signature should increase projectile count" % id)
		_expect(BossSignatureRules.damage(id, 3) > BossSignatureRules.damage(id, 1), "%s signature should increase damage" % id)
	_expect(BossSignatureRules.projectile_speed("orbital_command_node", 3) > BossSignatureRules.projectile_speed("swarm_controller", 3), "orbital kinetic lanes should be substantially faster than swarm shots")

func _test_source_wiring() -> void:
	var director := FileAccess.open("res://scripts/boss_director.gd", FileAccess.READ)
	_expect(director != null, "boss director should be readable")
	if director != null:
		var source := director.get_as_text()
		_expect(source.contains("BossSignatureRules.interval"), "boss runtime should schedule signature attacks")
		_expect(source.contains("_emit_signature_attack"), "boss runtime should emit signature attacks")
		_expect(source.contains('shot["kinetic"] = true'), "orbital command node should mark kinetic signature shots")
		_expect(source.contains("_report_signature"), "signature attacks should be telegraphed through status HUD")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
