extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const ServiceRules = preload("res://scripts/service_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const DirectedEnergyRules = preload("res://scripts/directed_energy_rules.gd")
const AirframeRules = preload("res://scripts/airframe_rules.gd")
const MissionStateRules = preload("res://scripts/mission_state_rules.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_service_rules()
	_test_energy_rules()
	_test_generator_efficiency()
	_test_directed_energy_pulse()
	_test_airframe_progression()
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
	EnergyRules.recharge(0.0, {}, 0.0)
	_expect(EnergyRules.can_fire(14.0, heavy_weapon), "weapon should fire when exact energy cost is available")
	_expect(not EnergyRules.can_fire(13.9, heavy_weapon), "weapon should not fire below energy cost")
	_expect(absf(EnergyRules.consume(20.0, heavy_weapon) - 6.0) < 0.001, "weapon energy consumption should be exact without an efficiency generator")
	_expect(absf(EnergyRules.recharge(90.0, weak_generator, 1.0) - 100.0) < 0.001, "recharge must clamp to generator capacity")
	_expect(EnergyRules.weapon_cost(heavy_weapon) > EnergyRules.weapon_cost(light_weapon), "endgame weapon should demand more generator output than starter weapon")

func _test_generator_efficiency() -> void:
	var pulse_core := {"capacity":180.0,"recharge_per_second":50.0,"efficiency_tech_era":"electromagnetic","efficiency_multiplier":0.90}
	var overdrive := {"capacity":220.0,"recharge_per_second":60.0,"efficiency_tech_era":"directed_energy","efficiency_multiplier":0.86}
	var conventional := {"energy_cost":10.0,"unlock_tech_era":"advanced_conventional"}
	var rail := {"energy_cost":10.0,"unlock_tech_era":"electromagnetic"}
	var energy_weapon := {"energy_cost":10.0,"unlock_tech_era":"directed_energy"}
	_expect(absf(EnergyRules.effective_weapon_cost(conventional, pulse_core) - 10.0) < 0.001, "Pulse Core must not discount older conventional weapons")
	_expect(absf(EnergyRules.effective_weapon_cost(rail, pulse_core) - 9.0) < 0.001, "Pulse Core should improve electromagnetic weapon efficiency")
	_expect(absf(EnergyRules.effective_weapon_cost(rail, overdrive) - 10.0) < 0.001, "Overdrive directed-energy efficiency should not retroactively discount electromagnetic weapons")
	_expect(absf(EnergyRules.effective_weapon_cost(energy_weapon, overdrive) - 8.6) < 0.001, "Overdrive Core should improve directed-energy weapon efficiency")

func _test_directed_energy_pulse() -> void:
	var storm := {"weapon_id":"storm_cannon","position":Vector2(100,100)}
	var plasma := {"weapon_id":"plasma_lance","position":Vector2(100,100)}
	_expect(DirectedEnergyRules.is_storm_packet(storm), "Storm Cannon packets should be recognized")
	_expect(DirectedEnergyRules.is_plasma_packet(plasma), "Plasma Lance packets should be recognized")
	_expect(DirectedEnergyRules.can_discharge(storm) and DirectedEnergyRules.can_discharge(plasma), "fresh directed-energy packets should be able to discharge")
	_expect(DirectedEnergyRules.pulse_radius(plasma) > DirectedEnergyRules.pulse_radius(storm), "Plasma Lance should own the larger field discharge")
	_expect(DirectedEnergyRules.max_secondary_targets(plasma) > DirectedEnergyRules.max_secondary_targets(storm), "Plasma Lance should pressure more secondary targets than Storm Cannon")
	_expect(DirectedEnergyRules.secondary_damage(plasma) > DirectedEnergyRules.secondary_damage(storm), "Plasma Lance should have the stronger secondary field")
	_expect(DirectedEnergyRules.PLASMA_PULSE_RADIUS <= 50.0 and DirectedEnergyRules.PLASMA_MAX_SECONDARY_TARGETS <= 3, "Plasma Lance field must remain tightly bounded")
	storm["pulse_discharged"] = true
	plasma["pulse_discharged"] = true
	_expect(not DirectedEnergyRules.can_discharge(storm) and not DirectedEnergyRules.can_discharge(plasma), "each directed-energy packet must discharge at most once")
	var enemies := [{"position":Vector2(108,100),"hp":5},{"position":Vector2(118,100),"hp":5},{"position":Vector2(138,100),"hp":5},{"position":Vector2(145,100),"hp":5}]
	var fresh_plasma := {"weapon_id":"plasma_lance","position":Vector2(100,100)}
	var trigger := DirectedEnergyRules.trigger_enemy_index(Vector2(100,100), enemies, fresh_plasma)
	_expect(trigger == 0, "Plasma discharge should trigger on nearest target")
	var secondary := DirectedEnergyRules.secondary_indices(Vector2(108,100), enemies, trigger, fresh_plasma)
	_expect(secondary.size() == 3, "Plasma Lance should respect its three-target secondary cap")
	var director_file := FileAccess.open("res://scripts/directed_energy_director.gd", FileAccess.READ)
	_expect(director_file != null, "directed energy runtime should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains("DirectedEnergyRules.secondary_damage(bullet)"), "runtime should use weapon-specific field damage")
		_expect(source.contains("var damage := mini(authored_damage, hp - 1)"), "all secondary field damage should remain nonlethal")

func _test_airframe_progression() -> void:
	var data = ContentCatalog.load_json("res://data/airframes.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "airframe catalogue should load")
	if typeof(data) != TYPE_DICTIONARY: return
	var frames: Array = data.get("airframes", [])
	_expect(frames.size() == 5, "VX-94 should expose five authored airframe tiers")
	_expect(AirframeRules.capacities_non_decreasing(frames), "airframe hull/shield capacities should never regress")
	_expect(AirframeRules.resistance_non_decreasing(frames), "airframe incoming damage resistance should improve monotonically")
	var base := AirframeRules.active_frame(frames, 0)
	var magnetic := AirframeRules.active_frame(frames, 3)
	var field := AirframeRules.active_frame(frames, 4)
	_expect(AirframeRules.incoming_damage_multiplier(field) < AirframeRules.incoming_damage_multiplier(magnetic), "field-coupled frame should improve resistance")
	CombatRules.set_incoming_damage_multiplier(AirframeRules.incoming_damage_multiplier(base))
	_expect(CombatRules.mitigated_damage(20) == 20, "base frame should not reduce authored damage")
	CombatRules.set_incoming_damage_multiplier(AirframeRules.incoming_damage_multiplier(field))
	_expect(CombatRules.mitigated_damage(20) == 16, "field-coupled frame should reduce 20 damage to 16")
	CombatRules.set_incoming_damage_multiplier(1.0)
	MissionStateRules.set_airframe_context({})

func _test_runtime_ownership() -> void:
	var airframe_file := FileAccess.open("res://scripts/airframe_director.gd", FileAccess.READ)
	_expect(airframe_file != null, "airframe director should be readable")
	if airframe_file != null:
		var source := airframe_file.get_as_text()
		_expect(source.contains("CombatRules.set_incoming_damage_multiplier"), "airframe owner should publish resistance into canonical combat rule")
	var save_file := FileAccess.open("res://scripts/campaign_save.gd", FileAccess.READ)
	_expect(save_file != null, "campaign save should be readable")
	if save_file != null:
		var source := save_file.get_as_text()
		_expect(source.contains("SAVE_VERSION := 8") and source.contains('"airframe_index"'), "campaign save v8 should persist airframe tier")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	if project != null:
		var text := project.get_as_text()
		_expect(text.contains('DirectedEnergyDirector="*res://scripts/directed_energy_director.gd"'), "directed-energy owner should remain active")
		_expect(text.contains('AirframeDirector="*res://scripts/airframe_director.gd"'), "airframe owner should remain active")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
