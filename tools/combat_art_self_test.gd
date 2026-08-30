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
	_expect(source.contains("func _draw_fighter"), "VX-94 fighter silhouette should have dedicated rendering")
	_expect(source.contains("func _draw_bomber"), "VX-94 bomber silhouette should have dedicated rendering")
	_expect(source.contains("PLAYER_GLASS"), "VX-94 should retain visible cockpit-glass language")
	_expect(source.contains("PLAYER_ENGINE"), "VX-94 should retain visible engine/hardpoint accents")
	_expect(source.contains("func _draw_ground") and source.contains("func _draw_sea") and source.contains("func _draw_air"), "mercenary air/ground/sea roles should have distinct silhouette renderers")
	_expect(source.contains("MERCENARY_AIR_SPRITES") and source.contains("MERCENARY_GROUND_SPRITES") and source.contains("LAYERED_GROUND_SPRITES") and source.contains("MERCENARY_SEA_SPRITES") and source.contains("MACHINE_AIR_SPRITES") and source.contains("MACHINE_GROUND_SPRITES") and source.contains("ORBITAL_AIR_SPRITES") and source.contains("MERCENARY_BOSS_SPRITES") and source.contains("MACHINE_BOSS_SPRITES") and source.contains("ORBITAL_BOSS_SPRITES") and source.contains("func _draw_production_sprite"), "reviewed units should use production sprite assets")
	_expect(source.contains("func _draw_layered_ground") and source.contains("Vector2.DOWN.angle_to") and source.contains("recoil_timer"), "layered emplacements should track targets and recoil around registered pivots")
	_expect(source.contains("func _draw_autonomous"), "autonomous machines should have their own visual language")
	_expect(source.contains("AI_CORE"), "autonomous enemies should expose readable machine-core accents")
	_expect(source.contains("func _draw_boss"), "boss-scale enemies should have dedicated presentation")
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
	var sea_sizes := {
		"river_patrol": Vector2(30,44),
		"torpedo_boat": Vector2(34,48),
		"fast_attack_craft": Vector2(36,50),
		"missile_corvette": Vector2(50,66),
	}
	for enemy_id in sea_sizes:
		var texture := load("res://assets/runtime/enemies/mercenary_sea/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == sea_sizes[enemy_id], "sea production sprite should retain reviewed geometry: %s" % enemy_id)
	var machine_air_sizes := {
		"drone_scout": Vector2(24,26),
		"drone_hunter": Vector2(30,30),
		"drone_bomber": Vector2(44,38),
		"drone_missile_node": Vector2(38,36),
	}
	for enemy_id in machine_air_sizes:
		var texture := load("res://assets/runtime/enemies/machine_air/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == machine_air_sizes[enemy_id], "machine-air sprite should retain reviewed geometry: %s" % enemy_id)
	var machine_ground_sizes := {
		"autonomous_armor": Vector2(36,30),
		"factory_defence_node": Vector2(34,34),
	}
	for enemy_id in machine_ground_sizes:
		var texture := load("res://assets/runtime/enemies/machine_ground/%s_idle.png" % enemy_id)
		_expect(texture is Texture2D and texture.get_size() == machine_ground_sizes[enemy_id], "machine-ground sprite should retain reviewed geometry: %s" % enemy_id)
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
	_expect(source.contains("fighter_tip_l.lerp(bomber_tip_l, t)"), "wing tips should physically sweep around the hinge")
	_expect(source.contains("Visible variable-geometry hinge plates"), "wing sweep should retain visible mechanical hinges")
	_expect(source.contains("_draw_rotary_cannon(surface, p, deploy)"), "nose rotary should deploy during bomber transformation")
	_expect(source.contains("Fighter wing-root cannons") or source.contains("wing-root cannon"), "fighter should visibly retain wing-root cannon packs")
	_expect(source.contains("Under-wing hardpoints"), "bomber configuration should expose physical bomb/rocket/missile hardpoints")
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
	_expect(source.contains('id == "phase_control_array"') and source.contains("func _draw_phase_array"), "Phase Control Array should have a dedicated ring-array silhouette")
	_expect(source.contains('id == "station_warden"') and source.contains("func _draw_station_warden"), "Station Warden should have a dedicated fortified station silhouette")
	_expect(source.contains('id == "machine_ark"') and source.contains("func _draw_machine_ark"), "Machine Ark should have a dedicated carrier/command silhouette")

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
	_expect(source.contains("_draw_player_hit"), "VX-94 damage should receive visible shield/hull impact feedback")
	_expect(not source.contains("scene.set(\"enemies\"") and not source.contains("scene.set(\"hull\""), "combat FX must remain presentation-only")

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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
