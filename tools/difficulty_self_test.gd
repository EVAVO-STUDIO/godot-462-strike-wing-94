extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const DifficultyRules = preload("res://scripts/difficulty_rules.gd")
var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/difficulty_profiles.json")
	var profiles := DifficultyRules.sanitize_profiles(data.get("profiles",[]))
	_expect(profiles.size() == 4,"four authored campaign difficulty profiles should validate")
	_expect(str(profiles[0].get("id")) == "cadet" and str(profiles[3].get("id")) == "ace","difficulty order should remain canonical")
	_expect(float(profiles[3].get("projectile_speed")) > float(profiles[1].get("projectile_speed")),"Ace ordnance should be faster than Combat ordnance")
	_expect(float(profiles[3].get("fire_interval")) < float(profiles[1].get("fire_interval")),"Ace enemies should fire more aggressively")
	_expect(float(profiles[3].get("spawn_interval")) < float(profiles[1].get("spawn_interval")),"Ace encounter density should be higher")
	_expect(float(profiles[0].get("telegraph_seconds")) > float(profiles[3].get("telegraph_seconds")),"Cadet signature warnings should remain longer")
	_expect(float(profiles[0].get("pickup_rate")) > float(profiles[3].get("pickup_rate")),"Cadet field recovery should remain more generous")
	_expect(float(profiles[3].get("reward")) > float(profiles[1].get("reward")),"higher campaign risk should pay a real economy premium")
	_expect(DifficultyRules.elite_index(10,0.20,profiles[3]) >= 5 and DifficultyRules.elite_index(10,0.20,profiles[1]) == -1,"elite frequency should change actual enemy mix")
	var main_source := _source("res://scripts/main.gd")
	for token in ["_difficulty_spawn_interval","_difficulty_fire_interval","_difficulty_projectile_speed","_difficulty_pickup_roll","_difficulty_reward","_difficulty_elite_index"]:
		_expect(main_source.contains(token),"canonical runtime should use difficulty hook: %s" % token)
	var boss_source := _source("res://scripts/boss_director.gd")
	_expect(boss_source.contains("signature_warning_timer") and boss_source.find("_report_signature") < boss_source.rfind("_emit_signature_attack"),"boss signature warning state should precede attack release")
	_expect(boss_source.contains("_difficulty_boss_interval") and boss_source.contains("_difficulty_telegraph_seconds"),"boss cadence and warning time should respect difficulty")
	var project := _source("res://project.godot")
	_expect(project.contains('DifficultyDirector="*res://scripts/difficulty_director.gd"'),"difficulty should be a canonical project service")
	_expect(_source("res://scripts/settings_director.gd").contains("--capture-difficulty="),"difficulty visual QA should be deterministic without mutating player preferences")
	var settings := root.get_node_or_null("SettingsDirector")
	var director := root.get_node_or_null("DifficultyDirector")
	if settings != null and director != null:
		director.set("_profile_override",profiles[3])
		_expect(float(director.call("projectile_speed",100.0)) == 122.0,"Ace runtime should apply authored projectile speed")
		_expect(float(director.call("fire_interval",1.0)) == 0.74,"Ace runtime should apply authored aggression")
		_expect(int(director.call("reward",1000)) == 1350,"Ace runtime should apply authored economy premium")
		_expect(float(director.call("pickup_roll",0.20)) > 0.30,"Ace runtime should reduce pickup probability")
		director.set("_profile_override",{})
	if failures.is_empty(): print("HYPERSONIC campaign difficulty self-test passed."); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)

func _source(path: String) -> String:
	var file := FileAccess.open(path,FileAccess.READ)
	return file.get_as_text() if file != null else ""
func _expect(condition: bool,message: String) -> void:
	if not condition: failures.append(message)
