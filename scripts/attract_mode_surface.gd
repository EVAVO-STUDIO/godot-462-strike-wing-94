class_name AttractModeSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_attract_mode"):
		director.call("draw_attract_mode", self)
