extends CanvasLayer

const StrikeOrdnanceRules = preload("res://scripts/strike_ordnance_rules.gd")
const StrikeOrdnanceSurface = preload("res://scripts/strike_ordnance_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")

var ordnance := StrikeOrdnanceRules.MAX_ORDNANCE
var _cooldown := 0.0
var _pending: Array = []
var _surface: Control
var _last_phase := -1

func _ready() -> void:
	layer = 14
	_surface = StrikeOrdnanceSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_ensure_action()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var phase := int(scene.get("phase"))
	if phase == 1 and _last_phase != 1:
		ordnance = StrikeOrdnanceRules.MAX_ORDNANCE
		_pending.clear()
	if phase == 1:
		_update_pending(scene, delta)
		if Input.is_action_just_pressed("drop_strike_ordnance"):
			_try_drop(scene)
	else:
		_pending.clear()
	_last_phase = phase
	_surface.queue_redraw()

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "player_position", "enemies", "score", "status_text", "status_timer"]:
		if not names.has(required):
			return false
	return true

func _try_drop(scene: Object) -> void:
	var form := _craft_value("current_form", "fighter")
	var altitude := _craft_value("current_altitude", "mid")
	if not StrikeOrdnanceRules.can_drop(form, altitude, ordnance, _cooldown):
		if form != "bomber":
			_set_status(scene, "STRIKE ORDNANCE REQUIRES BOMBER CONFIG")
		elif not StrikeOrdnanceRules.altitude_allowed(altitude):
			_set_status(scene, "STRIKE ORDNANCE TOO HIGH")
		elif ordnance <= 0:
			_set_status(scene, "STRIKE ORDNANCE EMPTY")
		return
	ordnance -= 1
	_cooldown = StrikeOrdnanceRules.DROP_COOLDOWN
	var point := StrikeOrdnanceRules.target_point(scene.get("player_position"), altitude)
	_pending.append({"position": point, "time": StrikeOrdnanceRules.IMPACT_DELAY, "altitude": altitude})
	_set_status(scene, "BOMB AWAY  %d LEFT" % ordnance)

func _update_pending(scene: Object, delta: float) -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var item: Dictionary = _pending[i]
		item["time"] = float(item.get("time", 0.0)) - delta
		_pending[i] = item
		if float(item["time"]) <= 0.0:
			_impact(scene, item)
			_pending.remove_at(i)

func _impact(scene: Object, item: Dictionary) -> void:
	var enemies: Array = scene.get("enemies")
	var point: Vector2 = item.get("position", Vector2.ZERO)
	var altitude := str(item.get("altitude", "low"))
	var radius_sq := pow(StrikeOrdnanceRules.blast_radius(altitude), 2)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		if position.distance_squared_to(point) > radius_sq:
			continue
		var is_boss := bool(enemy.get("boss", false))
		var enemy_class := str(enemy.get("category", "air"))
		var damage := StrikeOrdnanceRules.damage_for_target(enemy_class, is_boss, altitude)
		if damage <= 0:
			continue
		var hp := int(enemy.get("hp", 1))
		if is_boss:
			enemy["hp"] = maxi(1, hp - damage)
			enemies[i] = enemy
		elif hp - damage <= 0:
			if scene.has_method("_register_destroy"):
				scene.call("_register_destroy", enemy)
			scene.set("score", int(scene.get("score")) + int(enemy.get("value", 0)))
			enemies.remove_at(i)
		else:
			enemy["hp"] = hp - damage
			enemies[i] = enemy
	scene.set("enemies", enemies)
	_set_status(scene, "SURFACE IMPACT")

func rearm_full() -> void:
	ordnance = StrikeOrdnanceRules.MAX_ORDNANCE
	_cooldown = 0.0

func ordnance_count() -> int:
	return ordnance

func _craft_value(method_name: String, fallback: String) -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method(method_name):
		return str(director.call(method_name))
	return fallback

func _set_status(scene: Object, text: String) -> void:
	scene.set("status_text", text)
	scene.set("status_timer", 1.6)

func _draw_surface(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or int(scene.get("phase")) != 1:
		return
	var form := _craft_value("current_form", "fighter")
	var altitude := _craft_value("current_altitude", "mid")
	if form != "bomber" or not StrikeOrdnanceRules.altitude_allowed(altitude):
		return
	var target := StrikeOrdnanceRules.target_point(scene.get("player_position"), altitude)
	var radius := StrikeOrdnanceRules.blast_radius(altitude)
	surface.draw_arc(target, radius, 0.0, TAU, 20, Color(0.92, 0.74, 0.30, 0.55), 1.0)
	surface.draw_line(target + Vector2(-6, 0), target + Vector2(6, 0), Color(0.92, 0.74, 0.30, 0.75), 1.0)
	surface.draw_line(target + Vector2(0, -6), target + Vector2(0, 6), Color(0.92, 0.74, 0.30, 0.75), 1.0)
	PixelFont.draw_text(surface, "E BOMB %d" % ordnance, Vector2(18, 314), 1, Color(0.92, 0.74, 0.30, 0.92), 1)
	for item in _pending:
		var point: Vector2 = item.get("position", Vector2.ZERO)
		var t := clampf(float(item.get("time", 0.0)) / StrikeOrdnanceRules.IMPACT_DELAY, 0.0, 1.0)
		surface.draw_circle(point, 3.0 + 6.0 * (1.0 - t), Color(1.0, 0.48, 0.20, 0.7), false, 1.0)

func _ensure_action() -> void:
	if not InputMap.has_action("drop_strike_ordnance"):
		InputMap.add_action("drop_strike_ordnance")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	if not InputMap.action_has_event("drop_strike_ordnance", event):
		InputMap.action_add_event("drop_strike_ordnance", event)
