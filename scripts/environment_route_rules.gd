class_name EnvironmentRouteRules
extends RefCounted

static func by_id(routes: Array, route_id: String) -> Dictionary:
	for route in routes:
		if typeof(route) == TYPE_DICTIONARY and str(route.get("id", "")) == route_id:
			return route
	return {}

static func validation_errors(route: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var route_id := str(route.get("id", "<unnamed>"))
	var width := int(route.get("native_width", 0))
	var chunk_height := int(route.get("chunk_height", 0))
	var world_length := int(route.get("world_length", 0))
	var districts: Array = route.get("districts", [])
	if width != 640:
		errors.append("%s must use the native 640px combat width" % route_id)
	if chunk_height <= 0:
		errors.append("%s must define a positive chunk height" % route_id)
	if districts.size() < 6:
		errors.append("%s must contain at least six districts before repeating" % route_id)
	if world_length != chunk_height * districts.size():
		errors.append("%s world length must equal chunk height times district count" % route_id)
	var ids: Dictionary = {}
	for index in range(districts.size()):
		var district = districts[index]
		if typeof(district) != TYPE_DICTIONARY:
			errors.append("%s district %d is not an object" % [route_id, index])
			continue
		var district_id := str(district.get("id", ""))
		if district_id.is_empty() or ids.has(district_id):
			errors.append("%s district IDs must be non-empty and unique" % route_id)
		ids[district_id] = true
		var asset := str(district.get("asset", ""))
		if asset.is_empty() or not FileAccess.file_exists(asset):
			errors.append("%s district %s has no loadable asset" % [route_id, district_id])
		var next = districts[(index + 1) % districts.size()]
		if typeof(next) == TYPE_DICTIONARY and str(district.get("south", "")) != str(next.get("north", "")):
			errors.append("%s connector mismatch: %s -> %s" % [route_id, district_id, str(next.get("id", ""))])
	return errors

static func texture_paths(route: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for district in route.get("districts", []):
		if typeof(district) == TYPE_DICTIONARY:
			result.append(str(district.get("asset", "")))
	return result
