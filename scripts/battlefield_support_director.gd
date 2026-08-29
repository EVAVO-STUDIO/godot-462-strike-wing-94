extends CanvasLayer

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const BattlefieldSupportRules = preload("res://scripts/battlefield_support_rules.gd")
const BattlefieldSupportSurface = preload("res://scripts/battlefield_support_surface.gd")

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
	_tick_cooldowns(delta)
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		_clear_active()
		_queue_surface()
		return
	var mission_index := int(scene.get("mission_index"))
	if mission_index != _last_mission_index:
		_last_mission_index = mission_index
		_refresh_allowed()
		_clear_active()
	if int(scene.get("phase")) == 0:
		if Input.is_action_just_pressed("cycle_battlefield_support"):
			_cycle(scene)
	elif int(scene.get("phase")) == 1:
		if Input.is_action_just_pressed("call_battlefield_support"):
			_call_selected(scene)
		_update_active(scene, delta)
	else:
		_clear_active()
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
	_apply_immediate_support(scene, support)
	_cooldowns[id] = maxf(1.0, float(support.get("cooldown_seconds", 60.0)))

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
	if _active_id != "atlas_tanker":
		return
	var body := Color("798a93")
	var dark := Color("26323a")
	var hose := Color("d5c878")
	var p := _tanker_position
	surface.draw_rect(Rect2(p.x - 34, p.y - 6, 68, 12), body)
	surface.draw_rect(Rect2(p.x - 12, p.y - 12, 24, 24), body)
	surface.draw_colored_polygon(PackedVector2Array([p + Vector2(-12,0), p + Vector2(-52,12), p + Vector2(-18,14), p + Vector2(0,4)]), body)
	surface.draw_colored_polygon(PackedVector2Array([p + Vector2(12,0), p + Vector2(52,12), p + Vector2(18,14), p + Vector2(0,4)]), body)
	surface.draw_rect(Rect2(p.x - 4, p.y - 14, 8, 7), dark)
	var hose_point := BattlefieldSupportRules.tanker_hose_point(p)
	surface.draw_line(p + Vector2(0, 12), hose_point, hose, 2.0)
	surface.draw_circle(hose_point, BattlefieldSupportRules.TANKER_RADIUS, Color(0.85, 0.75, 0.35, 0.25), false, 1.0)
	var bar_width := 80.0
	var ratio := clampf(_tanker_progress / BattlefieldSupportRules.TANKER_REQUIRED_SECONDS, 0.0, 1.0)
	surface.draw_rect(Rect2(p.x - 40, p.y + 28, bar_width, 4), dark)
	surface.draw_rect(Rect2(p.x - 40, p.y + 28, floorf(bar_width * ratio), 4), hose)

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
