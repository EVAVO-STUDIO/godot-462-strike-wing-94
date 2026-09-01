extends Node

const LOGICAL_SIZE := Vector2i(640, 360)

func _ready() -> void:
	process_priority = 1000
	call_deferred("_capture")

func _capture() -> void:
	var delay := _argument_float("--visual-capture-delay=", 0.85)
	await get_tree().create_timer(clampf(delay, 0.1, 5.0)).timeout
	await RenderingServer.frame_post_draw
	var output := _argument_value("--visual-capture=", "")
	if output.is_empty():
		_fail("missing --visual-capture path")
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport image was empty")
		return
	if image.get_size() != LOGICAL_SIZE:
		image.resize(LOGICAL_SIZE.x, LOGICAL_SIZE.y, Image.INTERPOLATE_NEAREST)
	var absolute := ProjectSettings.globalize_path(output)
	var directory := absolute.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		_fail("could not create capture directory")
		return
	var result := image.save_png(absolute)
	if result != OK:
		_fail("PNG save failed with code %d" % result)
		return
	print("HYPERSONIC_VISUAL_CAPTURE %s %dx%d" % [absolute, image.get_width(), image.get_height()])
	get_tree().quit(0)

func _argument_value(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback

func _argument_float(prefix: String, fallback: float) -> float:
	var value := _argument_value(prefix, "")
	return value.to_float() if value.is_valid_float() else fallback

func _fail(reason: String) -> void:
	push_error("HYPERSONIC visual capture failed: %s." % reason)
	get_tree().quit(1)
