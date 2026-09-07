class_name ProjectileRules
extends RefCounted

const MISSILE_ACQUISITION_RANGE := 430.0
const MISSILE_MIN_POST_LAUNCH_TTI := 0.90
const AIR_GUN_RANGE := 430.0
const SURFACE_GUN_RANGE := 390.0
const MIN_GUN_RANGE := 42.0
const ENEMY_MISSILE_ENGAGEMENT_INTERVAL := 1.6
const MAX_ACTIVE_GUIDED_MISSILES := 4
const FIXED_GUN_PATTERNS := ["sine_dive", "tracking_sweep", "aggressive_weave"]
const FIXED_GUN_ALIGNMENT_PIXELS := 34.0

static func enemy_missile_capacity(category: String, boss: bool = false) -> int:
	if boss:
		return 8
	match category:
		"ground":
			return 4
		"sea":
			return 6
		_:
			return 2

static func missile_salvo_available(remaining: int) -> bool:
	return remaining >= 2

static func missile_launch_authorized(engagement_cooldown: float, active_guided_missiles: int) -> bool:
	return engagement_cooldown <= 0.0 and active_guided_missiles < MAX_ACTIVE_GUIDED_MISSILES

static func enemy_shot_velocity(origin: Vector2, target: Vector2, speed: float) -> Vector2:
	var direction := origin.direction_to(target)
	if direction.length_squared() < 0.001:
		direction = Vector2.DOWN
	return direction * speed

static func uses_fixed_aircraft_gun(category: String, pattern: String, weapon_id: String, boss: bool = false) -> bool:
	return category == "air" and not boss and pattern in FIXED_GUN_PATTERNS and weapon_id not in ["missile", "side_burst"]

static func fixed_aircraft_shot_velocity(lateral_velocity: float, speed: float) -> Vector2:
	var heading := Vector2(clampf(lateral_velocity / 120.0, -0.48, 0.48), 1.0).normalized()
	return heading * maxf(1.0, speed)

static func fixed_aircraft_has_boresight(origin: Vector2, target: Vector2, lateral_velocity: float, projectile_speed: float) -> bool:
	var offset := target - origin
	if offset.y < 0.0:
		return false
	var velocity := fixed_aircraft_shot_velocity(lateral_velocity, projectile_speed)
	var time_to_target_y := offset.y / maxf(1.0, velocity.y)
	var projected_x := origin.x + velocity.x * time_to_target_y
	return absf(projected_x - target.x) <= FIXED_GUN_ALIGNMENT_PIXELS

static func twin_gun_origins(origin: Vector2, shot_velocity: Vector2, half_spacing: float = 4.0) -> Array[Vector2]:
	var direction := shot_velocity.normalized() if shot_velocity.length_squared() > 0.001 else Vector2.DOWN
	var across := direction.orthogonal() * maxf(1.0, half_spacing)
	return [origin - across, origin + across]

static func missile_in_acquisition_envelope(origin: Vector2, target: Vector2) -> bool:
	return origin.distance_to(target) <= MISSILE_ACQUISITION_RANGE

static func missile_launch_has_warning_time(origin: Vector2, target: Vector2, speed: float) -> bool:
	return origin.distance_to(target) / maxf(1.0, speed) >= MISSILE_MIN_POST_LAUNCH_TTI

static func enemy_has_firing_solution(origin: Vector2, target: Vector2, weapon_id: String, category: String) -> bool:
	var offset := target-origin
	var distance := offset.length()
	if weapon_id == "missile":
		return missile_in_acquisition_envelope(origin,target)
	if distance < MIN_GUN_RANGE:
		return false
	if category in ["ground","sea"]:
		# Surface mounts traverse, but cannot shoot through their own hull or
		# terrain once the player has passed the emplacement.
		return distance <= SURFACE_GUN_RANGE and offset.y >= 10.0
	if weapon_id == "side_burst":
		# Door guns and helicopter cheek mounts retain a broad beam arc.
		return distance <= AIR_GUN_RANGE and offset.y >= -72.0
	# Fixed forward aircraft guns require the target to remain downrange.
	return distance <= AIR_GUN_RANGE and offset.y >= -24.0

static func advance_enemy_shot(shot: Dictionary, target: Vector2, delta: float) -> Dictionary:
	var next := shot.duplicate(true)
	var position: Vector2 = next.get("position", Vector2.ZERO)
	var velocity: Vector2 = next.get("velocity", Vector2.DOWN * 150.0)
	if bool(next.get("homing", false)):
		var speed := maxf(1.0, float(next.get("homing_speed", velocity.length())))
		var desired := position.direction_to(target)
		if desired.length_squared() > 0.001:
			var difference := angle_difference(velocity.angle(), desired.angle())
			var turn := clampf(difference, -float(next.get("turn_rate",1.8))*maxf(0.0,delta), float(next.get("turn_rate",1.8))*maxf(0.0,delta))
			velocity = velocity.rotated(turn).normalized() * speed
	position += velocity * maxf(0.0,delta)
	next["position"] = position
	next["velocity"] = velocity
	if next.has("life"): next["life"] = maxf(0.0, float(next.life) - maxf(0.0,delta))
	return next

static func pickup_kind_for_roll(roll: float) -> String:
	if roll < 0.09:
		return "shield"
	if roll < 0.15:
		return "repair"
	if roll < 0.20:
		return "bomb"
	if roll < 0.25:
		return "weapon"
	return ""

static func enemy_fire_interval(weapon_id: String, wave: int) -> float:
	var base := 2.2
	match weapon_id:
		"aimed_burst":
			base = 1.45
		"twin_burst":
			base = 1.25
		"missile":
			base = 2.0
		"cannon":
			base = 2.55
		"deck_gun":
			base = 2.25
		"side_burst":
			base = 1.55
		"single_burst":
			base = 2.05
		_:
			base = 2.1
	var wave_pressure := minf(0.75, float(maxi(0, wave - 1)) * 0.035)
	return maxf(0.52, base - wave_pressure)

static func enemy_projectile_speed(weapon_id: String) -> float:
	match weapon_id:
		"missile":
			return 132.0
		"cannon":
			return 168.0
		"deck_gun":
			return 152.0
		"twin_burst":
			return 212.0
		"side_burst":
			return 198.0
		"aimed_burst":
			return 192.0
		_:
			return 182.0

static func collision_damage(weapon_id: String, boss: bool) -> int:
	var damage := 8
	match weapon_id:
		"missile":
			damage = 13
		"cannon":
			damage = 12
		"deck_gun":
			damage = 10
		"twin_burst":
			damage = 7
		"side_burst":
			damage = 6
		"aimed_burst":
			damage = 9
		_:
			damage = 8
	if boss:
		damage += 5
	return damage

static func danger_rating(weapon_id: String) -> int:
	match weapon_id:
		"missile":
			return 5
		"cannon", "deck_gun":
			return 4
		"twin_burst", "aimed_burst":
			return 3
		"side_burst":
			return 2
		_:
			return 1
