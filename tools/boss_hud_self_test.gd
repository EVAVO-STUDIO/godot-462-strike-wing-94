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
	_expect(BossRules.projectile_hits("gunship_alpha", Vector2(320,115), Vector2(357,115)), "rounds crossing Gunship Alpha's visible wing mass should register")
	_expect(BossRules.projectile_hits("gunship_alpha", Vector2(320,115), Vector2(320,143)), "rounds crossing Gunship Alpha's ventral hull should register")
	_expect(not BossRules.projectile_hits("gunship_alpha", Vector2(320,115), Vector2(362,145)), "transparent Gunship Alpha canvas corners should not become a rectangular hit box")
	_expect(not BossRules.projectile_hits("gunship_alpha", Vector2(320,115), Vector2(366,115)), "rounds outside Gunship Alpha's reviewed silhouette should miss")
	_expect(BossRules.craft_contacts("gunship_alpha", Vector2(320,115), Vector2(373,115), 14.0), "VX-94 contact should register against Gunship Alpha's visible wing before centers overlap")
	_expect(not BossRules.craft_contacts("gunship_alpha", Vector2(320,115), Vector2(378,115), 14.0), "boss contact should still leave a precise escape margin outside both silhouettes")
	var separated := Vector2(320,115) + BossRules.craft_separation_offset("gunship_alpha", Vector2(320,115), Vector2(320,115), 14.0)
	_expect(separated.y > 158.0 and not BossRules.craft_contacts("gunship_alpha", Vector2(320,115), separated, 14.0), "centered boss impact should eject the VX-94 aft beyond both silhouettes")
	var wing_separation := BossRules.craft_separation_offset("gunship_alpha", Vector2(320,115), Vector2(373,115), 14.0)
	_expect(wing_separation.x > 4.0 and wing_separation.x < 6.0 and absf(wing_separation.y) < 0.01, "glancing wing impact should use the minimum lateral separation instead of a generic teleport")
	_expect(BossRules.arrival_clears_enemy("gunship_alpha", {"category":"air"}), "Gunship Alpha should take possession of the air lane for a readable command entrance")
	_expect(not BossRules.arrival_clears_enemy("gunship_alpha", {"category":"ground"}), "ground emplacements should remain active beneath the command entrance")
	_expect(not BossRules.arrival_clears_enemy("armoured_train", {"category":"air"}), "boss-specific arrival staging should not silently erase escorts in unrelated encounters")
	_expect(BossRules.phase_salvo_enabled("gunship_alpha", 1) and BossRules.volley_count("twin_burst", 1) == 3, "Gunship Alpha should open with a conventional three-lane command burst rather than ordinary gunship fire alone")
	_expect(BossRules.volley_spread_radians("twin_burst", 1) >= 0.16 and BossRules.phase_salvo_interval("gunship_alpha", 1) >= 3.0, "opening command burst should be broad, readable, and paced rather than spammed")
	var gunship_origins := BossRules.volley_origins("gunship_alpha", Vector2(320,115), 3)
	_expect(gunship_origins == [Vector2(293,142),Vector2(320,149),Vector2(347,142)], "Gunship Alpha salvos should leave its registered port, ventral and starboard weapon stations")
	_expect(BossRules.volley_origins("gunship_alpha",Vector2(320,115),2) == [Vector2(293,142),Vector2(347,142)], "paired Gunship Alpha salvos should use the two chin stations")
	_expect(BossRules.volley_origins("machine_ark",Vector2(320,150),3) == [Vector2(320,150),Vector2(320,150),Vector2(320,150)], "bosses without reviewed hardpoints should retain safe centered origins")
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
	_expect(main_source.contains("BossRules.projectile_hits") and not main_source.contains("var radius_sq := 420.0 if bool(enemies[enemy_index].get(\"boss\""), "player fire should use authored boss silhouette geometry instead of the obsolete universal center circle")
	_expect(main_source.contains("BossRules.craft_contacts") and main_source.contains("contact_damage_cooldown = 0.55"), "boss ramming should use silhouette contact with a bounded recovery window instead of stacking damage every frame")
	_expect(main_source.contains("BossRules.craft_separation_offset") and main_source.contains("PLAYER_FLIGHT_MAX.y"), "boss impact should visibly separate and re-clamp the VX-94 inside its flight envelope")
	_expect(main_source.contains('enemy["entry_ready"] = position.y >= entry_center_y - 0.01') and main_source.contains('not is_boss or bool(enemy.get("entry_ready", false))'), "bosses should become attack-active only after their complete entrance silhouette is stationed")
	_expect(source.contains('bool(enemy.get("entry_ready", true))'), "integrated boss HUD should reveal only after the command hull clears its entrance lane")
	_expect(main_source.contains("_stage_boss_arrival(current_boss_id)") and main_source.contains("enemy_bullets.clear()") and main_source.contains('status_text = "COMMAND CONTACT // %s"'), "boss arrival should clear stale airborne crossfire and announce command contact before the hull enters")
	_expect(main_source.contains('BossRules.volley_origins("gunship_alpha", origin, 3)') and main_source.contains("boss_origin"), "Gunship Alpha's ordinary command burst should share its registered muzzle stations with phase salvos")
	var boss_director_source := FileAccess.get_file_as_string("res://scripts/boss_director.gd")
	_expect(boss_director_source.contains("BossRules.volley_origins(boss_id, origin, count)") and boss_director_source.contains('"position": shot_origin'), "boss phase salvos should originate from reviewed per-boss hardpoints")
	_expect(boss_director_source.contains('boss["recoil_timer"] = 0.10') and boss_director_source.contains('boss["salvo_station_count"] = station_count'), "boss phase salvos should synchronize their visible recoil and active station count")
	var combat_art_source := FileAccess.get_file_as_string("res://scripts/combat_art_director.gd")
	_expect(combat_art_source.contains('BossRules.volley_origins("gunship_alpha", p, station_count)'), "Gunship Alpha muzzle flashes should share the exact hardpoint registration used by its projectiles")
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
