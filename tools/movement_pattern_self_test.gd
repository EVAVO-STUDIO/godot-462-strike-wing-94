extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/enemies.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "enemy catalogue should load")
	var enemies: Array = data.get("enemies", []) if typeof(data) == TYPE_DICTIONARY else []
	var seen: Dictionary = {}
	for enemy in enemies:
		if bool(enemy.get("boss", false)):
			continue
		var pattern := str(enemy.get("pattern", ""))
		seen[pattern] = true
		_expect(pattern in MovementPatternRules.supported_patterns(), "unsupported authored pattern: %s" % pattern)
	for required in ["sine_dive", "tracking_sweep", "hover_strafe", "bomber_run", "combat_orbit", "road_column", "water_lane", "static", "aggressive_weave"]:
		_expect(seen.has(required), "expected authored movement pattern: %s" % required)
	var base := Vector2(200, 100)
	var player := Vector2(400, 200)
	_expect(MovementPatternRules.adjusted_position("tracking_sweep", base, player, 1.0, 1.0, 200.0).x > base.x, "tracking sweep should move toward player x")
	_expect(MovementPatternRules.adjusted_position("hover_strafe", base, player, 1.0, 1.0, 200.0).y < base.y, "hover strafe should resist downward travel")
	_expect(MovementPatternRules.adjusted_position("road_column", Vector2(240,100), player, 1.0, 1.0, 200.0).x < 240.0, "road column should return toward lane anchor")
	_expect(MovementPatternRules.adjusted_position("static", Vector2(240,100), player, 1.0, 1.0, 200.0).x == 200.0, "static emplacement should lock to anchor")
	var air_first := MovementPatternRules.adjusted_motion("tracking_sweep",base,player,1.0,0.1,200.0,0.0)
	var air_second := MovementPatternRules.adjusted_motion("tracking_sweep",air_first["position"],player,1.1,0.1,200.0,float(air_first["lateral_velocity"]))
	_expect(float(air_first["lateral_velocity"]) > 0.0 and float(air_second["lateral_velocity"]) >= float(air_first["lateral_velocity"]), "interceptors should build lateral pursuit velocity instead of snapping sideways")
	var slash_approach := MovementPatternRules.adjusted_motion("sine_dive",Vector2(180,20),player,0.5,0.1,180.0,0.0)
	var slash_break := MovementPatternRules.adjusted_motion("sine_dive",Vector2(430,240),player,3.0,0.1,180.0,0.0)
	_expect(float(slash_approach.desired_lateral_velocity)>0.0 and float(slash_break.desired_lateral_velocity)>0.0, "human fighter slash should lead toward the player then continue an energy-preserving breakaway without periodic lane waggle")
	_expect(Vector2(slash_approach.position).y>20.0 and Vector2(slash_break.position).y>240.0, "human fighter slash should accelerate into closure and unload forward energy during breakaway")
	var gunship_overflight := MovementPatternRules.adjusted_motion("tracking_sweep",Vector2(360,245),player,3.0,0.1,200.0,0.0)
	_expect(float(gunship_overflight.desired_lateral_velocity)<0.0, "gunships should unload away from the player after overflight instead of continuing screen-space tracking")
	var helicopter_station := MovementPatternRules.adjusted_motion("hover_strafe",Vector2(200,100),player,1.0,0.1,200.0,0.0)
	_expect(float(helicopter_station.desired_lateral_velocity)>0.0 and absf(float(helicopter_station.lateral_velocity))<=3.41, "helicopters should translate gradually toward a stable offset firing station")
	var ace_close := MovementPatternRules.adjusted_motion("aggressive_weave",Vector2(330,150),player,2.0,0.1,100.0,0.0)
	var ace_break := MovementPatternRules.adjusted_motion("aggressive_weave",Vector2(330,242),player,3.0,0.1,100.0,0.0)
	_expect(signf(float(ace_close.desired_lateral_velocity))!=signf(float(ace_break.desired_lateral_velocity)), "ace close jink should resolve into a distinct post-pass breakaway rather than a continuous sine weave")
	var road := MovementPatternRules.adjusted_motion("road_column",Vector2(240,100),player,1.0,0.1,200.0,0.0)
	_expect(absf(float(road["lateral_velocity"])) <= 3.01, "road vehicles should steer gradually within their route lane")
	var ship := MovementPatternRules.adjusted_motion("water_lane",Vector2(200,100),player,1.0,0.1,200.0,0.0)
	_expect(absf(float(ship["lateral_velocity"])) <= 1.21, "ships should change heading with heavy waterborne inertia")
	var bomber := MovementPatternRules.adjusted_motion("bomber_run",Vector2(240,100),player,1.0,0.1,200.0,0.0)
	_expect(absf(float(bomber["lateral_velocity"])) <= 2.01, "loaded bombers should make measured course corrections")
	var sentry := MovementPatternRules.adjusted_motion("combat_orbit",base,player,1.0,0.1,200.0,0.0)
	_expect(float(sentry["position"].y) < base.y and absf(float(sentry["lateral_velocity"])) <= 3.81, "airborne sentries should establish a controlled standoff orbit")
	_expect(MovementPatternRules.hit_response_impulse("air","tracking_sweep",240.0,200.0,240.0)>0.0, "hit aircraft should break away from the attacker's line")
	_expect(absf(MovementPatternRules.hit_response_impulse("air","bomber_run",240.0,200.0,240.0))<absf(MovementPatternRules.hit_response_impulse("air","tracking_sweep",240.0,200.0,240.0)), "loaded bombers should react with less lateral authority than fighters")
	_expect(is_zero_approx(MovementPatternRules.hit_response_impulse("ground","road_column",240.0,200.0,240.0)), "surface units should not slide sideways when hit")
	_expect(MovementPatternRules.hit_suppression_seconds("ground")>MovementPatternRules.hit_suppression_seconds("air"), "surface crews should need longer to recover their firing solution")
	_expect(MovementPatternRules.airframe_control_authority("air",2,8)<MovementPatternRules.airframe_control_authority("air",8,8), "damaged aircraft should lose maneuver authority")
	_expect(MovementPatternRules.airframe_propulsion_multiplier("air",2,8)<MovementPatternRules.airframe_propulsion_multiplier("air",8,8), "damaged aircraft should lose bounded forward propulsion")
	_expect(is_equal_approx(MovementPatternRules.airframe_control_authority("ground",2,8),1.0), "surface lane movement should not be treated as aircraft control damage")
	_expect(is_equal_approx(MovementPatternRules.airframe_propulsion_multiplier("sea",2,8),1.0), "ships should retain their authored water-lane propulsion model")
	_expect(MovementPatternRules.fire_recovery_multiplier(2,8)>MovementPatternRules.fire_recovery_multiplier(8,8), "damaged weapon systems should take longer to recover a firing solution")
	var clamped := MovementPatternRules.clamp_x(Vector2(999, 100), 36.0, 604.0)
	_expect(clamped.x == 604.0, "movement clamp should keep enemies inside playfield")
	var air_boundary := MovementPatternRules.constrain_lateral_motion(Vector2(620,100),72.0,36.0,604.0,"air")
	_expect(Vector2(air_boundary.position).x == 604.0 and float(air_boundary.lateral_velocity) < 0.0 and absf(float(air_boundary.lateral_velocity)) < 72.0, "aircraft should bank inward with energy loss instead of sticking to the playfield edge")
	var road_boundary := MovementPatternRules.constrain_lateral_motion(Vector2(20,100),-14.0,36.0,604.0,"ground")
	_expect(Vector2(road_boundary.position).x == 36.0 and is_zero_approx(float(road_boundary.lateral_velocity)), "ground vehicles should stop at their route boundary instead of bouncing")
	var sea_boundary := MovementPatternRules.constrain_lateral_motion(Vector2(620,100),9.0,36.0,604.0,"sea")
	_expect(Vector2(sea_boundary.position).x == 604.0 and is_zero_approx(float(sea_boundary.lateral_velocity)), "ships should stop at their water-lane boundary instead of bouncing")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main_source.contains("if is_boss or pursuit_active:") and main_source.contains("lateral_delta / maxf(delta, 0.001)"), "bosses and hypersonic pursuers should expose their real lateral motion to bank presentation")
	_expect(main_source.contains("--capture-air-pass=") and main_source.contains('["approach", "firing", "breakaway"]'), "visual QA should expose the complete human fighter attack-pass grammar")
	_expect(main_source.contains('"visual_bank"') and main_source.contains('"recoil_timer"') and main_source.contains('"last_shot_direction"'), "attack-pass capture evidence should expose bank attitude and connected weapon discharge")
	if failures.is_empty():
		print("Strike Wing movement pattern self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
