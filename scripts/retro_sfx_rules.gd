class_name RetroSfxRules
extends RefCounted

const FIRE_BALLISTIC := "fire_ballistic"
const FIRE_RAIL := "fire_rail"
const FIRE_STORM := "fire_storm"
const FIRE_PLASMA := "fire_plasma"
const TRANSFORM := "transform"
const AFTERBURNER := "afterburner"
const MISSILE_WARNING := "missile_warning"
const ALTITUDE_SHIFT := "altitude_shift"

static func event_for_weapon(weapon_id: String) -> String:
	match weapon_id:
		"needle_rail": return FIRE_RAIL
		"storm_cannon": return FIRE_STORM
		"plasma_lance": return FIRE_PLASMA
	return FIRE_BALLISTIC

static func voice(event_id: String) -> Dictionary:
	match event_id:
		FIRE_BALLISTIC:
			return {"wave":"square","frequency":160.0,"end_frequency":105.0,"duration":0.055,"gain":0.16}
		FIRE_RAIL:
			return {"wave":"square","frequency":920.0,"end_frequency":210.0,"duration":0.085,"gain":0.19}
		FIRE_STORM:
			return {"wave":"sine","frequency":510.0,"end_frequency":260.0,"duration":0.11,"gain":0.18}
		FIRE_PLASMA:
			return {"wave":"saw","frequency":250.0,"end_frequency":95.0,"duration":0.19,"gain":0.20}
		TRANSFORM:
			return {"wave":"mechanical","frequency":84.0,"end_frequency":138.0,"duration":0.28,"gain":0.18}
		AFTERBURNER:
			return {"wave":"noise","frequency":72.0,"end_frequency":118.0,"duration":0.16,"gain":0.15}
		MISSILE_WARNING:
			return {"wave":"square","frequency":760.0,"end_frequency":760.0,"duration":0.10,"gain":0.14}
		ALTITUDE_SHIFT:
			return {"wave":"sine","frequency":330.0,"end_frequency":660.0,"duration":0.20,"gain":0.15}
	return {}

static func valid_voice(value: Dictionary) -> bool:
	if value.is_empty(): return false
	var duration := float(value.get("duration", 0.0))
	var gain := float(value.get("gain", 0.0))
	var frequency := float(value.get("frequency", 0.0))
	return duration > 0.0 and duration <= 0.5 and gain > 0.0 and gain <= 0.30 and frequency > 0.0
