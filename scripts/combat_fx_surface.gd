extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_combat_fx"):
		director.call("_draw_combat_fx", self)
