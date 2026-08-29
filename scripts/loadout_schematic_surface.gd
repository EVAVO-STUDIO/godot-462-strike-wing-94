extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_schematic"):
		director.call("draw_schematic", self)
