class_name EnergyRules
extends RefCounted

const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

static var _active_generator_context: Dictionary = {}

static func capacity(generator: Dictionary) -> float:
	return maxf(1.0, float(generator.get("capacity", 100.0)))

static func recharge_rate(generator: Dictionary) -> float:
	return maxf(0.0, float(generator.get("recharge_per_second", 0.0)))

static func recharge(current: float, generator: Dictionary, delta: float) -> float:
	_active_generator_context = generator.duplicate(true)
	return clampf(current + recharge_rate(generator) * maxf(0.0, delta), 0.0, capacity(generator))

static func weapon_cost(weapon: Dictionary) -> float:
	return maxf(0.0, float(weapon.get("energy_cost", 0.0)))

static func generator_efficiency(generator: Dictionary, equipment_era: String) -> float:
	if generator.is_empty():
		return 1.0
	var efficiency_era := str(generator.get("efficiency_tech_era", "advanced_conventional"))
	if TechProgressionRules.era_order(equipment_era) < TechProgressionRules.era_order(efficiency_era):
		return 1.0
	return clampf(float(generator.get("efficiency_multiplier", 1.0)), 0.75, 1.0)

static func effective_weapon_cost(weapon: Dictionary, generator: Dictionary = {}) -> float:
	var power_source := generator if not generator.is_empty() else _active_generator_context
	var equipment_era := str(weapon.get("unlock_tech_era", "advanced_conventional"))
	return weapon_cost(weapon) * generator_efficiency(power_source, equipment_era)

static func can_fire(current: float, weapon: Dictionary, generator: Dictionary = {}) -> bool:
	return current + 0.0001 >= effective_weapon_cost(weapon, generator)

static func consume(current: float, weapon: Dictionary, generator: Dictionary = {}) -> float:
	return maxf(0.0, current - effective_weapon_cost(weapon, generator))

static func normalized(current: float, generator: Dictionary) -> float:
	return clampf(current / capacity(generator), 0.0, 1.0)
