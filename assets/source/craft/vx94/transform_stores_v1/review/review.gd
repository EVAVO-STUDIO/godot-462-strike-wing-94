extends SceneTree
const BASE:="C:/Gitrepos/godot-462-strike-wing-94/work/vx94_transform_stores_v1/"
class Surface extends Node2D:
	var textures:Dictionary
	var exposure:=0
	func _draw()->void:
		draw_rect(Rect2(0,0,640,360),Color("15212b"))
		draw_string(ThemeDB.fallback_font,Vector2(20,24),"VX-94 / SWIVEL PYLONS / EXPOSURE %02d"%exposure,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
		for row in 2:
			var kind:String=["hunter_rack","twin_rocket_pods"][row];var texture:Texture2D=textures[kind+"_%02d"%exposure]
			draw_texture(texture,Vector2(110,55+row*145))
			draw_texture_rect(texture,Rect2(320,40+row*145,128,144),false)
			draw_string(ThemeDB.fallback_font,Vector2(35,140+row*145),kind,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
		draw_string(ThemeDB.fallback_font,Vector2(20,350),"Art fixture / forward and reverse / no flight-code change",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
func _initialize()->void:call_deferred("review")
func review()->void:
	var s:=Surface.new();s.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(s)
	for kind in ["hunter_rack","twin_rocket_pods"]:
		for i in 10:s.textures[kind+"_%02d"%i]=ImageTexture.create_from_image(Image.load_from_file(BASE+"composites/"+kind+"_%02d.png"%i))
	var sequence:Array[int]=[]
	for i in 10:sequence.append(i)
	for i in 5:sequence.append(9)
	for i in 10:sequence.append(9-i)
	for i in 5:sequence.append(0)
	DirAccess.make_dir_recursive_absolute(BASE+"native")
	for i in 60:
		s.exposure=sequence[i/2];s.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(BASE+"native/frame_%03d.png"%i)
	print("VX94_TRANSFORM_STORES: 60 forward/reverse fixture captures, two loadouts")
	quit()
