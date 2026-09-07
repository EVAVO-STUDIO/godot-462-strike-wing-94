extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const HUD_STABILITY_TROUGH := preload("res://assets/runtime/ui/hud/stability_trough.png")
const HUD_STABILITY_FILL := preload("res://assets/runtime/ui/hud/stability_fill.png")
const HUD_STRIKE_FRAME := preload("res://assets/runtime/ui/hud/lower_systems_dock/strike_frame.png")
const HUD_STRIKE_BOMB := preload("res://assets/runtime/ui/hud/lower_systems_dock/icon_bomb.png")
const HUD_STRIKE_LOCK := preload("res://assets/runtime/ui/hud/lower_systems_dock/icon_lock.png")
const HUD_STRIKE_ROUTE := preload("res://assets/runtime/ui/hud/lower_systems_dock/icon_route.png")
const HUD_STRIKE_SAFE := preload("res://assets/runtime/ui/hud/lower_systems_dock/icon_safe.png")
const HUD_STRIKE_STABLE := preload("res://assets/runtime/ui/hud/lower_systems_dock/icon_stable.png")
const AIM_LATTICE := preload("res://assets/runtime/ui/hud/strike_targeting/aim_lattice.png")
const BLAST_ENVELOPE := preload("res://assets/runtime/ui/hud/strike_targeting/blast_envelope.png")
const PRIORITY_FRAME := preload("res://assets/runtime/ui/hud/strike_targeting/priority_frame.png")
const IMPACT_MARKER := preload("res://assets/runtime/ui/hud/strike_targeting/impact_marker.png")
const GUIDANCE_RIBBON := preload("res://assets/runtime/ui/hud/strike_targeting/guidance_ribbon.png")

const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")
const PRECISION_BOMB_FRAMES := [
	preload("res://assets/runtime/effects/projectiles/precision_bomb/0.png"),
	preload("res://assets/runtime/effects/projectiles/precision_bomb/1.png"),
	preload("res://assets/runtime/effects/projectiles/precision_bomb/2.png"),
	preload("res://assets/runtime/effects/projectiles/precision_bomb/3.png")
]

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
	return SceneContractCache.supports(scene, ["phase", "player_position", "enemies", "score", "status_text", "status_timer"])

func _altitude_transition_active() -> bool:
	var craft := get_node_or_null("/root/CraftFormDirector")
	return craft != null and craft.has_method("altitude_transition_active") and bool(craft.call("altitude_transition_active"))

func shift_camera_projection(shift: Vector2) -> void:
	for collection in [_pending, _impact_fx]:
		for item in collection:
			item["position"] = Vector2(item.get("position", Vector2.ZERO)) + shift
			if item.has("release_position"):
				item["release_position"] = Vector2(item["release_position"]) + shift

func _strike_release_position(scene: Object) -> Vector2:
	var player: Vector2 = scene.get("player_position")
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("role_mount_offsets"):
		var projected = craft.call("role_mount_offsets", "precision_bomb")
		if typeof(projected) == TYPE_ARRAY and not projected.is_empty() and typeof(projected[0]) == TYPE_VECTOR2:
			return player + Vector2(projected[0])
	var mounts := get_node_or_null("/root/PlayerMountDirector")
	if mounts != null and mounts.has_method("role_offsets"):
		var offsets = mounts.call("role_offsets", "bomber", "precision_bomb")
		if typeof(offsets) == TYPE_ARRAY and not offsets.is_empty() and typeof(offsets[0]) == TYPE_VECTOR2:
			return player + Vector2(offsets[0])
	return player + Vector2(0, 8)

func _update_attack_run_stability(scene: Object, delta: float) -> void:
	var form := _craft_value("current_form", "fighter")
	var altitude := _craft_value("current_altitude", "mid")
	var enemies: Array = scene.get("enemies")
	var has_lock := StrikeOrdnanceRules.assisted_target_index(scene.get("player_position"), altitude, enemies) >= 0
	var lateral := Input.get_axis("move_left", "move_right")
	var stable_envelope := form == "bomber" and altitude == "low" and not _altitude_transition_active()
	_stability = StrikeOrdnanceRules.update_stability(
		_stability,
		delta,
		stable_envelope,
		has_lock,
		lateral
	)

func _try_drop(scene: Object) -> void:
	if _altitude_transition_active():
		_set_status(scene, "ORDNANCE SAFE - ALTITUDE TRANSITION")
		return
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
		"release_position": _strike_release_position(scene),
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
	var hit_sea := false
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		if position.distance_squared_to(point) > radius_sq:
			continue
		var is_boss := bool(enemy.get("boss", false))
		var enemy_class := str(enemy.get("category", "air"))
		if enemy_class == "sea": hit_sea = true
		var damage := StrikeOrdnanceRules.damage_for_target(enemy_class, is_boss, altitude)
		if damage <= 0:
			continue
		var hp := int(enemy.get("hp", 1))
		if is_boss:
			enemy["hp"] = maxi(1, hp - damage)
			enemies[i] = enemy
		elif hp - damage <= 0:
			enemy["last_impact_family"] = "bomb"
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
	var collateral_losses := 0
	if scene.has_method("_apply_bomb_collateral"):
		collateral_losses = int(scene.call("_apply_bomb_collateral", point, StrikeOrdnanceRules.blast_radius(altitude)))
	_emit_impact_fx(point, altitude, bool(item.get("priority_lock", false)), float(item.get("stability", 0.0)), _impact_family(scene, hit_sea))
	_play_impact_sfx()
	if collateral_losses > 0:
		pass
	elif precision_bonus > 0:
		_set_status(scene, "PRECISION ROUTE HIT  +%d" % precision_bonus)
	else:
		_set_status(scene, "SURFACE IMPACT")

func _emit_impact_fx(point: Vector2, altitude: String, priority: bool, stability: float, family: String = "bomb_impact") -> void:
	_impact_serial += 1
	_impact_fx.append({
		"position": point,
		"age": 0.0,
		"duration": IMPACT_FX_SECONDS,
		"altitude": altitude,
		"priority": priority,
		"stability": clampf(stability, 0.0, 1.0),
		"family": family,
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
	var stable := altitude == "low" and _stability >= 0.95 and not _altitude_transition_active()
	var reticle := Color(0.42, 0.96, 0.62, 0.92) if priority else (Color(0.38, 0.86, 0.70, 0.72) if assisted else Color(0.92, 0.74, 0.30, 0.55))
	if stable:
		reticle = Color(0.72, 1.0, 0.82, 0.98)
	if assisted:
		_draw_effect_between(surface, GUIDANCE_RIBBON, projected, target, 4.0, Color(1,1,1,0.38))
	# Keep the simulation radius authoritative while presenting a tighter 1990s
	# strike sight that does not cover the target or nearby ground detail.
	var aim_size := Vector2.ONE * aim_radius * 0.92
	var blast_size := Vector2.ONE * blast_radius * 0.96
	surface.draw_texture_rect(AIM_LATTICE, Rect2(target - aim_size * 0.5, aim_size), false, Color(1,1,1,reticle.a))
	surface.draw_texture_rect(BLAST_ENVELOPE, Rect2(target - blast_size * 0.5, blast_size), false)
	if priority:
		surface.draw_texture(PRIORITY_FRAME, (target - Vector2(16,16)).round())
		PixelFont.draw_text(surface, "ROUTE TARGET", target + Vector2(-24, 15), 1, reticle, 1)
	_draw_strike_status(surface, altitude, assisted, priority, stable)
	for item in _pending:
		var point: Vector2 = item.get("position", Vector2.ZERO)
		var release: Vector2 = item.get("release_position", scene.get("player_position"))
		var initial_time := maxf(0.001, float(item.get("initial_time", StrikeOrdnanceRules.impact_delay(str(item.get("altitude", "low"))))))
		var remaining := clampf(float(item.get("time", 0.0)) / initial_time, 0.0, 1.0)
		var progress := 1.0 - remaining
		var travel := smoothstep(0.0, 1.0, progress)
		var bomb_position := release.lerp(point, travel)
		var bomb_scale := lerpf(1.0, 0.45, travel)
		var color := Color(0.42, 0.96, 0.62, 0.78) if bool(item.get("priority_lock", false)) else Color(1.0, 0.48, 0.20, 0.7)
		var marker_size := Vector2.ONE * (18.0 + 14.0 * progress)
		surface.draw_texture_rect(IMPACT_MARKER, Rect2(point - marker_size * 0.5, marker_size), false, color)
		_draw_effect_between(surface, GUIDANCE_RIBBON, release, point, 3.0, Color(color.r,color.g,color.b,0.18))
		var bomb_frame_index := int(floor(progress * 10.0)) % PRECISION_BOMB_FRAMES.size()
		var bomb_texture: Texture2D = PRECISION_BOMB_FRAMES[bomb_frame_index]
		var bomb_size := (bomb_texture.get_size() * bomb_scale).round()
		surface.draw_texture_rect(bomb_texture, Rect2((bomb_position - Vector2(8, 7) * bomb_scale).round(), bomb_size), false)

func _draw_strike_status(surface: CanvasItem, altitude: String, assisted: bool, priority: bool, stable: bool) -> void:
	var transition_active := _altitude_transition_active()
	var stability_pct := int(round(_stability * 100.0))
	surface.draw_texture(HUD_STRIKE_FRAME, Vector2(14, 298))
	surface.draw_texture(HUD_STRIKE_BOMB, Vector2(18, 300))
	PixelFont.draw_text(surface, "%d" % ordnance, Vector2(32, 302), 1, Color(0.92, 0.74, 0.30, 0.92), 1)
	PixelFont.draw_text(surface, "LOW" if altitude == "low" else "MID", Vector2(47, 302), 1, Color(0.92, 0.74, 0.30, 0.92), 1)
	if assisted:
		surface.draw_texture(HUD_STRIKE_LOCK, Vector2(72, 300))
	if priority:
		surface.draw_texture(HUD_STRIKE_ROUTE, Vector2(90, 300))
	if transition_active:
		surface.draw_texture(HUD_STRIKE_SAFE, Vector2(108, 300))
	elif stable:
		surface.draw_texture(HUD_STRIKE_STABLE, Vector2(108, 300))
	PixelFont.draw_text(surface, "STB%03d" % stability_pct, Vector2(124, 302), 1, Color(0.72, 0.88, 0.80, 0.94), 1)
	surface.draw_texture(HUD_STABILITY_TROUGH, Vector2(151, 303))
	var stability_width := roundf(float(HUD_STABILITY_FILL.get_width()) * _stability)
	if stability_width > 0.0:
		surface.draw_texture_rect_region(HUD_STABILITY_FILL,Rect2(Vector2(152,304),Vector2(stability_width,HUD_STABILITY_FILL.get_height())),Rect2(0,0,stability_width,HUD_STABILITY_FILL.get_height()))

func _draw_effect_between(surface: CanvasItem, texture: Texture2D, start: Vector2, finish: Vector2, height: float, tint: Color = Color.WHITE) -> void:
	var delta := finish - start
	if delta.length() < 1.0:
		return
	surface.draw_set_transform(start, delta.angle(), Vector2(delta.length() / texture.get_width(), height / texture.get_height()))
	surface.draw_texture(texture, Vector2(0, -texture.get_height() * 0.5), tint)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_impact_fx(surface: CanvasItem) -> void:
	for fx in _impact_fx:
		if typeof(fx) != TYPE_DICTIONARY:
			continue
		var duration := maxf(0.001, float(fx.get("duration", IMPACT_FX_SECONDS)))
		var ratio := clampf(float(fx.get("age", 0.0)) / duration, 0.0, 1.0)
		var p: Vector2 = fx.get("position", Vector2.ZERO)
		var stability := clampf(float(fx.get("stability", 0.0)), 0.0, 1.0)
		var texture := ImpactArtLibrary.frame_for_ratio(str(fx.get("family", "bomb_impact")), ratio)
		var draw_size := roundf(42.0 + stability * 8.0)
		surface.draw_texture_rect(texture, Rect2((p - Vector2.ONE * draw_size * 0.5).round(), Vector2.ONE * draw_size), false)

func _impact_family(scene: Object, hit_sea: bool) -> String:
	if hit_sea:
		return "water_impact"
	var environment := str(scene.get("current_environment")) if _has_property(scene, "current_environment") else ""
	if environment in ["storm_sea", "open_water", "river", "night_harbor"]:
		return "water_impact"
	if environment in ["desert", "mountain"]:
		return "dust_impact"
	return "bomb_impact"

func _has_property(subject: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(subject, property_name)

func _ensure_action() -> void:
	if not InputMap.has_action("drop_strike_ordnance"):
		InputMap.add_action("drop_strike_ordnance")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	if not InputMap.action_has_event("drop_strike_ordnance", event):
		InputMap.action_add_event("drop_strike_ordnance", event)
