extends SceneTree
class Review extends Control:
	var cels: Array[Texture2D] = []
	var bursts: Array[Texture2D] = []
	var bodies: Array[Texture2D] = []
	var exposure := 0
	var mounts := [
		[Vector2(1,27),Vector2(9,25)], [Vector2(-7,30),Vector2(3,30)], [Vector2(-6,30),Vector2(5,30)], [Vector2(-3,30),Vector2(5,30)], [Vector2(-10,25),Vector2(-2,28)],
		[Vector2(1,26),Vector2(10,22)], [Vector2(-4,30),Vector2(5,29)], [Vector2(-6,30),Vector2(5,30)], [Vector2(-7,29),Vector2(3,30)], [Vector2(-12,24),Vector2(-3,27)]
	]
	func _draw() -> void:
		draw_rect(Rect2(0,0,640,360),Color("283b43"))
		for i in 10:
			var p := Vector2(64 + (i % 5)*128, 80 + (i/5)*170)
			draw_texture(bodies[i], p-Vector2(32,38))
			for mount in mounts[i]:
				var angle := -0.30 if i%5 == 0 else (0.30 if i%5 == 4 else 0.0)
				draw_set_transform(p+mount,angle)
				draw_texture(cels[exposure%4],-Vector2(8,4))
				draw_set_transform(Vector2.ZERO)
			if exposure < 18 and i%5 == 2: draw_texture(bursts[mini(5,exposure/3)],p+Vector2(-48,22))
			draw_line(p+Vector2(-24,34),p+Vector2(24,34),Color(0.5,0.6,0.6,0.2))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var review := Review.new();root.add_child(review)
	for i in 4:
		review.cels.append(ImageTexture.create_from_image(Image.load_from_file("res://assets/source/effects/hypersonic_propulsion_v2/cels/blue_plume_%d.png"%i)))
	for i in 6:
		review.bursts.append(ImageTexture.create_from_image(Image.load_from_file("res://assets/source/effects/hypersonic_propulsion_v2/cels/engine_burst_%d.png"%i)))
	for form in ["fighter","bomber"]:
		for bank in ["hard_left","left","neutral","right","hard_right"]:
			review.bodies.append(load("res://assets/runtime/craft/vx94/gameplay/bank/%s_%s.png"%[form,bank]))
	var out := "res://work/hypersonic_propulsion_v2/native_v2/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in 48:
		review.exposure=i;review.queue_redraw()
		await create_timer(1.0/24.0).timeout;await RenderingServer.frame_post_draw
		var im:=root.get_texture().get_image()
		if im.get_size()!=Vector2i(640,360): im.resize(640,360,Image.INTERPOLATE_NEAREST)
		im.save_png(out+"frame_%03d.png"%i)
	print("PROPULSION_ART_REVIEW 48 frames across 10 bank/form registrations")
	quit()
