extends SceneTree
const BASE:="C:/Gitrepos/godot-462-strike-wing-94/work/vx94_specialist_housings_v2/"
class Surface extends Node2D:
	var textures:Dictionary
	var exposure:=0
	func _draw()->void:
		draw_rect(Rect2(0,0,640,360),Color("15212b"))
		var weapon:String=["needle_rail","storm_cannon","plasma_lance"][exposure/16]
		var state:=exposure%16/4
		var names:=["stowed","deployed","charged","discharge"]
		draw_string(ThemeDB.fallback_font,Vector2(14,20),"VX-94 / "+weapon+" / "+names[state],HORIZONTAL_ALIGNMENT_LEFT,-1,13)
		for row in 2:
			for col in 5:
				var form:String=["fighter","bomber"][row]
				var bank:String=["hard_left","left","neutral","right","hard_right"][col]
				var origin:=Vector2(32+col*128,48+row*160)
				draw_texture(textures["%s_%s_%s_%d"%[weapon,form,bank,state]],origin)
				draw_string(ThemeDB.fallback_font,origin+Vector2(-12,96),form+" "+bank,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("a6b4bd"))
		draw_string(ThemeDB.fallback_font,Vector2(14,350),"Native 1x art states / firing origins and gameplay unchanged",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
func _initialize()->void:call_deferred("review")
func review()->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE+"manifest.json"))
	var surface:=Surface.new();surface.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for frame in data.frames:surface.textures[frame.id]=ImageTexture.create_from_image(Image.load_from_file(BASE+"composites/"+frame.id+".png"))
	root.add_child(surface);DirAccess.make_dir_recursive_absolute(BASE+"native_frames")
	for i in 48:
		surface.exposure=i;surface.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(BASE+"native_frames/frame_%03d.png"%i)
	print("SPECIALIST_HARDWARE: 120 named states in 48 native fixture frames")
	quit()
