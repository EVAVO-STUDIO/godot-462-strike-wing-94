class_name MovementPatternRules
extends RefCounted

static func supported_patterns() -> Array[String]:
	return ["sine_dive", "tracking_sweep", "hover_strafe", "road_column", "water_lane", "static", "aggressive_weave"]

static func adjusted_position(pattern: String, current: Vector2, player: Vector2, age: float, delta: float, anchor_x: float) -> Vector2:
	var next := current
	match pattern:
		"sine_dive":
			next.x += sin(age * 3.2) * 42.0 * delta
		"tracking_sweep":
			next.x = move_toward(next.x, player.x, 34.0 * delta)
		"hover_strafe":
			next.x += sin(age * 2.4) * 58.0 * delta
			next.y -= 18.0 * delta
		"road_column":
			next.x = move_toward(next.x, anchor_x, 70.0 * delta)
		"water_lane":
			next.x = move_toward(next.x, anchor_x, 44.0 * delta)
			next.x += sin(age * 1.25) * 10.0 * delta
		"static":
			next.x = anchor_x
		"aggressive_weave":
			next.x += sin(age * 5.4) * 96.0 * delta
			next.x += signf(player.x - next.x) * 24.0 * delta
	return next

static func clamp_x(position: Vector2, minimum_x: float, maximum_x: float) -> Vector2:
	var next := position
	next.x = clampf(next.x, minimum_x, maximum_x)
	return next
