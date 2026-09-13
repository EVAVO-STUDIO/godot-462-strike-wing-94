class_name FlightCameraRules
extends RefCounted

# Route coordinates use cruise-seconds; this scale defines camera projection,
# while individual terrain layers retain their authored parallax scales.
const ROUTE_PIXELS := 48.0
const ANCHOR_Y := 230.0
const ACCELERATION_RESPONSE := 3.60
const RECOVERY_RESPONSE := 1.00

static func target_offset(speed: float) -> float:
	if speed <= 1.0:
		# At low power the aircraft falls back in the camera while the world
		# continues to advance. Cruise recentres it without stopping the route.
		return lerpf(58.0, 0.0, clampf((speed - 0.62) / 0.38, 0.0, 1.0))
	# Acceleration must visibly carry the aircraft forward. The asymptote keeps
	# even hypersonic flight readable below the HUD instead of pinning the VX-94.
	return -132.0 * (1.0 - exp(-0.85 * (speed - 1.0)))

static func advance_offset(offset: float, speed: float, delta: float) -> float:
	var target := target_offset(speed)
	# Power application should punch the VX-94 into look-ahead quickly enough to
	# sell the engine surge. Recovery is deliberately heavier so throttle-off
	# flight settles aft instead of snapping like a screen-space cursor.
	var response := ACCELERATION_RESPONSE if target < offset else RECOVERY_RESPONSE
	var projected := lerpf(offset, target, 1.0 - exp(-response * maxf(0.0, delta)))
	# Pulling the camera closer during deceleration must never reverse terrain.
	return maxf(projected, offset - maxf(0.0, speed) * ROUTE_PIXELS * 0.96 * maxf(0.0, delta))

static func camera_distance(player_distance: float, offset: float) -> float:
	return player_distance + offset / ROUTE_PIXELS
