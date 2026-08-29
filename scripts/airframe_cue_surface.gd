extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_airframe_cues"):
		director.call("_draw_airframe_cues", self)
