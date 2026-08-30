extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const PixelUiSurface = preload("res://scripts/pixel_ui_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v1.png")
const VX94_FIGHTER := preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png")
const VX94_BOMBER := preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png")
const SORTIE_BAY_BACKDROP := preload("res://assets/runtime/ui/menu/sortie_bay_backdrop_v1.png")
const OPERATIONS_PANEL := preload("res://assets/runtime/ui/menu/operations_panel_9slice.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_screen_9slice.png")
const OPERATIONS_BUTTON := preload("res://assets/runtime/ui/menu/operations_button_9slice.png")
const HUD_TOP_FRAME := preload("res://assets/runtime/ui/hud/top_frame.png")
const HUD_METER_TROUGH := preload("res://assets/runtime/ui/hud/meter_trough.png")
const HUD_HULL_FILL := preload("res://assets/runtime/ui/hud/hull_fill.png")
const HUD_SHIELD_FILL := preload("res://assets/runtime/ui/hud/shield_fill.png")
const HUD_ENERGY_FILL := preload("res://assets/runtime/ui/hud/energy_fill.png")
const HUD_STATUS_FRAME := preload("res://assets/runtime/ui/hud/status_frame.png")
const HUD_BOSS_FRAME := preload("res://assets/runtime/ui/hud/boss_frame.png")
const HUD_BOSS_TROUGH := preload("res://assets/runtime/ui/hud/boss_trough.png")
const HUD_BOSS_FILL := preload("res://assets/runtime/ui/hud/boss_fill.png")
const HUD_THREAT_FRAME := preload("res://assets/runtime/ui/hud/threat_frame.png")
const HUD_ICON_BOMB := preload("res://assets/runtime/ui/hud/icon_bomb.png")
const HUD_ICON_WAVE := preload("res://assets/runtime/ui/hud/icon_wave.png")
const HUD_ICON_TIME := preload("res://assets/runtime/ui/hud/icon_time.png")
const HUD_ICON_SCORE := preload("res://assets/runtime/ui/hud/icon_score.png")
const FLIGHT_STATE_FRAME := preload("res://assets/runtime/ui/hud/flight_state/frame.png")
const ALTITUDE_RAIL := preload("res://assets/runtime/ui/hud/flight_state/altitude_rail.png")
const ALTITUDE_STATES := {
	"low": preload("res://assets/runtime/ui/hud/flight_state/altitude_low.png"),
	"mid": preload("res://assets/runtime/ui/hud/flight_state/altitude_mid.png"),
	"high": preload("res://assets/runtime/ui/hud/flight_state/altitude_high.png"),
	"orbital": preload("res://assets/runtime/ui/hud/flight_state/altitude_orbital.png"),
}
const FORM_STATES := {
	"fighter": preload("res://assets/runtime/ui/hud/flight_state/form_fighter.png"),
	"bomber": preload("res://assets/runtime/ui/hud/flight_state/form_bomber.png"),
}
const TECH_STATES := {
	"advanced_conventional": preload("res://assets/runtime/ui/hud/flight_state/tech_conventional.png"),
	"electromagnetic": preload("res://assets/runtime/ui/hud/flight_state/tech_em.png"),
	"directed_energy": preload("res://assets/runtime/ui/hud/flight_state/tech_directed.png"),
	"strategic_orbital": preload("res://assets/runtime/ui/hud/flight_state/tech_orbital.png"),
}

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
	surface.draw_texture_rect(SORTIE_BAY_BACKDROP, Rect2(0,0,640,360), false, Color(0.78,0.86,0.88,0.88))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.025,0.035,0.42))
	_draw_frame(surface, Rect2(10, 10, 620, 340), false)
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(195, 18, 250, 32), false)
	PixelFont.draw_centered(surface, _identity_subtitle(), 320, 53, 1, BLUE, 1)
	_draw_console_panel(surface, Rect2(26, 72, 370, 119), "MISSION 01 / SORTIE ORDER", GOLD)
	PixelFont.draw_text(surface, str(scene.get("current_mission_name")), Vector2(40, 94), 2, GOLD, 2)
	PixelFont.draw_text(surface, "%s // %s // %s" % [_altitude_name(), _form_name(), _tech_era_name()], Vector2(40, 117), 1, BLUE, 1)
	var briefing := str(scene.get("current_briefing"))
	var lines := _wrap_text(briefing, 49)
	for i in range(mini(2, lines.size())):
		PixelFont.draw_text(surface, lines[i], Vector2(40, 139 + i * 11), 1, MUTED, 1)
	PixelFont.draw_text(surface, "INGRESS", Vector2(40, 170), 1, MUTED, 1)
	PixelFont.draw_text(surface, "HIGH-SPEED / LOW-LEVEL RELEASE", Vector2(105, 170), 1, GREEN, 1)

	_draw_console_panel(surface, Rect2(408, 72, 206, 119), "VX-94 AIRFRAME", BLUE)
	var craft := VX94_FIGHTER if _form_name() == "FIGHTER" else VX94_BOMBER
	surface.draw_texture_rect(craft, Rect2(420, 91, 64, 72), false)
	PixelFont.draw_text(surface, _form_name(), Vector2(493, 95), 1, TEXT, 1)
	PixelFont.draw_text(surface, _altitude_name(), Vector2(493, 109), 1, BLUE, 1)
	PixelFont.draw_text(surface, "GEOMETRY", Vector2(493, 129), 1, MUTED, 1)
	PixelFont.draw_text(surface, "VARIABLE", Vector2(493, 143), 1, GREEN, 1)
	PixelFont.draw_text(surface, "Q SWEEP", Vector2(493, 166), 1, GOLD, 1)

	_draw_console_panel(surface, Rect2(26, 203, 370, 93), "ARM / SERVICE", TEXT)
	var weapon := _call_dictionary(scene, "_active_weapon")
	var generator := _call_dictionary(scene, "_active_generator")
	PixelFont.draw_text(surface, "U PRIMARY", Vector2(40, 224), 1, MUTED, 1)
	PixelFont.draw_text(surface, _clip(str(weapon.get("name", "CANNON")), 22), Vector2(126, 224), 1, GOLD, 1)
	PixelFont.draw_text(surface, "G POWER", Vector2(40, 239), 1, MUTED, 1)
	PixelFont.draw_text(surface, _clip(str(generator.get("name", "GENERATOR")), 22), Vector2(126, 239), 1, BLUE, 1)
	PixelFont.draw_text(surface, "K FRAME", Vector2(40, 254), 1, MUTED, 1)
	PixelFont.draw_text(surface, _clip(_airframe_name(), 25), Vector2(126, 254), 1, TEXT, 1)
	PixelFont.draw_text(surface, "C TACTICAL", Vector2(40, 269), 1, MUTED, 1)
	PixelFont.draw_text(surface, _clip(_support_name(), 22), Vector2(126, 269), 1, GREEN, 1)
	PixelFont.draw_text(surface, "B BATTLE", Vector2(40, 284), 1, MUTED, 1)
	PixelFont.draw_text(surface, _clip(_battlefield_support_name(), 22), Vector2(126, 284), 1, BLUE, 1)

	_draw_console_panel(surface, Rect2(408, 203, 206, 93), "READINESS", TEXT)
	PixelFont.draw_text(surface, "CREDITS %06d" % int(scene.get("credits")), Vector2(422, 224), 1, TEXT, 1)
	var service_hull := int(scene.get("service_hull")) if _has_property(scene, "service_hull") else int(scene.get("hull"))
	var service_shield := int(scene.get("service_shield")) if _has_property(scene, "service_shield") else int(scene.get("shield"))
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	PixelFont.draw_text(surface, "H HULL   %03d/%03d" % [service_hull, max_hull], Vector2(422, 243), 1, GREEN, 1)
	PixelFont.draw_text(surface, "J SHIELD %03d/%03d" % [service_shield, max_shield], Vector2(422, 258), 1, BLUE, 1)
	PixelFont.draw_text(surface, "L STORES SCHEMATIC", Vector2(422, 280), 1, MUTED, 1)

	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_BUTTON, Rect2(26, 308, 588, 27), 6)
	PixelFont.draw_text(surface, ">>", Vector2(40, 317), 1, RED, 1)
	PixelFont.draw_centered(surface, "ENTER / START  AUTHORIZE LAUNCH", 320, 317, 1, GOLD, 1)
	if float(scene.get("status_timer")) > 0.0:
		PixelFont.draw_centered(surface, _clip(str(scene.get("status_text")), 72), 320, 340, 1, GREEN, 1)

func _draw_result(surface: CanvasItem, scene: Object) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	surface.draw_texture_rect(SORTIE_BAY_BACKDROP, Rect2(0,0,640,360), false, Color(0.62,0.70,0.73,0.72))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.02,0.03,0.66))
	_draw_frame(surface, Rect2(10, 10, 620, 340), false)
	PixelFont.draw_centered(surface, "MISSION REPORT", 320, 44, 3, GOLD, 2)

	var result_lines := _wrap_text(str(scene.get("result_text")), 66)
	for i in range(mini(3, result_lines.size())):
		PixelFont.draw_centered(surface, result_lines[i], 320, 94 + i * 12, 1, TEXT, 1)
	_draw_divider(surface, 142)
	PixelFont.draw_centered(surface, "SCORE %08d" % int(scene.get("score")), 210, 169, 2, TEXT, 1)
	PixelFont.draw_centered(surface, "CREDITS %06d" % int(scene.get("credits")), 430, 169, 2, TEXT, 1)
	PixelFont.draw_centered(surface, "%s   %s   %s" % [_altitude_name(), _form_name(), _tech_era_name()], 320, 198, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "FRAME %s" % _airframe_name(), 320, 214, 1, MUTED, 1)
	if _has_property(scene, "shots_fired") and int(scene.get("shots_fired")) > 0:
		var fired := int(scene.get("shots_fired"))
		var hits := clampi(int(scene.get("shots_hit")), 0, fired)
		var accuracy := int(round(float(hits) / float(fired) * 100.0))
		PixelFont.draw_centered(surface, "ACCURACY %03d%%   HITS %d/%d" % [accuracy, hits, fired], 320, 232, 1, GREEN, 1)
	PixelFont.draw_centered(surface, "ENTER NEXT MISSION   R RETRY", 320, 274, 1, TEXT, 1)

func _identity_title() -> String:
	var identity := get_node_or_null("/root/ProductIdentity")
	return str(identity.call("title_primary")) if identity != null and identity.has_method("title_primary") else "HYPERSONIC"

func _identity_subtitle() -> String:
	var identity := get_node_or_null("/root/ProductIdentity")
	return str(identity.call("title_subtitle")) if identity != null and identity.has_method("title_subtitle") else "VX-94 VARIABLE STRIKE FIGHTER"

func _draw_gameplay_hud(surface: CanvasItem, scene: Object) -> void:
	surface.draw_texture(HUD_TOP_FRAME, Vector2(8, 8))
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	var generator := _call_dictionary(scene, "_active_generator")
	var energy := float(scene.get("energy")) if _has_property(scene, "energy") else 0.0
	_draw_meter(surface, Vector2(16, 14), "H", int(scene.get("hull")), max_hull, HUD_HULL_FILL)
	_draw_meter(surface, Vector2(112, 14), "S", int(scene.get("shield")), maxi(1, max_shield), HUD_SHIELD_FILL)
	_draw_meter(surface, Vector2(208, 14), "E", int(round(energy)), maxi(1, int(round(EnergyRules.capacity(generator)))), HUD_ENERGY_FILL)
	surface.draw_texture(HUD_ICON_BOMB, Vector2(304, 12))
	PixelFont.draw_text(surface, "%d" % int(scene.get("bombs")), Vector2(318, 15), 1, TEXT, 1)
	surface.draw_texture(HUD_ICON_WAVE, Vector2(342, 12))
	PixelFont.draw_text(surface, "%02d" % int(scene.get("wave")), Vector2(356, 15), 1, TEXT, 1)
	var remaining := maxi(0, int(ceil(float(scene.get("mission_duration")) - float(scene.get("mission_time")))))
	surface.draw_texture(HUD_ICON_TIME, Vector2(388, 12))
	PixelFont.draw_text(surface, "%03d" % remaining, Vector2(402, 15), 1, TEXT, 1)
	surface.draw_texture(HUD_ICON_SCORE, Vector2(504, 12))
	PixelFont.draw_text(surface, "%08d" % int(scene.get("score")), Vector2(520, 15), 1, TEXT, 1)
	var mission_name := str(scene.get("current_mission_name"))
	var weapon := _call_dictionary(scene, "_active_weapon")
	PixelFont.draw_text(surface, _clip(mission_name, 16), Vector2(16, 39), 1, MUTED, 1)
	_draw_flight_state(surface)
	PixelFont.draw_centered(surface, _clip(str(weapon.get("name", "CANNON")), 18), 326, 39, 1, TEXT, 1)
	PixelFont.draw_text(surface, _clip(_support_name(), 14), Vector2(422, 39), 1, GREEN, 1)
	PixelFont.draw_text(surface, "F:%s" % _clip(_battlefield_support_name(), 12), Vector2(518, 39), 1, BLUE, 1)
	_draw_boss(surface, scene)
	_draw_threat(surface, scene)
	if float(scene.get("status_timer")) > 0.0:
		surface.draw_texture(HUD_STATUS_FRAME, Vector2(116, 330))
		PixelFont.draw_centered(surface, _clip(str(scene.get("status_text")), 70), 320, 336, 1, GOLD, 1)

func _draw_flight_state(surface: CanvasItem) -> void:
	surface.draw_texture(FLIGHT_STATE_FRAME, Vector2(140, 34))
	surface.draw_texture(ALTITUDE_RAIL, Vector2(144, 36))
	var altitude_key := _altitude_key()
	surface.draw_texture(ALTITUDE_STATES.get(altitude_key, ALTITUDE_STATES["mid"]), Vector2(144, 36))
	PixelFont.draw_text(surface, _short_altitude(), Vector2(170, 39), 1, BLUE, 1)
	var form_key := "fighter" if _form_name() == "FIGHTER" else "bomber"
	surface.draw_texture(FORM_STATES[form_key], Vector2(204, 36))
	PixelFont.draw_text(surface, _short_form(), Vector2(231, 39), 1, GREEN if form_key == "fighter" else GOLD, 1)
	var tech_key := _tech_era()
	surface.draw_texture(TECH_STATES.get(tech_key, TECH_STATES["advanced_conventional"]), Vector2(253, 36))
	PixelFont.draw_text(surface, _short_tech(), Vector2(278, 39), 1, BLUE, 1)

func _altitude_key() -> String:
	var value := _altitude_name()
	if value.begins_with("LOW"): return "low"
	if value.begins_with("HIGH"): return "high"
	if value.begins_with("ATMOS") or value.begins_with("ORBIT"): return "orbital"
	return "mid"

func _draw_boss(surface: CanvasItem, scene: Object) -> void:
	var boss := _active_boss(scene)
	if boss.is_empty(): return
	var hp := maxi(0, int(boss.get("hp", 0)))
	var max_hp := maxi(1, int(boss.get("max_hp", hp)))
	var phase := int(boss.get("boss_phase", BossRules.phase_for(hp, max_hp)))
	var cue := " WEAK" if phase >= 3 else ""
	surface.draw_texture(HUD_BOSS_FRAME, Vector2(126, 64))
	PixelFont.draw_centered(surface, "%s  P%d%s  %d/%d" % [str(boss.get("id", "BOSS")).replace("_", " "), phase, cue, hp, max_hp], 320, 69, 1, TEXT, 1)
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	surface.draw_texture(HUD_BOSS_TROUGH, Vector2(143, 80))
	_draw_clipped_fill(surface, HUD_BOSS_FILL, Vector2(144, 81), ratio)

func _draw_threat(surface: CanvasItem, scene: Object) -> void:
	var bullets: Array = scene.get("enemy_bullets")
	var player_position: Vector2 = scene.get("player_position")
	var count := ThreatWarningRules.homing_count(bullets)
	var distance := ThreatWarningRules.nearest_homing_distance(bullets, player_position)
	var text := ThreatWarningRules.warning_text(distance, count)
	if text == "": return
	surface.draw_texture(HUD_THREAT_FRAME, Vector2(180, 98))
	PixelFont.draw_centered(surface, text, 320, 104, 1, RED, 1)

func _support_name() -> String:
	var director := get_node_or_null("/root/SupportDirector")
	return str(director.call("current_support_name")).to_upper() if director != null and director.has_method("current_support_name") else "NO SUPPORT"

func _battlefield_support_name() -> String:
	var director := get_node_or_null("/root/BattlefieldSupportDirector")
	return str(director.call("current_support_name")).to_upper() if director != null and director.has_method("current_support_name") else "NONE"

func _airframe_name() -> String:
	var director := get_node_or_null("/root/AirframeDirector")
	return str(director.call("current_airframe_name")).to_upper() if director != null and director.has_method("current_airframe_name") else "COMPOSITE FRAME MK I"

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
		"strategic_orbital": return "OR"
	return "CV"

func _short_form() -> String:
	return "FTR" if _form_name() == "FIGHTER" else "BMB"

func _short_altitude() -> String:
	var value := _altitude_name()
	if value.begins_with("LOW"): return "LOW"
	if value.begins_with("HIGH"): return "HIGH"
	if value.begins_with("ATMOS"): return "ORB"
	return "MID"

func _draw_meter(surface: CanvasItem, position: Vector2, label: String, current: int, maximum: int, fill_texture: Texture2D) -> void:
	var max_value := maxi(1, maximum)
	var value := clampi(current, 0, max_value)
	PixelFont.draw_text(surface, "%s%03d" % [label, value], position, 1, TEXT, 1)
	var ratio := clampf(float(value) / float(max_value), 0.0, 1.0)
	surface.draw_texture(HUD_METER_TROUGH, position + Vector2(0, 13))
	_draw_clipped_fill(surface, fill_texture, position + Vector2(1, 14), ratio)

func _draw_clipped_fill(surface: CanvasItem, texture: Texture2D, position: Vector2, ratio: float) -> void:
	var width := floorf(float(texture.get_width()) * clampf(ratio, 0.0, 1.0))
	if width <= 0.0:
		return
	surface.draw_texture_rect_region(texture, Rect2(position, Vector2(width, texture.get_height())), Rect2(0, 0, width, texture.get_height()))

func _draw_frame(surface: CanvasItem, rect: Rect2, fill_background: bool = true) -> void:
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_SCREEN, rect, 8)
	if not fill_background:
		surface.draw_rect(rect.grow(-8), Color(0, 0, 0, 0.03), false, 1.0)

func _draw_console_panel(surface: CanvasItem, rect: Rect2, label: String, accent: Color) -> void:
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_PANEL, rect, 6)
	surface.draw_line(rect.position + Vector2(6, 16), Vector2(rect.end.x - 6, rect.position.y + 16), BORDER, 1.0)
	surface.draw_rect(Rect2(rect.position + Vector2(4, 5), Vector2(4, 4)), accent)
	PixelFont.draw_text(surface, label, rect.position + Vector2(14, 5), 1, accent, 1)

func _draw_divider(surface: CanvasItem, y: float) -> void:
	surface.draw_line(Vector2(42, y), Vector2(598, y), Color("19252c"), 3.0)
	surface.draw_line(Vector2(46, y), Vector2(594, y), BORDER, 1.0)

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
