extends SceneTree

const REPO := "C:/Gitrepos/godot-462-strike-wing-94/"
const BASE := REPO + "work/vx94_banked_housings/"
class ReviewSurface extends Node2D:
	var textures: Dictionary = {}
	var flashes: Dictionary = {}
	var poses: Dictionary
	var exposure := 0
	func _draw() -> void:
		draw_rect(Rect2(0,0,640,360),Color("15212b"))
		var forms := ["fighter","bomber"]
		var banks := ["hard_left","left","neutral","right","hard_right"]
		var stage := mini(3, exposure / 4)
		for row in 2:
			for col in 5:
				var form: String = forms[row]
				var bank: String = banks[col]
				var origin := Vector2(32 + col * 128, 48 + row * 160)
				draw_texture(textures["%s_%s_%d" % [form,bank,stage]],origin)
				if exposure >= 16 and exposure % 8 < 4:
					var pose: Dictionary = poses[form][bank]
					for muzzle in pose.muzzles:
						var p := origin + Vector2(muzzle[0],muzzle[1])
						draw_set_transform(p,deg_to_rad(float(pose.angle)))
						draw_texture(flashes[form][exposure % 4],Vector2(-12,-16))
						draw_set_transform(Vector2.ZERO)
				var font := ThemeDB.fallback_font
				draw_string(font,origin+Vector2(-12,96),form+" "+bank,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("a6b4bd"))
		draw_string(ThemeDB.fallback_font,Vector2(14,20),"VX-94 / PRIMARY HOUSING ART FIXTURE / 1x",HORIZONTAL_ALIGNMENT_LEFT,-1,13)
		draw_string(ThemeDB.fallback_font,Vector2(14,350),"Candidate anchors and flashes; no gameplay changes",HORIZONTAL_ALIGNMENT_LEFT,-1,12)

func _initialize() -> void: call_deferred("review")
func review() -> void:
	var surface := ReviewSurface.new()
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	surface.poses = JSON.parse_string(FileAccess.get_file_as_string(BASE+"poses.json")).poses
	for form in ["fighter","bomber"]:
		for bank in ["hard_left","left","neutral","right","hard_right"]:
			for stage in 4:
				var id := "%s_%s_%d" % [form,bank,stage]
				surface.textures[id] = ImageTexture.create_from_image(Image.load_from_file(BASE+"composites/"+id+".png"))
		var family := "muzzle" if form == "fighter" else "rotary_muzzle"
		surface.flashes[form] = []
		for i in 4:
			surface.flashes[form].append(ImageTexture.create_from_image(Image.load_from_file(REPO+"assets/runtime/effects/impacts/%s/%d.png" % [family,i])))
	root.add_child(surface)
	DirAccess.make_dir_recursive_absolute(BASE+"native_frames")
	for i in 48:
		surface.exposure = i
		surface.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(BASE+"native_frames/frame_%03d.png" % i)
	print("VX94_BANKED_HOUSING_ART: 48 native frames; 40 deployment states; no production integration")
	quit()
