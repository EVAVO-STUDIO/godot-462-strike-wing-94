class_name CombatImpactRules
extends RefCounted

const DIRECT_WARHEAD := "direct_warhead"
const HEAVY_CANNON := "heavy_cannon"
const AUTOCANNON := "autocannon"
const FRAGMENT := "fragment"
const ENERGY := "energy"
const HEAT_SEEKING := "heat_seeking"

static func projectile_class(weapon_id: String) -> String:
	match weapon_id:
		"missile": return DIRECT_WARHEAD
		"cannon", "deck_gun": return HEAVY_CANNON
		_: return AUTOCANNON

static func guidance_class(weapon_id: String) -> String:
	return HEAT_SEEKING if weapon_id == "missile" else "none"

static func apply(hull: int, shield: int, amount: int, impact_class: String, multiplier: float) -> Dictionary:
	var next_hull := maxi(0, hull)
	var next_shield := maxi(0, shield)
	if impact_class == DIRECT_WARHEAD:
		return {"hull":0, "shield":0, "catastrophic":true}
	var scaled := maxi(1, int(round(float(maxi(1,amount)) * multiplier)))
	match impact_class:
		HEAVY_CANNON:
			scaled = maxi(scaled, int(round(38.0 * multiplier)))
			var field_loss := mini(next_shield, maxi(1, int(round(scaled * 0.25))))
			next_shield -= field_loss
			next_hull = maxi(0, next_hull - scaled)
		AUTOCANNON:
			scaled = maxi(scaled, int(round(28.0 * multiplier)))
			var field_loss := mini(next_shield, maxi(1, int(round(scaled * 0.35))))
			next_shield -= field_loss
			next_hull = maxi(0, next_hull - scaled)
		FRAGMENT:
			var absorbed := mini(next_shield, scaled)
			next_shield -= absorbed
			next_hull = maxi(0, next_hull - (scaled - absorbed))
		_:
			var absorbed := mini(next_shield, scaled)
			next_shield -= absorbed
			next_hull = maxi(0, next_hull - (scaled - absorbed))
	return {"hull":next_hull, "shield":next_shield, "catastrophic":false}
