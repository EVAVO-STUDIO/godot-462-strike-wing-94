extends Control
var director:Node
func _draw()->void:
	if director!=null and director.has_method("draw_feedback"):director.call("draw_feedback",self)
