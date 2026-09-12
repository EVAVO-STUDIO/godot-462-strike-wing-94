extends CanvasLayer

const CountermeasureRules = preload("res://scripts/countermeasure_rules.gd")
const CountermeasureSurface = preload("res://scripts/countermeasure_surface.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const FLARE_FRAMES := [
	preload("res://assets/runtime/effects/countermeasure/flare_0.png"),
	preload("res://assets/runtime/effects/countermeasure/flare_1.png"),
	preload("res://assets/runtime/effects/countermeasure/flare_2.png"),
	preload("res://assets/runtime/effects/countermeasure/flare_3.png"),
]
const FLARE_PIVOT := Vector2(24, 10)
# Each cel already contains a paired cartridge. Keep the pair crisp but small
# enough that five staged ejections read as ten individual decoys, not one fire.
const SALVO_CARTRIDGE_SCALE := Vector2(0.60,0.60)
const SALVO_DELAYS := [0.0,0.045,0.090,0.135,0.180]
const SALVO_LATERAL_OFFSETS := [-17.0,17.0,-12.0,12.0,0.0]
const SALVO_ANGLE_OFFSETS := [-0.92,0.84,-0.58,0.66,-0.14]
const SALVO_SPEED_FACTORS := [0.94,1.08,0.80,1.16,0.88]
const DISPENSER_OFFSETS := {
	"fighter": [Vector2(-10,14),Vector2(-7,15),Vector2(0,16),Vector2(7,15),Vector2(10,14)],
	"bomber": [Vector2(-14,16),Vector2(-9,17),Vector2(0,18),Vector2(9,17),Vector2(14,16)],
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
			"speed_factor": SALVO_SPEED_FACTORS[salvo_index],
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
		var trail_direction := Vector2(sin(float(event.get("angle", 0.0))), cos(float(event.get("angle", 0.0))))
		# Each cassette cup leaves with slightly different impulse, then loses
		# energy into the slipstream and drops aft. Stable serial drift prevents
		# the port/starboard pairs forming a perfect arcade V while keeping the
		# cartridge, incandescent head and smoke on one physical trajectory.
		var speed_factor := float(event.get("speed_factor",1.0))
		var ballistic_time := 1.0-pow(1.0-ratio,1.42)
		var serial_drift := float(posmod(int(event.get("serial",0))*17,13)-6)
		position += trail_direction*ballistic_time*CountermeasureRules.DECOY_TRAIL_DISTANCE*speed_factor
		position += Vector2(serial_drift*ratio*ratio*0.72,ratio*ratio*18.0)
		for puff_index in range(4):
			var trail_ratio := clampf(ratio - float(puff_index + 1) * 0.075, 0.0, 1.0)
			if trail_ratio <= 0.0:
				continue
			var puff_position := position - trail_direction * float(8 + puff_index * 7)
			var puff_alpha := (1.0 - ratio) * (0.24 - float(puff_index) * 0.038)
			var smoke := PersistentEffectArtLibrary.frame_for_ratio("damage_smoke",trail_ratio)
			var smoke_size := Vector2.ONE*(15.0+float(puff_index)*5.0)
			var smoke_rect := Rect2((puff_position-smoke_size*0.5).round(),smoke_size.round())
			# A cool soot underside survives snowfields; the restrained warm-grey
			# body remains visible over water and night terrain. Both use the same
			# authored cel and stay subordinate to the incandescent cartridge.
			surface.draw_texture_rect(smoke,Rect2(smoke_rect.position+Vector2(1,2),smoke_rect.size),false,Color(0.035,0.045,0.050,puff_alpha*1.45))
			surface.draw_texture_rect(smoke,smoke_rect,false,Color(0.58,0.60,0.56,puff_alpha*1.12))
		if ratio < 0.18:
			var ignition := 1.0 - ratio / 0.18
			var sparks := PersistentEffectArtLibrary.frame_for_ratio("damage_sparks",ratio/0.18)
			var spark_size := Vector2.ONE*(18.0+ratio*24.0)
			surface.draw_texture_rect(sparks,Rect2((position-spark_size*0.5).round(),spark_size.round()),false,Color(1.0,0.88,0.60,ignition*0.72))
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
