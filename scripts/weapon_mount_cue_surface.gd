extends Control

var director: Node

func _draw() -> void:
	if director != null and director.has_method("_draw_weapon_mount_cues"):
		director.call("_draw_weapon_mount_cues", self)
