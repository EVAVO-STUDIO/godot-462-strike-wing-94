extends Node

const DirectedEnergyRules = preload("res://scripts/directed_energy_rules.gd")

func _ready() -> void:
	process_priority = -1

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	var bullets: Array = scene.get("bullets")
	var enemies: Array = scene.get("enemies")
	if bullets.is_empty() or enemies.is_empty():
		return
	var bullets_changed := false
	var enemies_changed := false
	for bi in range(bullets.size()):
		var bullet = bullets[bi]
		if typeof(bullet) != TYPE_DICTIONARY or not DirectedEnergyRules.can_discharge(bullet):
			continue
		var position: Vector2 = bullet.get("position", Vector2.ZERO)
		var primary_index := DirectedEnergyRules.trigger_enemy_index(position, enemies)
		if primary_index < 0:
			continue
		bullet["pulse_discharged"] = true
		bullets[bi] = bullet
		bullets_changed = true
		var secondary := DirectedEnergyRules.secondary_indices(position, enemies, primary_index)
		for enemy_index in secondary:
			if enemy_index < 0 or enemy_index >= enemies.size():
				continue
			var enemy: Dictionary = enemies[enemy_index]
			var hp := maxi(0, int(enemy.get("hp", 0)))
			if hp <= 0:
				continue
			var damage := DirectedEnergyRules.SECONDARY_DAMAGE
			if bool(enemy.get("boss", false)):
				damage = mini(damage, maxi(0, hp - 1))
			enemy["hp"] = hp - damage
			enemies[enemy_index] = enemy
			enemies_changed = true
	if bullets_changed:
		scene.set("bullets", bullets)
	if enemies_changed:
		scene.set("enemies", enemies)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("bullets") and names.has("enemies")
