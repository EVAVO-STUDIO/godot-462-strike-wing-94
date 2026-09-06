extends SceneTree
const BASE:="C:/Gitrepos/godot-462-strike-wing-94/work/vx94_dorsal_modules_v1/"
class Surface extends Node2D:
	var texture:Texture2D
	var label:String
	func _draw()->void:
		draw_rect(Rect2(0,0,640,360),Color("15212b"))
		draw_string(ThemeDB.fallback_font,Vector2(20,24),"VX-94 / DORSAL MODULES / ART FIXTURE",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
		draw_texture(texture,Vector2(98,100))
		draw_texture_rect(texture,Rect2(290,60,192,216),false)
		draw_string(ThemeDB.fallback_font,Vector2(30,315),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
		draw_string(ThemeDB.fallback_font,Vector2(30,345),"Native 1x and 3x / dorsal hardware / no gameplay integration",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
func _initialize()->void:call_deferred("review")
func review()->void:
	var data=JSON.parse_string(FileAccess.get_file_as_string(BASE+"manifest.json"))
	var s:=Surface.new();s.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(s)
	DirAccess.make_dir_recursive_absolute(BASE+"native")
	var index:=0
	for entry in data.entries:
		s.texture=ImageTexture.create_from_image(Image.load_from_file(BASE+"composites/"+entry.id+".png"));s.label=entry.id
		s.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(BASE+"native/frame_%03d.png"%index);index+=1
	print("VX94_STORES_NATIVE: 60 dorsal module states captured")
	quit()
