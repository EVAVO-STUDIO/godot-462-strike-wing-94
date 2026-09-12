extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const FirstSortieGuidanceSurface = preload("res://scripts/first_sortie_guidance_surface.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const TEXT := Color("d9e0e5")
const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a")
const RED := Color("dc6655")
const PANEL := Color(0.02, 0.05, 0.07, 0.62)

var _surface: Control

func _ready() -> void:
	layer = 36
	if DisplayServer.get_name() == "headless":
		return
	_surface = FirstSortieGuidanceSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func draw_guidance(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	var guidance := guidance_for(scene)
	if guidance.is_empty():
		return
	var text := str(guidance.get("text", ""))
	if text.is_empty():
		return
	var width := clampf(20.0 + float(text.length()) * 4.0, 176.0, 340.0)
	var x := floorf((640.0 - width) * 0.5)
	var rect := Rect2(x, 43, width, 15)
	surface.draw_rect(rect, PANEL)
	surface.draw_rect(rect, _tone(str(guidance.get("tone", "blue"))), false, 1.0)
	PixelFont.draw_centered(surface, text, 320, 48, 1, _tone(str(guidance.get("tone", "blue"))), 1)

func guidance_for(scene: Object) -> Dictionary:
	var forced := _capture_guidance()
	if not forced.is_empty():
		return _forced_guidance(forced)
	if not _first_campaign_sortie_active(scene):
		return {}

	if _has_property(scene, "egress_active") and bool(scene.get("egress_active")):
		return _egress_guidance()

	if _homing_threat_count(scene) > 0:
		return _countermeasure_guidance()

	var elapsed := _route_seconds(scene)
	# Teach basic control before MissionRadioDirector's normal 1.62s briefing
	# delay expires. The first sortie therefore presents controls and narrative as
	# consecutive beats rather than two simultaneous instruction channels.
	if elapsed >= 0.20 and elapsed < 1.50:
		return _steer_fire_guidance()
	if elapsed >= 9.0 and elapsed < 12.0:
		return _power_geometry_guidance()
	if elapsed >= 18.0 and elapsed < 21.0:
		return _altitude_guidance()
	return {}

func _steer_fire_guidance() -> Dictionary:
	var left := _keyboard_label("move_left", "A")
	var right := _keyboard_label("move_right", "D")
	var fire := _keyboard_label("fire_primary", "SPACE")
	var pause := _keyboard_label("cancel", "ESC")
	return {"id":"steer_fire", "text":"STEER %s-%s/LS   FIRE %s/A   PAUSE %s/START" % [left, right, fire, pause], "tone":"blue"}

func _power_geometry_guidance() -> Dictionary:
	var throttle_up := _keyboard_label("throttle_up", "T")
	var throttle_down := _keyboard_label("throttle_down", "G")
	var transform := _keyboard_label("transform_craft", "Q")
	return {"id":"power_geometry", "text":"THROTTLE %s-%s/RS   GEOMETRY %s/Y" % [throttle_up, throttle_down, transform], "tone":"gold"}

func _altitude_guidance() -> Dictionary:
	var up := _keyboard_label("altitude_up", "PGUP")
	var down := _keyboard_label("altitude_down", "PGDN")
	return {"id":"altitude", "text":"ALTITUDE %s-%s/D-PAD" % [up, down], "tone":"blue"}

func _countermeasure_guidance() -> Dictionary:
	var countermeasure := _keyboard_label("deploy_countermeasure", "V")
	return {"id":"countermeasure", "text":"MISSILE LOCK   FLARE %s/LT" % countermeasure, "tone":"red"}

func _egress_guidance() -> Dictionary:
	var craft := get_node_or_null("/root/CraftFormDirector")
	var altitude := str(craft.call("current_altitude")) if craft != null and craft.has_method("current_altitude") else "mid"
	var hypersonic := craft != null and craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))
	if altitude not in ["high", "orbital"]:
		return {"id":"egress_climb", "text":"EGRESS // %s / D-PAD UP -> HIGH" % _keyboard_label("altitude_up", "PGUP"), "tone":"red"}
	if not hypersonic:
		return {"id":"egress_burn", "text":"MACH GATE // HOLD %s / LB AFTERBURNER" % _keyboard_label("afterburner", "SHIFT"), "tone":"red"}
	return {"id":"egress_hold", "text":"MACH GATE // HOLD COURSE", "tone":"gold"}

func _first_campaign_sortie_active(scene: Object) -> bool:
	if scene == null:
		return false
	if not SceneContractCache.supports(scene, ["phase", "mission_index", "mission_time", "enemy_bullets"]):
		return false
	if int(scene.get("phase")) != 1 or int(scene.get("mission_index")) != 0:
		return false
	if _has_property(scene, "game_mode") and str(scene.get("game_mode")) != "campaign":
		return false
	if _has_property(scene, "active_secret_mission_id") and not str(scene.get("active_secret_mission_id")).is_empty():
		return false
	return true

func _homing_threat_count(scene: Object) -> int:
	if scene == null or not _has_property(scene, "enemy_bullets"):
		return 0
	var bullets = scene.get("enemy_bullets")
	return ThreatWarningRules.homing_count(bullets) if typeof(bullets) == TYPE_ARRAY else 0

func _route_seconds(scene: Object) -> float:
	if scene != null and scene.has_method("route_progress_seconds"):
		return maxf(0.0, float(scene.call("route_progress_seconds")))
	return maxf(0.0, float(scene.get("mission_time"))) if scene != null and _has_property(scene, "mission_time") else 0.0

func _keyboard_label(action: StringName, fallback: String) -> String:
	if not InputMap.has_action(action):
		return fallback
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var key := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			var label := OS.get_keycode_string(key).to_upper()
			if not label.is_empty():
				return _short_key(label)
	return fallback

func _short_key(label: String) -> String:
	match label:
		"PAGEUP": return "PGUP"
		"PAGEDOWN": return "PGDN"
		"SHIFT": return "SHIFT"
		"ESCAPE": return "ESC"
	return label

func _capture_guidance() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-first-sortie-guidance="):
			return argument.trim_prefix("--capture-first-sortie-guidance=").to_lower()
	return ""

func _forced_guidance(id: String) -> Dictionary:
	match id:
		"steer_fire": return _steer_fire_guidance()
		"power_geometry": return _power_geometry_guidance()
		"altitude": return _altitude_guidance()
		"countermeasure": return _countermeasure_guidance()
		"egress_climb": return {"id":id, "text":"EGRESS // %s / D-PAD UP -> HIGH" % _keyboard_label("altitude_up", "PGUP"), "tone":"red"}
		"egress_burn": return {"id":id, "text":"MACH GATE // HOLD %s / LB AFTERBURNER" % _keyboard_label("afterburner", "SHIFT"), "tone":"red"}
	return {}

func _tone(id: String) -> Color:
	match id:
		"gold": return GOLD
		"red": return RED
		"text": return TEXT
	return BLUE

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)
