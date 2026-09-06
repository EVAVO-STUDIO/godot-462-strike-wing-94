extends SceneTree

class ReviewSurface extends Control:
	var fx: Node
	var caption: String
	var elapsed := 0.0
	var cases: Array
	func _draw() -> void:
		draw_rect(Rect2(0,0,640,180), Color("20292c"))
		draw_string(ThemeDB.fallback_font, Vector2(8,17), caption + "  %.3fs" % elapsed,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
		for i in cases.size():
			var c: Array = cases[i]
			var p := Vector2(108+i*212,94)
			draw_string(ThemeDB.fallback_font,p+Vector2(-96,74),str(c[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE)
			if elapsed < float(c[4]):
				fx.call("_draw_explosion", self, p, elapsed/float(c[4]), float(c[5]), 3, bool(c[3]), str(c[1]), str(c[2]), str(c[0]))

func _initialize() -> void: call_deferred("review")
func review() -> void:
	var groups := [
		[["gunship_alpha","air","mercenary",true,2.3,28], ["armoured_train","ground","mercenary",true,2.3,28], ["missile_cruiser","sea","mercenary",true,2.3,28]],
		[["swarm_controller","air","autonomous",true,2.3,28], ["ai_forge_core","ground","autonomous",true,2.3,28], ["orbital_command_node","air","autonomous",true,3.0,28]],
		[["phase_control_array","air","autonomous",true,3.0,28], ["station_warden","air","autonomous",true,3.0,28], ["machine_ark","air","autonomous",true,3.0,28]],
		[["light_tank","ground","mercenary",false,.96,19], ["river_patrol","sea","mercenary",false,1.35,15], ["scout_falcon","air","mercenary",false,.92,19]],
		[["security_patrol_mech","ground","mercenary",false,1.1,19], ["fortified_turret","ground","mercenary",false,.72,15], ["autonomous_armor","ground","autonomous",false,.96,19]],
	]
	var layer := CanvasLayer.new(); layer.layer=100; root.add_child(layer)
	var panels: Array=[]
	for row in 2:
		var panel := ReviewSurface.new()
		panel.fx=load("res://work/destruction_continuity_v2/%s.gd" % ("baseline" if row==0 else "candidate")).new()
		panel.caption="CURRENT" if row==0 else "RETAINED HULL"
		panel.position=Vector2(0,row*180); panel.size=Vector2(640,180); panel.clip_contents=true
		layer.add_child(panel); panels.append(panel)
	for group in groups.size():
		for panel in panels: panel.cases=groups[group]
		var output := "res://work/destruction_continuity_v2/clipped_group_%d/" % group
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		for frame in 73:
			for panel in panels:
				panel.elapsed=float(frame)/24.0
				panel.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var im := root.get_texture().get_image()
			if im.get_size()!=Vector2i(640,360): im.resize(640,360,Image.INTERPOLATE_NEAREST)
			im.save_png(output+"frame_%03d.png" % frame)
		print("DESTRUCTION_GROUP_COMPLETE ",group," 73 addressed frames")
	for panel in panels: panel.fx.free()
	print("DESTRUCTION_CONTINUITY_V2_COMPLETE 9 bosses + 6 representatives; fixture, not natural kills")
	quit()
