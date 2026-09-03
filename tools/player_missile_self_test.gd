extends SceneTree

const Rules = preload("res://scripts/player_missile_rules.gd")
var failures: Array[String] = []

class Fixture:
	extends Node
	var phase := 1
	var mission_index := 0
	var player_position := Vector2(320, 300)
	var enemies: Array = []
	var bullets: Array = []
	var status_text := ""
	var status_timer := 0.0

func _initialize() -> void:
	if not InputMap.has_action("fire_missile"):
		InputMap.add_action("fire_missile")
	var player := Vector2(320, 300)
	var air := {"position":Vector2(350, 120), "category":"air", "hp":20, "target_uid":7}
	var ground := {"position":Vector2(320, 120), "category":"ground", "hp":20, "target_uid":8}
	var behind := {"position":Vector2(320, 330), "category":"air", "hp":20, "target_uid":9}
	_expect(Rules.is_valid_target(air, player), "aircraft in the forward seeker cone should be valid")
	_expect(not Rules.is_valid_target(ground, player), "Sidewinder seeker must not replace air-to-ground weapons")
	_expect(not Rules.is_valid_target(behind, player), "seeker must not lock behind the VX-94")
	_expect(Rules.acquire_index([ground, air, behind], player) == 1, "seeker should select the valid aircraft")
	var steered := Rules.steer_velocity(Vector2.UP * Rules.MISSILE_SPEED, Vector2(320,260), Vector2(390,100), 0.1)
	_expect(steered.x > 0.0 and absf(steered.length() - Rules.MISSILE_SPEED) < 0.1, "guided missile should turn toward target without losing motor speed")
	var scene := Fixture.new()
	root.add_child(scene)
	scene.enemies = [air.duplicate(true)]
	var director: Node = load("res://scripts/player_missile_director.gd").new()
	root.add_child(director)
	director.call("update_targeting", scene, Rules.LOCK_SECONDS)
	_expect(float(director.call("lock_ratio")) >= 0.999, "valid target should acquire after authored lock time")
	_expect(bool(director.call("launch", scene)), "hard lock with stores should launch")
	_expect(scene.bullets.size() == 1 and bool(scene.bullets[0].get("player_guided_missile", false)), "launch should create a dedicated guided projectile")
	_expect(int(scene.bullets[0].get("target_uid", -1)) == int(director.call("target_uid")), "missile should retain the stable target identity")
	_expect(int(director.call("missiles_remaining")) == Rules.MAX_MISSILES - 1, "launch should consume exactly one store")
	_expect(scene.status_text.contains("FOX TWO"), "successful launch should use concise fighter brevity")
	var before: Vector2 = scene.bullets[0].velocity
	director.call("update_targeting", scene, 0.1)
	_expect(Vector2(scene.bullets[0].velocity).x > before.x, "launched missile should continue steering in simulation")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('PlayerMissileDirector="*res://scripts/player_missile_director.gd"'), "player missile director should be a project autoload")
	for path in ["res://assets/runtime/effects/projectiles/player_sidewinder/0.png", "res://assets/runtime/ui/hud/player_lock/locked.png"]:
		var texture: Texture2D = load(path)
		_expect(texture != null and texture.get_width() > 0, "missing authored player missile asset: %s" % path)
	director.queue_free()
	scene.queue_free()
	if failures.is_empty():
		print("HYPERSONIC player missile self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
