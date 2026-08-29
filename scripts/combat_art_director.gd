extends CanvasLayer

const CombatArtSurface = preload("res://scripts/combat_art_surface.gd")

const PLAYER := Color("d9e0e5")
const PLAYER_DARK := Color("667985")
const PLAYER_GLASS := Color("6aa4c8")
const PLAYER_ENGINE := Color("e8ca6a")
const MERC_AIR := Color("9f5049")
const MERC_DARK := Color("4d3e3a")
const SURFACE := Color("766b55")
const SURFACE_DARK := Color("3d3a31")
const AI := Color("b7c7ca")
const AI_DARK := Color("45545a")
const AI_CORE := Color("67c3a5")
const BOSS := Color("c86054")
const BOSS_DARK := Color("55322f")
const TRANSFORM_VISUAL_SECONDS := 0.34

var _surface: Control
var _visual_sweep := 0.0

func _ready() -> void:
	layer = 12
	_surface = CombatArtSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	var target := 1.0 if _craft_form() == "bomber" else 0.0
	_visual_sweep = move_toward(_visual_sweep, target, maxf(0.0, delta) / TRANSFORM_VISUAL_SECONDS)
	if _surface != null:
		_surface.queue_redraw()

func _draw_combat_art(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			_draw_enemy(surface, enemy)
	_draw_player(surface, scene.get("player_position"))

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("player_position") and names.has("enemies")

func _draw_player(surface: CanvasItem, position: Vector2) -> void:
	if _visual_sweep <= 0.02:
		_draw_fighter(surface, position)
	elif _visual_sweep >= 0.98:
		_draw_bomber(surface, position)
	else:
		_draw_transforming(surface, position, _visual_sweep)

func _draw_transforming(surface: CanvasItem, p: Vector2, sweep: float) -> void:
	var t := clampf(sweep, 0.0, 1.0)
	var wing := roundf(lerpf(17.0, 29.0, t))
	var wing_y := roundf(lerpf(9.0, 5.0, t))
	var shoulder := roundf(lerpf(8.0, 25.0, t))
	var shoulder_y := roundf(lerpf(8.0, 12.0, t))
	var rear := roundf(lerpf(5.0, 7.0, t))
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,-20), p+Vector2(-5,-8), p+Vector2(-wing,wing_y),
		p+Vector2(-shoulder,shoulder_y), p+Vector2(-rear,17), p+Vector2(0,12),
		p+Vector2(rear,17), p+Vector2(shoulder,shoulder_y), p+Vector2(wing,wing_y), p+Vector2(5,-8)
	]), PLAYER)
	var glass_tip := roundf(lerpf(-15.0, -14.0, t))
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,glass_tip), p+Vector2(-4,-4), p+Vector2(0,5), p+Vector2(4,-4)
	]), PLAYER_GLASS)
	var engine_span := roundf(lerpf(7.0, 18.0, t))
	surface.draw_rect(Rect2(p.x-engine_span, p.y+13, 4, 3), PLAYER_ENGINE)
	surface.draw_rect(Rect2(p.x+engine_span-4, p.y+13, 4, 3), PLAYER_ENGINE)
	surface.draw_rect(Rect2(p.x-2, p.y+6, 4, 9), PLAYER_DARK)
	# Mechanical hinge marks make the sweep read as variable-geometry hardware.
	surface.draw_rect(Rect2(p.x-8,p.y+5,3,3), PLAYER_DARK)
	surface.draw_rect(Rect2(p.x+5,p.y+5,3,3), PLAYER_DARK)

func _draw_fighter(surface: CanvasItem, p: Vector2) -> void:
	# Opaque body deliberately covers the prototype polygon underneath.
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-21), p + Vector2(-5,-7), p + Vector2(-17,9),
		p + Vector2(-8,8), p + Vector2(-5,16), p + Vector2(0,11),
		p + Vector2(5,16), p + Vector2(8,8), p + Vector2(17,9), p + Vector2(5,-7)
	]), PLAYER)
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-15), p + Vector2(-4,-4), p + Vector2(0,5), p + Vector2(4,-4)
	]), PLAYER_GLASS)
	surface.draw_rect(Rect2(p.x-2, p.y+6, 4, 8), PLAYER_DARK)
	surface.draw_rect(Rect2(p.x-7, p.y+13, 4, 3), PLAYER_ENGINE)
	surface.draw_rect(Rect2(p.x+3, p.y+13, 4, 3), PLAYER_ENGINE)
	surface.draw_line(p + Vector2(-7,3), p + Vector2(-18,11), PLAYER_DARK, 2)
	surface.draw_line(p + Vector2(7,3), p + Vector2(18,11), PLAYER_DARK, 2)

func _draw_bomber(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-19), p + Vector2(-5,-8), p + Vector2(-29,5),
		p + Vector2(-25,12), p + Vector2(-10,9), p + Vector2(-7,17),
		p + Vector2(0,12), p + Vector2(7,17), p + Vector2(10,9),
		p + Vector2(25,12), p + Vector2(29,5), p + Vector2(5,-8)
	]), PLAYER)
	surface.draw_rect(Rect2(p.x-18, p.y+6, 36, 4), PLAYER_DARK)
	surface.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,-14), p + Vector2(-5,-3), p + Vector2(0,5), p + Vector2(5,-3)
	]), PLAYER_GLASS)
	for x in [-18, -8, 5, 15]:
		surface.draw_rect(Rect2(p.x+x, p.y+10, 4, 3), PLAYER_ENGINE)
	surface.draw_rect(Rect2(p.x-3, p.y+5, 6, 12), PLAYER_DARK)
	surface.draw_rect(Rect2(p.x-9,p.y+4,3,3), PLAYER_DARK)
	surface.draw_rect(Rect2(p.x+6,p.y+4,3,3), PLAYER_DARK)

func _draw_enemy(surface: CanvasItem, enemy: Dictionary) -> void:
	var p: Vector2 = enemy.get("position", Vector2.ZERO)
	var is_boss := bool(enemy.get("boss", false))
	var faction := str(enemy.get("faction", "mercenary"))
	var category := str(enemy.get("category", "air"))
	if is_boss:
		_draw_boss(surface, p, str(enemy.get("id", "boss")), faction)
	elif faction == "autonomous":
		_draw_autonomous(surface, p, str(enemy.get("id", "drone")), category)
	elif category == "ground":
		_draw_ground(surface, p)
	elif category == "sea":
		_draw_sea(surface, p)
	else:
		_draw_air(surface, p)

func _draw_air(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,12), p+Vector2(-15,-7), p+Vector2(-5,-4),
		p+Vector2(0,-10), p+Vector2(5,-4), p+Vector2(15,-7)
	]), MERC_AIR)
	surface.draw_rect(Rect2(p.x-3,p.y-7,6,15), MERC_DARK)
	surface.draw_rect(Rect2(p.x-8,p.y-6,3,3), Color("d3a56c"))
	surface.draw_rect(Rect2(p.x+5,p.y-6,3,3), Color("d3a56c"))

func _draw_ground(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_rect(Rect2(p.x-13,p.y-7,26,14), SURFACE)
	surface.draw_rect(Rect2(p.x-9,p.y-11,18,7), SURFACE_DARK)
	surface.draw_rect(Rect2(p.x-2,p.y-15,4,9), SURFACE)
	surface.draw_line(p+Vector2(1,-12), p+Vector2(11,-17), SURFACE_DARK, 2)
	for x in [-10,-4,4,10]:
		surface.draw_rect(Rect2(p.x+x-2,p.y+6,4,3), Color("252722"))

func _draw_sea(surface: CanvasItem, p: Vector2) -> void:
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,-16), p+Vector2(-12,9), p+Vector2(-8,14),
		p+Vector2(8,14), p+Vector2(12,9)
	]), SURFACE)
	surface.draw_rect(Rect2(p.x-5,p.y-6,10,12), SURFACE_DARK)
	surface.draw_rect(Rect2(p.x-2,p.y-11,4,8), Color("94907b"))

func _draw_autonomous(surface: CanvasItem, p: Vector2, id: String, category: String) -> void:
	if category == "ground":
		surface.draw_rect(Rect2(p.x-12,p.y-9,24,18), AI_DARK)
		surface.draw_rect(Rect2(p.x-8,p.y-13,16,8), AI)
		surface.draw_rect(Rect2(p.x-3,p.y-5,6,6), AI_CORE)
		return
	var wide := 18.0 if id in ["drone_bomber","orbital_sentry"] else 13.0
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,13), p+Vector2(-wide,-4), p+Vector2(-6,-10),
		p+Vector2(0,-6), p+Vector2(6,-10), p+Vector2(wide,-4)
	]), AI)
	surface.draw_rect(Rect2(p.x-3,p.y-4,6,7), AI_CORE)
	surface.draw_line(p+Vector2(-wide+3,-3), p+Vector2(-5,5), AI_DARK, 2)
	surface.draw_line(p+Vector2(wide-3,-3), p+Vector2(5,5), AI_DARK, 2)

func _draw_boss(surface: CanvasItem, p: Vector2, id: String, faction: String) -> void:
	var body := AI if faction == "autonomous" else BOSS
	var dark := AI_DARK if faction == "autonomous" else BOSS_DARK
	var half_width := 34.0
	if id in ["missile_cruiser","orbital_command_node"]:
		half_width = 43.0
	elif id in ["armoured_train","ai_forge_core"]:
		half_width = 38.0
	surface.draw_colored_polygon(PackedVector2Array([
		p+Vector2(0,24), p+Vector2(-half_width,0), p+Vector2(-25,-15),
		p+Vector2(0,-20), p+Vector2(25,-15), p+Vector2(half_width,0)
	]), body)
	surface.draw_rect(Rect2(p.x-15,p.y-9,30,19), dark)
	surface.draw_rect(Rect2(p.x-5,p.y-14,10,10), AI_CORE if faction == "autonomous" else Color("e1b16d"))
	for x in [-25,20]:
		surface.draw_rect(Rect2(p.x+x,p.y+5,6,4), dark)

func _craft_form() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("current_form"):
		return str(director.call("current_form"))
	return "fighter"
