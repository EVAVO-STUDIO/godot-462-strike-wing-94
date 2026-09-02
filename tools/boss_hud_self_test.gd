extends SceneTree

const BossRules = preload("res://scripts/boss_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_expect(BossRules.phase_for(100, 100) == 1, "full-health boss should begin in phase one")
	_expect(BossRules.phase_for(50, 100) == 2, "damaged boss should expose phase two")
	_expect(BossRules.phase_for(20, 100) == 3, "critical boss should expose phase three")
	_expect(is_equal_approx(BossRules.entry_center_y("gunship_alpha"), 115.0), "Gunship Alpha should clear the integrated HUD with its full 78-pixel silhouette")
	_expect(is_equal_approx(BossRules.entry_center_y("missile_cruiser"), 153.0), "tall naval command hulls should derive a deeper entry center from their reviewed canvas")
	_expect(BossRules.entry_center_y("machine_ark") > BossRules.entry_center_y("gunship_alpha"), "larger late bosses should reserve proportionally more HUD clearance")
	_expect(BossRules.arrival_clears_enemy("gunship_alpha", {"category":"air"}), "Gunship Alpha should take possession of the air lane for a readable command entrance")
	_expect(not BossRules.arrival_clears_enemy("gunship_alpha", {"category":"ground"}), "ground emplacements should remain active beneath the command entrance")
	_expect(not BossRules.arrival_clears_enemy("armoured_train", {"category":"air"}), "boss-specific arrival staging should not silently erase escorts in unrelated encounters")
	_expect(BossRules.phase_salvo_enabled("gunship_alpha", 1) and BossRules.volley_count("twin_burst", 1) == 3, "Gunship Alpha should open with a conventional three-lane command burst rather than ordinary gunship fire alone")
	_expect(BossRules.volley_spread_radians("twin_burst", 1) >= 0.16 and BossRules.phase_salvo_interval("gunship_alpha", 1) >= 3.0, "opening command burst should be broad, readable, and paced rather than spammed")
	_expect(not BossRules.phase_salvo_enabled("armoured_train", 1), "unreviewed phase-one bosses should retain their authored opening pressure")
	for phase_name in ["phase_1", "phase_2", "phase_3"]:
		var frame := load("res://assets/runtime/ui/hud/boss_phase_bar/%s.png" % phase_name)
		var fill := load("res://assets/runtime/ui/hud/boss_phase_bar/%s_fill.png" % phase_name)
		_expect(frame is Texture2D and frame.get_size() == Vector2(388, 28), "%s frame should retain reviewed HUD geometry" % phase_name)
		_expect(fill is Texture2D and fill.get_size() == Vector2(352, 5), "%s fill should retain reviewed HUD geometry" % phase_name)
	var source := FileAccess.get_file_as_string("res://scripts/pixel_ui_director.gd")
	_expect(source.contains("func _draw_boss") and source.contains("HUD_BOSS_PHASE_FRAMES") and source.contains("HUD_BOSS_PHASE_FILLS"), "live pixel UI should own the authored boss HUD")
	_expect(source.contains('boss.get("boss_phase", BossRules.phase_for') and source.contains('cue := " WEAK" if phase >= 3'), "boss HUD should expose authoritative phase and critical weak-point state")
	_expect(source.contains('replace("_", " ")') and source.contains('P%d%s  %d/%d'), "boss HUD should show readable identity, phase, and exact integrity")
	_expect(source.contains('clampf(float(hp) / float(max_hp), 0.0, 1.0)'), "boss integrity fill should remain safely clamped")
	_expect(not FileAccess.file_exists("res://scripts/boss_hud_rules.gd") and not FileAccess.file_exists("res://scripts/boss_hud_director.gd"), "obsolete competing boss HUD owners should remain removed")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main_source.contains('BossRules.entry_center_y(str(archetype.get("id", "")))') and main_source.contains("position.y = minf(position.y, entry_center_y)"), "boss spawning and entry movement should consume the canvas-aware HUD clearance without overshoot")
	_expect(main_source.contains('enemy["entry_ready"] = position.y >= entry_center_y - 0.01') and main_source.contains('not is_boss or bool(enemy.get("entry_ready", false))'), "bosses should become attack-active only after their complete entrance silhouette is stationed")
	_expect(source.contains('bool(enemy.get("entry_ready", true))'), "integrated boss HUD should reveal only after the command hull clears its entrance lane")
	_expect(main_source.contains("_stage_boss_arrival(current_boss_id)") and main_source.contains("enemy_bullets.clear()") and main_source.contains('status_text = "COMMAND CONTACT // %s"'), "boss arrival should clear stale airborne crossfire and announce command contact before the hull enters")
	if failures.is_empty():
		print("HYPERSONIC integrated boss HUD self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
