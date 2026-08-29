class_name EnergyRules
extends RefCounted

static func capacity(generator: Dictionary) -> float:
	return maxf(1.0, float(generator.get("capacity", 100.0)))

static func recharge_rate(generator: Dictionary) -> float:
	return maxf(0.0, float(generator.get("recharge_per_second", 0.0)))

static func recharge(current: float, generator: Dictionary, delta: float) -> float:
	return clampf(current + recharge_rate(generator) * maxf(0.0, delta), 0.0, capacity(generator))

static func weapon_cost(weapon: Dictionary) -> float:
	return maxf(0.0, float(weapon.get("energy_cost", 0.0)))

static func can_fire(current: float, weapon: Dictionary) -> bool:
	return current + 0.0001 >= weapon_cost(weapon)

static func consume(current: float, weapon: Dictionary) -> float:
	return maxf(0.0, current - weapon_cost(weapon))

static func normalized(current: float, generator: Dictionary) -> float:
	return clampf(current / capacity(generator), 0.0, 1.0)
