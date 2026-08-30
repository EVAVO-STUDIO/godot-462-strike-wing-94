extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const BattlefieldSupportRules = preload("res://scripts/battlefield_support_rules.gd")
const BattlefieldSupportSurface = preload("res://scripts/battlefield_support_surface.gd")
const BattlefieldSupportArtLibrary = preload("res://scripts/battlefield_support_art_library.gd")

var _catalog: Array = []
var _allowed_ids: Array[String] = []
var _selected_index := 0
var _cooldowns: Dictionary = {}
var _last_mission_index := -1
var _active_id := ""
var _active_timer := 0.0
var _tanker_position := Vector2(320, 82)
var _tanker_progress := 0.0
var _tanker_rewarded := false
var _visual_id := ""
var _visual_type := ""
var _visual_timer := 0.0
var _visual_target := Vector2(320, 150)
var _animation_clock := 0.0
var _surface: Control

func _ready() -> void:
	layer = 18
	process_priority = -4
	var data = ContentCatalog.load_json("res://data/battlefield_support.json")
	if typeof(data) == TYPE_DICTIONARY:
		_catalog = data.get("supports", [])
	_surface = BattlefieldSupportSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_ensure_actions()

func _process(delta: float) -> void:
	_animation_clock += delta
	_tick_cooldowns(delta)
	_visual_timer = maxf(0.0, _visual_timer - delta)
	if _visual_timer <= 0.0:
		_clear_visual()
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		_clear_active()
		_clear_visual()
		_queue_surface()
		return
	var mission_index := int(scene.get("mission_index"))
	if mission_index != _last_mission_index:
		_last_mission_index = mission_index
		_refresh_allowed()
		_clear_active()
		_clear_visual()
	if int(scene.get("phase")) == 0:
		if Input.is_action_just_pressed("cycle_battlefield_support"):
			_cycle(scene)
	elif int(scene.get("phase")) == 1:
		if Input.is_action_just_pressed("call_battlefield_support"):
			_call_selected(scene)
		_update_active(scene, delta)
	else:
		_clear_active()
		_clear_visual()
	_queue_surface()

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "mission_index", "player_position", "energy", "bombs", "hull", "shield", "enemies", "score", "status_text", "status_timer"]:
		if not names.has(required):
			return false
	return true

func _refresh_allowed() -> void:
	_allowed_ids.clear()
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("mission_context"):
		var context = craft.call("mission_context")
		if typeof(context) == TYPE_DICTIONARY:
			_allowed_ids = BattlefieldSupportRules.allowed_ids(context)
	_selected_index = clampi(_selected_index, 0, maxi(0, _allowed_ids.size() - 1))

func current_support_id() -> String:
	if _allowed_ids.is_empty():
		return ""
	return _allowed_ids[clampi(_selected_index, 0, _allowed_ids.size() - 1)]

func current_support_name() -> String:
	return str(BattlefieldSupportRules.support_for_id(_catalog, current_support_id()).get("name", "NO BATTLEFIELD SUPPORT"))

func cooldown_remaining() -> float:
	return maxf(0.0, float(_cooldowns.get(current_support_id(), 0.0)))

func readiness_ratio() -> float:
	var support := BattlefieldSupportRules.support_for_id(_catalog, current_support_id())
	if support.is_empty() or _active_id != "":
		return 0.0
	var duration := maxf(1.0, float(support.get("cooldown_seconds", 60.0)))
	return clampf(1.0 - cooldown_remaining() / duration, 0.0, 1.0)

func support_available() -> bool:
	var support := BattlefieldSupportRules.support_for_id(_catalog, current_support_id())
	return not support.is_empty() and _active_id == "" and BattlefieldSupportRules.altitude_allowed(support, _current_altitude())

func _cycle(scene: Object) -> void:
	if _allowed_ids.is_empty():
		_set_status(scene, "NO BATTLEFIELD SUPPORT ASSIGNED")
		return
	_selected_index = BattlefieldSupportRules.cycle_index(_selected_index, _allowed_ids.size())
	_set_status(scene, "BATTLEFIELD SUPPORT - %s" % current_support_name().to_upper())

func _call_selected(scene: Object) -> void:
	if _active_id != "":
		_set_status(scene, "SUPPORT ALREADY ACTIVE")
		return
	var id := current_support_id()
	var support := BattlefieldSupportRules.support_for_id(_catalog, id)
	if support.is_empty():
		_set_status(scene, "NO BATTLEFIELD SUPPORT ASSIGNED")
		return
	var altitude := _current_altitude()
	if not BattlefieldSupportRules.altitude_allowed(support, altitude):
		_set_status(scene, "SUPPORT UNAVAILABLE AT THIS ALTITUDE")
		return
	if float(_cooldowns.get(id, 0.0)) > 0.0:
		_set_status(scene, "%s RECHARGING %d" % [str(support.get("name", "SUPPORT")).to_upper(), int(ceil(float(_cooldowns[id])))])
		return
	var type := str(support.get("type", ""))
	if type == "tanker_rearm":
		_active_id = id
		_active_timer = maxf(1.0, float(support.get("duration_seconds", 12.0)))
		_tanker_progress = 0.0
		_tanker_rewarded = false
		_set_status(scene, "ATLAS TANKER INBOUND - MATCH HOSE")
		return
	_begin_visual(scene, id, type)
	_apply_immediate_support(scene, support)
	_cooldowns[id] = maxf(1.0, float(support.get("cooldown_seconds", 60.0)))

func _begin_visual(scene: Object, id: String, type: String) -> void:
	_visual_id = id
	_visual_type = type
	_visual_timer = 1.25
	_visual_target = _priority_target_position(scene)

func _priority_target_position(scene: Object) -> Vector2:
	var enemies: Array = scene.get("enemies")
	var best_hp := -1
	var best := Vector2(320, 150)
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var hp := int(enemy.get("hp", 0))
		if hp > best_hp:
			best_hp = hp
			best = enemy.get("position", best)
	return best

func _apply_immediate_support(scene: Object, support: Dictionary) -> void:
	var type := str(support.get("type", ""))
	match type:
		"fighter_squadron":
			_damage_targets(scene, 7, 5, ["air", "boss"], "RAPIER FLIGHT - AIR SWEEP")
		"bomber_squadron":
			_damage_targets(scene, 14, 5, ["ground", "sea"], "HAMMER FLIGHT - STRIKE RUN")
		"loitering_gunship":
			_damage_targets(scene, 9, 7, ["ground", "sea"], "SPECTRE GUNSHIP - FIRE MISSION")
		"precision_missile":
			_damage_priority_target(scene, 38, "CRUISE MISSILE - IMPACT")
		"rail_strike":
			_damage_priority_target(scene, 64, "LONGSHOT RAIL - IMPACT")
		"orbital_bombardment":
			_damage_targets(scene, 24, 10, ["air", "ground", "sea", "boss"], "ORBITAL STRIKE - IMPACT")
		_:
			_set_status(scene, "SUPPORT LINK INVALID")

func _damage_targets(scene: Object, damage: int, max_targets: int, classes: Array, label: String) -> void:
	var enemies: Array = scene.get("enemies")
	var hit_count := 0
	for i in range(enemies.size() - 1, -1, -1):
		if hit_count >= max_targets:
			break
		var enemy: Dictionary = enemies[i]
		var category := "boss" if bool(enemy.get("boss", false)) else str(enemy.get("category", "air"))
		if category not in classes:
			continue
		var hp := int(enemy.get("hp", 1))
		var applied := damage
		if bool(enemy.get("boss", false)):
			applied = mini(applied, maxi(0, hp - 1))
		enemy["hp"] = hp - applied
		hit_count += 1
		if int(enemy["hp"]) <= 0:
			_register_support_destroy(scene, enemy)
			enemies.remove_at(i)
		else:
			enemies[i] = enemy
	scene.set("enemies", enemies)
	_set_status(scene, "%s  TARGETS %d" % [label, hit_count])

func _damage_priority_target(scene: Object, damage: int, label: String) -> void:
	var enemies: Array = scene.get("enemies")
	var best_index := -1
	var best_hp := -1
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var hp := int(enemy.get("hp", 0))
		if hp > best_hp:
			best_hp = hp
			best_index = i
	if best_index < 0:
		_set_status(scene, "SUPPORT - NO TARGET")
		return
	var target: Dictionary = enemies[best_index]
	var hp := int(target.get("hp", 1))
	var applied := damage
	if bool(target.get("boss", false)):
		applied = mini(applied, maxi(0, hp - 1))
	target["hp"] = hp - applied
	if int(target["hp"]) <= 0:
		_register_support_destroy(scene, target)
		enemies.remove_at(best_index)
	else:
		enemies[best_index] = target
	scene.set("enemies", enemies)
	_set_status(scene, label)

func _register_support_destroy(scene: Object, enemy: Dictionary) -> void:
	if scene.has_method("_register_destroy"):
		scene.call("_register_destroy", enemy)
	scene.set("score", int(scene.get("score")) + int(enemy.get("value", 0)))

func _update_active(scene: Object, delta: float) -> void:
	if _active_id == "":
		return
	_active_timer = maxf(0.0, _active_timer - delta)
	if _active_id == "atlas_tanker":
		_update_tanker(scene, delta)
	if _active_timer <= 0.0:
		_finish_active(scene)

func _update_tanker(scene: Object, delta: float) -> void:
	var connected := BattlefieldSupportRules.tanker_connected(scene.get("player_position"), _tanker_position)
	_tanker_progress = BattlefieldSupportRules.tanker_progress(_tanker_progress, connected, delta)
	if connected:
		var max_energy := _max_energy(scene)
		scene.set("energy", BattlefieldSupportRules.tanker_restore(float(scene.get("energy")), max_energy, BattlefieldSupportRules.TANKER_ENERGY_PER_SECOND, delta))
		scene.set("shield", int(round(BattlefieldSupportRules.tanker_restore(float(scene.get("shield")), float(_scene_max(scene, "_max_shield", 100)), BattlefieldSupportRules.TANKER_SHIELD_PER_SECOND, delta))))
		scene.set("hull", int(round(BattlefieldSupportRules.tanker_restore(float(scene.get("hull")), float(_scene_max(scene, "_max_hull", 100)), BattlefieldSupportRules.TANKER_HULL_PER_SECOND, delta))))
		_set_status(scene, "TANKER CONNECTED %d%%" % int(round(_tanker_progress / BattlefieldSupportRules.TANKER_REQUIRED_SECONDS * 100.0)), 0.25)
	if BattlefieldSupportRules.tanker_complete(_tanker_progress) and not _tanker_rewarded:
		_tanker_rewarded = true
		scene.set("bombs", mini(5, int(scene.get("bombs")) + 2))
		var support_director := get_node_or_null("/root/SupportDirector")
		if support_director != null and support_director.has_method("rearm_support"):
			support_director.call("rearm_support")
		_set_status(scene, "TANKER REARM COMPLETE")

func _finish_active(scene: Object) -> void:
	var support := BattlefieldSupportRules.support_for_id(_catalog, _active_id)
	if not support.is_empty():
		_cooldowns[_active_id] = maxf(1.0, float(support.get("cooldown_seconds", 60.0)))
	if _active_id == "atlas_tanker" and not _tanker_rewarded:
		_set_status(scene, "TANKER WINDOW MISSED")
	_clear_active()

func _clear_active() -> void:
	_active_id = ""
	_active_timer = 0.0
	_tanker_progress = 0.0
	_tanker_rewarded = false

func _clear_visual() -> void:
	_visual_id = ""
	_visual_type = ""
	_visual_timer = 0.0

func _tick_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)

func _current_altitude() -> String:
	var craft := get_node_or_null("/root/CraftFormDirector")
	if craft != null and craft.has_method("current_altitude"):
		return str(craft.call("current_altitude"))
	return "mid"

func _max_energy(scene: Object) -> float:
	if scene.has_method("_active_generator"):
		var generator = scene.call("_active_generator")
		if typeof(generator) == TYPE_DICTIONARY:
			return maxf(1.0, float(generator.get("capacity", 100.0)))
	return 100.0

func _scene_max(scene: Object, method_name: String, fallback: int) -> int:
	return int(scene.call(method_name)) if scene.has_method(method_name) else fallback

func _set_status(scene: Object, text: String, duration: float = 1.8) -> void:
	scene.set("status_text", text)
	scene.set("status_timer", duration)

func _queue_surface() -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_support_surface(surface: CanvasItem) -> void:
	if _active_id == "atlas_tanker":
		_draw_tanker(surface)
	if _visual_timer <= 0.0:
		return
	var progress := clampf(1.0 - (_visual_timer / 1.25), 0.0, 1.0)
	match _visual_type:
		"fighter_squadron": _draw_fighter_sweep(surface, progress)
		"bomber_squadron": _draw_bomber_run(surface, progress)
		"loitering_gunship": _draw_gunship_fire(surface, progress)
		"precision_missile": _draw_missile_strike(surface, progress)
		"rail_strike": _draw_rail_strike(surface, progress)
		"orbital_bombardment": _draw_orbital_strike(surface, progress)

func _draw_tanker(surface: CanvasItem) -> void:
	var p := _tanker_position
	_draw_support_craft(surface, p, "atlas_tanker", 6.0)
	var hose_point := BattlefieldSupportRules.tanker_hose_point(p)
	var hose := BattlefieldSupportArtLibrary.effect("tanker_hose")
	var contact := BattlefieldSupportArtLibrary.effect("tanker_contact")
	surface.draw_texture(hose, (p + Vector2(-32, 8)).round())
	surface.draw_texture(contact, (hose_point - contact.get_size() * 0.5).round())
	var ratio := clampf(_tanker_progress / BattlefieldSupportRules.TANKER_REQUIRED_SECONDS, 0.0, 1.0)
	surface.draw_texture(BattlefieldSupportArtLibrary.effect("tanker_meter_trough"), (p + Vector2(-40, 29)).round())
	_draw_clipped_effect(surface, BattlefieldSupportArtLibrary.effect("tanker_meter_fill"), (p + Vector2(-40, 30)).round(), ratio)

func _draw_fighter_sweep(surface: CanvasItem, progress: float) -> void:
	for i in range(3):
		var x := -40.0 + progress * 760.0 + float(i) * 52.0
		var y := 112.0 + float(i) * 24.0
		var p := Vector2(x, y)
		_draw_support_craft(surface, p, "rapier_fighter", 11.0 + float(i))

func _draw_bomber_run(surface: CanvasItem, progress: float) -> void:
	for i in range(3):
		var x := 700.0 - progress * 820.0 - float(i) * 64.0
		var y := 92.0 + float(i) * 20.0
		var p := Vector2(x, y)
		_draw_support_craft(surface, p, "hammer_bomber", 7.0 + float(i))
		if progress > 0.35:
			var bomb := BattlefieldSupportArtLibrary.effect("strike_bomb")
			surface.draw_texture(bomb, (p + Vector2(-8, 8 + 24.0 * (progress - 0.35))).round())

func _draw_gunship_fire(surface: CanvasItem, progress: float) -> void:
	var p := Vector2(552, 118 + sin(progress * PI) * 8.0)
	_draw_support_craft(surface, p, "spectre_gunship", 6.0)
	for offset in [-12.0, 0.0, 12.0]:
		_draw_effect_between(surface, BattlefieldSupportArtLibrary.effect("tracer"), p+Vector2(-31,18+offset*0.2), _visual_target+Vector2(offset,0), 4.0)

func _draw_support_craft(surface: CanvasItem, position: Vector2, family: String, fps: float) -> void:
	var texture := BattlefieldSupportArtLibrary.frame_for_clock(family, _animation_clock, fps)
	if texture != null:
		surface.draw_texture(texture, (position - texture.get_size() * 0.5).round())

func _draw_missile_strike(surface: CanvasItem, progress: float) -> void:
	var start := Vector2(80, 330)
	var p := start.lerp(_visual_target, progress)
	var trail_start := start.lerp(_visual_target, maxf(0.0, progress-0.18))
	_draw_effect_between(surface, BattlefieldSupportArtLibrary.effect("tracer"), trail_start, p, 5.0)
	var bomb := BattlefieldSupportArtLibrary.effect("strike_bomb")
	_draw_rotated_effect(surface, bomb, p, (_visual_target - start).angle() + PI * 0.5)
	if progress > 0.86:
		var impact := BattlefieldSupportArtLibrary.staged_effect("impact", (progress - 0.86) / 0.14)
		surface.draw_texture(impact, (_visual_target - impact.get_size() * 0.5).round())

func _draw_rail_strike(surface: CanvasItem, progress: float) -> void:
	var charge := clampf(progress / 0.38, 0.0, 1.0)
	if progress < 0.38:
		var charge_frame := BattlefieldSupportArtLibrary.staged_effect("rail_charge", charge)
		surface.draw_texture(charge_frame, (_visual_target - charge_frame.get_size() * 0.5).round())
		return
	var fade := 1.0 - clampf((progress-0.38)/0.62,0.0,1.0)
	var beam := BattlefieldSupportArtLibrary.effect("rail_beam")
	surface.draw_texture_rect(beam, Rect2(_visual_target.x - 6, 0, 12, 360), false, Color(1,1,1,fade))
	var impact := BattlefieldSupportArtLibrary.staged_effect("impact", clampf((progress - 0.38) / 0.62, 0.0, 1.0))
	surface.draw_texture(impact, (_visual_target - impact.get_size() * 0.5).round(), Color(1,1,1,fade))

func _draw_orbital_strike(surface: CanvasItem, progress: float) -> void:
	var fade := 1.0 - progress
	for x in [130.0, 240.0, 350.0, 460.0, 540.0]:
		var bottom := Vector2(x + sin(x)*8.0, 300)
		var beam := BattlefieldSupportArtLibrary.effect("orbital_beam")
		surface.draw_texture_rect(beam, Rect2(bottom.x - 6, 0, 12, bottom.y), false, Color(1,1,1,0.35+fade*0.65))
		if progress > 0.55:
			var impact := BattlefieldSupportArtLibrary.effect("orbital_impact")
			surface.draw_texture(impact, (bottom - impact.get_size() * 0.5).round(), Color(1,1,1,fade))

func _draw_clipped_effect(surface: CanvasItem, texture: Texture2D, position: Vector2, ratio: float) -> void:
	var width := floorf(float(texture.get_width()) * clampf(ratio, 0.0, 1.0))
	if width > 0.0:
		surface.draw_texture_rect_region(texture, Rect2(position, Vector2(width, texture.get_height())), Rect2(0, 0, width, texture.get_height()))

func _draw_effect_between(surface: CanvasItem, texture: Texture2D, start: Vector2, finish: Vector2, height: float) -> void:
	var delta := finish - start
	if delta.length() < 1.0:
		return
	surface.draw_set_transform(start, delta.angle(), Vector2(delta.length() / texture.get_width(), height / texture.get_height()))
	surface.draw_texture(texture, Vector2(0, -texture.get_height() * 0.5))
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_rotated_effect(surface: CanvasItem, texture: Texture2D, position: Vector2, angle: float) -> void:
	surface.draw_set_transform(position, angle, Vector2.ONE)
	surface.draw_texture(texture, -texture.get_size() * 0.5)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _ensure_actions() -> void:
	_add_key_action("cycle_battlefield_support", KEY_B)
	_add_key_action("call_battlefield_support", KEY_F)

func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
