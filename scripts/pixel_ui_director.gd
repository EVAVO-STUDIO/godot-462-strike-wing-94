extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")

const BG := Color("0b1016")
const PANEL := Color("070a0e")
const BORDER := Color("34414b")
const TEXT := Color("d9e0e5")
const MUTED := Color("7f909b")
const GOLD := Color("e8ca6a")
const GREEN := Color("67c3a5")
const RED := Color("dc6655")
const BLUE := Color("6aa4c8")

class PixelSurface extends Control:
	var director: Node
	func _draw() -> void:
		if director != null:
			director._draw_surface(self)

var _surface: PixelSurface

func _ready() -> void:
	layer = 30
	_surface = PixelSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func _draw_surface(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		return
	var phase := int(scene.get("phase"))
	if phase == 0:
		_draw_title(surface, scene)
	elif phase == 2:
		_draw_result(surface, scene)
	else:
		_draw_gameplay_hud(surface, scene)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	for required in ["phase", "credits", "mission_time", "mission_duration", "hull", "shield", "bombs", "wave", "score", "status_text", "status_timer", "enemies", "enemy_bullets", "player_position"]:
		if not names.has(required):
			return false
	return true

func _draw_title(surface: CanvasItem, scene: Object) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	PixelFont.draw_centered(surface, "STRIKE WING '94", 320, 34, 3, TEXT, 2)
	PixelFont.draw_centered(surface, str(scene.get("current_mission_name")), 320, 78, 2, GOLD, 2)
	var briefing := str(scene.get("current_briefing"))
	var lines := _wrap_text(briefing, 72)
	for i in range(mini(2, lines.size())):
		PixelFont.draw_centered(surface, lines[i], 320, 108 + i * 10, 1, MUTED, 1)
	_draw_divider(surface, 142)
	PixelFont.draw_centered(surface, "ENTER LAUNCH   U WEAPON   G GENERATOR", 320, 157, 1, TEXT, 1)
	PixelFont.draw_centered(surface, "H HULL SERVICE   J SHIELD SERVICE", 320, 171, 1, TEXT, 1)
	var weapon := _call_dictionary(scene, "_active_weapon")
	var generator := _call_dictionary(scene, "_active_generator")
	PixelFont.draw_centered(surface, str(weapon.get("name", "CANNON")), 190, 206, 1, GOLD, 1)
	PixelFont.draw_centered(surface, str(generator.get("name", "GENERATOR")), 450, 206, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "CREDITS %06d" % int(scene.get("credits")), 320, 226, 2, TEXT, 1)
	var service_hull := int(scene.get("service_hull")) if _has_property(scene, "service_hull") else int(scene.get("hull"))
	var service_shield := int(scene.get("service_shield")) if _has_property(scene, "service_shield") else int(scene.get("shield"))
	PixelFont.draw_centered(surface, "AIRFRAME H%03d S%03d" % [service_hull, service_shield], 320, 257, 1, GREEN, 1)
	_draw_divider(surface, 284)
	if float(scene.get("status_timer")) > 0.0:
		PixelFont.draw_centered(surface, str(scene.get("status_text")), 320, 306, 1, GREEN, 1)
	else:
		PixelFont.draw_centered(surface, "640X360 LOGICAL / INTEGER 2X OUTPUT", 320, 306, 1, MUTED, 1)

func _draw_result(surface: CanvasItem, scene: Object) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	PixelFont.draw_centered(surface, "MISSION REPORT", 320, 44, 3, GOLD, 2)
	var result_lines := _wrap_text(str(scene.get("result_text")), 66)
	for i in range(mini(3, result_lines.size())):
		PixelFont.draw_centered(surface, result_lines[i], 320, 94 + i * 12, 1, TEXT, 1)
	_draw_divider(surface, 142)
	PixelFont.draw_centered(surface, "SCORE %08d" % int(scene.get("score")), 210, 169, 2, TEXT, 1)
	PixelFont.draw_centered(surface, "CREDITS %06d" % int(scene.get("credits")), 430, 169, 2, TEXT, 1)
	if _has_property(scene, "shots_fired") and int(scene.get("shots_fired")) > 0:
		var fired := int(scene.get("shots_fired"))
		var hits := clampi(int(scene.get("shots_hit")), 0, fired)
		var accuracy := int(round(float(hits) / float(fired) * 100.0))
		PixelFont.draw_centered(surface, "ACCURACY %03d%%   HITS %d/%d" % [accuracy, hits, fired], 320, 212, 1, GREEN, 1)
	PixelFont.draw_centered(surface, "ENTER NEXT MISSION   R RETRY", 320, 274, 1, TEXT, 1)

func _draw_gameplay_hud(surface: CanvasItem, scene: Object) -> void:
	surface.draw_rect(Rect2(8, 8, 624, 50), PANEL)
	surface.draw_rect(Rect2(8, 8, 624, 50), BORDER, false, 1.0)
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	var generator := _call_dictionary(scene, "_active_generator")
	var energy := float(scene.get("energy")) if _has_property(scene, "energy") else 0.0
	_draw_meter(surface, Vector2(16, 14), "H", int(scene.get("hull")), max_hull, RED)
	_draw_meter(surface, Vector2(112, 14), "S", int(scene.get("shield")), maxi(1, max_shield), BLUE)
	_draw_meter(surface, Vector2(208, 14), "E", int(round(energy)), maxi(1, int(round(EnergyRules.capacity(generator)))), GOLD)
	PixelFont.draw_text(surface, "B%d" % int(scene.get("bombs")), Vector2(310, 15), 1, TEXT, 1)
	PixelFont.draw_text(surface, "W%02d" % int(scene.get("wave")), Vector2(344, 15), 1, TEXT, 1)
	var remaining := maxi(0, int(ceil(float(scene.get("mission_duration")) - float(scene.get("mission_time")))))
	PixelFont.draw_text(surface, "T%03d" % remaining, Vector2(390, 15), 1, TEXT, 1)
	PixelFont.draw_text(surface, "%08d" % int(scene.get("score")), Vector2(520, 15), 1, TEXT, 1)
	var mission_name := str(scene.get("current_mission_name"))
	var weapon := _call_dictionary(scene, "_active_weapon")
	PixelFont.draw_text(surface, _clip(mission_name, 24), Vector2(16, 39), 1, MUTED, 1)
	PixelFont.draw_centered(surface, _clip(str(weapon.get("name", "CANNON")), 24), 320, 39, 1, TEXT, 1)
	PixelFont.draw_text(surface, _clip(str(generator.get("name", "GENERATOR")), 22), Vector2(472, 39), 1, BLUE, 1)
	_draw_boss(surface, scene)
	_draw_threat(surface, scene)
	if float(scene.get("status_timer")) > 0.0:
		surface.draw_rect(Rect2(116, 330, 408, 18), PANEL)
		PixelFont.draw_centered(surface, _clip(str(scene.get("status_text")), 70), 320, 336, 1, GOLD, 1)

func _draw_boss(surface: CanvasItem, scene: Object) -> void:
	var boss := _active_boss(scene)
	if boss.is_empty():
		return
	var hp := maxi(0, int(boss.get("hp", 0)))
	var max_hp := maxi(1, int(boss.get("max_hp", hp)))
	var phase := int(boss.get("boss_phase", BossRules.phase_for(hp, max_hp)))
	surface.draw_rect(Rect2(126, 64, 388, 28), PANEL)
	surface.draw_rect(Rect2(126, 64, 388, 28), RED, false, 1.0)
	PixelFont.draw_centered(surface, "%s  P%d  %d/%d" % [str(boss.get("id", "BOSS")).replace("_", " "), phase, hp, max_hp], 320, 69, 1, TEXT, 1)
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	surface.draw_rect(Rect2(144, 82, 352, 4), BORDER)
	surface.draw_rect(Rect2(144, 82, floorf(352.0 * ratio), 4), RED)

func _draw_threat(surface: CanvasItem, scene: Object) -> void:
	var bullets: Array = scene.get("enemy_bullets")
	var player_position: Vector2 = scene.get("player_position")
	var count := ThreatWarningRules.homing_count(bullets)
	var distance := ThreatWarningRules.nearest_homing_distance(bullets, player_position)
	var text := ThreatWarningRules.warning_text(distance, count)
	if text == "":
		return
	surface.draw_rect(Rect2(180, 98, 280, 17), PANEL)
	PixelFont.draw_centered(surface, text, 320, 104, 1, RED, 1)

func _draw_meter(surface: CanvasItem, position: Vector2, label: String, current: int, maximum: int, color: Color) -> void:
	var max_value := maxi(1, maximum)
	var value := clampi(current, 0, max_value)
	PixelFont.draw_text(surface, "%s%03d" % [label, value], position, 1, TEXT, 1)
	var ratio := clampf(float(value) / float(max_value), 0.0, 1.0)
	surface.draw_rect(Rect2(position.x, position.y + 14, 78, 4), BORDER)
	surface.draw_rect(Rect2(position.x, position.y + 14, floorf(78.0 * ratio), 4), color)

func _draw_frame(surface: CanvasItem, rect: Rect2) -> void:
	surface.draw_rect(rect, PANEL)
	surface.draw_rect(rect, BORDER, false, 1.0)
	surface.draw_rect(rect.grow(-3), Color("1b242b"), false, 1.0)

func _draw_divider(surface: CanvasItem, y: float) -> void:
	surface.draw_line(Vector2(42, y), Vector2(598, y), BORDER, 1.0)

func _active_boss(scene: Object) -> Dictionary:
	var enemies: Array = scene.get("enemies")
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and bool(enemy.get("boss", false)) and int(enemy.get("hp", 0)) > 0:
			return enemy
	return {}

func _call_dictionary(scene: Object, method_name: String) -> Dictionary:
	if scene.has_method(method_name):
		var value = scene.call(method_name)
		return value if typeof(value) == TYPE_DICTIONARY else {}
	return {}

func _call_int(scene: Object, method_name: String, fallback: int) -> int:
	if scene.has_method(method_name):
		return int(scene.call(method_name))
	return fallback

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _wrap_text(text: String, max_chars: int) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	for word in text.to_upper().replace("_", " ").split(" ", false):
		var candidate := str(word) if line == "" else "%s %s" % [line, word]
		if candidate.length() > max_chars and line != "":
			result.append(line)
			line = str(word)
		else:
			line = candidate
	if line != "":
		result.append(line)
	return result

func _clip(text: String, max_chars: int) -> String:
	var value := text.to_upper().replace("_", " ")
	return value if value.length() <= max_chars else value.substr(0, maxi(0, max_chars - 1)) + "."
