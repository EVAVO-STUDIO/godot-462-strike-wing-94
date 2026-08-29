class_name ProgressionRules
extends RefCounted

const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

static var _current_tech_era := "advanced_conventional"

static func set_current_tech_era(era: String) -> void:
	_current_tech_era = TechProgressionRules.sanitize_era(era)

static func current_tech_era() -> String:
	return _current_tech_era

static func mission_reward(score: int, base_reward: int = 1000) -> int:
	return maxi(0, base_reward + int(score / 10))

static func can_afford(credits: int, cost: int) -> bool:
	return cost >= 0 and credits >= cost

static func purchase(credits: int, cost: int) -> Dictionary:
	if not can_afford(credits, cost):
		return {"ok": false, "credits": credits}
	return {"ok": true, "credits": credits - cost}

static func item_unlocked(item: Dictionary) -> bool:
	var required_era := str(item.get("unlock_tech_era", "advanced_conventional"))
	return TechProgressionRules.can_unlock(required_era, _current_tech_era)

static func next_weapon_index(current_index: int, weapons: Array, credits: int) -> Dictionary:
	if weapons.is_empty():
		return {"changed": false, "index": current_index, "credits": credits, "reason": "EMPTY"}
	var candidate := clampi(current_index + 1, 0, weapons.size() - 1)
	if candidate == current_index:
		return {"changed": false, "index": current_index, "credits": credits, "reason": "MAX"}
	var item = weapons[candidate]
	if typeof(item) != TYPE_DICTIONARY:
		return {"changed": false, "index": current_index, "credits": credits, "reason": "INVALID"}
	if not item_unlocked(item):
		return {
			"changed": false,
			"index": current_index,
			"credits": credits,
			"reason": "TECH_LOCK",
			"required_tech_era": str(item.get("unlock_tech_era", "advanced_conventional"))
		}
	var cost := int(item.get("cost", 0))
	var result := purchase(credits, cost)
	if not bool(result["ok"]):
		return {"changed": false, "index": current_index, "credits": credits, "reason": "CREDITS", "cost": cost}
	return {"changed": true, "index": candidate, "credits": int(result["credits"]), "reason": "PURCHASED"}
