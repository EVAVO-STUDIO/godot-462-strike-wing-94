extends RefCounted

const FAMILIES := {
	"atlas_tanker": [preload("res://assets/runtime/support/battlefield/atlas_tanker/0.png"), preload("res://assets/runtime/support/battlefield/atlas_tanker/1.png"), preload("res://assets/runtime/support/battlefield/atlas_tanker/2.png"), preload("res://assets/runtime/support/battlefield/atlas_tanker/3.png")],
	"rapier_fighter": [preload("res://assets/runtime/support/battlefield/rapier_fighter/0.png"), preload("res://assets/runtime/support/battlefield/rapier_fighter/1.png"), preload("res://assets/runtime/support/battlefield/rapier_fighter/2.png"), preload("res://assets/runtime/support/battlefield/rapier_fighter/3.png")],
	"hammer_bomber": [preload("res://assets/runtime/support/battlefield/hammer_bomber/0.png"), preload("res://assets/runtime/support/battlefield/hammer_bomber/1.png"), preload("res://assets/runtime/support/battlefield/hammer_bomber/2.png"), preload("res://assets/runtime/support/battlefield/hammer_bomber/3.png")],
	"spectre_gunship": [preload("res://assets/runtime/support/battlefield/spectre_gunship/0.png"), preload("res://assets/runtime/support/battlefield/spectre_gunship/1.png"), preload("res://assets/runtime/support/battlefield/spectre_gunship/2.png"), preload("res://assets/runtime/support/battlefield/spectre_gunship/3.png")],
	"precision_missile": [preload("res://assets/runtime/effects/projectiles/support_rocket/0.png"), preload("res://assets/runtime/effects/projectiles/support_rocket/1.png"), preload("res://assets/runtime/effects/projectiles/support_rocket/2.png"), preload("res://assets/runtime/effects/projectiles/support_rocket/3.png")],
}

const STRIKE_CEL := {
	"missile_impact": [preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0000.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0001.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0002.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0003.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0004.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0005.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0006.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0007.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0008.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0009.png"), preload("res://assets/runtime/effects/weapon_explosions/missile/frame_0010.png")],
	"bomb_impact": [preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0000.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0001.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0002.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0003.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0004.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0005.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0006.png"), preload("res://assets/runtime/effects/weapon_explosions/rocket/frame_0007.png")],
	"detonation_core": [preload("res://assets/runtime/effects/explosion/explosion_0.png"), preload("res://assets/runtime/effects/explosion/explosion_1.png"), preload("res://assets/runtime/effects/explosion/explosion_2.png"), preload("res://assets/runtime/effects/explosion/explosion_3.png"), preload("res://assets/runtime/effects/explosion/explosion_4.png"), preload("res://assets/runtime/effects/explosion/explosion_5.png"), preload("res://assets/runtime/effects/explosion/explosion_6.png"), preload("res://assets/runtime/effects/explosion/explosion_7.png")],
	"rail_beam": [preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_beam_0.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_beam_1.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_beam_2.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_beam_3.png")],
	"rail_impact": [preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_impact_0.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_impact_1.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_impact_2.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/rail_impact_3.png")],
	"orbital_beam": [preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_beam_0.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_beam_1.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_beam_2.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_beam_3.png")],
	"orbital_impact": [preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_impact_0.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_impact_1.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_impact_2.png"), preload("res://assets/runtime/support/battlefield/strike_cel_v3/orbital_impact_3.png")],
}

const EFFECTS := {
	"tanker_hose": preload("res://assets/runtime/support/battlefield/effects/tanker_hose.png"),
	"tanker_contact": preload("res://assets/runtime/support/battlefield/effects/tanker_contact.png"),
	"tanker_meter_trough": preload("res://assets/runtime/support/battlefield/effects/tanker_meter_trough.png"),
	"tanker_meter_fill": preload("res://assets/runtime/support/battlefield/effects/tanker_meter_fill.png"),
	"tanker_dock_align": preload("res://assets/runtime/support/battlefield/tanker_docking_instrument/align.png"),
	"tanker_dock_contact": preload("res://assets/runtime/support/battlefield/tanker_docking_instrument/contact.png"),
	"tanker_dock_transfer": preload("res://assets/runtime/support/battlefield/tanker_docking_instrument/transfer.png"),
	"tanker_dock_complete": preload("res://assets/runtime/support/battlefield/tanker_docking_instrument/complete.png"),
	"tanker_dock_fill": preload("res://assets/runtime/support/battlefield/tanker_docking_instrument/transfer_fill.png"),
	"strike_bomb": preload("res://assets/runtime/support/battlefield/effects/strike_bomb.png"),
	"tracer": preload("res://assets/runtime/support/battlefield/effects/tracer.png"),
	"impact_0": preload("res://assets/runtime/support/battlefield/effects/impact_0.png"),
	"impact_1": preload("res://assets/runtime/support/battlefield/effects/impact_1.png"),
	"impact_2": preload("res://assets/runtime/support/battlefield/effects/impact_2.png"),
	"rail_charge_0": preload("res://assets/runtime/support/battlefield/effects/rail_charge_0.png"),
	"rail_charge_1": preload("res://assets/runtime/support/battlefield/effects/rail_charge_1.png"),
	"rail_charge_2": preload("res://assets/runtime/support/battlefield/effects/rail_charge_2.png"),
	"rail_beam": preload("res://assets/runtime/support/battlefield/effects/rail_beam.png"),
	"orbital_beam": preload("res://assets/runtime/support/battlefield/effects/orbital_beam.png"),
	"orbital_impact": preload("res://assets/runtime/support/battlefield/effects/orbital_impact.png"),
}

static func frame_for_clock(family: String, clock: float, fps: float = 8.0) -> Texture2D:
	var frames: Array = FAMILIES.get(family, [])
	if frames.is_empty():
		return null
	return frames[int(floor(clock * fps)) % frames.size()]

static func effect(name: String) -> Texture2D:
	return EFFECTS.get(name)

static func staged_effect(prefix: String, ratio: float, frame_count: int = 3) -> Texture2D:
	var index := clampi(int(floor(clampf(ratio, 0.0, 0.9999) * frame_count)), 0, frame_count - 1)
	return effect("%s_%d" % [prefix, index])

static func strike_cel(prefix: String, ratio: float) -> Texture2D:
	var frames: Array = STRIKE_CEL.get(prefix, [])
	if frames.is_empty(): return null
	var index := clampi(int(floor(clampf(ratio, 0.0, 0.9999) * frames.size())), 0, frames.size()-1)
	return frames[index]
