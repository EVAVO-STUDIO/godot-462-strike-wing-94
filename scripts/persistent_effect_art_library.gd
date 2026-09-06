class_name PersistentEffectArtLibrary
extends RefCounted

const FRAMES := {
	"damage_smoke": [preload("res://assets/runtime/effects/persistent/damage_smoke/0.png"), preload("res://assets/runtime/effects/persistent/damage_smoke/1.png"), preload("res://assets/runtime/effects/persistent/damage_smoke/2.png"), preload("res://assets/runtime/effects/persistent/damage_smoke/3.png")],
	"damage_fire": [preload("res://assets/runtime/effects/persistent/damage_fire/0.png"), preload("res://assets/runtime/effects/persistent/damage_fire/1.png"), preload("res://assets/runtime/effects/persistent/damage_fire/2.png"), preload("res://assets/runtime/effects/persistent/damage_fire/3.png")],
	"damage_sparks": [preload("res://assets/runtime/effects/persistent/damage_sparks/0.png"), preload("res://assets/runtime/effects/persistent/damage_sparks/1.png"), preload("res://assets/runtime/effects/persistent/damage_sparks/2.png"), preload("res://assets/runtime/effects/persistent/damage_sparks/3.png")],
	"afterburner": [preload("res://assets/runtime/effects/persistent/afterburner/0.png"), preload("res://assets/runtime/effects/persistent/afterburner/1.png"), preload("res://assets/runtime/effects/persistent/afterburner/2.png"), preload("res://assets/runtime/effects/persistent/afterburner/3.png")],
	"contrail": [preload("res://assets/runtime/effects/persistent/contrail/0.png"), preload("res://assets/runtime/effects/persistent/contrail/1.png"), preload("res://assets/runtime/effects/persistent/contrail/2.png"), preload("res://assets/runtime/effects/persistent/contrail/3.png")],
	"debris": [preload("res://assets/runtime/effects/persistent/debris/0.png"), preload("res://assets/runtime/effects/persistent/debris/1.png"), preload("res://assets/runtime/effects/persistent/debris/2.png"), preload("res://assets/runtime/effects/persistent/debris/3.png")],
	"sonic_boom": [preload("res://assets/runtime/effects/persistent/sonic_boom/0.png"), preload("res://assets/runtime/effects/persistent/sonic_boom/1.png"), preload("res://assets/runtime/effects/persistent/sonic_boom/2.png"), preload("res://assets/runtime/effects/persistent/sonic_boom/3.png")],
	"hypersonic_ignition": [preload("res://assets/runtime/effects/persistent/hypersonic_ignition/0.png"), preload("res://assets/runtime/effects/persistent/hypersonic_ignition/1.png"), preload("res://assets/runtime/effects/persistent/hypersonic_ignition/2.png"), preload("res://assets/runtime/effects/persistent/hypersonic_ignition/3.png")]
	,"hypersonic_blue_plume": [preload("res://assets/runtime/effects/persistent/hypersonic_blue_plume/0.png"), preload("res://assets/runtime/effects/persistent/hypersonic_blue_plume/1.png"), preload("res://assets/runtime/effects/persistent/hypersonic_blue_plume/2.png"), preload("res://assets/runtime/effects/persistent/hypersonic_blue_plume/3.png")]
	,"hypersonic_engine_burst": [preload("res://assets/runtime/effects/persistent/hypersonic_engine_burst/0.png"), preload("res://assets/runtime/effects/persistent/hypersonic_engine_burst/1.png"), preload("res://assets/runtime/effects/persistent/hypersonic_engine_burst/2.png"), preload("res://assets/runtime/effects/persistent/hypersonic_engine_burst/3.png"), preload("res://assets/runtime/effects/persistent/hypersonic_engine_burst/4.png"), preload("res://assets/runtime/effects/persistent/hypersonic_engine_burst/5.png")]
}

static func frame_for_clock(family: String, fps: float = 10.0, phase_offset: int = 0) -> Texture2D:
	var frames: Array = FRAMES[family]
	var index := (int(floor(Time.get_ticks_msec() / 1000.0 * fps)) + phase_offset) % frames.size()
	return frames[index]

static func frame_for_ratio(family: String, ratio: float) -> Texture2D:
	var frames: Array = FRAMES[family]
	var index := clampi(int(floor(clampf(ratio, 0.0, 0.999) * frames.size())), 0, frames.size() - 1)
	return frames[index]
