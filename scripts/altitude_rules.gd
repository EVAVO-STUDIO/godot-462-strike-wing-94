class_name AltitudeRules
extends RefCounted

const LOW := "low"
const MID := "mid"
const HIGH := "high"
const ORBITAL := "orbital"
const BANDS := [LOW, MID, HIGH, ORBITAL]

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

static func supports_form(band: String, form: String) -> bool:
	var safe_band := sanitize(band)
	if safe_band == LOW:
		return form == "bomber" or form == "fighter"
	if safe_band == ORBITAL:
		return form == "fighter"
	return true
