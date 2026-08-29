extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_damage_state"):
		director.call("_draw_damage_state", self)
