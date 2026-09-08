class_name RetroSfxPriorityRules
extends RefCounted

const ROUTINE := 1
const TACTICAL := 2
const COCKPIT := 3
const CRITICAL := 4
const COMMAND := 5
const CRITICAL_DUCK_SECONDS := 0.28
const LOWER_PRIORITY_DUCK_GAIN := 0.42
const PROPULSION_DUCK_GAIN := 0.55

static func priority(event_id: String) -> int:
	match event_id:
		"missile_warning", "shield_break":
			return COMMAND
		"radio_alert":
			return COMMAND
		"player_hit", "countermeasure", "seeker_lock":
			return CRITICAL
		"altitude_shift", "altitude_climb", "altitude_dive", "radio_tx":
			return COCKPIT
		"boss_explosion", "sonic_boom", "missile_launch", "strike_impact", "fire_strategic", "reward_stinger":
			return TACTICAL
		"transform", "transform_ready", "afterburner", "strike_release", "ui_purchase", "ui_service", "fire_support":
			return TACTICAL
	return ROUTINE

static func critical(priority_value: int) -> bool:
	return priority_value >= CRITICAL

static func voice_duck(priority_value: int, critical_duck_active: bool) -> float:
	if not critical_duck_active or priority_value >= CRITICAL:
		return 1.0
	return LOWER_PRIORITY_DUCK_GAIN

static func propulsion_duck(critical_duck_active: bool) -> float:
	return PROPULSION_DUCK_GAIN if critical_duck_active else 1.0

# Return the voice index to evict, -1 when no eviction is required, or -2 when
# the incoming voice should be rejected because every active voice outranks it.
# Oldest wins ties because voices are stored in admission order.
static func eviction_index(voices: Array, incoming_priority: int, max_voices: int) -> int:
	if voices.size() < max_voices:
		return -1
	var lowest_priority := 999
	var lowest_index := -1
	for index in range(voices.size()):
		var voice = voices[index]
		var voice_priority := int(voice.get("priority", ROUTINE)) if typeof(voice) == TYPE_DICTIONARY else ROUTINE
		if voice_priority < lowest_priority:
			lowest_priority = voice_priority
			lowest_index = index
	if incoming_priority < lowest_priority:
		return -2
	return lowest_index
