extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const DamageStateSurface = preload("res://scripts/damage_state_surface.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const TRANSFORM_VISUAL_SECONDS := 0.42

var _surface: Control
var _form_sweep := 0.0

func _ready() -> void:
	layer = 15
	_surface = DamageStateSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	var target := 1.0 if _craft_form() == "bomber" else 0.0
	_form_sweep = move_toward(_form_sweep, target, maxf(0.0, delta) / TRANSFORM_VISUAL_SECONDS)
	if _surface != null:
		_surface.queue_redraw()

func _draw_damage_state(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var max_hull := _max_hull(scene)
	if max_hull <= 0:
		return
	var hull := clampi(int(scene.get("hull")), 0, max_hull)
	var damage_ratio := clampf(1.0 - float(hull) / float(max_hull), 0.0, 1.0)
	if damage_ratio < 0.20:
		return
	var p: Vector2 = scene.get("player_position")
	if damage_ratio >= 0.45:
		_draw_smoke(surface, p, damage_ratio)
	if damage_ratio >= 0.72:
		_draw_critical_sparks(surface, p, damage_ratio)

func _lerp_mount(fighter_offset: Vector2, bomber_offset: Vector2) -> Vector2:
	var t := smoothstep(0.0, 1.0, clampf(_form_sweep, 0.0, 1.0))
	var point := fighter_offset.lerp(bomber_offset, t)
	return Vector2(roundf(point.x), roundf(point.y))

func _draw_smoke(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var origin := p + _lerp_mount(Vector2(-6,11), Vector2(-14,10))
	var texture := PersistentEffectArtLibrary.frame_for_clock("damage_smoke", 8.0)
	var alpha := clampf(0.55 + ratio * 0.45, 0.0, 1.0)
	surface.draw_texture(texture, (origin - Vector2(16,4)).round(), Color(1,1,1,alpha))

func _draw_critical_sparks(surface: CanvasItem, p: Vector2, ratio: float) -> void:
	var origin := p + _lerp_mount(Vector2(6,7), Vector2(13,6))
	var sparks := PersistentEffectArtLibrary.frame_for_clock("damage_sparks", 11.0)
	surface.draw_texture(sparks, (origin - Vector2(16,4)).round())
	if ratio >= 0.86:
		var fire := PersistentEffectArtLibrary.frame_for_clock("damage_fire", 9.0, 1)
		surface.draw_texture(fire, (origin - Vector2(16,4)).round())

func _max_hull(scene: Object) -> int:
	if scene.has_method("_max_hull"):
		return maxi(1, int(scene.call("_max_hull")))
	return 100

func _craft_form() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_form"):
		return str(craft.call("current_form"))
	return "fighter"

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "hull", "player_position"])
