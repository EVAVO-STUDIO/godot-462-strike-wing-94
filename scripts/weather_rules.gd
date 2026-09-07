class_name WeatherRules
extends RefCounted

const ALTITUDE_WEIGHTS := {"low":1.0, "mid":0.6, "high":0.0, "orbital":0.0}
const SNOW_TRAVEL := {"distant":6.0, "middle":20.0, "near":52.0}
const AUDIO_BASE_GAIN := {"clear":0.0, "drizzle":0.040, "rain":0.070, "storm":0.100, "snow":0.062}

static func altitude_weight(state: Dictionary, weights: Dictionary = ALTITUDE_WEIGHTS) -> float:
	if bool(state.get("transition", false)):
		return lerpf(float(weights.get(str(state.get("from", "mid")), 0.0)), float(weights.get(str(state.get("to", "mid")), 0.0)), clampf(float(state.get("ratio", 1.0)), 0.0, 1.0))
	return float(weights.get(str(state.get("current", "mid")), 0.0))

static func rain_drop(p: Dictionary, elapsed: float, travel: float, world_speed_multiplier: float = 1.0) -> Dictionary:
	# Registered Atmosphere Studio v4 drop-head projection. Time supplies wind
	# and rainfall; integrated camera travel supplies depth-dependent closure.
	var phase := fposmod(elapsed / 8.0, 1.0)
	var perspective := 0.38 + (1.0 - float(p.depth)) * 1.42
	var margin := maxf(8.0, float(p.lengthPixels) * 1.4)
	var period := 304.0 + margin * 2.0
	var age := fposmod(phase * float(p.fallCycles) + float(p.phaseOffset) + travel * 42.0 * (1.0 - float(p.depth)) / period, 1.0)
	var gust := sin(TAU * (phase * float(p.gustCycles) + float(p.gustPhase))) + 0.38 * sin(TAU * (phase * (float(p.gustCycles) + 1.0) + float(p.secondaryGustPhase)))
	var drift := 0.14 * age * (0.035 + perspective * 0.035)
	var x := fposmod(float(p.baseX) + drift + gust * float(p.lateralVariation), 1.0) * 640.0
	var y := -margin + age * period
	var length := float(p.lengthPixels) * (0.92 + 0.08 * sin(TAU * (phase * 2.0 + float(p.gustPhase))))
	var speed_ratio := clampf((world_speed_multiplier-0.45)/3.95,0.0,1.0)
	var closure_scale := lerpf(0.78,1.38,speed_ratio)
	var direction := Vector2((0.14*(0.34+perspective*0.16)+gust*0.035+speed_ratio*0.22)*length,length*1.028)
	# Three fixed cel lengths create readable depth without approaching the long,
	# bright language reserved for cannon and directed-energy fire.
	var cap: float = {"background":3.0, "midground":5.5, "foreground":8.0}[p.depthBand]
	var drawn_length := minf(direction.length()*closure_scale,cap*closure_scale)
	direction = direction.normalized()
	var fade := minf(clampf((y + margin) / margin, 0, 1), clampf((304.0 + margin - (y - direction.y * drawn_length)) / margin, 0, 1))
	return {"head":Vector2(x,y), "tail":Vector2(x,y) - direction * drawn_length, "opacity":float(p.opacity) * fade * 0.78}

static func snow_position(p: Dictionary, travel: float, elapsed: float = 0.0) -> Vector2:
	var layer_speed: float = float(SNOW_TRAVEL[p.layer])
	var phase := float(abs(str(p.id).hash()) % 997) / 997.0
	var gust_strength: float = {"distant":2.0, "middle":5.0, "near":10.0}[p.layer]
	var gust := sin(elapsed * 1.7 + phase * TAU) + 0.38 * sin(elapsed * 3.1 + phase * TAU * 2.0)
	return Vector2(
		fposmod(float(p.x) + gust * gust_strength + 8.0, 656.0) - 8.0,
		fposmod(float(p.y) + travel * layer_speed + elapsed * layer_speed * 0.34 + 8.0, 320.0) - 8.0
	)

static func storm_flash(elapsed: float) -> float:
	# Two-frame stepped lightning cells, followed by a dimmer reflected exposure.
	# The long irregular cycle avoids a metronomic arcade blink.
	var phase := fposmod(elapsed + 1.73, 7.9)
	if phase < 0.055: return 0.34
	if phase >= 0.12 and phase < 0.175: return 0.18
	return 0.0

static func storm_flash_frame(elapsed: float) -> int:
	var phase := fposmod(elapsed + 1.73, 7.9)
	if phase < 0.025: return 0
	if phase < 0.055: return 1
	if phase >= 0.12 and phase < 0.175: return 2
	return -1

static func audio_mix(profile: String, altitude_weight_value: float, world_speed_multiplier: float) -> Dictionary:
	var weather_gain := float(AUDIO_BASE_GAIN.get(profile, 0.0)) * clampf(altitude_weight_value, 0.0, 1.0)
	var speed_lift := lerpf(0.88, 1.08, clampf((world_speed_multiplier - 0.45) / 3.75, 0.0, 1.0))
	weather_gain *= speed_lift
	return {
		"rain": weather_gain if profile in ["drizzle","rain"] else 0.0,
		"storm": weather_gain if profile == "storm" else 0.0,
		"snow": weather_gain if profile == "snow" else 0.0,
		"pitch": lerpf(0.96, 1.04, clampf((world_speed_multiplier - 0.45) / 3.75, 0.0, 1.0))
	}
