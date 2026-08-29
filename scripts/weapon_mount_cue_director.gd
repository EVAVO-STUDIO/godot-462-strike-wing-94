extends CanvasLayer

const WeaponMountCueSurface = preload("res://scripts/weapon_mount_cue_surface.gd")

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
	var craft := get_node_or_null("/root/CraftFormDirector")
	_mounts.clear()
	_rotary = false
	_weapon_id = str(weapon.get("id", ""))
	if craft != null:
		if craft.has_method("primary_mount_offsets"):
			var offsets = craft.call("primary_mount_offsets", weapon, count)
			if typeof(offsets) == TYPE_ARRAY:
				for offset in offsets:
					if typeof(offset) == TYPE_VECTOR2:
						_mounts.append(offset)
		if craft.has_method("bomber_rotary_deployed"):
			_rotary = bool(craft.call("bomber_rotary_deployed", weapon))
	_flash_timer = ROTARY_FLASH_SECONDS if _rotary else FLASH_SECONDS

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
	var outer := Color(1.0, 0.72, 0.28, 0.88)
	var core := Color(1.0, 0.94, 0.68, 0.96)
	if _weapon_id == "needle_rail":
		outer = Color(0.40, 0.80, 0.94, 0.86)
		core = Color(0.88, 0.98, 1.0, 0.98)
	elif _weapon_id in ["storm_cannon", "plasma_lance"]:
		outer = Color(0.50, 0.54, 0.98, 0.84)
		core = Color(0.82, 0.94, 1.0, 0.98)
	surface.draw_line(p, p + Vector2(0, -8), outer, 2.0)
	surface.draw_rect(Rect2(roundf(p.x)-1, roundf(p.y)-10, 3, 4), core)

func _draw_rotary_flash(surface: CanvasItem, p: Vector2) -> void:
	var flicker := 1.0 if sin(_phase) >= 0.0 else 0.72
	var flame := Color(1.0, 0.63, 0.18, 0.90 * flicker)
	var core := Color(1.0, 0.92, 0.58, 0.98)
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-4, 0),
		p + Vector2(-2, -8),
		p + Vector2(0, -14),
		p + Vector2(2, -8),
		p + Vector2(4, 0)
	]), flame)
	surface.draw_rect(Rect2(roundf(p.x)-1, roundf(p.y)-12, 3, 8), core)
	# Tiny alternating barrel-end pixels imply rotary spool without a modern particle effect.
	var barrel_offset := 2 if sin(_phase * 1.7) >= 0.0 else -2
	surface.draw_rect(Rect2(roundf(p.x)+barrel_offset-1, roundf(p.y)-4, 2, 2), Color(0.94,0.78,0.36,0.96))

func _active_weapon(scene: Object) -> Dictionary:
	if scene.has_method("_active_weapon"):
		var weapon = scene.call("_active_weapon")
		if typeof(weapon) == TYPE_DICTIONARY:
			return weapon
	return {}

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
