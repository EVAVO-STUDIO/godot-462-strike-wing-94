extends SceneTree
const Impact = preload("res://scripts/combat_impact_rules.gd")
const Countermeasures = preload("res://scripts/countermeasure_rules.gd")
const ProjectileRules = preload("res://scripts/projectile_rules.gd")
var failures: Array[String] = []
func _initialize() -> void:
	check(ProjectileRules.missile_in_acquisition_envelope(Vector2(0,0),Vector2(0,430)), "Missile acquisition should cover the authored warning envelope")
	check(not ProjectileRules.missile_launch_has_warning_time(Vector2(0,0),Vector2(0,144),161.04), "Ace missiles must not launch with less than 0.9 seconds of reaction time")
	check(ProjectileRules.missile_launch_has_warning_time(Vector2(0,0),Vector2(0,145),161.04), "Ace missiles should launch once the 0.9-second reaction window is available")
	check(Impact.projectile_class("missile") == Impact.DIRECT_WARHEAD, "Missiles need direct-warhead impacts")
	check(Impact.guidance_class("missile") == Impact.HEAT_SEEKING, "Current Sidewinder-like missiles need heat-seeking guidance")
	var direct := Impact.apply(160,140,13,Impact.DIRECT_WARHEAD,0.65)
	check(direct.hull == 0 and direct.shield == 0 and direct.catastrophic, "A successful direct warhead must destroy even an upgraded craft")
	var state := {"hull":100,"shield":100}
	for i in 2: state = Impact.apply(state.hull,state.shield,8,Impact.AUTOCANNON,1.0)
	check(state.hull == 44 and state.shield == 80, "Two autocannon hits should leave basic airframe critical but flying")
	state = Impact.apply(state.hull,state.shield,8,Impact.AUTOCANNON,1.0)
	state = Impact.apply(state.hull,state.shield,8,Impact.AUTOCANNON,1.0)
	check(state.hull == 0, "Four basic autocannon hits must destroy the craft")
	var heavy := Impact.apply(100,100,12,Impact.HEAVY_CANNON,1.0)
	heavy = Impact.apply(heavy.hull,heavy.shield,12,Impact.HEAVY_CANNON,1.0)
	heavy = Impact.apply(heavy.hull,heavy.shield,12,Impact.HEAVY_CANNON,1.0)
	check(heavy.hull == 0, "Three heavy cannon hits must destroy the basic craft")
	var fragment := Impact.apply(100,20,9,Impact.FRAGMENT,1.0)
	check(fragment.hull == 100 and fragment.shield == 11, "Fragments should remain recoverable shield damage")
	var threats: Array = [
		{"position":Vector2(100,100),"velocity":Vector2.DOWN*180,"homing":true,"guidance_class":"heat_seeking","homing_speed":180.0},
		{"position":Vector2(104,100),"velocity":Vector2.DOWN*180,"homing":true,"guidance_class":"radar","homing_speed":180.0},
	]
	check(Countermeasures.divert_missiles(threats,Vector2(120,220),Vector2(154,294)) == 1, "Flares must divert heat seekers only")
	check(threats[0].countermeasure_decoyed and threats[1].homing, "Radar guidance must ignore heat flares")
	var guided := {"position":Vector2(100,100),"velocity":Vector2.RIGHT*100,"homing":true,"homing_speed":100.0,"turn_rate":2.0,"life":2.0}
	var advanced := preload("res://scripts/projectile_rules.gd").advance_enemy_shot(guided,Vector2(100,200),0.25)
	check(Vector2(advanced.velocity).y > 0.0 and float(advanced.life) == 1.75, "Live seeker must turn toward target and consume finite lifetime")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_source.contains("_apply_projectile_impact(shot)") and main_source.contains('"DIRECT WARHEAD IMPACT // AIRFRAME LOST"'), "Runtime collision must use classified impact outcome")
	if failures.is_empty(): print("HYPERSONIC combat impact self-test passed: catastrophic warheads, penetrating cannon, recoverable fragments and heat-only flares.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
