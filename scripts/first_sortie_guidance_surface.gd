extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_guidance"):
		director.call("draw_guidance", self)
