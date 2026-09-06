extends SceneTree
const BASE:="C:/Gitrepos/godot-462-strike-wing-94/work/vx94_pitch_relief_v3/"
class Surface extends Node2D:
	var textures:Dictionary
	var exposure:=0
	func _draw()->void:
		draw_rect(Rect2(0,0,640,360),Color("15212b"))
		var poses:=["neutral","climb_06","climb_12","climb_18","climb_12","climb_06","neutral","dive_06","dive_12","dive_18","dive_12","dive_06","neutral"]
		var pose:String=poses[exposure/4]
		draw_string(ThemeDB.fallback_font,Vector2(20,24),"VX-94 / RETAINED-ART 3D PITCH / "+pose,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
		for row in 2:
			var form:String=["fighter","bomber"][row]
			var origin:=Vector2(130,65+row*140)
			draw_texture(textures[form+"_original"],origin)
			draw_texture(textures[form+"_"+pose],origin+Vector2(180,0))
			draw_string(ThemeDB.fallback_font,origin+Vector2(-20,94),form+" neutral",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
			draw_string(ThemeDB.fallback_font,origin+Vector2(160,94),form+" "+pose,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
		draw_string(ThemeDB.fallback_font,Vector2(20,350),"Native 1x / fixed pivot / art fixture, no flight-code change",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
func _initialize()->void:call_deferred("review")
func review()->void:
	var surface:=Surface.new();surface.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for form in ["fighter","bomber"]:
		for pose in ["dive_18","dive_12","dive_06","neutral","climb_06","climb_12","climb_18"]:
			surface.textures[form+"_"+pose]=ImageTexture.create_from_image(Image.load_from_file(BASE+"native/"+form+"_"+pose+".png"))
		surface.textures[form+"_original"]=ImageTexture.create_from_image(Image.load_from_file("C:/Gitrepos/godot-462-strike-wing-94/assets/runtime/craft/vx94/gameplay/bank/"+form+"_neutral.png"))
	root.add_child(surface);DirAccess.make_dir_recursive_absolute(BASE+"native_review")
	for i in 52:
		surface.exposure=i;surface.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(BASE+"native_review/frame_%03d.png"%i)
	print("VX94_PITCH_NATIVE: 52 fixture frames; two forms; seven pitch views")
	quit()
