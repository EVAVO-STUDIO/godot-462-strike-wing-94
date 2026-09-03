class_name CountermeasureSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_countermeasures"):
		director.call("draw_countermeasures", self)
