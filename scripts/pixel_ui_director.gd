extends CanvasLayer

const PixelFont = preload("res://scripts/pixel_font.gd")
const PixelUiSurface = preload("res://scripts/pixel_ui_surface.gd")
const UiSpriteRenderer = preload("res://scripts/ui_sprite_renderer.gd")
const BossRules = preload("res://scripts/boss_rules.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
const ContentCatalog = preload("res://scripts/content_catalog.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const HYPERSONIC_WORDMARK := preload("res://assets/runtime/title/hypersonic_wordmark_v3.png")
const VX94_FIGHTER := preload("res://assets/runtime/craft/vx94/vx94_fighter_v1.png")
const VX94_BOMBER := preload("res://assets/runtime/craft/vx94/vx94_bomber_v1.png")
const VX94_MENU_PORTRAIT := preload("res://assets/runtime/craft/vx94/vx94_menu_portrait_fighter_v2.png")
const SORTIE_BAY_BACKDROP := preload("res://assets/runtime/ui/menu/maintenance_bay_v2.png")
const MAINTENANCE_BAY_ACTIVITY := [
	preload("res://assets/runtime/ui/menu/maintenance_bay_activity/activity_0.png"),
	preload("res://assets/runtime/ui/menu/maintenance_bay_activity/activity_1.png"),
	preload("res://assets/runtime/ui/menu/maintenance_bay_activity/activity_2.png"),
	preload("res://assets/runtime/ui/menu/maintenance_bay_activity/activity_3.png"),
]
const OPERATIONS_PANEL := preload("res://assets/runtime/ui/menu/operations_panel_9slice.png")
const OPERATIONS_SCREEN := preload("res://assets/runtime/ui/menu/operations_screen_9slice.png")
const OPERATIONS_BUTTON := preload("res://assets/runtime/ui/menu/operations_button_9slice.png")
const FRONT_END_FRAME := preload("res://assets/runtime/ui/menu/front_end/frame.png")
const FRONT_END_BUTTON_IDLE := preload("res://assets/runtime/ui/menu/front_end/button_idle.png")
const FRONT_END_BUTTON_SELECTED := preload("res://assets/runtime/ui/menu/front_end/button_selected.png")
const FRONT_END_CURSOR := preload("res://assets/runtime/ui/menu/front_end/cursor.png")
const MODE_EMBLEMS := {
	"arcade": preload("res://assets/runtime/ui/modes/arcade.png"),
	"boss": preload("res://assets/runtime/ui/modes/boss.png"),
	"hypersonic": preload("res://assets/runtime/ui/modes/hypersonic.png"),
	"strike": preload("res://assets/runtime/ui/modes/strike.png"),
}
const MODE_RUN_FRAME := preload("res://assets/runtime/ui/modes/mode_run_frame.png")
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
const HUD_TOP_FRAME := preload("res://assets/runtime/ui/hud/compact_combat_fascia.png")
const HUD_NOTIFICATION_FRAME := preload("res://assets/runtime/ui/hud/compact_notification_frame.png")
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
const HUD_THREAT_FRAMES := [
	preload("res://assets/runtime/ui/hud/threat_annunciator/tracking.png"),
	preload("res://assets/runtime/ui/hud/threat_annunciator/caution.png"),
	preload("res://assets/runtime/ui/hud/threat_annunciator/lock.png"),
]
const HUD_THREAT_APPROACH_TROUGH := preload("res://assets/runtime/ui/hud/threat_annunciator/approach_trough.png")
const HUD_THREAT_CAUTION_FILL := preload("res://assets/runtime/ui/hud/threat_annunciator/caution_fill.png")
const HUD_THREAT_LOCK_FILL := preload("res://assets/runtime/ui/hud/threat_annunciator/lock_fill.png")
const HUD_THREAT_MISSILE_ICON := preload("res://assets/runtime/ui/hud/threat_annunciator/missile_icon.png")
const HUD_RWR_BEARINGS := [
	preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_00.png"), preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_01.png"),
	preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_02.png"), preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_03.png"),
	preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_04.png"), preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_05.png"),
	preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_06.png"), preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_07.png"),
	preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_08.png"), preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_09.png"),
	preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_10.png"), preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_11.png"),
]
const HUD_RWR_SPIKE := preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/spike.png")
const HUD_RWR_HARD_LOCK := preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/hard_lock.png")
const HUD_RWR_MISSILE_INBOUND := preload("res://assets/runtime/ui/hud/rwr_aircraft_cues/missile_inbound.png")
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
const INGRESS_SECONDS := 1.10

var _surface: Control
var _last_phase := -1
var _last_mission_index := -1
var _ingress_time := 0.0
var _front_end_time := 0.0

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
	_front_end_time += maxf(0.0, delta)
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
		if phase == 1 and "--capture-gameplay" in OS.get_cmdline_user_args():
			var capture_state := _capture_hud_state()
			if capture_state == "ingress":
				_ingress_time = INGRESS_SECONDS * 0.62
			elif _capture_time() > INGRESS_SECONDS or capture_state == "objective":
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
	return SceneContractCache.supports(scene, ["phase", "credits", "mission_time", "mission_duration", "hull", "shield", "bombs", "wave", "score", "status_text", "status_timer", "enemies", "enemy_bullets", "player_position"])

func _draw_title(surface: CanvasItem, scene: Object) -> void:
	var front_end := str(scene.get("front_end_screen")) if _has_property(scene, "front_end_screen") else "sortie"
	if front_end != "sortie":
		_draw_front_end(surface, scene, front_end)
		return
	_draw_maintenance_bay(surface, 0.42, 0.88)
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(195, 14, 250, 40), false)
	PixelFont.draw_centered(surface, _identity_subtitle(), 320, 58, 1, BLUE, 1)
	var mission_index := clampi(int(scene.get("mission_index")) if _has_property(scene, "mission_index") else 0, 0, 29)
	var mode_active := _has_property(scene,"game_mode") and str(scene.get("game_mode")) != "campaign"
	var secret_active := _has_property(scene,"active_secret_mission_id") and not str(scene.get("active_secret_mission_id")).is_empty()
	var sortie_header := str(scene.get("mode_name")) if mode_active else (_secret_sortie_header(scene) if secret_active else _sortie_order_header(mission_index))
	_draw_console_panel(surface, Rect2(26, 72, 370, 119), sortie_header, GOLD)
	PixelFont.draw_text(surface, str(scene.get("current_mission_name")), Vector2(40, 94), 2, GOLD, 2)
	PixelFont.draw_text(surface, "%s // %s // %s" % [_altitude_name(), _form_name(), _tech_era_name()], Vector2(40, 117), 1, BLUE, 1)
	var briefing := str(scene.get("current_briefing"))
	var lines := _wrap_text(briefing, 49)
	for i in range(mini(2, lines.size())):
		PixelFont.draw_text(surface, lines[i], Vector2(40, 139 + i * 11), 1, MUTED, 1)
	PixelFont.draw_text(surface, "INGRESS", Vector2(40, 170), 1, MUTED, 1)
	PixelFont.draw_text(surface, "HIGH-SPEED / LOW-LEVEL RELEASE", Vector2(105, 170), 1, GREEN, 1)
	if mode_active:
		_draw_mode_progress(surface,int(scene.get("mode_route_index")),int(scene.get("mode_route_total")),Vector2(40,180))
	elif secret_active:
		_draw_mode_progress(surface,_secret_sortie_index(scene),maxi(1,scene.get("secret_mission_catalog").size()),Vector2(40,180))
	else:
		_draw_campaign_progress(surface, mission_index, Vector2(40, 180))

	_draw_console_panel(surface, Rect2(408, 72, 206, 119), "VX-94 AIRFRAME", BLUE)
	var craft := VX94_FIGHTER if _form_name() == "FIGHTER" else VX94_BOMBER
	# The registered 64x72 source includes safety margins for gameplay effects.
	# Give the inspection silhouette enough panel weight to read as an airframe,
	# while leaving the technical legend in its own clean right-hand column.
	surface.draw_texture_rect(craft, Rect2(412, 82, 80, 90), false)
	PixelFont.draw_text(surface, _form_name(), Vector2(493, 95), 1, TEXT, 1)
	PixelFont.draw_text(surface, _altitude_name(), Vector2(493, 109), 1, BLUE, 1)
	PixelFont.draw_text(surface, "GEOMETRY", Vector2(493, 129), 1, MUTED, 1)
	PixelFont.draw_text(surface, "VARIABLE", Vector2(493, 143), 1, GREEN, 1)
	PixelFont.draw_text(surface, "Q SWEEP", Vector2(493, 166), 1, GOLD, 1)

	_draw_console_panel(surface, Rect2(26, 203, 370, 93), "FIXED MODE STORES" if mode_active else "ARM / SERVICE", TEXT)
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

	_draw_console_panel(surface, Rect2(408, 203, 206, 93), "RUN STATE" if mode_active else "READINESS", TEXT)
	PixelFont.draw_text(surface, "TOTAL %08d" % int(scene.get("mode_total_score")) if mode_active else "CREDITS %06d" % int(scene.get("credits")), Vector2(422, 224), 1, TEXT, 1)
	var service_hull := int(scene.get("service_hull")) if _has_property(scene, "service_hull") else int(scene.get("hull"))
	var service_shield := int(scene.get("service_shield")) if _has_property(scene, "service_shield") else int(scene.get("shield"))
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	PixelFont.draw_text(surface, "LIVES %02d" % int(scene.get("mode_lives")) if mode_active else "H HULL   %03d/%03d" % [service_hull, max_hull], Vector2(422, 243), 1, GREEN, 1)
	PixelFont.draw_text(surface, str(scene.get("mode_rule_summary")) if mode_active else "J SHIELD %03d/%03d" % [service_shield, max_shield], Vector2(422, 258), 1, BLUE, 1)
	PixelFont.draw_text(surface, "FIXED LOADOUT" if mode_active else "L STORES SCHEMATIC", Vector2(422, 280), 1, MUTED, 1)

	UiSpriteRenderer.draw_nine_slice(surface, OPERATIONS_BUTTON, Rect2(26, 308, 588, 27), 6)
	PixelFont.draw_text(surface, ">>", Vector2(40, 317), 1, RED, 1)
	PixelFont.draw_centered(surface, "ENTER / START  AUTHORIZE LAUNCH", 320, 317, 1, GOLD, 1)
	if float(scene.get("status_timer")) > 0.0:
		PixelFont.draw_centered(surface, _clip(str(scene.get("status_text")), 72), 320, 340, 1, GREEN, 1)

func _draw_front_end(surface: CanvasItem, scene: Object, screen: String) -> void:
	_draw_maintenance_bay(surface, 0.39, 0.82)
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	# Keep the title authoritative without allowing it to consume half the screen.
	# Late-90s premium front ends used the logo as a masthead, then gave the hero
	# machine and the player's next decision room to breathe.
	surface.draw_texture_rect(HYPERSONIC_WORDMARK, Rect2(34, 18, 390, 62), false)
	PixelFont.draw_text(surface, _identity_subtitle(), Vector2(39, 84), 1, BLUE, 1)
	PixelFont.draw_text(surface, "TACTICAL FLIGHT OPERATIONS", Vector2(449, 35), 1, GOLD, 1)
	PixelFont.draw_text(surface, "SYSTEM  VX94-OPS", Vector2(449, 51), 1, MUTED, 1)
	surface.draw_rect(Rect2(36, 99, 568, 1), Color("6a8794"))
	surface.draw_rect(Rect2(36, 102, 568, 1), Color("203845"))
	if screen == "modes":
		_draw_front_end_modes(surface,scene)
	elif screen == "branch":
		_draw_front_end_branch(surface,scene)
	elif screen == "secret_sorties":
		_draw_front_end_secret_sorties(surface,scene)
	elif screen == "controls":
		_draw_front_end_controls(surface, scene)
	elif screen == "options":
		_draw_front_end_options(surface, scene)
	elif screen == "dossier":
		_draw_front_end_dossier(surface,scene)
	else:
		_draw_front_end_main(surface, scene)
	PixelFont.draw_centered(surface, "%s // %s %s" % [_identity_text("developer", "EVAVO STUDIO"), _identity_title(), _identity_text("version", "0.0.0-DEV")], 320, 334, 1, MUTED, 1)

func _draw_front_end_main(surface: CanvasItem, scene: Object) -> void:
	PixelFont.draw_text(surface, "FLIGHT OPERATIONS", Vector2(40, 116), 1, GOLD, 1)
	PixelFont.draw_text(surface, "SELECT COMMAND", Vector2(178, 116), 1, MUTED, 1)
	var selection := clampi(int(scene.get("menu_selection")) if _has_property(scene, "menu_selection") else 0, 0, 6)
	var labels := ["CONTINUE CAMPAIGN", "ARCADE / CHALLENGE", "SECRET OPERATIONS", "SYSTEM OPTIONS", "FLIGHT CONTROLS", "EVAVO DOSSIER", "EXIT TO SYSTEM"]
	for index in range(labels.size()):
		var position := Vector2(40, 133 + index * 27)
		if index == selection:
			surface.draw_rect(Rect2(position.x, position.y, 246, 22), Color("162b36"))
			surface.draw_rect(Rect2(position.x, position.y, 3, 22), GOLD)
			surface.draw_rect(Rect2(position.x + 4, position.y, 242, 1), Color("6a8794"))
		else:
			surface.draw_rect(Rect2(position.x + 8, position.y + 21, 238, 1), Color("203845"))
		if index == selection:
			surface.draw_texture(FRONT_END_CURSOR, position + Vector2(-17, 5))
		PixelFont.draw_text(surface, labels[index], position + Vector2(14, 7), 1, GOLD if index == selection else TEXT, 1)
	_draw_console_panel(surface, Rect2(310, 114, 294, 201), "CAMPAIGN STATUS", BLUE)
	var mission_index := clampi(int(scene.get("mission_index")) if _has_property(scene, "mission_index") else 0, 0, 29)
	surface.draw_texture(VX94_MENU_PORTRAIT, Vector2(322, 147))
	PixelFont.draw_text(surface, "VX-94", Vector2(451, 151), 2, TEXT, 1)
	PixelFont.draw_text(surface, "VARIABLE STRIKE", Vector2(451, 177), 1, BLUE, 1)
	PixelFont.draw_text(surface, "MISSION %02d / 30" % (mission_index + 1), Vector2(451, 202), 1, GOLD, 1)
	PixelFont.draw_text(surface, _front_end_sector(mission_index), Vector2(451, 219), 1, BLUE, 1)
	PixelFont.draw_text(surface, _clip(str(scene.get("current_mission_name")), 20), Vector2(451, 239), 1, GREEN, 1)
	PixelFont.draw_text(surface, "%s // %s" % [_short_altitude(), _short_form()], Vector2(451, 259), 1, MUTED, 1)
	if _has_property(scene, "campaign_completed") and bool(scene.get("campaign_completed")):
		var clear_count := maxi(1, int(scene.get("campaign_completions"))) if _has_property(scene, "campaign_completions") else 1
		PixelFont.draw_text(surface, "BLACK SKY CLEAR %02d" % clear_count, Vector2(451, 279), 1, GOLD, 1)
		var vector_count: int = scene.get("discovered_secret_ids").size() if _has_property(scene, "discovered_secret_ids") else 0
		PixelFont.draw_text(surface, "SECRETS %02d" % vector_count, Vector2(451, 296), 1, GREEN, 1)
	else:
		PixelFont.draw_text(surface, "ENTER  SELECT", Vector2(451, 288), 1, GOLD, 1)

func _draw_front_end_modes(surface: CanvasItem, scene: Object) -> void:
	var director := get_node_or_null("/root/GameModeDirector")
	var modes: Array = director.call("modes") if director != null and director.has_method("modes") else []
	if modes.is_empty():
		PixelFont.draw_centered(surface,"NO MODES AVAILABLE",320,190,2,RED,1)
		return
	var selection := clampi(int(scene.get("mode_selection")),0,modes.size()-1)
	PixelFont.draw_centered(surface,"ARCADE / CHALLENGE OPERATIONS",320,122,1,GOLD,1)
	for i in range(modes.size()):
		var mode: Dictionary = modes[i]
		var unlocked := not director.has_method("is_unlocked") or bool(director.call("is_unlocked", scene, i))
		var y := 140+i*42
		surface.draw_rect(Rect2(34,y,250,36),Color("12212b") if i == selection else Color("08131b"))
		surface.draw_rect(Rect2(34,y,250,36),GOLD if i == selection and unlocked else Color("314955"),false,1.0)
		var icon: Texture2D = MODE_EMBLEMS.get(str(mode.get("icon","arcade")),MODE_EMBLEMS["arcade"])
		surface.draw_texture_rect(icon,Rect2(38,y+2,32,32),false,Color.WHITE if unlocked else Color(0.32,0.38,0.40))
		PixelFont.draw_text(surface,str(mode.get("name","MODE")),Vector2(78,y+7),1,GOLD if i == selection and unlocked else (TEXT if unlocked else MUTED),1)
		PixelFont.draw_text(surface,str(mode.get("tagline","")) if unlocked else "LOCKED // CLEAR BLACK SKY",Vector2(78,y+20),1,BLUE if i == selection and unlocked else MUTED,1)
		if i == selection: surface.draw_texture(FRONT_END_CURSOR,Vector2(20,y+10))
	var selected: Dictionary = modes[selection]
	var selected_unlocked := not director.has_method("is_unlocked") or bool(director.call("is_unlocked", scene, selection))
	_draw_console_panel(surface,Rect2(300,140,306,162),str(selected.get("name","MODE")),BLUE)
	var large_icon: Texture2D = MODE_EMBLEMS.get(str(selected.get("icon","arcade")),MODE_EMBLEMS["arcade"])
	surface.draw_texture_rect(large_icon,Rect2(320,160,64,64),false)
	PixelFont.draw_text(surface,"ROUTE %02d" % selected.get("missions",[]).size(),Vector2(404,164),1,GOLD,1)
	PixelFont.draw_text(surface,"AIRFRAMES %02d" % int(selected.get("lives",1)),Vector2(404,181),1,GREEN,1)
	PixelFont.draw_text(surface,"SCORE X%.2f" % float(selected.get("score_multiplier",1.0)),Vector2(404,198),1,BLUE,1)
	var records: Dictionary = scene.get("mode_records") if _has_property(scene,"mode_records") else {}
	var record: Dictionary = records.get(str(selected.get("id","")),{})
	if not record.is_empty():
		PixelFont.draw_text(surface,"BEST %08d  CLEAR %02d" % [int(record.get("best_score",0)),int(record.get("clears",0))],Vector2(404,215),1,GREEN,1)
	var lines := _wrap_text(str(selected.get("description","")),35)
	for i in range(mini(3,lines.size())):
		PixelFont.draw_text(surface,lines[i],Vector2(320,238+i*12),1,MUTED,1)
	PixelFont.draw_centered(surface,"ENTER DEPLOY   ESC RETURN" if selected_unlocked else "CAMPAIGN CLEAR REQUIRED",453,286,1,GOLD if selected_unlocked else RED,1)

func _draw_front_end_branch(surface: CanvasItem, scene: Object) -> void:
	var branch: Dictionary = scene.get("current_branch") if _has_property(scene,"current_branch") else {}
	var choices: Array = branch.get("choices", [])
	PixelFont.draw_centered(surface,"OPERATIONAL BRANCH // COMMAND DECISION",320,122,1,GOLD,1)
	_draw_console_panel(surface,Rect2(42,138,556,168),str(branch.get("title","CRISIS VECTOR")),BLUE)
	var briefing_lines := _wrap_text(str(branch.get("briefing","SELECT THE NEXT SORTIE.")),78)
	for line_index in range(mini(2,briefing_lines.size())):
		PixelFont.draw_centered(surface,briefing_lines[line_index],320,156+line_index*12,1,MUTED,1)
	var selection := clampi(int(scene.get("branch_selection")) if _has_property(scene,"branch_selection") else 0,0,maxi(0,choices.size()-1))
	for i in range(mini(2,choices.size())):
		var choice: Dictionary = choices[i]
		var position := Vector2(70,190+i*43)
		surface.draw_texture(FRONT_END_BUTTON_SELECTED if i == selection else FRONT_END_BUTTON_IDLE,position)
		if i == selection: surface.draw_texture(FRONT_END_CURSOR,position+Vector2(-16,6))
		PixelFont.draw_text(surface,str(choice.get("label","VECTOR")),position+Vector2(18,7),1,GOLD if i == selection else TEXT,1)
		PixelFont.draw_text(surface,_clip(str(choice.get("detail","")),28),Vector2(366,position.y+7),1,BLUE if i == selection else MUTED,1)
		PixelFont.draw_text(surface,"+%04d CR" % int(choice.get("bonus_credits",0)),Vector2(468,position.y+21),1,GREEN,1)
	PixelFont.draw_centered(surface,"UP / DOWN SELECT   ENTER COMMIT",320,286,1,GOLD,1)

func _draw_front_end_secret_sorties(surface: CanvasItem, scene: Object) -> void:
	var unlocked: Array = scene.call("_unlocked_secret_missions") if scene.has_method("_unlocked_secret_missions") else []
	var all_missions: Array = scene.get("secret_mission_catalog") if _has_property(scene,"secret_mission_catalog") else []
	var completed: Array = scene.get("completed_secret_mission_ids") if _has_property(scene,"completed_secret_mission_ids") else []
	PixelFont.draw_centered(surface,"ENCRYPTED OPTIONAL OPERATIONS",320,122,1,GOLD,1)
	_draw_console_panel(surface,Rect2(28,138,224,168),"VECTORS %02d / %02d" % [unlocked.size(),all_missions.size()],BLUE)
	_draw_console_panel(surface,Rect2(262,138,350,168),"MISSION FILE",BLUE)
	if unlocked.is_empty():
		PixelFont.draw_centered(surface,"NO SECRET VECTORS RECOVERED",320,207,1,RED,1)
		PixelFont.draw_centered(surface,"MASTERY CONDITIONS REVEAL HIDDEN OPERATIONS",320,228,1,MUTED,1)
		PixelFont.draw_centered(surface,"ESC RETURN",320,287,1,GOLD,1)
		return
	var selection := clampi(int(scene.get("secret_sortie_selection")),0,unlocked.size()-1)
	for i in range(unlocked.size()):
		var mission: Dictionary = unlocked[i]
		var y := 158+i*22
		UiSpriteRenderer.draw_nine_slice(surface,OPERATIONS_BUTTON,Rect2(38,y,204,20),6)
		if i == selection: surface.draw_texture(FRONT_END_CURSOR,Vector2(22,y+4))
		var clear_mark := "C " if str(mission.get("id","")) in completed else "  "
		PixelFont.draw_text(surface,_clip(clear_mark+str(mission.get("name","VECTOR")).to_upper(),25),Vector2(50,y+6),1,GOLD if i == selection else TEXT,1)
	var selected: Dictionary = unlocked[selection]
	PixelFont.draw_text(surface,str(selected.get("sector","CLASSIFIED")),Vector2(280,158),1,BLUE,1)
	PixelFont.draw_text(surface,str(selected.get("name","SECRET SORTIE")).to_upper(),Vector2(280,177),2,GOLD,1)
	PixelFont.draw_text(surface,"REWARD +%05d CR" % int(selected.get("reward_credits",0)),Vector2(280,205),1,GREEN,1)
	PixelFont.draw_text(surface,"STATUS  %s" % ("CLEARED" if str(selected.get("id","")) in completed else "AVAILABLE"),Vector2(280,220),1,TEXT,1)
	var lines := _wrap_text(str(selected.get("briefing","")),45)
	for i in range(mini(4,lines.size())):
		PixelFont.draw_text(surface,lines[i],Vector2(280,240+i*11),1,MUTED,1)
	PixelFont.draw_centered(surface,"UP / DOWN VECTOR   ENTER OPEN FILE   ESC RETURN",320,316,1,GOLD,1)

func _draw_front_end_controls(surface: CanvasItem, scene: Object) -> void:
	var bindings := get_node_or_null("/root/InputBindings")
	var count := int(bindings.call("binding_count")) if bindings != null and bindings.has_method("binding_count") else 0
	var selection := clampi(int(scene.get("control_selection")), 0, maxi(0, count - 1))
	var listening := bool(scene.get("control_listening"))
	var visible_rows := 7
	var first := clampi(selection - 3, 0, maxi(0, count - visible_rows))
	var last := mini(first + visible_rows, count)
	PixelFont.draw_centered(surface, "FLIGHT CONTROL ASSIGNMENT", 320, 119, 1, GOLD, 1)
	var range_text := "%02d-%02d / %02d" % [first + 1 if count > 0 else 0, last, count]
	_draw_console_panel(surface, Rect2(88, 133, 464, 174), "KEYBOARD COMMANDS // %s" % range_text, BLUE)
	for row in range(first, last):
		var y := 151 + (row - first) * 20
		var selected := row == selection
		if selected:
			surface.draw_rect(Rect2(104, y - 3, 432, 18), Color("162b36"))
			surface.draw_rect(Rect2(104, y - 3, 3, 18), GOLD)
			surface.draw_texture(FRONT_END_CURSOR, Vector2(87, y + 1))
		var label := str(bindings.call("binding_label", row)) if bindings != null else "CONTROL"
		var key_name := str(bindings.call("binding_key_name", row)) if bindings != null else "--"
		PixelFont.draw_text(surface, label, Vector2(118, y), 1, GOLD if selected else TEXT, 1)
		PixelFont.draw_text(surface, key_name, Vector2(500 - PixelFont.text_width(key_name, 1, 1), y), 1, GREEN if selected else BLUE, 1)
	if listening:
		surface.draw_rect(Rect2(151, 239, 338, 34), Color("071018"))
		surface.draw_rect(Rect2(151, 239, 338, 34), GOLD, false, 1.0)
		PixelFont.draw_centered(surface, "PRESS NEW KEY // ESC CANCEL", 320, 251, 1, GOLD, 1)
	else:
		PixelFont.draw_centered(surface, "UP / DOWN SELECT   ENTER REBIND   BACKSPACE DEFAULTS   ESC RETURN", 320, 286, 1, MUTED, 1)

func _draw_front_end_options(surface: CanvasItem, scene: Object) -> void:
	var settings := get_node_or_null("/root/SettingsDirector")
	var category:=clampi(int(scene.get("option_category")) if _has_property(scene,"option_category") else 0,0,4)
	var count:=int(settings.call("category_setting_count",category)) if settings!=null and settings.has_method("category_setting_count") else 1
	var selection := clampi(int(scene.get("option_selection")) if _has_property(scene, "option_selection") else 0, 0, count - 1)
	PixelFont.draw_centered(surface, "SYSTEM OPTIONS", 320, 128, 1, GOLD, 1)
	var tabs:=[]
	for i in range(int(settings.call("category_count")) if settings!=null and settings.has_method("category_count") else 1):tabs.append(str(settings.call("category_name",i)))
	PixelFont.draw_centered(surface,"  ".join(tabs),320,141,1,BLUE,1)
	PixelFont.draw_centered(surface,"< %s >" % str(settings.call("category_name",category)),320,153,1,GOLD,1)
	for index in range(count):
		var position:=Vector2(100,170+index*35)
		surface.draw_texture(OPTIONS_ROW_SELECTED if index == selection else OPTIONS_ROW_IDLE, position)
		if index == selection:
			surface.draw_texture(FRONT_END_CURSOR, position + Vector2(-16, 6))
		var global_index:=int(settings.call("category_global_index",category,index)) if settings!=null and settings.has_method("category_global_index") else index
		var label:=str(settings.call("setting_label",global_index)) if settings!=null else "OPTION"
		var value:=str(settings.call("setting_value",global_index)) if settings!=null else "--"
		var ratio:=float(settings.call("setting_ratio",global_index)) if settings!=null else 0.0
		PixelFont.draw_text(surface, label, position + Vector2(18, 9), 1, GOLD if index == selection else TEXT, 1)
		if global_index in [0,1,8,9,10,11]:
			surface.draw_texture(OPTIONS_TOGGLE_ON if ratio >= 0.5 else OPTIONS_TOGGLE_OFF, position + Vector2(306, 8))
		else:
			surface.draw_texture(OPTIONS_VALUE_TROUGH, position + Vector2(286, 11))
			_draw_clipped_fill(surface, OPTIONS_VALUE_FILL, position + Vector2(288, 13), ratio)
		PixelFont.draw_text(surface, value, position + Vector2(382 - PixelFont.text_width(value, 1, 1), 9), 1, GREEN if ratio >= 0.5 else MUTED, 1)
	var difficulty:=get_node_or_null("/root/DifficultyDirector")
	if category==4 and difficulty!=null:
		var profile: Dictionary = difficulty.call("active_profile")
		PixelFont.draw_centered(surface, _clip(str(profile.get("description", "")), 72), 320, 312, 1, BLUE, 1)
	PixelFont.draw_centered(surface,"Q / X CATEGORY   LEFT / RIGHT ADJUST   ESC RETURN",320,324,1,MUTED,1)

func _draw_front_end_dossier(surface: CanvasItem, scene: Object) -> void:
	var data: Dictionary = ContentCatalog.load_json("res://data/intelligence.json")
	var entries: Array = data.get("entries", []) if typeof(data) == TYPE_DICTIONARY else []
	var unlocked_ids: Array = scene.get("intelligence_unlocked_ids") if _has_property(scene,"intelligence_unlocked_ids") else []
	var unlocked: Array = []
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id","")) in unlocked_ids:
			unlocked.append(entry)
	PixelFont.draw_centered(surface,"EVAVO TACTICAL INTELLIGENCE DATABASE",320,122,1,GOLD,1)
	_draw_console_panel(surface,Rect2(28,136,214,174),"INDEX %02d / %02d" % [unlocked.size(),entries.size()],BLUE)
	_draw_console_panel(surface,Rect2(252,136,360,174),"TECHNICAL FILE",BLUE)
	if unlocked.is_empty():
		PixelFont.draw_centered(surface,"NO FILES RELEASED",320,216,1,RED,1)
		return
	var selection := clampi(int(scene.get("dossier_selection")) if _has_property(scene,"dossier_selection") else 0,0,unlocked.size()-1)
	var first := clampi(selection-2,0,maxi(0,unlocked.size()-5))
	for row in range(first,mini(first+5,unlocked.size())):
		var entry: Dictionary = unlocked[row]
		var y := 158+(row-first)*27
		UiSpriteRenderer.draw_nine_slice(surface,OPERATIONS_BUTTON,Rect2(38,y,194,24),6)
		if row == selection: surface.draw_texture(FRONT_END_CURSOR,Vector2(22,y+6))
		PixelFont.draw_text(surface,_clip(str(entry.get("name","FILE")),25),Vector2(54,y+8),1,GOLD if row == selection else TEXT,1)
	var selected: Dictionary = unlocked[selection]
	var texture: Texture2D = load(str(selected.get("illustration",""))) as Texture2D
	if texture is Texture2D:
		var raw_size: Vector2 = texture.get_size()
		var scale: float = minf(142.0/maxf(1.0,raw_size.x),92.0/maxf(1.0,raw_size.y))
		var draw_size: Vector2 = (raw_size*scale).round()
		surface.draw_texture_rect(texture,Rect2((Vector2(330,207)-draw_size*0.5).round(),draw_size),false,Color(0.88,0.93,0.95))
	PixelFont.draw_text(surface,str(selected.get("category","FILE")),Vector2(412,154),1,GOLD,1)
	PixelFont.draw_text(surface,_clip(str(selected.get("name","UNKNOWN")),29),Vector2(412,171),1,TEXT,1)
	PixelFont.draw_text(surface,_clip(str(selected.get("classification","RESTRICTED")),29),Vector2(412,187),1,BLUE,1)
	var summary_lines := _wrap_text(str(selected.get("summary","")),43)
	for i in range(mini(3,summary_lines.size())):
		PixelFont.draw_text(surface,summary_lines[i],Vector2(270,258+i*12),1,MUTED,1)
	PixelFont.draw_centered(surface,"UP / DOWN FILE   ESC RETURN",432,296,1,GREEN,1)

func _front_end_sector(mission_index: int) -> String:
	if mission_index >= 20: return "S3 BLACK SKY"
	if mission_index >= 10: return "S2 MACHINE WAR"
	return "S1 MERCENARY WAR"

func _sortie_order_header(mission_index: int) -> String:
	var sector := clampi(int(mission_index / 10), 0, 2)
	var sector_names := ["MERCENARY WAR", "MACHINE WAR", "BLACK SKY"]
	return "MISSION %02d / S%d %s" % [mission_index + 1, sector + 1, sector_names[sector]]

func _secret_sortie_index(scene: Object) -> int:
	var active_id := str(scene.get("active_secret_mission_id"))
	var catalogue: Array = scene.get("secret_mission_catalog")
	for index in range(catalogue.size()):
		if str(catalogue[index].get("id", "")) == active_id:
			return index
	return 0

func _secret_sortie_header(scene: Object) -> String:
	var catalogue: Array = scene.get("secret_mission_catalog")
	var active: Dictionary = scene.call("_active_secret_mission") if scene.has_method("_active_secret_mission") else {}
	return "SECRET %02d / %02d  %s" % [_secret_sortie_index(scene) + 1, catalogue.size(), str(active.get("sector", "CLASSIFIED"))]

func _draw_campaign_progress(surface: CanvasItem, mission_index: int, position: Vector2) -> void:
	surface.draw_texture(CAMPAIGN_PROGRESS_RAIL, position)
	for index in range(30):
		var sector_gap := int(index / 10) * 5
		var node_position := position + Vector2(3 + index * 11 + sector_gap, 2)
		var node: Texture2D = CAMPAIGN_NODE_CURRENT if index == mission_index else (CAMPAIGN_NODE_COMPLETE if index < mission_index else CAMPAIGN_NODE_LOCKED)
		surface.draw_texture(node, node_position)

func _draw_mode_progress(surface: CanvasItem, route_index: int, route_total: int, position: Vector2) -> void:
	surface.draw_texture(CAMPAIGN_PROGRESS_RAIL,position)
	var count := clampi(route_total,1,18)
	for index in range(count):
		var node_position := position+Vector2(3+index*18,2)
		var node: Texture2D = CAMPAIGN_NODE_CURRENT if index == route_index else (CAMPAIGN_NODE_COMPLETE if index < route_index else CAMPAIGN_NODE_LOCKED)
		surface.draw_texture(node,node_position)

func _draw_result(surface: CanvasItem, scene: Object) -> void:
	_draw_maintenance_bay(surface, 0.66, 0.74)
	_draw_frame(surface, Rect2(10, 10, 620, 340))
	var mission_success := bool(scene.get("mission_success")) if _has_property(scene, "mission_success") else true
	var mode_active := _has_property(scene,"game_mode") and str(scene.get("game_mode")) != "campaign"
	PixelFont.draw_centered(surface, "MODE REPORT" if mode_active else ("MISSION COMPLETE" if mission_success else "SORTIE FAILED"), 320, 35, 3, GOLD if mission_success else RED, 2)

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
	var result_prompt := "ENTER CONTINUE RUN   R CONTINUE" if mode_active else ("ENTER NEXT MISSION   R RETRY" if mission_success else "ENTER / R RETRY SORTIE")
	PixelFont.draw_centered(surface,result_prompt,320,315,1,TEXT,1)

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
	surface.draw_texture(HUD_TOP_FRAME, Vector2(8, 5))
	var max_hull := _call_int(scene, "_max_hull", 100)
	var max_shield := _call_int(scene, "_max_shield", 100)
	var generator := _call_dictionary(scene, "_active_generator")
	var energy := float(scene.get("energy")) if _has_property(scene, "energy") else 0.0
	var capture_warning := _capture_hud_state() == "warning"
	var hull_value := mini(int(scene.get("hull")), 18) if capture_warning else int(scene.get("hull"))
	var shield_value := mini(int(scene.get("shield")), 15) if capture_warning else int(scene.get("shield"))
	var energy_value := minf(energy, 12.0) if capture_warning else energy
	_draw_primary_meter(surface, Vector2(12, 7), hull_value, max_hull, HUD_HULL_FILL, HUD_HULL_FRAME, HUD_HULL_WARNING_FRAME, 0.30)
	_draw_primary_meter(surface, Vector2(106, 7), shield_value, maxi(1, max_shield), HUD_SHIELD_FILL, HUD_SHIELD_FRAME, HUD_SHIELD_WARNING_FRAME, 0.24)
	_draw_primary_meter(surface, Vector2(200, 7), int(round(energy_value)), maxi(1, int(round(EnergyRules.capacity(generator)))), HUD_ENERGY_FILL, HUD_ENERGY_FRAME, HUD_ENERGY_WARNING_FRAME, 0.18)
	surface.draw_texture(HUD_ICON_BOMB, Vector2(342, 10))
	PixelFont.draw_text(surface, "%d" % int(scene.get("bombs")), Vector2(356, 13), 1, TEXT, 1)
	var remaining := maxi(0, int(ceil(float(scene.get("mission_duration")) - float(scene.get("mission_time")))))
	if _has_property(scene, "egress_active") and bool(scene.get("egress_active")) and _has_property(scene, "egress_time_remaining"):
		remaining = maxi(0, int(ceil(float(scene.get("egress_time_remaining")))))
	surface.draw_texture(HUD_ICON_TIME, Vector2(390, 10))
	PixelFont.draw_text(surface, "%03d" % remaining, Vector2(404, 13), 1, TEXT, 1)
	surface.draw_texture(HUD_ICON_SCORE, Vector2(506, 10))
	PixelFont.draw_text(surface, "%08d" % int(scene.get("score")), Vector2(522, 13), 1, TEXT, 1)
	var weapon := _call_dictionary(scene, "_active_weapon")
	var altitude_choice := _compact_altitude_choice()
	if altitude_choice.is_empty():
		PixelFont.draw_text(surface, "%s/%s" % [_short_altitude(), _short_form()], Vector2(298, 13), 1, BLUE, 1)
	else:
		PixelFont.draw_centered(surface, altitude_choice, 320, 13, 1, GOLD, 1)
	PixelFont.draw_text(surface, _clip(str(weapon.get("name", "CANNON")), 12), Vector2(448, 13), 1, MUTED, 1)
	# One shared information lane: urgent combat state always replaces routine mission data.
	if not _active_boss(scene).is_empty():
		_draw_boss(surface, scene)
	elif _has_threat_warning(scene):
		_draw_threat(surface, scene)
	elif _ingress_time > 0.0:
		_draw_mission_ingress(surface, scene)
	else:
		_draw_objective_tracker(surface, scene)
	_draw_mode_run_state(surface, scene)
	if float(scene.get("status_timer")) > 0.0:
		var status := str(scene.get("status_text"))
		if status.begins_with("SECRET - "):
			_draw_secret_discovery(surface, status, float(scene.get("status_timer")))
		else:
			var egress_priority := (_has_property(scene, "egress_active") and bool(scene.get("egress_active"))) or (_has_property(scene, "egress_completion_timer") and float(scene.get("egress_completion_timer")) > 0.0)
			if egress_priority or (not _altitude_choice_active(scene) and not _radio_occupies_status_lane()):
				surface.draw_texture_rect(HUD_STATUS_FRAME, Rect2(180, 338, 280, 14), false)
				PixelFont.draw_centered(surface, _clip(status, 46), 320, 341, 1, GOLD, 1)

func _altitude_choice_active(scene: Object) -> bool:
	var presentation := get_node_or_null("/root/AltitudeTransitionDirector")
	return presentation != null and presentation.has_method("occupies_status_lane") and bool(presentation.call("occupies_status_lane"))

func _compact_altitude_choice() -> String:
	var presentation := get_node_or_null("/root/AltitudeTransitionDirector")
	return str(presentation.call("compact_choice_label")) if presentation != null and presentation.has_method("compact_choice_label") else ""

func _radio_occupies_status_lane() -> bool:
	var radio := get_node_or_null("/root/MissionRadioDirector")
	return radio != null and radio.has_method("occupies_status_lane") and bool(radio.call("occupies_status_lane"))

func _draw_mode_run_state(surface: CanvasItem, scene: Object) -> void:
	if not _has_property(scene, "game_mode") or str(scene.get("game_mode")) == "campaign":
		return
	var labels := {
		"arcade_assault": "ASSAULT",
		"boss_rush": "BOSS",
		"hypersonic_trial": "TRIAL",
		"strike_mastery": "STRIKE",
	}
	var mode_id := str(scene.get("game_mode"))
	var route := int(scene.get("mode_route_index")) + 1 if _has_property(scene, "mode_route_index") else 1
	var total := int(scene.get("mode_route_total")) if _has_property(scene, "mode_route_total") else 1
	var lives := int(scene.get("mode_lives")) if _has_property(scene, "mode_lives") else 0
	var run_score := int(scene.get("mode_total_score")) + int(scene.get("score")) if _has_property(scene, "mode_total_score") else int(scene.get("score"))
	var position := Vector2(420, 316)
	surface.draw_texture(MODE_RUN_FRAME, position)
	PixelFont.draw_text(surface, str(labels.get(mode_id, "SPECIAL")), position + Vector2(9, 7), 1, BLUE, 1)
	PixelFont.draw_text(surface, "%02d/%02d" % [route, total], position + Vector2(68, 7), 1, TEXT, 1)
	PixelFont.draw_text(surface, "A%02d" % lives, position + Vector2(122, 7), 1, GOLD, 1)
	PixelFont.draw_text(surface, "%08d" % run_score, position + Vector2(151, 7), 1, TEXT, 1)

func _draw_secret_discovery(surface: CanvasItem, status: String, remaining: float) -> void:
	var position := Vector2(160, 38)
	var age := maxf(0.0, 1.4 - remaining)
	var frame_index := posmod(int(floor(age * 5.0)), SECRET_DISCOVERY_FX.size())
	var reveal_step := clampi(int(floor(age / 0.045)), 0, 4)
	position.y -= float(4 - reveal_step)
	surface.draw_texture(SECRET_DISCOVERY_FRAME, position)
	surface.draw_texture(SECRET_DISCOVERY_FX[frame_index], position)
	PixelFont.draw_text(surface, "VECTOR ACQUIRED", position + Vector2(36, 7), 1, BLUE, 1)
	PixelFont.draw_text(surface, _clip(status.trim_prefix("SECRET - "), 43), position + Vector2(36, 17), 1, GOLD, 1)

func _draw_mission_ingress(surface: CanvasItem, scene: Object) -> void:
	if _ingress_time <= 0.0:
		return
	var age := INGRESS_SECONDS - _ingress_time
	var frame_step := clampi(int(floor(age / 0.045)), 0, 4)
	var y := 42.0 - float(4 - frame_step) * 2.0
	var alpha := clampf(age / 0.16, 0.0, 1.0) * clampf(_ingress_time / 0.28, 0.0, 1.0)
	var tint := Color(1, 1, 1, alpha)
	surface.draw_texture(HUD_NOTIFICATION_FRAME, Vector2(152, y), tint)
	PixelFont.draw_text(surface, "INGRESS", Vector2(164, y + 6), 1, Color(GOLD, alpha), 1)
	PixelFont.draw_text(surface, "%s/%s" % [_short_altitude(), _short_form()], Vector2(420, y + 6), 1, Color(BLUE, alpha), 1)
	PixelFont.draw_centered(surface, _clip(str(scene.get("current_mission_name")), 30), 320, y + 6, 1, Color(TEXT, alpha), 1)
	var objective := _primary_objective(scene)
	var required := bool(objective.get("required", true))
	surface.draw_texture(OBJECTIVE_REQUIRED if required else OBJECTIVE_BONUS, Vector2(164, y + 18), tint)
	PixelFont.draw_text(surface, _clip(_objective_line(scene, objective), 48), Vector2(180, y + 21), 1, Color(GREEN if required else GOLD, alpha), 1)

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
	return not _threat_snapshot(scene).is_empty()

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
	# Routine mission progress belongs inside the instrument fascia. Reserving
	# the centered y=42 combat lane for ingress, bosses and genuine RWR events
	# returns twenty unobstructed pixels to the battlefield at all other times.
	var position := Vector2(298, 24)
	surface.draw_texture_rect(OBJECTIVE_REQUIRED if required else OBJECTIVE_BONUS, Rect2(position, Vector2(7,7)), false)
	PixelFont.draw_text(surface, _clip(_objective_line(scene, objective), 48), position + Vector2(10, 1), 1, GREEN if required else GOLD, 1)
	surface.draw_texture_rect(OBJECTIVE_TRACKER_TROUGH, Rect2(position + Vector2(10,8),Vector2(310,2)), false)
	var ratio := _objective_ratio(scene, objective)
	if ratio > 0.0:
		surface.draw_texture_rect(OBJECTIVE_TRACKER_REQUIRED_FILL if required else OBJECTIVE_TRACKER_BONUS_FILL, Rect2(position + Vector2(11,8),Vector2(308.0*ratio,1)), false)

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
	surface.draw_texture(HUD_BOSS_PHASE_FRAMES[phase_index], Vector2(126, 42))
	PixelFont.draw_centered(surface, "%s  P%d%s  %d/%d" % [str(boss.get("id", "BOSS")).replace("_", " "), phase, cue, hp, max_hp], 320, 47, 1, TEXT, 1)
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	surface.draw_texture(HUD_BOSS_TROUGH, Vector2(143, 58))
	_draw_clipped_fill(surface, HUD_BOSS_PHASE_FILLS[phase_index], Vector2(144, 59), ratio)

func _draw_threat(surface: CanvasItem, scene: Object) -> void:
	var snapshot := _threat_snapshot(scene)
	if snapshot.is_empty(): return
	var count := int(snapshot.get("count", 0))
	var distance := float(snapshot.get("distance", INF))
	var acquiring := float(snapshot.get("acquiring", 0.0))
	var countermeasures := get_node_or_null("/root/CountermeasureDirector")
	var cm := int(countermeasures.call("charges_remaining")) if countermeasures != null and countermeasures.has_method("charges_remaining") else 0
	var text := ThreatWarningRules.warning_text(distance, count)
	if count > 0:
		text = "MISSILE X%d  %d O'CLOCK  TTI %.1f  CM%02d" % [count, int(snapshot.get("bearing", 12)), float(snapshot.get("tti", 9.9)), cm]
	elif acquiring > 0.0:
		text = "RADAR SPIKE  %02d%%  EVADE  CM%02d" % [int(roundf(acquiring * 100.0)), cm]
	if text == "": return
	var level := clampi(ThreatWarningRules.warning_level(distance, count), 0, 2) if count > 0 else 1
	var position := Vector2(180, 42)
	surface.draw_texture(HUD_THREAT_FRAMES[level], position)
	surface.draw_texture(HUD_THREAT_MISSILE_ICON, position + Vector2(7, 5), RED if level >= 2 else (GOLD if level == 1 else BLUE))
	PixelFont.draw_centered(surface, text, 326, 48, 1, RED if level >= 2 else (GOLD if level == 1 else BLUE), 1)
	surface.draw_texture(HUD_THREAT_APPROACH_TROUGH, position + Vector2(190, 16))
	var approach_ratio := clampf(1.0 - distance / 480.0, 0.04, 1.0) if count > 0 else acquiring
	_draw_clipped_fill(surface, HUD_THREAT_LOCK_FILL if level >= 2 else HUD_THREAT_CAUTION_FILL, position + Vector2(191, 17), approach_ratio)
	_draw_aircraft_rwr_cue(surface, scene, snapshot, level)

func _draw_aircraft_rwr_cue(surface: CanvasItem, scene: Object, snapshot: Dictionary, warning_level: int) -> void:
	var player: Vector2 = scene.get("player_position")
	var count := int(snapshot.get("count", 0))
	var acquiring := float(snapshot.get("acquiring", 0.0))
	var frame: Texture2D = HUD_RWR_SPIKE
	if count > 0 and warning_level >= 2:
		frame = HUD_RWR_MISSILE_INBOUND
	elif count > 0 or acquiring >= 0.65:
		frame = HUD_RWR_HARD_LOCK
	var pulse := 0.78 + 0.22 * absf(sin(float(scene.get("mission_time")) * 18.0)) if count > 0 else 0.88
	var frame_position := Vector2(clampf(player.x - 14.0, 4.0, 608.0), clampf(player.y - 14.0, 70.0, 328.0)).round()
	surface.draw_texture(frame, frame_position, Color(1,1,1,pulse))
	var bearing := clampi(int(snapshot.get("bearing", 12)), 1, 12)
	var radians := float(bearing % 12) / 12.0 * TAU - PI * 0.5
	var direction := Vector2(cos(radians), sin(radians))
	# Keep the direction pip close enough to the airframe that it cannot collide
	# with bottom-edge altitude/support controls during low-screen maneuvering.
	var cue_position := player + direction * 31.0 - Vector2(8,8)
	cue_position.x = clampf(cue_position.x, 6.0, 618.0)
	cue_position.y = clampf(cue_position.y, 70.0, 338.0)
	surface.draw_texture(HUD_RWR_BEARINGS[bearing % 12], cue_position.round(), Color(1,1,1,pulse))

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

func _draw_maintenance_bay(surface: CanvasItem, wash_alpha: float, tint_alpha: float) -> void:
	surface.draw_rect(Rect2(0, 0, 640, 360), BG)
	surface.draw_texture_rect(SORTIE_BAY_BACKDROP, Rect2(0,0,640,360), false, Color(0.78,0.84,0.86,tint_alpha))
	var frame_index := posmod(int(floor(_front_end_time * 3.0)), MAINTENANCE_BAY_ACTIVITY.size())
	surface.draw_texture(MAINTENANCE_BAY_ACTIVITY[frame_index], Vector2.ZERO, Color(1,1,1,0.82))
	surface.draw_rect(Rect2(0,0,640,360), Color(0.01,0.02,0.03,clampf(wash_alpha,0.0,0.82)))

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
	if _capture_hud_state() == "boss":
		return {"id":"SKY FORTRESS", "boss":true, "hp":720, "max_hp":1200, "boss_phase":2}
	var enemies: Array = scene.get("enemies")
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and bool(enemy.get("boss", false)) and bool(enemy.get("entry_ready", true)) and int(enemy.get("hp", 0)) > 0: return enemy
	return {}

func _threat_snapshot(scene: Object) -> Dictionary:
	if _capture_hud_state() == "warning":
		return {"count":3, "distance":96.0, "bearing":5, "tti":1.4, "acquiring":1.0}
	if _capture_hud_state() == "acquisition":
		return {"count":0, "distance":INF, "bearing":10, "tti":INF, "acquiring":0.48}
	var bullets: Array = scene.get("enemy_bullets")
	var player_position: Vector2 = scene.get("player_position")
	var count := ThreatWarningRules.homing_count(bullets)
	var distance := ThreatWarningRules.nearest_homing_distance(bullets, player_position)
	var acquiring := 0.0
	var acquiring_bearing := 12
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			var ratio := float(enemy.get("missile_lock_ratio", 0.0))
			if ratio > acquiring:
				acquiring = ratio
				acquiring_bearing = ThreatWarningRules.clock_bearing(enemy.get("position", Vector2.ZERO), player_position)
	if count <= 0:
		return {"count":0,"distance":INF,"acquiring":acquiring,"bearing":acquiring_bearing} if acquiring > 0.05 else {}
	var nearest := ThreatWarningRules.nearest_homing(bullets, player_position)
	return {"count":count, "distance":distance, "bearing":ThreatWarningRules.clock_bearing(nearest.get("position",Vector2.ZERO),player_position), "tti":ThreatWarningRules.time_to_impact(nearest,player_position), "acquiring":acquiring}

func _capture_hud_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args():
		return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-hud="):
			var state := argument.trim_prefix("--capture-hud=").to_lower()
			return state if state in ["objective", "ingress", "acquisition", "warning", "boss"] else ""
	return ""

func _capture_time() -> float:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-time="):
			var value := argument.trim_prefix("--capture-time=")
			if value.is_valid_float():
				return maxf(0.0, value.to_float())
	return 0.0

func _call_dictionary(scene: Object, method_name: String) -> Dictionary:
	if scene.has_method(method_name):
		var value = scene.call(method_name)
		return value if typeof(value) == TYPE_DICTIONARY else {}
	return {}

func _call_int(scene: Object, method_name: String, fallback: int) -> int:
	return int(scene.call(method_name)) if scene.has_method(method_name) else fallback

func _has_property(object: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(object, property_name)

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
