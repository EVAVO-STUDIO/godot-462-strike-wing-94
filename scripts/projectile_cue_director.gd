extends CanvasLayer

const ProjectileCueRules = preload("res://scripts/projectile_cue_rules.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const PROJECTILE_FRAMES := {
	"ballistic": [
		preload("res://assets/runtime/effects/projectiles/ballistic/0.png"),
		preload("res://assets/runtime/effects/projectiles/ballistic/1.png"),
		preload("res://assets/runtime/effects/projectiles/ballistic/2.png"),
		preload("res://assets/runtime/effects/projectiles/ballistic/3.png")
	],
	"enemy_cannon": [
		preload("res://assets/runtime/effects/projectiles/enemy_cannon/0.png"),
		preload("res://assets/runtime/effects/projectiles/enemy_cannon/1.png"),
		preload("res://assets/runtime/effects/projectiles/enemy_cannon/2.png"),
		preload("res://assets/runtime/effects/projectiles/enemy_cannon/3.png")
	],
	"homing_missile": [
		preload("res://assets/runtime/effects/projectiles/homing_missile/0.png"),
		preload("res://assets/runtime/effects/projectiles/homing_missile/1.png"),
		preload("res://assets/runtime/effects/projectiles/homing_missile/2.png"),
		preload("res://assets/runtime/effects/projectiles/homing_missile/3.png")
	],
	"needle_rail": [
		preload("res://assets/runtime/effects/projectiles/needle_rail/0.png"),
		preload("res://assets/runtime/effects/projectiles/needle_rail/1.png"),
		preload("res://assets/runtime/effects/projectiles/needle_rail/2.png"),
		preload("res://assets/runtime/effects/projectiles/needle_rail/3.png")
	],
	"plasma_lance": [
		preload("res://assets/runtime/effects/projectiles/plasma_lance/0.png"),
		preload("res://assets/runtime/effects/projectiles/plasma_lance/1.png"),
		preload("res://assets/runtime/effects/projectiles/plasma_lance/2.png"),
		preload("res://assets/runtime/effects/projectiles/plasma_lance/3.png")
	],
	"support_rocket": [
		preload("res://assets/runtime/effects/projectiles/support_rocket/0.png"),
		preload("res://assets/runtime/effects/projectiles/support_rocket/1.png"),
		preload("res://assets/runtime/effects/projectiles/support_rocket/2.png"),
		preload("res://assets/runtime/effects/projectiles/support_rocket/3.png")
	],
	"strategic_warhead": [
		preload("res://assets/runtime/effects/projectiles/strategic_warhead/0.png"),
		preload("res://assets/runtime/effects/projectiles/strategic_warhead/1.png"),
		preload("res://assets/runtime/effects/projectiles/strategic_warhead/2.png"),
		preload("res://assets/runtime/effects/projectiles/strategic_warhead/3.png")
	]
}

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
			var type := ProjectileCueRules.projectile_type(shot)
			_draw_registered_sprite(position, direction, "homing_missile" if type == ProjectileCueRules.TYPE_MISSILE else "enemy_cannon")

	func _draw_player_shots() -> void:
		for shot in player_shots:
			if typeof(shot) != TYPE_DICTIONARY:
				continue
			var position: Vector2 = shot.get("position", Vector2.ZERO)
			var velocity: Vector2 = shot.get("velocity", Vector2.UP * 300.0)
			var direction := velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.UP
			var weapon_id := str(shot.get("weapon_id", ""))
			if bool(shot.get("strategic_support", false)):
				_draw_strategic_warhead(position, direction)
			elif weapon_id == "needle_rail" or bool(shot.get("kinetic", false)):
				_draw_kinetic(position, direction)
			elif weapon_id == "plasma_lance":
				_draw_plasma_lance(position, direction)
			elif weapon_id == "storm_cannon":
				_draw_energy_pulse(position, direction)
			elif bool(shot.get("support_homing", false)) or bool(shot.get("support", false)):
				_draw_support_round(position, direction, bool(shot.get("support_homing", false)))
			else:
				_draw_ballistic(position, direction)

	func _draw_ballistic(position: Vector2, direction: Vector2) -> void:
		_draw_registered_sprite(position, direction, "ballistic")

	func _draw_kinetic(position: Vector2, direction: Vector2) -> void:
		_draw_registered_sprite(position, direction, "needle_rail")

	func _draw_energy_pulse(position: Vector2, direction: Vector2) -> void:
		_draw_registered_sprite(position, direction, "needle_rail")

	func _draw_plasma_lance(position: Vector2, direction: Vector2) -> void:
		_draw_registered_sprite(position, direction, "plasma_lance")

	func _draw_support_round(position: Vector2, direction: Vector2, homing: bool) -> void:
		_draw_registered_sprite(position, direction, "support_rocket" if homing else "ballistic")

	func _draw_strategic_warhead(position: Vector2, direction: Vector2) -> void:
		_draw_registered_sprite(position, direction, "strategic_warhead")

	func _draw_registered_sprite(position: Vector2, direction: Vector2, family: String) -> void:
		var frames: Array = PROJECTILE_FRAMES[family]
		var frame_index := int(floor(Time.get_ticks_msec() / 83.0)) % frames.size()
		var texture: Texture2D = frames[frame_index]
		draw_set_transform(position.round(), Vector2.UP.angle_to(direction), Vector2.ONE)
		# Late-DOS shooters keyed tiny ordnance with a one-pixel ink trap so hot
		# cores survived both pale terrain and near-black water. Keep the original
		# raster untouched and underprint it at runtime; enhanced contrast remains
		# a stronger accessibility tint rather than the only readable mode.
		for offset in [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]:
			draw_texture(texture, Vector2(-8, -7) + offset, Color(0.01,0.02,0.03,0.78))
		var settings := get_node_or_null("/root/SettingsDirector")
		if settings != null and settings.has_method("enhanced_projectile_contrast") and bool(settings.call("enhanced_projectile_contrast")):
			var contrast_tint := Color("ffb278") if family in ["enemy_cannon", "homing_missile"] else Color("b8f4ff")
			draw_texture(texture, Vector2(-8, -7), contrast_tint)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		draw_texture(texture, Vector2(-8, -7))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
	return SceneContractCache.supports(scene, ["phase", "enemy_bullets", "bullets"])
