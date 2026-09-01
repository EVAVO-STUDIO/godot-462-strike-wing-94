class_name RetroSfxRules
extends RefCounted

const FIRE_BALLISTIC := "fire_ballistic"
const FIRE_ROTARY := "fire_rotary"
const FIRE_RAIL := "fire_rail"
const FIRE_STORM := "fire_storm"
const FIRE_PLASMA := "fire_plasma"
const FIRE_SUPPORT := "fire_support"
const FIRE_STRATEGIC := "fire_strategic"
const HIT := "hit"
const EXPLOSION := "explosion"
const BOSS_EXPLOSION := "boss_explosion"
const PLAYER_HIT := "player_hit"
const STRIKE_RELEASE := "strike_release"
const STRIKE_IMPACT := "strike_impact"
const TRANSFORM := "transform"
const AFTERBURNER := "afterburner"
const SONIC_BOOM := "sonic_boom"
const MISSILE_WARNING := "missile_warning"
const MISSILE_LAUNCH := "missile_launch"
const UI_PURCHASE := "ui_purchase"
const UI_SERVICE := "ui_service"
const REWARD_STINGER := "reward_stinger"
const ALTITUDE_SHIFT := "altitude_shift"
const ALTITUDE_CLIMB := "altitude_climb"
const ALTITUDE_DIVE := "altitude_dive"
const RADIO_TX := "radio_tx"
const RADIO_ALERT := "radio_alert"

static func event_for_weapon(weapon_id: String) -> String:
	match weapon_id:
		"needle_rail": return FIRE_RAIL
		"storm_cannon": return FIRE_STORM
		"plasma_lance": return FIRE_PLASMA
	return FIRE_BALLISTIC

static func event_for_primary(weapon_id: String, bomber_rotary: bool) -> String:
	if bomber_rotary and event_for_weapon(weapon_id) == FIRE_BALLISTIC:
		return FIRE_ROTARY
	return event_for_weapon(weapon_id)

static func event_for_projectile(projectile: Dictionary, fallback_weapon_id: String = "", bomber_rotary: bool = false) -> String:
	if bool(projectile.get("strategic_support", false)): return FIRE_STRATEGIC
	if bool(projectile.get("support", false)): return FIRE_SUPPORT
	return event_for_primary(str(projectile.get("weapon_id", fallback_weapon_id)), bomber_rotary)

static func altitude_event(direction: int) -> String:
	if direction > 0: return ALTITUDE_CLIMB
	if direction < 0: return ALTITUDE_DIVE
	return ALTITUDE_SHIFT

static func voice(event_id: String) -> Dictionary:
	match event_id:
		FIRE_BALLISTIC: return {"wave":"square","frequency":176.0,"end_frequency":112.0,"duration":0.055,"gain":0.16}
		FIRE_ROTARY: return {"wave":"rotary","frequency":92.0,"end_frequency":74.0,"duration":0.12,"gain":0.23}
		FIRE_RAIL: return {"wave":"square","frequency":920.0,"end_frequency":210.0,"duration":0.085,"gain":0.19}
		FIRE_STORM: return {"wave":"sine","frequency":510.0,"end_frequency":260.0,"duration":0.11,"gain":0.18}
		FIRE_PLASMA: return {"wave":"saw","frequency":250.0,"end_frequency":95.0,"duration":0.19,"gain":0.20}
		FIRE_SUPPORT: return {"wave":"square","frequency":210.0,"end_frequency":130.0,"duration":0.09,"gain":0.17}
		FIRE_STRATEGIC: return {"wave":"noise","frequency":96.0,"end_frequency":58.0,"duration":0.24,"gain":0.22}
		HIT: return {"wave":"noise","frequency":420.0,"end_frequency":180.0,"duration":0.045,"gain":0.10}
		EXPLOSION: return {"wave":"blast","frequency":118.0,"end_frequency":54.0,"duration":0.22,"gain":0.21}
		BOSS_EXPLOSION: return {"wave":"blast","frequency":92.0,"end_frequency":38.0,"duration":0.42,"gain":0.26}
		PLAYER_HIT: return {"wave":"square","frequency":250.0,"end_frequency":115.0,"duration":0.09,"gain":0.15}
		# Internal rack solenoid/clunk followed by a short low airflow tail; original procedural release cue.
		STRIKE_RELEASE: return {"wave":"mechanical","frequency":132.0,"end_frequency":62.0,"duration":0.13,"gain":0.17}
		STRIKE_IMPACT: return {"wave":"blast","frequency":74.0,"end_frequency":32.0,"duration":0.30,"gain":0.24}
		TRANSFORM: return {"wave":"mechanical","frequency":84.0,"end_frequency":138.0,"duration":0.32,"gain":0.18}
		AFTERBURNER: return {"wave":"noise","frequency":72.0,"end_frequency":118.0,"duration":0.16,"gain":0.15}
		SONIC_BOOM: return {"wave":"blast","frequency":82.0,"end_frequency":31.0,"duration":0.48,"gain":0.28}
		MISSILE_WARNING: return {"wave":"square","frequency":760.0,"end_frequency":760.0,"duration":0.10,"gain":0.14}
		# Igniter snap into a descending rocket-motor rasp; deliberately separate from the cockpit lock tone.
		MISSILE_LAUNCH: return {"wave":"missile","frequency":286.0,"end_frequency":82.0,"duration":0.24,"gain":0.19}
		UI_PURCHASE: return {"wave":"mechanical","frequency":186.0,"end_frequency":248.0,"duration":0.16,"gain":0.13}
		UI_SERVICE: return {"wave":"service","frequency":112.0,"end_frequency":196.0,"duration":0.28,"gain":0.14}
		REWARD_STINGER: return {"wave":"reward","frequency":392.0,"end_frequency":784.0,"duration":0.42,"gain":0.16}
		ALTITUDE_SHIFT: return {"wave":"sine","frequency":330.0,"end_frequency":660.0,"duration":0.20,"gain":0.15}
		ALTITUDE_CLIMB: return {"wave":"saw","frequency":180.0,"end_frequency":520.0,"duration":0.34,"gain":0.15}
		ALTITUDE_DIVE: return {"wave":"saw","frequency":520.0,"end_frequency":150.0,"duration":0.34,"gain":0.15}
		RADIO_TX: return {"wave":"radio","frequency":1240.0,"end_frequency":1840.0,"duration":0.16,"gain":0.13}
		RADIO_ALERT: return {"wave":"radio","frequency":820.0,"end_frequency":410.0,"duration":0.24,"gain":0.17}
	return {}

static func valid_voice(value: Dictionary) -> bool:
	if value.is_empty(): return false
	var duration := float(value.get("duration", 0.0))
	var gain := float(value.get("gain", 0.0))
	var frequency := float(value.get("frequency", 0.0))
	return duration > 0.0 and duration <= 0.5 and gain > 0.0 and gain <= 0.30 and frequency > 0.0
