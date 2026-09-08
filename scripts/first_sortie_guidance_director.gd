extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const FirstSortieGuidanceSurface = preload("res://scripts/first_sortie_guidance_surface.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const TEXT := Color("d9e0e5")
const BLUE := Color("6aa4c8")
const GOLD := Color("e8ca6a")
const RED := Color("dc6655")
const PANEL := Color(0.02, 0.05, 0.07, 0.82)
const PANEL_EDGE := Color(0.25, 0.43, 0.50, 0.86)

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
	var width := clampf(34.0 + float(text.length()) * 4.0, 230.0, 420.0)
	var x := floorf((640.0 - width) * 0.5)
	var rect := Rect2(x, 70, width, 19)
	surface.draw_rect(rect, PANEL)
	surface.draw_rect(rect, _tone(str(guidance.get("tone", "blue"))), false, 1.0)
	PixelFont.draw_centered(surface, text, 320, 76, 1, _tone(str(guidance.get("tone", "blue"))), 1)

func guidance_for(scene: Object) -> Dictionary:
	var forced := _capture_guidance()
	if not forced.is_empty():
		return _forced_guidance(forced)
	if not _first_campaign_sortie_active(scene):
		return {}

	if _has_property(scene, "egress_active") and bool(scene.get("egress_active")):
		return _egress_guidance()

	if _homing_threat_count(scene) > 0:
		return {"id":"countermeasure", "text":"MISSILE // V / LT COUNTERMEASURE", "tone":"red"}

	var elapsed := _route_seconds(scene)
	if elapsed >= 1.8 and elapsed < 6.8:
		return {"id":"steer_fire", "text":"FLIGHT CHECK // A-D/LS STEER // SPACE/A FIRE", "tone":"blue"}
	if elapsed >= 9.0 and elapsed < 14.0:
		return {"id":"power_geometry", "text":"POWER // T-G/RS THROTTLE // Q/Y GEOMETRY", "tone":"gold"}
	if elapsed >= 18.0 and elapsed < 23.0:
		return {"id":"altitude", "text":"ALTITUDE // PGUP-PGDN / D-PAD", "tone":"blue"}
	return {}

func _egress_guidance() -> Dictionary:
	var craft := get_node_or_null("/root/CraftFormDirector")
	var altitude := str(craft.call("current_altitude")) if craft != null and craft.has_method("current_altitude") else "mid"
	var hypersonic := craft != null and craft.has_method("hypersonic_active") and bool(craft.call("hypersonic_active"))
	if altitude not in ["high", "orbital"]:
		return {"id":"egress_climb", "text":"EGRESS // PGUP / D-PAD UP -> HIGH", "tone":"red"}
	if not hypersonic:
		return {"id":"egress_burn", "text":"MACH GATE // HOLD SHIFT / LB AFTERBURNER", "tone":"red"}
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

func _capture_guidance() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-first-sortie-guidance="):
			return argument.trim_prefix("--capture-first-sortie-guidance=").to_lower()
	return ""

func _forced_guidance(id: String) -> Dictionary:
	match id:
		"steer_fire": return {"id":id, "text":"FLIGHT CHECK // A-D/LS STEER // SPACE/A FIRE", "tone":"blue"}
		"power_geometry": return {"id":id, "text":"POWER // T-G/RS THROTTLE // Q/Y GEOMETRY", "tone":"gold"}
		"altitude": return {"id":id, "text":"ALTITUDE // PGUP-PGDN / D-PAD", "tone":"blue"}
		"countermeasure": return {"id":id, "text":"MISSILE // V / LT COUNTERMEASURE", "tone":"red"}
		"egress_climb": return {"id":id, "text":"EGRESS // PGUP / D-PAD UP -> HIGH", "tone":"red"}
		"egress_burn": return {"id":id, "text":"MACH GATE // HOLD SHIFT / LB AFTERBURNER", "tone":"red"}
	return {}

func _tone(id: String) -> Color:
	match id:
		"gold": return GOLD
		"red": return RED
		"text": return TEXT
	return BLUE

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)
