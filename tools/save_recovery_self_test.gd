extends SceneTree

const SaveRecoveryRules = preload("res://scripts/save_recovery_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var valid := JSON.stringify({"version":5,"credits":100,"mission_index":1,"generator_index":2,"airframe_index":3,"service_hull":133,"service_shield":118,"support_selected":2,"support_unlocked":3})
	var v4 := JSON.stringify({"version":4,"credits":90,"mission_index":1,"generator_index":2,"service_hull":83,"service_shield":64,"support_selected":2,"support_unlocked":3})
	var v3 := JSON.stringify({"version":3,"credits":80,"mission_index":1,"generator_index":1,"service_hull":87,"service_shield":68})
	var v2 := JSON.stringify({"version":2,"credits":50,"mission_index":0,"service_hull":90,"service_shield":75})
	var legacy := JSON.stringify({"version":1,"credits":25,"mission_index":0})
	var unsupported := JSON.stringify({"version":99,"credits":999})
	var corrupt := "{not json"
	var parsed := SaveRecoveryRules.parse_supported_json(valid, 1, 5)
	_expect(int(parsed.get("credits", 0)) == 100 and int(parsed.get("airframe_index", -1)) == 3, "supported v5 JSON should preserve airframe tier")
	_expect(int(parsed.get("support_selected", -1)) == 2 and int(parsed.get("support_unlocked", -1)) == 3, "supported v5 JSON should preserve support loadout")
	_expect(SaveRecoveryRules.parse_supported_json(unsupported, 1, 5).is_empty(), "unsupported save version should be rejected")
	_expect(SaveRecoveryRules.parse_supported_json(corrupt, 1, 5).is_empty(), "corrupt JSON should be rejected")
	var primary := SaveRecoveryRules.choose_primary_or_backup(valid, v4, 1, 5)
	_expect(str(primary.get("source", "")) == "primary" and int(primary.get("data", {}).get("airframe_index", -1)) == 3, "valid v5 primary should win over v4 backup")
	var backup_v4 := SaveRecoveryRules.choose_primary_or_backup(corrupt, v4, 1, 5)
	_expect(str(backup_v4.get("source", "")) == "backup" and int(backup_v4.get("data", {}).get("credits", 0)) == 90, "corrupt primary should recover from supported v4 backup")
	var backup_v3 := SaveRecoveryRules.choose_primary_or_backup(corrupt, v3, 1, 5)
	_expect(str(backup_v3.get("source", "")) == "backup" and int(backup_v3.get("data", {}).get("credits", 0)) == 80, "v3 backup should remain migration-compatible")
	var backup_v2 := SaveRecoveryRules.choose_primary_or_backup(corrupt, v2, 1, 5)
	_expect(str(backup_v2.get("source", "")) == "backup" and int(backup_v2.get("data", {}).get("credits", 0)) == 50, "v2 backup should remain migration-compatible")
	var legacy_choice := SaveRecoveryRules.choose_primary_or_backup(corrupt, legacy, 1, 5)
	_expect(str(legacy_choice.get("source", "")) == "backup", "legacy v1 backup should remain migration-compatible")
	var none := SaveRecoveryRules.choose_primary_or_backup(corrupt, unsupported, 1, 5)
	_expect(str(none.get("source", "")) == "none" and none.get("data", {}).is_empty(), "invalid primary and backup should produce no restore state")
	var save_file := FileAccess.open("res://scripts/campaign_save.gd", FileAccess.READ)
	_expect(save_file != null, "campaign_save.gd should be readable for v5 schema checks")
	if save_file != null:
		var source := save_file.get_as_text()
		_expect(source.contains("SAVE_VERSION := 5"), "campaign save should use v5 schema")
		_expect(source.contains('"generator_index"') and source.contains('"service_hull"') and source.contains('"service_shield"'), "v5 snapshot should retain generator and serviced durability state")
		_expect(source.contains('"airframe_index"'), "v5 snapshot should persist VX-94 airframe tier")
		_expect(source.contains('"support_selected"') and source.contains('"support_unlocked"'), "v5 snapshot should include support selection/unlock state")
		_expect(source.contains("restore_airframe_state"), "v5 restore should restore airframe through public API")
		_expect(source.contains("restore_support_state"), "v5 restore should use public support restore API")
		_expect(source.contains("if _capture_mode():"), "deterministic visual captures must not restore or mutate campaign saves")
	if failures.is_empty():
		print("Strike Wing save recovery self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
