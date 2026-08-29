extends CanvasLayer

const StrategicWarheadRules = preload("res://scripts/strategic_warhead_rules.gd")
const StrategicWarheadSurface = preload("res://scripts/strategic_warhead_surface.gd")

const BLAST_SECONDS := 0.22

var _surface: Control
var _burst_position := Vector2.ZERO
var _burst_timer := 0.0

func _ready() -> void:
	layer = 15
	process_priority = -2
	_surface = StrategicWarheadSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	_burst_timer = maxf(0.0, _burst_timer - maxf(0.0, delta))
	var scene := get_tree().current_scene
	if scene != null and _supports(scene) and int(scene.get("phase")) == 1:
		_update_warheads(scene)
	if _surface != null:
		_surface.queue_redraw()

func _update_warheads(scene: Object) -> void:
	var bullets: Array = scene.get("bullets")
	var enemies: Array = scene.get("enemies")
	if bullets.is_empty() or enemies.is_empty(): return
	var bullets_changed := false
	var enemies_changed := false
	for bi in range(bullets.size()):
		var bullet = bullets[bi]
		if typeof(bullet) != TYPE_DICTIONARY or not StrategicWarheadRules.can_burst(bullet): continue
		var position: Vector2 = bullet.get("position", Vector2.ZERO)
		var primary_index := StrategicWarheadRules.trigger_enemy_index(position, enemies)
		if primary_index < 0: continue
		bullet["strategic_burst"] = true
		bullets[bi] = bullet
		bullets_changed = true
		_burst_position = position
		_burst_timer = BLAST_SECONDS
		for enemy_index in StrategicWarheadRules.secondary_indices(position, enemies, primary_index):
			if enemy_index < 0 or enemy_index >= enemies.size(): continue
			var enemy: Dictionary = enemies[enemy_index]
			var hp := maxi(0, int(enemy.get("hp", 0)))
			if hp <= 1: continue
			var damage := mini(StrategicWarheadRules.SECONDARY_DAMAGE, hp - 1)
			enemy["hp"] = hp - damage
			enemies[enemy_index] = enemy
			enemies_changed = true
	if bullets_changed: scene.set("bullets", bullets)
	if enemies_changed: scene.set("enemies", enemies)

func draw_blast(surface: CanvasItem) -> void:
	if _burst_timer <= 0.0: return
	var progress := clampf(1.0 - (_burst_timer / BLAST_SECONDS), 0.0, 1.0)
	var radius := lerpf(10.0, StrategicWarheadRules.BLAST_RADIUS, progress)
	var outer := Color(1.0, 0.40, 0.18, 0.82 * (1.0 - progress))
	var inner := Color(1.0, 0.82, 0.40, 0.92 * (1.0 - progress))
	surface.draw_arc(_burst_position, radius, 0.0, TAU, 20, outer, 2.0)
	surface.draw_arc(_burst_position, maxf(3.0, radius * 0.55), 0.0, TAU, 16, inner, 1.0)
	for axis in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		surface.draw_line(_burst_position + axis * maxf(3.0, radius * 0.25), _burst_position + axis * radius, outer, 1.0)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("bullets") and names.has("enemies")
