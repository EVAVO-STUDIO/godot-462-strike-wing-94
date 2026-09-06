class_name FlightCameraRules
extends RefCounted

# Route coordinates use cruise-seconds; this scale defines camera projection,
# while individual terrain layers retain their authored parallax scales.
const ROUTE_PIXELS := 48.0
const ANCHOR_Y := 252.0
const RESPONSE := 2.5

static func target_offset(speed: float) -> float:
	if speed <= 1.0:
		return lerpf(-18.0, 0.0, clampf((speed - 0.62) / 0.38, 0.0, 1.0))
	return 26.0 * (1.0 - exp(-(speed - 1.0)))

static func advance_offset(offset: float, speed: float, delta: float) -> float:
	var projected := lerpf(offset, target_offset(speed), 1.0 - exp(-RESPONSE * maxf(0.0, delta)))
	# Pulling the camera closer during deceleration must never reverse terrain.
	return maxf(projected, offset - maxf(0.0, speed) * ROUTE_PIXELS * 0.8 * maxf(0.0, delta))

static func camera_distance(player_distance: float, offset: float) -> float:
	return player_distance + offset / ROUTE_PIXELS
