class_name ProgressionRules
extends RefCounted

static func mission_reward(score: int, base_reward: int = 1000) -> int:
	return maxi(0, base_reward + int(score / 10))

static func can_afford(credits: int, cost: int) -> bool:
	return cost >= 0 and credits >= cost

static func purchase(credits: int, cost: int) -> Dictionary:
	if not can_afford(credits, cost):
		return {"ok": false, "credits": credits}
	return {"ok": true, "credits": credits - cost}

static func next_weapon_index(current_index: int, weapons: Array, credits: int) -> Dictionary:
	if weapons.is_empty():
		return {"changed": false, "index": current_index, "credits": credits}
	var candidate := clampi(current_index + 1, 0, weapons.size() - 1)
	if candidate == current_index:
		return {"changed": false, "index": current_index, "credits": credits}
	var cost := int(weapons[candidate].get("cost", 0))
	var result := purchase(credits, cost)
	if not bool(result["ok"]):
		return {"changed": false, "index": current_index, "credits": credits}
	return {"changed": true, "index": candidate, "credits": int(result["credits"])}
