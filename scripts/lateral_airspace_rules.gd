class_name LateralAirspaceRules
extends RefCounted

const SAFE_MIN_X := 72.0
const SAFE_MAX_X := 568.0
const ABORT_SECONDS := 4.0

static func side_for_x(x: float) -> String:
	if x < SAFE_MIN_X:
		return "left"
	if x > SAFE_MAX_X:
		return "right"
	return ""

static func advance(timer: float, x: float, delta: float, lateral_command: float = 0.0) -> float:
	var side := side_for_x(x)
	var departing := (side == "left" and lateral_command < -0.1) or (side == "right" and lateral_command > 0.1)
	if not departing:
		return move_toward(maxf(0.0, timer), 0.0, maxf(0.0, delta) * 2.0)
	return minf(ABORT_SECONDS, maxf(0.0, timer) + maxf(0.0, delta))

static func warning_ratio(timer: float) -> float:
	return clampf(maxf(0.0, timer) / ABORT_SECONDS, 0.0, 1.0)

static func seconds_remaining(timer: float) -> int:
	return maxi(0, int(ceil(ABORT_SECONDS - maxf(0.0, timer))))
