extends SceneTree

const SaveRecoveryRules = preload("res://scripts/save_recovery_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var valid := JSON.stringify({"version":3,"credits":100,"mission_index":1,"generator_index":2,"service_hull":83,"service_shield":64})
	var older := JSON.stringify({"version":2,"credits":50,"mission_index":0,"service_hull":90,"service_shield":75})
	var legacy := JSON.stringify({"version":1,"credits":25,"mission_index":0})
	var unsupported := JSON.stringify({"version":99,"credits":999})
	var corrupt := "{not json"
	var parsed := SaveRecoveryRules.parse_supported_json(valid, 1, 3)
	_expect(int(parsed.get("credits", 0)) == 100 and int(parsed.get("generator_index", -1)) == 2, "supported v3 primary JSON should preserve generator progression")
	_expect(SaveRecoveryRules.parse_supported_json(unsupported, 1, 3).is_empty(), "unsupported save version should be rejected")
	_expect(SaveRecoveryRules.parse_supported_json(corrupt, 1, 3).is_empty(), "corrupt JSON should be rejected")
	var primary := SaveRecoveryRules.choose_primary_or_backup(valid, older, 1, 3)
	_expect(str(primary.get("source", "")) == "primary" and int(primary.get("data", {}).get("credits", 0)) == 100, "valid v3 primary should win over backup")
	var backup := SaveRecoveryRules.choose_primary_or_backup(corrupt, older, 1, 3)
	_expect(str(backup.get("source", "")) == "backup" and int(backup.get("data", {}).get("credits", 0)) == 50, "corrupt primary should recover from supported v2 backup")
	var legacy_choice := SaveRecoveryRules.choose_primary_or_backup(corrupt, legacy, 1, 3)
	_expect(str(legacy_choice.get("source", "")) == "backup", "legacy v1 backup should remain migration-compatible")
	var none := SaveRecoveryRules.choose_primary_or_backup(corrupt, unsupported, 1, 3)
	_expect(str(none.get("source", "")) == "none" and none.get("data", {}).is_empty(), "invalid primary and backup should produce no restore state")
	var save_file := FileAccess.open("res://scripts/campaign_save.gd", FileAccess.READ)
	_expect(save_file != null, "campaign_save.gd should be readable for v3 schema checks")
	if save_file != null:
		var source := save_file.get_as_text()
		_expect(source.contains("SAVE_VERSION := 3"), "campaign save should use v3 schema")
		_expect(source.contains('"generator_index"') and source.contains('"service_hull"') and source.contains('"service_shield"'), "v3 snapshot should include generator and serviced airframe state")
		_expect(not source.contains("ServiceDirector"), "campaign persistence must not depend on service reconciliation")
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
