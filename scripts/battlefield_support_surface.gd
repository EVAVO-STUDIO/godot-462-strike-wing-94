class_name BattlefieldSupportSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_support_surface"):
		director.call("_draw_support_surface", self)
