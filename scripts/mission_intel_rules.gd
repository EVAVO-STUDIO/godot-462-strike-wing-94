class_name MissionIntelRules
extends RefCounted

static func tech_code(era: String) -> String:
	match era:
		"electromagnetic": return "EM"
		"directed_energy": return "DE"
		"strategic_orbital": return "ORB"
	return "CONV"

static func altitude_code(altitude: String) -> String:
	match altitude:
		"low": return "LOW"
		"high": return "HIGH"
		"orbital": return "ORB"
	return "MID"

static func form_code(form: String) -> String:
	return "BMB" if form == "bomber" else "FTR"

static func threat_name(phase: String) -> String:
	match phase:
		"drone_war": return "AUTONOMOUS NETWORK"
		"external_contact": return "EXTERNAL CONTACT"
	return "MERCENARY FORCE"

static func support_summary(ids: Array) -> String:
	if ids.is_empty(): return "NONE"
	var names: Array[String] = []
	for id in ids: names.append(str(id).replace("_", " ").to_upper())
	return " / ".join(names)

static func transition_summary(transitions: Array) -> String:
	if transitions.is_empty(): return "FIXED ENVELOPE"
	var parts: Array[String] = []
	for item in transitions:
		if typeof(item) != TYPE_DICTIONARY: continue
		parts.append("%03dS>%s" % [maxi(0, int(item.get("at_seconds", 0))), altitude_code(str(item.get("altitude", "mid")))])
	return "  ".join(parts) if not parts.is_empty() else "FIXED ENVELOPE"

static func support_recommendation(context: Dictionary) -> String:
	var ids: Array = context.get("support", [])
	var transitions: Array = context.get("altitude_transitions", [])
	var role := str(context.get("role", ""))
	var has_orbital_transition := false
	for transition in transitions:
		if typeof(transition) == TYPE_DICTIONARY and str(transition.get("altitude", "")) == "orbital":
			has_orbital_transition = true
			break
	if "atlas_tanker" in ids and has_orbital_transition:
		return "ATLAS BEFORE ORBITAL BURN"
	if role in ["surface_strike", "factory_strike", "armoured_corridor_strike", "anti_ship"]:
		if "hammer_bomber_flight" in ids: return "HAMMER FOR SURFACE PRESSURE"
		if "spectre_gunship" in ids: return "SPECTRE FOR SURFACE PRESSURE"
		if "cruise_missile_support" in ids: return "CRUISE FOR HARD TARGETS"
	if role in ["intercept", "swarm_intercept", "air_superiority_strike"] and "rapier_flight" in ids:
		return "RAPIER FOR AIR COVER"
	if "rail_support" in ids: return "LONGSHOT FOR HEAVY TARGETS"
	if "orbital_strike" in ids: return "ORBITAL STRIKE FOR DENSE WAVES"
	return "MISSION COMMANDER DISCRETION"

static func mission_lines(context: Dictionary, boss_name: String) -> Array[String]:
	return [
		"THREAT %s" % threat_name(str(context.get("threat_phase", "mercenary_war"))),
		"ENVELOPE %s  CONFIG %s  TECH %s" % [altitude_code(str(context.get("altitude", "mid"))), form_code(str(context.get("recommended_form", "fighter"))), tech_code(str(context.get("tech_era", "advanced_conventional")))],
		"PROFILE %s" % transition_summary(context.get("altitude_transitions", [])),
		"BOSS %s" % boss_name.replace("_", " ").to_upper(),
		"ALLIED %s" % support_summary(context.get("support", [])),
		"ADVICE %s" % support_recommendation(context)
	]
