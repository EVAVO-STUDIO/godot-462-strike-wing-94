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
	_expect(director_source.contains("SPEED_MULTIPLIER if hypersonic_active()"), "visual QA and live hypersonic flight should share the public world-speed latch")
	_expect(director_source.contains("AltitudeRules.BANDS.duplicate()") and director_source.contains('"%s LIMIT"') and director_source.contains('"CLIMB" if direction > 0 else "DESCENT"'), "latched hypersonic flight should permit bounded emergency climb and dive")
	_expect(director_source.contains('scene.call("_apply_structural_damage", whole_damage)') and not director_source.contains('maxi(1, int(scene.get("hull"))'), "hypersonic overload must be able to destroy the airframe instead of secretly clamping hull at one")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := main_file.get_as_text() if main_file != null else ""
	_expect(main_source.contains("func _apply_structural_damage(amount: int)") and main_source.contains("damage_taken += applied"), "structural overload should use an explicit hull-only damage path with sortie accounting")
	_expect(main_source.contains('status_text = "AIRFRAME BREAKUP // OVERSPEED"') and main_source.contains("player_loss_timer = PLAYER_LOSS_SEQUENCE_SECONDS"), "fatal overspeed should enter the authored player-loss sequence")
	if failures.is_empty():
		print("Hypersonic rules self-test passed.")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
