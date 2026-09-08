extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var script := load("res://scripts/progression_cost_director.gd") as Script
	_expect(script != null, "progression cost director should load")
	if script == null:
		_finish()
		return
	var director: Node = script.new()

	var max_tag: Dictionary = director.call("_purchase_tag", {}, "advanced_conventional", 99999)
	_expect(str(max_tag.get("text", "")) == "MAX", "empty next tier should read MAX")

	var first_weapon := {"cost":2600,"unlock_tech_era":"advanced_conventional"}
	var short_wallet: Dictionary = director.call("_purchase_tag", first_weapon, "advanced_conventional", 2500)
	_expect(str(short_wallet.get("text", "")) == ">002600" and str(short_wallet.get("tone", "")) == "price", "unaffordable legal tier should expose exact price")
	var ready_wallet: Dictionary = director.call("_purchase_tag", first_weapon, "advanced_conventional", 2600)
	_expect(str(ready_wallet.get("tone", "")) == "ready", "affordable legal tier should receive ready tone")

	var em_item := {"cost":4800,"unlock_tech_era":"electromagnetic"}
	var locked: Dictionary = director.call("_purchase_tag", em_item, "advanced_conventional", 99999)
	_expect(str(locked.get("text", "")) == "LOCK EM", "tech-locked tier should explain its required era instead of pretending credits are the blocker")
	var unlocked: Dictionary = director.call("_purchase_tag", em_item, "electromagnetic", 4800)
	_expect(str(unlocked.get("text", "")) == ">004800" and str(unlocked.get("tone", "")) == "ready", "matching tech era should expose the real price")

	var catalog := [
		{"id":"base","cost":0},
		{"id":"tier1","cost":2600},
		{"id":"tier2","cost":4800}
	]
	_expect(str((director.call("_next_catalog_item", catalog, 0) as Dictionary).get("id", "")) == "tier1", "overlay should show the actually next sequential tier")
	_expect(str((director.call("_next_catalog_item", catalog, 1) as Dictionary).get("id", "")) == "tier2", "overlay should advance with owned tier")
	_expect((director.call("_next_catalog_item", catalog, 2) as Dictionary).is_empty(), "last owned tier should have no phantom purchase")

	director.free()
	var source := FileAccess.get_file_as_string("res://scripts/progression_cost_director.gd")
	_expect(source.contains("layer = 31"), "progression prices should layer immediately above the existing pixel UI")
	_expect(source.contains("Vector2(340, 224)") and source.contains("Vector2(340, 269)"), "all four progression rows should receive compact price/lock tags")
	_expect(source.contains("repair_cost_per_hull") and source.contains("shield_recharge_cost_per_point"), "readiness rows should expose the authoritative service liabilities")
	_expect(source.contains('str(scene.get("game_mode")) != "campaign"'), "fixed non-campaign modes should not advertise campaign purchases")
	_expect(FileAccess.get_file_as_string("res://project.godot").contains('ProgressionCostDirector="*res://scripts/progression_cost_director.gd"'), "progression cost overlay should remain mounted as a project service")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("HYPERSONIC progression cost overlay self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
