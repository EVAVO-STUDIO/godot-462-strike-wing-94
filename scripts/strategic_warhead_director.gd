extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const StrategicWarheadRules = preload("res://scripts/strategic_warhead_rules.gd")
const StrategicWarheadSurface = preload("res://scripts/strategic_warhead_surface.gd")
const BLAST_FRAMES := [
	preload("res://assets/runtime/effects/impacts/strategic_blast/0.png"),
	preload("res://assets/runtime/effects/impacts/strategic_blast/1.png"),
	preload("res://assets/runtime/effects/impacts/strategic_blast/2.png"),
	preload("res://assets/runtime/effects/impacts/strategic_blast/3.png"),
]

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
	var index := clampi(int(floor(progress * BLAST_FRAMES.size())), 0, BLAST_FRAMES.size() - 1)
	var texture: Texture2D = BLAST_FRAMES[index]
	var alpha := 1.0 - smoothstep(0.78, 1.0, progress)
	surface.draw_texture(texture, (_burst_position - texture.get_size() * 0.5).round(), Color(1,1,1,alpha))

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "bullets", "enemies"])
