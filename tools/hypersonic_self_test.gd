extends SceneTree

const HypersonicRules = preload("res://scripts/hypersonic_rules.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_expect(HypersonicRules.can_charge("fighter", false, 1.0), "fighter should enter the hypersonic envelope")
	_expect(not HypersonicRules.can_charge("bomber", false, 1.0), "deployed bomber geometry must not enter hypersonic flight")
	_expect(HypersonicRules.charge_seconds("high") < HypersonicRules.charge_seconds("low"), "thin-air high-altitude transition should be safer and faster")
	_expect(HypersonicRules.structural_damage_per_second("low") > HypersonicRules.structural_damage_per_second("mid"), "low hypersonic flight should carry severe airframe risk")
	_expect(HypersonicRules.structural_damage_per_second("high") == 0.0, "high altitude should be the intended hypersonic corridor")
	_expect(HypersonicRules.enemy_can_pursue({"class":"air","hypersonic_capable":true}), "authored interceptor should be able to pursue")
	_expect(not HypersonicRules.enemy_can_pursue({"class":"ground","hypersonic_capable":true}), "surface targets cannot join pursuit")
	if failures.is_empty():
		print("Hypersonic rules self-test passed.")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
