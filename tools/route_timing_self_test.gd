extends SceneTree
const Routes=preload("res://scripts/route_progress_rules.gd")
const Objectives=preload("res://scripts/objective_rules.gd")
var failures:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failures.append(message)
func run()->void:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		push_error("Route timing fixture requires --capture-gameplay to isolate saves");quit(1);return
	var scene:Node=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
	await process_frame
	scene.set_process(false)
	root.get_node("StartupSequenceDirector").call("_complete")
	var campaign:Array=scene.get("mission_catalog")
	var secrets:Array=scene.get("secret_mission_catalog")
	var missions:=campaign+secrets
	check(missions.size()==36,"Fixture must cover 30 campaign and 6 secret sorties")
	for i in missions.size():
		var mission:Dictionary=missions[i]
		var id:=str(mission.id)
		scene.set("active_secret_mission_id",id if i>=campaign.size() else "")
		scene.set("mission_index",i if i<campaign.size() else 0)
		scene.call("_prepare_mission",int(scene.get("mission_index")))
		scene.call("_start_mission")
		scene.set("enemy_spawn_timer",9999.0)
		var elapsed:=float(mission.duration_seconds)+1.0
		var progress:=Routes.advance(0,elapsed,.62)
		scene.set("mission_time",elapsed);scene.set("environment_world_distance",progress)
		scene.call("_update_mission",.001)
		check(int(scene.get("phase"))==1,id+": slow approach must survive the old elapsed deadline")
		check(not bool(scene.get("boss_spawned")),id+": boss must not appear before its spatial gate")
		check(float(scene.call("mission_remaining_seconds"))>0,id+": slow approach needs positive ETA")
		var gate:=Routes.boss_gate_for_mission(mission)
		for beat in mission.get("encounter_beats",[]):
			if not bool(beat.get("secret",false)):
				check(gate>=float(beat.get("at_seconds",0))+8.0,id+": command must follow authored approach beat")
		check(Routes.route_length(mission)>=gate+24.0,id+": command needs route space before overtime")
		scene.set("environment_world_distance",gate-.01);scene.call("_try_spawn_boss")
		check(not bool(scene.get("boss_spawned")),id+": command cannot spawn early")
		scene.set("environment_world_distance",gate);scene.call("_try_spawn_boss")
		check(bool(scene.get("boss_spawned")),id+": required boss must spawn at its gate")
		scene.set("environment_world_distance",Routes.route_length(mission));scene.call("_update_mission",.01)
		check(int(scene.get("phase"))==1 and float(scene.get("route_overtime_elapsed"))>0,id+": live required boss enters overtime at route end")
		scene.set("route_overtime_elapsed",45.0);scene.call("_update_mission",.01)
		check(int(scene.get("phase"))==2 and not bool(scene.get("mission_success")),id+": overtime still expires in real seconds")
	check(is_equal_approx(Routes.remaining_travel_seconds(50,150,.5),200),"ETA must use actual speed")
	check(is_equal_approx(Routes.remaining_travel_seconds(50,150,2),50),"Faster travel must reduce ETA")
	var route_objective := [{"id":"route","type":"survive","seconds":150,"required":true}]
	var route_progress := Objectives.make_progress(route_objective)
	Objectives.update_survival(route_objective,route_progress,150.0)
	check(Objectives.required_complete(route_objective,route_progress),"Reaching the authored route distance must satisfy its survival contract regardless of elapsed wall time")
	check(Objectives.progress_text(route_objective[0],{"route":75.0})=="50% ROUTE","Route survival HUD must describe spatial progress instead of false wall-clock seconds")
	# A fast aircraft that has already destroyed the command target must be able
	# to finish at the route boundary even when little wall-clock time elapsed.
	scene.set("active_secret_mission_id","");scene.set("mission_index",1)
	scene.call("_prepare_mission",1);scene.call("_start_mission")
	scene.set("mission_time",20.0);scene.set("environment_world_distance",Routes.route_length(campaign[1])-.01)
	var fast_progress:Dictionary=scene.get("objective_progress")
	Objectives.register_destroy(scene.get("current_objectives"),fast_progress,str(campaign[1].boss_id))
	scene.set("objective_progress",fast_progress);scene.call("_update_mission",.02)
	check(int(scene.get("phase"))==2 and bool(scene.get("mission_success")),"Fast route traversal plus the required command kill must complete instead of reporting OBJECTIVES INCOMPLETE")
	if failures.is_empty():print("HYPERSONIC route timing self-test passed: 36 slow approaches, 36 boss gates, 36 overtime boundaries.")
	else:
		for failure in failures:push_error(failure)
	scene.queue_free();await process_frame
	quit(0 if failures.is_empty() else 1)
