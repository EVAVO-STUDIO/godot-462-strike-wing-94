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
	_expect(pause != null, "pause director autoload should exist at runtime")
	if pause != null:
		_expect(bool(pause.call("pause_game")), "active gameplay should accept a pause request")
		_expect(paused and bool(pause.call("pause_active")), "pause request should stop the SceneTree and expose active state")
		var held_time := float(scene.get("mission_time"))
		await process_frame
		await process_frame
		_expect(is_equal_approx(float(scene.get("mission_time")), held_time), "mission time should remain frozen while tactical hold is active")
		pause.call("resume_game")
		_expect(not paused and not bool(pause.call("pause_active")), "resume should restore the SceneTree and close the overlay")
		scene.set("mission_time", 27.0)
		_expect(bool(pause.call("pause_game")), "sortie should be pausable again after resume")
		pause.call("restart_sortie")
		_expect(not paused and not bool(pause.call("pause_active")), "restart should leave simulation running")
		_expect(int(scene.get("phase")) == 1 and is_zero_approx(float(scene.get("mission_time"))), "restart should reset the current sortie to its initial gameplay state")
	if failures.is_empty():
		print("HYPERSONIC tactical pause self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	paused = false
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
