class_name MovementPatternRules
extends RefCounted

static func supported_patterns() -> Array[String]:
	return ["sine_dive", "tracking_sweep", "hover_strafe", "bomber_run", "combat_orbit", "road_column", "water_lane", "static", "aggressive_weave"]

static func adjusted_position(pattern: String, current: Vector2, player: Vector2, age: float, delta: float, anchor_x: float) -> Vector2:
	return adjusted_motion(pattern,current,player,age,delta,anchor_x,0.0)["position"]

static func adjusted_motion(pattern: String, current: Vector2, player: Vector2, age: float, delta: float, anchor_x: float, lateral_velocity: float, control_authority: float = 1.0) -> Dictionary:
	var next := current
	var desired_velocity := 0.0
	var acceleration := 80.0
	var maneuver_phase := fposmod(anchor_x * 0.037,TAU)
	var approach_distance := player.y-next.y
	var entry_side := -1.0 if sin(maneuver_phase)<0.0 else 1.0
	var tracking_error := player.x-next.x
	var away_side := signf(next.x-player.x)
	if is_zero_approx(away_side): away_side = -entry_side
	match pattern:
		"sine_dive":
			# Human fighters fly one readable slashing pass: establish an offset,
			# lead-turn into the firing corridor, hold the gun line, then unload
			# away after crossing the player's plane. They do not waggle left/right.
			if approach_distance>145.0:
				desired_velocity = clampf(tracking_error*0.42+entry_side*18.0,-54.0,54.0)
				acceleration = 46.0
				next.y += 10.0*delta
			elif approach_distance>38.0:
				desired_velocity = clampf(tracking_error*0.66,-62.0,62.0)
				acceleration = 82.0
				next.y += 18.0*delta
			elif approach_distance>-18.0:
				desired_velocity = lateral_velocity*0.82
				acceleration = 28.0
				next.y -= 5.0*delta
			else:
				desired_velocity = away_side*76.0
				acceleration = 104.0
				next.y += 32.0*delta
		"tracking_sweep":
			# Gunships build a lead solution on approach, stabilize while weapons
			# bear, and break away after overflight instead of mirroring the player.
			if approach_distance>82.0:
				desired_velocity = clampf(tracking_error*0.62,-52.0,52.0) if absf(tracking_error)>18.0 else 0.0
				acceleration = 66.0
				next.y += 8.0*delta
			elif approach_distance>-22.0:
				desired_velocity = lateral_velocity*0.72
				acceleration = 24.0
				next.y -= 7.0*delta
			else:
				desired_velocity = away_side*58.0
				acceleration = 72.0
				next.y += 22.0*delta
		"hover_strafe":
			# Rotorcraft translate toward a stable offset firing station. Their
			# slower mass response distinguishes them from fixed-wing interceptors.
			var station_x := player.x+entry_side*104.0
			desired_velocity = clampf((station_x-next.x)*0.38,-34.0,34.0)
			acceleration = 34.0
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
			# Aces and hunter drones make a high-authority lead turn and a single
			# close defensive jink, then preserve energy in the breakaway.
			if approach_distance>112.0:
				desired_velocity = clampf(tracking_error*0.82+entry_side*14.0,-82.0,82.0)
				acceleration = 118.0
				next.y += 14.0*delta
			elif approach_distance>18.0:
				desired_velocity = clampf(tracking_error*0.38-entry_side*64.0,-92.0,92.0)
				acceleration = 148.0
				next.y += 6.0*delta
			elif approach_distance>-20.0:
				desired_velocity = lateral_velocity*0.90
				acceleration = 30.0
				next.y -= 8.0*delta
			else:
				desired_velocity = away_side*104.0
				acceleration = 170.0
				next.y += 38.0*delta
	if pattern != "static":
		lateral_velocity = move_toward(lateral_velocity,desired_velocity,acceleration*clampf(control_authority,0.0,1.0)*maxf(0.0,delta))
		next.x += lateral_velocity*delta
	return {"position":next,"lateral_velocity":lateral_velocity,"desired_lateral_velocity":desired_velocity}

static func hit_response_impulse(category: String, pattern: String, enemy_x: float, player_x: float, anchor_x: float) -> float:
	if category != "air":
		return 0.0
	var away := signf(enemy_x-player_x)
	if is_zero_approx(away):
		away = -1.0 if fposmod(anchor_x,2.0)<1.0 else 1.0
	var magnitude := 30.0 if pattern in ["bomber_run","hover_strafe","combat_orbit"] else 52.0
	return away*magnitude

static func hit_suppression_seconds(category: String) -> float:
	return 0.38 if category in ["ground","sea"] else 0.22

static func airframe_control_authority(category: String, hp: int, max_hp: int) -> float:
	if category != "air" or max_hp <= 0:
		return 1.0
	var integrity := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	# Damaged aircraft can still escape, but cannot keep snapping through the
	# same high-g manoeuvres as an intact airframe.
	return lerpf(0.42, 1.0, integrity)

static func airframe_propulsion_multiplier(category: String, hp: int, max_hp: int) -> float:
	if category != "air" or max_hp <= 0:
		return 1.0
	var integrity := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	# Engine and control damage reduce closure without making a wounded aircraft
	# hover unnaturally or reverse against the route.
	return lerpf(0.64, 1.0, integrity)

static func fire_recovery_multiplier(hp: int, max_hp: int) -> float:
	if max_hp <= 0:
		return 1.0
	var integrity := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	return lerpf(1.55, 1.0, integrity)

static func clamp_x(position: Vector2, minimum_x: float, maximum_x: float) -> Vector2:
	var next := position
	next.x = clampf(next.x, minimum_x, maximum_x)
	return next

static func constrain_lateral_motion(position: Vector2, lateral_velocity: float, minimum_x: float, maximum_x: float, category: String) -> Dictionary:
	var next := position
	var velocity := lateral_velocity
	if next.x < minimum_x:
		next.x = minimum_x
		if velocity < 0.0:
			velocity = -velocity * 0.46 if category == "air" else 0.0
	elif next.x > maximum_x:
		next.x = maximum_x
		if velocity > 0.0:
			velocity = -velocity * 0.46 if category == "air" else 0.0
	return {"position": next, "lateral_velocity": velocity}
