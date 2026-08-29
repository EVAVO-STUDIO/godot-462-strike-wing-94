class_name BossSignatureRules
extends RefCounted

const SWARM := "swarm_controller"
const FORGE := "ai_forge_core"
const ORBITAL := "orbital_command_node"
const PHASE_ARRAY := "phase_control_array"
const WARDEN := "station_warden"
const ARK := "machine_ark"

static func is_signature_boss(boss_id: String) -> bool:
	return boss_id in [SWARM, FORGE, ORBITAL, PHASE_ARRAY, WARDEN, ARK]

static func interval(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return [4.8, 3.8, 2.9][p - 1]
		FORGE: return [5.4, 4.2, 3.2][p - 1]
		ORBITAL: return [5.8, 4.5, 3.4][p - 1]
		PHASE_ARRAY: return [5.0, 3.9, 2.9][p - 1]
		WARDEN: return [5.6, 4.2, 3.0][p - 1]
		ARK: return [6.2, 4.8, 3.5][p - 1]
	return 999.0

static func shot_count(boss_id: String, phase: int) -> int:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return 3 + p * 2
		FORGE: return 2 + p
		ORBITAL: return 2 + p
		PHASE_ARRAY: return 4 + p * 2
		WARDEN: return 3 + p
		ARK: return 4 + p * 2
	return 0

static func damage(boss_id: String, phase: int) -> int:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return 8 + p * 2
		FORGE: return 13 + p * 2
		ORBITAL: return 16 + p * 3
		PHASE_ARRAY: return 12 + p * 3
		WARDEN: return 18 + p * 3
		ARK: return 20 + p * 4
	return 8

static func projectile_speed(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return 165.0 + p * 12.0
		FORGE: return 145.0 + p * 10.0
		ORBITAL: return 320.0 + p * 45.0
		PHASE_ARRAY: return 230.0 + p * 28.0
		WARDEN: return 285.0 + p * 32.0
		ARK: return 340.0 + p * 42.0
	return 160.0

static func telegraph(boss_id: String) -> String:
	match boss_id:
		SWARM: return "SWARM VECTOR LOCK"
		FORGE: return "FORGE MISSILE BATTERY"
		ORBITAL: return "ORBITAL KINETIC LANE"
		PHASE_ARRAY: return "PHASE ARRAY CROSSLOCK"
		WARDEN: return "WARDEN ENERGY GRID"
		ARK: return "ARK STRATEGIC SALVO"
	return "SIGNATURE ATTACK"

static func spread_radians(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	match boss_id:
		SWARM: return deg_to_rad(24.0 + p * 5.0)
		FORGE: return deg_to_rad(10.0 + p * 3.0)
		ORBITAL: return deg_to_rad(18.0 + p * 2.0)
		PHASE_ARRAY: return deg_to_rad(32.0 + p * 4.0)
		WARDEN: return deg_to_rad(14.0 + p * 3.0)
		ARK: return deg_to_rad(26.0 + p * 3.0)
	return deg_to_rad(12.0)
