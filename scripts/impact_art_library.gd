class_name ImpactArtLibrary
extends RefCounted

const FRAMES := {
	"muzzle": [preload("res://assets/runtime/effects/impacts/muzzle/0.png"), preload("res://assets/runtime/effects/impacts/muzzle/1.png"), preload("res://assets/runtime/effects/impacts/muzzle/2.png"), preload("res://assets/runtime/effects/impacts/muzzle/3.png")],
	"rotary_muzzle": [preload("res://assets/runtime/effects/impacts/rotary_muzzle/0.png"), preload("res://assets/runtime/effects/impacts/rotary_muzzle/1.png"), preload("res://assets/runtime/effects/impacts/rotary_muzzle/2.png"), preload("res://assets/runtime/effects/impacts/rotary_muzzle/3.png")],
	"armor_hit": [preload("res://assets/runtime/effects/impacts/armor_hit/0.png"), preload("res://assets/runtime/effects/impacts/armor_hit/1.png"), preload("res://assets/runtime/effects/impacts/armor_hit/2.png"), preload("res://assets/runtime/effects/impacts/armor_hit/3.png")],
	"shield_hit": [preload("res://assets/runtime/effects/impacts/shield_hit/0.png"), preload("res://assets/runtime/effects/impacts/shield_hit/1.png"), preload("res://assets/runtime/effects/impacts/shield_hit/2.png"), preload("res://assets/runtime/effects/impacts/shield_hit/3.png")],
	"bomb_impact": [preload("res://assets/runtime/effects/impacts/bomb_impact/0.png"), preload("res://assets/runtime/effects/impacts/bomb_impact/1.png"), preload("res://assets/runtime/effects/impacts/bomb_impact/2.png"), preload("res://assets/runtime/effects/impacts/bomb_impact/3.png")],
	"emp_disruption": [preload("res://assets/runtime/effects/impacts/emp_disruption/0.png"), preload("res://assets/runtime/effects/impacts/emp_disruption/1.png"), preload("res://assets/runtime/effects/impacts/emp_disruption/2.png"), preload("res://assets/runtime/effects/impacts/emp_disruption/3.png")],
	"water_impact": [preload("res://assets/runtime/effects/impacts/water_impact/0.png"), preload("res://assets/runtime/effects/impacts/water_impact/1.png"), preload("res://assets/runtime/effects/impacts/water_impact/2.png"), preload("res://assets/runtime/effects/impacts/water_impact/3.png")],
	"dust_impact": [preload("res://assets/runtime/effects/impacts/dust_impact/0.png"), preload("res://assets/runtime/effects/impacts/dust_impact/1.png"), preload("res://assets/runtime/effects/impacts/dust_impact/2.png"), preload("res://assets/runtime/effects/impacts/dust_impact/3.png")]
}

static func frame_for_ratio(family: String, ratio: float) -> Texture2D:
	var frames: Array = FRAMES.get(family, FRAMES["armor_hit"])
	var index := clampi(int(floor(clampf(ratio, 0.0, 0.999) * frames.size())), 0, frames.size() - 1)
	return frames[index]

static func frame_for_clock(family: String, fps: float = 12.0) -> Texture2D:
	var frames: Array = FRAMES.get(family, FRAMES["armor_hit"])
	var index := int(floor(Time.get_ticks_msec() / 1000.0 * fps)) % frames.size()
	return frames[index]
