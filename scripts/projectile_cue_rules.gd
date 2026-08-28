class_name ProjectileCueRules
extends RefCounted

const TYPE_MISSILE := "MISSILE"
const TYPE_CANNON := "CANNON"
const TYPE_BURST := "BURST"

static func projectile_type(shot: Dictionary) -> String:
	if bool(shot.get("homing", false)):
		return TYPE_MISSILE
	var damage := int(shot.get("damage", 0))
	var velocity: Vector2 = shot.get("velocity", Vector2.ZERO)
	if damage >= 14 or velocity.length() <= 130.0:
		return TYPE_CANNON
	return TYPE_BURST

static func radius_for(shot: Dictionary) -> float:
	match projectile_type(shot):
		TYPE_MISSILE:
			return 5.0
		TYPE_CANNON:
			return 4.0
		_:
			return 2.5

static func trail_length_for(shot: Dictionary) -> float:
	match projectile_type(shot):
		TYPE_MISSILE:
			return 13.0
		TYPE_CANNON:
			return 8.0
		_:
			return 4.0

static func direction_for(shot: Dictionary) -> Vector2:
	var velocity: Vector2 = shot.get("velocity", Vector2.DOWN)
	if velocity.length_squared() < 0.001:
		return Vector2.DOWN
	return velocity.normalized()
