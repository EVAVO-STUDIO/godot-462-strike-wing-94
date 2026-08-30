class_name StartupSequenceSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_startup_sequence"):
		director.call("draw_startup_sequence", self)
