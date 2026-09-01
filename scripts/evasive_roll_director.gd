extends Node

const EvasiveRollRules = preload("res://scripts/evasive_roll_rules.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

var _elapsed := 99.0
var _cooldown := 0.0
var _direction := 0
var _previous_travel := 0.0
var _form := "fighter"

func update_maneuver(scene: Object, delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - maxf(0.0, delta))
	if not active() and Input.is_action_just_pressed("evasive_roll") and _cooldown <= 0.0:
		var axis := Input.get_axis("move_left", "move_right")
		if absf(axis) >= 0.25:
			_begin(scene, -1 if axis < 0.0 else 1)
	if not active():
		return
	_elapsed = minf(EvasiveRollRules.duration(_form), _elapsed + maxf(0.0, delta))
	var travel := EvasiveRollRules.travel_ratio(progress())
	var offset := float(_direction) * (travel - _previous_travel) * EvasiveRollRules.displacement(_form)
	_previous_travel = travel
	if _has_property(scene, "player_position"):
		var p: Vector2 = scene.get("player_position")
		p.x = clampf(p.x + offset, 26.0, 614.0)
		scene.set("player_position", p)
	if _elapsed >= EvasiveRollRules.duration(_form):
		_cooldown = EvasiveRollRules.RECOVERY_SECONDS

func _begin(scene: Object, direction: int) -> void:
	_direction = clampi(direction, -1, 1)
	_elapsed = 0.0
	_previous_travel = 0.0
	var craft := get_node_or_null("/root/CraftFormDirector")
	_form = str(craft.call("current_form")) if craft != null and craft.has_method("current_form") else "fighter"
	if _has_property(scene, "status_text"):
		scene.set("status_text", "EVASIVE BREAK  %s" % ("LEFT" if _direction < 0 else "RIGHT"))
	if _has_property(scene, "status_timer"):
		scene.set("status_timer", 0.55)

func active() -> bool:
	return _elapsed < EvasiveRollRules.duration(_form)

func progress() -> float:
	return clampf(_elapsed / EvasiveRollRules.duration(_form), 0.0, 1.0) if active() else 0.0

func direction() -> int:
	return _direction if active() else 0

func collision_multiplier() -> float:
	return EvasiveRollRules.collision_multiplier(progress()) if active() else 1.0

func _has_property(subject: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(subject, property_name)
