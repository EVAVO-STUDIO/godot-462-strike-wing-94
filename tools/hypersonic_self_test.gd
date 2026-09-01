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
	_expect(HypersonicRules.SPEED_MULTIPLIER == 3.40, "latched hypersonic flight should accelerate the layered world massively")
	_expect(HypersonicRules.enemy_pursuit_ratio(HypersonicRules.ENEMY_CHARGE_SECONDS) == 1.0, "enemy pursuit wings should finish sweeping before speed latches")
	_expect(not HypersonicRules.enemy_can_pursue({"class":"ground","hypersonic_capable":true}), "surface targets cannot join pursuit")
	var director_file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	var director_source := director_file.get_as_text() if director_file != null else ""
	_expect(director_source.contains('"--capture-flight=hypersonic"') and director_source.contains("_capture_hypersonic"), "hypersonic presentation should expose a deterministic visual QA fixture")
	_expect(director_source.contains("AltitudeRules.BANDS.duplicate()") and director_source.contains("ALTITUDE LIMIT"), "latched hypersonic flight should permit bounded emergency climb and dive")
	if failures.is_empty():
		print("Hypersonic rules self-test passed.")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
