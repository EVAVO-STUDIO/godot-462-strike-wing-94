extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_intel"):
		director.call("draw_intel", self)
