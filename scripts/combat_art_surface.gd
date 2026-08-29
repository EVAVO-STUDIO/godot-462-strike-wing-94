class_name CombatArtSurface
extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_combat_art"):
		director.call("_draw_combat_art", self)
