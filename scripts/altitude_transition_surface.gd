extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_altitude_transition_surface"):
		director.call("_draw_altitude_transition_surface", self)
