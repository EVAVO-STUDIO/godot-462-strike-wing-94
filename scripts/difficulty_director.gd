extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const DifficultyRules = preload("res://scripts/difficulty_rules.gd")

var _profiles: Array = []
var _profile_override: Dictionary = {}

func _ready() -> void:
	var data = ContentCatalog.load_json("res://data/difficulty_profiles.json")
	_profiles = DifficultyRules.sanitize_profiles(data.get("profiles", []) if typeof(data) == TYPE_DICTIONARY else [])

func profiles() -> Array: return _profiles.duplicate(true)
func active_profile() -> Dictionary:
	if not _profile_override.is_empty(): return _profile_override
	var wanted := "combat"
	var tree := Engine.get_main_loop() as SceneTree
	var settings := tree.root.get_node_or_null("SettingsDirector") if tree != null else null
	if settings != null and settings.has_method("difficulty_id"): wanted = str(settings.call("difficulty_id"))
	for profile in _profiles:
		if str(profile.get("id")) == wanted: return profile
	return _profiles[0] if not _profiles.is_empty() else {}

func enemy_hp(base: int, elite := false) -> int:
	var profile := active_profile(); var value := DifficultyRules.scaled(float(base),profile,"enemy_hp")
	if elite: value *= float(profile.get("elite_hp",1.0))
	return maxi(1,int(round(value)))
func enemy_speed(base: float) -> float: return DifficultyRules.scaled(base,active_profile(),"enemy_speed")
func spawn_interval(base: float) -> float: return maxf(0.24,DifficultyRules.scaled(base,active_profile(),"spawn_interval"))
func fire_interval(base: float) -> float: return maxf(0.42,DifficultyRules.scaled(base,active_profile(),"fire_interval"))
func projectile_speed(base: float) -> float: return DifficultyRules.scaled(base,active_profile(),"projectile_speed")
func boss_interval(base: float) -> float: return maxf(0.45,DifficultyRules.scaled(base,active_profile(),"boss_interval"))
func telegraph_seconds() -> float: return float(active_profile().get("telegraph_seconds",0.9))
func pickup_roll(roll: float) -> float: return clampf(roll / float(active_profile().get("pickup_rate",1.0)),0.0,1.0)
func reward(base: int) -> int: return maxi(0,int(round(float(base)*float(active_profile().get("reward",1.0)))))
func elite_index(candidate_count: int, roll: float) -> int: return DifficultyRules.elite_index(candidate_count,roll,active_profile())
func elite_value(base: int) -> int: return maxi(0,int(round(float(base)*float(active_profile().get("elite_value",1.0)))))
