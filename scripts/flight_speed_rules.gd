class_name FlightSpeedRules
extends RefCounted

const HypersonicRules = preload("res://scripts/hypersonic_rules.gd")

const MINIMUM_POWER_MULTIPLIER := 0.62
const CRUISE_POWER_MULTIPLIER := 1.00
const MILITARY_POWER_MULTIPLIER := 1.36
const AFTERBURNER_POWER_MULTIPLIER := 1.78
const HYPERSONIC_POWER_MULTIPLIER := HypersonicRules.SPEED_MULTIPLIER
const THROTTLE_CHANGE_PER_SECOND := 0.55
const POWER_RESPONSE_PER_SECOND := 2.20
const DEFAULT_THROTTLE_RATIO := (CRUISE_POWER_MULTIPLIER - MINIMUM_POWER_MULTIPLIER) / (MILITARY_POWER_MULTIPLIER - MINIMUM_POWER_MULTIPLIER)

static func commanded_power(throttle_ratio: float) -> float:
	return lerpf(MINIMUM_POWER_MULTIPLIER, MILITARY_POWER_MULTIPLIER, clampf(throttle_ratio, 0.0, 1.0))

static func target_world_multiplier(throttle_ratio: float, afterburner: bool, hypersonic_ratio: float) -> float:
	var dry_power := commanded_power(throttle_ratio)
	var powered := maxf(dry_power, AFTERBURNER_POWER_MULTIPLIER) if afterburner else dry_power
	return lerpf(powered, HYPERSONIC_POWER_MULTIPLIER, clampf(hypersonic_ratio, 0.0, 1.0))

static func world_closure_multiplier(world_multiplier: float, category: String) -> float:
	# Surface contacts are fixed to geography. Aircraft retain more of their own
	# velocity, but still close materially faster when the VX-94 advances.
	var excess := maxf(0.0, world_multiplier - CRUISE_POWER_MULTIPLIER)
	if category in ["ground", "sea"]:
		return maxf(0.48, world_multiplier)
	return maxf(0.70, 1.0 + excess * 0.46)

static func recovery_closure_multiplier(world_multiplier: float) -> float:
	return maxf(0.48, world_multiplier)

static func dynamic_pressure_damage_per_second(altitude: String, world_multiplier: float) -> float:
	if altitude == "low":
		return maxf(0.0, world_multiplier - 1.62) * 7.8
	if altitude == "mid":
		return maxf(0.0, world_multiplier - 3.25) * 2.8
	return 0.0
