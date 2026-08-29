class_name StrikeOrdnanceSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_surface"):
		director.call("_draw_surface", self)
