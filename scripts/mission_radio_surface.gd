class_name MissionRadioSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_radio"): director.call("draw_radio", self)
