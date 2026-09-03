extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_targeting"):
		director.call("draw_targeting", self)
