extends CanvasLayer

const CountermeasureRules = preload("res://scripts/countermeasure_rules.gd")
const CountermeasureSurface = preload("res://scripts/countermeasure_surface.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const FLARE_FRAMES := [
	preload("res://assets/runtime/effects/countermeasure/flare_0.png"),
	preload("res://assets/runtime/effects/countermeasure/flare_1.png"),
	preload("res://assets/runtime/effects/countermeasure/flare_2.png"),
	preload("res://assets/runtime/effects/countermeasure/flare_3.png"),
]

var _charges := CountermeasureRules.MAX_CHARGES
var _cooldown := 0.0
var _serial := 0
var _sortie_key := ""
var _events: Array[Dictionary] = []
var _surface: Control
var _capture_deployed := false

func _ready() -> void:
	layer = 15
	_surface = CountermeasureSurface.new()
	_surface.director = self
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func update_countermeasures(scene: Object, delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - maxf(0.0, delta))
	_update_events(delta)
	var playing := _has_property(scene, "phase") and int(scene.get("phase")) == 1
	if not playing:
		_sortie_key = ""
		return
	var key := _current_sortie_key(scene)
	if key != _sortie_key:
		_sortie_key = key
		_charges = CountermeasureRules.MAX_CHARGES
		_cooldown = 0.0
		_events.clear()
		_capture_deployed = false
	if "--capture-countermeasure" in OS.get_cmdline_user_args() and not _capture_deployed:
		_capture_deployed = true
		deploy(scene)
	if Input.is_action_just_pressed("deploy_countermeasure"):
		deploy(scene)
	if _surface != null:
		_surface.queue_redraw()

func deploy(scene: Object) -> int:
	if not CountermeasureRules.can_deploy(_charges, _cooldown) or not _has_property(scene, "enemy_bullets") or not _has_property(scene, "player_position"):
		return 0
	var player: Vector2 = scene.get("player_position")
	var decoy := CountermeasureRules.decoy_point(player, _serial)
	var bullets: Array = scene.get("enemy_bullets")
	var diverted := CountermeasureRules.divert_missiles(bullets, player, decoy)
	scene.set("enemy_bullets", bullets)
	_charges -= 1
	_cooldown = CountermeasureRules.COOLDOWN_SECONDS
	_serial += 1
	_events.append({"position":player + Vector2(0, 16), "age":0.0, "serial":_serial})
	var sfx := get_node_or_null("/root/RetroSfxDirector")
	if sfx != null and sfx.has_method("play_event"):
		sfx.call("play_event", RetroSfxRules.COUNTERMEASURE)
	if _has_property(scene, "status_text"):
		scene.set("status_text", "CM %02d  //  %s" % [_charges, "MISSILE DECOYED" if diverted > 0 else "FLARE OUT"])
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 0.72)
	return diverted

func draw_countermeasures(surface: CanvasItem) -> void:
	for event in _events:
		var age := float(event.get("age", 0.0))
		var ratio := clampf(age / CountermeasureRules.EFFECT_SECONDS, 0.0, 0.999)
		var frame_index := clampi(int(floor(ratio * float(FLARE_FRAMES.size()))), 0, FLARE_FRAMES.size() - 1)
		var texture: Texture2D = FLARE_FRAMES[frame_index]
		var position: Vector2 = event.get("position", Vector2.ZERO)
		position.y += ratio * CountermeasureRules.DECOY_TRAIL_DISTANCE
		position.x += sin(ratio * PI) * (-18.0 if posmod(int(event.get("serial", 0)), 2) == 0 else 18.0)
		surface.draw_texture(texture, (position - texture.get_size() * 0.5).round(), Color(1,1,1,1.0-smoothstep(0.72,1.0,ratio)))

func charges_remaining() -> int:
	return _charges

func _update_events(delta: float) -> void:
	for index in range(_events.size() - 1, -1, -1):
		_events[index]["age"] = float(_events[index].get("age", 0.0)) + maxf(0.0, delta)
		if float(_events[index]["age"]) >= CountermeasureRules.EFFECT_SECONDS:
			_events.remove_at(index)

func _current_sortie_key(scene: Object) -> String:
	var mission := int(scene.get("mission_index")) if _has_property(scene, "mission_index") else 0
	var secret := str(scene.get("active_secret_mission_id")) if _has_property(scene, "active_secret_mission_id") else ""
	return "%d:%s" % [mission, secret]

func _has_property(subject: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(subject, property_name)
