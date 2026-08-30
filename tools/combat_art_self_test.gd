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
	for bank_path in ["fighter_hard_left.png", "fighter_left.png", "fighter_neutral.png", "fighter_right.png", "fighter_hard_right.png", "bomber_hard_left.png", "bomber_left.png", "bomber_neutral.png", "bomber_right.png", "bomber_hard_right.png"]:
		var bank_frame := load("res://assets/runtime/craft/vx94/gameplay/bank/%s" % bank_path)
		_expect(bank_frame is Texture2D and bank_frame.get_size() == Vector2(48,54), "VX-94 bank frame should retain native 48x54 geometry: %s" % bank_path)
	_expect(source.contains("_bank_visual < -0.78") and source.contains("_bank_visual > 0.78"), "VX-94 hard-bank art should engage only during committed lateral input")
	for form in ["fighter", "bomber"]:
		for frame_index in range(4):
			var breakup := load("res://assets/runtime/craft/vx94/gameplay/destruction/%s_breakup_%d.png" % [form, frame_index])
			_expect(breakup is Texture2D and breakup.get_size() == Vector2(48,54), "VX-94 breakup frame should retain native 48x54 geometry: %s %d" % [form, frame_index])
	var escape_capsule := load("res://assets/runtime/craft/vx94/gameplay/destruction/escape_capsule.png")
	_expect(escape_capsule is Texture2D and escape_capsule.get_size() == Vector2(16,20), "VX-94 escape capsule should retain registered 16x20 geometry")
	_expect(source.contains("VX94_FIGHTER_BREAKUP") and source.contains("VX94_BOMBER_BREAKUP") and source.contains("VX94_ESCAPE_CAPSULE") and source.contains("_draw_player_loss"), "VX-94 loss should render authored form-specific breakup and escape art")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/vx94_destruction_asset_manifest.json"), "VX-94 destruction/escape manifest should exist")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := main_file.get_as_text() if main_file != null else ""
	_expect(main_source.contains("PLAYER_LOSS_SEQUENCE_SECONDS") and main_source.contains("player_loss_timer") and main_source.contains("_finish_mission(false)"), "fatal hull damage should hold gameplay for the authored VX-94 loss sequence before mission failure")
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
	_expect(source.contains('ImpactArtLibrary.frame_for_ratio("muzzle"') and not source.contains("surface.draw_circle(Vector2(0, 14)"), "layered weapon recoil should use authored muzzle sprites instead of circle/line programmer art")
	_expect(source.contains("MACHINE_AIR_SPRITES") and source.contains("MACHINE_GROUND_SPRITES") and source.contains("ORBITAL_AIR_SPRITES"), "autonomous machines should retain their own authored visual families")
	_expect(source.contains("AI_CORE"), "autonomous enemies should expose readable machine-core accents")
	_expect(source.contains("func _draw_enemy_damage_attachments") and source.contains("damage_ratio < 0.35") and source.contains("damage_ratio >= 0.62") and source.contains("damage_ratio >= 0.82"), "ordinary enemies should expose progressive smoke, spark and critical-fire states")
	_expect(source.contains('"damage_smoke"') and source.contains('"damage_sparks"') and source.contains('"damage_fire"'), "enemy damage states should reuse authored persistent raster effects")
	_expect(not source.contains('enemy["hp"] =') and not source.contains('enemy["max_hp"] ='), "enemy damage art must remain presentation-only")
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
	var bank_sizes := {
		"scout_falcon":Vector2(28,30), "gunship_mk1":Vector2(42,38), "attack_chopper":Vector2(42,38), "ace_interceptor":Vector2(32,34), "heavy_bomber":Vector2(50,42),
		"drone_scout":Vector2(24,26), "drone_hunter":Vector2(30,30), "drone_bomber":Vector2(44,38), "drone_missile_node":Vector2(38,36),
		"exo_drone":Vector2(30,30), "orbital_sentry":Vector2(40,38), "phase_interceptor":Vector2(34,34), "beam_sentry":Vector2(42,40), "orbital_lancer":Vector2(48,58),
	}
	for bank_id in bank_sizes:
		for direction in ["left", "right"]:
			var bank_texture := load("res://assets/runtime/enemies/bank/%s/%s.png" % [bank_id, direction])
			_expect(bank_texture is Texture2D and bank_texture.get_size() == bank_sizes[bank_id], "hostile bank pose should preserve registered canvas: %s %s" % [bank_id, direction])
	_expect(CombatArtDirector.hostile_bank_frame_index(-0.4) == 0 and CombatArtDirector.hostile_bank_frame_index(0.0) == 1 and CombatArtDirector.hostile_bank_frame_index(0.4) == 2, "hostile airframes should hold discrete left, neutral and right bank poses")
	_expect(source.contains('enemy.get("visual_bank", 0.0)'), "hostile bank art should consume real movement state")
	_expect(FileAccess.file_exists("res://assets/source/enemies/air_bank_asset_manifest.json"), "hostile bank source/runtime manifest should exist")
	var specialist_sizes := {
		"gunship_turret":Vector2(42,38), "chopper_cannon":Vector2(42,38),
		"heavy_bomber_bay_closed":Vector2(50,42), "heavy_bomber_bay_opening":Vector2(50,42), "heavy_bomber_bay_open":Vector2(50,42), "heavy_bomber_bay_fire":Vector2(50,42),
	}
	for specialist_id in specialist_sizes:
		var specialist_texture := load("res://assets/runtime/enemies/air_specialist/%s.png" % specialist_id)
		_expect(specialist_texture is Texture2D and specialist_texture.get_size() == specialist_sizes[specialist_id], "air specialist component should retain registered pivot canvas: %s" % specialist_id)
	_expect(CombatArtDirector.heavy_bomber_bay_frame_index(1.0, 0.0) == 0, "heavy bomber bay should hold closed between attacks")
	_expect(CombatArtDirector.heavy_bomber_bay_frame_index(0.5, 0.0) == 1, "heavy bomber bay should visibly open before firing")
	_expect(CombatArtDirector.heavy_bomber_bay_frame_index(0.1, 0.0) == 2, "heavy bomber bay should reach an open weapon-ready pose")
	_expect(CombatArtDirector.heavy_bomber_bay_frame_index(1.0, 0.8) == 3, "heavy bomber bay should expose an authored firing pose during recoil")
	_expect(source.contains('enemy_id == "gunship_mk1"') and source.contains('enemy_id == "attack_chopper"'), "gunship turret and helicopter cannon should receive specialist articulation")
	_expect(FileAccess.file_exists("res://assets/source/enemies/air_specialist/air_specialist_asset_manifest.json"), "air specialist source/runtime manifest should exist")
	var machine_specialist_sizes := {
		"core_0":Vector2(5,5), "core_1":Vector2(5,5), "core_2":Vector2(5,5), "hunter_weapon":Vector2(30,30),
		"bomber_bay_closed":Vector2(44,38), "bomber_bay_opening":Vector2(44,38), "bomber_bay_open":Vector2(44,38), "bomber_bay_fire":Vector2(44,38),
		"missile_hatch_closed":Vector2(38,36), "missile_hatch_opening":Vector2(38,36), "missile_hatch_open":Vector2(38,36), "missile_hatch_fire":Vector2(38,36),
	}
	for machine_specialist_id in machine_specialist_sizes:
		var machine_specialist_texture := load("res://assets/runtime/enemies/machine_air_specialist/%s.png" % machine_specialist_id)
		_expect(machine_specialist_texture is Texture2D and machine_specialist_texture.get_size() == machine_specialist_sizes[machine_specialist_id], "machine-air specialist component should retain registered canvas: %s" % machine_specialist_id)
	_expect(CombatArtDirector.machine_weapon_door_frame_index(1.0, 0.0) == 0 and CombatArtDirector.machine_weapon_door_frame_index(0.5, 0.0) == 1, "machine weapon doors should hold closed then visibly open before firing")
	_expect(CombatArtDirector.machine_weapon_door_frame_index(0.1, 0.0) == 2 and CombatArtDirector.machine_weapon_door_frame_index(1.0, 0.8) == 3, "machine weapon doors should expose ready and authored firing poses")
	_expect(source.contains('MACHINE_AIR_SPECIALIST_ART') and source.contains('pulse_cycle := [0, 1, 2, 1]'), "machine airframes should share restrained perceptual core animation")
	_expect(FileAccess.file_exists("res://assets/source/enemies/machine_air_specialist/machine_air_specialist_asset_manifest.json"), "machine-air specialist source/runtime manifest should exist")
	var orbital_specialist_sizes := {
		"sentry_turret":Vector2(40,38), "phase_nodes_0":Vector2(34,34), "phase_nodes_1":Vector2(34,34), "phase_nodes_2":Vector2(34,34),
		"beam_aperture_closed":Vector2(42,40), "beam_aperture_opening":Vector2(42,40), "beam_aperture_open":Vector2(42,40), "beam_aperture_fire":Vector2(42,40),
		"rail_charge_0":Vector2(48,58), "rail_charge_1":Vector2(48,58), "rail_charge_2":Vector2(48,58), "rail_charge_fire":Vector2(48,58),
	}
	for orbital_specialist_id in orbital_specialist_sizes:
		var orbital_specialist_texture := load("res://assets/runtime/enemies/orbital_air_specialist/%s.png" % orbital_specialist_id)
		_expect(orbital_specialist_texture is Texture2D and orbital_specialist_texture.get_size() == orbital_specialist_sizes[orbital_specialist_id], "orbital-air specialist component should retain registered canvas: %s" % orbital_specialist_id)
	_expect(CombatArtDirector.orbital_weapon_frame_index(1.0, 0.0) == 0 and CombatArtDirector.orbital_weapon_frame_index(0.5, 0.0) == 1, "orbital apertures should hold safe then visibly prepare before firing")
	_expect(CombatArtDirector.orbital_weapon_frame_index(0.1, 0.0) == 2 and CombatArtDirector.orbital_weapon_frame_index(1.0, 0.8) == 3, "orbital apertures should expose charged and discharge poses")
	_expect(source.contains('ORBITAL_AIR_SPECIALIST_ART') and source.contains('enemy_id == "orbital_sentry"') and source.contains('enemy_id == "phase_interceptor"'), "BLACK SKY airframes should receive specialist mechanical animation")
	_expect(FileAccess.file_exists("res://assets/source/enemies/orbital_air_specialist/orbital_air_specialist_asset_manifest.json"), "orbital-air specialist source/runtime manifest should exist")
	var enemy_file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	_expect(enemy_file != null and enemy_file.get_as_text().contains('{"id":"orbital_lancer","class":"air","hp":30,"speed":126,"value":4300,"pattern":"tracking_sweep","weapon":"cannon"'), "orbital lancer gameplay should fire through its authored ballistic rail rather than a mismatched homing missile")
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
	var vehicle_weapon_layers := {"light_tank_weapon":Vector2(30,30), "sam_truck_weapon":Vector2(34,34), "aa_carrier_weapon":Vector2(38,38)}
	for layer_id in vehicle_weapon_layers:
		var vehicle_layer := load("res://assets/runtime/enemies/mercenary_ground_layered/%s.png" % layer_id)
		_expect(vehicle_layer is Texture2D and vehicle_layer.get_size() == vehicle_weapon_layers[layer_id], "articulated vehicle weapon layer should retain registered pivot canvas: %s" % layer_id)
	_expect(source.contains('"light_tank": {') and source.contains('"sam_truck": {') and source.contains('"armoured_aa_carrier": {'), "tank, SAM and AA carrier should use layered target-tracking weapon assemblies")
	for sam_pose in ["sam_truck_weapon_stowed", "sam_truck_weapon_rising", "sam_truck_weapon_launch"]:
		var sam_texture := load("res://assets/runtime/enemies/mercenary_ground_layered/%s.png" % sam_pose)
		_expect(sam_texture is Texture2D and sam_texture.get_size() == Vector2(34,34), "SAM key pose should retain registered 34x34 pivot canvas: %s" % sam_pose)
	_expect(CombatArtDirector.sam_launcher_frame_index(1.0, 0.0) == 0, "SAM launcher should remain stowed outside its attack window")
	_expect(CombatArtDirector.sam_launcher_frame_index(0.5, 0.0) == 1, "SAM launcher should visibly rise before firing")
	_expect(CombatArtDirector.sam_launcher_frame_index(0.15, 0.0) == 2, "SAM launcher should lock in a deployed tracking pose before firing")
	_expect(CombatArtDirector.sam_launcher_frame_index(1.0, 0.8) == 3, "SAM launcher should show its authored launch pose during recoil")
	_expect(source.contains('Rect2(-8, 9, 7, 11)') and source.contains('Rect2(1, 9, 7, 11)'), "SAM launch should show separate authored ignition at both missile tubes")
	_expect(FileAccess.file_exists("res://assets/source/enemies/vehicle_articulation/vehicle_articulation_asset_manifest.json"), "vehicle articulation source/runtime manifest should exist")
	var ground_force_sizes := {
		"mercenary_infantry/mercenary_rifle_team": Vector2(26,22),
		"mercenary_infantry/mercenary_heavy_team": Vector2(30,26),
		"ground_mechs/security_patrol_mech": Vector2(38,42),
		"ground_mechs/autonomous_salvage_mech": Vector2(44,42),
	}
	for ground_force_path in ground_force_sizes:
		var force_texture := load("res://assets/runtime/enemies/%s_idle.png" % ground_force_path)
		_expect(force_texture is Texture2D and force_texture.get_size() == ground_force_sizes[ground_force_path], "ground-force identity should retain reviewed geometry: %s" % ground_force_path)
	var ground_specialist_sizes := {
		"heavy_team_weapon":Vector2(30,26), "rifle_scatter_0":Vector2(26,22), "rifle_scatter_1":Vector2(26,22), "heavy_scatter_0":Vector2(30,26),
		"security_mech_weapon":Vector2(38,42), "salvage_mech_tool":Vector2(44,42),
	}
	for ground_specialist_id in ground_specialist_sizes:
		var ground_specialist_texture := load("res://assets/runtime/enemies/ground_force_specialist/%s.png" % ground_specialist_id)
		_expect(ground_specialist_texture is Texture2D and ground_specialist_texture.get_size() == ground_specialist_sizes[ground_specialist_id], "ground-force specialist component should retain registered canvas: %s" % ground_specialist_id)
	_expect(source.contains('GROUND_FORCE_SPECIALIST_ART') and source.contains('enemy.get("hit_timer", 0.0)') and source.contains('enemy.get("recoil_timer", 0.0)'), "ground troops and mechs should consume live hit and firing state")
	_expect(source.contains('Vector2(-8,-4)') and source.contains('Vector2(0,9)'), "rifle team should use restrained per-soldier muzzle cadence rather than a single squad-wide flash")
	_expect(FileAccess.file_exists("res://assets/source/enemies/ground_force_specialist/ground_force_specialist_asset_manifest.json"), "ground-force specialist source/runtime manifest should exist")
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
	var naval_specialist_sizes := {
		"river_turret": Vector2(30,44), "torpedo_turret": Vector2(34,48), "fast_turret": Vector2(36,50), "corvette_turret": Vector2(50,66),
		"torpedo_launcher_closed": Vector2(34,48), "torpedo_launcher_open": Vector2(34,48), "torpedo_launcher_fire": Vector2(34,48),
		"corvette_hatch_closed": Vector2(50,66), "corvette_hatch_opening": Vector2(50,66), "corvette_hatch_open": Vector2(50,66), "corvette_hatch_fire": Vector2(50,66),
	}
	for asset_name in naval_specialist_sizes:
		var specialist_texture := load("res://assets/runtime/enemies/naval_specialist/%s.png" % asset_name)
		_expect(specialist_texture is Texture2D and specialist_texture.get_size() == naval_specialist_sizes[asset_name], "naval specialist layer should retain its registered hull canvas: %s" % asset_name)
	_expect(source.contains("NAVAL_SPECIALIST_ART") and source.contains("naval_launcher_frame_index") and source.contains("recoil_timer"), "naval hulls should expose target-tracking turrets, launcher deployment and recoil")
	_expect(FileAccess.file_exists("res://assets/source/enemies/naval_specialist/naval_specialist_asset_manifest.json"), "naval articulation source/runtime manifest should exist")
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
	for family in ["human_turbine", "machine_thruster", "orbital_impulse"]:
		for frame_index in range(4):
			var propulsion_frame := load("res://assets/runtime/effects/enemy_propulsion/%s/%d.png" % [family, frame_index])
			_expect(propulsion_frame is Texture2D and propulsion_frame.get_size() == Vector2(16,24), "enemy propulsion frame should retain registered 16x24 geometry: %s/%d" % [family, frame_index])
	_expect(source.contains("AIR_PROPULSION_FRAMES") and source.contains("AIR_PROPULSION_STYLE") and source.contains("func _draw_hostile_airframe"), "static hostile airframes should receive faction-specific production propulsion animation")
	_expect(source.contains('"human_turbine"') and source.contains('"machine_thruster"') and source.contains('"orbital_impulse"'), "human, machine and orbital propulsion should remain visually distinct")
	_expect(FileAccess.file_exists("res://assets/source/effects/enemy_propulsion/enemy_propulsion_asset_manifest.json"), "enemy propulsion source/runtime manifest should exist")
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
	var mercenary_boss_specialist_sizes := {
		"gunship_turret":Vector2(18,24), "train_turret":Vector2(20,28), "cruiser_turret":Vector2(22,30),
		"gunship_mount":Vector2(16,24), "train_mount":Vector2(18,28), "cruiser_mount":Vector2(20,32),
		"cruiser_hatch_closed":Vector2(16,22), "cruiser_hatch_opening":Vector2(16,22), "cruiser_hatch_open":Vector2(16,22), "cruiser_hatch_fire":Vector2(16,22),
	}
	for component_id in mercenary_boss_specialist_sizes:
		var component := load("res://assets/runtime/enemies/mercenary_boss_specialist/%s.png" % component_id)
		_expect(component is Texture2D and component.get_size()==mercenary_boss_specialist_sizes[component_id],"mercenary boss mechanical component should retain registered geometry: %s" % component_id)
	_expect(source.contains("MERCENARY_BOSS_SPECIALIST_ART") and source.contains("_draw_mercenary_boss_entrance") and source.contains("_draw_mercenary_boss_mechanics"),"mercenary bosses should receive authored entrance and mechanical combat layers")
	_expect(CombatArtDirector.boss_hatch_frame_index(1.0,0.0)==0 and CombatArtDirector.boss_hatch_frame_index(0.6,0.0)==1 and CombatArtDirector.boss_hatch_frame_index(0.2,0.0)==2 and CombatArtDirector.boss_hatch_frame_index(1.0,0.8)==3,"missile-cruiser hatches should communicate closed, opening, armed and launch poses")
	_expect(FileAccess.file_exists("res://assets/source/enemies/mercenary_boss_specialist/mercenary_boss_specialist_asset_manifest.json"),"mercenary boss mechanics manifest should exist")
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
	var machine_boss_specialist_sizes := {"swarm_rack":Vector2(36,34),"swarm_drone":Vector2(10,12),"forge_conveyor":Vector2(24,64),"forge_blank":Vector2(12,14),"forge_press":Vector2(20,24),"forge_tool":Vector2(18,26)}
	for component_id in machine_boss_specialist_sizes:
		var component := load("res://assets/runtime/enemies/machine_boss_specialist/%s.png" % component_id)
		_expect(component is Texture2D and component.get_size()==machine_boss_specialist_sizes[component_id],"machine-boss industrial component should retain registered geometry: %s" % component_id)
	_expect(source.contains("MACHINE_BOSS_SPECIALIST_ART") and source.contains("_draw_machine_boss_mechanics") and source.contains("cradle_offsets"),"machine bosses should expose physical drone rack and forge machinery layers")
	_expect(CombatArtDirector.machine_boss_cycle_frame_index(0.0)==0 and CombatArtDirector.machine_boss_cycle_frame_index(0.25)==1 and CombatArtDirector.machine_boss_cycle_frame_index(0.50)==2 and CombatArtDirector.machine_boss_cycle_frame_index(0.75)==3,"forge machinery should use four held industrial poses")
	_expect(FileAccess.file_exists("res://assets/source/enemies/machine_boss_specialist/machine_boss_specialist_asset_manifest.json"),"machine boss specialist source/runtime manifest should exist")
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
	var orbital_boss_specialist_sizes := {"pylon_mount":Vector2(20,20),"tracking_pylon":Vector2(18,30),"phase_field_0":Vector2(126,126),"phase_field_1":Vector2(126,126),"phase_field_2":Vector2(126,126),"phase_field_3":Vector2(126,126)}
	for component_id in orbital_boss_specialist_sizes:
		var component := load("res://assets/runtime/enemies/orbital_boss_specialist/%s.png" % component_id)
		_expect(component is Texture2D and component.get_size()==orbital_boss_specialist_sizes[component_id],"BLACK SKY boss component should retain registered geometry: %s" % component_id)
	_expect(source.contains("ORBITAL_BOSS_SPECIALIST_ART") and source.contains("PHASE_FIELD_FRAMES") and source.contains("_draw_orbital_boss_mechanics"),"BLACK SKY bosses should expose authored field and independently tracking pressure-hardware pylons")
	_expect(CombatArtDirector.phase_field_cycle_index(0.0,1)==0 and CombatArtDirector.phase_field_cycle_index(0.34,1)==1 and CombatArtDirector.phase_field_cycle_index(0.50,2)==2,"phase field should use held calibration exposures whose cadence responds to canonical boss phase")
	_expect(FileAccess.file_exists("res://assets/source/enemies/orbital_boss_specialist/orbital_boss_specialist_asset_manifest.json"),"BLACK SKY boss mechanics source/runtime manifest should exist")

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
	_expect(source.contains('"magneto_composite_frame"') and source.contains('art["magnetic"][frame_index]'), "magneto-composite frame should expose authored animated magnetic nodes")
	_expect(source.contains('"field_coupled_frame"') and source.contains('art["field"][frame_index]'), "field-coupled frame should expose an authored broken field lattice")
	_expect(source.contains("AIRFRAME_ATTACHMENT_ART") and source.contains("_draw_attachment"), "airframe progression should stack registered attachment sprites")
	_expect(not source.contains("draw_rect") and not source.contains("draw_line") and not source.contains("draw_arc"), "airframe equipment must not regress to primitive rectangle, line or arc drawing")
	for form in ["fighter", "bomber"]:
		for static_layer in ["armor", "reactive"]:
			var static_texture := load("res://assets/runtime/craft/vx94/gameplay/airframe/%s_%s.png" % [form,static_layer])
			_expect(static_texture is Texture2D and static_texture.get_size()==Vector2(48,54), "airframe static attachment must retain VX-94 canvas: %s %s" % [form,static_layer])
		for animated_layer in ["magnetic", "field"]:
			for frame_index in range(3):
				var animation_texture := load("res://assets/runtime/craft/vx94/gameplay/airframe/%s_%s_%d.png" % [form,animated_layer,frame_index])
				_expect(animation_texture is Texture2D and animation_texture.get_size()==Vector2(48,54), "airframe animated attachment must retain VX-94 canvas: %s %s %d" % [form,animated_layer,frame_index])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/airframe_attachment_manifest.json"), "VX-94 layered airframe attachment manifest should exist")

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
	_expect(source.contains("func _draw_destruction_consequence") and source.contains('category == "sea"') and source.contains('faction == "autonomous"'), "enemy destruction should branch into naval, machine, air and ground material consequences")
	_expect(source.contains('enemy_id in ["mercenary_rifle_team", "mercenary_heavy_team"]'), "infantry destruction should use subdued dust/scatter instead of a wreck fire")
	_expect(source.contains('ImpactArtLibrary.frame_for_ratio("water_impact"') and source.contains('ImpactArtLibrary.frame_for_ratio("emp_disruption"'), "naval and autonomous destruction should use authored water and EMP raster effects")
	_expect(source.contains("NAVAL_WRECK_HULLS") and source.contains("NAVAL_SINK_SECONDS") and source.contains("func _draw_naval_sinking"), "naval destruction should retain the authored hull through a dedicated multi-stage sinking window")
	_expect(source.contains("NAVAL_SINK_SECONDS / EXPLOSION_SECONDS"), "the extended naval sinking window should not slow the authored arcade explosion cadence")
	_expect(source.contains("list_angle") and source.contains("sink_offset") and source.contains("bow") and source.contains("stern"), "naval sinking should visibly list, submerge and displace water at separate hull points")
	_expect(source.contains("MERCENARY_BOSS_WRECK_HULLS") and source.contains("BOSS_DESTRUCTION_SECONDS") and source.contains("func _draw_mercenary_boss_breakup"),"Sector I bosses should retain their silhouettes through bespoke extended destruction sequences")
	_expect(source.contains('enemy_id == "gunship_alpha"') and source.contains('enemy_id == "armoured_train"') and source.contains("source_region"),"gunship, train and cruiser boss deaths should use materially different roll, sectional breakup and sinking behavior")
	_expect(source.contains("MACHINE_BOSS_WRECK_HULLS") and source.contains("func _draw_machine_boss_breakup"),"machine bosses should retain reviewed hull material through extended physical breakup")
	_expect(source.contains('enemy_id=="swarm_controller"') and source.contains("central_width") and source.contains("tread_center"),"swarm controller and forge should use distinct three-way controller separation and tread/forge collapse")
	_expect(source.contains("ORBITAL_BOSS_WRECK_HULLS") and source.contains("ORBITAL_BOSS_DESTRUCTION_SECONDS") and source.contains("func _draw_orbital_boss_breakup"),"BLACK SKY bosses should receive an extended vacuum-breakup window with retained authored hull material")
	_expect(source.contains('enemy_id=="phase_control_array"') and source.contains('enemy_id=="machine_ark"') and source.contains("section_count"),"phase array should separate by projector quadrant while other orbital infrastructure breaks along authored longitudinal sections")
	_expect(source.contains("GROUND_EMPLACEMENT_BREAKUP_FRAMES") and source.contains("func _draw_ground_emplacement_breakup"),"layered human emplacements should retain authored weapon/ring breakup silhouettes after the primary blast")
	for emplacement in ["fort","flak"]:
		for frame_index in range(3):
			var breakup_frame := load("res://assets/runtime/effects/ground_breakup/%s_breakup_%d.png" % [emplacement,frame_index])
			_expect(breakup_frame is Texture2D and breakup_frame.get_size()==Vector2(40,40),"ground-emplacement breakup frame should retain 40x40 wreck canvas: %s/%d" % [emplacement,frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/ground_breakup/ground_breakup_asset_manifest.json"),"ground-emplacement breakup source/runtime manifest should exist")
	_expect(FileAccess.file_exists("res://assets/source/effects/destruction_consequence_asset_manifest.json"), "destruction consequence source/runtime manifest should exist")
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
