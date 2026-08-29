class_name TechProgressionRules
extends RefCounted

const ERA_ORDER := {
	"advanced_conventional": 1,
	"electromagnetic": 2,
	"directed_energy": 3,
	"strategic_orbital": 4
}

static func era_order(era_id: String) -> int:
	return int(ERA_ORDER.get(era_id, 0))

static func can_unlock(required_era: String, current_era: String) -> bool:
	var required := era_order(required_era)
	var current := era_order(current_era)
	return required > 0 and current >= required

static func era_name(era_id: String) -> String:
	match era_id:
		"advanced_conventional": return "ADVANCED CONVENTIONAL"
		"electromagnetic": return "ELECTROMAGNETIC"
		"directed_energy": return "DIRECTED ENERGY"
		"strategic_orbital": return "STRATEGIC ORBITAL"
	return "UNKNOWN TECH"
