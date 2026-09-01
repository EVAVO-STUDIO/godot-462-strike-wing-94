extends RefCounted

static var _property_names_by_instance: Dictionary = {}
static var _support_results: Dictionary = {}

static func supports(object: Object, required: Array) -> bool:
	if object == null or not is_instance_valid(object):
		return false
	var instance_id := object.get_instance_id()
	var signature := "%d|%s" % [instance_id, ",".join(required)]
	if _support_results.has(signature):
		return bool(_support_results[signature])
	var names := _property_names(object, instance_id)
	for property_name in required:
		if not names.has(str(property_name)):
			_support_results[signature] = false
			return false
	_support_results[signature] = true
	return true

static func has_property(object: Object, property_name: String) -> bool:
	if object == null or not is_instance_valid(object):
		return false
	return _property_names(object, object.get_instance_id()).has(property_name)

static func _property_names(object: Object, instance_id: int) -> Dictionary:
	if _property_names_by_instance.has(instance_id):
		return _property_names_by_instance[instance_id]
	var names: Dictionary = {}
	for property in object.get_property_list():
		names[str(property.get("name", ""))] = true
	_property_names_by_instance[instance_id] = names
	return names
