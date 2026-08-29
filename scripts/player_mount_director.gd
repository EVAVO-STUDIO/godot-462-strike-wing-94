extends Node

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const PlayerMountRules = preload("res://scripts/player_mount_rules.gd")

var mounts: Array = []

func _ready() -> void:
	process_priority = -35
	var data = ContentCatalog.load_json("res://data/player_mounts.json")
	if typeof(data) == TYPE_DICTIONARY:
		mounts = data.get("mounts", [])

func primary_offsets(form: String, weapon: Dictionary, projectile_count: int) -> Array[Vector2]:
	return PlayerMountRules.primary_offsets(mounts, form, weapon, projectile_count)

func support_offsets(form: String, support: Dictionary, projectile_count: int, alternating_side: bool = false) -> Array[Vector2]:
	return PlayerMountRules.support_offsets(mounts, form, support, projectile_count, alternating_side)

func bomber_rotary_deployed(form: String, weapon: Dictionary) -> bool:
	return PlayerMountRules.bomber_rotary_deployed(form, weapon)

func mount_count() -> int:
	return mounts.size()
