class_name EnvironmentRules
extends RefCounted

const AltitudeRules = preload("res://scripts/altitude_rules.gd")

static func profile_for(profiles: Array, environment_id: String) -> Dictionary:
	for profile in profiles:
		if typeof(profile) == TYPE_DICTIONARY and str(profile.get("id", "")) == environment_id:
			return profile
	return {}

static func parallax_speed(profile: Dictionary, band: String, layer_name: String) -> float:
	var base := float(profile.get("%s_speed" % layer_name, 0.0))
	var altitude := AltitudeRules.index(band)
	var multiplier: float = [1.35, 1.0, 0.62, 0.28][clampi(altitude, 0, 3)]
	return maxf(0.0, base * multiplier)

static func blended_parallax_speed(profile: Dictionary, from_band: String, to_band: String, ratio: float, layer_name: String) -> float:
	var t := smoothstep(0.0, 1.0, clampf(ratio, 0.0, 1.0))
	return lerpf(parallax_speed(profile, from_band, layer_name), parallax_speed(profile, to_band, layer_name), t)

static func ground_detail_scale(band: String) -> float:
	return AltitudeRules.ground_scale(band)

static func blended_ground_detail_scale(from_band: String, to_band: String, ratio: float) -> float:
	return AltitudeRules.transition_ground_scale(from_band, to_band, ratio)

static func cloud_density(band: String) -> float:
	match AltitudeRules.sanitize(band):
		AltitudeRules.LOW: return 0.12
		AltitudeRules.MID: return 0.45
		AltitudeRules.HIGH: return 0.82
		AltitudeRules.ORBITAL: return 0.06
	return 0.45

static func blended_cloud_density(from_band: String, to_band: String, ratio: float) -> float:
	var t := smoothstep(0.0, 1.0, clampf(ratio, 0.0, 1.0))
	return lerpf(cloud_density(from_band), cloud_density(to_band), t)

static func horizon_glow(band: String) -> float:
	match AltitudeRules.sanitize(band):
		AltitudeRules.LOW: return 0.0
		AltitudeRules.MID: return 0.05
		AltitudeRules.HIGH: return 0.18
		AltitudeRules.ORBITAL: return 0.78
	return 0.05

static func blended_horizon_glow(from_band: String, to_band: String, ratio: float) -> float:
	var t := smoothstep(0.0, 1.0, clampf(ratio, 0.0, 1.0))
	return lerpf(horizon_glow(from_band), horizon_glow(to_band), t)

static func high_atmosphere_mix(band: String) -> float:
	match AltitudeRules.sanitize(band):
		AltitudeRules.LOW: return 0.0
		AltitudeRules.MID: return 0.26
		AltitudeRules.HIGH: return 1.0
		AltitudeRules.ORBITAL: return 0.12
	return 0.0

static func blended_high_atmosphere_mix(from_band: String, to_band: String, ratio: float) -> float:
	var t := smoothstep(0.0, 1.0, clampf(ratio, 0.0, 1.0))
	return lerpf(high_atmosphere_mix(from_band), high_atmosphere_mix(to_band), t)

static func ground_target_visual_scale(band: String) -> float:
	return clampf(AltitudeRules.ground_scale(band), 0.10, 1.0)

static func surface_spawn_x(environment_id: String, variant_id: String, enemy_class: String, roll: float, minimum_x: float, maximum_x: float) -> float:
	var ratio := clampf(roll, 0.0, 1.0)
	var span := maxf(1.0, maximum_x - minimum_x)
	if variant_id == "river":
		if enemy_class == "sea": return lerpf(minimum_x + span * 0.37, minimum_x + span * 0.63, ratio)
		if enemy_class == "ground":
			return lerpf(minimum_x + span * 0.04, minimum_x + span * 0.27, ratio * 2.0) if ratio < 0.5 else lerpf(minimum_x + span * 0.73, minimum_x + span * 0.96, (ratio - 0.5) * 2.0)
	if environment_id == "coast":
		if enemy_class == "ground": return lerpf(minimum_x + span * 0.04, minimum_x + span * 0.46, ratio)
		if enemy_class == "sea": return lerpf(minimum_x + span * 0.61, minimum_x + span * 0.96, ratio)
	if environment_id == "open_water" and enemy_class == "sea":
		return lerpf(minimum_x + span * 0.06, minimum_x + span * 0.94, ratio)
	return lerpf(minimum_x, maximum_x, ratio)

static func should_draw_ground_detail(band: String) -> bool:
	return AltitudeRules.sanitize(band) != AltitudeRules.ORBITAL

static func should_draw_ground_detail_blended(from_band: String, to_band: String, ratio: float) -> bool:
	return blended_ground_detail_scale(from_band, to_band, ratio) >= 0.18
