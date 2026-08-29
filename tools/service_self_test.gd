extends SceneTree

const ServiceRules = preload("res://scripts/service_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_service_rules()
	_test_energy_rules()
	_test_runtime_ownership()
	if failures.is_empty():
		print("Strike Wing service/energy self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_service_rules() -> void:
	_expect(ServiceRules.service_cost(80, 100, 8) == 160, "20 hull points at 8 credits each should cost 160")
	_expect(ServiceRules.service_cost(70, 100, 3) == 90, "30 shield points at 3 credits each should cost 90")
	var repaired := ServiceRules.service_full(500, 80, 100, 8)
	_expect(bool(repaired.get("changed", false)), "affordable hull service should complete")
	_expect(int(repaired.get("value", 0)) == 100 and int(repaired.get("credits", 0)) == 340, "full hull service should restore maximum and deduct exact cost")
	var denied := ServiceRules.service_full(100, 80, 100, 8)
	_expect(not bool(denied.get("changed", false)) and str(denied.get("reason", "")) == "INSUFFICIENT_CREDITS", "unaffordable service should not change airframe state")
	var full := ServiceRules.service_full(500, 100, 100, 8)
	_expect(not bool(full.get("changed", false)) and int(full.get("cost", -1)) == 0, "already-full system should cost zero")

func _test_energy_rules() -> void:
	var weak_generator := {"capacity":100.0,"recharge_per_second":25.0}
	var strong_generator := {"capacity":180.0,"recharge_per_second":50.0}
	var light_weapon := {"energy_cost":3.0}
	var heavy_weapon := {"energy_cost":14.0}
	_expect(EnergyRules.capacity(strong_generator) > EnergyRules.capacity(weak_generator), "upgraded generator should increase capacity")
	_expect(EnergyRules.recharge_rate(strong_generator) > EnergyRules.recharge_rate(weak_generator), "upgraded generator should improve sustained-fire recovery")
	_expect(EnergyRules.can_fire(14.0, heavy_weapon), "weapon should fire when exact energy cost is available")
	_expect(not EnergyRules.can_fire(13.9, heavy_weapon), "weapon should not fire below energy cost")
	_expect(absf(EnergyRules.consume(20.0, heavy_weapon) - 6.0) < 0.001, "weapon energy consumption should be exact")
	_expect(absf(EnergyRules.recharge(90.0, weak_generator, 1.0) - 100.0) < 0.001, "recharge must clamp to generator capacity")
	_expect(EnergyRules.weapon_cost(heavy_weapon) > EnergyRules.weapon_cost(light_weapon), "endgame weapon should demand more generator output than starter weapon")

func _test_runtime_ownership() -> void:
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for service/energy ownership checks")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("var service_hull := 100") and source.contains("var service_shield := 100"), "scene should own persistent airframe service state")
		_expect(source.contains("var generator_index := 0") and source.contains("var energy := 100.0"), "scene should own generator tier and sortie energy")
		_expect(source.contains("EnergyRules.recharge(energy, _active_generator(), delta)"), "mission loop should recharge generator energy directly")
		_expect(source.contains("EnergyRules.can_fire(energy, weapon)"), "primary firing should be energy gated")
		_expect(source.contains("energy = EnergyRules.consume(energy, weapon)"), "successful primary fire should consume energy")
		_expect(source.contains("service_hull = clampi(hull") and source.contains("service_shield = clampi(shield"), "successful sortie should capture surviving airframe condition directly")
		_expect(source.contains("_service_hull_full()") and source.contains("_service_shield_full()"), "title scene should own servicing actions")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	if project != null:
		_expect(not project.get_as_text().contains("ServiceDirector"), "service reconciliation autoload should remain removed")
	_expect(not FileAccess.file_exists("res://scripts/service_director.gd"), "obsolete service director file should remain deleted")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
