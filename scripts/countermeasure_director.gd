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
const FLARE_PIVOT := Vector2(24, 10)
const SALVO_CARTRIDGE_SCALE := Vector2(0.72, 0.72)
const SALVO_DELAYS := [0.0, 0.055, 0.11]
const SALVO_LATERAL_OFFSETS := [-3.0, 0.0, 3.0]
const SALVO_ANGLE_OFFSETS := [-0.16, 0.0, 0.16]
const DISPENSER_OFFSETS := {
	"fighter": [Vector2(-5,14),Vector2(-3,15),Vector2(0,16),Vector2(3,15),Vector2(5,14)],
	"bomber": [Vector2(-6,16),Vector2(-3,17),Vector2(0,18),Vector2(3,17),Vector2(6,16)],
}

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
	if diverted > 0 and _has_property(scene, "countermeasures_decoyed"):
		scene.set("countermeasures_decoyed", int(scene.get("countermeasures_decoyed")) + diverted)
	scene.set("enemy_bullets", bullets)
	_charges -= 1
	_cooldown = CountermeasureRules.COOLDOWN_SECONDS
	_serial += 1
	var combat_art := get_node_or_null("/root/CombatArtDirector")
	var bank := int(combat_art.call("propulsion_bank_frame_index")) if combat_art != null and combat_art.has_method("propulsion_bank_frame_index") else 2
	var craft := get_node_or_null("/root/CraftStateDirector")
	var form := str(craft.call("current_form")) if craft != null and craft.has_method("current_form") else "fighter"
	var registrations: Array = DISPENSER_OFFSETS.get(form, DISPENSER_OFFSETS["fighter"])
	var bank_angle := -0.22 if bank == 0 else (0.22 if bank == 4 else 0.0)
	var dispenser: Vector2 = registrations[clampi(bank,0,4)]
	for salvo_index in range(SALVO_DELAYS.size()):
		_events.append({
			"position": player + dispenser + Vector2(SALVO_LATERAL_OFFSETS[salvo_index], float(salvo_index)),
			"angle": bank_angle + SALVO_ANGLE_OFFSETS[salvo_index],
			"age": -SALVO_DELAYS[salvo_index],
			"serial": _serial * SALVO_DELAYS.size() + salvo_index,
		})
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
		if age < 0.0:
			continue
		var ratio := clampf(age / CountermeasureRules.EFFECT_SECONDS, 0.0, 0.999)
		var frame_index := clampi(int(floor(ratio * float(FLARE_FRAMES.size()))), 0, FLARE_FRAMES.size() - 1)
		var texture: Texture2D = FLARE_FRAMES[frame_index]
		var position: Vector2 = event.get("position", Vector2.ZERO)
		position.y += ratio * CountermeasureRules.DECOY_TRAIL_DISTANCE
		position.x += sin(ratio * PI) * (-18.0 if posmod(int(event.get("serial", 0)), 2) == 0 else 18.0)
		var trail_direction := Vector2(sin(float(event.get("angle", 0.0))), cos(float(event.get("angle", 0.0))))
		for puff_index in range(3):
			var trail_ratio := clampf(ratio - float(puff_index + 1) * 0.075, 0.0, 1.0)
			if trail_ratio <= 0.0:
				continue
			var puff_position := position - trail_direction * float(8 + puff_index * 7)
			var puff_alpha := (1.0 - ratio) * (0.20 - float(puff_index) * 0.04)
			surface.draw_circle(puff_position.round(), 2.5 + float(puff_index), Color(0.68, 0.72, 0.70, puff_alpha))
		if ratio < 0.18:
			var ignition := 1.0 - ratio / 0.18
			surface.draw_circle(position.round(), 6.0 + ratio * 18.0, Color(1.0, 0.82, 0.38, 0.18 * ignition))
			surface.draw_arc(position.round(), 5.0 + ratio * 20.0, 0.0, TAU, 20, Color(1.0, 0.94, 0.72, 0.72 * ignition), 1.2)
		surface.draw_set_transform(position.round(), float(event.get("angle",0.0)), SALVO_CARTRIDGE_SCALE)
		surface.draw_texture(texture, -FLARE_PIVOT, Color(1,1,1,1.0-smoothstep(0.72,1.0,ratio)))
		surface.draw_set_transform(Vector2.ZERO)

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
