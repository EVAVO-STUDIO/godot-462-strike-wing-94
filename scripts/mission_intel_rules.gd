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
	for id in ids:
		names.append(str(id).replace("_", " ").to_upper())
	return " / ".join(names)

static func transition_summary(transitions: Array) -> String:
	if transitions.is_empty(): return "FIXED ENVELOPE"
	var parts: Array[String] = []
	for item in transitions:
		if typeof(item) != TYPE_DICTIONARY: continue
		parts.append("%03dS>%s" % [maxi(0, int(item.get("at_seconds", 0))), altitude_code(str(item.get("altitude", "mid")))])
	return "  ".join(parts) if not parts.is_empty() else "FIXED ENVELOPE"

static func mission_lines(context: Dictionary, boss_name: String) -> Array[String]:
	return [
		"THREAT %s" % threat_name(str(context.get("threat_phase", "mercenary_war"))),
		"ENVELOPE %s  CONFIG %s  TECH %s" % [altitude_code(str(context.get("altitude", "mid"))), form_code(str(context.get("recommended_form", "fighter"))), tech_code(str(context.get("tech_era", "advanced_conventional")))],
		"PROFILE %s" % transition_summary(context.get("altitude_transitions", [])),
		"BOSS %s" % boss_name.replace("_", " ").to_upper(),
		"ALLIED %s" % support_summary(context.get("support", []))
	]
