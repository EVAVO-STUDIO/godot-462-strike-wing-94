extends RefCounted

static func draw_nine_slice(surface: CanvasItem, texture: Texture2D, rect: Rect2, border: int) -> void:
	if texture == null or rect.size.x < border * 2 or rect.size.y < border * 2:
		return
	var source_size := texture.get_size()
	var b := float(border)
	var source_middle := source_size - Vector2(b * 2.0, b * 2.0)
	var destination_middle := rect.size - Vector2(b * 2.0, b * 2.0)
	var source_x := [0.0, b, source_size.x - b]
	var source_y := [0.0, b, source_size.y - b]
	var source_w := [b, source_middle.x, b]
	var source_h := [b, source_middle.y, b]
	var destination_x := [rect.position.x, rect.position.x + b, rect.end.x - b]
	var destination_y := [rect.position.y, rect.position.y + b, rect.end.y - b]
	var destination_w := [b, destination_middle.x, b]
	var destination_h := [b, destination_middle.y, b]
	for y in range(3):
		for x in range(3):
			surface.draw_texture_rect_region(
				texture,
				Rect2(destination_x[x], destination_y[y], destination_w[x], destination_h[y]),
				Rect2(source_x[x], source_y[y], source_w[x], source_h[y])
			)

static func draw_three_slice_horizontal(surface: CanvasItem, texture: Texture2D, rect: Rect2, border: int) -> void:
	if texture == null or rect.size.x < border * 2 or rect.size.y <= 0:
		return
	var source_size := texture.get_size()
	var b := float(border)
	var source_middle := source_size.x - b * 2.0
	var destination_middle := rect.size.x - b * 2.0
	var source_x := [0.0, b, source_size.x - b]
	var source_w := [b, source_middle, b]
	var destination_x := [rect.position.x, rect.position.x + b, rect.end.x - b]
	var destination_w := [b, destination_middle, b]
	for x in range(3):
		surface.draw_texture_rect_region(
			texture,
			Rect2(destination_x[x], rect.position.y, destination_w[x], rect.size.y),
			Rect2(source_x[x], 0, source_w[x], source_size.y)
		)
