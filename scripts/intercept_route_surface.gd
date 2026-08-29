extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_intercept_routes"):
		director.call("_draw_intercept_routes", self)
