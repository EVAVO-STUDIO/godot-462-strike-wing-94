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
	for id in ["swarm_controller", "ai_forge_core", "orbital_command_node", "phase_control_array", "station_warden", "machine_ark"]:
		_expect(BossSignatureRules.is_signature_boss(id), "%s should own a signature attack" % id)
	_expect(not BossSignatureRules.is_signature_boss("gunship_alpha"), "opening mercenary boss should not be routed through autonomous signature rules")
	_expect(BossSignatureRules.telegraph("swarm_controller").contains("SWARM"), "swarm signature should have readable telegraph")
	_expect(BossSignatureRules.telegraph("ai_forge_core").contains("MISSILE"), "forge signature should telegraph missile battery")
	_expect(BossSignatureRules.telegraph("orbital_command_node").contains("KINETIC"), "orbital signature should telegraph kinetic lane")
	_expect(BossSignatureRules.telegraph("phase_control_array").contains("CROSSLOCK"), "phase array should telegraph crosslock attack")
	_expect(BossSignatureRules.telegraph("station_warden").contains("WARDEN"), "station warden should telegraph energy-grid attack")
	_expect(BossSignatureRules.telegraph("machine_ark").contains("STRATEGIC"), "machine ark should telegraph strategic salvo")

func _test_escalation() -> void:
	for id in ["swarm_controller", "ai_forge_core", "orbital_command_node", "phase_control_array", "station_warden", "machine_ark"]:
		_expect(BossSignatureRules.interval(id, 3) < BossSignatureRules.interval(id, 1), "%s signature should accelerate by phase 3" % id)
		_expect(BossSignatureRules.shot_count(id, 3) > BossSignatureRules.shot_count(id, 1), "%s signature should increase projectile count" % id)
		_expect(BossSignatureRules.damage(id, 3) > BossSignatureRules.damage(id, 1), "%s signature should increase damage" % id)
	_expect(BossSignatureRules.projectile_speed("machine_ark", 3) > BossSignatureRules.projectile_speed("swarm_controller", 3), "machine ark strategic lanes should be substantially faster than swarm shots")
	_expect(BossSignatureRules.damage("station_warden", 3) > BossSignatureRules.damage("swarm_controller", 3), "station warden should escalate beyond early autonomous boss damage")

func _test_source_wiring() -> void:
	var director := FileAccess.open("res://scripts/boss_director.gd", FileAccess.READ)
	_expect(director != null, "boss director should be readable")
	if director != null:
		var source := director.get_as_text()
		_expect(source.contains("BossSignatureRules.interval"), "boss runtime should schedule signature attacks")
		_expect(source.contains("BossRules.phase_salvo_enabled") and source.contains("BossRules.phase_salvo_interval"), "conventional boss salvos should use explicit per-boss phase pacing")
		_expect(source.contains("_emit_signature_attack"), "boss runtime should emit signature attacks")
		_expect(source.contains("BossSignatureRules.PHASE_ARRAY"), "phase array should receive dedicated tracking behavior")
		_expect(source.contains("BossSignatureRules.WARDEN"), "station warden should receive dedicated guided behavior")
		_expect(source.contains("BossSignatureRules.ARK"), "machine ark should receive dedicated kinetic behavior")
		_expect(source.contains('shot["kinetic"] = true'), "late orbital signatures should mark kinetic shots")
		_expect(source.contains("_report_signature"), "signature attacks should be telegraphed through status HUD")
		_expect(source.contains("_register_new_missiles") and source.contains('scene.call("_register_enemy_missile_launch", count)'), "boss homing salvos should advance the authoritative missile-launch audio counter")
		_expect(source.contains('if not bool(boss.get("entry_ready", true))') and source.contains("continue"), "boss phase and signature attacks should remain safed during the entrance reveal")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
