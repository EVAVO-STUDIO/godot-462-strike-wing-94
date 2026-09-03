extends CanvasLayer

const PlayerMissileRules = preload("res://scripts/player_missile_rules.gd")
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const RETICLES := [
	preload("res://assets/runtime/ui/hud/player_lock/track.png"),
	preload("res://assets/runtime/ui/hud/player_lock/acquire.png"),
	preload("res://assets/runtime/ui/hud/player_lock/locked.png"),
]

var _surface: Control
var _target_uid := -1
var _target_position := Vector2.ZERO
var _lock_ratio := 0.0
var _missiles := PlayerMissileRules.MAX_MISSILES
var _cooldown := 0.0
var _next_uid := 1
var _last_phase := -1
var _last_mission := -1
var _launch_side := -1.0
var _lock_cued := false

func _ready() -> void:
	layer = 29
	_surface = load("res://scripts/player_missile_surface.gd").new()
	_surface.set("director", self)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.custom_minimum_size = Vector2(640, 360)

func _process(_delta: float) -> void:
	if _surface != null:
		_surface.queue_redraw()

func update_targeting(scene: Object, delta: float) -> void:
	if not _supports(scene):
		return
	var phase := int(scene.get("phase"))
	var mission := int(scene.get("mission_index")) if SceneContractCache.has_property(scene, "mission_index") else 0
	if phase == 1 and (_last_phase != 1 or mission != _last_mission):
		_reset_sortie()
	_last_phase = phase
	_last_mission = mission
	if phase != 1:
		_target_uid = -1
		_lock_ratio = 0.0
		return
	_cooldown = maxf(0.0, _cooldown - maxf(0.0, delta))
	var enemies: Array = scene.get("enemies")
	_assign_target_uids(enemies)
	scene.set("enemies", enemies)
	var player: Vector2 = scene.get("player_position")
	var index := PlayerMissileRules.acquire_index(enemies, player, _target_uid)
	if index < 0:
		_target_uid = -1
		_lock_ratio = move_toward(_lock_ratio, 0.0, delta * 2.8)
		_lock_cued = false
	else:
		var candidate: Dictionary = enemies[index]
		var uid := int(candidate.get("target_uid", -1))
		if uid != _target_uid:
			_target_uid = uid
			_lock_ratio = minf(_lock_ratio, 0.18)
			_lock_cued = false
		_target_position = candidate.get("position", Vector2.ZERO)
		_lock_ratio = move_toward(_lock_ratio, 1.0, delta / PlayerMissileRules.LOCK_SECONDS)
		if _lock_ratio >= 0.999 and not _lock_cued:
			_play_event("seeker_lock")
			_lock_cued = true
	if Input.is_action_just_pressed("fire_missile"):
		launch(scene)
	_update_guided_missiles(scene, delta)

func launch(scene: Object) -> bool:
	if _missiles <= 0:
		_set_status(scene, "AIM-9 STORES EMPTY")
		return false
	if _cooldown > 0.0 or _target_uid < 0 or _lock_ratio < 0.999:
		_set_status(scene, "SEEKER NO LOCK")
		return false
	var player: Vector2 = scene.get("player_position")
	var bullets: Array = scene.get("bullets")
	_launch_side *= -1.0
	bullets.append({
		"position": player + Vector2(13.0 * _launch_side, -7.0),
		"velocity": Vector2.UP * PlayerMissileRules.MISSILE_SPEED,
		"damage": PlayerMissileRules.DAMAGE,
		"weapon_id": "sidewinder",
		"player_guided_missile": true,
		"target_uid": _target_uid,
		"life": PlayerMissileRules.LIFE_SECONDS,
	})
	scene.set("bullets", bullets)
	_missiles -= 1
	_cooldown = PlayerMissileRules.COOLDOWN_SECONDS
	_set_status(scene, "FOX TWO // AIM-9 AWAY")
	_play_event("missile_launch")
	return true

func _update_guided_missiles(scene: Object, delta: float) -> void:
	var bullets: Array = scene.get("bullets")
	var enemies: Array = scene.get("enemies")
	var changed := false
	for index in range(bullets.size() - 1, -1, -1):
		if typeof(bullets[index]) != TYPE_DICTIONARY or not bool(bullets[index].get("player_guided_missile", false)):
			continue
		var missile: Dictionary = bullets[index]
		missile["life"] = float(missile.get("life", PlayerMissileRules.LIFE_SECONDS)) - delta
		if float(missile["life"]) <= 0.0:
			bullets.remove_at(index)
			changed = true
			continue
		var target := _enemy_for_uid(enemies, int(missile.get("target_uid", -1)))
		if not target.is_empty():
			missile["velocity"] = PlayerMissileRules.steer_velocity(missile.get("velocity", Vector2.UP * PlayerMissileRules.MISSILE_SPEED), missile.get("position", Vector2.ZERO), target.get("position", Vector2.ZERO), delta)
		bullets[index] = missile
		changed = true
	if changed:
		scene.set("bullets", bullets)

func _assign_target_uids(enemies: Array) -> void:
	for index in range(enemies.size()):
		if typeof(enemies[index]) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemies[index]
		if int(enemy.get("target_uid", -1)) < 0:
			enemy["target_uid"] = _next_uid
			_next_uid += 1
			enemies[index] = enemy

func _enemy_for_uid(enemies: Array, uid: int) -> Dictionary:
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and int(enemy.get("target_uid", -1)) == uid and int(enemy.get("hp", 0)) > 0:
			return enemy
	return {}

func draw_targeting(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var position := _target_position
	var ratio := _lock_ratio
	var ammo := _missiles
	if "--capture-player-lock" in OS.get_cmdline_user_args():
		position = Vector2(235, 145)
		ratio = 1.0
		ammo = 3
	if ratio <= 0.02:
		return
	var frame := 2 if ratio >= 0.999 else (1 if ratio >= 0.48 else 0)
	var pulse := Vector2.ONE * (1.0 + (0.04 if frame == 2 and posmod(Time.get_ticks_msec() / 140, 2) == 0 else 0.0))
	surface.draw_set_transform(position.round(), 0.0, pulse)
	surface.draw_texture(RETICLES[frame], Vector2(-16, -16))
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var label := "LOCK" if frame == 2 else "ACQ %02d" % int(roundf(ratio * 100.0))
	PixelFont.draw_text(surface, "%s  AIM9 %d" % [label, ammo], position + Vector2(-25, 19), 1, Color("efcc62") if frame == 2 else Color("73b8d2"), 1)

func lock_ratio() -> float:
	return _lock_ratio

func missiles_remaining() -> int:
	return _missiles

func target_uid() -> int:
	return _target_uid

func _reset_sortie() -> void:
	_target_uid = -1
	_lock_ratio = 0.0
	_missiles = PlayerMissileRules.MAX_MISSILES
	_cooldown = 0.0
	_next_uid = 1
	_launch_side = -1.0
	_lock_cued = false

func _play_event(event_id: String) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var audio := tree.root.get_node_or_null("RetroSfxDirector") if tree != null and tree.root != null else null
	if audio != null and audio.has_method("play_event"):
		audio.call("play_event", event_id)

func _set_status(scene: Object, text: String) -> void:
	if SceneContractCache.has_property(scene, "status_text"):
		scene.set("status_text", text)
	if SceneContractCache.has_property(scene, "status_timer"):
		scene.set("status_timer", 1.2)

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "enemies", "bullets", "player_position"])
