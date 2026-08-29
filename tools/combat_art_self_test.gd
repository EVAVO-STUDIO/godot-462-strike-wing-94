extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CombatArtDirector = preload("res://scripts/combat_art_director.gd")
const CombatFxDirector = preload("res://scripts/combat_fx_director.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_wiring()
	_test_visual_language()
	_test_transform_presentation()
	_test_altitude_presentation()
	_test_late_boss_silhouettes()
	_test_airframe_cues()
	_test_combat_fx()
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
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		var source := project.get_as_text()
		_expect(source.contains('CombatArtDirector="*res://scripts/combat_art_director.gd"'), "combat art presentation should remain autoloaded")
		_expect(source.contains('AirframeCueDirector="*res://scripts/airframe_cue_director.gd"'), "airframe progression cues should remain autoloaded")
		_expect(source.contains('AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"'), "altitude transitions should retain dedicated presentation")
		_expect(source.contains('CombatFxDirector="*res://scripts/combat_fx_director.gd"'), "combat impact feedback should remain autoloaded")
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
	_expect(source.contains("func _draw_autonomous"), "autonomous machines should have their own visual language")
	_expect(source.contains("AI_CORE"), "autonomous enemies should expose readable machine-core accents")
	_expect(source.contains("func _draw_boss"), "boss-scale enemies should have dedicated presentation")
	_expect(source.contains("layer = 12"), "combat art should remain below tactical ordnance/HUD layers")
	for forbidden in ["Label.new()", "PanelContainer.new()", "ProgressBar.new()"]:
		_expect(not source.contains(forbidden), "combat art must remain hard-edged canvas drawing: %s" % forbidden)

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
