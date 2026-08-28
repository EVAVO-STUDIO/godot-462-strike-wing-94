class_name BossRules
extends RefCounted

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

static func volley_count(weapon_id: String, phase: int) -> int:
	if phase <= 1:
		return 1
	match weapon_id:
		"missile": return 2 if phase == 2 else 3
		"twin_burst": return 2 if phase == 2 else 3
		"cannon", "deck_gun": return 2
		_: return 1 if phase == 2 else 2

static func volley_spread_radians(weapon_id: String, phase: int) -> float:
	if phase <= 1:
		return 0.0
	match weapon_id:
		"missile": return 0.10 if phase == 2 else 0.16
		"twin_burst": return 0.13 if phase == 2 else 0.21
		_: return 0.08 if phase == 2 else 0.14

static func weak_point_multiplier(phase: int) -> float:
	return 1.35 if phase >= 3 else 1.0
