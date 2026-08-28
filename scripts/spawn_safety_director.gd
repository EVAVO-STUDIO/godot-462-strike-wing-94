extends Node

const SpawnSafetyRules = preload("res://scripts/spawn_safety_rules.gd")

var _injected_profile: Dictionary = {}

func _ready() -> void:
	process_priority = -120

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var profiles = scene.get("spawn_profiles")
	if typeof(profiles) != TYPE_ARRAY:
		return
	_remove_previous_sentinel(profiles)
	var environment := str(scene.get("current_environment"))
	var wave := maxi(1, int(scene.get("wave")))
	if not SpawnSafetyRules.has_matching_profile(profiles, environment, wave):
		_injected_profile = SpawnSafetyRules.sentinel_profile(environment, wave)
		profiles.append(_injected_profile)
	else:
		_injected_profile = {}
	scene.set("spawn_profiles", profiles)

func _remove_previous_sentinel(profiles: Array) -> void:
	for i in range(profiles.size() - 1, -1, -1):
		var profile = profiles[i]
		if typeof(profile) == TYPE_DICTIONARY and str(profile.get("id", "")) == "runtime_spawn_block":
			profiles.remove_at(i)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("spawn_profiles") and names.has("current_environment") and names.has("wave")
