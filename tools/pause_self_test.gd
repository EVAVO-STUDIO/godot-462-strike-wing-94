extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var startup := root.get_node_or_null("StartupSequenceDirector")
	if startup != null:
		startup.call("_complete")
	scene.call("_start_mission")
	scene.set("mission_time", 18.5)
	var pause := root.get_node_or_null("PauseDirector")
	var controller_context := root.get_node_or_null("ControllerMenuContextDirector")
	_expect(pause != null, "pause director autoload should exist at runtime")
	_expect(controller_context != null, "controller menu context autoload should exist at runtime")
	if pause != null:
		_expect(bool(pause.call("pause_game")), "active gameplay should accept a pause request")
		_expect(paused and bool(pause.call("pause_active")), "pause request should stop the SceneTree and expose active state")
		_expect(str(pause.call("pause_context")) == "menu", "pause should expose its current command context")
		var held_time := float(scene.get("mission_time"))
		await process_frame
		await process_frame
		_expect(is_equal_approx(float(scene.get("mission_time")), held_time), "mission time should remain frozen while tactical hold is active")

		# Paused Options previously reused B/fire_secondary for next category before
		# checking cancel, so pad B could not reliably return to Commands. The
		# always-processing context director now moves that pad event to X only for
		# the paused-options context and restores the universal map afterward.
		pause.call("_activate_menu_item", 1)
		_expect(str(pause.call("pause_context")) == "options", "pause options command should expose options context")
		if controller_context != null:
			controller_context.call("_set_context", "pause_options")
			_expect(_has_button(&"fire_secondary", JOY_BUTTON_X), "paused Options should map next-category to pad X")
			_expect(not _has_button(&"fire_secondary", JOY_BUTTON_B), "paused Options must keep pad B free for BACK")
			controller_context.call("_set_context", "")
			_expect(_has_button(&"fire_secondary", JOY_BUTTON_B), "leaving paused Options should restore pad B secondary fire")
			_expect(not _has_button(&"fire_secondary", JOY_BUTTON_X), "leaving paused Options should remove contextual pad X secondary mapping")
		pause.set("_mode", "menu")

		pause.call("resume_game")
		_expect(not paused and not bool(pause.call("pause_active")), "resume should restore the SceneTree and close the overlay")
		scene.set("mission_time", 27.0)
		_expect(bool(pause.call("pause_game")), "sortie should be pausable again after resume")
		pause.call("restart_sortie")
		_expect(not paused and not bool(pause.call("pause_active")), "restart should leave simulation running")
		_expect(int(scene.get("phase")) == 1 and is_zero_approx(float(scene.get("mission_time"))), "restart should reset the current sortie to its initial gameplay state")
		scene.set("mission_time", 33.0)
		_expect(bool(pause.call("pause_game")), "restarted sortie should remain pausable")
		pause.call("_activate_menu_item", 2)
		_expect(str(pause.get("_mode")) == "confirm_restart" and is_equal_approx(float(scene.get("mission_time")), 33.0), "restart command should require confirmation before discarding progress")
		pause.set("_mode", "menu")
		pause.call("_activate_menu_item", 3)
		_expect(str(pause.get("_mode")) == "confirm_return", "return command should require explicit sortie-loss confirmation")
		pause.call("return_to_menu")
		_expect(not paused and int(scene.get("phase")) == 0 and str(scene.get("front_end_screen")) == "main_menu", "confirmed return should leave combat at the main menu without mutating campaign selection")

	var pause_sizes := {"warning_frame":Vector2(400,74),"icon_resume":Vector2(16,16),"icon_options":Vector2(16,16),"icon_restart":Vector2(16,16),"icon_return":Vector2(16,16),"icon_warning":Vector2(16,16)}
	for asset_name in pause_sizes:
		var texture := load("res://assets/runtime/ui/menu/pause_command/%s.png" % asset_name)
		_expect(texture is Texture2D and texture.get_size() == pause_sizes[asset_name], "pause command sprite should retain registered geometry: %s" % asset_name)
	_expect(FileAccess.file_exists("res://assets/source/ui/menu/pause_command_manifest.json"), "pause command source/runtime manifest should exist")
	var pause_source := FileAccess.get_file_as_string("res://scripts/pause_director.gd")
	_expect(pause_source.contains('argument.begins_with("--capture-pause=")') and pause_source.contains('"confirm_restart", "confirm_return"'), "pause menu and destructive confirmations should expose deterministic visual QA fixtures")
	_expect(pause_source.contains("ENTER/A SELECT") and pause_source.contains("ESC/B RESUME") and pause_source.contains("Q/Y PREV") and pause_source.contains("X NEXT"), "pause UI should expose keyboard and controller navigation")
	_expect(pause_source.contains("ENTER/A CONFIRM") and pause_source.contains("ESC/B CANCEL"), "destructive pause confirmations should expose pad-safe controls")
	var context_source := FileAccess.get_file_as_string("res://scripts/controller_menu_context_director.gd")
	_expect(context_source.contains("PROCESS_MODE_ALWAYS") and context_source.contains('"pause_options"') and context_source.contains("pause_context"), "controller menu context should remain active while the SceneTree is paused")

	if failures.is_empty():
		print("HYPERSONIC tactical pause self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	paused = false
	quit(1)

func _has_button(action: StringName, button: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and int((event as InputEventJoypadButton).button_index) == button:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
