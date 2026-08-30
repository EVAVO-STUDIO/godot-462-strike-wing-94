extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const PixelUiSurface = preload("res://scripts/pixel_ui_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v1.png")
const VX94_FIGHTER := preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png")
const VX94_BOMBER := preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png")
const SORTIE_BAY_BACKDROP := preload("res://assets/runtime/ui/menu/sortie_bay_backdrop_v1.png")
const OPERATIONS_PANEL := preload("res://assets/runtime/ui/menu/operations_panel_9slice.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_screen_9slice.png")
const OPERATIONS_BUTTON := preload("res://assets/runtime/ui/menu/operations_button_9slice.png")
const FRONT_END_FRAME := preload("res://assets/runtime/ui/menu/front_end/frame.png")
const FRONT_END_BUTTON_IDLE := preload("res://assets/runtime/ui/menu/front_end/button_idle.png")
const FRONT_END_BUTTON_SELECTED := preload("res://assets/runtime/ui/menu/front_end/button_selected.png")
const FRONT_END_CURSOR := preload("res://assets/runtime/ui/menu/front_end/cursor.png")
const OPTIONS_ROW_IDLE := preload("res://assets/runtime/ui/menu/system_options/row_idle.png")
const OPTIONS_ROW_SELECTED := preload("res://assets/runtime/ui/menu/system_options/row_selected.png")
const OPTIONS_VALUE_TROUGH := preload("res://assets/runtime/ui/menu/system_options/value_trough.png")
const OPTIONS_VALUE_FILL := preload("res://assets/runtime/ui/menu/system_options/value_fill.png")
const OPTIONS_TOGGLE_OFF := preload("res://assets/runtime/ui/menu/system_options/toggle_off.png")
const OPTIONS_TOGGLE_ON := preload("res://assets/runtime/ui/menu/system_options/toggle_on.png")
const CAMPAIGN_PROGRESS_RAIL := preload("res://assets/runtime/ui/menu/campaign_progress/rail.png")
const CAMPAIGN_NODE_COMPLETE := preload("res://assets/runtime/ui/menu/campaign_progress/node_complete.png")
const CAMPAIGN_NODE_CURRENT := preload("res://assets/runtime/ui/menu/campaign_progress/node_current.png")
const CAMPAIGN_NODE_LOCKED := preload("res://assets/runtime/ui/menu/campaign_progress/node_locked.png")
const PANEL_HEADER_RULE := preload("res://assets/runtime/ui/menu/panel_header_rule.png")
const PANEL_STATUS_LAMP := preload("res://assets/runtime/ui/menu/panel_status_lamp.png")
const REPORT_DIVIDER := preload("res://assets/runtime/ui/menu/report_divider.png")
const REPORT_BADGES := {
	"C": preload("res://assets/runtime/ui/menu/mission_report/badge_c.png"),
	"B": preload("res://assets/runtime/ui/menu/mission_report/badge_b.png"),
	"A": preload("res://assets/runtime/ui/menu/mission_report/badge_a.png"),
	"S": preload("res://assets/runtime/ui/menu/mission_report/badge_s.png"),
}
const REPORT_FAILURE_BADGE := preload("res://assets/runtime/ui/menu/mission_report/badge_failure.png")
const REPORT_STAT_FRAME := preload("res://assets/runtime/ui/menu/mission_report/stat_frame.png")
const REPORT_ACCURACY_TROUGH := preload("res://assets/runtime/ui/menu/mission_report/accuracy_trough.png")
const REPORT_ACCURACY_FILL := preload("res://assets/runtime/ui/menu/mission_report/accuracy_fill.png")
const REPORT_METRIC_CELL := preload("res://assets/runtime/ui/menu/mission_report/metrics/cell.png")
const REPORT_METRIC_ICONS := {
	"targets": preload("res://assets/runtime/ui/menu/mission_report/metrics/icon_targets.png"),
	"damage": preload("res://assets/runtime/ui/menu/mission_report/metrics/icon_damage.png"),
	"secret": preload("res://assets/runtime/ui/menu/mission_report/metrics/icon_secret.png"),
	"repair": preload("res://assets/runtime/ui/menu/mission_report/metrics/icon_repair.png"),
}
const HUD_TOP_FRAME := preload("res://assets/runtime/ui/hud/top_frame.png")
const HUD_METER_TROUGH := preload("res://assets/runtime/ui/hud/meter_trough.png")
const HUD_HULL_FILL := preload("res://assets/runtime/ui/hud/hull_fill.png")
const HUD_SHIELD_FILL := preload("res://assets/runtime/ui/hud/shield_fill.png")
const HUD_ENERGY_FILL := preload("res://assets/runtime/ui/hud/energy_fill.png")
const HUD_HULL_FRAME := preload("res://assets/runtime/ui/hud/primary_meter_cluster/hull_frame.png")
const HUD_SHIELD_FRAME := preload("res://assets/runtime/ui/hud/primary_meter_cluster/shield_frame.png")
const HUD_ENERGY_FRAME := preload("res://assets/runtime/ui/hud/primary_meter_cluster/energy_frame.png")
const HUD_HULL_WARNING_FRAME := preload("res://assets/runtime/ui/hud/primary_meter_cluster/hull_warning_frame.png")
const HUD_SHIELD_WARNING_FRAME := preload("res://assets/runtime/ui/hud/primary_meter_cluster/shield_warning_frame.png")
const HUD_ENERGY_WARNING_FRAME := preload("res://assets/runtime/ui/hud/primary_meter_cluster/energy_warning_frame.png")
const HUD_STATUS_FRAME := preload("res://assets/runtime/ui/hud/status_frame.png")
const HUD_BOSS_FRAME := preload("res://assets/runtime/ui/hud/boss_frame.png")
const HUD_BOSS_TROUGH := preload("res://assets/runtime/ui/hud/boss_trough.png")
const HUD_BOSS_FILL := preload("res://assets/runtime/ui/hud/boss_fill.png")
const HUD_BOSS_PHASE_FRAMES := [
	preload("res://assets/runtime/ui/hud/boss_phase_bar/phase_1.png"),
	preload("res://assets/runtime/ui/hud/boss_phase_bar/phase_2.png"),
	preload("res://assets/runtime/ui/hud/boss_phase_bar/phase_3.png"),
]
const HUD_BOSS_PHASE_FILLS := [
	preload("res://assets/runtime/ui/hud/boss_phase_bar/phase_1_fill.png"),
	preload("res://assets/runtime/ui/hud/boss_phase_bar/phase_2_fill.png"),
	preload("res://assets/runtime/ui/hud/boss_phase_bar/phase_3_fill.png"),
]
const HUD_THREAT_FRAME := preload("res://assets/runtime/ui/hud/threat_frame.png")
const HUD_ICON_BOMB := preload("res://assets/runtime/ui/hud/icon_bomb.png")
const HUD_ICON_WAVE := preload("res://assets/runtime/ui/hud/icon_wave.png")
const HUD_ICON_TIME := preload("res://assets/runtime/ui/hud/icon_time.png")
const HUD_ICON_SCORE := preload("res://assets/runtime/ui/hud/icon_score.png")
const SUPPORT_LINK_TROUGH := preload("res://assets/runtime/ui/hud/support_link/trough.png")
const SUPPORT_LINK_TACTICAL_FILL := preload("res://assets/runtime/ui/hud/support_link/tactical_fill.png")
const SUPPORT_LINK_BATTLEFIELD_FILL := preload("res://assets/runtime/ui/hud/support_link/battlefield_fill.png")
const SUPPORT_LINK_READY := preload("res://assets/runtime/ui/hud/support_link/ready.png")
const SUPPORT_LINK_CHARGING := preload("res://assets/runtime/ui/hud/support_link/charging.png")
const SUPPORT_LINK_UNAVAILABLE := preload("res://assets/runtime/ui/hud/support_link/unavailable.png")
const MISSION_INGRESS_FRAME := preload("res://assets/runtime/ui/hud/mission_ingress/frame.png")
const OBJECTIVE_REQUIRED := preload("res://assets/runtime/ui/hud/mission_ingress/objective_required.png")
const OBJECTIVE_BONUS := preload("res://assets/runtime/ui/hud/mission_ingress/objective_bonus.png")
const OBJECTIVE_TRACKER_FRAME := preload("res://assets/runtime/ui/hud/objective_tracker/frame.png")
const OBJECTIVE_TRACKER_TROUGH := preload("res://assets/runtime/ui/hud/objective_tracker/trough.png")
const OBJECTIVE_TRACKER_REQUIRED_FILL := preload("res://assets/runtime/ui/hud/objective_tracker/required_fill.png")
const OBJECTIVE_TRACKER_BONUS_FILL := preload("res://assets/runtime/ui/hud/objective_tracker/bonus_fill.png")
const SECRET_DISCOVERY_FRAME := preload("res://assets/runtime/ui/hud/secret_discovery/frame.png")
const SECRET_DISCOVERY_FX := [
	preload("res://assets/runtime/ui/hud/secret_discovery/fx_0.png"),
	preload("res://assets/runtime/ui/hud/secret_discovery/fx_1.png"),
	preload("res://assets/runtime/ui/hud/secret_discovery/fx_2.png"),
	preload("res://assets/runtime/ui/hud/secret_discovery/fx_3.png"),
]
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
const TEXT := Color("d9e0e5")
const MUTED := Color("7f909b")
const GOLD := Color("e8ca6a")
const GREEN := Color("67c3a5")
const RED := Color("dc6655")
const BLUE := Color("6aa4c8")
const INGRESS_SECONDS := 3.2

var _surface: Control
var _last_phase := -1
var _last_mission_index := -1
var _ingress_time := 0.0

func _ready() -> void:
	layer = 30
	_surface = PixelUiSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != null and _supports(scene):
		var phase := int(scene.get("phase"))
		var mission_index := int(scene.get("mission_index")) if _has_property(scene, "mission_index") else 0
		if phase == 1 and (_last_phase != 1 or mission_index != _last_mission_index):
			_ingress_time = INGRESS_SECONDS
		elif phase == 1:
			_ingress_time = maxf(0.0, _ingress_time - maxf(0.0, delta))
		else:
			_ingress_time = 0.0
		_last_phase = phase
		_last_mission_index = mission_index
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
	var front_end := str(scene.get("front_end_screen")) if _has_property(scene, "front_end_screen") else "sortie"
	if front_end != "sortie":
		_draw_front_end(surface, scene, front_end)
		return
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	surface.draw_texture_rect(SORTIE_BAY_BACKDROP, Rect2(0,0,640,360), false, Color(0.78,0.86,0.88,0.88))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.025,0.035,0.42))
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(195, 18, 250, 32), false)
	PixelFont.draw_centered(surface, _identity_subtitle(), 320, 53, 1, BLUE, 1)
	var mission_index := clampi(int(scene.get("mission_index")) if _has_property(scene, "mission_index") else 0, 0, 29)
	_draw_console_panel(surface, Rect2(26, 72, 370, 119), _sortie_order_header(mission_index), GOLD)
	PixelFont.draw_text(surface, str(scene.get("current_mission_name")), Vector2(40, 94), 2, GOLD, 2)
	PixelFont.draw_text(surface, "%s // %s // %s" % [_altitude_name(), _form_name(), _tech_era_name()], Vector2(40, 117), 1, BLUE, 1)
	var briefing := str(scene.get("current_briefing"))
	var lines := _wrap_text(briefing, 49)
	for i in range(mini(2, lines.size())):
		PixelFont.draw_text(surface, lines[i], Vector2(40, 139 + i * 11), 1, MUTED, 1)
	PixelFont.draw_text(surface, "INGRESS", Vector2(40, 170), 1, MUTED, 1)
	PixelFont.draw_text(surface, "HIGH-SPEED / LOW-LEVEL RELEASE", Vector2(105, 170), 1, GREEN, 1)
	_draw_campaign_progress(surface, mission_index, Vector2(40, 180))

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

func _draw_front_end(surface: CanvasItem, scene: Object, screen: String) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	surface.draw_texture_rect(SORTIE_BAY_BACKDROP, Rect2(0,0,640,360), false, Color(0.55,0.64,0.68,0.70))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.02,0.03,0.52))
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(70, 28, 500, 64), false)
	PixelFont.draw_centered(surface, _identity_subtitle(), 320, 102, 1, BLUE, 1)
	if screen == "controls":
		_draw_front_end_controls(surface)
	elif screen == "options":
		_draw_front_end_options(surface, scene)
	elif screen == "dossier":
		_draw_front_end_dossier(surface)
	else:
		_draw_front_end_main(surface, scene)
	PixelFont.draw_centered(surface, "%s // %s %s" % [_identity_text("developer", "EVAVO STUDIO"), _identity_title(), _identity_text("version", "0.0.0-DEV")], 320, 334, 1, MUTED, 1)

func _draw_front_end_main(surface: CanvasItem, scene: Object) -> void:
	surface.draw_texture(FRONT_END_FRAME, Vector2(30, 128))
	PixelFont.draw_text(surface, "FLIGHT OPERATIONS", Vector2(48, 137), 1, GOLD, 1)
	var selection := clampi(int(scene.get("menu_selection")) if _has_property(scene, "menu_selection") else 0, 0, 4)
	var labels := ["CONTINUE CAMPAIGN", "SYSTEM OPTIONS", "FLIGHT CONTROLS", "EVAVO DOSSIER", "EXIT TO SYSTEM"]
	for index in range(labels.size()):
		var position := Vector2(50, 154 + index * 27)
		surface.draw_texture(FRONT_END_BUTTON_SELECTED if index == selection else FRONT_END_BUTTON_IDLE, position)
		if index == selection:
			surface.draw_texture(FRONT_END_CURSOR, position + Vector2(-16, 6))
		PixelFont.draw_text(surface, labels[index], position + Vector2(18, 8), 1, GOLD if index == selection else TEXT, 1)
	_draw_console_panel(surface, Rect2(336, 128, 274, 170), "CAMPAIGN STATUS", BLUE)
	var mission_index := clampi(int(scene.get("mission_index")) if _has_property(scene, "mission_index") else 0, 0, 29)
	var craft := VX94_FIGHTER if _form_name() == "FIGHTER" else VX94_BOMBER
	surface.draw_texture_rect(craft, Rect2(352, 151, 96, 108), false)
	PixelFont.draw_text(surface, "VX-94", Vector2(464, 154), 2, TEXT, 1)
	PixelFont.draw_text(surface, "MISSION %02d / 30" % (mission_index + 1), Vector2(464, 181), 1, GOLD, 1)
	PixelFont.draw_text(surface, _front_end_sector(mission_index), Vector2(464, 197), 1, BLUE, 1)
	PixelFont.draw_text(surface, _clip(str(scene.get("current_mission_name")), 20), Vector2(464, 217), 1, GREEN, 1)
	PixelFont.draw_text(surface, "%s // %s" % [_short_altitude(), _short_form()], Vector2(464, 238), 1, MUTED, 1)
	PixelFont.draw_text(surface, "ENTER SELECT", Vector2(464, 274), 1, GOLD, 1)

func _draw_front_end_controls(surface: CanvasItem) -> void:
	surface.draw_texture(FRONT_END_FRAME, Vector2(176, 128))
	PixelFont.draw_centered(surface, "FLIGHT CONTROLS", 320, 139, 1, GOLD, 1)
	var lines := ["ARROWS / WASD   MANEUVER", "SPACE           PRIMARY FIRE", "X               SECONDARY", "Q               WING GEOMETRY", "SHIFT           AFTERBURNER", "Z / F           TACTICAL / ALLIED", "ENTER / ESC     CONFIRM / RETURN"]
	for index in range(lines.size()):
		PixelFont.draw_text(surface, lines[index], Vector2(198, 162 + index * 17), 1, TEXT if index < 4 else BLUE, 1)
	PixelFont.draw_centered(surface, "ENTER / ESC RETURN", 320, 281, 1, GOLD, 1)

func _draw_front_end_options(surface: CanvasItem, scene: Object) -> void:
	var settings := get_node_or_null("/root/SettingsDirector")
	var selection := clampi(int(scene.get("option_selection")) if _has_property(scene, "option_selection") else 0, 0, 3)
	PixelFont.draw_centered(surface, "SYSTEM OPTIONS", 320, 128, 1, GOLD, 1)
	PixelFont.draw_centered(surface, "VIDEO // AUDIO // CONTROL // ACCESSIBILITY", 320, 141, 1, BLUE, 1)
	for index in range(4):
		var position := Vector2(100, 154 + index * 35)
		surface.draw_texture(OPTIONS_ROW_SELECTED if index == selection else OPTIONS_ROW_IDLE, position)
		if index == selection:
			surface.draw_texture(FRONT_END_CURSOR, position + Vector2(-16, 6))
		var label := str(settings.call("setting_label", index)) if settings != null and settings.has_method("setting_label") else "OPTION"
		var value := str(settings.call("setting_value", index)) if settings != null and settings.has_method("setting_value") else "--"
		var ratio := float(settings.call("setting_ratio", index)) if settings != null and settings.has_method("setting_ratio") else 0.0
		PixelFont.draw_text(surface, label, position + Vector2(18, 9), 1, GOLD if index == selection else TEXT, 1)
		if index in [0, 3]:
			surface.draw_texture(OPTIONS_TOGGLE_ON if ratio >= 0.5 else OPTIONS_TOGGLE_OFF, position + Vector2(306, 8))
		else:
			surface.draw_texture(OPTIONS_VALUE_TROUGH, position + Vector2(286, 11))
			_draw_clipped_fill(surface, OPTIONS_VALUE_FILL, position + Vector2(288, 13), ratio)
		PixelFont.draw_text(surface, value, position + Vector2(382 - PixelFont.text_width(value, 1, 1), 9), 1, GREEN if ratio >= 0.5 else MUTED, 1)
	PixelFont.draw_centered(surface, "LEFT / RIGHT ADJUST   ESC RETURN", 320, 305, 1, MUTED, 1)

func _draw_front_end_dossier(surface: CanvasItem) -> void:
	surface.draw_texture(FRONT_END_FRAME, Vector2(176, 128))
	PixelFont.draw_centered(surface, "EVAVO DOSSIER", 320, 139, 1, GOLD, 1)
	PixelFont.draw_centered(surface, "HYPERSONIC", 320, 169, 2, TEXT, 1)
	PixelFont.draw_centered(surface, "VX-94 VARIABLE STRIKE FIGHTER", 320, 194, 1, BLUE, 1)
	PixelFont.draw_centered(surface, "DEVELOPED AND PUBLISHED BY", 320, 222, 1, MUTED, 1)
	PixelFont.draw_centered(surface, _identity_text("developer", "EVAVO STUDIO"), 320, 241, 2, GOLD, 1)
	PixelFont.draw_centered(surface, "ENTER / ESC RETURN", 320, 281, 1, GREEN, 1)

func _front_end_sector(mission_index: int) -> String:
	if mission_index >= 20: return "S3 BLACK SKY"
	if mission_index >= 10: return "S2 MACHINE WAR"
	return "S1 MERCENARY WAR"

func _sortie_order_header(mission_index: int) -> String:
	var sector := clampi(int(mission_index / 10), 0, 2)
	var sector_names := ["MERCENARY WAR", "MACHINE WAR", "BLACK SKY"]
	return "MISSION %02d / S%d %s" % [mission_index + 1, sector + 1, sector_names[sector]]

func _draw_campaign_progress(surface: CanvasItem, mission_index: int, position: Vector2) -> void:
	surface.draw_texture(CAMPAIGN_PROGRESS_RAIL, position)
	for index in range(30):
		var sector_gap := int(index / 10) * 5
		var node_position := position + Vector2(3 + index * 11 + sector_gap, 2)
		var node: Texture2D = CAMPAIGN_NODE_CURRENT if index == mission_index else (CAMPAIGN_NODE_COMPLETE if index < mission_index else CAMPAIGN_NODE_LOCKED)
		surface.draw_texture(node, node_position)

func _draw_result(surface: CanvasItem, scene: Object) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	surface.draw_texture_rect(SORTIE_BAY_BACKDROP, Rect2(0,0,640,360), false, Color(0.62,0.70,0.73,0.72))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.02,0.03,0.66))
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	var mission_success := bool(scene.get("mission_success")) if _has_property(scene, "mission_success") else true
	PixelFont.draw_centered(surface, "MISSION REPORT" if mission_success else "SORTIE FAILURE", 320, 35, 3, GOLD if mission_success else RED, 2)

	var result_lines := _wrap_text(str(scene.get("result_text")), 66)
	for i in range(mini(3, result_lines.size())):
		PixelFont.draw_centered(surface, result_lines[i], 320, 73 + i * 11, 1, TEXT, 1)
	_draw_divider(surface, 118)

	var fired := int(scene.get("shots_fired")) if _has_property(scene, "shots_fired") else 0
	var hits := clampi(int(scene.get("shots_hit")), 0, fired) if fired > 0 else 0
	var accuracy := int(round(float(hits) / float(fired) * 100.0)) if fired > 0 else 0
	var grade := _sortie_grade(accuracy) if mission_success else "X"
	var grade_color := _sortie_grade_color(grade) if mission_success else RED
	surface.draw_texture(REPORT_STAT_FRAME, Vector2(48, 139))
	surface.draw_texture(REPORT_STAT_FRAME, Vector2(400, 139))
	PixelFont.draw_centered(surface, "COMBAT SCORE", 144, 148, 1, MUTED, 1)
	PixelFont.draw_centered(surface, "%08d" % int(scene.get("score")), 144, 165, 2, TEXT, 1)
	PixelFont.draw_centered(surface, "ACCOUNT CREDIT", 496, 148, 1, MUTED, 1)
	PixelFont.draw_centered(surface, "%06d" % int(scene.get("credits")), 496, 165, 2, GOLD, 1)

	PixelFont.draw_centered(surface, "STRIKE RATING", 320, 128, 1, grade_color, 1)
	surface.draw_texture(REPORT_BADGES.get(grade, REPORT_BADGES["C"]) if mission_success else REPORT_FAILURE_BADGE, Vector2(280, 134))
	PixelFont.draw_centered(surface, grade, 320, 156, 3, TEXT, 2)
	PixelFont.draw_centered(surface, _sortie_grade_label(grade) if mission_success else "AIRFRAME RECOVERY REQUIRED", 320, 198, 1, grade_color, 1)

	_draw_report_metric(surface, Vector2(40, 208), "targets", "TARGETS", int(scene.get("targets_destroyed")) if _has_property(scene, "targets_destroyed") else 0, TEXT)
	_draw_report_metric(surface, Vector2(184, 208), "damage", "DAMAGE", int(scene.get("damage_taken")) if _has_property(scene, "damage_taken") else 0, RED)
	_draw_report_metric(surface, Vector2(328, 208), "secret", "VECTORS", int(scene.get("secrets_discovered")) if _has_property(scene, "secrets_discovered") else 0, GREEN)
	_draw_report_metric(surface, Vector2(472, 208), "repair", "REPAIR", int(scene.get("repair_cost")) if _has_property(scene, "repair_cost") else 0, GOLD)
	PixelFont.draw_centered(surface, "WEAPON ACCURACY %03d%%" % accuracy, 320, 240, 1, GREEN, 1)
	surface.draw_texture(REPORT_ACCURACY_TROUGH, Vector2(140, 251))
	_draw_clipped_fill(surface, REPORT_ACCURACY_FILL, Vector2(144, 255), float(accuracy) / 100.0)
	PixelFont.draw_centered(surface, "CONFIRMED HITS %04d / ROUNDS %04d   %s" % [hits, fired, _objective_report(scene)], 320, 270, 1, MUTED, 1)
	PixelFont.draw_centered(surface, "%s   %s   %s" % [_altitude_name(), _form_name(), _tech_era_name()], 320, 286, 1, BLUE, 1)

	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_BUTTON, Rect2(26, 306, 588, 27), 6)
	PixelFont.draw_text(surface, ">>", Vector2(40, 315), 1, RED, 1)
	PixelFont.draw_centered(surface, "ENTER NEXT MISSION   R RETRY" if mission_success else "ENTER / R RETRY SORTIE", 320, 315, 1, TEXT, 1)

func _draw_report_metric(surface: CanvasItem, position: Vector2, icon_key: String, label: String, value: int, color: Color) -> void:
	surface.draw_texture(REPORT_METRIC_CELL, position)
	surface.draw_texture(REPORT_METRIC_ICONS[icon_key], position + Vector2(10, 7))
	PixelFont.draw_text(surface, label, position + Vector2(28, 5), 1, MUTED, 1)
	PixelFont.draw_text(surface, "%05d" % maxi(0, value), position + Vector2(28, 15), 1, color, 1)

func _objective_report(scene: Object) -> String:
	var objectives: Array = scene.get("current_objectives") if _has_property(scene, "current_objectives") else []
	var progress: Dictionary = scene.get("objective_progress") if _has_property(scene, "objective_progress") and typeof(scene.get("objective_progress")) == TYPE_DICTIONARY else {}
	var complete := 0
	for objective in objectives:
		if typeof(objective) == TYPE_DICTIONARY and ObjectiveRules.is_complete(objective, progress):
			complete += 1
	return "OBJECTIVES %d/%d" % [complete, objectives.size()]

func _sortie_grade(accuracy: int) -> String:
	if accuracy >= 90: return "S"
	if accuracy >= 75: return "A"
	if accuracy >= 55: return "B"
	return "C"

func _sortie_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color("62b9be")
		"A": return Color("e0bd59")
		"B": return Color("8ca2ad")
	return Color("9a7250")

func _sortie_grade_label(grade: String) -> String:
	match grade:
		"S": return "BLACK SKY QUALIFIED"
		"A": return "PRECISION STRIKE"
		"B": return "COMBAT EFFECTIVE"
	return "SORTIE COMPLETE"

func _identity_title() -> String:
	var identity := get_node_or_null("/root/ProductIdentity")
	return str(identity.call("title_primary")) if identity != null and identity.has_method("title_primary") else "HYPERSONIC"

func _identity_text(key: String, fallback: String) -> String:
	var identity := get_node_or_null("/root/ProductIdentity")
	return str(identity.call("text", key, fallback)).to_upper() if identity != null and identity.has_method("text") else fallback

func _identity_subtitle() -> String:
	var identity := get_node_or_null("/root/ProductIdentity")
	return str(identity.call("title_subtitle")) if identity != null and identity.has_method("title_subtitle") else "VX-94 VARIABLE STRIKE FIGHTER"

func _draw_gameplay_hud(surface: CanvasItem, scene: Object) -> void:
	surface.draw_texture(HUD_TOP_FRAME, Vector2(8, 8))
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	var generator := _call_dictionary(scene, "_active_generator")
	var energy := float(scene.get("energy")) if _has_property(scene, "energy") else 0.0
	_draw_primary_meter(surface, Vector2(12, 11), int(scene.get("hull")), max_hull, HUD_HULL_FILL, HUD_HULL_FRAME, HUD_HULL_WARNING_FRAME, 0.30)
	_draw_primary_meter(surface, Vector2(108, 11), int(scene.get("shield")), maxi(1, max_shield), HUD_SHIELD_FILL, HUD_SHIELD_FRAME, HUD_SHIELD_WARNING_FRAME, 0.24)
	_draw_primary_meter(surface, Vector2(204, 11), int(round(energy)), maxi(1, int(round(EnergyRules.capacity(generator)))), HUD_ENERGY_FILL, HUD_ENERGY_FRAME, HUD_ENERGY_WARNING_FRAME, 0.18)
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
	PixelFont.draw_text(surface, _clip(_support_name(), 14), Vector2(422, 38), 1, GREEN, 1)
	PixelFont.draw_text(surface, _clip(_battlefield_support_name(), 16), Vector2(518, 38), 1, BLUE, 1)
	_draw_support_links(surface)
	_draw_boss(surface, scene)
	_draw_threat(surface, scene)
	_draw_mission_ingress(surface, scene)
	_draw_objective_tracker(surface, scene)
	if float(scene.get("status_timer")) > 0.0:
		var status := str(scene.get("status_text"))
		if status.begins_with("SECRET - "):
			_draw_secret_discovery(surface, status, float(scene.get("status_timer")))
		else:
			surface.draw_texture(HUD_STATUS_FRAME, Vector2(116, 330))
			PixelFont.draw_centered(surface, _clip(status, 70), 320, 336, 1, GOLD, 1)

func _draw_secret_discovery(surface: CanvasItem, status: String, remaining: float) -> void:
	var position := Vector2(120, 108)
	var age := maxf(0.0, 2.4 - remaining)
	var frame_index := posmod(int(floor(age * 5.0)), SECRET_DISCOVERY_FX.size())
	var reveal_step := clampi(int(floor(age / 0.045)), 0, 4)
	position.y -= float(4 - reveal_step) * 2.0
	surface.draw_texture(SECRET_DISCOVERY_FRAME, position)
	surface.draw_texture(SECRET_DISCOVERY_FX[frame_index], position)
	PixelFont.draw_text(surface, "ENCRYPTED VECTOR // ACQUIRED", position + Vector2(46, 8), 1, BLUE, 1)
	PixelFont.draw_text(surface, _clip(status.trim_prefix("SECRET - "), 45), position + Vector2(46, 25), 2, GOLD, 1)

func _draw_mission_ingress(surface: CanvasItem, scene: Object) -> void:
	if _ingress_time <= 0.0:
		return
	var age := INGRESS_SECONDS - _ingress_time
	var frame_step := clampi(int(floor(age / 0.045)), 0, 4)
	var y := 116.0 - float(4 - frame_step) * 2.0
	var alpha := clampf(age / 0.16, 0.0, 1.0) * clampf(_ingress_time / 0.28, 0.0, 1.0)
	var tint := Color(1, 1, 1, alpha)
	surface.draw_texture(MISSION_INGRESS_FRAME, Vector2(116, y), tint)
	PixelFont.draw_text(surface, "MISSION DATA // INGRESS", Vector2(128, y + 7), 1, Color(GOLD, alpha), 1)
	PixelFont.draw_text(surface, "%s // %s" % [_short_altitude(), _short_form()], Vector2(448, y + 7), 1, Color(BLUE, alpha), 1)
	PixelFont.draw_centered(surface, _clip(str(scene.get("current_mission_name")), 34), 320, y + 18, 2, Color(TEXT, alpha), 1)
	var objective := _primary_objective(scene)
	var required := bool(objective.get("required", true))
	surface.draw_texture(OBJECTIVE_REQUIRED if required else OBJECTIVE_BONUS, Vector2(128, y + 31), tint)
	PixelFont.draw_text(surface, _objective_line(scene, objective), Vector2(144, y + 34), 1, Color(GREEN if required else GOLD, alpha), 1)

func _primary_objective(scene: Object) -> Dictionary:
	if not _has_property(scene, "current_objectives"):
		return {"id":"mission", "label":"COMPLETE AUTHORIZED OBJECTIVES", "required":true}
	var objectives = scene.get("current_objectives")
	if typeof(objectives) != TYPE_ARRAY:
		return {"id":"mission", "label":"COMPLETE AUTHORIZED OBJECTIVES", "required":true}
	for objective in objectives:
		if typeof(objective) == TYPE_DICTIONARY and bool(objective.get("required", true)):
			return objective
	for objective in objectives:
		if typeof(objective) == TYPE_DICTIONARY:
			return objective
	return {"id":"mission", "label":"COMPLETE AUTHORIZED OBJECTIVES", "required":true}

func _tracked_objective(scene: Object) -> Dictionary:
	if not _has_property(scene, "current_objectives"):
		return {}
	var objectives = scene.get("current_objectives")
	var progress: Dictionary = scene.get("objective_progress") if _has_property(scene, "objective_progress") and typeof(scene.get("objective_progress")) == TYPE_DICTIONARY else {}
	if typeof(objectives) != TYPE_ARRAY:
		return {}
	for required_state in [true, false]:
		for objective in objectives:
			if typeof(objective) == TYPE_DICTIONARY and bool(objective.get("required", true)) == required_state and not ObjectiveRules.is_complete(objective, progress):
				return objective
	return {}

func _objective_ratio(scene: Object, objective: Dictionary) -> float:
	var progress: Dictionary = scene.get("objective_progress") if _has_property(scene, "objective_progress") and typeof(scene.get("objective_progress")) == TYPE_DICTIONARY else {}
	var value := float(progress.get(str(objective.get("id", "")), 0.0))
	var target := float(objective.get("seconds", objective.get("count", 1)))
	return clampf(value / maxf(1.0, target), 0.0, 1.0)

func _has_threat_warning(scene: Object) -> bool:
	var bullets: Array = scene.get("enemy_bullets")
	var player_position: Vector2 = scene.get("player_position")
	return ThreatWarningRules.warning_text(ThreatWarningRules.nearest_homing_distance(bullets, player_position), ThreatWarningRules.homing_count(bullets)) != ""

func _draw_objective_tracker(surface: CanvasItem, scene: Object) -> void:
	if _ingress_time > 0.0 or not _active_boss(scene).is_empty() or _has_threat_warning(scene):
		return
	var battlefield_support := get_node_or_null("/root/BattlefieldSupportDirector")
	if battlefield_support != null and battlefield_support.has_method("active_support_id") and str(battlefield_support.call("active_support_id")) == "atlas_tanker":
		return
	var objective := _tracked_objective(scene)
	if objective.is_empty():
		return
	var required := bool(objective.get("required", true))
	var position := Vector2(140, 64)
	surface.draw_texture(OBJECTIVE_TRACKER_FRAME, position)
	surface.draw_texture(OBJECTIVE_REQUIRED if required else OBJECTIVE_BONUS, position + Vector2(10, 7))
	PixelFont.draw_text(surface, _objective_line(scene, objective), position + Vector2(28, 8), 1, GREEN if required else GOLD, 1)
	surface.draw_texture(OBJECTIVE_TRACKER_TROUGH, position + Vector2(14, 20))
	_draw_clipped_fill(surface, OBJECTIVE_TRACKER_REQUIRED_FILL if required else OBJECTIVE_TRACKER_BONUS_FILL, position + Vector2(15, 21), _objective_ratio(scene, objective))

func _objective_line(scene: Object, objective: Dictionary) -> String:
	var label := str(objective.get("label", objective.get("id", "OBJECTIVE"))).to_upper().replace("_", " ")
	var progress: Dictionary = scene.get("objective_progress") if _has_property(scene, "objective_progress") and typeof(scene.get("objective_progress")) == TYPE_DICTIONARY else {}
	var progress_text := ObjectiveRules.progress_text(objective, progress) if not objective.is_empty() else ""
	var prefix := "REQ" if bool(objective.get("required", true)) else "BONUS"
	return _clip("%s %s  %s" % [prefix, label, progress_text], 58)

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
	var phase_index := clampi(phase - 1, 0, HUD_BOSS_PHASE_FRAMES.size() - 1)
	surface.draw_texture(HUD_BOSS_PHASE_FRAMES[phase_index], Vector2(126, 64))
	PixelFont.draw_centered(surface, "%s  P%d%s  %d/%d" % [str(boss.get("id", "BOSS")).replace("_", " "), phase, cue, hp, max_hp], 320, 69, 1, TEXT, 1)
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	surface.draw_texture(HUD_BOSS_TROUGH, Vector2(143, 80))
	_draw_clipped_fill(surface, HUD_BOSS_PHASE_FILLS[phase_index], Vector2(144, 81), ratio)

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

func _draw_support_links(surface: CanvasItem) -> void:
	var tactical := get_node_or_null("/root/SupportDirector")
	var tactical_ratio := float(tactical.call("readiness_ratio")) if tactical != null and tactical.has_method("readiness_ratio") else 0.0
	_draw_support_link(surface, Vector2(410, 48), tactical_ratio, true, tactical != null)
	var battlefield := get_node_or_null("/root/BattlefieldSupportDirector")
	var battlefield_ratio := float(battlefield.call("readiness_ratio")) if battlefield != null and battlefield.has_method("readiness_ratio") else 0.0
	var battlefield_available := bool(battlefield.call("support_available")) if battlefield != null and battlefield.has_method("support_available") else false
	_draw_support_link(surface, Vector2(508, 48), battlefield_ratio, false, battlefield_available)

func _draw_support_link(surface: CanvasItem, position: Vector2, ratio: float, tactical: bool, available: bool) -> void:
	var safe_ratio := clampf(ratio, 0.0, 1.0)
	var lamp: Texture2D = SUPPORT_LINK_UNAVAILABLE if not available else (SUPPORT_LINK_READY if safe_ratio >= 0.999 else SUPPORT_LINK_CHARGING)
	surface.draw_texture(lamp, position + Vector2(-10, -8))
	surface.draw_texture(SUPPORT_LINK_TROUGH, position)
	_draw_clipped_fill(surface, SUPPORT_LINK_TACTICAL_FILL if tactical else SUPPORT_LINK_BATTLEFIELD_FILL, position + Vector2(1, 1), safe_ratio)

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

func _draw_primary_meter(surface: CanvasItem, position: Vector2, current: int, maximum: int, fill_texture: Texture2D, normal_frame: Texture2D, warning_frame: Texture2D, warning_ratio: float) -> void:
	var max_value := maxi(1, maximum)
	var value := clampi(current, 0, max_value)
	var ratio := clampf(float(value) / float(max_value), 0.0, 1.0)
	var frame := warning_frame if ratio <= warning_ratio else normal_frame
	surface.draw_texture(frame, position)
	PixelFont.draw_text(surface, "%03d" % value, position + Vector2(25, 5), 1, RED if ratio <= warning_ratio else TEXT, 1)
	var instrument_width := floorf(67.0 * ratio)
	if instrument_width > 0.0:
		surface.draw_texture_rect_region(fill_texture, Rect2(position + Vector2(18,15),Vector2(instrument_width,fill_texture.get_height())),Rect2(0,0,instrument_width,fill_texture.get_height()))

func _draw_clipped_fill(surface: CanvasItem, texture: Texture2D, position: Vector2, ratio: float) -> void:
	var width := floorf(float(texture.get_width()) * clampf(ratio, 0.0, 1.0))
	if width <= 0.0:
		return
	surface.draw_texture_rect_region(texture, Rect2(position, Vector2(width, texture.get_height())), Rect2(0, 0, width, texture.get_height()))

func _draw_frame(surface: CanvasItem, rect: Rect2) -> void:
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_SCREEN, rect, 8)

func _draw_console_panel(surface: CanvasItem, rect: Rect2, label: String, accent: Color) -> void:
	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_PANEL, rect, 6)
	UiSpriteRenderer.draw_three_slice_horizontal(surface, PANEL_HEADER_RULE, Rect2(rect.position + Vector2(6, 15), Vector2(rect.size.x - 12, 3)), 4)
	surface.draw_texture(PANEL_STATUS_LAMP, rect.position + Vector2(3, 3), accent)
	PixelFont.draw_text(surface, label, rect.position + Vector2(14, 5), 1, accent, 1)

func _draw_divider(surface: CanvasItem, y: float) -> void:
	surface.draw_texture(REPORT_DIVIDER, Vector2(42, y - 2))

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
