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
	_test_destruction_reward_art()
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
		_expect(gameplay_form is Texture2D and gameplay_form.get_size() == Vector2(64,72), "VX-94 gameplay form should retain reviewed 64x72 geometry: %s" % frame_path)
	for bank_path in ["fighter_hard_left.png", "fighter_left.png", "fighter_neutral.png", "fighter_right.png", "fighter_hard_right.png", "bomber_hard_left.png", "bomber_left.png", "bomber_neutral.png", "bomber_right.png", "bomber_hard_right.png"]:
		var bank_frame := load("res://assets/runtime/craft/vx94/gameplay/bank/%s" % bank_path)
		_expect(bank_frame is Texture2D and bank_frame.get_size() == Vector2(64,72) and bank_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "VX-94 bank frame should retain reviewed transparent 64x72 geometry: %s" % bank_path)
	_expect(FileAccess.file_exists("res://tools/build_vx94_bank_art.ps1") and FileAccess.file_exists("res://assets/source/craft/vx94/vx94_bank_family_v2_manifest.json"), "VX-94 bank poses should retain their canonical-planform builder and source/runtime contract")
	_expect(source.contains("_bank_visual < -0.78") and source.contains("_bank_visual > 0.78"), "VX-94 hard-bank art should engage only during committed lateral input")
	_expect(source.contains('argument.begins_with("--capture-bank=")') and source.contains('"hard-left": bank_target = -1.0') and source.contains('"hard-right": bank_target = 1.0'), "visual QA should expose deterministic VX-94 bank fixtures")
	_expect(source.contains('argument.begins_with("--capture-form=")') and source.contains('captured_form in ["fighter", "bomber"]'), "visual QA should expose deterministic fighter and bomber form fixtures")
	for form in ["fighter", "bomber"]:
		for frame_index in range(4):
			var breakup := load("res://assets/runtime/craft/vx94/gameplay/destruction/%s_breakup_%d.png" % [form, frame_index])
			_expect(breakup is Texture2D and breakup.get_size() == Vector2(64,72), "VX-94 breakup frame should retain registered 64x72 geometry: %s %d" % [form, frame_index])
	var escape_capsule := load("res://assets/runtime/craft/vx94/gameplay/destruction/escape_capsule.png")
	_expect(escape_capsule is Texture2D and escape_capsule.get_size() == Vector2(16,20), "VX-94 escape capsule should retain registered 16x20 geometry")
	_expect(source.contains("VX94_FIGHTER_BREAKUP") and source.contains("VX94_BOMBER_BREAKUP") and source.contains("VX94_ESCAPE_CAPSULE") and source.contains("_draw_player_loss"), "VX-94 loss should render authored form-specific breakup and escape art")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/vx94_destruction_asset_manifest.json"), "VX-94 destruction/escape manifest should exist")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	var main_source := main_file.get_as_text() if main_file != null else ""
	_expect(main_source.contains("PLAYER_LOSS_SEQUENCE_SECONDS") and main_source.contains("player_loss_timer") and main_source.contains("_finish_mission(false)"), "fatal hull damage should hold gameplay for the authored VX-94 loss sequence before mission failure")
	_expect(main_source.contains("--capture-player-loss=") and main_source.contains("AIRFRAME LOST // EJECTION SEQUENCE"), "visual QA should expose deterministic early, breakup and ejection states for VX-94 loss art")
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
	_expect(source.contains("func _render_airframe_shadow") and source.contains("visible_hull") and source.contains("CraftFormDirector"), "atmospheric hostile airframes should cast their authored silhouette with altitude-aware separation")
	_expect(source.contains("ORBITAL_AIR_SPRITES.has(enemy_id)") and source.contains("AltitudeRules.ORBITAL"), "orbital hostiles should not receive an atmospheric contact shadow")
	_expect(source.contains("func _render_mercenary_position_lights") and source.contains("MERCENARY_AIR_SPRITES.has(enemy_id)") and source.contains("fposmod(age + phase * 0.09, 1.18)"), "human hostile aircraft should retain subdued navigation lamps and an asynchronous anti-collision strobe for dark-terrain separation")
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
	_expect(source.contains("func _draw_infantry_member") and source.contains("shadow_size") and source.contains("Color(1.16,1.14,1.08,0.24)"), "human-scale squads should retain registered contact shadows and a restrained value lift over detailed terrain")
	_expect(source.contains("func _render_airframe_weapon_discharge") and source.contains('"scout_falcon", "ace_interceptor", "drone_scout", "drone_hunter", "phase_interceptor"') and source.contains("direction.orthogonal() * 4.0"), "ordinary and pursuit-capable hostile fighters should expose authored single/twin hardpoint discharge instead of spawning disconnected rounds")
	_expect(FileAccess.file_exists("res://assets/source/enemies/air_specialist/air_specialist_asset_manifest.json"), "air specialist source/runtime manifest should exist")
	var layered_human_air_sizes := {
		"gunship_mount":Vector2(15,15), "gunship_turret":Vector2(16,20), "gunship_barrel":Vector2(12,24), "gunship_barrel_recoil":Vector2(12,24), "gunship_sensor":Vector2(8,8),
		"chopper_rotor_0":Vector2(36,36), "chopper_rotor_1":Vector2(36,36), "chopper_rotor_2":Vector2(36,36), "chopper_rotor_3":Vector2(36,36), "chopper_rotor_hub":Vector2(12,12),
		"chopper_cannon":Vector2(12,15), "chopper_barrel":Vector2(10,20), "chopper_barrel_recoil":Vector2(10,20),
		"bomber_bay_closed":Vector2(20,20), "bomber_bay_opening":Vector2(20,20), "bomber_bay_open":Vector2(20,20), "bomber_bay_fire":Vector2(20,20), "bomber_door_left":Vector2(7,18), "bomber_door_right":Vector2(7,18),
		"missile_rail_loaded":Vector2(7,13), "mounted_missile":Vector2(8,14), "missile_rail_empty":Vector2(7,13), "air_sensor_cluster":Vector2(11,8), "damaged_turret":Vector2(16,19), "separated_rotor_blade":Vector2(29,8),
	}
	for human_air_layer_id in layered_human_air_sizes:
		var human_air_layer := load("res://assets/runtime/enemies/human_air_layered/%s.png" % human_air_layer_id) as Texture2D
		_expect(human_air_layer != null and human_air_layer.get_size() == layered_human_air_sizes[human_air_layer_id], "layered human-air component should retain its registered canvas: %s" % human_air_layer_id)
	_expect(source.contains('"anchor": Vector2(0, 5)') and source.contains('"anchor": Vector2(0, 7)') and source.contains("_render_air_component"), "gunship and helicopter weapons should attach to reviewed independent hardpoints")
	_expect(source.contains('argument.begins_with("--capture-air=")') and source.contains('_capture_air_state() == "human"') and source.contains("_render_human_air_capture") and source.contains('{"id":"scout_falcon"') and source.contains('"visual_bank":sin(time*2.0)'), "visual QA should expose an isolated human-air scout, bank, rotor, tracking, recoil, and bay fixture")
	_expect(source.contains('_capture_air_state() == "hypersonic"') and source.contains("_render_hypersonic_air_capture") and source.contains('"hypersonic_boom_age":boom_age'), "visual QA should expose transforming human, machine, and orbital hypersonic pursuers")
	_expect(FileAccess.file_exists("res://assets/source/enemies/human_air_layered/human_air_layered_manifest.json"), "layered human-air source/runtime manifest should exist")
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
	var layered_machine_air_sizes := {
		"core_dim":Vector2(13,13), "core_active":Vector2(13,13), "core_overload":Vector2(13,13), "core_collar":Vector2(15,15), "core_damaged":Vector2(14,14),
		"hunter_mount":Vector2(17,20), "hunter_barrel":Vector2(6,18), "hunter_barrel_recoil":Vector2(6,18),
		"bomber_bay_closed":Vector2(17,22), "bomber_bay_opening":Vector2(17,22), "bomber_bay_open":Vector2(17,22), "bomber_bay_fire":Vector2(17,22), "bomber_door_left":Vector2(8,19), "bomber_door_right":Vector2(8,19),
		"missile_hatch_closed":Vector2(12,21), "missile_hatch_opening":Vector2(12,21), "missile_hatch_open":Vector2(12,21), "missile_hatch_fire":Vector2(12,27), "missile_hatch_door":Vector2(12,15), "mounted_missile":Vector2(8,17),
		"armor_fragment_large":Vector2(10,13), "armor_fragment_small":Vector2(8,11), "thruster_dim":Vector2(10,12), "thruster_active":Vector2(10,13), "thruster_overload":Vector2(10,16),
	}
	for machine_air_layer_id in layered_machine_air_sizes:
		var machine_air_layer := load("res://assets/runtime/enemies/machine_air_layered/%s.png" % machine_air_layer_id) as Texture2D
		_expect(machine_air_layer != null and machine_air_layer.get_size() == layered_machine_air_sizes[machine_air_layer_id], "layered machine-air component should retain its registered canvas: %s" % machine_air_layer_id)
	_expect(source.contains('_capture_air_state() == "machine"') and source.contains("_render_machine_air_capture") and source.contains("_render_machine_component"), "visual QA should expose isolated machine-air banking, propulsion, recoil, core and weapon-door fixtures")
	_expect(source.contains('MACHINE_AIR_SPECIALIST_ART["damaged_core"]') and source.contains("_render_machine_air_propulsion"), "machine airframes should expose layered damage and propulsion states")
	_expect(FileAccess.file_exists("res://assets/source/enemies/machine_air_layered/machine_air_layered_manifest.json"), "layered machine-air source/runtime manifest should exist")
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
	_expect(source.contains("MACHINE_AIR_ROLE_SCALE") and source.contains('"drone_scout":{"core":0.72') and source.contains('"drone_bomber":{"core":1.18'), "Machine War aircraft should scale shared cores and propulsion by scout, hunter, bomber and missile roles")
	_expect(FileAccess.file_exists("res://assets/source/enemies/specialist_mechanics_upgrade_manifest.json"), "machine and BLACK SKY specialist mechanics v2 manifest should exist")
	_expect(FileAccess.file_exists("res://assets/source/enemies/orbital_air_specialist/orbital_air_specialist_asset_manifest.json"), "orbital-air specialist source/runtime manifest should exist")
	var layered_orbital_air_sizes := {
		"sentry_collar":Vector2(17,14), "sentry_turret":Vector2(17,15), "sentry_barrel":Vector2(6,22), "sentry_barrel_recoil":Vector2(6,22),
		"phase_nodes_dormant":Vector2(20,12), "phase_nodes_active":Vector2(20,12), "phase_nodes_overload":Vector2(20,13), "phase_nodes_damaged":Vector2(20,14),
		"beam_aperture_closed":Vector2(18,28), "beam_aperture_opening":Vector2(18,28), "beam_aperture_open":Vector2(18,28), "beam_aperture_fire":Vector2(18,28),
		"rail_safe":Vector2(14,34), "rail_charge_1":Vector2(14,34), "rail_charge_2":Vector2(14,34), "rail_fire":Vector2(14,34), "rail_capacitor_bank":Vector2(12,15), "rail_barrel":Vector2(6,27),
		"orbital_thruster_dim":Vector2(14,12), "orbital_thruster_active":Vector2(15,13), "orbital_thruster_overload":Vector2(16,14), "radiator_cool":Vector2(12,16), "radiator_hot":Vector2(12,16),
		"orbital_fragment_large":Vector2(15,12), "orbital_fragment_small":Vector2(13,10),
	}
	for orbital_air_layer_id in layered_orbital_air_sizes:
		var orbital_air_layer := load("res://assets/runtime/enemies/orbital_air_layered/%s.png" % orbital_air_layer_id) as Texture2D
		_expect(orbital_air_layer != null and orbital_air_layer.get_size() == layered_orbital_air_sizes[orbital_air_layer_id], "layered BLACK SKY component should retain its registered canvas: %s" % orbital_air_layer_id)
	_expect(source.contains('_capture_air_state() == "orbital"') and source.contains("_render_orbital_air_capture") and source.contains("_render_orbital_air_propulsion"), "visual QA should expose isolated BLACK SKY bank, thrust, phase, iris and rail fixtures")
	_expect(source.contains("func _boss_weak_point_family") and source.contains('BOSS_WEAK_POINT_CUES[family]'), "boss weak points should select distinct authored conventional, autonomous and BLACK SKY cue families")
	for family in ["conventional", "machine", "orbital"]:
		for frame in range(4):
			var cue := load("res://assets/runtime/enemies/boss_weak_point/%s/cue_%d.png" % [family, frame]) as Texture2D
			_expect(cue != null and cue.get_size() == Vector2(18,18), "boss weak-point cue should retain reviewed 18x18 geometry: %s %d" % [family, frame])
	_expect(source.contains('definition["barrel_recoil"]') and source.contains('definition["capacitor"]'), "BLACK SKY sentry and lancer should use separately articulated weapon hardware")
	_expect(FileAccess.file_exists("res://assets/source/enemies/orbital_air_layered/orbital_air_layered_manifest.json"), "layered BLACK SKY source/runtime manifest should exist")
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
	var mobile_ground_layers := {
		"light_tank_base":Vector2(36,44), "light_tank_turret":Vector2(44,44), "light_tank_barrel":Vector2(44,44),
		"sam_truck_base":Vector2(32,46), "sam_launcher_stowed":Vector2(44,44), "sam_launcher_rising":Vector2(44,44), "sam_launcher_deployed":Vector2(44,44), "sam_launcher_launch":Vector2(44,44),
		"aa_carrier_base":Vector2(40,46), "aa_weapon_head":Vector2(48,48), "aa_twin_barrels":Vector2(48,48),
	}
	for layer_name in mobile_ground_layers:
		var mobile_layer := load("res://assets/runtime/enemies/mobile_ground_layered/%s.png" % layer_name) as Texture2D
		_expect(mobile_layer != null and mobile_layer.get_size() == mobile_ground_layers[layer_name], "mobile ground layer should retain registered pivot canvas: %s" % layer_name)
	_expect(source.contains("mobile_ground_layered/light_tank_base.png") and source.contains("mobile_ground_layered/aa_twin_barrels.png"), "mobile armour should use weaponless hulls and separately recoiling barrel layers")
	_expect(source.contains('argument.begins_with("--capture-ground=")') and source.contains("_draw_mobile_ground_capture"), "visual QA should expose a simulation-isolated mobile-ground tracking and recoil fixture")
	_expect(source.contains("machine_definitions") and source.contains("LAYERED_MACHINE_GROUND_SPRITES[enemy[\"id\"]]"), "mobile-ground visual QA should include autonomous armour locomotion beside its static factory node contrast")
	_expect(source.contains('layers.has("locomotion")') and source.contains('* 8.0'), "mobile tanks and carriers should consume registered held tread/wheel locomotion frames")
	for vehicle_id in ["light_tank", "sam_truck", "aa_carrier"]:
		for frame_index in range(4):
			var locomotion := load("res://assets/runtime/enemies/mobile_ground_layered/locomotion/%s/%d.png" % [vehicle_id, frame_index]) as Texture2D
			_expect(locomotion != null, "mobile-ground locomotion frame should load: %s %d" % [vehicle_id, frame_index])
	_expect(source.contains('1.16 if enemy_id == "security_patrol_mech"'), "human security mech should retain its reviewed presentation-only readability scale without changing simulation geometry")
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
	_expect(FileAccess.file_exists("res://assets/source/enemies/ground_force_specialist/ground_force_specialist_asset_manifest.json"), "ground-force specialist source/runtime manifest should exist")
	var layered_infantry_sizes := {
		"rifle_advance_0":Vector2(10,16), "rifle_advance_1":Vector2(10,16), "rifle_advance_2":Vector2(10,16), "rifle_aim":Vector2(12,14), "rifle_fire":Vector2(12,14), "rifle_flinch":Vector2(10,14),
		"rifle_kneel":Vector2(14,11), "rifle_kneel_fire":Vector2(14,11), "rifle_prone":Vector2(19,8), "radio_operator":Vector2(10,13), "dropped_rifle":Vector2(11,9), "radio_pack":Vector2(8,11),
		"heavy_loader":Vector2(13,12), "heavy_spotter":Vector2(10,13), "heavy_tripod":Vector2(15,19), "heavy_tripod_recoil":Vector2(15,19), "heavy_ammo_crate":Vector2(9,10), "heavy_ammo_belt":Vector2(12,6),
		"fallen_rifleman":Vector2(18,10), "fallen_heavy":Vector2(18,10), "damaged_tripod":Vector2(11,11), "loose_helmet":Vector2(8,8), "loose_pack":Vector2(9,9), "hit_dust_0":Vector2(13,9), "hit_dust_1":Vector2(14,8),
	}
	for infantry_layer_id in layered_infantry_sizes:
		var infantry_layer := load("res://assets/runtime/enemies/infantry_layered/%s.png" % infantry_layer_id) as Texture2D
		_expect(infantry_layer != null and infantry_layer.get_size() == layered_infantry_sizes[infantry_layer_id], "layered infantry component should retain its registered canvas: %s" % infantry_layer_id)
	_expect(source.contains("INFANTRY_LAYERED_ART") and source.contains("var active_member") and source.contains("offsets[active_member]+Vector2(0,7)"), "rifle squads should assemble independent members with restrained one-at-a-time firing cadence")
	_expect(source.contains('"belt": preload("res://assets/runtime/enemies/infantry_layered/heavy_ammo_belt.png")') and source.contains('definition["tripod_recoil"]') and source.contains('definition["belt"]'), "heavy teams should assemble independent crew, ammunition feed, and tripod recoil layers")
	_expect(source.contains('_capture_ground_state() == "infantry"') and source.contains("_render_infantry_capture"), "visual QA should expose an isolated infantry gait, firing, recoil, and hit fixture")
	_expect(FileAccess.file_exists("res://assets/source/enemies/infantry_layered/infantry_layered_manifest.json"), "layered infantry source/runtime manifest should exist")
	var mech_layer_sizes := {
		"security_cannon":Vector2(18,38), "security_cannon_recoil":Vector2(18,38), "security_barrel":Vector2(12,30), "security_shield":Vector2(16,28), "security_collar":Vector2(14,14),
		"salvage_cutter_arm":Vector2(18,38), "salvage_grapple_open":Vector2(18,38), "salvage_grapple_closed":Vector2(18,38), "salvage_disc_0":Vector2(16,16), "salvage_disc_1":Vector2(16,16), "salvage_disc_2":Vector2(16,16), "salvage_collar":Vector2(14,14),
	}
	for mech_layer_id in mech_layer_sizes:
		var mech_layer := load("res://assets/runtime/enemies/ground_mech_layered/%s.png" % mech_layer_id) as Texture2D
		_expect(mech_layer != null and mech_layer.get_size() == mech_layer_sizes[mech_layer_id], "ground-mech appendage should retain its registered pivot canvas: %s" % mech_layer_id)
	_expect(source.contains('"primary_anchor": Vector2(-10, -5)') and source.contains('"secondary_anchor": Vector2(13, -4)'), "ground-mech appendages should attach at reviewed independent shoulder hardpoints")
	_expect(source.contains('_capture_ground_state() == "mechs"') and source.contains("_render_mech_capture"), "visual QA should expose an isolated live mech gait, aim, recoil, grapple, and cutter fixture")
	_expect(FileAccess.file_exists("res://assets/source/enemies/ground_mech_layered/ground_mech_layered_manifest.json"), "layered ground-mech source/runtime manifest should exist")
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
	var layered_naval_sizes := {
		"river_mount":Vector2(14,14), "river_turret":Vector2(14,28), "river_turret_recoil":Vector2(14,28),
		"torpedo_turret":Vector2(14,21), "torpedo_launcher_closed":Vector2(12,19), "torpedo_launcher_opening":Vector2(12,19), "torpedo_launcher_open":Vector2(12,19), "torpedo_launcher_fire":Vector2(12,19),
		"fast_turret":Vector2(16,23), "fast_radar_pedestal":Vector2(10,13), "fast_radar_array":Vector2(14,12),
		"corvette_turret":Vector2(18,25), "corvette_mount":Vector2(13,13), "corvette_launcher_closed":Vector2(15,23), "corvette_launcher_opening":Vector2(15,23), "corvette_launcher_open":Vector2(15,23), "corvette_launcher_fire":Vector2(15,23),
	}
	for naval_layer_id in layered_naval_sizes:
		var naval_layer := load("res://assets/runtime/enemies/naval_layered/%s.png" % naval_layer_id) as Texture2D
		_expect(naval_layer != null and naval_layer.get_size() == layered_naval_sizes[naval_layer_id], "layered naval component should retain its registered pivot canvas: %s" % naval_layer_id)
	_expect(source.contains('"radar_anchor": Vector2(0, -11)') and source.contains('"turret_anchor": Vector2(0, 17)'), "naval components should attach to reviewed independent deck hardpoints")
	_expect(source.contains('_capture_ground_state() == "naval"') and source.contains("_render_naval_capture"), "visual QA should expose an isolated live naval wake, tracking, recoil, radar, and launcher fixture")
	_expect(FileAccess.file_exists("res://assets/source/enemies/naval_layered/naval_layered_manifest.json"), "layered naval source/runtime manifest should exist")
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
	for frame_index in range(4):
		var armor_locomotion := load("res://assets/runtime/enemies/machine_ground_layered/locomotion/autonomous_armor/%d.png" % frame_index) as Texture2D
		_expect(armor_locomotion != null and armor_locomotion.get_size() == Vector2(36,30), "autonomous armour locomotion should retain the registered 36x30 chassis canvas: %d" % frame_index)
	_expect(FileAccess.file_exists("res://tools/build_machine_ground_locomotion_art.ps1"), "autonomous armour locomotion should retain a reproducible builder")
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
	for frame_index in range(4):
		var weak_point_cue := load("res://assets/runtime/enemies/boss_weak_point/cue_%d.png" % frame_index) as Texture2D
		_expect(weak_point_cue != null and weak_point_cue.get_size() == Vector2(18,18), "boss weak-point cue should retain reviewed 18x18 registration: %d" % frame_index)
	_expect(CombatArtDirector.BOSS_WEAK_POINTS.size() == 9, "all nine bosses should register their three authored physical weak points")
	for boss_id in CombatArtDirector.BOSS_WEAK_POINTS:
		_expect(CombatArtDirector.BOSS_WEAK_POINTS[boss_id].size() == 3, "boss should retain three documented weak-point stations: %s" % boss_id)
	_expect(source.contains("_draw_boss_weak_points") and source.contains("boss_phase >= 3"), "phase-three bosses should reveal the authored on-hull weak-point cue")
	_expect(FileAccess.file_exists("res://assets/source/enemies/boss_weak_point_v1/runtime_integration.json"), "boss weak-point presentation should retain native runtime evidence")
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
	var layered_mercenary_boss_sizes := {
		"gunship_collar":Vector2(28,25), "gunship_turret":Vector2(26,28), "gunship_barrel":Vector2(14,31), "gunship_barrel_recoil":Vector2(14,31), "gunship_barrel_hot":Vector2(14,31),
		"gunship_engine_normal":Vector2(24,28), "gunship_engine_hot":Vector2(24,28), "gunship_engine_damaged":Vector2(24,28), "gunship_cracked_plate":Vector2(22,24),
		"train_collar":Vector2(28,23), "train_turret":Vector2(26,28), "train_turret_damaged":Vector2(27,29), "train_barrel":Vector2(15,31), "train_barrel_recoil":Vector2(15,31), "train_barrel_hot":Vector2(15,31),
		"train_vent_closed":Vector2(14,12), "train_vent_open":Vector2(14,12), "train_bogie_intact":Vector2(22,17), "train_bogie_damaged":Vector2(23,17),
		"cruiser_collar":Vector2(28,21), "cruiser_turret":Vector2(26,27), "cruiser_barrel":Vector2(16,31), "cruiser_barrel_recoil":Vector2(16,31),
		"cruiser_hatch_port":Vector2(29,17), "cruiser_hatch_starboard":Vector2(29,17), "cruiser_cells_closed":Vector2(24,26), "cruiser_cells_opening":Vector2(24,26), "cruiser_cells_open":Vector2(24,26), "cruiser_cells_fire":Vector2(24,26),
		"cruiser_radar_damaged":Vector2(26,24), "cruiser_scorched_deck":Vector2(46,21),
	}
	for component_id in layered_mercenary_boss_sizes:
		var component := load("res://assets/runtime/enemies/mercenary_boss_layered/%s.png" % component_id)
		_expect(component is Texture2D and component.get_size()==layered_mercenary_boss_sizes[component_id],"layered mercenary-boss mechanism should retain its registered pivot canvas: %s" % component_id)
	_expect(source.contains('argument.begins_with("--capture-boss=")') and source.contains('_capture_boss_state() == "mercenary"') and source.contains("_render_mercenary_boss_capture"),"visual QA should expose isolated conventional boss phase, recoil, engine, vent and missile-cell fixtures")
	_expect(source.contains("AIRCRAFT_NAVIGATION_LIGHTS") and source.contains("_draw_registered_navigation_light") and not source.contains("surface.draw_rect(Rect2(left") and not source.contains("surface.draw_rect(Rect2(strobe"),"human aircraft navigation lamps should use authored registered raster clusters rather than vector programmer marks")
	_expect(source.contains('enemy_id != "gunship_alpha"') and source.contains('if enemy_id == "gunship_alpha":\n\t\t_render_mercenary_position_lights'),"Gunship Alpha should share the restrained military navigation-light language with the conventional airframe family")
	for light_id in ["port_red", "starboard_green", "anti_collision_white"]:
		var light := load("res://assets/runtime/effects/aircraft_navigation_lights/%s.png" % light_id)
		_expect(light is Texture2D and light.get_size() == Vector2(5,5), "aircraft navigation light should retain its five-pixel registered canvas: %s" % light_id)
	_expect(FileAccess.file_exists("res://assets/source/effects/aircraft_navigation_lights_manifest.json"),"aircraft navigation light source/runtime manifest should exist")
	_expect(source.contains('definition["barrel_recoil"]') and source.contains('definition["engines"]') and source.contains('definition["bogies"]') and source.contains('definition["damage"]'),"mercenary bosses should expose independently animated weapon, propulsion and damage mechanisms")
	_expect(FileAccess.file_exists("res://assets/source/enemies/mercenary_boss_layered/mercenary_boss_layered_manifest.json"),"layered mercenary-boss source/runtime manifest should exist")
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
	var layered_machine_boss_sizes := {
		"swarm_rack_closed":Vector2(48,46), "swarm_rack_opening":Vector2(48,46), "swarm_rack_open":Vector2(48,46),
		"swarm_drone_folded":Vector2(23,26), "swarm_drone_ready":Vector2(31,27), "swarm_sensor":Vector2(33,32), "swarm_sensor_damaged":Vector2(33,32),
		"swarm_core_normal":Vector2(18,30), "swarm_core_overload":Vector2(18,30), "swarm_core_ruptured":Vector2(19,30),
		"forge_conveyor":Vector2(54,35), "forge_conveyor_broken":Vector2(58,31), "forge_blank_light":Vector2(22,27), "forge_blank_medium":Vector2(22,27), "forge_blank_heavy":Vector2(23,27),
		"forge_press_raised":Vector2(42,35), "forge_press_lowered":Vector2(44,35), "forge_press_scorched":Vector2(45,30),
		"forge_arm_extended":Vector2(46,37), "forge_arm_retracted":Vector2(40,35), "forge_arm_severed":Vector2(54,31), "forge_tool_head":Vector2(34,33),
		"forge_crucible_closed":Vector2(40,37), "forge_crucible_open":Vector2(43,37),
	}
	for component_id in layered_machine_boss_sizes:
		var component := load("res://assets/runtime/enemies/machine_boss_layered/%s.png" % component_id)
		_expect(component is Texture2D and component.get_size()==layered_machine_boss_sizes[component_id],"layered machine-boss mechanism should retain its registered pivot canvas: %s" % component_id)
	_expect(CombatArtDirector.machine_swarm_rack_frame_index(1.0,0.0)==0 and CombatArtDirector.machine_swarm_rack_frame_index(0.5,0.0)==1 and CombatArtDirector.machine_swarm_rack_frame_index(0.2,0.0)==2 and CombatArtDirector.machine_swarm_rack_frame_index(1.0,0.8)==2,"swarm rack should communicate closed, preparing and launch-ready poses")
	_expect(source.contains('_capture_boss_state() == "machine"') and source.contains("_render_machine_boss_capture"),"visual QA should expose isolated machine-boss process, phase, launch, and damage fixtures")
	_expect(source.contains('definition["cores"]') and source.contains('definition["conveyors"]') and source.contains('definition["presses"]') and source.contains('definition["crucibles"]'),"machine bosses should visibly change their physical process and damaged mechanisms")
	_expect(FileAccess.file_exists("res://assets/source/enemies/machine_boss_layered/machine_boss_layered_manifest.json"),"layered machine-boss source/runtime manifest should exist")
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
	var layered_orbital_boss_sizes := {
		"command_collar":Vector2(33,33), "command_dish":Vector2(33,31), "command_beam":Vector2(18,34), "command_beam_recoil":Vector2(18,34), "command_mast_folded":Vector2(20,35), "command_mast_deployed":Vector2(20,36),
		"command_core_normal":Vector2(17,29), "command_core_overload":Vector2(17,29), "command_core_ruptured":Vector2(18,29),
		"phase_lens_calm":Vector2(44,44), "phase_lens_charge":Vector2(44,44), "phase_lens_aligned":Vector2(44,44), "phase_lens_unstable":Vector2(45,44), "phase_shutter_closed":Vector2(21,35), "phase_shutter_open":Vector2(23,35), "phase_projector":Vector2(26,32), "phase_projector_damaged":Vector2(28,32),
		"warden_collar":Vector2(36,36), "warden_rail":Vector2(20,43), "warden_rail_recoil":Vector2(20,43), "warden_point_turret":Vector2(31,27), "warden_clamp_closed":Vector2(22,34), "warden_clamp_open":Vector2(32,34), "warden_clamp_broken":Vector2(47,28), "warden_vent_closed":Vector2(29,27), "warden_vent_hot":Vector2(29,27), "warden_rail_scorched":Vector2(43,28),
		"ark_aperture_closed":Vector2(41,41), "ark_aperture_opening":Vector2(41,41), "ark_aperture_open":Vector2(43,41), "ark_arc_retracted":Vector2(21,38), "ark_arc_extended":Vector2(29,41), "ark_arc_severed":Vector2(26,32), "ark_tracking_pylon":Vector2(28,35), "ark_core_normal":Vector2(21,32), "ark_core_overload":Vector2(21,32), "ark_core_ruptured":Vector2(23,32), "ark_cracked_plate":Vector2(30,27),
	}
	for component_id in layered_orbital_boss_sizes:
		var component := load("res://assets/runtime/enemies/orbital_boss_layered/%s.png" % component_id)
		_expect(component is Texture2D and component.get_size()==layered_orbital_boss_sizes[component_id],"layered BLACK SKY boss mechanism should retain its registered pivot canvas: %s" % component_id)
	_expect(CombatArtDirector.orbital_mechanism_frame_index(0.0,1)==0 and CombatArtDirector.orbital_mechanism_frame_index(0.34,1)==1 and CombatArtDirector.orbital_mechanism_frame_index(0.50,2)==2,"orbital mechanisms should retain held phase-responsive exposures")
	_expect(source.contains('_capture_boss_state() == "orbital"') and source.contains("_render_orbital_boss_capture"),"visual QA should expose all four isolated BLACK SKY boss mechanism, phase and damage fixtures")
	_expect(source.contains('definition["lenses"]') and source.contains('definition["clamps"]') and source.contains('definition["apertures"]') and source.contains('definition["cores"]'),"BLACK SKY bosses should use distinct command, phase, station and ark machinery")
	_expect(FileAccess.file_exists("res://assets/source/enemies/orbital_boss_layered/orbital_boss_layered_manifest.json"),"layered BLACK SKY boss source/runtime manifest should exist")

func _test_transform_presentation() -> void:
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable for transform checks")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("CraftFormRules.TRANSFORM_VISUAL_SECONDS"), "variable geometry sweep should consume the canonical near-one-second mechanical cadence")
	_expect(source.contains("TRANSFORM_EXPOSURES := 10"), "variable geometry should retain ten deliberate animation exposures")
	_expect(source.contains("func _draw_transform_motion_cues") and source.contains("start_left.lerp(end_left,progress)"), "variable geometry sweep should expose readable wing-tip travel and hinge cues at gameplay scale")
	_expect(source.contains("PRESENTATION_REDRAW_SECONDS := 1.0 / 30.0"), "combat sprites should retain an authentic held-pose 30 Hz presentation cadence over 60 Hz simulation")
	_expect(source.contains("_visual_sweep = move_toward"), "visual wing geometry should interpolate rather than snap")
	_expect(source.contains("roundf(_visual_sweep * float(TRANSFORM_EXPOSURES - 1))"), "variable geometry should advance through quantized authored exposures")
	_expect(source.contains("_draw_transform_exposure(surface, p, exposure, true)"), "hypersonic charge should use the deeper registered folded-wing sprite family")
	_expect(source.contains("VX94_BOMBER_TRANSFORM") and source.contains("VX94_HYPERSONIC_TRANSFORM"), "live variable geometry should use two authored ten-exposure raster families")
	_expect(source.contains("--capture-transform-exposure="), "visual QA should expose every exact registered geometry exposure")
	var hud_source := FileAccess.get_file_as_string("res://scripts/pixel_ui_director.gd")
	_expect(hud_source.contains("func _compact_form_state") and hud_source.contains('"F>B%d"') and hud_source.contains("transform_ratio"), "HUD should report mechanical form-transition progress instead of claiming the destination form instantly")
	_expect(not source.contains("_draw_pivoted_component") and not source.contains("VX94_LAYERED"), "live VX-94 geometry must not rotate aircraft component bitmaps like paper")
	_expect(source.contains("vx94_transform_01.png") and source.contains("vx94_transform_02.png") and source.contains("vx94_transform_03.png"), "VX-94 transformation should retain all three authored mechanical intermediate keyframes")
	_expect(not source.contains("func _draw_transforming") and not source.contains("func _draw_rotary_cannon"), "obsolete procedural VX-94 construction should remain removed")
	_expect(source.contains("_preload_player_transform_loadouts") and source.contains("_draw_transform_external_stores"), "ten-exposure transforms should select mounted primary hardware and retained external-store state")
	var open_hypersonic := load("res://assets/runtime/craft/vx94/transform/hypersonic_00.png") as Texture2D
	var tucked_hypersonic := load("res://assets/runtime/craft/vx94/transform/hypersonic_09.png") as Texture2D
	_expect(open_hypersonic != null and tucked_hypersonic != null and open_hypersonic.get_image().get_used_rect().size.x - tucked_hypersonic.get_image().get_used_rect().size.x >= 14, "hypersonic geometry must produce a clearly readable deep wing tuck at gameplay scale")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/transform_v3/manifest.json"), "deep-sweep hypersonic art should preserve its predecessor and build evidence")
	for destination in ["bomber", "hypersonic"]:
		for weapon_family in ["ballistic", "needle_rail", "storm_cannon", "plasma_lance"]:
			for exposure in range(10):
				var primary_transform := load("res://assets/runtime/craft/vx94/gameplay/transform_primary/%s_%s_%02d.png" % [destination, weapon_family, exposure]) as Texture2D
				_expect(primary_transform != null and primary_transform.get_size() == Vector2(64,72), "mounted primary transform should retain registered exposure: %s %s %02d" % [destination, weapon_family, exposure])
		for store_kind in ["hunter_rack", "twin_rocket_pods"]:
			for store_state in ["loaded", "left_expended", "empty"]:
				for exposure in range(10):
					for layer_index in range(2):
						var transform_store := load("res://assets/runtime/craft/vx94/gameplay/transform_stores/%s_%s_%s_%02d_%d.png" % [destination, store_kind, store_state, exposure, layer_index]) as Texture2D
						_expect(transform_store != null and transform_store.get_size() == Vector2(64,72), "transforming store layer should retain registered exposure: %s %s %s %02d %d" % [destination, store_kind, store_state, exposure, layer_index])
	for store_state in ["loaded", "left_released", "empty"]:
		for exposure in range(10):
			for layer_index in range(2):
				var bomb_transform := load("res://assets/runtime/craft/vx94/gameplay/transform_stores/bomber_precision_bomb_%s_%02d_%d.png" % [store_state, exposure, layer_index]) as Texture2D
				_expect(bomb_transform != null and bomb_transform.get_size() == Vector2(64,72), "transforming precision-bomb layer should retain registered exposure: %s %02d %d" % [store_state, exposure, layer_index])
	for destination in ["bomber", "hypersonic"]:
		for module_id in ["point_defence_pod", "emp_disruptor", "magnetic_screen"]:
			for module_state in ["idle", "active"]:
				for exposure in range(10):
					var transform_module := load("res://assets/runtime/craft/vx94/gameplay/transform_modules/%s_%s_%s_%02d.png" % [destination, module_id, module_state, exposure]) as Texture2D
					_expect(transform_module != null and transform_module.get_size() == Vector2(64,72), "transforming dorsal module should retain registered exposure: %s %s %s %02d" % [destination, module_id, module_state, exposure])
			for damage_state in ["scarred", "burnt"]:
				for exposure in range(10):
					var transform_module_damage := load("res://assets/runtime/craft/vx94/gameplay/transform_module_damage/%s_%s_%s_%02d.png" % [destination, module_id, damage_state, exposure]) as Texture2D
					_expect(transform_module_damage != null and transform_module_damage.get_size() == Vector2(64,72), "transforming module damage should retain registered exposure: %s %s %s %02d" % [destination, module_id, damage_state, exposure])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/transform_primary_v1/runtime_integration.json"), "primary transform runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/transform_stores_v2/runtime_integration.json"), "transform store runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/transform_precision_bombs_v1/runtime_integration.json"), "precision-bomb transform runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/transform_dorsal_modules_v1/runtime_integration.json"), "dorsal-module transform runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/transform_module_damage_v1/runtime_integration.json"), "transforming module-damage runtime receipt should exist")
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
	_expect(source.contains("_altitude_pitch_state") and source.contains("_pitch_primary_cache"), "VX-94 altitude changes should select authored pitch silhouettes with the installed primary weapon")
	for form in ["fighter", "bomber"]:
		for pitch_state in ["dive_18", "dive_12", "dive_06", "neutral", "climb_06", "climb_12", "climb_18"]:
			for family in ["ballistic", "needle_rail", "storm_cannon", "plasma_lance"]:
				for hardware_state in range(4):
					var pitch_texture := load("res://assets/runtime/craft/vx94/gameplay/pitch_primary/%s_%s_%s_%d.png" % [family, form, pitch_state, hardware_state]) as Texture2D
					_expect(pitch_texture != null and pitch_texture.get_size() == Vector2(64,72), "weapon-mounted pitch exposure should retain registered canvas: %s %s %s %d" % [family, form, pitch_state, hardware_state])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/pitch_relief_v3/runtime_loadout_integration.json"), "weapon-mounted pitch family should retain a source/runtime receipt")
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
			_expect(static_texture is Texture2D and static_texture.get_size()==Vector2(64,72), "airframe static attachment must retain reviewed VX-94 canvas: %s %s" % [form,static_layer])
		for animated_layer in ["magnetic", "field"]:
			for frame_index in range(3):
				var animation_texture := load("res://assets/runtime/craft/vx94/gameplay/airframe/%s_%s_%d.png" % [form,animated_layer,frame_index])
				_expect(animation_texture is Texture2D and animation_texture.get_size()==Vector2(64,72), "airframe animated attachment must retain reviewed VX-94 canvas: %s %s %d" % [form,animated_layer,frame_index])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/airframe_attachment_manifest.json"), "VX-94 layered airframe attachment manifest should exist")
	var combat_source := FileAccess.get_file_as_string("res://scripts/combat_art_director.gd")
	_expect(combat_source.contains("_preload_player_housings") and combat_source.contains("_player_housing_texture"), "live VX-94 rendering should select weapon hardware before drawing the banked aircraft")
	for form in ["fighter", "bomber"]:
		for bank in ["hard_left", "left", "neutral", "right", "hard_right"]:
			for state in range(4):
				var primary_housing := load("res://assets/runtime/craft/vx94/gameplay/primary_housings/%s_%s_%d.png" % [form, bank, state]) as Texture2D
				_expect(primary_housing != null and primary_housing.get_size() == Vector2(64,72), "conventional primary housing should retain registered canvas: %s %s %d" % [form, bank, state])
				for weapon_id in ["needle_rail", "storm_cannon", "plasma_lance"]:
					var specialist_housing := load("res://assets/runtime/craft/vx94/gameplay/specialist_housings/%s_%s_%s_%d.png" % [weapon_id, form, bank, state]) as Texture2D
					_expect(specialist_housing != null and specialist_housing.get_size() == Vector2(64,72), "specialist primary housing should retain registered canvas: %s %s %s %d" % [weapon_id, form, bank, state])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/banked_primary_housings_v2/runtime_integration.json"), "conventional primary housing runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/specialist_housings_v2/runtime_integration.json"), "specialist primary housing runtime receipt should exist")
	_expect(combat_source.contains("_draw_player_external_stores") and combat_source.contains("_draw_player_dorsal_module"), "live VX-94 rendering should bind external stores and defensive modules to gameplay state")
	for form in ["fighter", "bomber"]:
		for bank in ["hard_left", "left", "neutral", "right", "hard_right"]:
			for kind in ["hunter_rack", "twin_rocket_pods"]:
				var partial_state := "left_released" if kind == "hunter_rack" else "left_expended"
				for state in ["loaded", partial_state, "empty"]:
					for layer_index in range(2):
						var store := load("res://assets/runtime/craft/vx94/gameplay/external_stores/%s_%s_%s_%s_%d.png" % [form, kind, state, bank, layer_index]) as Texture2D
						_expect(store != null and store.get_size() == Vector2(64,72), "banked external store layer should retain registered canvas: %s %s %s %s %d" % [form, kind, state, bank, layer_index])
			for module_id in ["point_defence_pod", "emp_disruptor", "magnetic_screen"]:
				for active_state in ["idle", "active"]:
					var module := load("res://assets/runtime/craft/vx94/gameplay/dorsal_modules/%s_%s_%s_%s.png" % [module_id, form, active_state, bank]) as Texture2D
					_expect(module != null and module.get_size() == Vector2(64,72), "dorsal support module should retain registered canvas: %s %s %s %s" % [module_id, form, active_state, bank])
				for damage_state in ["scarred", "burnt"]:
					var module_damage := load("res://assets/runtime/craft/vx94/gameplay/module_damage/%s_%s_%s_%s.png" % [module_id, form, damage_state, bank]) as Texture2D
					_expect(module_damage != null and module_damage.get_size() == Vector2(64,72), "localized module damage should retain registered canvas: %s %s %s %s" % [module_id, form, damage_state, bank])
	for bank in ["hard_left", "left", "neutral", "right", "hard_right"]:
		for state in ["loaded", "left_released", "empty"]:
			for layer_index in range(2):
				var bomb_store := load("res://assets/runtime/craft/vx94/gameplay/external_stores/bomber_precision_bomb_%s_%s_%d.png" % [state, bank, layer_index]) as Texture2D
				_expect(bomb_store != null and bomb_store.get_size() == Vector2(64,72), "precision-bomb store layer should retain registered canvas: %s %s %d" % [state, bank, layer_index])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/banked_external_stores_v2/runtime_integration.json"), "external store runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/dorsal_modules_v1/runtime_integration.json"), "dorsal module runtime receipt should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/module_damage_v1/runtime_integration.json"), "module damage runtime receipt should exist")

func _test_combat_fx() -> void:
	var file := FileAccess.open("res://scripts/combat_fx_director.gd", FileAccess.READ)
	_expect(file != null, "combat FX director should be readable")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("const MAX_EVENTS := 48"), "combat FX event count should stay bounded")
	_expect(source.contains('"hit"') and source.contains('"explosion"') and source.contains('"boss_explosion"') and source.contains('"shield_hit"') and source.contains('"shield_break"') and source.contains('"player_hit"'), "combat FX should distinguish shield contact, shield collapse, hull strikes, kills and bosses")
	_expect(source.contains("_draw_explosion"), "enemy destruction should receive pixel explosion feedback")
	_expect(source.contains("EXPLOSION_FRAMES"), "enemy destruction should use the authored eight-frame raster sequence")
	_expect(source.contains("A killing cannon burst ruptures the target") and source.contains("fireball_size") and source.contains("5.80 if impact_family") and source.contains("5.60 if impact_family") and source.contains("detonation_grade"), "lethal cannon, rocket and missile impacts should remain distinct while producing readable target-scale destruction")
	_expect(source.contains("func _draw_destruction_consequence") and source.contains('category == "sea"') and source.contains('faction == "autonomous"'), "enemy destruction should branch into naval, machine, air and ground material consequences")
	_expect(source.contains('enemy_id in ["mercenary_rifle_team", "mercenary_heavy_team"]'), "infantry destruction should use subdued dust/scatter instead of a wreck fire")
	_expect(source.contains('ImpactArtLibrary.frame_for_ratio("water_impact"') and source.contains('ImpactArtLibrary.frame_for_ratio("emp_disruption"'), "naval and autonomous destruction should use authored water and EMP raster effects")
	_expect(source.contains("NAVAL_WRECK_HULLS") and source.contains("NAVAL_SINK_SECONDS") and source.contains("func _draw_naval_sinking"), "naval destruction should retain the authored hull through a dedicated multi-stage sinking window")
	_expect(source.contains("var blast_clock := clampf(ratio * event_duration / blast_duration") and source.contains("_draw_destruction_consequence(surface, p, ratio"), "fast arcade blasts and extended physical wreck sequences should use independent clocks")
	_expect(source.contains("list_angle") and source.contains("sink_offset") and source.contains("bow") and source.contains("stern"), "naval sinking should visibly list, submerge and displace water at separate hull points")
	_expect(source.contains("NAVAL_WRECK_COMPONENTS") and source.contains("turret_center") and source.contains("turret_splash") and source.contains('components.has("launcher")'),"naval destruction should retain launcher layers and eject registered deck turrets into separate water impacts")
	_expect(source.contains("MERCENARY_BOSS_WRECK_HULLS") and source.contains("BOSS_DESTRUCTION_SECONDS") and source.contains("func _draw_mercenary_boss_breakup"),"Sector I bosses should retain their silhouettes through bespoke extended destruction sequences")
	_expect(source.contains('enemy_id == "gunship_alpha"') and source.contains('enemy_id == "armoured_train"') and source.contains("source_region"),"gunship, train and cruiser boss deaths should use materially different roll, sectional breakup and sinking behavior")
	_expect(source.contains("MACHINE_BOSS_WRECK_HULLS") and source.contains("func _draw_machine_boss_breakup"),"machine bosses should retain reviewed hull material through extended physical breakup")
	_expect(source.contains('enemy_id=="swarm_controller"') and source.contains("central_width") and source.contains("tread_center"),"swarm controller and forge should use distinct three-way controller separation and tread/forge collapse")
	_expect(source.contains("ORBITAL_BOSS_WRECK_HULLS") and source.contains("ORBITAL_BOSS_DESTRUCTION_SECONDS") and source.contains("func _draw_orbital_boss_breakup"),"BLACK SKY bosses should receive an extended vacuum-breakup window with retained authored hull material")
	_expect(source.contains('enemy_id=="phase_control_array"') and source.contains('enemy_id=="machine_ark"') and source.contains("section_count"),"phase array should separate by projector quadrant while other orbital infrastructure breaks along authored longitudinal sections")
	_expect(source.contains("GROUND_EMPLACEMENT_BREAKUP_FRAMES") and source.contains("func _draw_ground_emplacement_breakup"),"layered human emplacements should retain authored weapon/ring breakup silhouettes after the primary blast")
	_expect(source.contains("GROUND_MECH_WRECK_HULLS") and source.contains("func _draw_ground_mech_breakup") and source.contains("torso_height") and source.contains("leg_center"),"ground mechs should retain authored torso and actuator clusters through a staged destruction sequence")
	_expect(source.contains("GROUND_VEHICLE_WRECK_LAYERS") and source.contains("func _draw_ground_vehicle_breakup") and source.contains("weapon_lift") and source.contains("chassis_offset"),"layered ground vehicles should preserve independent chassis and weapon assemblies through destruction")
	_expect(source.contains("AIRFRAME_WRECK_HULLS") and source.contains("func _draw_airframe_breakup") and source.contains("wing_width") and source.contains("center_width"),"hostile aircraft should retain their authored wings and fuselage through staged destruction")
	_expect(FileAccess.file_exists("res://assets/source/enemies/airframe_breakup_manifest.json"),"hostile-airframe breakup production manifest should exist")
	for emplacement in ["fort","flak"]:
		for frame_index in range(3):
			var breakup_frame := load("res://assets/runtime/effects/ground_breakup/%s_breakup_%d.png" % [emplacement,frame_index])
			_expect(breakup_frame is Texture2D and breakup_frame.get_size()==Vector2(40,40),"ground-emplacement breakup frame should retain 40x40 wreck canvas: %s/%d" % [emplacement,frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/ground_breakup/ground_breakup_asset_manifest.json"),"ground-emplacement breakup source/runtime manifest should exist")
	_expect(FileAccess.file_exists("res://assets/source/effects/destruction_consequence_asset_manifest.json"), "destruction consequence source/runtime manifest should exist")
	_expect(source.contains("_draw_player_hit") and source.contains("SHIELD_BREAK_SECONDS") and source.contains("RetroSfxRules.SHIELD_BREAK"), "VX-94 damage should receive distinct shield-contact, shield-collapse and hull-impact feedback")
	_expect(source.contains("func register_player_loss") and source.contains('"WARHEAD" in status') and source.contains('"enemy_id":"vx94"'), "fatal VX-94 damage should carry its causing warhead or cannon blast into the authored breakup sequence")
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
	_expect(not source.contains("draw_line") and not source.contains("draw_rect") and not source.contains("_draw_panel_scars"), "VX-94 damage must not regress to procedural line/rectangle scars")
	for forbidden in ['scene.set("hull"', 'scene.set("shield"', 'var extra_health']:
		_expect(not source.contains(forbidden), "damage-state presentation must not create or mutate durability state: %s" % forbidden)
	var combat_file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	var combat_source := combat_file.get_as_text() if combat_file != null else ""
	_expect(combat_source.contains('VX94_DAMAGE := {') and combat_source.contains('VX94_DAMAGE["fighter"]') and combat_source.contains('VX94_DAMAGE["bomber"]') and combat_source.contains("func _draw_player_damage"), "VX-94 hull scars should use form-registered authored overlays")
	for form_name in ["fighter", "bomber"]:
		for stage_name in ["light", "damaged", "critical"]:
			var damage_texture := load("res://assets/runtime/craft/vx94/gameplay/damage/%s_%s.png" % [form_name, stage_name])
			_expect(damage_texture is Texture2D and damage_texture.get_size() == Vector2(64,72), "VX-94 damage overlay should retain reviewed gameplay registration: %s %s" % [form_name, stage_name])
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/vx94_damage_overlay_manifest.json"), "VX-94 form damage source/runtime manifest should exist")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/layered/vx94_layered_manifest.json"), "VX-94 should retain a governed articulated component and pivot contract")
	_expect(FileAccess.file_exists("res://tools/build_vx94_layered_art.ps1"), "VX-94 articulated runtime components should remain reproducible")
	_expect(FileAccess.file_exists("res://tools/build_vx94_transform_art.ps1") and FileAccess.file_exists("res://tools/build_vx94_transform_frames.gd"), "registered transformation sprite families should remain reproducible")
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/layered/vx94_transform_frames_manifest.json"), "registered transformation families should retain a source/runtime contract")
	var vx94_component_raw := load("res://assets/source/craft/vx94/layered/vx94_component_sheet_raw_v1.png") as Texture2D
	var vx94_component_clean := load("res://assets/source/craft/vx94/layered/vx94_component_sheet_source_v1.png") as Texture2D
	_expect(vx94_component_raw != null and vx94_component_clean != null and vx94_component_raw.get_size() == Vector2(1536,1024) and vx94_component_clean.get_size() == Vector2(1536,1024), "VX-94 RAW_ART and clean component source should retain identical registration")
	if vx94_component_raw != null and vx94_component_clean != null:
		_expect(vx94_component_raw.get_image().detect_alpha() == Image.ALPHA_NONE, "VX-94 RAW_ART should preserve provider output unchanged")
		_expect(vx94_component_clean.get_image().detect_alpha() != Image.ALPHA_NONE, "VX-94 finished component sheet should use genuine border-connected alpha")
	for component_name in ["fuselage", "wing_left", "wing_right", "actuator_left", "actuator_right", "bay_closed", "bay_open", "hardpoint_left", "hardpoint_right", "tailplane_left", "tailplane_right", "nozzle_left", "nozzle_right", "settle_panel"]:
		var component_texture := load("res://assets/runtime/craft/vx94/layered/%s.png" % component_name) as Texture2D
		_expect(component_texture != null and component_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "VX-94 articulated component should retain transparency: %s" % component_name)
	_expect(combat_source.contains('argument.begins_with("--capture-craft=")') and combat_source.contains('"layered-sweep"'), "visual QA should expose a simulation-isolated articulated VX-94 sweep fixture")
	_expect(combat_source.contains('"hypersonic-sweep"') and combat_source.contains("_draw_transform_exposure"), "visual QA should expose both registered ten-exposure geometry families")
	_expect(combat_source.contains("TRANSFORM_EXPOSURE_THRESHOLDS") and combat_source.contains("func _transform_exposure_index"), "VX-94 transformations should use authored cel holds and accelerated mechanical middle exposures")
	var combat_art := CombatArtDirector.new()
	var previous_transform_index := -1
	for sample in range(101):
		var transform_index := int(combat_art.call("_transform_exposure_index", float(sample) / 100.0))
		_expect(transform_index >= previous_transform_index and transform_index >= 0 and transform_index < 10, "VX-94 cel exposure timing should remain monotonic and bounded at sample %d" % sample)
		previous_transform_index = transform_index
	_expect(int(combat_art.call("_transform_exposure_index", 0.0)) == 0 and int(combat_art.call("_transform_exposure_index", 1.0)) == 9, "VX-94 cel exposure timing should retain exact fighter and destination endpoints")
	combat_art.free()
	for family_name in ["bomber", "hypersonic"]:
		for frame_index in 10:
			var transform_texture := load("res://assets/runtime/craft/vx94/transform/%s_%02d.png" % [family_name, frame_index]) as Texture2D
			_expect(transform_texture != null and transform_texture.get_size() == Vector2(64,72) and transform_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "VX-94 registered transform frame should retain canvas and alpha: %s/%02d" % [family_name, frame_index])

func _test_projectile_art() -> void:
	var projectile_source := FileAccess.open("res://scripts/projectile_cue_director.gd", FileAccess.READ)
	_expect(projectile_source != null, "projectile cue director should be readable")
	if projectile_source != null:
		var source := projectile_source.get_as_text()
		_expect(source.contains("PROJECTILE_FRAMES") and source.contains("_draw_registered_sprite"), "live projectile cues should use registered production sprites")
		_expect(source.contains("Vector2(-1,0)") and source.contains("Color(0.01,0.02,0.03,0.78)"), "authentic projectile mode should retain a one-pixel ink trap over light and dark terrain")
		_expect(source.contains('Color("ffb278")') and source.contains('Color("b8f4ff")'), "enhanced projectile mode should remain a stronger ownership tint")
		_expect(not source.contains("draw_circle(position") and not source.contains("draw_arc(position"), "live projectile bodies should not retain generic vector circles")
	var families := ["ballistic", "enemy_cannon", "homing_missile", "needle_rail", "storm_pulse", "plasma_lance", "support_rocket", "strategic_warhead", "precision_bomb"]
	for family in families:
		for frame_index in range(4):
			var frame := load("res://assets/runtime/effects/projectiles/%s/%d.png" % [family, frame_index])
			_expect(frame is Texture2D and frame.get_size() == Vector2(16,24), "projectile frame should retain registered 16x24 geometry: %s/%d" % [family, frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/projectiles/projectile_asset_manifest.json"), "projectile source/runtime manifest should exist")
	_expect(FileAccess.file_exists("res://assets/source/effects/storm_pulse_v2/runtime_integration.json"), "Storm pulse should retain its reviewed runtime integration receipt")
	_expect(FileAccess.file_exists("res://assets/source/effects/combat_fx_v2/combat_fx_v2_manifest.json"), "combat FX v2 source/runtime contract should exist")
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
	_expect(FileAccess.file_exists("res://tools/build_combat_fx_v2.ps1"), "combat FX v2 should remain reproducible from its cleaned source sheets")
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
		_expect(source.contains("MAGNETIC_FIELD_FRAMES") and not source.contains("draw_arc") and not source.contains("draw_line"), "magnetic support field should use authored broken-lattice sprite animation")
	for frame_index in range(4):
		var field := load("res://assets/runtime/effects/fields/magnetic_field/%d.png" % frame_index)
		_expect(field is Texture2D and field.get_size() == Vector2(256,256), "magnetic field frame should retain registered 256x256 geometry: %d" % frame_index)

func _test_persistent_effect_art() -> void:
	var trail_families := ["damage_smoke", "damage_fire", "damage_sparks", "afterburner", "contrail", "debris"]
	for family in trail_families:
		for frame_index in range(4):
			var frame := load("res://assets/runtime/effects/persistent/%s/%d.png" % [family, frame_index])
			_expect(frame is Texture2D and frame.get_size() == Vector2(32,40), "persistent effect should retain registered 32x40 geometry: %s/%d" % [family, frame_index])
	for frame_index in range(4):
		var boom := load("res://assets/runtime/effects/persistent/sonic_boom/%d.png" % frame_index)
		_expect(boom is Texture2D and boom.get_size() == Vector2(64,64) and boom.get_image().detect_alpha() != Image.ALPHA_NONE, "sonic-boom pressure frame should retain transparent registered 64x64 geometry: %d" % frame_index)
		var ignition := load("res://assets/runtime/effects/persistent/hypersonic_ignition/%d.png" % frame_index)
		_expect(ignition is Texture2D and ignition.get_size() == Vector2(64,64) and ignition.get_image().detect_alpha() != Image.ALPHA_NONE, "hypersonic ignition frame should retain registered transparent 64x64 geometry: %d" % frame_index)
	_expect(FileAccess.file_exists("res://assets/source/effects/persistent/persistent_asset_manifest.json"), "persistent effect source/runtime manifest should exist")
	var fx_builder := FileAccess.get_file_as_string("res://tools/build_combat_fx_v2.ps1")
	_expect(fx_builder.contains("sonic_boom_runtime_master.svg") and fx_builder.contains("-background none $SonicMaster") and fx_builder.contains("$SonicMasterPreview -crop"), "combat FX build should rasterize and slice the transparent hand-authored lateral pressure master")
	var sonic_master_preview := load("res://assets/source/effects/persistent/sonic_boom_runtime_master.png")
	_expect(sonic_master_preview is Texture2D and sonic_master_preview.get_size() == Vector2(256,64) and sonic_master_preview.get_image().detect_alpha() != Image.ALPHA_NONE, "sonic-boom source preview should remain a transparent registered four-frame master")
	var combat_source_file := FileAccess.open("res://scripts/combat_art_director.gd",FileAccess.READ)
	var combat_source := combat_source_file.get_as_text() if combat_source_file != null else ""
	_expect(combat_source.contains('_capture_fx_state() == "combat"') and combat_source.contains("_render_combat_fx_capture"),"visual QA should expose the complete projectile, impact and persistent FX fixture")
	var damage := FileAccess.open("res://scripts/damage_state_director.gd", FileAccess.READ)
	if damage != null:
		var source := damage.get_as_text()
		_expect(source.contains('frame_for_clock("damage_smoke"') and source.contains('frame_for_clock("damage_sparks"') and source.contains('frame_for_clock("damage_fire"'), "VX-94 progressive damage should use authored smoke, spark and fire attachments")
		_expect(not source.contains("draw_circle") and not source.contains("draw_colored_polygon"), "VX-94 damage effects should not retain smoke circles or vector flame triangles")
	var afterburner := FileAccess.open("res://scripts/afterburner_cue_director.gd", FileAccess.READ)
	if afterburner != null:
		var source := afterburner.get_as_text()
		_expect(source.contains('frame_for_clock("afterburner"') and source.contains('frame_for_clock("contrail"') and source.contains('frame_for_clock("hypersonic_blue_plume"'), "propulsion should separate ordinary afterburner, hypersonic blue plumes and contrails")
		_expect(source.contains('frame_for_ratio("sonic_boom"'), "sonic transition should use the authored broken pressure front")
		_expect(source.contains("Vector2(roundf(lerpf(76.0, 286.0, t)), roundf(lerpf(38.0, 104.0, t)))"), "player sonic break should expand as a shallow transverse pressure front instead of a square ghost-wing exposure")
		_expect(source.contains("SECONDARY_RING_DELAY") and source.contains("PRIMARY_RING_END_SIZE"), "player sonic break should stage expanding primary and secondary engine-origin pressure rings")
		_expect(source.contains('"hypersonic_engine_burst"') and source.contains("ENGINE_BURST_FRAME_ENDS") and not source.contains("draw_circle"), "hypersonic latch should use the registered timed engine burst instead of programmer-art circles")
		_expect(not source.contains("surface.draw_arc(scene.get(\"player_position\")"), "sonic boom should not regress to a perfect vector circle")

func _test_destruction_reward_art() -> void:
	for frame_index in range(8):
		var explosion := load("res://assets/runtime/effects/explosion/explosion_%d.png" % frame_index) as Texture2D
		_expect(explosion != null and explosion.get_size() == Vector2(48,48), "explosion frame should retain registered 48x48 geometry: %d" % frame_index)
	for family in ["flak", "fort"]:
		for frame_index in range(3):
			var breakup := load("res://assets/runtime/effects/ground_breakup/%s_breakup_%d.png" % [family,frame_index]) as Texture2D
			_expect(breakup != null and breakup.get_size() == Vector2(40,40), "ground breakup should retain registered 40x40 geometry: %s/%d" % [family,frame_index])
	for family in ["bomb", "repair", "shield", "weapon"]:
		for frame_index in range(4):
			var pickup := load("res://assets/runtime/effects/pickups/%s_%d.png" % [family,frame_index]) as Texture2D
			_expect(pickup != null and pickup.get_size() == Vector2(32,32), "recovery pod should retain readable 32x32 geometry: %s/%d" % [family,frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/destruction_reward_v2/destruction_reward_v2_manifest.json"), "destruction and reward source/runtime contract should exist")
	_expect(FileAccess.file_exists("res://tools/build_destruction_reward_fx_v2.ps1"), "destruction and reward art should remain reproducible through Sprite Studio")
	_expect(FileAccess.file_exists("res://assets/source/effects/pickups/pickup_animation_sheet.svg") and FileAccess.file_exists("res://tools/build_pickup_art.ps1"), "recovery-pod art should remain reproducible from its crisp-edge SVG master")
	var combat_file := FileAccess.open("res://scripts/combat_art_director.gd",FileAccess.READ)
	var combat_source := combat_file.get_as_text() if combat_file != null else ""
	_expect(combat_source.contains('_capture_fx_state() == "destruction"') and combat_source.contains("_render_destruction_reward_capture"), "visual QA should expose isolated destruction and reward fixtures")

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
	for bay_state in ["bay_closed", "bay_opening", "bay_open"]:
		var bay_texture := load("res://assets/runtime/craft/vx94/gameplay/ventral_bay/%s.png" % bay_state) as Texture2D
		_expect(bay_texture != null and bay_texture.get_size() == Vector2(64,72), "VX-94 ventral bay state should retain full gameplay registration: %s" % bay_state)
	var player_art_source := FileAccess.get_file_as_string("res://scripts/combat_art_director.gd")
	_expect(player_art_source.contains("_draw_player_ventral_bay") and player_art_source.contains("--capture-ventral-bay="), "VX-94 precision ordnance should expose authored ventral-bay runtime states")
	_expect(not player_art_source.contains('kind = "precision_bomb"'), "precision bombs should no longer be rendered as exposed external stores")
	for strategic_state in ["strategic_closed", "strategic_opening", "strategic_open"]:
		var strategic_texture := load("res://assets/runtime/craft/vx94/gameplay/strategic_bay/%s.png" % strategic_state) as Texture2D
		_expect(strategic_texture != null and strategic_texture.get_size() == Vector2(64,72), "VX-94 strategic bay state should retain full gameplay registration: %s" % strategic_state)
	_expect(player_art_source.contains("_draw_player_strategic_bay") and player_art_source.contains("--capture-strategic-bay="), "Micro-Warhead Rack should expose authored strategic-bay runtime states")
	_expect(by_id.has("dorsal_module") and "emp" in by_id["dorsal_module"].get("roles", []), "electronic systems should have dorsal module location")
	var schematic := FileAccess.open("res://scripts/loadout_schematic_director.gd", FileAccess.READ)
	_expect(schematic != null, "loadout schematic should be readable")
	if schematic != null:
		var source := schematic.get_as_text()
		_expect(source.contains("KEY_L"), "L should toggle VX-94 stores schematic")
		_expect(source.contains("player_mounts.json"), "schematic should consume the authored physical mount map")
		_expect(source.contains("FIGHTER") and source.contains("BOMBER / ATTACK"), "schematic should compare both variable-geometry planforms")
		_expect(source.contains("VX94_PLANFORMS") and source.contains("vx94_fighter_v1.png") and source.contains("vx94_bomber_v1.png"), "stores schematic should use the reviewed VX-94 planform masters")
		_expect(source.contains("texture.get_size() * 1.5") and source.contains("float(raw[0]) * 1.5"), "schematic planforms and physical mount coordinates should share the reviewed 1.5x scale")
		_expect(not source.contains("draw_colored_polygon"), "stores schematic should not retain prototype vector aircraft")
		_expect(source.contains("MOUNT_SOCKET") and source.contains("MOUNT_SOCKET_ACTIVE") and source.contains("HARNESS_ACTIVE"), "stores schematic should use authored station sockets and wiring harness sprites")
		_expect(not source.contains("draw_rect") and not source.contains("draw_line"), "stores schematic should not regress to vector station boxes or leader lines")
	var schematic_sizes := {"mount_socket":Vector2(12,12),"mount_socket_active":Vector2(12,12),"harness":Vector2(64,6),"harness_active":Vector2(64,6)}
	for asset_name in schematic_sizes:
		var texture := load("res://assets/runtime/ui/menu/loadout_schematic/%s.png" % asset_name)
		_expect(texture is Texture2D and texture.get_size() == schematic_sizes[asset_name], "stores schematic sprite should retain registered geometry: %s" % asset_name)
	_expect(FileAccess.file_exists("res://assets/source/ui/menu/loadout_schematic_manifest.json"), "stores schematic source/runtime manifest should exist")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
