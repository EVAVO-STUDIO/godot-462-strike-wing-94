extends CanvasLayer

const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const WeaponMountCueSurface = preload("res://scripts/weapon_mount_cue_surface.gd")
const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")

const FLASH_SECONDS := 0.065
const ROTARY_FLASH_SECONDS := 0.11

var _surface: Control
var _flash_timer := 0.0
var _last_shots_fired := 0
var _mounts: Array[Vector2] = []
var _rotary := false
var _weapon_id := ""
var _phase := 0.0

func _ready() -> void:
	layer = 15
	_surface = WeaponMountCueSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_flash_timer = maxf(0.0, _flash_timer - delta)
	_phase = fposmod(_phase + delta * 34.0, TAU)
	_observe_fire()
	if _surface != null:
		_surface.queue_redraw()

func _observe_fire() -> void:
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "phase") or not _has_property(scene, "shots_fired"):
		return
	if int(scene.get("phase")) != 1:
		_last_shots_fired = int(scene.get("shots_fired"))
		_flash_timer = 0.0
		return
	var fired := int(scene.get("shots_fired"))
	if fired <= _last_shots_fired:
		return
	_last_shots_fired = fired
	var weapon := _active_weapon(scene)
	var count := maxi(1, int(weapon.get("projectiles", 1)))
	var form := _current_form()
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	_mounts.clear()
	_rotary = false
	_weapon_id = str(weapon.get("id", ""))
	if mounts != null:
		if mounts.has_method("primary_offsets"):
			var offsets = mounts.call("primary_offsets", form, weapon, count)
			if typeof(offsets) == TYPE_ARRAY:
				for offset in offsets:
					if typeof(offset) == TYPE_VECTOR2:
						_mounts.append(offset)
		if mounts.has_method("bomber_rotary_deployed"):
			_rotary = bool(mounts.call("bomber_rotary_deployed", form, weapon))
	_flash_timer = ROTARY_FLASH_SECONDS if _rotary else FLASH_SECONDS

func _current_form() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_form"):
		return str(craft.call("current_form"))
	return "fighter"

func _draw_weapon_mount_cues(surface: CanvasItem) -> void:
	if _flash_timer <= 0.0:
		return
	var scene := get_tree().current_scene
	if scene == null or not _has_property(scene, "player_position"):
		return
	var origin: Vector2 = scene.get("player_position")
	if _mounts.is_empty():
		_mounts = [Vector2(0, -18)]
	if _rotary:
		_draw_rotary_flash(surface, origin + _mounts[0])
		return
	for offset in _mounts:
		_draw_mount_flash(surface, origin + offset)

func _draw_mount_flash(surface: CanvasItem, p: Vector2) -> void:
	var ratio := 1.0 - clampf(_flash_timer / FLASH_SECONDS, 0.0, 1.0)
	var texture := ImpactArtLibrary.frame_for_ratio("muzzle", ratio)
	var tint := Color.WHITE
	if _weapon_id == "needle_rail": tint = Color(0.66, 0.92, 1.0)
	elif _weapon_id in ["storm_cannon", "plasma_lance"]: tint = Color(0.78, 0.74, 1.0)
	surface.draw_texture(texture, (p - Vector2(12, 16)).round(), tint)

func _draw_rotary_flash(surface: CanvasItem, p: Vector2) -> void:
	var ratio := 1.0 - clampf(_flash_timer / ROTARY_FLASH_SECONDS, 0.0, 1.0)
	var texture := ImpactArtLibrary.frame_for_ratio("rotary_muzzle", ratio)
	surface.draw_texture(texture, (p - Vector2(12, 16)).round())

func _active_weapon(scene: Object) -> Dictionary:
	if scene.has_method("_active_weapon"):
		var weapon = scene.call("_active_weapon")
		if typeof(weapon) == TYPE_DICTIONARY:
			return weapon
	return {}

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)
