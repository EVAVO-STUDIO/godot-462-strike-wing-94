extends SceneTree

const SaveRecoveryRules = preload("res://scripts/save_recovery_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var valid := JSON.stringify({"version":2,"credits":100,"mission_index":1})
	var older := JSON.stringify({"version":1,"credits":50,"mission_index":0})
	var unsupported := JSON.stringify({"version":99,"credits":999})
	var corrupt := "{not json"
	_expect(int(SaveRecoveryRules.parse_supported_json(valid, 1, 2).get("credits", 0)) == 100, "supported primary JSON should parse")
	_expect(SaveRecoveryRules.parse_supported_json(unsupported, 1, 2).is_empty(), "unsupported save version should be rejected")
	_expect(SaveRecoveryRules.parse_supported_json(corrupt, 1, 2).is_empty(), "corrupt JSON should be rejected")
	var primary := SaveRecoveryRules.choose_primary_or_backup(valid, older, 1, 2)
	_expect(str(primary.get("source", "")) == "primary" and int(primary.get("data", {}).get("credits", 0)) == 100, "valid primary should win over backup")
	var backup := SaveRecoveryRules.choose_primary_or_backup(corrupt, older, 1, 2)
	_expect(str(backup.get("source", "")) == "backup" and int(backup.get("data", {}).get("credits", 0)) == 50, "corrupt primary should recover from supported backup")
	var none := SaveRecoveryRules.choose_primary_or_backup(corrupt, unsupported, 1, 2)
	_expect(str(none.get("source", "")) == "none" and none.get("data", {}).is_empty(), "invalid primary and backup should produce no restore state")
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
