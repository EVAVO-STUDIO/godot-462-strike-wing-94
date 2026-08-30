extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatArtDirector = preload("res://scripts/combat_art_director.gd")
const CombatFxDirector = preload("res://scripts/combat_fx_director.gd")
const DamageStateDirector = preload("res://scripts/damage_state_director.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_wiring()
	_test_visual_language()
	_test_transform_presentation()
	_test_altitude_presentation()
	_test_late_boss_silhouettes()
	_test_airframe_cues()
	_test_combat_fx()
	_test_projectile_art()
	_test_impact_art()
	_test_persistent_effect_art()
	_test_damage_state()
	_test_mount_map()
	if failures.is_empty():
		print("Strike Wing combat art self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_wiring() -> void:
	var director := CombatArtDirector.new()
	_expect(director != null, "CombatArtDirector should instantiate")
	director.free()
	var fx := CombatFxDirector.new()
	_expect(fx != null, "CombatFxDirector should instantiate")
	fx.free()
	var damage := DamageStateDirector.new()
	_expect(damage != null, "DamageStateDirector should instantiate")
	damage.free()
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		var source := project.get_as_text()
		_expect(source.contains('CombatArtDirector="*res://scripts/combat_art_director.gd"'), "combat art presentation should remain autoloaded")
		_expect(source.contains('AirframeCueDirector="*res://scripts/airframe_cue_director.gd"'), "airframe progression cues should remain autoloaded")
		_expect(source.contains('AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"'), "altitude transitions should retain dedicated presentation")
		_expect(source.contains('CombatFxDirector="*res://scripts/combat_fx_director.gd"'), "combat impact feedback should remain autoloaded")
		_expect(source.contains('DamageStateDirector="*res://scripts/damage_state_director.gd"'), "VX-94 progressive damage presentation should remain autoloaded")
		_expect(source.contains('LoadoutSchematicDirector="*res://scripts/loadout_schematic_director.gd"'), "VX-94 stores schematic should remain autoloaded")

func _test_visual_language() -> void:
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("VX94_GAMEPLAY_FORMS") and source.contains("VX94_FIGHTER_BANK") and source.contains("VX94_BOMBER_BANK"), "live VX-94 should use authored form and bank sprites")
	_expect(source.contains("VX94_EXHAUST") and source.contains("VX94_DAMAGE"), "live VX-94 should use authored thrust and damage overlays")
	for frame_path in ["vx94_fighter_v1.png", "vx94_transform_01.png", "vx94_transform_02.png", "vx94_transform_03.png", "vx94_bomber_v1.png"]:
		var gameplay_form := load("res://assets/runtime/craft/vx94/gameplay/%s" % frame_path)
		_expect(gameplay_form is Texture2D and gameplay_form.get_size() == Vector2(48,54), "VX-94 gameplay form should retain native 48x54 geometry: %s" % frame_path)
	for bank_path in ["fighter_left.png", "fighter_neutral.png", "fighter_right.png", "bomber_left.png", "bomber_neutral.png", "bomber_right.png"]:
		var bank_frame := load("res://assets/runtime/craft/vx94/gameplay/bank/%s" % bank_path)
		_expect(bank_frame is Texture2D and bank_frame.get_size() == Vector2(48,54), "VX-94 bank frame should retain native 48x54 geometry: %s" % bank_path)
	_expect(source.contains("PLAYER_GLASS"), "VX-94 should retain visible cockpit-glass language")
	_expect(source.contains("PLAYER_ENGINE"), "VX-94 should retain visible engine/hardpoint accents")
	_expect(source.contains("has_production_art") and source.contains("_report_missing_art"), "unregistered enemies should fail explicitly instead of receiving generic vector silhouettes")
	_expect(not source.contains("func _draw_ground") and not source.contains("func _draw_sea") and not source.contains("func _draw_air") and not source.contains("func _draw_autonomous"), "obsolete generic enemy silhouette fallbacks should remain removed")
	var enemy_catalog = ContentCatalog.load_json("res://data/enemies.json")
	_expect(typeof(enemy_catalog) == TYPE_DICTIONARY, "enemy catalogue should load for production-art coverage")
	if typeof(enemy_catalog) == TYPE_DICTIONARY:
		for enemy in enemy_catalog.get("enemies", []):
			if typeof(enemy) == TYPE_DICTIONARY:
				var enemy_id := str(enemy.get("id", ""))
				_expect(CombatArtDirector.has_production_art(enemy_id), "canonical enemy is missing production sprite coverage: %s" % enemy_id)
	_expect(source.contains("MERCENARY_AIR_SPRITES") and source.contains("MERCENARY_GROUND_SPRITES") and source.contains("LAYERED_GROUND_SPRITES") and source.contains("MERCENARY_SEA_SPRITES") and source.contains("MACHINE_AIR_SPRITES") and source.contains("MACHINE_GROUND_SPRITES") and source.contains("ORBITAL_AIR_SPRITES") and source.contains("MERCENARY_BOSS_SPRITES") and source.contains("MACHINE_BOSS_SPRITES") and source.contains("ORBITAL_BOSS_SPRITES") and source.contains("func _draw_production_sprite"), "reviewed units should use production sprite assets")
	_expect(source.contains("func _draw_layered_ground") and source.contains("Vector2.DOWN.angle_to") and source.contains("recoil_timer"), "layered emplacements should track targets and recoil around registered pivots")
	_expect(source.contains("MACHINE_AIR_SPRITES") and source.contains("MACHINE_GROUND_SPRITES") and source.contains("ORBITAL_AIR_SPRITES"), "autonomous machines should retain their own authored visual families")
	_expect(source.contains("AI_CORE"), "autonomous enemies should expose readable machine-core accents")
	_expect(source.contains("_draw_production_boss") and source.contains("BOSS_PHASE_OVERLAYS"), "boss-scale enemies should retain dedicated production presentation")
	_expect(source.contains("layer = 12"), "combat art should remain below tactical ordnance/HUD layers")
	for forbidden in ["Label.new()", "PanelContainer.new()", "ProgressBar.new()"]:
		_expect(not source.contains(forbidden), "combat art must remain hard-edged canvas drawing: %s" % forbidden)
	var expected_sizes := {
		"scout_falcon": Vector2(28,30),
		"gunship_mk1": Vector2(42,38),
		"attack_chopper": Vector2(42,38),
		"ace_interceptor": Vector2(32,34),
		"heavy_bomber": Vector2(50,42),
	}
	for enemy_id in expected_sizes:
		var texture := load("res://assets/runtime/enemies/mercenary_air/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == expected_sizes[enemy_id], "production sprite should retain reviewed geometry: %s" % enemy_id)
	for frame_index in range(4):
		var rotor_frame := load("res://assets/runtime/enemies/unit_animation/attack_chopper/rotor_%d.png" % frame_index)
		_expect(rotor_frame is Texture2D and rotor_frame.get_size() == Vector2(42,38), "attack-chopper rotor frame should retain registered 42x38 geometry: %d" % frame_index)
	_expect(source.contains("UNIT_ANIMATION_FRAMES") and source.contains("func _draw_animated_unit") and source.contains('float(animation["fps"])'), "ordinary production units should support deliberate per-family low-frame-rate animation")
	var ground_sizes := {
		"light_tank": Vector2(30,24),
		"sam_truck": Vector2(34,26),
		"fortified_turret": Vector2(28,28),
		"coastal_flak": Vector2(28,28),
		"armoured_aa_carrier": Vector2(38,30),
	}
	for enemy_id in ground_sizes:
		var texture := load("res://assets/runtime/enemies/mercenary_ground/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == ground_sizes[enemy_id], "ground production sprite should retain reviewed geometry: %s" % enemy_id)
	for layer_path in ["fort_base", "fort_weapon", "fort_barrel", "fort_damage", "flak_base", "flak_weapon", "flak_barrel", "flak_damage"]:
		var layer_texture := load("res://assets/runtime/enemies/mercenary_ground_layered/%s.png" % layer_path)
		_expect(layer_texture is Texture2D and layer_texture.get_size() == Vector2(28,28), "registered emplacement layer should retain 28x28 canvas: %s" % layer_path)
	_expect(source.contains('float(enemy.get("hp", max_hp)) / max_hp <= 0.55'), "layered emplacements should reveal physical damage from real hull ratio")
	var ground_force_sizes := {
		"mercenary_infantry/mercenary_rifle_team": Vector2(26,22),
		"mercenary_infantry/mercenary_heavy_team": Vector2(30,26),
		"ground_mechs/security_patrol_mech": Vector2(38,42),
		"ground_mechs/autonomous_salvage_mech": Vector2(44,42),
	}
	for ground_force_path in ground_force_sizes:
		var force_texture := load("res://assets/runtime/enemies/%s_idle.png" % ground_force_path)
		_expect(force_texture is Texture2D and force_texture.get_size() == ground_force_sizes[ground_force_path], "ground-force identity should retain reviewed geometry: %s" % ground_force_path)
	var mech_animation_sizes := {
		"security_patrol_mech": Vector2(38,42),
		"autonomous_salvage_mech": Vector2(44,42),
	}
	for mech_id in mech_animation_sizes:
		for frame_index in range(4):
			var walk_frame := load("res://assets/runtime/enemies/unit_animation/%s/walk_%d.png" % [mech_id, frame_index])
			_expect(walk_frame is Texture2D and walk_frame.get_size() == mech_animation_sizes[mech_id], "ground-mech gait frame should retain registered geometry: %s/%d" % [mech_id, frame_index])
	var infantry_animation_sizes := {
		"mercenary_rifle_team": Vector2(26,22),
		"mercenary_heavy_team": Vector2(30,26),
	}
	for team_id in infantry_animation_sizes:
		for frame_index in range(4):
			var advance_frame := load("res://assets/runtime/enemies/unit_animation/%s/advance_%d.png" % [team_id, frame_index])
			_expect(advance_frame is Texture2D and advance_frame.get_size() == infantry_animation_sizes[team_id], "infantry advance frame should retain registered geometry: %s/%d" % [team_id, frame_index])
	var sea_sizes := {
		"river_patrol": Vector2(30,44),
		"torpedo_boat": Vector2(34,48),
		"fast_attack_craft": Vector2(36,50),
		"missile_corvette": Vector2(50,66),
	}
	for enemy_id in sea_sizes:
		var texture := load("res://assets/runtime/enemies/mercenary_sea/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == sea_sizes[enemy_id], "sea production sprite should retain reviewed geometry: %s" % enemy_id)
	for frame_index in range(4):
		var wake_frame := load("res://assets/runtime/effects/naval_wake/%d.png" % frame_index)
		_expect(wake_frame is Texture2D and wake_frame.get_size() == Vector2(32,40), "naval wake frame should retain registered 32x40 geometry: %d" % frame_index)
	_expect(source.contains("NAVAL_WAKE_FRAMES") and source.contains("func _draw_naval_unit") and source.contains("* 8.0"), "naval production sprites should carry a restrained eight-fps authored wake cycle")
	_expect(FileAccess.file_exists("res://assets/source/effects/naval_wake/naval_wake_asset_manifest.json"), "naval wake source/runtime manifest should exist")
	var machine_air_sizes := {
		"drone_scout": Vector2(24,26),
		"drone_hunter": Vector2(30,30),
		"drone_bomber": Vector2(44,38),
		"drone_missile_node": Vector2(38,36),
	}
	for enemy_id in machine_air_sizes:
		var texture := load("res://assets/runtime/enemies/machine_air/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == machine_air_sizes[enemy_id], "machine-air sprite should retain reviewed geometry: %s" % enemy_id)
	var pursuit_animation_sizes := {
		"ace_interceptor": Vector2(32,34),
		"drone_hunter": Vector2(30,30),
		"phase_interceptor": Vector2(34,34),
	}
	for pursuit_id in pursuit_animation_sizes:
		for frame_index in range(4):
			var thrust_frame := load("res://assets/runtime/enemies/unit_animation/%s/thrust_%d.png" % [pursuit_id, frame_index])
			_expect(thrust_frame is Texture2D and thrust_frame.get_size() == pursuit_animation_sizes[pursuit_id], "hypersonic-pursuit thrust frame should retain registered geometry: %s/%d" % [pursuit_id, frame_index])
	var machine_ground_sizes := {
		"autonomous_armor": Vector2(36,30),
		"factory_defence_node": Vector2(34,34),
	}
	for enemy_id in machine_ground_sizes:
		var texture := load("res://assets/runtime/enemies/machine_ground/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == machine_ground_sizes[enemy_id], "machine-ground sprite should retain reviewed geometry: %s" % enemy_id)
	var machine_ground_layers := {
		"autonomous_armor_base": Vector2(36,30),
		"autonomous_armor_weapon": Vector2(36,36),
		"factory_defence_base": Vector2(34,34),
		"factory_defence_weapon": Vector2(34,38),
	}
	for layer_id in machine_ground_layers:
		var layer_texture := load("res://assets/runtime/enemies/machine_ground_layered/%s.png" % layer_id)
		_expect(layer_texture is Texture2D and layer_texture.get_size() == machine_ground_layers[layer_id], "machine-ground articulated layer should retain registered geometry: %s" % layer_id)
	_expect(source.contains("LAYERED_MACHINE_GROUND_SPRITES"), "autonomous armor and factory nodes should use separately articulated production layers")
	_expect(source.contains('layers.get("core_pulse", false)'), "machine-ground protected cores should retain restrained age-driven pulse animation")
	var orbital_air_sizes := {
		"exo_drone": Vector2(30,30),
		"orbital_sentry": Vector2(40,38),
		"phase_interceptor": Vector2(34,34),
		"beam_sentry": Vector2(42,40),
		"orbital_lancer": Vector2(48,58),
	}
	for enemy_id in orbital_air_sizes:
		var texture := load("res://assets/runtime/enemies/orbital_air/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == orbital_air_sizes[enemy_id], "orbital-air sprite should retain reviewed geometry: %s" % enemy_id)
	var mercenary_boss_sizes := {
		"gunship_alpha": Vector2(94,78),
		"armoured_train": Vector2(78,150),
		"missile_cruiser": Vector2(92,154),
	}
	for enemy_id in mercenary_boss_sizes:
		var texture := load("res://assets/runtime/enemies/mercenary_boss/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == mercenary_boss_sizes[enemy_id], "mercenary boss sprite should retain reviewed geometry: %s" % enemy_id)
	for boss_id in mercenary_boss_sizes:
		for overlay_name in ["phase_2_damage", "phase_3_damage", "critical_0", "critical_1", "critical_2", "critical_3"]:
			var overlay := load("res://assets/runtime/enemies/boss_animation/%s/%s.png" % [boss_id, overlay_name])
			_expect(overlay is Texture2D and overlay.get_size() == mercenary_boss_sizes[boss_id], "mercenary boss phase overlay should retain its registered canvas: %s/%s" % [boss_id, overlay_name])
	_expect(source.contains("BOSS_PHASE_OVERLAYS") and source.contains('enemy.get("boss_phase", 1)') and source.contains('enemy.get("age", 0.0)') and source.contains("* 8.0"), "production bosses should use canonical boss phase and age-driven critical animation")
	var machine_boss_sizes := {
		"swarm_controller": Vector2(106,88),
		"ai_forge_core": Vector2(112,112),
	}
	for enemy_id in machine_boss_sizes:
		var texture := load("res://assets/runtime/enemies/machine_boss/%s_idle_v2.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == machine_boss_sizes[enemy_id], "machine boss sprite should retain reviewed geometry: %s" % enemy_id)
		for overlay_name in ["phase_2_damage", "phase_3_damage", "critical_0", "critical_1", "critical_2", "critical_3"]:
			var overlay := load("res://assets/runtime/enemies/boss_animation/%s/%s.png" % [enemy_id, overlay_name])
			_expect(overlay is Texture2D and overlay.get_size() == machine_boss_sizes[enemy_id], "machine boss phase overlay should retain its registered canvas: %s/%s" % [enemy_id, overlay_name])
	var orbital_boss_sizes := {
		"orbital_command_node": Vector2(124,104),
		"phase_control_array": Vector2(126,126),
		"station_warden": Vector2(146,116),
		"machine_ark": Vector2(160,128),
	}
	for enemy_id in orbital_boss_sizes:
		var suffix := "_idle_v2.png" if enemy_id in ["orbital_command_node", "phase_control_array"] else "_idle.png"
		var texture := load("res://assets/runtime/enemies/orbital_boss/%s%s" % [enemy_id, suffix])
		_expect(texture is Texture2D and texture.get_size() == orbital_boss_sizes[enemy_id], "orbital boss sprite should retain reviewed geometry: %s" % enemy_id)
		for overlay_name in ["phase_2_damage", "phase_3_damage", "critical_0", "critical_1", "critical_2", "critical_3"]:
			var overlay := load("res://assets/runtime/enemies/boss_animation/%s/%s.png" % [enemy_id, overlay_name])
			_expect(overlay is Texture2D and overlay.get_size() == orbital_boss_sizes[enemy_id], "orbital boss phase overlay should retain its registered canvas: %s/%s" % [enemy_id, overlay_name])

func _test_transform_presentation() -> void:
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable for transform checks")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("TRANSFORM_VISUAL_SECONDS := 0.42"), "variable geometry sweep should remain visibly mechanical")
	_expect(source.contains("_visual_sweep = move_toward"), "visual wing geometry should interpolate rather than snap")
	_expect(source.contains("VX94_GAMEPLAY_FORMS[form_index]"), "variable geometry should advance through the authored mechanical keyframes")
	_expect(source.contains("vx94_transform_01.png") and source.contains("vx94_transform_02.png") and source.contains("vx94_transform_03.png"), "VX-94 transformation should retain all three authored mechanical intermediate keyframes")
	_expect(not source.contains("func _draw_transforming") and not source.contains("func _draw_rotary_cannon"), "obsolete procedural VX-94 construction should remain removed")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main gameplay source should be readable for production-art cutover")
	if main_file != null:
		var main_source := main_file.get_as_text()
		_expect(main_source.contains('"faction": str(archetype.get("faction", "mercenary"))'), "spawned enemies should preserve authored faction metadata for production art")
		var gameplay_start := main_source.find("func _draw_gameplay()")
		var gameplay_source := main_source.substr(gameplay_start) if gameplay_start >= 0 else ""
		_expect(not gameplay_source.contains("draw_colored_polygon"), "main gameplay draw must not retain prototype craft/enemy polygons")
		_expect(not gameplay_source.contains('for bullet in bullets:'), "main gameplay draw must not duplicate production projectile cues")

func _test_altitude_presentation() -> void:
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable for altitude checks")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("AltitudeRules.transition_ground_scale"), "surface targets should interpolate scale during altitude changes")
	_expect(source.contains("_altitude_pitch_offset"), "VX-94 should receive a climb/dive pitch cue during lane changes")
	_expect(source.contains('category in ["ground", "sea"]'), "ground/sea targets should be identified for altitude treatment")
	_expect(source.contains("scale < 0.25"), "ordinary surface silhouettes should disappear when the player is effectively too high to engage them visually")

func _test_late_boss_silhouettes() -> void:
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable for late-boss checks")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains('"phase_control_array": preload') and source.contains('"station_warden": preload') and source.contains('"machine_ark": preload'), "late bosses should retain dedicated production sprite registrations")
	_expect(not source.contains("func _draw_phase_array") and not source.contains("func _draw_station_warden") and not source.contains("func _draw_machine_ark"), "late bosses should not retain prototype vector substitutes")

func _test_airframe_cues() -> void:
	var file := FileAccess.open("res://scripts/airframe_cue_director.gd", FileAccess.READ)
	_expect(file != null, "airframe cue director should be readable")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("layer = 13"), "airframe cues should remain above combat silhouettes and below projectile/HUD layers")
	_expect(source.contains('"magneto_composite_frame"') and source.contains("_draw_magnetic_nodes"), "magneto-composite frame should expose restrained magnetic nodes")
	_expect(source.contains('"field_coupled_frame"') and source.contains("_draw_field_lattice"), "field-coupled frame should expose visible field-lattice language")

func _test_combat_fx() -> void:
	var file := FileAccess.open("res://scripts/combat_fx_director.gd", FileAccess.READ)
	_expect(file != null, "combat FX director should be readable")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("const MAX_EVENTS := 48"), "combat FX event count should stay bounded")
	_expect(source.contains('"hit"') and source.contains('"explosion"') and source.contains('"boss_explosion"') and source.contains('"player_hit"'), "combat FX should distinguish hits, kills, bosses and player damage")
	_expect(source.contains("_draw_explosion"), "enemy destruction should receive pixel explosion feedback")
	_expect(source.contains("EXPLOSION_FRAMES"), "enemy destruction should use the authored eight-frame raster sequence")
	_expect(source.contains("_draw_player_hit"), "VX-94 damage should receive visible shield/hull impact feedback")
	_expect(not source.contains("scene.set(\"enemies\"") and not source.contains("scene.set(\"hull\""), "combat FX must remain presentation-only")
	for frame_index in range(8):
		var frame := load("res://assets/runtime/effects/explosion/explosion_%d.png" % frame_index)
		_expect(frame is Texture2D and frame.get_size() == Vector2(48,48), "explosion animation frame should retain native 48x48 geometry: %d" % frame_index)
	_expect(FileAccess.file_exists("res://assets/source/effects/explosion_asset_manifest.json"), "explosion source/runtime manifest should exist")
	var observer := CombatFxDirector.new()
	_expect(observer.call("_observation_kind", {"hp":4}, {"hp":4}, true) == "", "a surviving unchanged enemy must not emit a false explosion")
	_expect(observer.call("_observation_kind", {"hp":4}, {"hp":3}, true) == "hit", "a surviving damaged enemy should emit only a hit cue")
	_expect(observer.call("_observation_kind", {"hp":1}, {}, false) == "destroyed", "a disappeared enemy should emit a destruction cue")
	observer.free()

func _test_damage_state() -> void:
	var file := FileAccess.open("res://scripts/damage_state_director.gd", FileAccess.READ)
	_expect(file != null, "damage-state director should be readable")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("damage_ratio < 0.20"), "minor battle damage should stay visually restrained")
	_expect(source.contains("damage_ratio >= 0.45"), "mid damage should introduce smoke")
	_expect(source.contains("damage_ratio >= 0.72"), "critical damage should introduce sparks")
	_expect(source.contains("ratio >= 0.86"), "small flame cue should be reserved for severe damage")
	_expect(source.contains('_craft_form() == "bomber"'), "battle-damage attachments should react to fighter/bomber geometry")
	_expect(source.contains('scene.call("_max_hull")'), "damage presentation should read canonical airframe hull capacity")
	for forbidden in ['scene.set("hull"', 'scene.set("shield"', 'var extra_health']:
		_expect(not source.contains(forbidden), "damage-state presentation must not create or mutate durability state: %s" % forbidden)

func _test_projectile_art() -> void:
	var projectile_source := FileAccess.open("res://scripts/projectile_cue_director.gd", FileAccess.READ)
	_expect(projectile_source != null, "projectile cue director should be readable")
	if projectile_source != null:
		var source := projectile_source.get_as_text()
		_expect(source.contains("PROJECTILE_FRAMES") and source.contains("_draw_registered_sprite"), "live projectile cues should use registered production sprites")
		_expect(not source.contains("draw_circle(position") and not source.contains("draw_arc(position"), "live projectile bodies should not retain generic vector circles")
	var families := ["ballistic", "enemy_cannon", "homing_missile", "needle_rail", "plasma_lance", "support_rocket", "strategic_warhead", "precision_bomb"]
	for family in families:
		for frame_index in range(4):
			var frame := load("res://assets/runtime/effects/projectiles/%s/%d.png" % [family, frame_index])
			_expect(frame is Texture2D and frame.get_size() == Vector2(16,24), "projectile frame should retain registered 16x24 geometry: %s/%d" % [family, frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/projectiles/projectile_asset_manifest.json"), "projectile source/runtime manifest should exist")
	var strike_source := FileAccess.open("res://scripts/strike_ordnance_director.gd", FileAccess.READ)
	_expect(strike_source != null, "strike ordnance director should be readable for bomb-art checks")
	if strike_source != null:
		var source := strike_source.get_as_text()
		_expect(source.contains("PRECISION_BOMB_FRAMES") and source.contains("bomb_texture"), "precision strike ordnance should use the authored tumble frames")

func _test_impact_art() -> void:
	var families := ["muzzle", "rotary_muzzle", "armor_hit", "shield_hit", "bomb_impact", "emp_disruption", "water_impact", "dust_impact"]
	for family in families:
		for frame_index in range(4):
			var frame := load("res://assets/runtime/effects/impacts/%s/%d.png" % [family, frame_index])
			_expect(frame is Texture2D and frame.get_size() == Vector2(24,24), "impact frame should retain registered 24x24 geometry: %s/%d" % [family, frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/impacts/impact_asset_manifest.json"), "impact source/runtime manifest should exist")
	var library := FileAccess.open("res://scripts/impact_art_library.gd", FileAccess.READ)
	_expect(library != null, "shared impact art library should be readable")
	if library != null:
		var source := library.get_as_text()
		for family in families:
			_expect(source.contains('"%s"' % family), "shared impact library should register family: %s" % family)
	var combat := FileAccess.open("res://scripts/combat_fx_director.gd", FileAccess.READ)
	if combat != null:
		var source := combat.get_as_text()
		_expect(source.contains('category == "sea"') and source.contains('"shield_hit" if shield'), "combat impacts should distinguish water, armour and shield materials")
	var mounts := FileAccess.open("res://scripts/weapon_mount_cue_director.gd", FileAccess.READ)
	if mounts != null:
		var source := mounts.get_as_text()
		_expect(source.contains('frame_for_ratio("muzzle"') and source.contains('frame_for_ratio("rotary_muzzle"'), "weapon mounts should use authored compact and rotary muzzle sequences")
		_expect(not source.contains("draw_colored_polygon"), "weapon muzzle flash should not retain the prototype vector flame")
	var electromagnetic := FileAccess.open("res://scripts/electromagnetic_cue_director.gd", FileAccess.READ)
	if electromagnetic != null:
		var source := electromagnetic.get_as_text()
		_expect(source.contains('frame_for_clock("emp_disruption"'), "EMP disruption should use authored broken-arc animation")

func _test_persistent_effect_art() -> void:
	var trail_families := ["damage_smoke", "damage_fire", "damage_sparks", "afterburner", "contrail", "debris"]
	for family in trail_families:
		for frame_index in range(4):
			var frame := load("res://assets/runtime/effects/persistent/%s/%d.png" % [family, frame_index])
			_expect(frame is Texture2D and frame.get_size() == Vector2(32,40), "persistent effect should retain registered 32x40 geometry: %s/%d" % [family, frame_index])
	for frame_index in range(4):
		var boom := load("res://assets/runtime/effects/persistent/sonic_boom/%d.png" % frame_index)
		_expect(boom is Texture2D and boom.get_size() == Vector2(64,64), "sonic-boom pressure frame should retain registered 64x64 geometry: %d" % frame_index)
	_expect(FileAccess.file_exists("res://assets/source/effects/persistent/persistent_asset_manifest.json"), "persistent effect source/runtime manifest should exist")
	var damage := FileAccess.open("res://scripts/damage_state_director.gd", FileAccess.READ)
	if damage != null:
		var source := damage.get_as_text()
		_expect(source.contains('frame_for_clock("damage_smoke"') and source.contains('frame_for_clock("damage_sparks"') and source.contains('frame_for_clock("damage_fire"'), "VX-94 progressive damage should use authored smoke, spark and fire attachments")
		_expect(not source.contains("draw_circle") and not source.contains("draw_colored_polygon"), "VX-94 damage effects should not retain smoke circles or vector flame triangles")
	var afterburner := FileAccess.open("res://scripts/afterburner_cue_director.gd", FileAccess.READ)
	if afterburner != null:
		var source := afterburner.get_as_text()
		_expect(source.contains('frame_for_clock("afterburner"') and source.contains('frame_for_clock("contrail"'), "hypersonic thrust should use authored compression plumes and contrails")
		_expect(source.contains('frame_for_ratio("sonic_boom"'), "sonic transition should use the authored broken pressure front")
		_expect(not source.contains("surface.draw_arc(scene.get(\"player_position\")"), "sonic boom should not regress to a perfect vector circle")

func _test_mount_map() -> void:
	var data = ContentCatalog.load_json("res://data/player_mounts.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "VX-94 mount map should load")
	if typeof(data) != TYPE_DICTIONARY:
		return
	_expect(str(data.get("craft_id", "")) == "vx_94_strikewing", "mount map should belong to VX-94")
	var mounts: Array = data.get("mounts", [])
	_expect(mounts.size() >= 10, "VX-94 should expose a useful physical mount map")
	var by_id: Dictionary = {}
	for mount in mounts:
		if typeof(mount) == TYPE_DICTIONARY:
			by_id[str(mount.get("id", ""))] = mount
	_expect(by_id.has("nose_rotary") and "bomber" in by_id["nose_rotary"].get("forms", []), "nose rotary should be bomber-only deployment")
	_expect(by_id.has("wing_root_left") and "fighter" in by_id["wing_root_left"].get("forms", []), "wing-root cannon should be fighter mount")
	_expect(by_id.has("centerline_emitter") and "rail" in by_id["centerline_emitter"].get("roles", []), "specialist rail/energy systems should retain centreline emitter")
	_expect(by_id.has("ventral_strike_bay") and "precision_bomb" in by_id["ventral_strike_bay"].get("roles", []), "precision bombing should use ventral strike bay")
	_expect(by_id.has("dorsal_module") and "emp" in by_id["dorsal_module"].get("roles", []), "electronic systems should have dorsal module location")
	var schematic := FileAccess.open("res://scripts/loadout_schematic_director.gd", FileAccess.READ)
	_expect(schematic != null, "loadout schematic should be readable")
	if schematic != null:
		var source := schematic.get_as_text()
		_expect(source.contains("KEY_L"), "L should toggle VX-94 stores schematic")
		_expect(source.contains("player_mounts.json"), "schematic should consume the authored physical mount map")
		_expect(source.contains("FIGHTER") and source.contains("BOMBER / ATTACK"), "schematic should compare both variable-geometry planforms")
		_expect(source.contains("VX94_PLANFORMS") and source.contains("vx94_fighter_v1.png") and source.contains("vx94_bomber_v1.png"), "stores schematic should use the reviewed VX-94 planform masters")
		_expect(source.contains("texture.get_size() * 2.25"), "schematic planforms should align with the 2.25x physical mount-coordinate map")
		_expect(not source.contains("draw_colored_polygon"), "stores schematic should not retain prototype vector aircraft")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
