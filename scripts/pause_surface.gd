extends Control

var director: Object

func _draw() -> void:
	if director != null:
		director.draw_pause(self)
