extends SceneTree

# Bake the reviewed VX-94 mechanical poses from immutable current-hero pixels.
# Five disjoint masks were extracted by the source-bound Art Studio sandbox.
const SOURCE := "res://assets/source/craft/vx94/transform_v2/components/"
const OUTPUT := "res://assets/runtime/craft/vx94/transform/"
const SIZE := Vector2i(64, 72)
const WING_ANGLES := [-22.0, -20.0, -17.0, -13.0, -9.0, -5.0, -2.0, 0.0, 2.5, 0.0]
const TAIL_ANGLES := [-18.0, -16.5, -14.0, -11.0, -7.5, -4.0, -1.5, 0.0, 1.5, 0.0]
var parts: Dictionary = {}

func _init() -> void:
	for part in ["fuselage", "wing_left", "wing_right", "tail_left", "tail_right"]:
		parts[part] = Image.load_from_file(SOURCE + part + ".png")
		if parts[part] == null or parts[part].get_size() != SIZE:
			push_error("Missing registered source component: " + part)
			quit(1)
			return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for exposure in range(10):
		var frame := compose(WING_ANGLES[exposure], TAIL_ANGLES[exposure])
		if frame.save_png(OUTPUT + "bomber_%02d.png" % exposure) != OK:
			quit(1)
			return
		var hyper_ratio := smoothstep(0.0, 1.0, float(exposure) / 9.0)
		frame = compose(lerpf(-22.0, -36.0, hyper_ratio), lerpf(-18.0, -26.0, hyper_ratio))
		if frame.save_png(OUTPUT + "hypersonic_%02d.png" % exposure) != OK:
			quit(1)
			return
	print("Built registered VX-94 art: ten bomber and ten hypersonic exposures, fixed current-hero fuselage.")
	quit(0)

func compose(wing_angle: float, tail_angle: float) -> Image:
	var frame := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	frame.fill(Color.TRANSPARENT)
	# Tail carriages retract along the nacelle rails as the surfaces tuck in.
	# This keeps the existing exhaust ends fixed and retains the canvas gutter.
	var tail_slide := Vector2(0.0, -absf(tail_angle) * 0.15)
	place(frame, parts["tail_left"], Vector2(24.0, 48.0), tail_angle, tail_slide)
	place(frame, parts["tail_right"], Vector2(39.0, 48.0), -tail_angle, tail_slide)
	place(frame, parts["wing_left"], Vector2(25.0, 35.0), wing_angle)
	place(frame, parts["wing_right"], Vector2(38.0, 35.0), -wing_angle)
	place(frame, parts["fuselage"], Vector2.ZERO, 0.0)
	return frame

func place(target: Image, source: Image, pivot: Vector2, degrees: float, slide := Vector2.ZERO) -> void:
	var angle := deg_to_rad(degrees)
	for y in SIZE.y:
		for x in SIZE.x:
			var point := (Vector2(x, y) - slide - pivot).rotated(-angle) + pivot
			var sx := roundi(point.x)
			var sy := roundi(point.y)
			if sx < 0 or sx >= SIZE.x or sy < 0 or sy >= SIZE.y:
				continue
			var pixel := source.get_pixel(sx, sy)
			if pixel.a <= 0.0:
				continue
			var under := target.get_pixel(x, y)
			target.set_pixel(x, y, under.blend(pixel))
