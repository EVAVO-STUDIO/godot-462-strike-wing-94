class_name MovementPatternRules
extends RefCounted

static func supported_patterns() -> Array[String]:
	return ["sine_dive", "tracking_sweep", "hover_strafe", "bomber_run", "combat_orbit", "road_column", "water_lane", "static", "aggressive_weave"]

static func adjusted_position(pattern: String, current: Vector2, player: Vector2, age: float, delta: float, anchor_x: float) -> Vector2:
	return adjusted_motion(pattern,current,player,age,delta,anchor_x,0.0)["position"]

static func adjusted_motion(pattern: String, current: Vector2, player: Vector2, age: float, delta: float, anchor_x: float, lateral_velocity: float) -> Dictionary:
	var next := current
	var desired_velocity := 0.0
	var acceleration := 80.0
	var maneuver_phase := fposmod(anchor_x * 0.037,TAU)
	match pattern:
		"sine_dive":
			desired_velocity = sin(age * 1.45 + maneuver_phase) * 48.0
			acceleration = 74.0
		"tracking_sweep":
			var tracking_error := player.x-next.x
			desired_velocity = clampf(tracking_error*0.72,-58.0,58.0) if absf(tracking_error)>22.0 else 0.0
			acceleration = 92.0
		"hover_strafe":
			desired_velocity = sin(age * 0.92 + maneuver_phase) * 42.0
			acceleration = 55.0
			next.y -= 18.0 * delta
		"bomber_run":
			# Loaded strike aircraft commit to a stable run and make measured course corrections.
			desired_velocity = clampf((anchor_x-next.x)*0.42 + sin(age*0.32+maneuver_phase)*7.0,-16.0,16.0)
			acceleration = 20.0
		"combat_orbit":
			# Airborne sentries hold a broad standoff orbit instead of directly homing.
			var orbit_center := player.x + sin(age*0.48+maneuver_phase)*118.0
			desired_velocity = clampf((orbit_center-next.x)*0.36,-34.0,34.0)
			acceleration = 38.0
			next.y -= 10.0*delta
		"road_column":
			desired_velocity = clampf((anchor_x-next.x)*0.9,-18.0,18.0)
			acceleration = 30.0
		"water_lane":
			desired_velocity = clampf((anchor_x-next.x)*0.5 + sin(age*0.38+maneuver_phase)*5.0,-12.0,12.0)
			acceleration = 12.0
		"static":
			next.x = anchor_x
			lateral_velocity = 0.0
		"aggressive_weave":
			desired_velocity = sin(age*2.15+maneuver_phase)*76.0 + clampf((player.x-next.x)*0.18,-22.0,22.0)
			acceleration = 155.0
	if pattern != "static":
		lateral_velocity = move_toward(lateral_velocity,desired_velocity,acceleration*maxf(0.0,delta))
		next.x += lateral_velocity*delta
	return {"position":next,"lateral_velocity":lateral_velocity,"desired_lateral_velocity":desired_velocity}

static func clamp_x(position: Vector2, minimum_x: float, maximum_x: float) -> Vector2:
	var next := position
	next.x = clampf(next.x, minimum_x, maximum_x)
	return next
