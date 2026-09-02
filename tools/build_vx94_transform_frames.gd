extends SceneTree

const SIZE := Vector2i(64, 72)
const CENTER := Vector2(32, 38)
const EXPOSURES := 10
const COMPONENT_ROOT := "res://assets/runtime/craft/vx94/layered/"
const OUTPUT_ROOT := "res://assets/runtime/craft/vx94/transform/"

var components: Dictionary = {}

func _init() -> void:
	for component_name in ["fuselage", "wing_left", "wing_right", "actuator_left", "actuator_right", "bay_closed", "bay_open", "hardpoint_left", "hardpoint_right", "tailplane_left", "tailplane_right"]:
		var image := Image.load_from_file(COMPONENT_ROOT + component_name + ".png")
		if image == null or image.is_empty():
			push_error("Missing VX-94 component: %s" % component_name)
			quit(1)
			return
		components[component_name] = image
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	for index in EXPOSURES:
		var ratio := float(index) / float(EXPOSURES - 1)
		_write_frame("bomber_%02d.png" % index, _render_frame(ratio, false))
		_write_frame("hypersonic_%02d.png" % index, _render_frame(ratio, true))
	print("Built 20 registered VX-94 transformation exposures.")
	quit()

func _render_frame(ratio: float, hypersonic: bool) -> Image:
	var frame := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	frame.fill(Color.TRANSPARENT)
	var sweep := -ratio if hypersonic else ratio
	var bomber_sweep := clampf(sweep, 0.0, 1.0)
	var hypersonic_sweep := clampf(-sweep, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, bomber_sweep)
	var settle := sin(clampf((bomber_sweep - 0.72) / 0.28, 0.0, 1.0) * PI) * 0.055
	var articulated := clampf(eased + settle, 0.0, 1.06)
	var left_hinge := CENTER + Vector2(-6, -6)
	var right_hinge := CENTER + Vector2(6, -6)
	_composite(frame, "tailplane_left", CENTER + Vector2(-5, 14), Vector2(0.82, 0.50), 0.0)
	_composite(frame, "tailplane_right", CENTER + Vector2(5, 14), Vector2(0.18, 0.50), 0.0)
	var left_angle := deg_to_rad(lerpf(lerpf(-18.0, -44.0, hypersonic_sweep), 13.0, articulated))
	var right_angle := deg_to_rad(lerpf(lerpf(18.0, 44.0, hypersonic_sweep), -13.0, articulated))
	_composite(frame, "wing_left", left_hinge, Vector2(0.88, 0.18), left_angle)
	_composite(frame, "wing_right", right_hinge, Vector2(0.12, 0.18), right_angle)
	_composite(frame, "hardpoint_left", left_hinge + Vector2(-7, 9), Vector2(0.78, 0.50), left_angle * 0.55)
	_composite(frame, "hardpoint_right", right_hinge + Vector2(7, 9), Vector2(0.22, 0.50), right_angle * 0.55)
	_composite(frame, "actuator_left", left_hinge, Vector2(0.55, 0.08), left_angle * 0.42)
	_composite(frame, "actuator_right", right_hinge, Vector2(0.45, 0.08), right_angle * 0.42)
	var fuselage: Image = components["fuselage"]
	_blit_alpha(frame, fuselage, Vector2i(roundi(CENTER.x - fuselage.get_width() * 0.5), roundi(CENTER.y - 29.0)), 1.0)
	_composite(frame, "bay_open" if articulated > 0.72 else "bay_closed", CENTER + Vector2(0, 4), Vector2(0.50, 0.50), 0.0, 0.72)
	return frame

func _composite(destination: Image, component_name: String, world_pivot: Vector2, normalized_pivot: Vector2, angle: float, opacity := 1.0) -> void:
	var source: Image = components[component_name]
	var local_pivot := Vector2(source.get_width(), source.get_height()) * normalized_pivot
	var cosine := cos(angle)
	var sine := sin(angle)
	for y in SIZE.y:
		for x in SIZE.x:
			var delta := Vector2(x + 0.5, y + 0.5) - world_pivot
			var local := Vector2(cosine * delta.x + sine * delta.y, -sine * delta.x + cosine * delta.y) + local_pivot
			var source_x := floori(local.x)
			var source_y := floori(local.y)
			if source_x < 0 or source_y < 0 or source_x >= source.get_width() or source_y >= source.get_height():
				continue
			var color := source.get_pixel(source_x, source_y)
			if color.a <= 0.0:
				continue
			_blend_pixel(destination, x, y, Color(color.r, color.g, color.b, color.a * opacity))

func _blit_alpha(destination: Image, source: Image, position: Vector2i, opacity: float) -> void:
	for y in source.get_height():
		for x in source.get_width():
			var target := position + Vector2i(x, y)
			if target.x < 0 or target.y < 0 or target.x >= SIZE.x or target.y >= SIZE.y:
				continue
			var color := source.get_pixel(x, y)
			if color.a > 0.0:
				_blend_pixel(destination, target.x, target.y, Color(color.r, color.g, color.b, color.a * opacity))

func _blend_pixel(destination: Image, x: int, y: int, source: Color) -> void:
	var under := destination.get_pixel(x, y)
	var out_alpha := source.a + under.a * (1.0 - source.a)
	if out_alpha <= 0.0:
		return
	var out_rgb := (Vector3(source.r, source.g, source.b) * source.a + Vector3(under.r, under.g, under.b) * under.a * (1.0 - source.a)) / out_alpha
	destination.set_pixel(x, y, Color(out_rgb.x, out_rgb.y, out_rgb.z, out_alpha))

func _write_frame(file_name: String, image: Image) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_ROOT + file_name))
	if error != OK:
		push_error("Could not save VX-94 transform exposure %s: %s" % [file_name, error_string(error)])
		quit(1)
