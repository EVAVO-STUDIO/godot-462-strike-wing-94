extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const PixelUiSurface = preload("res://scripts/pixel_ui_surface.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

const BG := Color("0b1016")
const PANEL := Color("070a0e")
const BORDER := Color("34414b")
const TEXT := Color("d9e0e5")
const MUTED := Color("7f909b")
const GOLD := Color("e8ca6a")
const GREEN := Color("67c3a5")
const RED := Color("dc6655")
const BLUE := Color("6aa4c8")

var _surface: Control

func _ready() -> void:
	layer = 30
	_surface = PixelUiSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
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
	PixelFont.draw_centered(surface, "STRIKE WING '94", 320, 28, 3, TEXT, 2)
	PixelFont.draw_centered(surface, str(scene.get("current_mission_name")), 320, 66, 2, GOLD, 2)
	PixelFont.draw_centered(surface, "%s   %s CONFIG   TECH %s" % [_altitude_name(), _form_name(), _tech_era_name()], 320, 88, 1, BLUE, 1)
	var briefing := str(scene.get("current_briefing"))
	var lines := _wrap_text(briefing, 72)
	for i in range(mini(2, lines.size())):
		PixelFont.draw_centered(surface, lines[i], 320, 106 + i * 10, 1, MUTED, 1)
	_draw_divider(surface, 136)
	PixelFont.draw_centered(surface, "ENTER LAUNCH   U WEAPON   G GENERATOR", 320, 148, 1, TEXT, 1)
	PixelFont.draw_centered(surface, "C SUPPORT   V SUPPORT BUY   H HULL   J SHIELD", 320, 162, 1, TEXT, 1)
	PixelFont.draw_centered(surface, "B BATTLE SUPPORT   F CALL   Q TRANSFORM IN FLIGHT", 320, 176, 1, GREEN, 1)
	var weapon := _call_dictionary(scene, "_active_weapon")
	var generator := _call_dictionary(scene, "_active_generator")
	PixelFont.draw_centered(surface, str(weapon.get("name", "CANNON")), 160, 199, 1, GOLD, 1)
	PixelFont.draw_centered(surface, str(generator.get("name", "GENERATOR")), 480, 199, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "TACTICAL %s" % _support_name(), 320, 216, 1, GREEN, 1)
	PixelFont.draw_centered(surface, "BATTLE %s" % _battlefield_support_name(), 320, 230, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "CREDITS %06d" % int(scene.get("credits")), 320, 246, 2, TEXT, 1)
	var service_hull := int(scene.get("service_hull")) if _has_property(scene, "service_hull") else int(scene.get("hull"))
	var service_shield := int(scene.get("service_shield")) if _has_property(scene, "service_shield") else int(scene.get("shield"))
	PixelFont.draw_centered(surface, "AIRFRAME H%03d S%03d" % [service_hull, service_shield], 320, 270, 1, GREEN, 1)
	_draw_divider(surface, 286)
	if float(scene.get("status_timer")) > 0.0:
		PixelFont.draw_centered(surface, _clip(str(scene.get("status_text")), 72), 320, 306, 1, GREEN, 1)
	else:
		PixelFont.draw_centered(surface, "VARIABLE GEOMETRY STRIKE CRAFT", 320, 306, 1, MUTED, 1)

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
	PixelFont.draw_centered(surface, "%s   %s   %s" % [_altitude_name(), _form_name(), _tech_era_name()], 320, 198, 1, BLUE, 1)
	if _has_property(scene, "shots_fired") and int(scene.get("shots_fired")) > 0:
		var fired := int(scene.get("shots_fired"))
		var hits := clampi(int(scene.get("shots_hit")), 0, fired)
		var accuracy := int(round(float(hits) / float(fired) * 100.0))
		PixelFont.draw_centered(surface, "ACCURACY %03d%%   HITS %d/%d" % [accuracy, hits, fired], 320, 218, 1, GREEN, 1)
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
	PixelFont.draw_text(surface, _clip(mission_name, 16), Vector2(16, 39), 1, MUTED, 1)
	PixelFont.draw_text(surface, "%s %s %s" % [_short_altitude(), _short_form(), _short_tech()], Vector2(148, 39), 1, BLUE, 1)
	PixelFont.draw_centered(surface, _clip(str(weapon.get("name", "CANNON")), 18), 326, 39, 1, TEXT, 1)
	PixelFont.draw_text(surface, _clip(_support_name(), 14), Vector2(422, 39), 1, GREEN, 1)
	PixelFont.draw_text(surface, "F:%s" % _clip(_battlefield_support_name(), 12), Vector2(518, 39), 1, BLUE, 1)
	_draw_boss(surface, scene)
	_draw_threat(surface, scene)
	if float(scene.get("status_timer")) > 0.0:
		surface.draw_rect(Rect2(116, 330, 408, 18), PANEL)
		PixelFont.draw_centered(surface, _clip(str(scene.get("status_text")), 70), 320, 336, 1, GOLD, 1)

func _draw_boss(surface: CanvasItem, scene: Object) -> void:
	var boss := _active_boss(scene)
	if boss.is_empty(): return
	var hp := maxi(0, int(boss.get("hp", 0)))
	var max_hp := maxi(1, int(boss.get("max_hp", hp)))
	var phase := int(boss.get("boss_phase", BossRules.phase_for(hp, max_hp)))
	var cue := " WEAK" if phase >= 3 else ""
	surface.draw_rect(Rect2(126, 64, 388, 28), PANEL)
	surface.draw_rect(Rect2(126, 64, 388, 28), RED, false, 1.0)
	PixelFont.draw_centered(surface, "%s  P%d%s  %d/%d" % [str(boss.get("id", "BOSS")).replace("_", " "), phase, cue, hp, max_hp], 320, 69, 1, TEXT, 1)
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	surface.draw_rect(Rect2(144, 82, 352, 4), BORDER)
	surface.draw_rect(Rect2(144, 82, floorf(352.0 * ratio), 4), RED)

func _draw_threat(surface: CanvasItem, scene: Object) -> void:
	var bullets: Array = scene.get("enemy_bullets")
	var player_position: Vector2 = scene.get("player_position")
	var count := ThreatWarningRules.homing_count(bullets)
	var distance := ThreatWarningRules.nearest_homing_distance(bullets, player_position)
	var text := ThreatWarningRules.warning_text(distance, count)
	if text == "": return
	surface.draw_rect(Rect2(180, 98, 280, 17), PANEL)
	surface.draw_rect(Rect2(180, 98, 280, 17), RED, false, 1.0)
	PixelFont.draw_centered(surface, text, 320, 104, 1, RED, 1)

func _support_name() -> String:
	var director := get_node_or_null("/root/SupportDirector")
	return str(director.call("current_support_name")).to_upper() if director != null and director.has_method("current_support_name") else "NO SUPPORT"

func _battlefield_support_name() -> String:
	var director := get_node_or_null("/root/BattlefieldSupportDirector")
	return str(director.call("current_support_name")).to_upper() if director != null and director.has_method("current_support_name") else "NONE"

func _form_name() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	return str(director.call("current_form_name")).to_upper() if director != null and director.has_method("current_form_name") else "FIGHTER"

func _altitude_name() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	return str(director.call("current_altitude_name")).to_upper() if director != null and director.has_method("current_altitude_name") else "MID ALT"

func _tech_era() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("mission_context"):
		var context = director.call("mission_context")
		if typeof(context) == TYPE_DICTIONARY:
			return TechProgressionRules.sanitize_era(str(context.get("tech_era", "advanced_conventional")))
	return "advanced_conventional"

func _tech_era_name() -> String:
	return TechProgressionRules.era_name(_tech_era())

func _short_tech() -> String:
	match _tech_era():
		"electromagnetic": return "EM"
		"directed_energy": return "DE"
		"strategic_orbital": return "ORB"
	return "CONV"

func _short_form() -> String:
	return "FTR" if _form_name() == "FIGHTER" else "BMB"

func _short_altitude() -> String:
	var value := _altitude_name()
	if value.begins_with("LOW"): return "LOW"
	if value.begins_with("HIGH"): return "HIGH"
	if value.begins_with("ATMOS"): return "ORB"
	return "MID"

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
		if typeof(enemy) == TYPE_DICTIONARY and bool(enemy.get("boss", false)) and int(enemy.get("hp", 0)) > 0: return enemy
	return {}

func _call_dictionary(scene: Object, method_name: String) -> Dictionary:
	if scene.has_method(method_name):
		var value = scene.call(method_name)
		return value if typeof(value) == TYPE_DICTIONARY else {}
	return {}

func _call_int(scene: Object, method_name: String, fallback: int) -> int:
	return int(scene.call(method_name)) if scene.has_method(method_name) else fallback

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name: return true
	return false

func _wrap_text(text: String, max_chars: int) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	for word in text.to_upper().replace("_", " ").split(" ", false):
		var candidate := str(word) if line == "" else "%s %s" % [line, word]
		if candidate.length() > max_chars and line != "": result.append(line); line = str(word)
		else: line = candidate
	if line != "": result.append(line)
	return result

func _clip(text: String, max_chars: int) -> String:
	var value := text.to_upper().replace("_", " ")
	return value if value.length() <= max_chars else value.substr(0, maxi(0, max_chars - 1)) + "."