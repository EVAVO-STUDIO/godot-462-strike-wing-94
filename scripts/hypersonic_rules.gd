class_name HypersonicRules
extends RefCounted

const CHARGE_SECONDS := {"low":1.40,"mid":1.15,"high":0.85,"orbital":0.70}
const SPEED_MULTIPLIER := 4.40
const TURN_SCALE := 0.38
const ENTRY_ACCEL_SECONDS := 0.12
const EXIT_DECEL_SECONDS := 0.62
const ENEMY_CHARGE_SECONDS := 0.82
const ENEMY_SPEED_MULTIPLIER := 2.65

static func can_charge(form: String, altitude_transition_active: bool, fuel: float) -> bool:
	return form == "fighter" and not altitude_transition_active and fuel > 0.001

static func charge_seconds(altitude: String) -> float:
	return float(CHARGE_SECONDS.get(altitude, CHARGE_SECONDS["mid"]))

static func structural_damage_per_second(altitude: String) -> float:
	match altitude:
		"low": return 15.0
		"mid": return 3.5
	return 0.0

static func fuel_burn_multiplier(altitude: String) -> float:
	match altitude:
		"low": return 2.6
		"mid": return 2.0
		"high": return 1.65
		"orbital": return 1.45
	return 2.0

static func enemy_can_pursue(archetype: Dictionary) -> bool:
	return bool(archetype.get("hypersonic_capable", false)) and str(archetype.get("class", "air")) == "air"

static func enemy_pursuit_ratio(charge: float) -> float:
	return clampf(charge / ENEMY_CHARGE_SECONDS, 0.0, 1.0)
