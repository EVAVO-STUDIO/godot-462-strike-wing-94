extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var credits := root.get_node_or_null("CreditsDirector")
	_expect(credits != null, "credits director autoload should exist", failures)
	var data := _load_json("res://data/credits.json")
	var pages: Array = data.get("pages", [])
	_expect(pages.size() == 6, "credits should contain six authored held pages", failures)
	var plate_ids: Dictionary = {}
	for page in pages:
		_expect(typeof(page) == TYPE_DICTIONARY, "each credits page should be a dictionary", failures)
		if typeof(page) != TYPE_DICTIONARY:
			continue
		_expect(not str(page.get("heading", "")).is_empty(), "each credits page should have a heading", failures)
		_expect(page.get("lines", []).size() >= 1, "each credits page should have at least one credit line", failures)
		_expect(float(page.get("duration", 0.0)) >= 4.0, "credits pages should use readable held timing", failures)
		plate_ids[str(page.get("plate", ""))] = true
	_expect(plate_ids.size() >= 5, "credits should reuse the full authored epilogue visual arc", failures)
	_expect(FileAccess.file_exists("res://assets/source/ui/credits/credits_manifest.json"), "credits art manifest should exist", failures)
	_expect(FileAccess.file_exists("res://tools/build_credits_art.ps1"), "credits frame should be deterministically rebuildable", failures)
	var frame := load("res://assets/runtime/ui/credits/credits_frame.png") as Texture2D
	_expect(frame != null and frame.get_size() == Vector2(608,312), "credits frame should retain its registered 608x312 canvas", failures)
	var director_file := FileAccess.open("res://scripts/credits_director.gd",FileAccess.READ)
	var source := director_file.get_as_text() if director_file != null else ""
	_expect(source.contains("--capture-credits") and source.contains("ENTER ADVANCE   ESC SKIP"), "credits should expose deterministic capture and player-controlled pacing", failures)
	_expect(source.contains("_return_to_front_door") and source.contains('front_end_screen","main_menu"'), "credits completion should return to the main menu", failures)
	var cinematic_file := FileAccess.open("res://scripts/campaign_cinematic_director.gd",FileAccess.READ)
	var cinematic_source := cinematic_file.get_as_text() if cinematic_file != null else ""
	_expect(cinematic_source.contains('was_campaign_ending') and cinematic_source.contains('/root/CreditsDirector'), "Machine Ark epilogue should hand off directly to credits", failures)
	var main_file := FileAccess.open("res://scripts/main.gd",FileAccess.READ)
	var main_source := main_file.get_as_text() if main_file != null else ""
	_expect(main_source.contains("_credits_blocking()"), "mission result flow should remain blocked while credits are active", failures)
	if credits != null:
		credits.call("begin")
		_expect(bool(credits.call("credits_active")), "credits should become active when begun", failures)
		credits.call("finish")
		_expect(not bool(credits.call("credits_active")), "credits should become inactive when finished", failures)
	if failures.is_empty():
		print("HYPERSONIC credits self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
