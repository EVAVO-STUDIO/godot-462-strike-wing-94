extends SceneTree

const HypersonicRules = preload("res://scripts/hypersonic_rules.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_expect(HypersonicRules.can_charge("fighter", false, 1.0), "fighter should enter the hypersonic envelope")
	_expect(not HypersonicRules.can_charge("bomber", false, 1.0), "deployed bomber geometry must not enter hypersonic flight")
	_expect(HypersonicRules.charge_seconds("high") < HypersonicRules.charge_seconds("low"), "thin-air high-altitude transition should be safer and faster")
	_expect(HypersonicRules.structural_damage_per_second("low") > HypersonicRules.structural_damage_per_second("mid"), "low hypersonic flight should carry severe airframe risk")
	_expect(HypersonicRules.structural_damage_per_second("high") == 0.0, "high altitude should be the intended hypersonic corridor")
	_expect(HypersonicRules.enemy_can_pursue({"class":"air","hypersonic_capable":true}), "authored interceptor should be able to pursue")
	_expect(HypersonicRules.SPEED_MULTIPLIER == 3.40, "latched hypersonic flight should accelerate the layered world massively")
	_expect(HypersonicRules.ENTRY_ACCEL_SECONDS < HypersonicRules.EXIT_DECEL_SECONDS and HypersonicRules.EXIT_DECEL_SECONDS < 0.75, "Mach entry should hit decisively while exit recovers smoothly within arcade timing")
	_expect(HypersonicRules.enemy_pursuit_ratio(HypersonicRules.ENEMY_CHARGE_SECONDS) == 1.0, "enemy pursuit wings should finish sweeping before speed latches")
	_expect(not HypersonicRules.enemy_can_pursue({"class":"ground","hypersonic_capable":true}), "surface targets cannot join pursuit")
	var art_source := FileAccess.get_file_as_string("res://scripts/combat_art_director.gd")
	_expect(art_source.contains("HYPERSONIC_PURSUER_TRANSFORMS") and art_source.contains("pursuit_%02d.png"), "all capable pursuit aircraft should use registered ten-exposure transformation art")
	_expect(not art_source.contains("hull.get_width() * lerpf(1.0, 0.62, ratio)"), "enemy hypersonic transformation must never squash a flat hull sprite")
	_expect(art_source.contains('engine_anchor := p+Vector2(0,-hull.get_height()*0.30)') and art_source.contains('draw_set_transform(engine_anchor.round(),PI'), "enemy pursuit exhaust should project aft toward the top of the screen rather than through the aircraft nose")
	_expect(art_source.contains('_render_airframe_shadow(surface,p,hull,enemy_id)') and art_source.find('_render_airframe_shadow(surface,p,hull,enemy_id)') < art_source.find('surface.draw_texture(hull, (p-hull.get_size()*0.5).round())'), "folded pursuers should retain their altitude-aware silhouette shadow beneath the selected transform exposure")
	_expect(art_source.contains('frame_for_ratio("hypersonic_ignition",boom_age/0.16)') and art_source.contains('_draw_enemy_damage_attachments(surface,p,enemy,"air"'), "enemy pursuit latch should preserve authored ignition and damage-state continuity")
	_expect(art_source.contains('["ace_interceptor", "drone_hunter", "phase_interceptor"]'), "all three pursuit families should expose paired forward firing cues while folded")
	for enemy_id in ["ace_interceptor", "drone_hunter", "phase_interceptor"]:
		for frame in range(10):
			var path := "res://assets/runtime/enemies/hypersonic_pursuit/%s/pursuit_%02d.png" % [enemy_id,frame]
			var texture := load(path)
			_expect(texture is Texture2D, "%s pursuit exposure %02d should import as transparent runtime art" % [enemy_id,frame])
	var director_file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	var director_source := director_file.get_as_text() if director_file != null else ""
	_expect(director_source.contains('"--capture-flight=hypersonic"') and director_source.contains("_capture_hypersonic"), "hypersonic presentation should expose a deterministic visual QA fixture")
	_expect(director_source.contains("lerpf(1.0, HypersonicRules.SPEED_MULTIPLIER, hypersonic_speed_ratio())"), "visual QA and live flight should share progressive Mach entry and recovery speed")
	_expect(director_source.contains("MACH RECOVERY // CONTROL AUTHORITY RETURNING") and director_source.contains("EXIT_DECEL_SECONDS"), "afterburner release should announce and time a bounded Mach-recovery state")
	_expect(director_source.contains("lerpf(1.0, full_boost, speed_ratio)") and director_source.contains("TURN_SCALE, speed_ratio"), "Mach recovery should restore propulsion and control authority through the same continuous ratio")
	_expect(director_source.contains("AltitudeRules.BANDS.duplicate()") and director_source.contains('"%s LIMIT"') and director_source.contains('"CLIMB" if direction > 0 else "DESCENT"'), "latched hypersonic flight should permit bounded emergency climb and dive")
	_expect(director_source.contains('scene.call("_apply_structural_damage", whole_damage)') and not director_source.contains('maxi(1, int(scene.get("hull"))'), "hypersonic overload must be able to destroy the airframe instead of secretly clamping hull at one")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := main_file.get_as_text() if main_file != null else ""
	_expect(main_source.contains("func _apply_structural_damage(amount: int)") and main_source.contains("damage_taken += applied"), "structural overload should use an explicit hull-only damage path with sortie accounting")
	_expect(main_source.contains('status_text = "AIRFRAME BREAKUP // OVERSPEED"') and main_source.contains("player_loss_timer = PLAYER_LOSS_SEQUENCE_SECONDS"), "fatal overspeed should enter the authored player-loss sequence")
	if failures.is_empty():
		print("Hypersonic rules self-test passed.")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
