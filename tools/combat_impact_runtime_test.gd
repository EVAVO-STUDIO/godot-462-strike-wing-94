extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		push_error("Impact runtime test requires isolated capture save mode"); quit(1); return
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene); current_scene=scene
	await process_frame
	scene.set_process(false)
	root.get_node("StartupSequenceDirector").call("_complete")
	scene.call("_prepare_mission",0); scene.call("_start_mission")
	var p: Vector2 = scene.get("player_position")
	var missile: Dictionary = scene.call("_make_enemy_shot",p,Vector2.DOWN*132,13,true,"missile")
	check(missile.impact_class == "direct_warhead" and missile.guidance_class == "heat_seeking", "Enemy missile factory must publish impact and guidance classes")
	scene.set("enemy_bullets",[missile]); scene.call("_update_enemy_bullets",0.0)
	check(int(scene.get("hull")) == 0 and int(scene.get("shield")) == 0, "Live direct missile collision must destroy craft")
	check(float(scene.get("player_loss_timer")) > 0 and str(scene.get("status_text")).contains("AIRFRAME LOST"), "Catastrophic collision must enter loss presentation")
	scene.call("_start_mission"); p=scene.get("player_position")
	for i in 3:
		var cannon: Dictionary = scene.call("_make_enemy_shot",p,Vector2.DOWN*168,12,false,"cannon")
		scene.set("enemy_bullets",[cannon]); scene.call("_update_enemy_bullets",0.0)
	check(int(scene.get("hull")) == 0, "Three live heavy-cannon collisions must destroy basic craft")
	check(int(scene.get("damage_sources").get("heavy_cannon",0)) > 0, "Runtime telemetry must classify cannon damage")
	scene.queue_free(); await process_frame
	if failures.is_empty(): print("HYPERSONIC impact runtime test passed: live missile and three-hit heavy cannon loss paths.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
