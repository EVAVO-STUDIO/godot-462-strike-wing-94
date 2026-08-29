extends CanvasLayer

const StrikeOrdnanceRules = preload("res://scripts/strike_ordnance_rules.gd")
const StrikeOrdnanceSurface = preload("res://scripts/strike_ordnance_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")

const IMPACT_FX_SECONDS := 0.30

var ordnance := StrikeOrdnanceRules.MAX_ORDNANCE
var _cooldown := 0.0
var _pending: Array = []
var _impact_fx: Array = []
var _surface: Control
var _last_phase := -1
var _stability := 0.0
var _impact_serial := 0

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
	_update_impact_fx(delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var phase := int(scene.get("phase"))
	if phase == 1 and _last_phase != 1:
		ordnance = StrikeOrdnanceRules.MAX_ORDNANCE
		_pending.clear()
		_impact_fx.clear()
		_stability = 0.0
	if phase == 1:
		_update_attack_run_stability(scene, delta)
		_update_pending(scene, delta)
		if Input.is_action_just_pressed("drop_strike_ordnance"):
			_try_drop(scene)
	else:
		_pending.clear()
		_impact_fx.clear()
		_stability = 0.0
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

func _update_attack_run_stability(scene: Object, delta: float) -> void:
	var form := _craft_value("current_form", "fighter")
	var altitude := _craft_value("current_altitude", "mid")
	var enemies: Array = scene.get("enemies")
	var has_lock := StrikeOrdnanceRules.assisted_target_index(scene.get("player_position"), altitude, enemies) >= 0
	var lateral := Input.get_axis("move_left", "move_right")
	_stability = StrikeOrdnanceRules.update_stability(
		_stability,
		delta,
		form == "bomber" and altitude == "low",
		has_lock,
		lateral
	)

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
	var enemies: Array = scene.get("enemies")
	var point := StrikeOrdnanceRules.assisted_target_point(scene.get("player_position"), altitude, enemies)
	var delay := StrikeOrdnanceRules.stabilized_impact_delay(altitude, _stability)
	_pending.append({
		"position": point,
		"time": delay,
		"initial_time": delay,
		"altitude": altitude,
		"stability": _stability,
		"priority_lock": StrikeOrdnanceRules.priority_target_at_point(point, enemies)
	})
	var lock_text := "  ROUTE LOCK" if bool(_pending[_pending.size()-1].get("priority_lock", false)) else ""
	var stable_text := "  STABLE" if _stability >= 0.95 and altitude == "low" else ""
	_set_status(scene, "%s - BOMB AWAY  %d LEFT%s%s" % [StrikeOrdnanceRules.delivery_quality(altitude), ordnance, lock_text, stable_text])

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
	var precision_bonus := 0
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
			precision_bonus += StrikeOrdnanceRules.route_precision_score(enemy, true)
			scene.set("score", int(scene.get("score")) + int(enemy.get("value", 0)))
			enemies.remove_at(i)
		else:
			enemy["hp"] = hp - damage
			enemies[i] = enemy
	if precision_bonus > 0:
		scene.set("score", int(scene.get("score")) + precision_bonus)
	scene.set("enemies", enemies)
	_emit_impact_fx(point, altitude, bool(item.get("priority_lock", false)), float(item.get("stability", 0.0)))
	_play_impact_sfx()
	if precision_bonus > 0:
		_set_status(scene, "PRECISION ROUTE HIT  +%d" % precision_bonus)
	else:
		_set_status(scene, "SURFACE IMPACT")

func _emit_impact_fx(point: Vector2, altitude: String, priority: bool, stability: float) -> void:
	_impact_serial += 1
	_impact_fx.append({
		"position": point,
		"age": 0.0,
		"duration": IMPACT_FX_SECONDS,
		"altitude": altitude,
		"priority": priority,
		"stability": clampf(stability, 0.0, 1.0),
		"serial": _impact_serial
	})
	while _impact_fx.size() > 8:
		_impact_fx.pop_front()

func _update_impact_fx(delta: float) -> void:
	for i in range(_impact_fx.size() - 1, -1, -1):
		var fx: Dictionary = _impact_fx[i]
		fx["age"] = float(fx.get("age", 0.0)) + maxf(0.0, delta)
		if float(fx["age"]) >= float(fx.get("duration", IMPACT_FX_SECONDS)):
			_impact_fx.remove_at(i)
		else:
			_impact_fx[i] = fx

func _play_impact_sfx() -> void:
	var sfx := get_node_or_null("/root/RetroSfxDirector")
	if sfx != null and sfx.has_method("play_event"):
		sfx.call("play_event", RetroSfxRules.STRIKE_IMPACT)

func rearm_full() -> void:
	ordnance = StrikeOrdnanceRules.MAX_ORDNANCE
	_cooldown = 0.0
	_stability = 0.0

func ordnance_count() -> int:
	return ordnance

func attack_run_stability() -> float:
	return _stability

func _craft_value(method_name: String, fallback: String) -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method(method_name):
		return str(director.call(method_name))
	return fallback

func _set_status(scene: Object, text: String) -> void:
	scene.set("status_text", text)
	scene.set("status_timer", 1.6)

func _draw_surface(surface: CanvasItem) -> void:
	_draw_impact_fx(surface)
	var scene := get_tree().current_scene
	if scene == null or int(scene.get("phase")) != 1:
		return
	var form := _craft_value("current_form", "fighter")
	var altitude := _craft_value("current_altitude", "mid")
	if form != "bomber" or not StrikeOrdnanceRules.altitude_allowed(altitude):
		return
	var enemies: Array = scene.get("enemies")
	var projected := StrikeOrdnanceRules.target_point(scene.get("player_position"), altitude)
	var target_index := StrikeOrdnanceRules.assisted_target_index(scene.get("player_position"), altitude, enemies)
	var target := StrikeOrdnanceRules.assisted_target_point(scene.get("player_position"), altitude, enemies)
	var assisted := target.distance_squared_to(projected) > 0.5
	var priority := target_index >= 0 and target_index < enemies.size() and typeof(enemies[target_index]) == TYPE_DICTIONARY and bool(enemies[target_index].get("strike_priority", false))
	var aim_radius := StrikeOrdnanceRules.stabilized_aim_radius(altitude, _stability)
	var blast_radius := StrikeOrdnanceRules.blast_radius(altitude)
	var stable := altitude == "low" and _stability >= 0.95
	var reticle := Color(0.42, 0.96, 0.62, 0.92) if priority else (Color(0.38, 0.86, 0.70, 0.72) if assisted else Color(0.92, 0.74, 0.30, 0.55))
	if stable:
		reticle = Color(0.72, 1.0, 0.82, 0.98)
	if assisted:
		surface.draw_line(projected, target, Color(reticle.r, reticle.g, reticle.b, 0.35), 1.0)
	surface.draw_arc(target, aim_radius, 0.0, TAU, 20, reticle, 1.0)
	surface.draw_arc(target, blast_radius, 0.0, TAU, 20, Color(0.92, 0.44, 0.22, 0.24), 1.0)
	surface.draw_line(target + Vector2(-6, 0), target + Vector2(6, 0), reticle, 1.0)
	surface.draw_line(target + Vector2(0, -6), target + Vector2(0, 6), reticle, 1.0)
	if priority:
		surface.draw_rect(Rect2(roundf(target.x)-11, roundf(target.y)-11, 22, 22), reticle, false, 1.0)
		PixelFont.draw_text(surface, "ROUTE TARGET", target + Vector2(-24, 15), 1, reticle, 1)
	var stability_pct := int(round(_stability * 100.0))
	PixelFont.draw_text(
		surface,
		"E BOMB %d  %s%s%s  STB%03d" % [ordnance, "LOW" if altitude == "low" else "MID", " LOCK" if assisted else "", " ROUTE" if priority else "", stability_pct],
		Vector2(18, 314),
		1,
		Color(0.92, 0.74, 0.30, 0.92),
		1
	)
	if altitude == "low" and target_index >= 0:
		var bar_width := 48.0
		surface.draw_rect(Rect2(18, 325, bar_width, 3), Color(0.12,0.18,0.20,0.82))
		surface.draw_rect(Rect2(18, 325, roundf(bar_width * _stability), 3), Color(0.42,0.86,0.64,0.92))
	for item in _pending:
		var point: Vector2 = item.get("position", Vector2.ZERO)
		var initial_time := maxf(0.001, float(item.get("initial_time", StrikeOrdnanceRules.impact_delay(str(item.get("altitude", "low"))))))
		var t := clampf(float(item.get("time", 0.0)) / initial_time, 0.0, 1.0)
		var pulse := 3.0 + 7.0 * (1.0 - t)
		var color := Color(0.42, 0.96, 0.62, 0.78) if bool(item.get("priority_lock", false)) else Color(1.0, 0.48, 0.20, 0.7)
		surface.draw_circle(point, pulse, color, false, 1.0)

func _draw_impact_fx(surface: CanvasItem) -> void:
	for fx in _impact_fx:
		if typeof(fx) != TYPE_DICTIONARY:
			continue
		var duration := maxf(0.001, float(fx.get("duration", IMPACT_FX_SECONDS)))
		var ratio := clampf(float(fx.get("age", 0.0)) / duration, 0.0, 1.0)
		var p: Vector2 = fx.get("position", Vector2.ZERO)
		var priority := bool(fx.get("priority", false))
		var stability := clampf(float(fx.get("stability", 0.0)), 0.0, 1.0)
		var fade := 1.0 - ratio
		var radius := 5.0 + ratio * (34.0 + stability * 8.0)
		var shock := Color(0.96,0.56,0.20,0.78 * fade)
		var hot := Color(1.0,0.90,0.48,0.88 * fade)
		if priority:
			shock = Color(0.46,0.96,0.62,0.76 * fade)
		surface.draw_arc(p, radius, 0.0, TAU, 20, shock, 2.0)
		if ratio < 0.42:
			surface.draw_circle(p, maxf(2.0, radius * 0.28), hot)
		var serial := int(fx.get("serial", 0))
		for i in range(7):
			var angle := float((serial * 43 + i * 67) % 360) * PI / 180.0
			var distance := radius * (0.35 + float((serial + i) % 5) * 0.12)
			var q := p + Vector2.RIGHT.rotated(angle) * distance
			surface.draw_rect(Rect2(roundf(q.x), roundf(q.y), 2, 2), shock)

func _ensure_action() -> void:
	if not InputMap.has_action("drop_strike_ordnance"):
		InputMap.add_action("drop_strike_ordnance")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	if not InputMap.action_has_event("drop_strike_ordnance", event):
		InputMap.action_add_event("drop_strike_ordnance", event)
