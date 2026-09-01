extends CanvasLayer

const MissionRadioSurface = preload("res://scripts/mission_radio_surface.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")

const INTRO_DELAY := 1.62
const INTRO_SECONDS := 4.8
const CONTACT_SECONDS := 2.7
const BOSS_SECONDS := 3.4

var _surface: Control
var _last_phase := -1
var _last_mission := -1
var _last_status := ""
var _last_boss_spawned := false
var _intro_delay := 0.0
var _message_timer := 0.0
var _message_duration := 0.0
var _speaker := ""
var _message := ""
var _priority := 0

func _ready() -> void:
	layer = 38
	if DisplayServer.get_name() == "headless": return
	_surface = MissionRadioSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene):
		_reset_observation()
		return
	var phase := int(scene.get("phase"))
	var mission := int(scene.get("mission_index"))
	if phase != 1:
		_last_phase = phase
		_last_mission = mission
		_last_status = ""
		_last_boss_spawned = false
		_clear_message()
		return
	if _last_phase != 1 or _last_mission != mission:
		_last_phase = 1
		_last_mission = mission
		_last_status = str(scene.get("status_text"))
		_last_boss_spawned = bool(scene.get("boss_spawned"))
		_intro_delay = 0.0 if "--capture-radio" in OS.get_cmdline_user_args() else INTRO_DELAY
		_clear_message()
	_intro_delay = maxf(0.0, _intro_delay - delta)
	if _intro_delay > 0.0:
		_redraw()
		return
	if _intro_delay == 0.0 and _message.is_empty():
		_show(_sector_callsign(mission), str(scene.get("current_briefing")), INTRO_SECONDS, 1, RetroSfxRules.RADIO_TX)
		_intro_delay = -1.0
	var boss_spawned := bool(scene.get("boss_spawned"))
	if boss_spawned and not _last_boss_spawned:
		var boss_name := str(scene.get("current_boss_id")).replace("_", " ").to_upper()
		_show(_sector_callsign(mission), "HEAVY CONTACT // %s. WEAPONS FREE." % boss_name, BOSS_SECONDS, 3, RetroSfxRules.RADIO_ALERT)
	_last_boss_spawned = boss_spawned
	var status := str(scene.get("status_text"))
	var status_timer := float(scene.get("status_timer"))
	if not status.is_empty() and status != _last_status and status_timer >= 1.0 and not status.begins_with("BOMB STRIKE"):
		_show("AWACS", "CONTACT // %s" % status, CONTACT_SECONDS, 2, RetroSfxRules.RADIO_TX)
	_last_status = status
	if _message_timer > 0.0:
		_message_timer = maxf(0.0, _message_timer - delta)
		if _message_timer == 0.0: _clear_message()
	_redraw()

func _show(speaker: String, message: String, duration: float, priority: int, audio_event: String) -> void:
	if message.is_empty() or (not _message.is_empty() and priority < _priority): return
	_speaker = speaker
	_message = message.to_upper()
	_message_duration = duration
	_message_timer = duration
	_priority = priority
	var audio := get_node_or_null("/root/RetroSfxDirector")
	if audio != null and audio.has_method("play_event"): audio.call("play_event", audio_event)

func draw_radio(surface: CanvasItem) -> void:
	if _message.is_empty() or not _subtitles_enabled(): return
	var age := _message_duration - _message_timer
	var alpha := minf(clampf(age / 0.12, 0.0, 1.0), clampf(_message_timer / 0.22, 0.0, 1.0))
	surface.draw_rect(Rect2(18, 263, 292, 43), Color(0.015, 0.035, 0.050, 0.94 * alpha))
	surface.draw_rect(Rect2(18, 263, 292, 43), Color(0.32, 0.55, 0.62, 0.88 * alpha), false, 1.0)
	surface.draw_rect(Rect2(24, 269, 3, 29), Color(0.90, 0.73, 0.31, alpha))
	PixelFont.draw_text(surface, "RX // %s" % _speaker, Vector2(34, 269), 1, Color(0.42, 0.73, 0.78, alpha), 1)
	var lines := _wrap(_message, 38)
	for i in range(mini(2, lines.size())):
		PixelFont.draw_text(surface, lines[i], Vector2(34, 281 + i * 9), 1, Color(0.86, 0.89, 0.90, alpha), 1)
	var pulse := 0.45 + 0.55 * absf(sin(age * 9.0))
	for i in range(5):
		var height := 2.0 + float((i * 3 + int(age * 12.0)) % 5)
		surface.draw_rect(Rect2(282 + i * 4, 270 + (6.0 - height) * 0.5, 2, height), Color(0.90, 0.73, 0.31, alpha * pulse))

func _wrap(text: String, columns: int) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in text.split(" ", false):
		var candidate := str(word) if current.is_empty() else "%s %s" % [current, word]
		if candidate.length() > columns and not current.is_empty():
			lines.append(current)
			current = str(word)
		else: current = candidate
	if not current.is_empty(): lines.append(current)
	return lines

func _sector_callsign(mission: int) -> String:
	if mission < 10: return "COASTWATCH"
	if mission < 20: return "ORACLE"
	return "SKYWARD"

func _subtitles_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsDirector")
	return settings == null or not settings.has_method("subtitles_enabled") or bool(settings.call("subtitles_enabled"))

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "mission_index", "current_briefing", "status_text", "status_timer", "boss_spawned", "current_boss_id"])

func _reset_observation() -> void:
	_last_phase = -1
	_last_mission = -1
	_clear_message()

func _clear_message() -> void:
	_message_timer = 0.0
	_message_duration = 0.0
	_message = ""
	_priority = 0
	_redraw()

func _redraw() -> void:
	if _surface != null: _surface.queue_redraw()
