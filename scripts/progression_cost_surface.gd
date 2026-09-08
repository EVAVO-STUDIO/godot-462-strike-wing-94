class_name ProgressionCostSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_progression_costs"):
		director.call("draw_progression_costs", self)
