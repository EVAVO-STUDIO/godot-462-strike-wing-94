class_name BossSignatureRules
extends RefCounted

const SWARM := "swarm_controller"
const FORGE := "ai_forge_core"
const ORBITAL := "orbital_command_node"

static func is_signature_boss(boss_id: String) -> bool:
	return boss_id in [SWARM, FORGE, ORBITAL]

static func interval(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return [4.8, 3.8, 2.9][p - 1]
		FORGE: return [5.4, 4.2, 3.2][p - 1]
		ORBITAL: return [5.8, 4.5, 3.4][p - 1]
	return 999.0

static func shot_count(boss_id: String, phase: int) -> int:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return 3 + p * 2
		FORGE: return 2 + p
		ORBITAL: return 2 + p
	return 0

static func damage(boss_id: String, phase: int) -> int:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return 8 + p * 2
		FORGE: return 13 + p * 2
		ORBITAL: return 16 + p * 3
	return 8

static func projectile_speed(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return 165.0 + p * 12.0
		FORGE: return 145.0 + p * 10.0
		ORBITAL: return 320.0 + p * 45.0
	return 160.0

static func telegraph(boss_id: String) -> String:
	match boss_id:
		SWARM: return "SWARM VECTOR LOCK"
		FORGE: return "FORGE MISSILE BATTERY"
		ORBITAL: return "ORBITAL KINETIC LANE"
	return "SIGNATURE ATTACK"

static func spread_radians(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return deg_to_rad(24.0 + p * 5.0)
		FORGE: return deg_to_rad(10.0 + p * 3.0)
		ORBITAL: return deg_to_rad(18.0 + p * 2.0)
	return deg_to_rad(12.0)
