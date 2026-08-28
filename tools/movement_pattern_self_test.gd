extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/enemies.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "enemy catalogue should load")
	var enemies: Array = data.get("enemies", []) if typeof(data) == TYPE_DICTIONARY else []
	var seen: Dictionary = {}
	for enemy in enemies:
		if bool(enemy.get("boss", false)):
			continue
		var pattern := str(enemy.get("pattern", ""))
		seen[pattern] = true
		_expect(pattern in MovementPatternRules.supported_patterns(), "unsupported authored pattern: %s" % pattern)
	for required in ["sine_dive", "tracking_sweep", "hover_strafe", "road_column", "water_lane", "static", "aggressive_weave"]:
		_expect(seen.has(required), "expected authored movement pattern: %s" % required)
	var base := Vector2(200, 100)
	var player := Vector2(400, 200)
	_expect(MovementPatternRules.adjusted_position("tracking_sweep", base, player, 1.0, 1.0, 200.0).x > base.x, "tracking sweep should move toward player x")
	_expect(MovementPatternRules.adjusted_position("hover_strafe", base, player, 1.0, 1.0, 200.0).y < base.y, "hover strafe should resist downward travel")
	_expect(MovementPatternRules.adjusted_position("road_column", Vector2(240,100), player, 1.0, 1.0, 200.0).x < 240.0, "road column should return toward lane anchor")
	_expect(MovementPatternRules.adjusted_position("static", Vector2(240,100), player, 1.0, 1.0, 200.0).x == 200.0, "static emplacement should lock to anchor")
	var clamped := MovementPatternRules.clamp_x(Vector2(999, 100), 36.0, 604.0)
	_expect(clamped.x == 604.0, "movement clamp should keep enemies inside playfield")
	if failures.is_empty():
		print("Strike Wing movement pattern self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
