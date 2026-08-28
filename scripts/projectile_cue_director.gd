extends CanvasLayer

const ProjectileCueRules = preload("res://scripts/projectile_cue_rules.gd")

class ProjectileCueCanvas:
	extends Control
	var shots: Array = []

	func _draw() -> void:
		for shot in shots:
			if typeof(shot) != TYPE_DICTIONARY:
				continue
			var position: Vector2 = shot.get("position", Vector2.ZERO)
			var direction := ProjectileCueRules.direction_for(shot)
			var radius := ProjectileCueRules.radius_for(shot)
			var trail := ProjectileCueRules.trail_length_for(shot)
			var type := ProjectileCueRules.projectile_type(shot)
			var body := Color(1.0, 0.86, 0.48, 0.92)
			if type == ProjectileCueRules.TYPE_MISSILE:
				body = Color(1.0, 0.36, 0.28, 0.96)
			elif type == ProjectileCueRules.TYPE_CANNON:
				body = Color(1.0, 0.68, 0.26, 0.94)
			draw_line(position - direction * trail, position - direction * radius, body, 2.0)
			draw_circle(position, radius, body)
			if type == ProjectileCueRules.TYPE_MISSILE:
				draw_arc(position, radius + 3.0, 0.0, TAU, 12, Color(1.0, 0.78, 0.38, 0.72), 1.0)

var _canvas: ProjectileCueCanvas

func _ready() -> void:
	layer = 16
	_canvas = ProjectileCueCanvas.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		_canvas.shots = []
		_canvas.queue_redraw()
		return
	var bullets = scene.get("enemy_bullets")
	_canvas.shots = bullets.duplicate(true) if typeof(bullets) == TYPE_ARRAY else []
	_canvas.queue_redraw()

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("enemy_bullets")
