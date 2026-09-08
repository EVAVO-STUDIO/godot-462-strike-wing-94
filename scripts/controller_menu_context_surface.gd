extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("draw_context_hint"):
		director.call("draw_context_hint", self)
