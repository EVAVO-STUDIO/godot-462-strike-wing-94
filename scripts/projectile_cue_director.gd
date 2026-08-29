extends CanvasLayer

const ProjectileCueRules = preload("res://scripts/projectile_cue_rules.gd")

class ProjectileCueCanvas:
	extends Control
	var enemy_shots: Array = []
	var player_shots: Array = []

	func _draw() -> void:
		_draw_enemy_shots()
		_draw_player_shots()

	func _draw_enemy_shots() -> void:
		for shot in enemy_shots:
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

	func _draw_player_shots() -> void:
		for shot in player_shots:
			if typeof(shot) != TYPE_DICTIONARY:
				continue
			var position: Vector2 = shot.get("position", Vector2.ZERO)
			var velocity: Vector2 = shot.get("velocity", Vector2.UP * 300.0)
			var direction := velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.UP
			var weapon_id := str(shot.get("weapon_id", ""))
			if weapon_id == "needle_rail" or bool(shot.get("kinetic", false)):
				_draw_kinetic(position, direction)
			elif weapon_id == "storm_cannon":
				_draw_energy_pulse(position, direction)
			elif bool(shot.get("support_homing", false)) or bool(shot.get("support", false)):
				_draw_support_round(position, direction, bool(shot.get("support_homing", false)))
			else:
				_draw_ballistic(position, direction)

	func _draw_ballistic(position: Vector2, direction: Vector2) -> void:
		var color := Color(0.95, 0.82, 0.42, 0.9)
		draw_line(position - direction * 7.0, position + direction * 2.0, color, 1.0)
		draw_rect(Rect2(position.x-1, position.y-2, 2, 4), color)

	func _draw_kinetic(position: Vector2, direction: Vector2) -> void:
		var core := Color(0.78, 0.95, 1.0, 0.98)
		var wake := Color(0.30, 0.66, 0.78, 0.68)
		draw_line(position - direction * 18.0, position - direction * 3.0, wake, 1.0)
		draw_line(position - direction * 6.0, position + direction * 5.0, core, 2.0)

	func _draw_energy_pulse(position: Vector2, direction: Vector2) -> void:
		var core := Color(0.55, 0.90, 1.0, 0.96)
		var edge := Color(0.24, 0.58, 0.82, 0.76)
		draw_circle(position, 3.0, core)
		draw_arc(position, 5.0, 0.0, TAU, 8, edge, 1.0)
		draw_line(position - direction * 8.0, position - direction * 3.0, edge, 1.0)

	func _draw_support_round(position: Vector2, direction: Vector2, homing: bool) -> void:
		var core := Color(0.52, 0.84, 0.66, 0.94)
		draw_line(position - direction * 10.0, position, core, 2.0)
		draw_circle(position, 2.0, core)
		if homing:
			draw_arc(position, 4.0, 0.0, TAU, 8, Color(0.72, 0.95, 0.78, 0.7), 1.0)

var _canvas: ProjectileCueCanvas

func _ready() -> void:
	layer = 16
	_canvas = ProjectileCueCanvas.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.custom_minimum_size = Vector2(640, 360)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		_canvas.enemy_shots = []
		_canvas.player_shots = []
		_canvas.queue_redraw()
		return
	var enemy_bullets = scene.get("enemy_bullets")
	var player_bullets = scene.get("bullets")
	_canvas.enemy_shots = enemy_bullets.duplicate(true) if typeof(enemy_bullets) == TYPE_ARRAY else []
	_canvas.player_shots = player_bullets.duplicate(true) if typeof(player_bullets) == TYPE_ARRAY else []
	_canvas.queue_redraw()

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("enemy_bullets") and names.has("bullets")
