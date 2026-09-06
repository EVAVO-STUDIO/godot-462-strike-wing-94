extends SceneTree
const Art = preload("res://scripts/persistent_effect_art_library.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var cue: Node = load("res://scripts/afterburner_cue_director.gd").new()
	check(cue.get("ENGINE_BURST_FRAME_ENDS") == [0.035,0.080,0.135,0.200,0.275,0.360], "Burst timing must retain reviewed 35/45/55/65/75/85 ms exposures")
	var previous := -1
	for sample in [0.0,0.034,0.035,0.079,0.080,0.134,0.135,0.199,0.200,0.274,0.275,0.359]:
		var frame := int(cue.call("_engine_burst_frame", sample))
		check(frame >= previous and frame >= 0 and frame < 6, "Burst frames must advance once without reversal")
		previous = frame
	var extents: Array[int] = []
	var alpha_totals: Array[int] = []
	for frame in Art.FRAMES["hypersonic_engine_burst"]:
		var image: Image = frame.get_image()
		var min_x := image.get_width()
		var max_x := -1
		var total := 0
		for y in image.get_height():
			for x in image.get_width():
				var alpha := image.get_pixel(x,y).a8
				if alpha > 0:
					min_x = mini(min_x,x); max_x = maxi(max_x,x); total += alpha
		extents.append(max_x-min_x+1); alpha_totals.append(total)
	for i in range(1,extents.size()): check(extents[i] >= extents[i-1], "Pressure front must expand monotonically")
	check(alpha_totals[-1] < alpha_totals[2], "Pressure front must dissipate by final exposure")
	var mounts: Dictionary = cue.get("ENGINE_MOUNTS")
	check(mounts.fighter.size() == 5 and mounts.bomber.size() == 5, "Both forms need five registered bank poses")
	for form in mounts:
		for pose in mounts[form]: check(pose.size() == 2, "%s bank pose must retain both engine outlets" % form)
	check(Art.FRAMES["hypersonic_blue_plume"].size() == 4, "Blue exhaust must retain its four-exposure loop")
	check(Art.FRAMES["hypersonic_engine_ring"].size() == 6, "Engine-origin pressure ring must retain its six authored exposures")
	for frame in Art.FRAMES["hypersonic_engine_ring"]:
		check(frame is Texture2D and frame.get_size() == Vector2(128,128) and frame.get_image().detect_alpha() != Image.ALPHA_NONE, "Engine-origin pressure ring must retain registered transparent geometry")
	cue.free()
	if failures.is_empty(): print("HYPERSONIC propulsion self-test passed: paired engines, timed expanding burst and blue plume loop.")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
