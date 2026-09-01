extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const ElectromagneticCueSurface = preload("res://scripts/electromagnetic_cue_surface.gd")
const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")
const MAGNETIC_FIELD_FRAMES := [
	preload("res://assets/runtime/effects/fields/magnetic_field/0.png"),
	preload("res://assets/runtime/effects/fields/magnetic_field/1.png"),
	preload("res://assets/runtime/effects/fields/magnetic_field/2.png"),
	preload("res://assets/runtime/effects/fields/magnetic_field/3.png"),
]

var _surface: Control
var _animation_clock := 0.0

func _ready() -> void:
	layer = 15
	_surface = ElectromagneticCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_animation_clock += maxf(0.0, delta)
	if _surface != null:
		_surface.queue_redraw()

func _draw_surface(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	_draw_magnetic(surface, scene)
	_draw_emp(surface, scene)

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "player_position", "enemies"])

func _draw_magnetic(surface: CanvasItem, scene: Object) -> void:
	var support := get_node_or_null("/root/SupportDirector")
	if support == null or not support.has_method("magnetic_active") or not bool(support.call("magnetic_active")):
		return
	var radius := 92.0
	if support.has_method("current_support"):
		var item = support.call("current_support")
		if typeof(item) == TYPE_DICTIONARY:
			radius = clampf(float(item.get("radius", radius)), 24.0, 240.0)
	var p: Vector2 = scene.get("player_position")
	var texture: Texture2D = MAGNETIC_FIELD_FRAMES[int(floor(_animation_clock * 8.0)) % MAGNETIC_FIELD_FRAMES.size()]
	var diameter := radius * 2.0 + 12.0
	surface.draw_texture_rect(texture, Rect2(p - Vector2(diameter, diameter) * 0.5, Vector2(diameter, diameter)), false)

func _draw_emp(surface: CanvasItem, scene: Object) -> void:
	var enemies: Array = scene.get("enemies")
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY or float(enemy.get("emp_timer", 0.0)) <= 0.0:
			continue
		var p: Vector2 = enemy.get("position", Vector2.ZERO)
		var texture := ImpactArtLibrary.frame_for_clock("emp_disruption", 12.0)
		surface.draw_texture(texture, (p - Vector2(12, 12)).round())
