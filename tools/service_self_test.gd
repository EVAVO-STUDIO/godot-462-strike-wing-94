extends SceneTree

const ServiceRules = preload("res://scripts/service_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_expect(ServiceRules.service_cost(80, 100, 8) == 160, "20 hull points at 8 credits each should cost 160")
	_expect(ServiceRules.service_cost(70, 100, 3) == 90, "30 shield points at 3 credits each should cost 90")
	var repaired := ServiceRules.service_full(500, 80, 100, 8)
	_expect(bool(repaired.get("changed", false)), "affordable hull service should complete")
	_expect(int(repaired.get("value", 0)) == 100 and int(repaired.get("credits", 0)) == 340, "full hull service should restore maximum and deduct exact cost")
	var denied := ServiceRules.service_full(100, 80, 100, 8)
	_expect(not bool(denied.get("changed", false)) and str(denied.get("reason", "")) == "INSUFFICIENT_CREDITS", "unaffordable service should not change airframe state")
	var full := ServiceRules.service_full(500, 100, 100, 8)
	_expect(not bool(full.get("changed", false)) and int(full.get("cost", -1)) == 0, "already-full system should cost zero")
	if failures.is_empty():
		print("Strike Wing service economy self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
