class_name BossRules
extends RefCounted

# Reviewed production canvases. Boss centers are derived from their actual
# vertical registration so every complete silhouette clears the integrated HUD
# at y=69 with a seven-pixel breathing lane.
const HUD_CLEARANCE_Y := 76.0
const PRESENTATION_HEIGHT := {
	"gunship_alpha": 78.0,
	"armoured_train": 150.0,
	"missile_cruiser": 154.0,
	"swarm_controller": 88.0,
	"ai_forge_core": 112.0,
	"orbital_command_node": 104.0,
	"phase_control_array": 126.0,
	"station_warden": 116.0,
	"machine_ark": 128.0,
}

static func entry_center_y(boss_id: String) -> float:
	return HUD_CLEARANCE_Y + float(PRESENTATION_HEIGHT.get(boss_id, 92.0)) * 0.5

static func arrival_clears_enemy(boss_id: String, enemy: Dictionary) -> bool:
	# Air-command bosses take possession of the combat lane: surviving aircraft
	# peel away before the command hull enters, while terrain-bound emplacements
	# remain part of the battlefield. This produces a readable arcade reveal
	# without erasing grounded mission targets.
	if boss_id != "gunship_alpha" or bool(enemy.get("boss", false)):
		return false
	return str(enemy.get("category", "air")) == "air"

static func phase_for(hp: int, max_hp: int) -> int:
	if max_hp <= 0:
		return 1
	var ratio := float(hp) / float(max_hp)
	if ratio <= 0.33:
		return 3
	if ratio <= 0.66:
		return 2
	return 1

static func phase_fire_multiplier(phase: int) -> float:
	match phase:
		3: return 0.62
		2: return 0.78
		_: return 1.0

static func phase_speed_multiplier(phase: int) -> float:
	match phase:
		3: return 1.28
		2: return 1.12
		_: return 1.0

static func phase_drift_multiplier(phase: int) -> float:
	match phase:
		3: return 1.55
		2: return 1.25
		_: return 1.0

static func phase_salvo_interval(boss_id: String, phase: int) -> float:
	var p := clampi(phase, 1, 3)
	if boss_id == "gunship_alpha":
		return [3.35, 2.4, 1.55][p - 1]
	return 999.0 if p <= 1 else (2.4 if p == 2 else 1.55)

static func phase_salvo_enabled(boss_id: String, phase: int) -> bool:
	return boss_id == "gunship_alpha" or phase >= 2

static func volley_count(weapon_id: String, phase: int) -> int:
	if phase <= 1:
		return 3 if weapon_id == "twin_burst" else 1
	match weapon_id:
		"missile": return 2 if phase == 2 else 3
		"twin_burst": return 2 if phase == 2 else 3
		"cannon", "deck_gun": return 2
		_: return 1 if phase == 2 else 2

static func volley_spread_radians(weapon_id: String, phase: int) -> float:
	if phase <= 1:
		return 0.18 if weapon_id == "twin_burst" else 0.0
	match weapon_id:
		"missile": return 0.10 if phase == 2 else 0.16
		"twin_burst": return 0.13 if phase == 2 else 0.21
		_: return 0.08 if phase == 2 else 0.14

static func weak_point_multiplier(phase: int) -> float:
	return 1.35 if phase >= 3 else 1.0
