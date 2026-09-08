class_name AltitudeRules
extends RefCounted

const LOW := "low"
const MID := "mid"
const HIGH := "high"
const ORBITAL := "orbital"
const BANDS := [LOW, MID, HIGH, ORBITAL]
const TRANSITION_SECONDS := 1.40
const TALL_SURFACE_HAZARDS := ["strategic_silo", "radar_site", "fortified_turret", "factory_defence_node", "civilian_village", "field_clinic"]

static func sanitize(band: String) -> String:
	return band if band in BANDS else MID

static func index(band: String) -> int:
	return BANDS.find(sanitize(band))

static func display_name(band: String) -> String:
	match sanitize(band):
		LOW: return "LOW ALT"
		MID: return "MID ALT"
		HIGH: return "HIGH ALT"
		ORBITAL: return "ATMOS/SPACE"
	return "MID ALT"

static func ground_scale(band: String) -> float:
	match sanitize(band):
		LOW: return 1.0
		MID: return 0.68
		HIGH: return 0.34
		ORBITAL: return 0.12
	return 0.68

static func ground_target_multiplier(band: String) -> float:
	match sanitize(band):
		LOW: return 1.25
		MID: return 0.92
		HIGH: return 0.45
		ORBITAL: return 0.12
	return 0.92

static func air_target_multiplier(band: String) -> float:
	match sanitize(band):
		LOW: return 0.90
		MID: return 1.0
		HIGH: return 1.12
		ORBITAL: return 1.18
	return 1.0

static func clouds_in_front(band: String) -> bool:
	return sanitize(band) in [MID, HIGH]

static func allows_ground_targets(band: String) -> bool:
	return sanitize(band) in [LOW, MID]

static func surface_collision_active(band: String, diving_to_low: bool = false, transition_ratio: float = 0.0) -> bool:
	return sanitize(band) == LOW or (diving_to_low and transition_ratio >= 0.72)

static func is_tall_surface_hazard(contact_id: String) -> bool:
	return contact_id in TALL_SURFACE_HAZARDS

static func surface_collision_radius(contact_id: String) -> float:
	match contact_id:
		"strategic_silo", "factory_defence_node": return 25.0
		"civilian_village": return 29.0
		"radar_site", "fortified_turret", "field_clinic": return 22.0
	return 0.0

static func supports_form(band: String, form: String) -> bool:
	var safe_band := sanitize(band)
	if safe_band == ORBITAL:
		return form == "fighter"
	return form in ["fighter", "bomber"]

static func allows_enemy_class(band: String, enemy_class: String, is_boss := false) -> bool:
	if is_boss or enemy_class == "boss":
		return true
	var safe_band := sanitize(band)
	match enemy_class:
		"air":
			return true
		"ground", "sea":
			return safe_band in [LOW, MID]
	return false

static func allows_enemy_archetype(band: String, archetype: Dictionary) -> bool:
	return allows_enemy_class(
		band,
		str(archetype.get("class", "air")),
		bool(archetype.get("boss", false))
	)

static func enemy_weapon_can_engage(band: String, enemy_class: String, weapon_id: String, is_boss: bool = false) -> bool:
	if is_boss or enemy_class in ["air", "boss"]:
		return true
	var safe_band := sanitize(band)
	if safe_band == ORBITAL:
		return false
	if weapon_id == "missile":
		return safe_band in [LOW, MID, HIGH]
	return safe_band in [LOW, MID]

static func adjacent_band(current: String, direction: int) -> String:
	var current_index := index(current)
	if current_index < 0 or direction == 0:
		return sanitize(current)
	return BANDS[clampi(current_index + signi(direction), 0, BANDS.size() - 1)]

static func is_adjacent(from_band: String, to_band: String) -> bool:
	return absi(index(from_band) - index(to_band)) == 1

static func transition_direction(from_band: String, to_band: String) -> int:
	return signi(index(to_band) - index(from_band))

static func transition_ground_scale(from_band: String, to_band: String, ratio: float) -> float:
	return lerpf(ground_scale(from_band), ground_scale(to_band), smoothstep(0.0, 1.0, clampf(ratio, 0.0, 1.0)))

static func allowed_manual_bands(window: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for band in window.get("bands", []):
		var safe := sanitize(str(band))
		if safe not in result:
			result.append(safe)
	return result
