class_name EnvironmentSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_environment_surface"):
		director.call("_draw_environment_surface", self)
