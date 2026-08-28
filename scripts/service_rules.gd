class_name ServiceRules
extends RefCounted

static func missing_points(current: int, maximum: int) -> int:
	return maxi(0, maxi(1, maximum) - clampi(current, 0, maxi(1, maximum)))

static func service_cost(current: int, maximum: int, cost_per_point: int) -> int:
	return missing_points(current, maximum) * maxi(0, cost_per_point)

static func can_service(credits: int, current: int, maximum: int, cost_per_point: int) -> bool:
	var cost := service_cost(current, maximum, cost_per_point)
	return cost > 0 and maxi(0, credits) >= cost

static func service_full(credits: int, current: int, maximum: int, cost_per_point: int) -> Dictionary:
	var max_value := maxi(1, maximum)
	var cost := service_cost(current, max_value, cost_per_point)
	if cost <= 0:
		return {"changed": false, "value": clampi(current, 0, max_value), "credits": maxi(0, credits), "cost": 0, "reason": "FULL"}
	if credits < cost:
		return {"changed": false, "value": clampi(current, 0, max_value), "credits": maxi(0, credits), "cost": cost, "reason": "INSUFFICIENT_CREDITS"}
	return {"changed": true, "value": max_value, "credits": credits - cost, "cost": cost, "reason": "SERVICED"}
