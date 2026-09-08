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
	scene.call("_start_mission"); p=scene.get("player_position")
	var aircraft := {"id":"scout_falcon","category":"air","position":p,"hp":4,"max_hp":4,"value":100,"boss":false}
	scene.set("enemies",[aircraft]); scene.call("_resolve_combat")
	check(int(scene.get("hull"))==0 and scene.get("enemies").is_empty(), "Live airframe contact must destroy both aircraft")
	check(str(scene.get("status_text")).contains("AIRFRAME COLLISION") and int(scene.get("targets_destroyed"))==1, "Live collision must enter structural-loss presentation and register hostile destruction")
	scene.call("_start_mission"); p=scene.get("player_position")
	root.get_node("CraftFormDirector").set("altitude","high")
	var low_gun: Dictionary = scene.call("_make_enemy_shot",p,Vector2.DOWN*168,12,false,"cannon","ground")
	scene.set("enemy_bullets",[low_gun]); scene.call("_update_enemy_bullets",0.0)
	check(int(scene.get("hull"))==int(scene.call("_max_hull")) and scene.get("enemy_bullets").is_empty(), "A high-lane VX-94 should clear ordinary low-altitude gun trajectories")
	var high_sam: Dictionary = scene.call("_make_enemy_shot",p,Vector2.DOWN*132,13,true,"missile","ground")
	scene.set("enemy_bullets",[high_sam]); scene.call("_update_enemy_bullets",0.0)
	check(int(scene.get("hull"))==0, "A capable surface missile should remain lethal in the high-altitude lane")
	scene.call("_start_mission"); p=scene.get("player_position")
	var tank := {"id":"light_tank","category":"ground","position":p,"hp":4,"max_hp":4,"value":100,"boss":false}
	scene.set("enemies",[tank]); scene.call("_resolve_combat")
	check(int(scene.get("hull"))==int(scene.call("_max_hull")) and scene.get("enemies").size()==1, "A coincident surface target must not collide across altitude separation")
	scene.call("_start_mission"); p=scene.get("player_position")
	root.get_node("CraftFormDirector").set("altitude","low")
	var silo := {"id":"strategic_silo","category":"ground","position":p,"hp":20,"max_hp":20,"value":100,"boss":false}
	scene.set("enemies",[silo]); scene.call("_resolve_combat")
	check(int(scene.get("hull"))==0 and scene.get("enemies").is_empty(), "Terrain-skimming contact with a tall silo must destroy both aircraft and installation")
	check(str(scene.get("status_text")).contains("LOW ALTITUDE IMPACT") and int(scene.get("damage_sources").get("terrain_collision",0))>0, "Tall-site collision must enter explicit structural-loss presentation and telemetry")
	scene.call("_start_mission"); p=scene.get("player_position")
	var air_target := {"id":"scout_falcon","category":"air","position":p+Vector2(0,-80),"hp":4,"max_hp":4,"value":100,"boss":false}
	var ground_target := {"id":"light_tank","category":"ground","position":p+Vector2(0,-80),"hp":4,"max_hp":4,"value":100,"boss":false}
	var strafe_round := {"position":p+Vector2(0,-80),"velocity":Vector2.UP*390.0,"damage":5,"weapon_id":"heavy_autocannon","engagement_classes":["ground","sea","boss"],"pierce_remaining":0}
	scene.set("enemies",[air_target,ground_target]); scene.set("bullets",[strafe_round]); scene.call("_resolve_combat")
	var strafe_survivors: Array = scene.get("enemies")
	check(strafe_survivors.size()==1 and str(strafe_survivors[0].get("id",""))=="scout_falcon", "Depressed heavy-autocannon fire must cross the surface plane without hitting a coincident aircraft")
	scene.queue_free(); await process_frame
	if failures.is_empty(): print("HYPERSONIC impact runtime test passed: lethal missiles, cannon attrition, catastrophic airframe contact and surface separation.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
