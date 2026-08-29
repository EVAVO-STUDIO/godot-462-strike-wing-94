extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PlayerMountRules = preload("res://scripts/player_mount_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/player_mounts.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "player mount catalogue should load")
	if typeof(data) == TYPE_DICTIONARY:
		_expect(int(data.get("schema_version", 0)) >= 2, "mount catalogue should include strategic-bay schema")
		_expect(str(data.get("craft_id", "")) == "vx_94_strikewing", "mount catalogue should belong to VX-94")
		var mounts: Array = data.get("mounts", [])
		_expect(mounts.size() >= 11, "VX-94 should expose complete internal/pylon/module mount vocabulary")
		_test_primary_mounts(mounts)
		_test_support_mounts(mounts)
		_test_role_isolation(mounts)
	_test_wiring()
	if failures.is_empty():
		print("Strike Wing player mount self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _test_primary_mounts(mounts: Array) -> void:
	var ballistic := {"archetype":"balanced"}
	var fighter := PlayerMountRules.primary_offsets(mounts, "fighter", ballistic, 2)
	_expect(fighter == [Vector2(-13,-12),Vector2(13,-12)], "fighter ballistic pair should fire from wing-root cannons")
	var bomber := PlayerMountRules.primary_offsets(mounts, "bomber", ballistic, 2)
	_expect(bomber == [Vector2(0,-27),Vector2(0,-27)], "bomber ballistic pair should converge on deployed nose rotary bay")
	var rail := PlayerMountRules.primary_offsets(mounts, "fighter", {"archetype":"precision_kinetic"}, 1)
	_expect(rail == [Vector2(0,-19)], "Needle Rail should use centreline specialist emitter")
	var storm := PlayerMountRules.primary_offsets(mounts, "bomber", {"archetype":"directed_energy_pulse"}, 3)
	_expect(storm.size() == 3 and storm[0] == Vector2(0,-24) and storm[2] == Vector2(0,-24), "Storm pulses should share bomber centreline emitter")
	_expect(PlayerMountRules.bomber_rotary_deployed("bomber", ballistic), "bomber conventional gun should deploy nose rotary")
	_expect(not PlayerMountRules.bomber_rotary_deployed("fighter", ballistic), "fighter should keep nose rotary retracted")

func _test_support_mounts(mounts: Array) -> void:
	var rockets := {"id":"twin_rocket_pods","type":"rockets"}
	var fighter_rockets := PlayerMountRules.support_offsets(mounts, "fighter", rockets, 2)
	_expect(fighter_rockets == [Vector2(-15,-5),Vector2(15,-5)], "fighter rockets should use inner wing pylons")
	var bomber_rockets := PlayerMountRules.support_offsets(mounts, "bomber", rockets, 4)
	_expect(bomber_rockets == [Vector2(-21,3),Vector2(21,3),Vector2(-27,9),Vector2(27,9)], "bomber rocket salvo should expand across inner and outer pylons")
	var hunter := {"id":"hunter_rack","type":"hunter"}
	_expect(PlayerMountRules.support_offsets(mounts, "fighter", hunter, 1, false) == [Vector2(-15,-5)], "single fighter Hunter should use one inner pylon")
	_expect(PlayerMountRules.support_offsets(mounts, "fighter", hunter, 1, true) == [Vector2(15,-5)], "alternating single Hunter should switch wing pylon")
	var strategic := {"id":"micro_warhead_rack","type":"hunter","strategic":true}
	_expect(PlayerMountRules.support_offsets(mounts, "fighter", strategic, 1) == [Vector2(0,-7)], "Micro-Warhead should use reinforced strategic centreline bay")

func _test_role_isolation(mounts: Array) -> void:
	_expect(PlayerMountRules.mounts_for_role(mounts, "bomber", "precision_bomb").size() == 1, "precision bombing should have one dedicated ventral strike bay")
	_expect(PlayerMountRules.mounts_for_role(mounts, "fighter", "strategic_store").size() == 1, "strategic store should have one dedicated fighter-compatible bay")
	_expect(PlayerMountRules.mounts_for_role(mounts, "fighter", "emp").size() == 1, "EMP should map to dorsal mission module")
	_expect(PlayerMountRules.mounts_for_role(mounts, "fighter", "bomb").is_empty(), "fighter geometry should not expose bomber outer bomb pylons")

func _test_wiring() -> void:
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('PlayerMountDirector="*res://scripts/player_mount_director.gd"'), "canonical mount catalogue owner should remain autoloaded")
	var cue := FileAccess.open("res://scripts/weapon_mount_cue_director.gd", FileAccess.READ)
	_expect(cue != null, "weapon mount cue should be readable")
	if cue != null:
		var source := cue.get_as_text()
		_expect(source.contains('get_node_or_null("/root/PlayerMountDirector")'), "muzzle cues should consume canonical mount catalogue")
		_expect(source.contains('mounts.call("primary_offsets"'), "muzzle cues should request catalogue primary offsets")
	var schematic := FileAccess.open("res://scripts/loadout_schematic_director.gd", FileAccess.READ)
	_expect(schematic != null, "loadout schematic should be readable")
	if schematic != null:
		_expect(schematic.get_as_text().contains('res://data/player_mounts.json'), "stores schematic should use same authored mount catalogue")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
