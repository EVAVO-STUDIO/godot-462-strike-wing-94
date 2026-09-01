class_name CraftFormRules
extends RefCounted

const FIGHTER := "fighter"
const BOMBER := "bomber"
const TRANSFORM_VISUAL_SECONDS := 0.92
const TRANSFORM_COOLDOWN := 1.05
const TRANSFORM_WEAPON_INTERLOCK := 0.82

static func sanitize(form: String) -> String:
	return BOMBER if form == BOMBER else FIGHTER

static func toggle(form: String) -> String:
	return BOMBER if sanitize(form) == FIGHTER else FIGHTER

static func movement_multiplier(form: String) -> float:
	return 1.16 if sanitize(form) == FIGHTER else 0.82

static func collision_radius_sq(form: String) -> float:
	return 360.0 if sanitize(form) == FIGHTER else 520.0

static func projectile_hit_radius_sq(form: String) -> float:
	return 100.0 if sanitize(form) == FIGHTER else 156.0

static func primary_spread_multiplier(form: String) -> float:
	return 0.78 if sanitize(form) == FIGHTER else 1.22

static func primary_damage_multiplier(form: String) -> float:
	return 1.0 if sanitize(form) == FIGHTER else 1.12

static func support_energy_multiplier(form: String) -> float:
	return 1.0 if sanitize(form) == FIGHTER else 0.88

static func ground_attack_multiplier(form: String) -> float:
	return 0.82 if sanitize(form) == FIGHTER else 1.35

static func air_attack_multiplier(form: String) -> float:
	return 1.18 if sanitize(form) == FIGHTER else 0.92

static func display_name(form: String) -> String:
	return "FIGHTER" if sanitize(form) == FIGHTER else "BOMBER"
