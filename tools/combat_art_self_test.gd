extends SceneTree

const CombatArtDirector = preload("res://scripts/combat_art_director.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_wiring()
	_test_visual_language()
	_test_transform_presentation()
	_test_altitude_presentation()
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
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('CombatArtDirector="*res://scripts/combat_art_director.gd"'), "combat art presentation should remain autoloaded")

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
	_expect(source.contains("TRANSFORM_VISUAL_SECONDS := 0.34"), "variable geometry sweep should remain short and mechanical")
	_expect(source.contains("_visual_sweep = move_toward"), "visual wing geometry should interpolate rather than snap")
	_expect(source.contains("func _draw_transforming"), "intermediate wing geometry should have dedicated rendering")
	_expect(source.contains("lerpf(17.0, 29.0, t)"), "wing span should visibly expand between fighter and bomber")
	_expect(source.contains("Mechanical hinge marks"), "transforming silhouette should retain visible variable-geometry hinge language")

func _test_altitude_presentation() -> void:
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable for altitude checks")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("AltitudeRules.ground_scale"), "surface target presentation should use the canonical altitude scale")
	_expect(source.contains('category in ["ground", "sea"]'), "ground/sea targets should be identified for altitude treatment")
	_expect(source.contains("scale < 0.25"), "ordinary surface silhouettes should disappear when the player is effectively too high to engage them visually")
	_expect(source.contains("func _draw_ground(surface: CanvasItem, p: Vector2, scale: float)"), "ground target art should accept altitude scale")
	_expect(source.contains("func _draw_sea(surface: CanvasItem, p: Vector2, scale: float)"), "sea target art should accept altitude scale")
	_expect(source.contains("roundf(v.x * scale)"), "scaled target geometry should stay integer-aligned")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
