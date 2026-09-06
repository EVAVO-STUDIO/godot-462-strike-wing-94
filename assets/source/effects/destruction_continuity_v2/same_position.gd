extends SceneTree
const Review = preload("res://work/destruction_continuity_v2/review.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var groups := [
		[["gunship_alpha","air","mercenary",true,2.3,28], ["armoured_train","ground","mercenary",true,2.3,28], ["missile_cruiser","sea","mercenary",true,2.3,28]],
		[["swarm_controller","air","autonomous",true,2.3,28], ["ai_forge_core","ground","autonomous",true,2.3,28], ["orbital_command_node","air","autonomous",true,3.0,28]],
		[["phase_control_array","air","autonomous",true,3.0,28], ["station_warden","air","autonomous",true,3.0,28], ["machine_ark","air","autonomous",true,3.0,28]],
		[["light_tank","ground","mercenary",false,.96,19], ["river_patrol","sea","mercenary",false,1.35,15], ["scout_falcon","air","mercenary",false,.92,19]],
		[["security_patrol_mech","ground","mercenary",false,1.1,19], ["fortified_turret","ground","mercenary",false,.72,15], ["autonomous_armor","ground","autonomous",false,.96,19]],
	]
	var fx := [load("res://work/destruction_continuity_v2/baseline.gd").new(),load("res://work/destruction_continuity_v2/candidate.gd").new()]
	var layer:=CanvasLayer.new(); layer.layer=100;root.add_child(layer)
	var panel:=Review.ReviewSurface.new();panel.size=Vector2(640,180);panel.clip_contents=true;panel.caption="SAME POSITION CHECK";layer.add_child(panel)
	var checks:Array=[]
	for group in groups.size():
		panel.cases=groups[group]
		var counts:=[0,0,0]
		for frame in 73:
			panel.elapsed=float(frame)/24.0
			var images:Array[Image]=[]
			for variant in 2:
				panel.fx=fx[variant];panel.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var im:=root.get_texture().get_image()
				if im.get_size()!=Vector2i(640,360):im.resize(640,360,Image.INTERPOLATE_NEAREST)
				images.append(im)
			for i in 3:
				if panel.elapsed<=float(groups[group][i][4])*.32:continue
				var region:=Rect2i(i*212,20,212,135)
				if images[0].get_region(region).get_data()!=images[1].get_region(region).get_data():
					push_error("SAME_POSITION_MISMATCH group %d frame %d case %d" % [group,frame,i]);quit(1);return
				counts[i]+=1
		checks.append({"group":group,"late_exact_frames_per_case":counts})
		print("SAME_POSITION_GROUP_PASS ",group," ",counts)
	var file:=FileAccess.open("res://work/destruction_continuity_v2/same_position_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"status":"exact_late_art_pixels_pass","checks":checks,"scope":"Sequential native renders at identical screen coordinates; central art regions exclude annotations."},"\t"));file.close()
	for node in fx:node.free()
	quit()
