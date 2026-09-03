extends SceneTree

const CountermeasureRules = preload("res://scripts/countermeasure_rules.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_expect(CountermeasureRules.MAX_CHARGES == 4, "each sortie should carry a limited four-burst countermeasure cassette")
	_expect(CountermeasureRules.can_deploy(1, 0.0) and not CountermeasureRules.can_deploy(0, 0.0) and not CountermeasureRules.can_deploy(2, 0.1), "countermeasure deployment should respect charges and recovery")
	var bullets: Array = [
		{"position":Vector2(100,100), "velocity":Vector2(0,180), "homing":true, "homing_speed":180.0},
		{"position":Vector2(600,100), "velocity":Vector2(0,180), "homing":true, "homing_speed":180.0},
		{"position":Vector2(110,100), "velocity":Vector2(0,180), "homing":false},
	]
	var diverted := CountermeasureRules.divert_missiles(bullets, Vector2(120,220), Vector2(154,294))
	_expect(diverted == 1 and bool(bullets[0].get("countermeasure_decoyed", false)) and not bool(bullets[0].get("homing", true)), "nearby guided threats should commit to the decoy instead of vanishing")
	_expect(bool(bullets[1].get("homing", false)) and not bool(bullets[2].get("countermeasure_decoyed", false)), "distant missiles and ballistic fire should remain unaffected")
	for index in range(4):
		var frame := load("res://assets/runtime/effects/countermeasure/flare_%d.png" % index)
		_expect(frame is Texture2D and frame.get_size() == Vector2(32,40), "countermeasure frame should retain registered geometry: %d" % index)
	var project := FileAccess.get_file_as_string("res://project.godot")
	_expect(project.contains('CountermeasureDirector="*res://scripts/countermeasure_director.gd"'), "countermeasure presentation should be a live project system")
	_expect(FileAccess.file_exists("res://tools/build_countermeasure_art.ps1"), "countermeasure sprites should remain reproducible from governed vector source")
	if failures.is_empty():
		print("HYPERSONIC countermeasure self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
