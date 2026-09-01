extends CanvasLayer
const SceneContractCache = preload("res://scripts/scene_contract_cache.gd")

const CombatArtSurface = preload("res://scripts/combat_art_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")
const ProjectileCueDirector = preload("res://scripts/projectile_cue_director.gd")
const VX94_GAMEPLAY_FORMS := [
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_fighter_v1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_transform_01.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_transform_02.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_transform_03.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_bomber_v1.png"),
]
const VX94_FIGHTER_BANK := [
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_hard_left.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_left.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_neutral.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_right.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_hard_right.png"),
]
const VX94_BOMBER_BANK := [
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_hard_left.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_left.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_neutral.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_right.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_hard_right.png"),
]
const VX94_EXHAUST := [
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_0.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_2.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_3.png"),
]
const VX94_DAMAGE := {
	"fighter": [
		preload("res://assets/runtime/craft/vx94/gameplay/damage/fighter_light.png"),
		preload("res://assets/runtime/craft/vx94/gameplay/damage/fighter_damaged.png"),
		preload("res://assets/runtime/craft/vx94/gameplay/damage/fighter_critical.png"),
	],
	"bomber": [
		preload("res://assets/runtime/craft/vx94/gameplay/damage/bomber_light.png"),
		preload("res://assets/runtime/craft/vx94/gameplay/damage/bomber_damaged.png"),
		preload("res://assets/runtime/craft/vx94/gameplay/damage/bomber_critical.png"),
	],
}
const VX94_FIGHTER_BREAKUP := [
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/fighter_breakup_0.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/fighter_breakup_1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/fighter_breakup_2.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/fighter_breakup_3.png"),
]
const VX94_BOMBER_BREAKUP := [
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/bomber_breakup_0.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/bomber_breakup_1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/bomber_breakup_2.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/destruction/bomber_breakup_3.png"),
]
const VX94_ESCAPE_CAPSULE := preload("res://assets/runtime/craft/vx94/gameplay/destruction/escape_capsule.png")
const VX94_LAYERED := {
	"fuselage": preload("res://assets/runtime/craft/vx94/layered/fuselage.png"),
	"wing_left": preload("res://assets/runtime/craft/vx94/layered/wing_left.png"),
	"wing_right": preload("res://assets/runtime/craft/vx94/layered/wing_right.png"),
	"actuator_left": preload("res://assets/runtime/craft/vx94/layered/actuator_left.png"),
	"actuator_right": preload("res://assets/runtime/craft/vx94/layered/actuator_right.png"),
	"tailplane_left": preload("res://assets/runtime/craft/vx94/layered/tailplane_left.png"),
	"tailplane_right": preload("res://assets/runtime/craft/vx94/layered/tailplane_right.png"),
	"hardpoint_left": preload("res://assets/runtime/craft/vx94/layered/hardpoint_left.png"),
	"hardpoint_right": preload("res://assets/runtime/craft/vx94/layered/hardpoint_right.png"),
	"bay_closed": preload("res://assets/runtime/craft/vx94/layered/bay_closed.png"),
	"bay_open": preload("res://assets/runtime/craft/vx94/layered/bay_open.png"),
}
const PICKUP_ANIMATION_FRAMES := {
	"shield": [preload("res://assets/runtime/effects/pickups/shield_0.png"), preload("res://assets/runtime/effects/pickups/shield_1.png"), preload("res://assets/runtime/effects/pickups/shield_2.png"), preload("res://assets/runtime/effects/pickups/shield_3.png")],
	"repair": [preload("res://assets/runtime/effects/pickups/repair_0.png"), preload("res://assets/runtime/effects/pickups/repair_1.png"), preload("res://assets/runtime/effects/pickups/repair_2.png"), preload("res://assets/runtime/effects/pickups/repair_3.png")],
	"bomb": [preload("res://assets/runtime/effects/pickups/bomb_0.png"), preload("res://assets/runtime/effects/pickups/bomb_1.png"), preload("res://assets/runtime/effects/pickups/bomb_2.png"), preload("res://assets/runtime/effects/pickups/bomb_3.png")],
	"weapon": [preload("res://assets/runtime/effects/pickups/weapon_0.png"), preload("res://assets/runtime/effects/pickups/weapon_1.png"), preload("res://assets/runtime/effects/pickups/weapon_2.png"), preload("res://assets/runtime/effects/pickups/weapon_3.png")],
}
const DESTRUCTION_CAPTURE_FRAMES := {
	"explosion": [
		preload("res://assets/runtime/effects/explosion/explosion_0.png"), preload("res://assets/runtime/effects/explosion/explosion_1.png"), preload("res://assets/runtime/effects/explosion/explosion_2.png"), preload("res://assets/runtime/effects/explosion/explosion_3.png"),
		preload("res://assets/runtime/effects/explosion/explosion_4.png"), preload("res://assets/runtime/effects/explosion/explosion_5.png"), preload("res://assets/runtime/effects/explosion/explosion_6.png"), preload("res://assets/runtime/effects/explosion/explosion_7.png"),
	],
	"flak": [preload("res://assets/runtime/effects/ground_breakup/flak_breakup_0.png"), preload("res://assets/runtime/effects/ground_breakup/flak_breakup_1.png"), preload("res://assets/runtime/effects/ground_breakup/flak_breakup_2.png")],
	"fort": [preload("res://assets/runtime/effects/ground_breakup/fort_breakup_0.png"), preload("res://assets/runtime/effects/ground_breakup/fort_breakup_1.png"), preload("res://assets/runtime/effects/ground_breakup/fort_breakup_2.png")],
}
const PLAYER_LOSS_SEQUENCE_SECONDS := 2.40
const VX94_GAMEPLAY_ANCHOR := Vector2(24, 29)
const MERCENARY_AIR_SPRITES := {
	"scout_falcon": preload("res://assets/runtime/enemies/mercenary_air/scout_falcon_idle.png"),
	"gunship_mk1": preload("res://assets/runtime/enemies/mercenary_air/gunship_mk1_idle.png"),
	"attack_chopper": preload("res://assets/runtime/enemies/mercenary_air/attack_chopper_idle.png"),
	"ace_interceptor": preload("res://assets/runtime/enemies/mercenary_air/ace_interceptor_idle.png"),
	"heavy_bomber": preload("res://assets/runtime/enemies/mercenary_air/heavy_bomber_idle.png"),
}
const UNIT_ANIMATION_FRAMES := {
	"security_patrol_mech": {"fps": 7.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/security_patrol_mech/walk_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/security_patrol_mech/walk_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/security_patrol_mech/walk_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/security_patrol_mech/walk_3.png"),
	]},
	"autonomous_salvage_mech": {"fps": 9.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/autonomous_salvage_mech/walk_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/autonomous_salvage_mech/walk_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/autonomous_salvage_mech/walk_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/autonomous_salvage_mech/walk_3.png"),
	]},
	"mercenary_rifle_team": {"fps": 8.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/mercenary_rifle_team/advance_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/mercenary_rifle_team/advance_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/mercenary_rifle_team/advance_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/mercenary_rifle_team/advance_3.png"),
	]},
	"mercenary_heavy_team": {"fps": 6.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/mercenary_heavy_team/advance_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/mercenary_heavy_team/advance_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/mercenary_heavy_team/advance_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/mercenary_heavy_team/advance_3.png"),
	]},
	"ace_interceptor": {"fps": 10.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/ace_interceptor/thrust_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/ace_interceptor/thrust_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/ace_interceptor/thrust_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/ace_interceptor/thrust_3.png"),
	]},
	"drone_hunter": {"fps": 12.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/drone_hunter/thrust_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/drone_hunter/thrust_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/drone_hunter/thrust_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/drone_hunter/thrust_3.png"),
	]},
	"phase_interceptor": {"fps": 14.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/phase_interceptor/thrust_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/phase_interceptor/thrust_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/phase_interceptor/thrust_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/phase_interceptor/thrust_3.png"),
	]},
}
const HOSTILE_BANK_FRAMES := {
	"scout_falcon": [preload("res://assets/runtime/enemies/bank/scout_falcon/left.png"), preload("res://assets/runtime/enemies/mercenary_air/scout_falcon_idle.png"), preload("res://assets/runtime/enemies/bank/scout_falcon/right.png")],
	"gunship_mk1": [preload("res://assets/runtime/enemies/bank/gunship_mk1/left.png"), preload("res://assets/runtime/enemies/mercenary_air/gunship_mk1_idle.png"), preload("res://assets/runtime/enemies/bank/gunship_mk1/right.png")],
	"attack_chopper": [preload("res://assets/runtime/enemies/bank/attack_chopper/left.png"), preload("res://assets/runtime/enemies/mercenary_air/attack_chopper_idle.png"), preload("res://assets/runtime/enemies/bank/attack_chopper/right.png")],
	"ace_interceptor": [preload("res://assets/runtime/enemies/bank/ace_interceptor/left.png"), preload("res://assets/runtime/enemies/mercenary_air/ace_interceptor_idle.png"), preload("res://assets/runtime/enemies/bank/ace_interceptor/right.png")],
	"heavy_bomber": [preload("res://assets/runtime/enemies/bank/heavy_bomber/left.png"), preload("res://assets/runtime/enemies/mercenary_air/heavy_bomber_idle.png"), preload("res://assets/runtime/enemies/bank/heavy_bomber/right.png")],
	"drone_scout": [preload("res://assets/runtime/enemies/bank/drone_scout/left.png"), preload("res://assets/runtime/enemies/machine_air/drone_scout_idle.png"), preload("res://assets/runtime/enemies/bank/drone_scout/right.png")],
	"drone_hunter": [preload("res://assets/runtime/enemies/bank/drone_hunter/left.png"), preload("res://assets/runtime/enemies/machine_air/drone_hunter_idle.png"), preload("res://assets/runtime/enemies/bank/drone_hunter/right.png")],
	"drone_bomber": [preload("res://assets/runtime/enemies/bank/drone_bomber/left.png"), preload("res://assets/runtime/enemies/machine_air/drone_bomber_idle.png"), preload("res://assets/runtime/enemies/bank/drone_bomber/right.png")],
	"drone_missile_node": [preload("res://assets/runtime/enemies/bank/drone_missile_node/left.png"), preload("res://assets/runtime/enemies/machine_air/drone_missile_node_idle.png"), preload("res://assets/runtime/enemies/bank/drone_missile_node/right.png")],
	"exo_drone": [preload("res://assets/runtime/enemies/bank/exo_drone/left.png"), preload("res://assets/runtime/enemies/orbital_air/exo_drone_idle.png"), preload("res://assets/runtime/enemies/bank/exo_drone/right.png")],
	"orbital_sentry": [preload("res://assets/runtime/enemies/bank/orbital_sentry/left.png"), preload("res://assets/runtime/enemies/orbital_air/orbital_sentry_idle.png"), preload("res://assets/runtime/enemies/bank/orbital_sentry/right.png")],
	"phase_interceptor": [preload("res://assets/runtime/enemies/bank/phase_interceptor/left.png"), preload("res://assets/runtime/enemies/orbital_air/phase_interceptor_idle.png"), preload("res://assets/runtime/enemies/bank/phase_interceptor/right.png")],
	"beam_sentry": [preload("res://assets/runtime/enemies/bank/beam_sentry/left.png"), preload("res://assets/runtime/enemies/orbital_air/beam_sentry_idle.png"), preload("res://assets/runtime/enemies/bank/beam_sentry/right.png")],
	"orbital_lancer": [preload("res://assets/runtime/enemies/bank/orbital_lancer/left.png"), preload("res://assets/runtime/enemies/orbital_air/orbital_lancer_idle.png"), preload("res://assets/runtime/enemies/bank/orbital_lancer/right.png")],
}
const AIR_SPECIALIST_ART := {
	"gunship_mk1": {
		"mount": preload("res://assets/runtime/enemies/human_air_layered/gunship_mount.png"),
		"turret": preload("res://assets/runtime/enemies/human_air_layered/gunship_turret.png"),
		"barrel": preload("res://assets/runtime/enemies/human_air_layered/gunship_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/human_air_layered/gunship_barrel_recoil.png"),
		"sensor": preload("res://assets/runtime/enemies/human_air_layered/gunship_sensor.png"),
		"anchor": Vector2(0, 5),
	},
	"attack_chopper": {
		"rotor": [
			preload("res://assets/runtime/enemies/human_air_layered/chopper_rotor_0.png"),
			preload("res://assets/runtime/enemies/human_air_layered/chopper_rotor_1.png"),
			preload("res://assets/runtime/enemies/human_air_layered/chopper_rotor_2.png"),
			preload("res://assets/runtime/enemies/human_air_layered/chopper_rotor_3.png"),
		],
		"hub": preload("res://assets/runtime/enemies/human_air_layered/chopper_rotor_hub.png"),
		"turret": preload("res://assets/runtime/enemies/human_air_layered/chopper_cannon.png"),
		"barrel": preload("res://assets/runtime/enemies/human_air_layered/chopper_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/human_air_layered/chopper_barrel_recoil.png"),
		"anchor": Vector2(0, 7),
	},
	"heavy_bomber": {
		"bay": [
			preload("res://assets/runtime/enemies/human_air_layered/bomber_bay_closed.png"),
			preload("res://assets/runtime/enemies/human_air_layered/bomber_bay_opening.png"),
			preload("res://assets/runtime/enemies/human_air_layered/bomber_bay_open.png"),
			preload("res://assets/runtime/enemies/human_air_layered/bomber_bay_fire.png"),
		],
		"anchor": Vector2(0, 4),
	},
}
const MACHINE_AIR_SPECIALIST_ART := {
	"core": [
		preload("res://assets/runtime/enemies/machine_air_layered/core_dim.png"),
		preload("res://assets/runtime/enemies/machine_air_layered/core_active.png"),
		preload("res://assets/runtime/enemies/machine_air_layered/core_overload.png"),
	],
	"collar": preload("res://assets/runtime/enemies/machine_air_layered/core_collar.png"),
	"damaged_core": preload("res://assets/runtime/enemies/machine_air_layered/core_damaged.png"),
	"propulsion": [
		preload("res://assets/runtime/enemies/machine_air_layered/thruster_dim.png"),
		preload("res://assets/runtime/enemies/machine_air_layered/thruster_active.png"),
		preload("res://assets/runtime/enemies/machine_air_layered/thruster_overload.png"),
	],
	"drone_hunter": {
		"mount": preload("res://assets/runtime/enemies/machine_air_layered/hunter_mount.png"),
		"barrel": preload("res://assets/runtime/enemies/machine_air_layered/hunter_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/machine_air_layered/hunter_barrel_recoil.png"),
		"anchor": Vector2(0, 5),
	},
	"drone_bomber": {
		"frames": [
			preload("res://assets/runtime/enemies/machine_air_layered/bomber_bay_closed.png"),
			preload("res://assets/runtime/enemies/machine_air_layered/bomber_bay_opening.png"),
			preload("res://assets/runtime/enemies/machine_air_layered/bomber_bay_open.png"),
			preload("res://assets/runtime/enemies/machine_air_layered/bomber_bay_fire.png"),
		],
		"anchor": Vector2(0, 4),
	},
	"drone_missile_node": {
		"frames": [
			preload("res://assets/runtime/enemies/machine_air_layered/missile_hatch_closed.png"),
			preload("res://assets/runtime/enemies/machine_air_layered/missile_hatch_opening.png"),
			preload("res://assets/runtime/enemies/machine_air_layered/missile_hatch_open.png"),
			preload("res://assets/runtime/enemies/machine_air_layered/missile_hatch_fire.png"),
		],
		"anchor": Vector2(0, 3),
	},
}
const ORBITAL_AIR_SPECIALIST_ART := {
	"propulsion": [
		preload("res://assets/runtime/enemies/orbital_air_layered/orbital_thruster_dim.png"),
		preload("res://assets/runtime/enemies/orbital_air_layered/orbital_thruster_active.png"),
		preload("res://assets/runtime/enemies/orbital_air_layered/orbital_thruster_overload.png"),
	],
	"fragment_large": preload("res://assets/runtime/enemies/orbital_air_layered/orbital_fragment_large.png"),
	"fragment_small": preload("res://assets/runtime/enemies/orbital_air_layered/orbital_fragment_small.png"),
	"exo_drone": {
		"radiator_cool": preload("res://assets/runtime/enemies/orbital_air_layered/radiator_cool.png"),
		"radiator_hot": preload("res://assets/runtime/enemies/orbital_air_layered/radiator_hot.png"),
		"anchor": Vector2(0, 1),
	},
	"orbital_sentry": {
		"collar": preload("res://assets/runtime/enemies/orbital_air_layered/sentry_collar.png"),
		"turret": preload("res://assets/runtime/enemies/orbital_air_layered/sentry_turret.png"),
		"barrel": preload("res://assets/runtime/enemies/orbital_air_layered/sentry_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/orbital_air_layered/sentry_barrel_recoil.png"),
		"anchor": Vector2(0, 3),
	},
	"phase_interceptor": {
		"frames": [
			preload("res://assets/runtime/enemies/orbital_air_layered/phase_nodes_dormant.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/phase_nodes_active.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/phase_nodes_overload.png"),
		],
		"damaged": preload("res://assets/runtime/enemies/orbital_air_layered/phase_nodes_damaged.png"),
		"anchor": Vector2(0, 0),
	},
	"beam_sentry": {
		"frames": [
			preload("res://assets/runtime/enemies/orbital_air_layered/beam_aperture_closed.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/beam_aperture_opening.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/beam_aperture_open.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/beam_aperture_fire.png"),
		],
		"anchor": Vector2(0, 2),
	},
	"orbital_lancer": {
		"frames": [
			preload("res://assets/runtime/enemies/orbital_air_layered/rail_safe.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/rail_charge_1.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/rail_charge_2.png"),
			preload("res://assets/runtime/enemies/orbital_air_layered/rail_fire.png"),
		],
		"capacitor": preload("res://assets/runtime/enemies/orbital_air_layered/rail_capacitor_bank.png"),
		"anchor": Vector2(0, 5),
	},
}
const GROUND_FORCE_SPECIALIST_ART := {
	"security_patrol_mech": {
		"weapon": preload("res://assets/runtime/enemies/ground_mech_layered/security_cannon.png"),
		"weapon_recoil": preload("res://assets/runtime/enemies/ground_mech_layered/security_cannon_recoil.png"),
		"shield": preload("res://assets/runtime/enemies/ground_mech_layered/security_shield.png"),
		"collar": preload("res://assets/runtime/enemies/ground_mech_layered/security_collar.png"),
		"primary_anchor": Vector2(-10, -5),
		"secondary_anchor": Vector2(10, -3),
	},
	"autonomous_salvage_mech": {
		"weapon": preload("res://assets/runtime/enemies/ground_mech_layered/salvage_cutter_arm.png"),
		"grapple_open": preload("res://assets/runtime/enemies/ground_mech_layered/salvage_grapple_open.png"),
		"grapple_closed": preload("res://assets/runtime/enemies/ground_mech_layered/salvage_grapple_closed.png"),
		"disc": [
			preload("res://assets/runtime/enemies/ground_mech_layered/salvage_disc_0.png"),
			preload("res://assets/runtime/enemies/ground_mech_layered/salvage_disc_1.png"),
			preload("res://assets/runtime/enemies/ground_mech_layered/salvage_disc_2.png"),
		],
		"collar": preload("res://assets/runtime/enemies/ground_mech_layered/salvage_collar.png"),
		"primary_anchor": Vector2(-13, -4),
		"secondary_anchor": Vector2(13, -4),
	},
}
const INFANTRY_LAYERED_ART := {
	"mercenary_rifle_team": {
		"advance": [
			preload("res://assets/runtime/enemies/infantry_layered/rifle_advance_0.png"),
			preload("res://assets/runtime/enemies/infantry_layered/rifle_advance_1.png"),
			preload("res://assets/runtime/enemies/infantry_layered/rifle_advance_2.png"),
		],
		"aim": preload("res://assets/runtime/enemies/infantry_layered/rifle_aim.png"),
		"fire": preload("res://assets/runtime/enemies/infantry_layered/rifle_fire.png"),
		"flinch": preload("res://assets/runtime/enemies/infantry_layered/rifle_flinch.png"),
		"dust": [
			preload("res://assets/runtime/enemies/infantry_layered/hit_dust_0.png"),
			preload("res://assets/runtime/enemies/infantry_layered/hit_dust_1.png"),
		],
	},
	"mercenary_heavy_team": {
		"gunner": preload("res://assets/runtime/enemies/infantry_layered/rifle_kneel.png"),
		"gunner_fire": preload("res://assets/runtime/enemies/infantry_layered/rifle_kneel_fire.png"),
		"loader": preload("res://assets/runtime/enemies/infantry_layered/heavy_loader.png"),
		"spotter": preload("res://assets/runtime/enemies/infantry_layered/heavy_spotter.png"),
		"tripod": preload("res://assets/runtime/enemies/infantry_layered/heavy_tripod.png"),
		"tripod_recoil": preload("res://assets/runtime/enemies/infantry_layered/heavy_tripod_recoil.png"),
		"crate": preload("res://assets/runtime/enemies/infantry_layered/heavy_ammo_crate.png"),
		"belt": preload("res://assets/runtime/enemies/infantry_layered/heavy_ammo_belt.png"),
		"flinch": preload("res://assets/runtime/enemies/infantry_layered/rifle_flinch.png"),
		"dust": [
			preload("res://assets/runtime/enemies/infantry_layered/hit_dust_0.png"),
			preload("res://assets/runtime/enemies/infantry_layered/hit_dust_1.png"),
		],
	},
}
const MERCENARY_GROUND_SPRITES := {
	"light_tank": preload("res://assets/runtime/enemies/mercenary_ground/light_tank_idle.png"),
	"sam_truck": preload("res://assets/runtime/enemies/mercenary_ground/sam_truck_idle.png"),
	"fortified_turret": preload("res://assets/runtime/enemies/mercenary_ground/fortified_turret_idle.png"),
	"coastal_flak": preload("res://assets/runtime/enemies/mercenary_ground/coastal_flak_idle.png"),
	"armoured_aa_carrier": preload("res://assets/runtime/enemies/mercenary_ground/armoured_aa_carrier_idle.png"),
}
const LAYERED_GROUND_SPRITES := {
	"light_tank": {
		"base": preload("res://assets/runtime/enemies/mobile_ground_layered/light_tank_base.png"),
		"locomotion": [preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/light_tank/0.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/light_tank/1.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/light_tank/2.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/light_tank/3.png")],
		"weapon": preload("res://assets/runtime/enemies/mobile_ground_layered/light_tank_turret.png"),
		"barrel": preload("res://assets/runtime/enemies/mobile_ground_layered/light_tank_barrel.png"),
	},
	"sam_truck": {
		"base": preload("res://assets/runtime/enemies/mobile_ground_layered/sam_truck_base.png"),
		"locomotion": [preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/sam_truck/0.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/sam_truck/1.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/sam_truck/2.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/sam_truck/3.png")],
		"weapon": preload("res://assets/runtime/enemies/mobile_ground_layered/sam_launcher_deployed.png"),
		"weapon_animation": [
			preload("res://assets/runtime/enemies/mobile_ground_layered/sam_launcher_stowed.png"),
			preload("res://assets/runtime/enemies/mobile_ground_layered/sam_launcher_rising.png"),
			preload("res://assets/runtime/enemies/mobile_ground_layered/sam_launcher_deployed.png"),
			preload("res://assets/runtime/enemies/mobile_ground_layered/sam_launcher_launch.png"),
		],
	},
	"fortified_turret": {
		"base": preload("res://assets/runtime/enemies/mercenary_ground_layered/fort_base.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/fort_weapon.png"),
		"barrel": preload("res://assets/runtime/enemies/mercenary_ground_layered/fort_barrel.png"),
		"damage": preload("res://assets/runtime/enemies/mercenary_ground_layered/fort_damage.png"),
	},
	"coastal_flak": {
		"base": preload("res://assets/runtime/enemies/mercenary_ground_layered/flak_base.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/flak_weapon.png"),
		"barrel": preload("res://assets/runtime/enemies/mercenary_ground_layered/flak_barrel.png"),
		"damage": preload("res://assets/runtime/enemies/mercenary_ground_layered/flak_damage.png"),
	},
	"armoured_aa_carrier": {
		"base": preload("res://assets/runtime/enemies/mobile_ground_layered/aa_carrier_base.png"),
		"locomotion": [preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/aa_carrier/0.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/aa_carrier/1.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/aa_carrier/2.png"), preload("res://assets/runtime/enemies/mobile_ground_layered/locomotion/aa_carrier/3.png")],
		"weapon": preload("res://assets/runtime/enemies/mobile_ground_layered/aa_weapon_head.png"),
		"barrel": preload("res://assets/runtime/enemies/mobile_ground_layered/aa_twin_barrels.png"),
	},
}
const MERCENARY_GROUND_FORCE_SPRITES := {
	"mercenary_rifle_team": preload("res://assets/runtime/enemies/mercenary_infantry/mercenary_rifle_team_idle.png"),
	"mercenary_heavy_team": preload("res://assets/runtime/enemies/mercenary_infantry/mercenary_heavy_team_idle.png"),
	"security_patrol_mech": preload("res://assets/runtime/enemies/ground_mechs/security_patrol_mech_idle.png"),
}
const MACHINE_MECH_SPRITES := {
	"autonomous_salvage_mech": preload("res://assets/runtime/enemies/ground_mechs/autonomous_salvage_mech_idle.png"),
}
const MERCENARY_SEA_SPRITES := {
	"river_patrol": preload("res://assets/runtime/enemies/mercenary_sea/river_patrol_idle.png"),
	"torpedo_boat": preload("res://assets/runtime/enemies/mercenary_sea/torpedo_boat_idle.png"),
	"fast_attack_craft": preload("res://assets/runtime/enemies/mercenary_sea/fast_attack_craft_idle.png"),
	"missile_corvette": preload("res://assets/runtime/enemies/mercenary_sea/missile_corvette_idle.png"),
}
const NAVAL_SPECIALIST_ART := {
	"river_patrol": {
		"turret": [
			preload("res://assets/runtime/enemies/naval_layered/river_turret.png"),
			preload("res://assets/runtime/enemies/naval_layered/river_turret_recoil.png"),
		],
		"mount": preload("res://assets/runtime/enemies/naval_layered/river_mount.png"),
		"turret_anchor": Vector2(0, 5),
	},
	"torpedo_boat": {
		"turret": preload("res://assets/runtime/enemies/naval_layered/torpedo_turret.png"),
		"turret_anchor": Vector2(0, 8),
		"launcher_anchor": Vector2(0, -9),
		"launcher": [
			preload("res://assets/runtime/enemies/naval_layered/torpedo_launcher_closed.png"),
			preload("res://assets/runtime/enemies/naval_layered/torpedo_launcher_opening.png"),
			preload("res://assets/runtime/enemies/naval_layered/torpedo_launcher_open.png"),
			preload("res://assets/runtime/enemies/naval_layered/torpedo_launcher_fire.png"),
		],
	},
	"fast_attack_craft": {
		"turret": preload("res://assets/runtime/enemies/naval_layered/fast_turret.png"),
		"turret_anchor": Vector2(0, 8),
		"radar_pedestal": preload("res://assets/runtime/enemies/naval_layered/fast_radar_pedestal.png"),
		"radar_array": preload("res://assets/runtime/enemies/naval_layered/fast_radar_array.png"),
		"radar_anchor": Vector2(0, -11),
	},
	"missile_corvette": {
		"turret": preload("res://assets/runtime/enemies/naval_layered/corvette_turret.png"),
		"mount": preload("res://assets/runtime/enemies/naval_layered/corvette_mount.png"),
		"turret_anchor": Vector2(0, 17),
		"launcher_anchor": Vector2(0, -8),
		"launcher": [
			preload("res://assets/runtime/enemies/naval_layered/corvette_launcher_closed.png"),
			preload("res://assets/runtime/enemies/naval_layered/corvette_launcher_opening.png"),
			preload("res://assets/runtime/enemies/naval_layered/corvette_launcher_open.png"),
			preload("res://assets/runtime/enemies/naval_layered/corvette_launcher_fire.png"),
		],
	},
}
const NAVAL_WAKE_FRAMES := [
	preload("res://assets/runtime/effects/naval_wake/0.png"),
	preload("res://assets/runtime/effects/naval_wake/1.png"),
	preload("res://assets/runtime/effects/naval_wake/2.png"),
	preload("res://assets/runtime/effects/naval_wake/3.png"),
]
const AIR_PROPULSION_FRAMES := {
	"human_turbine": [
		preload("res://assets/runtime/effects/enemy_propulsion/human_turbine/0.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/human_turbine/1.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/human_turbine/2.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/human_turbine/3.png"),
	],
	"machine_thruster": [
		preload("res://assets/runtime/effects/enemy_propulsion/machine_thruster/0.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/machine_thruster/1.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/machine_thruster/2.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/machine_thruster/3.png"),
	],
	"orbital_impulse": [
		preload("res://assets/runtime/effects/enemy_propulsion/orbital_impulse/0.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/orbital_impulse/1.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/orbital_impulse/2.png"),
		preload("res://assets/runtime/effects/enemy_propulsion/orbital_impulse/3.png"),
	],
}
const AIR_PROPULSION_STYLE := {
	"scout_falcon": "human_turbine",
	"gunship_mk1": "human_turbine",
	"heavy_bomber": "human_turbine",
	"drone_scout": "machine_thruster",
	"drone_bomber": "machine_thruster",
	"drone_missile_node": "machine_thruster",
	"exo_drone": "orbital_impulse",
	"orbital_sentry": "orbital_impulse",
	"beam_sentry": "orbital_impulse",
	"orbital_lancer": "orbital_impulse",
}
const MACHINE_AIR_SPRITES := {
	"drone_scout": preload("res://assets/runtime/enemies/machine_air/drone_scout_idle.png"),
	"drone_hunter": preload("res://assets/runtime/enemies/machine_air/drone_hunter_idle.png"),
	"drone_bomber": preload("res://assets/runtime/enemies/machine_air/drone_bomber_idle.png"),
	"drone_missile_node": preload("res://assets/runtime/enemies/machine_air/drone_missile_node_idle.png"),
}
const MACHINE_GROUND_SPRITES := {
	"autonomous_armor": preload("res://assets/runtime/enemies/machine_ground/autonomous_armor_idle.png"),
	"factory_defence_node": preload("res://assets/runtime/enemies/machine_ground/factory_defence_node_idle.png"),
}
const LAYERED_MACHINE_GROUND_SPRITES := {
	"autonomous_armor": {
		"base": preload("res://assets/runtime/enemies/machine_ground_layered/autonomous_armor_base.png"),
		"locomotion": [preload("res://assets/runtime/enemies/machine_ground_layered/locomotion/autonomous_armor/0.png"), preload("res://assets/runtime/enemies/machine_ground_layered/locomotion/autonomous_armor/1.png"), preload("res://assets/runtime/enemies/machine_ground_layered/locomotion/autonomous_armor/2.png"), preload("res://assets/runtime/enemies/machine_ground_layered/locomotion/autonomous_armor/3.png")],
		"weapon": preload("res://assets/runtime/enemies/machine_ground_layered/autonomous_armor_weapon.png"),
		"core_pulse": true,
	},
	"factory_defence_node": {
		"base": preload("res://assets/runtime/enemies/machine_ground_layered/factory_defence_base.png"),
		"weapon": preload("res://assets/runtime/enemies/machine_ground_layered/factory_defence_weapon.png"),
		"core_pulse": true,
	},
}
const ORBITAL_AIR_SPRITES := {
	"exo_drone": preload("res://assets/runtime/enemies/orbital_air/exo_drone_idle.png"),
	"orbital_sentry": preload("res://assets/runtime/enemies/orbital_air/orbital_sentry_idle.png"),
	"phase_interceptor": preload("res://assets/runtime/enemies/orbital_air/phase_interceptor_idle.png"),
	"beam_sentry": preload("res://assets/runtime/enemies/orbital_air/beam_sentry_idle.png"),
	"orbital_lancer": preload("res://assets/runtime/enemies/orbital_air/orbital_lancer_idle.png"),
}
const MERCENARY_BOSS_SPRITES := {
	"gunship_alpha": preload("res://assets/runtime/enemies/mercenary_boss/gunship_alpha_idle.png"),
	"armoured_train": preload("res://assets/runtime/enemies/mercenary_boss/armoured_train_idle.png"),
	"missile_cruiser": preload("res://assets/runtime/enemies/mercenary_boss/missile_cruiser_idle.png"),
}
const MERCENARY_BOSS_SPECIALIST_ART := {
	"gunship_alpha": {
		"mount": preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_collar.png"),
		"turret": preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_turret.png"),
		"barrel": preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_barrel_recoil.png"),
		"barrel_hot": preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_barrel_hot.png"),
		"engines": [preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_engine_normal.png"), preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_engine_hot.png"), preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_engine_damaged.png")],
		"engine_anchors": [Vector2(-28,-25), Vector2(28,-25)],
		"damage": preload("res://assets/runtime/enemies/mercenary_boss_layered/gunship_cracked_plate.png"),
		"anchors": [Vector2(-22,-5), Vector2(22,-5)],
	},
	"armoured_train": {
		"mount": preload("res://assets/runtime/enemies/mercenary_boss_layered/train_collar.png"),
		"turret": preload("res://assets/runtime/enemies/mercenary_boss_layered/train_turret.png"),
		"turret_damaged": preload("res://assets/runtime/enemies/mercenary_boss_layered/train_turret_damaged.png"),
		"barrel": preload("res://assets/runtime/enemies/mercenary_boss_layered/train_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/mercenary_boss_layered/train_barrel_recoil.png"),
		"barrel_hot": preload("res://assets/runtime/enemies/mercenary_boss_layered/train_barrel_hot.png"),
		"vents": [preload("res://assets/runtime/enemies/mercenary_boss_layered/train_vent_closed.png"), preload("res://assets/runtime/enemies/mercenary_boss_layered/train_vent_open.png")],
		"vent_anchors": [Vector2(-18,-23), Vector2(18,23)],
		"bogies": [preload("res://assets/runtime/enemies/mercenary_boss_layered/train_bogie_intact.png"), preload("res://assets/runtime/enemies/mercenary_boss_layered/train_bogie_damaged.png")],
		"bogie_anchors": [Vector2(-19,-57), Vector2(19,57)],
		"anchors": [Vector2(0,-46), Vector2(0,2), Vector2(0,47)],
	},
	"missile_cruiser": {
		"mount": preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_collar.png"),
		"turret": preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_turret.png"),
		"barrel": preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_barrel.png"),
		"barrel_recoil": preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_barrel_recoil.png"),
		"anchors": [Vector2(0,-36)],
		"hatch_anchors": [Vector2(-21,-7), Vector2(21,-7)],
		"hatches": [
			preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_cells_closed.png"),
			preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_cells_opening.png"),
			preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_cells_open.png"),
			preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_cells_fire.png"),
		],
		"doors": [preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_hatch_port.png"), preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_hatch_starboard.png")],
		"damage": [preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_radar_damaged.png"), preload("res://assets/runtime/enemies/mercenary_boss_layered/cruiser_scorched_deck.png")],
	},
}
const BOSS_PHASE_OVERLAYS := {
	"gunship_alpha": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/gunship_alpha/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/gunship_alpha/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/gunship_alpha/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/gunship_alpha/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/gunship_alpha/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/gunship_alpha/critical_3.png"),
		],
	},
	"armoured_train": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/armoured_train/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/armoured_train/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/armoured_train/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/armoured_train/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/armoured_train/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/armoured_train/critical_3.png"),
		],
	},
	"missile_cruiser": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/missile_cruiser/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/missile_cruiser/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/missile_cruiser/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/missile_cruiser/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/missile_cruiser/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/missile_cruiser/critical_3.png"),
		],
	},
	"swarm_controller": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/swarm_controller/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/swarm_controller/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/swarm_controller/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/swarm_controller/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/swarm_controller/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/swarm_controller/critical_3.png"),
		],
	},
	"ai_forge_core": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/ai_forge_core/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/ai_forge_core/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/ai_forge_core/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/ai_forge_core/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/ai_forge_core/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/ai_forge_core/critical_3.png"),
		],
	},
	"orbital_command_node": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/orbital_command_node/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/orbital_command_node/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/orbital_command_node/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/orbital_command_node/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/orbital_command_node/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/orbital_command_node/critical_3.png"),
		],
	},
	"phase_control_array": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/phase_control_array/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/phase_control_array/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/phase_control_array/critical_3.png"),
		],
	},
	"station_warden": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/station_warden/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/station_warden/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/station_warden/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/station_warden/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/station_warden/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/station_warden/critical_3.png"),
		],
	},
	"machine_ark": {
		"phase_2": preload("res://assets/runtime/enemies/boss_animation/machine_ark/phase_2_damage.png"),
		"phase_3": preload("res://assets/runtime/enemies/boss_animation/machine_ark/phase_3_damage.png"),
		"critical": [
			preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_0.png"),
			preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_1.png"),
			preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_2.png"),
			preload("res://assets/runtime/enemies/boss_animation/machine_ark/critical_3.png"),
		],
	},
}
const MACHINE_BOSS_SPRITES := {
	"swarm_controller": preload("res://assets/runtime/enemies/machine_boss/swarm_controller_idle_v2.png"),
	"ai_forge_core": preload("res://assets/runtime/enemies/machine_boss/ai_forge_core_idle_v2.png"),
}
const MACHINE_BOSS_SPECIALIST_ART := {
	"swarm_controller": {
		"racks": [preload("res://assets/runtime/enemies/machine_boss_layered/swarm_rack_closed.png"), preload("res://assets/runtime/enemies/machine_boss_layered/swarm_rack_opening.png"), preload("res://assets/runtime/enemies/machine_boss_layered/swarm_rack_open.png")],
		"drones": [preload("res://assets/runtime/enemies/machine_boss_layered/swarm_drone_folded.png"), preload("res://assets/runtime/enemies/machine_boss_layered/swarm_drone_ready.png")],
		"sensor": preload("res://assets/runtime/enemies/machine_boss_layered/swarm_sensor.png"),
		"sensor_damaged": preload("res://assets/runtime/enemies/machine_boss_layered/swarm_sensor_damaged.png"),
		"sensor_anchor": Vector2(-28,-5),
		"cores": [preload("res://assets/runtime/enemies/machine_boss_layered/swarm_core_normal.png"), preload("res://assets/runtime/enemies/machine_boss_layered/swarm_core_overload.png"), preload("res://assets/runtime/enemies/machine_boss_layered/swarm_core_ruptured.png")],
		"rack_anchor": Vector2(29,1),
	},
	"ai_forge_core": {
		"conveyors": [preload("res://assets/runtime/enemies/machine_boss_layered/forge_conveyor.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_conveyor_broken.png")],
		"blanks": [preload("res://assets/runtime/enemies/machine_boss_layered/forge_blank_light.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_blank_medium.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_blank_heavy.png")],
		"presses": [preload("res://assets/runtime/enemies/machine_boss_layered/forge_press_raised.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_press_lowered.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_press_scorched.png")],
		"arms": [preload("res://assets/runtime/enemies/machine_boss_layered/forge_arm_retracted.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_arm_extended.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_arm_severed.png")],
		"tool": preload("res://assets/runtime/enemies/machine_boss_layered/forge_tool_head.png"),
		"crucibles": [preload("res://assets/runtime/enemies/machine_boss_layered/forge_crucible_closed.png"), preload("res://assets/runtime/enemies/machine_boss_layered/forge_crucible_open.png")],
	},
}
const ORBITAL_BOSS_SPRITES := {
	"orbital_command_node": preload("res://assets/runtime/enemies/orbital_boss/orbital_command_node_idle_v2.png"),
	"phase_control_array": preload("res://assets/runtime/enemies/orbital_boss/phase_control_array_idle_v2.png"),
	"station_warden": preload("res://assets/runtime/enemies/orbital_boss/station_warden_idle.png"),
	"machine_ark": preload("res://assets/runtime/enemies/orbital_boss/machine_ark_idle.png"),
}
const ORBITAL_BOSS_SPECIALIST_ART := {
	"orbital_command_node": {
		"anchors":[Vector2(-31,-1),Vector2(32,8)], "mount":preload("res://assets/runtime/enemies/orbital_boss_layered/command_collar.png"),
		"weapon":preload("res://assets/runtime/enemies/orbital_boss_layered/command_beam.png"), "weapon_recoil":preload("res://assets/runtime/enemies/orbital_boss_layered/command_beam_recoil.png"),
		"dish":preload("res://assets/runtime/enemies/orbital_boss_layered/command_dish.png"), "masts":[preload("res://assets/runtime/enemies/orbital_boss_layered/command_mast_folded.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/command_mast_deployed.png")],
		"cores":[preload("res://assets/runtime/enemies/orbital_boss_layered/command_core_normal.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/command_core_overload.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/command_core_ruptured.png")],
	},
	"phase_control_array": {
		"anchors":[Vector2(-38,-2),Vector2(36,-12)], "lenses":[preload("res://assets/runtime/enemies/orbital_boss_layered/phase_lens_calm.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/phase_lens_charge.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/phase_lens_aligned.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/phase_lens_unstable.png")],
		"shutters":[preload("res://assets/runtime/enemies/orbital_boss_layered/phase_shutter_closed.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/phase_shutter_open.png")],
		"projectors":[preload("res://assets/runtime/enemies/orbital_boss_layered/phase_projector.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/phase_projector_damaged.png")],
	},
	"station_warden": {
		"anchors":[Vector2(-48,-4),Vector2(45,-6)], "mount":preload("res://assets/runtime/enemies/orbital_boss_layered/warden_collar.png"),
		"weapon":preload("res://assets/runtime/enemies/orbital_boss_layered/warden_rail.png"), "weapon_recoil":preload("res://assets/runtime/enemies/orbital_boss_layered/warden_rail_recoil.png"),
		"point_turret":preload("res://assets/runtime/enemies/orbital_boss_layered/warden_point_turret.png"), "clamps":[preload("res://assets/runtime/enemies/orbital_boss_layered/warden_clamp_closed.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/warden_clamp_open.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/warden_clamp_broken.png")],
		"vents":[preload("res://assets/runtime/enemies/orbital_boss_layered/warden_vent_closed.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/warden_vent_hot.png")], "damage":preload("res://assets/runtime/enemies/orbital_boss_layered/warden_rail_scorched.png"),
	},
	"machine_ark": {
		"anchors":[Vector2(-46,0),Vector2(46,6)], "apertures":[preload("res://assets/runtime/enemies/orbital_boss_layered/ark_aperture_closed.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/ark_aperture_opening.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/ark_aperture_open.png")],
		"arcs":[preload("res://assets/runtime/enemies/orbital_boss_layered/ark_arc_retracted.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/ark_arc_extended.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/ark_arc_severed.png")],
		"pylon":preload("res://assets/runtime/enemies/orbital_boss_layered/ark_tracking_pylon.png"), "cores":[preload("res://assets/runtime/enemies/orbital_boss_layered/ark_core_normal.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/ark_core_overload.png"),preload("res://assets/runtime/enemies/orbital_boss_layered/ark_core_ruptured.png")], "damage":preload("res://assets/runtime/enemies/orbital_boss_layered/ark_cracked_plate.png"),
	},
}
const ORBITAL_PYLON_MOUNT := preload("res://assets/runtime/enemies/orbital_boss_specialist/pylon_mount.png")
const ORBITAL_TRACKING_PYLON := preload("res://assets/runtime/enemies/orbital_boss_specialist/tracking_pylon.png")
const PHASE_FIELD_FRAMES := [
	preload("res://assets/runtime/enemies/orbital_boss_specialist/phase_field_0.png"),
	preload("res://assets/runtime/enemies/orbital_boss_specialist/phase_field_1.png"),
	preload("res://assets/runtime/enemies/orbital_boss_specialist/phase_field_2.png"),
	preload("res://assets/runtime/enemies/orbital_boss_specialist/phase_field_3.png"),
]

const PLAYER := Color("d9e0e5")
const PLAYER_DARK := Color("667985")
const PLAYER_GLASS := Color("6aa4c8")
const PLAYER_ENGINE := Color("e8ca6a")
const PLAYER_GUN := Color("3d4a52")
const PLAYER_MUZZLE := Color("e7c46a")
const MERC_AIR := Color("9f5049")
const MERC_DARK := Color("4d3e3a")
const SURFACE := Color("766b55")
const SURFACE_DARK := Color("3d3a31")
const AI := Color("b7c7ca")
const AI_DARK := Color("45545a")
const AI_CORE := Color("67c3a5")
const BOSS := Color("c86054")
const BOSS_DARK := Color("55322f")
const TRANSFORM_EXPOSURES := 10
const PRESENTATION_REDRAW_SECONDS := 1.0 / 30.0
const VX94_EVASIVE_ROLL := [
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_00.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_01.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_02.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_03.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_04.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_05.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_06.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_07.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_08.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_09.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_10.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_11.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_12.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_13.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_14.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_15.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_16.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_17.png"),
	preload("res://assets/runtime/craft/vx94/evasive_roll/roll_18.png"), preload("res://assets/runtime/craft/vx94/evasive_roll/roll_19.png"),
]

var _surface: Control
var _visual_sweep := 0.0
var _bank_visual := 0.0
var _redraw_elapsed := 0.0
var _missing_art_ids: Dictionary = {}

func _ready() -> void:
	layer = 12
	_surface = CombatArtSurface.new()
	_surface.director = self
	_surface.position = Vector2.ZERO
	_surface.size = Vector2(640, 360)
	_surface.custom_minimum_size = Vector2(640, 360)
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)

func _process(delta: float) -> void:
	var target := 1.0 if _craft_form() == "bomber" else 0.0
	_visual_sweep = move_toward(_visual_sweep, target, maxf(0.0, delta) / CraftFormRules.TRANSFORM_VISUAL_SECONDS)
	_bank_visual = move_toward(_bank_visual, Input.get_axis("move_left", "move_right"), maxf(0.0, delta) * 5.5)
	_redraw_elapsed += maxf(0.0, delta)
	if _surface != null and _redraw_elapsed >= PRESENTATION_REDRAW_SECONDS:
		_redraw_elapsed = fposmod(_redraw_elapsed, PRESENTATION_REDRAW_SECONDS)
		_surface.queue_redraw()

func _draw_combat_art(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	_draw_pickups(surface, scene)
	if _capture_fx_state() == "destruction":
		_render_destruction_reward_capture(surface,scene)
		_draw_player(surface,scene)
		return
	if _capture_fx_state() == "combat":
		_render_combat_fx_capture(surface,scene)
		_draw_player(surface,scene)
		return
	if _capture_ground_state() == "mobile":
		_draw_mobile_ground_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_ground_state() == "mechs":
		_render_mech_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_ground_state() == "naval":
		_render_naval_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_ground_state() == "infantry":
		_render_infantry_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_air_state() == "human":
		_render_human_air_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_air_state() == "machine":
		_render_machine_air_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_air_state() == "orbital":
		_render_orbital_air_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_air_state() == "hypersonic":
		_render_hypersonic_air_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_boss_state() == "mercenary":
		_render_mercenary_boss_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_boss_state() == "machine":
		_render_machine_boss_capture(surface, scene)
		_draw_player(surface, scene)
		return
	if _capture_boss_state() == "orbital":
		_render_orbital_boss_capture(surface, scene)
		_draw_player(surface, scene)
		return
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			_draw_enemy(surface, enemy)
	_draw_player(surface, scene)

func _draw_mobile_ground_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 1.20) < 0.12 else 0.0
	var definitions := [
		{"id":"light_tank", "position":Vector2(176,158), "fire_timer":0.0, "recoil_timer":recoil, "hp":10, "max_hp":10, "age":time},
		{"id":"sam_truck", "position":Vector2(320,142), "fire_timer":fposmod(1.1-time, 1.1), "recoil_timer":recoil, "hp":10, "max_hp":10, "age":time},
		{"id":"armoured_aa_carrier", "position":Vector2(464,158), "fire_timer":0.0, "recoil_timer":recoil, "hp":10, "max_hp":10, "age":time},
	]
	for enemy in definitions:
		_draw_layered_ground(surface, enemy["position"], enemy, LAYERED_GROUND_SPRITES[enemy["id"]], 1.0)
	var machine_definitions := [
		{"id":"autonomous_armor", "position":Vector2(250,222), "fire_timer":0.0, "recoil_timer":recoil, "hp":12, "max_hp":12, "age":time},
		{"id":"factory_defence_node", "position":Vector2(390,222), "fire_timer":0.0, "recoil_timer":recoil, "hp":12, "max_hp":12, "age":time},
	]
	for enemy in machine_definitions:
		_draw_layered_ground(surface, enemy["position"], enemy, LAYERED_MACHINE_GROUND_SPRITES[enemy["id"]], 1.0)

func _render_mech_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 1.20) < 0.12 else 0.0
	var definitions := [
		{"id":"security_patrol_mech", "position":Vector2(150,150), "hit_timer":0.0, "recoil_timer":recoil, "hp":20, "max_hp":20, "age":time},
		{"id":"autonomous_salvage_mech", "position":Vector2(270,150), "hit_timer":0.0, "recoil_timer":recoil, "hp":20, "max_hp":20, "age":time},
	]
	for enemy in definitions:
		var enemy_id: String = enemy["id"]
		var fallback: Texture2D = MERCENARY_GROUND_FORCE_SPRITES[enemy_id] if enemy_id == "security_patrol_mech" else MACHINE_MECH_SPRITES[enemy_id]
		var presentation_scale := 1.16 if enemy_id == "security_patrol_mech" else 1.0
		_draw_animated_unit(surface, enemy["position"], enemy_id, enemy, fallback, presentation_scale)
		_render_ground_force_specialist(surface, enemy["position"], enemy_id, enemy, presentation_scale)

func _render_naval_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.12 if fposmod(time, 1.40) < 0.14 else 0.0
	var fire_timer := fposmod(1.0-time, 1.0)
	var definitions := [
		{"id":"river_patrol", "position":Vector2(110,150), "fire_timer":0.0, "recoil_timer":recoil, "hp":10, "max_hp":10, "age":time},
		{"id":"torpedo_boat", "position":Vector2(245,150), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":14, "max_hp":14, "age":time},
		{"id":"fast_attack_craft", "position":Vector2(390,150), "fire_timer":0.0, "recoil_timer":recoil, "hp":18, "max_hp":18, "age":time},
		{"id":"missile_corvette", "position":Vector2(530,150), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":30, "max_hp":30, "age":time},
	]
	for enemy in definitions:
		_draw_naval_unit(surface, enemy["position"], enemy["id"], enemy, MERCENARY_SEA_SPRITES[enemy["id"]], 1.0)

func _render_infantry_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 0.90) < 0.12 else 0.0
	var hit := 0.14 if fposmod(time+0.35, 1.70) < 0.14 else 0.0
	var definitions := [
		{"id":"mercenary_rifle_team", "position":Vector2(150,150), "hit_timer":hit, "recoil_timer":recoil, "hp":8, "max_hp":8, "age":time},
		{"id":"mercenary_heavy_team", "position":Vector2(270,150), "hit_timer":hit, "recoil_timer":recoil, "hp":12, "max_hp":12, "age":time},
	]
	for enemy in definitions:
		_draw_infantry_team(surface, enemy["position"], enemy["id"], enemy, 1.18)

func _render_human_air_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 1.20) < 0.12 else 0.0
	var fire_timer := fposmod(1.0-time, 1.0)
	var definitions := [
		{"id":"gunship_mk1", "position":Vector2(175,145), "fire_timer":0.0, "recoil_timer":recoil, "hp":18, "max_hp":18, "age":time, "visual_bank":sin(time*2.0)},
		{"id":"attack_chopper", "position":Vector2(320,145), "fire_timer":0.0, "recoil_timer":recoil, "hp":16, "max_hp":16, "age":time, "visual_bank":0.0},
		{"id":"heavy_bomber", "position":Vector2(475,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":30, "max_hp":30, "age":time, "visual_bank":0.0},
	]
	for enemy in definitions:
		_draw_hostile_airframe(surface, enemy["position"], enemy["id"], enemy, MERCENARY_AIR_SPRITES[enemy["id"]])

func _render_machine_air_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 1.20) < 0.12 else 0.0
	var fire_timer := fposmod(1.0-time, 1.0)
	var definitions := [
		{"id":"drone_scout", "position":Vector2(110,145), "fire_timer":0.0, "recoil_timer":0.0, "hp":4, "max_hp":4, "age":time, "visual_bank":sin(time*2.2)},
		{"id":"drone_hunter", "position":Vector2(245,145), "fire_timer":0.0, "recoil_timer":recoil, "hp":8, "max_hp":8, "age":time, "visual_bank":sin(time*1.8)},
		{"id":"drone_bomber", "position":Vector2(390,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":15, "max_hp":15, "age":time, "visual_bank":sin(time*1.4)},
		{"id":"drone_missile_node", "position":Vector2(530,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":11, "max_hp":11, "age":time, "visual_bank":sin(time*1.6)},
	]
	for enemy in definitions:
		_draw_hostile_airframe(surface, enemy["position"], enemy["id"], enemy, MACHINE_AIR_SPRITES[enemy["id"]])

func _render_orbital_air_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 1.20) < 0.12 else 0.0
	var fire_timer := fposmod(1.0-time, 1.0)
	var definitions := [
		{"id":"exo_drone", "position":Vector2(85,145), "fire_timer":0.0, "recoil_timer":0.0, "hp":13, "max_hp":13, "age":time, "visual_bank":sin(time*1.7)},
		{"id":"orbital_sentry", "position":Vector2(205,145), "fire_timer":0.0, "recoil_timer":recoil, "hp":16, "max_hp":16, "age":time, "visual_bank":sin(time*1.9)},
		{"id":"phase_interceptor", "position":Vector2(320,145), "fire_timer":0.0, "recoil_timer":0.0, "hp":18, "max_hp":18, "age":time, "visual_bank":sin(time*2.1)},
		{"id":"beam_sentry", "position":Vector2(445,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":24, "max_hp":24, "age":time, "visual_bank":sin(time*1.5)},
		{"id":"orbital_lancer", "position":Vector2(570,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":30, "max_hp":30, "age":time, "visual_bank":sin(time*1.3)},
	]
	for enemy in definitions:
		_draw_hostile_airframe(surface, enemy["position"], enemy["id"], enemy, ORBITAL_AIR_SPRITES[enemy["id"]])

func _render_hypersonic_air_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var pulse := fposmod(time, 2.4) / 2.4
	var boom_age := fposmod(time, 0.72)
	var definitions := [
		{"id":"ace_interceptor", "position":Vector2(175,142), "hp":18, "max_hp":18, "age":time, "visual_bank":-0.15, "hypersonic_ratio":clampf(pulse * 1.8, 0.0, 1.0), "hypersonic_boom_age":99.0},
		{"id":"drone_hunter", "position":Vector2(320,142), "hp":12, "max_hp":12, "age":time, "visual_bank":0.10, "hypersonic_ratio":clampf(0.35 + pulse, 0.0, 1.0), "hypersonic_boom_age":99.0},
		{"id":"phase_interceptor", "position":Vector2(465,142), "hp":20, "max_hp":20, "age":time, "visual_bank":0.0, "hypersonic_ratio":1.0, "hypersonic_boom_age":boom_age},
	]
	for enemy in definitions:
		var enemy_id: String = enemy["id"]
		var texture: Texture2D = MERCENARY_AIR_SPRITES[enemy_id] if MERCENARY_AIR_SPRITES.has(enemy_id) else (MACHINE_AIR_SPRITES[enemy_id] if MACHINE_AIR_SPRITES.has(enemy_id) else ORBITAL_AIR_SPRITES[enemy_id])
		_draw_hostile_airframe(surface, enemy["position"], enemy_id, enemy, texture)

func _render_mercenary_boss_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time, 1.40) < 0.14 else 0.0
	var fire_timer := fposmod(1.0-time, 1.0)
	var phase := 1 + posmod(int(floor(time / 2.0)), 3)
	var definitions := [
		{"id":"gunship_alpha", "position":Vector2(125,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":28 if phase < 3 else 8, "max_hp":40, "boss_phase":phase, "age":time+2.0},
		{"id":"armoured_train", "position":Vector2(320,155), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":45 if phase < 3 else 12, "max_hp":70, "boss_phase":phase, "age":time+2.0},
		{"id":"missile_cruiser", "position":Vector2(515,155), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":52 if phase < 3 else 14, "max_hp":80, "boss_phase":phase, "age":time+2.0},
	]
	for enemy in definitions:
		_draw_production_boss(surface, enemy["position"], enemy["id"], enemy, MERCENARY_BOSS_SPRITES[enemy["id"]])

func _render_machine_boss_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else 0.0
	var recoil := 0.10 if fposmod(time,1.55)<0.18 else 0.0
	var fire_timer := fposmod(1.0-time,1.0)
	var phase := 1+posmod(int(floor(time/2.0)),3)
	var definitions := [
		{"id":"swarm_controller", "position":Vector2(215,145), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":38 if phase<3 else 9, "max_hp":55, "boss_phase":phase, "age":time+2.0},
		{"id":"ai_forge_core", "position":Vector2(435,150), "fire_timer":fire_timer, "recoil_timer":recoil, "hp":52 if phase<3 else 12, "max_hp":75, "boss_phase":phase, "age":time+2.0},
	]
	for enemy in definitions:
		_draw_production_boss(surface,enemy["position"],enemy["id"],enemy,MACHINE_BOSS_SPRITES[enemy["id"]])

func _render_orbital_boss_capture(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene,"mission_time") else 0.0
	var recoil := 0.10 if fposmod(time,1.45)<0.16 else 0.0
	var fire_timer := fposmod(1.0-time,1.0)
	var phase := 1+posmod(int(floor(time/2.0)),3)
	var definitions := [
		{"id":"orbital_command_node","position":Vector2(175,115),"fire_timer":fire_timer,"recoil_timer":recoil,"hp":48 if phase<3 else 10,"max_hp":64,"boss_phase":phase,"age":time+2.0},
		{"id":"phase_control_array","position":Vector2(465,115),"fire_timer":fire_timer,"recoil_timer":recoil,"hp":55 if phase<3 else 12,"max_hp":72,"boss_phase":phase,"age":time+2.0},
		{"id":"station_warden","position":Vector2(165,245),"fire_timer":fire_timer,"recoil_timer":recoil,"hp":70 if phase<3 else 15,"max_hp":90,"boss_phase":phase,"age":time+2.0},
		{"id":"machine_ark","position":Vector2(475,240),"fire_timer":fire_timer,"recoil_timer":recoil,"hp":92 if phase<3 else 19,"max_hp":120,"boss_phase":phase,"age":time+2.0},
	]
	for enemy in definitions:
		_draw_production_boss(surface,enemy["position"],enemy["id"],enemy,ORBITAL_BOSS_SPRITES[enemy["id"]])

func _render_combat_fx_capture(surface: CanvasItem,scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene,"mission_time") else 0.0
	var frame_index := posmod(int(floor(time*7.0)),4)
	var projectile_families := ["ballistic","enemy_cannon","homing_missile","needle_rail","plasma_lance","support_rocket","strategic_warhead"]
	for index in range(projectile_families.size()):
		var frames: Array = ProjectileCueDirector.PROJECTILE_FRAMES[projectile_families[index]]
		var texture: Texture2D = frames[frame_index]
		var center := Vector2(85+index*78,82)
		surface.draw_texture(texture,(center-texture.get_size()*0.5).round())
	var impact_families := ["muzzle","rotary_muzzle","armor_hit","shield_hit","bomb_impact","emp_disruption","water_impact","dust_impact"]
	for index in range(impact_families.size()):
		var frames: Array = ImpactArtLibrary.FRAMES[impact_families[index]]
		var texture: Texture2D = frames[frame_index]
		var center := Vector2(55+index*75,155)
		surface.draw_texture(texture,(center-texture.get_size()*0.5).round())
	var persistent_families := ["damage_smoke","damage_fire","damage_sparks","afterburner","contrail","debris","sonic_boom"]
	for index in range(persistent_families.size()):
		var frames: Array = PersistentEffectArtLibrary.FRAMES[persistent_families[index]]
		var texture: Texture2D = frames[frame_index]
		var center := Vector2(75+index*82,232)
		surface.draw_texture(texture,(center-texture.get_size()*0.5).round())

func _render_destruction_reward_capture(surface: CanvasItem,scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene,"mission_time") else 0.0
	for index in range(DESTRUCTION_CAPTURE_FRAMES["explosion"].size()):
		var texture: Texture2D = DESTRUCTION_CAPTURE_FRAMES["explosion"][index]
		var center := Vector2(74+index*70,84)
		surface.draw_texture(texture,(center-texture.get_size()*0.5).round())
	for family_index in range(2):
		var family := "flak" if family_index == 0 else "fort"
		for frame_index in range(3):
			var texture: Texture2D = DESTRUCTION_CAPTURE_FRAMES[family][frame_index]
			var center := Vector2(140+family_index*330+frame_index*72,170)
			surface.draw_texture(texture,(center-texture.get_size()*0.5).round())
	var pickup_families := ["bomb","repair","shield","weapon"]
	var pickup_frame := posmod(int(floor(time*6.0)),4)
	for index in range(pickup_families.size()):
		var texture: Texture2D = PICKUP_ANIMATION_FRAMES[pickup_families[index]][pickup_frame]
		var center := Vector2(150+index*115,252)
		surface.draw_texture(texture,(center-texture.get_size()*0.5).round())

func _supports(scene: Object) -> bool:
	return SceneContractCache.supports(scene, ["phase", "player_position", "enemies", "pickups"])

func _draw_pickups(surface: CanvasItem, scene: Object) -> void:
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else Time.get_ticks_msec() / 1000.0
	var frame_index := int(floor(time * 8.0)) % 4
	for pickup in scene.get("pickups"):
		if typeof(pickup) != TYPE_DICTIONARY:
			continue
		var kind := str(pickup.get("kind", ""))
		if not PICKUP_ANIMATION_FRAMES.has(kind):
			continue
		var frames: Array = PICKUP_ANIMATION_FRAMES[kind]
		var texture: Texture2D = frames[frame_index]
		var position: Vector2 = pickup.get("position", Vector2.ZERO)
		surface.draw_texture(texture, (position - texture.get_size() * 0.5).round())

func _has_property(subject: Object, property_name: String) -> bool:
	return SceneContractCache.has_property(subject, property_name)

func _draw_player(surface: CanvasItem, scene: Object) -> void:
	var p: Vector2 = scene.get("player_position") + _altitude_pitch_offset()
	var origin := (p - VX94_GAMEPLAY_ANCHOR).round()
	var loss_timer := float(scene.get("player_loss_timer")) if _has_property(scene, "player_loss_timer") else 0.0
	if loss_timer > 0.0:
		_draw_player_loss(surface, p, origin, loss_timer)
		return
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else Time.get_ticks_msec() / 1000.0
	if _capture_craft_state() == "evasive-roll":
		var capture_progress := fposmod(time, 1.2) / 1.2
		_draw_evasive_player(surface, p, time, capture_progress, -1 if fposmod(time, 2.4) < 1.2 else 1)
		return
	var evasive := get_node_or_null("/root/EvasiveRollDirector")
	if evasive != null and evasive.has_method("active") and bool(evasive.call("active")):
		_draw_evasive_player(surface, p, time, float(evasive.call("progress")), int(evasive.call("direction")))
		return
	var exhaust_frame: Texture2D = VX94_EXHAUST[int(floor(time * 12.0)) % VX94_EXHAUST.size()]
	surface.draw_texture(exhaust_frame, origin)
	if _capture_craft_state() in ["layered-sweep", "hypersonic-sweep"]:
		var sweep := _capture_sweep_ratio(time)
		_draw_layered_vx94(surface, p, -sweep if _capture_craft_state() == "hypersonic-sweep" else sweep)
		return
	var texture: Texture2D
	var hypersonic_sweep := _hypersonic_visual_ratio()
	if hypersonic_sweep > 0.01:
		var exposure := roundf(hypersonic_sweep * float(TRANSFORM_EXPOSURES - 1)) / float(TRANSFORM_EXPOSURES - 1)
		_draw_layered_vx94(surface, p, -exposure)
		var max_hull := maxi(1, int(scene.call("_max_hull"))) if scene.has_method("_max_hull") else 100
		var damage_ratio := 1.0 - clampf(float(scene.get("hull")) / float(max_hull), 0.0, 1.0) if _has_property(scene, "hull") else 0.0
		_draw_player_damage(surface, origin, damage_ratio)
		return
	if _visual_sweep <= 0.02:
		texture = VX94_FIGHTER_BANK[_bank_frame_index()]
	elif _visual_sweep >= 0.98:
		texture = VX94_BOMBER_BANK[_bank_frame_index()]
	else:
		var exposure := roundf(_visual_sweep * float(TRANSFORM_EXPOSURES - 1)) / float(TRANSFORM_EXPOSURES - 1)
		_draw_layered_vx94(surface, p, exposure)
		texture = null
	if texture != null:
		surface.draw_texture(texture, origin)
	var max_hull := maxi(1, int(scene.call("_max_hull"))) if scene.has_method("_max_hull") else 100
	var damage_ratio := 1.0 - clampf(float(scene.get("hull")) / float(max_hull), 0.0, 1.0) if _has_property(scene, "hull") else 0.0
	_draw_player_damage(surface, origin, damage_ratio)

func _draw_evasive_player(surface: CanvasItem, p: Vector2, time: float, progress: float, direction: int) -> void:
	var roll_phase := clampf(progress, 0.0, 1.0)
	var authored_index := clampi(int(roundf(roll_phase * float(VX94_EVASIVE_ROLL.size() - 1))), 0, VX94_EVASIVE_ROLL.size() - 1)
	var frame_index := authored_index if direction < 0 else posmod(VX94_EVASIVE_ROLL.size() - authored_index, VX94_EVASIVE_ROLL.size())
	var texture: Texture2D = VX94_EVASIVE_ROLL[frame_index]
	var exhaust: Texture2D = VX94_EXHAUST[int(floor(time * 12.0)) % VX94_EXHAUST.size()]
	surface.draw_texture(exhaust, (p - VX94_GAMEPLAY_ANCHOR).round())
	surface.draw_texture(texture, (p - VX94_GAMEPLAY_ANCHOR).round())

func _draw_layered_vx94(surface: CanvasItem, p: Vector2, sweep: float) -> void:
	var bomber_sweep := clampf(sweep, 0.0, 1.0)
	var hypersonic_sweep := clampf(-sweep, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, bomber_sweep)
	var settle := sin(clampf((bomber_sweep - 0.72) / 0.28, 0.0, 1.0) * PI) * 0.055
	var articulated := clampf(eased + settle, 0.0, 1.06)
	var left_hinge := p + Vector2(-6,-6)
	var right_hinge := p + Vector2(6,-6)
	_draw_pivoted_component(surface, VX94_LAYERED["tailplane_left"], p + Vector2(-5,14), Vector2(0.82,0.50), 0.0)
	_draw_pivoted_component(surface, VX94_LAYERED["tailplane_right"], p + Vector2(5,14), Vector2(0.18,0.50), 0.0)
	var left_angle := deg_to_rad(lerpf(lerpf(-18.0, -44.0, hypersonic_sweep), 13.0, articulated))
	var right_angle := deg_to_rad(lerpf(lerpf(18.0, 44.0, hypersonic_sweep), -13.0, articulated))
	_draw_pivoted_component(surface, VX94_LAYERED["wing_left"], left_hinge, Vector2(0.88,0.18), left_angle)
	_draw_pivoted_component(surface, VX94_LAYERED["wing_right"], right_hinge, Vector2(0.12,0.18), right_angle)
	_draw_pivoted_component(surface, VX94_LAYERED["hardpoint_left"], left_hinge + Vector2(-7,9), Vector2(0.78,0.50), left_angle * 0.55)
	_draw_pivoted_component(surface, VX94_LAYERED["hardpoint_right"], right_hinge + Vector2(7,9), Vector2(0.22,0.50), right_angle * 0.55)
	_draw_pivoted_component(surface, VX94_LAYERED["actuator_left"], left_hinge, Vector2(0.55,0.08), left_angle * 0.42)
	_draw_pivoted_component(surface, VX94_LAYERED["actuator_right"], right_hinge, Vector2(0.45,0.08), right_angle * 0.42)
	var fuselage: Texture2D = VX94_LAYERED["fuselage"]
	surface.draw_texture(fuselage, (p - Vector2(fuselage.get_width() * 0.5, 29)).round())
	var bay: Texture2D = VX94_LAYERED["bay_open"] if articulated > 0.72 else VX94_LAYERED["bay_closed"]
	_draw_pivoted_component(surface, bay, p + Vector2(0,4), Vector2(0.50,0.50), 0.0, Color(1,1,1,0.72))

func _hypersonic_visual_ratio() -> float:
	var craft := get_node_or_null("/root/CraftFormDirector")
	return clampf(float(craft.call("hypersonic_visual_ratio")), 0.0, 1.0) if craft != null and craft.has_method("hypersonic_visual_ratio") else 0.0

func _draw_pivoted_component(surface: CanvasItem, texture: Texture2D, world_pivot: Vector2, normalized_pivot: Vector2, angle: float, tint := Color.WHITE) -> void:
	var local_pivot := texture.get_size() * normalized_pivot
	surface.draw_set_transform(world_pivot.round(), angle, Vector2.ONE)
	surface.draw_texture(texture, -local_pivot.round(), tint)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _capture_sweep_ratio(time: float) -> float:
	var phase := fposmod(time, 2.4) / 2.4
	var travel := phase * 2.0 if phase < 0.5 else (1.0 - phase) * 2.0
	if travel < 0.12:
		return 0.0
	if travel < 0.68:
		return smoothstep(0.12, 0.68, travel)
	return 1.0

func _capture_craft_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args(): return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-craft="):
			return argument.trim_prefix("--capture-craft=").to_lower()
	return ""

func _capture_ground_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args(): return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-ground="):
			return argument.trim_prefix("--capture-ground=").to_lower()
	return ""

func _capture_air_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args(): return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-air="):
			return argument.trim_prefix("--capture-air=").to_lower()
	return ""

func _capture_boss_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args(): return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-boss="):
			return argument.trim_prefix("--capture-boss=").to_lower()
	return ""

func _capture_fx_state() -> String:
	if not "--capture-gameplay" in OS.get_cmdline_user_args(): return ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-fx="):
			return argument.trim_prefix("--capture-fx=").to_lower()
	return ""

func _draw_player_damage(surface: CanvasItem, origin: Vector2, damage_ratio: float) -> void:
	var stage := -1
	if damage_ratio >= 0.72:
		stage = 2
	elif damage_ratio >= 0.48:
		stage = 1
	elif damage_ratio >= 0.22:
		stage = 0
	if stage < 0:
		return
	var sweep := smoothstep(0.0, 1.0, clampf(_visual_sweep, 0.0, 1.0))
	if sweep < 0.999:
		surface.draw_texture(VX94_DAMAGE["fighter"][stage], origin, Color(1,1,1,1.0-sweep))
	if sweep > 0.001:
		surface.draw_texture(VX94_DAMAGE["bomber"][stage], origin, Color(1,1,1,sweep))

func _draw_player_loss(surface: CanvasItem, p: Vector2, origin: Vector2, loss_timer: float) -> void:
	var ratio := clampf(1.0 - loss_timer / PLAYER_LOSS_SEQUENCE_SECONDS, 0.0, 1.0)
	var frames: Array = VX94_BOMBER_BREAKUP if _craft_form() == "bomber" else VX94_FIGHTER_BREAKUP
	var frame_index := clampi(int(floor(ratio * 4.8)), 0, frames.size() - 1)
	var wreck_fall := Vector2(sin(ratio * 9.0) * 3.0, ratio * ratio * 24.0)
	surface.draw_texture(frames[frame_index], (origin + wreck_fall).round(), Color(0.88, 0.86, 0.79, 1.0 - smoothstep(0.76, 1.0, ratio)))
	var phase := int(floor(ratio * 30.0))
	_draw_enemy_effect_frame(surface, p + wreck_fall + Vector2(-5, 5), "damage_smoke", phase, 1.15, Color(0.64, 0.68, 0.67, 0.82))
	if ratio < 0.72:
		_draw_enemy_effect_frame(surface, p + wreck_fall + Vector2(5, 7), "damage_fire", phase + 1, 0.92, Color(1.0, 0.78, 0.46, 0.94))
	if ratio >= 0.18:
		var escape_ratio := clampf((ratio - 0.18) / 0.82, 0.0, 1.0)
		var capsule_center := p + Vector2(7.0 + sin(escape_ratio * 5.0) * 2.0, -10.0 - escape_ratio * 76.0)
		surface.draw_texture(VX94_ESCAPE_CAPSULE, (capsule_center - VX94_ESCAPE_CAPSULE.get_size() * 0.5).round())
		_draw_enemy_effect_frame(surface, capsule_center + Vector2(0, 9), "damage_sparks", phase, 0.46, Color(1.0, 0.88, 0.58, 0.82))

func _bank_frame_index() -> int:
	if _bank_visual < -0.78: return 0
	if _bank_visual < -0.22: return 1
	if _bank_visual > 0.78: return 4
	if _bank_visual > 0.22: return 3
	return 2

func _draw_enemy(surface: CanvasItem, enemy: Dictionary) -> void:
	var p: Vector2 = enemy.get("position", Vector2.ZERO)
	var enemy_id := str(enemy.get("id", ""))
	if float(enemy.get("hypersonic_ratio", 0.0)) > 0.01 and _draw_hypersonic_interceptor(surface, p, enemy_id, enemy):
		return
	var is_boss := bool(enemy.get("boss", false))
	var faction := str(enemy.get("faction", "mercenary"))
	var category := str(enemy.get("category", "air"))
	var scale := _surface_target_scale() if category in ["ground", "sea"] else 1.0
	if category in ["ground", "sea"] and scale < 0.25 and not is_boss:
		return
	if is_boss:
		if MERCENARY_BOSS_SPRITES.has(enemy_id):
			_draw_production_boss(surface, p, enemy_id, enemy, MERCENARY_BOSS_SPRITES[enemy_id])
		elif MACHINE_BOSS_SPRITES.has(enemy_id):
			_draw_production_boss(surface, p, enemy_id, enemy, MACHINE_BOSS_SPRITES[enemy_id])
		elif ORBITAL_BOSS_SPRITES.has(enemy_id):
			_draw_production_boss(surface, p, enemy_id, enemy, ORBITAL_BOSS_SPRITES[enemy_id])
		else:
			_report_missing_art(enemy_id)
	elif faction == "autonomous" and category == "ground" and LAYERED_MACHINE_GROUND_SPRITES.has(enemy_id):
		_draw_layered_ground(surface, p, enemy, LAYERED_MACHINE_GROUND_SPRITES[enemy_id], scale)
	elif faction == "autonomous" and category == "ground" and MACHINE_GROUND_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MACHINE_GROUND_SPRITES[enemy_id], scale)
	elif faction == "autonomous" and category == "ground" and MACHINE_MECH_SPRITES.has(enemy_id):
		_draw_animated_unit(surface, p, enemy_id, enemy, MACHINE_MECH_SPRITES[enemy_id], scale)
	elif faction == "autonomous" and ORBITAL_AIR_SPRITES.has(enemy_id):
		_draw_hostile_airframe(surface, p, enemy_id, enemy, ORBITAL_AIR_SPRITES[enemy_id])
	elif faction == "autonomous" and MACHINE_AIR_SPRITES.has(enemy_id):
		_draw_hostile_airframe(surface, p, enemy_id, enemy, MACHINE_AIR_SPRITES[enemy_id])
	elif faction == "autonomous":
		_report_missing_art(enemy_id)
	elif category == "ground" and LAYERED_GROUND_SPRITES.has(enemy_id):
		_draw_layered_ground(surface, p, enemy, LAYERED_GROUND_SPRITES[enemy_id], scale)
	elif category == "ground" and MERCENARY_GROUND_FORCE_SPRITES.has(enemy_id):
		if INFANTRY_LAYERED_ART.has(enemy_id):
			_draw_infantry_team(surface, p, enemy_id, enemy, scale * 1.18)
		else:
			var unit_scale := scale * (1.16 if enemy_id == "security_patrol_mech" else 1.0)
			_draw_animated_unit(surface, p, enemy_id, enemy, MERCENARY_GROUND_FORCE_SPRITES[enemy_id], unit_scale)
	elif category == "ground" and MERCENARY_GROUND_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MERCENARY_GROUND_SPRITES[enemy_id], scale)
	elif category == "ground":
		_report_missing_art(enemy_id)
	elif category == "sea" and MERCENARY_SEA_SPRITES.has(enemy_id):
		_draw_naval_unit(surface, p, enemy_id, enemy, MERCENARY_SEA_SPRITES[enemy_id], scale)
	elif category == "sea":
		_report_missing_art(enemy_id)
	elif MERCENARY_AIR_SPRITES.has(enemy_id):
		_draw_hostile_airframe(surface, p, enemy_id, enemy, MERCENARY_AIR_SPRITES[enemy_id])
	else:
		_report_missing_art(enemy_id)
	if category == "ground" and GROUND_FORCE_SPECIALIST_ART.has(enemy_id):
		var specialist_scale := scale * (1.16 if enemy_id == "security_patrol_mech" else 1.0)
		_render_ground_force_specialist(surface, p, enemy_id, enemy, specialist_scale)
	if not is_boss:
		_draw_enemy_damage_attachments(surface, p, enemy, category, faction, scale)

func _draw_hypersonic_interceptor(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> bool:
	var hull: Texture2D
	if MERCENARY_AIR_SPRITES.has(enemy_id): hull = MERCENARY_AIR_SPRITES[enemy_id]
	elif MACHINE_AIR_SPRITES.has(enemy_id): hull = MACHINE_AIR_SPRITES[enemy_id]
	elif ORBITAL_AIR_SPRITES.has(enemy_id): hull = ORBITAL_AIR_SPRITES[enemy_id]
	else: return false
	var ratio := roundf(clampf(float(enemy.get("hypersonic_ratio", 0.0)), 0.0, 1.0) * float(TRANSFORM_EXPOSURES - 1)) / float(TRANSFORM_EXPOSURES - 1)
	var width := hull.get_width() * lerpf(1.0, 0.62, ratio)
	var height := hull.get_height() * lerpf(1.0, 1.08, ratio)
	surface.draw_texture_rect(hull, Rect2((p - Vector2(width, height) * 0.5).round(), Vector2(width, height).round()), false)
	var plume := PersistentEffectArtLibrary.frame_for_clock("afterburner", 12.0)
	surface.draw_texture(plume, (p + Vector2(-plume.get_width() * 0.5, height * 0.30)).round(), Color(0.88,0.94,1.0,ratio))
	var boom_age := float(enemy.get("hypersonic_boom_age", 99.0))
	if boom_age < 0.42:
		var t := boom_age / 0.42
		var boom := PersistentEffectArtLibrary.frame_for_ratio("sonic_boom", t)
		var size := roundf(lerpf(36.0, 112.0, t))
		surface.draw_texture_rect(boom, Rect2((p-Vector2.ONE*size*0.5).round(),Vector2.ONE*size),false,Color(1,1,1,1.0-t))
	return true

static func has_production_art(enemy_id: String) -> bool:
	return MERCENARY_AIR_SPRITES.has(enemy_id) or MERCENARY_GROUND_SPRITES.has(enemy_id) or MERCENARY_GROUND_FORCE_SPRITES.has(enemy_id) or MERCENARY_SEA_SPRITES.has(enemy_id) or MACHINE_AIR_SPRITES.has(enemy_id) or MACHINE_GROUND_SPRITES.has(enemy_id) or MACHINE_MECH_SPRITES.has(enemy_id) or ORBITAL_AIR_SPRITES.has(enemy_id) or MERCENARY_BOSS_SPRITES.has(enemy_id) or MACHINE_BOSS_SPRITES.has(enemy_id) or ORBITAL_BOSS_SPRITES.has(enemy_id)

func _report_missing_art(enemy_id: String) -> void:
	if _missing_art_ids.has(enemy_id):
		return
	_missing_art_ids[enemy_id] = true
	push_error("Production enemy art is not registered: %s" % enemy_id)

func _draw_production_sprite(surface: CanvasItem, p: Vector2, texture: Texture2D, scale: float = 1.0) -> void:
	var size := texture.get_size() * scale
	var destination := Rect2((p - size * 0.5).round(), size.round())
	surface.draw_texture_rect(texture, destination, false)

func _draw_animated_unit(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, fallback: Texture2D, scale: float = 1.0) -> void:
	if not UNIT_ANIMATION_FRAMES.has(enemy_id):
		_draw_production_sprite(surface, p, fallback, scale)
		return
	var animation: Dictionary = UNIT_ANIMATION_FRAMES[enemy_id]
	var frames: Array = animation["frames"]
	var frame_index := int(floor(float(enemy.get("age", 0.0)) * float(animation["fps"]))) % frames.size()
	_draw_production_sprite(surface, p, frames[frame_index], scale)

func _draw_hostile_airframe(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, hull: Texture2D) -> void:
	if MACHINE_AIR_SPRITES.has(enemy_id):
		_render_machine_air_propulsion(surface, p, enemy_id, enemy)
	elif ORBITAL_AIR_SPRITES.has(enemy_id):
		_render_orbital_air_propulsion(surface, p, enemy_id, enemy)
	elif AIR_PROPULSION_STYLE.has(enemy_id) and not UNIT_ANIMATION_FRAMES.has(enemy_id):
		var family := str(AIR_PROPULSION_STYLE[enemy_id])
		var frames: Array = AIR_PROPULSION_FRAMES[family]
		var frame_index := int(floor(float(enemy.get("age", 0.0)) * 12.0)) % frames.size()
		var plume: Texture2D = frames[frame_index]
		var engine_anchor := p + Vector2(0.0, -hull.get_height() * 0.30)
		surface.draw_set_transform(engine_anchor.round(), PI, Vector2(0.58, 0.58))
		surface.draw_texture(plume, Vector2(-8.0, 0.0), Color(0.84, 0.90, 0.94, 0.82))
		surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var bank_index := hostile_bank_frame_index(float(enemy.get("visual_bank", 0.0)))
	if HOSTILE_BANK_FRAMES.has(enemy_id) and bank_index != 1:
		var bank_frames: Array = HOSTILE_BANK_FRAMES[enemy_id]
		_draw_production_sprite(surface, p, bank_frames[bank_index])
	else:
		_draw_animated_unit(surface, p, enemy_id, enemy, hull)
	if AIR_SPECIALIST_ART.has(enemy_id):
		_render_air_specialist(surface, p, enemy_id, enemy)
	if MACHINE_AIR_SPRITES.has(enemy_id):
		_render_machine_air_specialist(surface, p, enemy_id, enemy, bank_index)
	elif ORBITAL_AIR_SPRITES.has(enemy_id):
		_render_orbital_air_specialist(surface, p, enemy_id, enemy, bank_index)

static func hostile_bank_frame_index(bank: float) -> int:
	if bank < -0.24:
		return 0
	if bank > 0.24:
		return 2
	return 1

func _render_air_specialist(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	if not AIR_SPECIALIST_ART.has(enemy_id):
		return
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.10, 0.0, 1.0)
	if enemy_id == "gunship_mk1":
		var definition: Dictionary = AIR_SPECIALIST_ART[enemy_id]
		var anchor: Vector2 = p + Vector2(definition["anchor"])
		var direction := _player_position() - p
		var rotation := 0.0 if direction.length_squared() < 0.001 else clampf(Vector2.DOWN.angle_to(direction.normalized()), -0.78, 0.78)
		_draw_production_sprite(surface, anchor, definition["mount"])
		_render_air_component(surface, definition["turret"], anchor, rotation, Vector2(0.5,0.38))
		var barrel: Texture2D = definition["barrel_recoil"] if recoil_ratio > 0.01 else definition["barrel"]
		_render_air_component(surface, barrel, anchor, rotation, Vector2(0.5,0.12))
		_draw_production_sprite(surface, p + Vector2(0,-3), definition["sensor"])
		if recoil_ratio > 0.45:
			_render_air_muzzle(surface, anchor + Vector2.DOWN.rotated(rotation) * 17.0, recoil_ratio)
	elif enemy_id == "attack_chopper":
		var definition: Dictionary = AIR_SPECIALIST_ART[enemy_id]
		var rotor_frames: Array = definition["rotor"]
		var rotor: Texture2D = rotor_frames[int(floor(float(enemy.get("age",0.0))*12.0)) % rotor_frames.size()]
		_draw_production_sprite(surface, p+Vector2(0,-2), rotor)
		_draw_production_sprite(surface, p+Vector2(0,-2), definition["hub"])
		var anchor: Vector2 = p + Vector2(definition["anchor"])
		var direction := _player_position() - p
		var rotation := 0.0 if direction.length_squared() < 0.001 else clampf(Vector2.DOWN.angle_to(direction.normalized()), -0.48, 0.48)
		_render_air_component(surface, definition["turret"], anchor, rotation, Vector2(0.5,0.36))
		var barrel: Texture2D = definition["barrel_recoil"] if recoil_ratio > 0.01 else definition["barrel"]
		_render_air_component(surface, barrel, anchor, rotation, Vector2(0.5,0.12))
		if recoil_ratio > 0.45:
			_render_air_muzzle(surface, anchor + Vector2.DOWN.rotated(rotation) * 15.0, recoil_ratio)
	elif enemy_id == "heavy_bomber":
		var definition: Dictionary = AIR_SPECIALIST_ART[enemy_id]
		var bay_frames: Array = definition["bay"]
		var frame_index := heavy_bomber_bay_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_draw_production_sprite(surface, p + Vector2(definition["anchor"]), bay_frames[frame_index])

func _render_air_component(surface: CanvasItem, texture: Texture2D, world_pivot: Vector2, angle: float, normalized_pivot: Vector2) -> void:
	var local_pivot := texture.get_size() * normalized_pivot
	surface.draw_set_transform(world_pivot.round(), angle, Vector2.ONE)
	surface.draw_texture(texture, -local_pivot.round())
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _render_air_muzzle(surface: CanvasItem, center: Vector2, recoil_ratio: float) -> void:
	var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
	surface.draw_texture_rect(flash, Rect2((center-Vector2(4,4)).round(), Vector2(8,8)), false)

static func heavy_bomber_bay_frame_index(fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.01:
		return 3
	if fire_timer > 0.62:
		return 0
	if fire_timer > 0.30:
		return 1
	return 2

func _render_machine_air_specialist(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, bank_index: int) -> void:
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.10, 0.0, 1.0)
	var bank_scale := Vector2(0.82 if bank_index != 1 else 1.0, 1.0)
	if enemy_id == "drone_hunter":
		var definition: Dictionary = MACHINE_AIR_SPECIALIST_ART[enemy_id]
		var anchor: Vector2 = p + Vector2(definition["anchor"])
		var direction := _player_position() - p
		var rotation := 0.0 if direction.length_squared() < 0.001 else clampf(Vector2.DOWN.angle_to(direction.normalized()), -0.58, 0.58)
		_render_machine_component(surface, definition["mount"], anchor, 0.0, Vector2(0.5,0.42), bank_scale)
		var barrel: Texture2D = definition["barrel_recoil"] if recoil_ratio > 0.01 else definition["barrel"]
		_render_machine_component(surface, barrel, anchor + Vector2(-4,1), rotation, Vector2(0.5,0.10), bank_scale)
		_render_machine_component(surface, barrel, anchor + Vector2(4,1), rotation, Vector2(0.5,0.10), bank_scale)
		if recoil_ratio > 0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
			surface.draw_texture_rect(flash, Rect2((anchor + Vector2(-7, 11)).round(), Vector2(7,9)), false)
			surface.draw_texture_rect(flash, Rect2((anchor + Vector2(1, 11)).round(), Vector2(7,9)), false)
	elif enemy_id in ["drone_bomber", "drone_missile_node"]:
		var definition: Dictionary = MACHINE_AIR_SPECIALIST_ART[enemy_id]
		var door_frames: Array = definition["frames"]
		var door_index := machine_weapon_door_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_render_machine_component(surface, door_frames[door_index], p + Vector2(definition["anchor"]), 0.0, Vector2(0.5,0.5), bank_scale)
	_render_machine_component(surface, MACHINE_AIR_SPECIALIST_ART["collar"], p, 0.0, Vector2(0.5,0.5), bank_scale)
	var core_frames: Array = MACHINE_AIR_SPECIALIST_ART["core"]
	var pulse_cycle := [0, 1, 2, 1]
	var core_index: int = pulse_cycle[int(floor(float(enemy.get("age", 0.0)) * 6.0)) % pulse_cycle.size()]
	var max_hp := maxf(1.0, float(enemy.get("max_hp", enemy.get("hp", 1.0))))
	var core: Texture2D = MACHINE_AIR_SPECIALIST_ART["damaged_core"] if float(enemy.get("hp", max_hp)) / max_hp <= 0.45 else core_frames[core_index]
	_render_machine_component(surface, core, p, 0.0, Vector2(0.5,0.5), bank_scale)

func _render_machine_air_propulsion(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	var frames: Array = MACHINE_AIR_SPECIALIST_ART["propulsion"]
	var cycle := [0, 1, 2, 1]
	var frame_index: int = cycle[int(floor(float(enemy.get("age",0.0))*9.0)) % cycle.size()]
	var thruster: Texture2D = frames[frame_index]
	var anchor := p + Vector2(0, -12 if enemy_id != "drone_bomber" else -16)
	surface.draw_set_transform(anchor.round(), PI, Vector2(0.80,0.80))
	surface.draw_texture(thruster, -thruster.get_size()*0.5)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _render_machine_component(surface: CanvasItem, texture: Texture2D, world_pivot: Vector2, angle: float, normalized_pivot: Vector2, component_scale: Vector2) -> void:
	var local_pivot := texture.get_size() * normalized_pivot
	surface.draw_set_transform(world_pivot.round(), angle, component_scale)
	surface.draw_texture(texture, -local_pivot.round())
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func machine_weapon_door_frame_index(fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.01:
		return 3
	if fire_timer > 0.62:
		return 0
	if fire_timer > 0.30:
		return 1
	return 2

func _render_orbital_air_specialist(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, bank_index: int) -> void:
	if not ORBITAL_AIR_SPECIALIST_ART.has(enemy_id):
		return
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.10, 0.0, 1.0)
	var bank_scale := Vector2(0.82 if bank_index != 1 else 1.0, 1.0)
	var definition: Dictionary = ORBITAL_AIR_SPECIALIST_ART[enemy_id]
	if enemy_id == "exo_drone":
		var hot := fposmod(float(enemy.get("age",0.0)), 1.2) > 0.72
		var radiator: Texture2D = definition["radiator_hot"] if hot else definition["radiator_cool"]
		_render_machine_component(surface, radiator, p + Vector2(-7,1), 0.0, Vector2(0.5,0.5), bank_scale)
		_render_machine_component(surface, radiator, p + Vector2(7,1), 0.0, Vector2(0.5,0.5), bank_scale)
	elif enemy_id == "orbital_sentry":
		var anchor: Vector2 = p + Vector2(definition["anchor"])
		var direction := _player_position() - p
		var rotation := 0.0 if direction.length_squared() < 0.001 else clampf(Vector2.DOWN.angle_to(direction.normalized()), -0.82, 0.82)
		_render_machine_component(surface, definition["collar"], anchor, 0.0, Vector2(0.5,0.5), bank_scale)
		_render_machine_component(surface, definition["turret"], anchor, rotation, Vector2(0.5,0.45), bank_scale)
		var barrel: Texture2D = definition["barrel_recoil"] if recoil_ratio > 0.01 else definition["barrel"]
		_render_machine_component(surface, barrel, anchor, rotation, Vector2(0.5,0.10), bank_scale)
		if recoil_ratio > 0.45:
			_render_air_muzzle(surface, anchor + Vector2.DOWN.rotated(rotation)*18.0, recoil_ratio)
	elif enemy_id == "phase_interceptor":
		var phase_frames: Array = definition["frames"]
		var phase_cycle := [0, 1, 2, 1]
		var phase_index: int = phase_cycle[int(floor(float(enemy.get("age", 0.0)) * 7.0)) % phase_cycle.size()]
		var max_hp := maxf(1.0, float(enemy.get("max_hp", enemy.get("hp",1.0))))
		var nodes: Texture2D = definition["damaged"] if float(enemy.get("hp",max_hp))/max_hp <= 0.45 else phase_frames[phase_index]
		_render_machine_component(surface, nodes, p + Vector2(definition["anchor"]), 0.0, Vector2(0.5,0.5), bank_scale)
	elif enemy_id in ["beam_sentry", "orbital_lancer"]:
		var weapon_frames: Array = definition["frames"]
		var weapon_index := orbital_weapon_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_render_machine_component(surface, weapon_frames[weapon_index], p + Vector2(definition["anchor"]), 0.0, Vector2(0.5,0.5), bank_scale)
		if enemy_id == "orbital_lancer":
			_render_machine_component(surface, definition["capacitor"], p + Vector2(-9,0), 0.0, Vector2(0.5,0.5), bank_scale)
			_render_machine_component(surface, definition["capacitor"], p + Vector2(9,0), 0.0, Vector2(0.5,0.5), bank_scale)
	var max_hp := maxf(1.0, float(enemy.get("max_hp", enemy.get("hp",1.0))))
	if float(enemy.get("hp",max_hp))/max_hp <= 0.35:
		_render_machine_component(surface, ORBITAL_AIR_SPECIALIST_ART["fragment_small"], p + Vector2(7,-4), 0.0, Vector2(0.5,0.5), bank_scale)

func _render_orbital_air_propulsion(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	var frames: Array = ORBITAL_AIR_SPECIALIST_ART["propulsion"]
	var cycle := [0, 1, 2, 1]
	var frame_index: int = cycle[int(floor(float(enemy.get("age",0.0))*8.0)) % cycle.size()]
	var thruster: Texture2D = frames[frame_index]
	var anchors := {"exo_drone":-10.0, "orbital_sentry":-13.0, "phase_interceptor":-12.0, "beam_sentry":-15.0, "orbital_lancer":-22.0}
	var anchor := p + Vector2(0, float(anchors.get(enemy_id,-13.0)))
	surface.draw_set_transform(anchor.round(), PI, Vector2(0.78,0.78))
	surface.draw_texture(thruster, -thruster.get_size()*0.5)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func orbital_weapon_frame_index(fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.01:
		return 3
	if fire_timer > 0.62:
		return 0
	if fire_timer > 0.30:
		return 1
	return 2

func _render_ground_force_specialist(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, scale: float) -> void:
	var hit_ratio := clampf(float(enemy.get("hit_timer", 0.0)) / 0.14, 0.0, 1.0)
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.10, 0.0, 1.0)
	var definition: Dictionary = GROUND_FORCE_SPECIALIST_ART[enemy_id]
	if enemy_id in ["security_patrol_mech", "autonomous_salvage_mech"]:
		_render_mech_appendages(surface, p, enemy_id, enemy, definition, scale, recoil_ratio)
		return
	var weapon: Texture2D = definition["weapon"]
	var direction := _player_position() - p
	var rotation := 0.0 if direction.length_squared() < 0.001 else Vector2.DOWN.angle_to(direction.normalized())
	var component_scale := scale * float(definition.get("scale", 1.0))
	var local_recoil := Vector2(0.0, -roundf(recoil_ratio * 2.0))
	surface.draw_set_transform(p.round(), rotation, Vector2.ONE * component_scale)
	surface.draw_texture(weapon, -weapon.get_size() * 0.5 + local_recoil)
	if recoil_ratio > 0.45:
		var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
		surface.draw_texture_rect(flash, Rect2(-5, weapon.get_height() * 0.31, 10, 10), false)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hit_ratio > 0.01 and definition.has("scatter"):
		_draw_production_sprite(surface, p, definition["scatter"], scale)

func _draw_infantry_team(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, scale: float) -> void:
	var definition: Dictionary = INFANTRY_LAYERED_ART[enemy_id]
	var age := float(enemy.get("age", 0.0))
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.10, 0.0, 1.0)
	var hit_ratio := clampf(float(enemy.get("hit_timer", 0.0)) / 0.14, 0.0, 1.0)
	if enemy_id == "mercenary_rifle_team":
		var offsets := [Vector2(-9,-5), Vector2(8,-4), Vector2(-5,4), Vector2(6,5), Vector2(0,10)]
		var active_member := int(floor(age * 6.0)) % offsets.size()
		var advance_frames: Array = definition["advance"]
		for member_index in range(offsets.size()):
			var texture: Texture2D = advance_frames[(int(floor(age * 7.0))+member_index) % advance_frames.size()]
			if member_index == active_member and hit_ratio > 0.01:
				texture = definition["flinch"]
			elif member_index == active_member and recoil_ratio > 0.01:
				texture = definition["fire"]
			_draw_production_sprite(surface, p + offsets[member_index] * scale, texture, scale)
		if hit_ratio > 0.01:
			var dust_frames: Array = definition["dust"]
			_draw_infantry_effect(surface, p + offsets[active_member] * scale, dust_frames[int(hit_ratio > 0.52)], scale)
		if recoil_ratio > 0.45:
			_draw_infantry_muzzle(surface, p + (offsets[active_member]+Vector2(0,7)) * scale, recoil_ratio, scale)
		return
	_draw_production_sprite(surface, p + Vector2(-11,5) * scale, definition["crate"], scale)
	_draw_production_sprite(surface, p + Vector2(-5,3) * scale, definition["belt"], scale)
	_draw_production_sprite(surface, p + Vector2(-9,-4) * scale, definition["loader"], scale)
	_draw_production_sprite(surface, p + Vector2(9,-6) * scale, definition["spotter"], scale)
	var gunner: Texture2D = definition["gunner_fire"] if recoil_ratio > 0.01 else definition["gunner"]
	var tripod: Texture2D = definition["tripod_recoil"] if recoil_ratio > 0.01 else definition["tripod"]
	_draw_production_sprite(surface, p + Vector2(0,-3) * scale, gunner, scale)
	_draw_production_sprite(surface, p + Vector2(0,7) * scale, tripod, scale)
	if hit_ratio > 0.01:
		var heavy_dust_frames: Array = definition["dust"]
		var hit_offset := Vector2(-9,-4) if int(floor(age*5.0)) % 2 == 0 else Vector2(9,-6)
		_draw_production_sprite(surface, p + hit_offset * scale, definition["flinch"], scale)
		_draw_infantry_effect(surface, p + hit_offset * scale, heavy_dust_frames[int(hit_ratio > 0.52)], scale)
	if recoil_ratio > 0.45:
		_draw_infantry_muzzle(surface, p + Vector2(0,17) * scale, recoil_ratio, scale)

func _draw_infantry_effect(surface: CanvasItem, center: Vector2, texture: Texture2D, scale: float) -> void:
	var size := texture.get_size() * scale
	surface.draw_texture_rect(texture, Rect2((center-size*0.5).round(), size.round()), false, Color(0.54,0.50,0.43,0.68))

func _draw_infantry_muzzle(surface: CanvasItem, center: Vector2, recoil_ratio: float, scale: float) -> void:
	var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
	surface.draw_texture_rect(flash, Rect2((center-Vector2(2,2)*scale).round(), Vector2(4,4)*scale), false)

func _render_mech_appendages(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, definition: Dictionary, scale: float, recoil_ratio: float) -> void:
	var direction := _player_position() - p
	var aim_angle := 0.0 if direction.length_squared() < 0.001 else clampf(Vector2.DOWN.angle_to(direction.normalized()), -0.72, 0.72)
	var primary_anchor: Vector2 = p + Vector2(definition["primary_anchor"]) * scale
	var secondary_anchor: Vector2 = p + Vector2(definition["secondary_anchor"]) * scale
	var collar: Texture2D = definition["collar"]
	_draw_mech_component(surface, collar, primary_anchor, 0.0, scale, Vector2(0.5, 0.5))
	_draw_mech_component(surface, collar, secondary_anchor, 0.0, scale, Vector2(0.5, 0.5))
	if enemy_id == "security_patrol_mech":
		var cannon: Texture2D = definition["weapon_recoil"] if recoil_ratio > 0.01 else definition["weapon"]
		_draw_mech_component(surface, cannon, primary_anchor, aim_angle, scale, Vector2(0.5, 0.08))
		_draw_mech_component(surface, definition["shield"], secondary_anchor, aim_angle * 0.22, scale, Vector2(0.5, 0.08))
		if recoil_ratio > 0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
			var muzzle := primary_anchor + Vector2.DOWN.rotated(aim_angle) * 31.0 * scale
			surface.draw_texture_rect(flash, Rect2((muzzle-Vector2(4,4)*scale).round(), Vector2(8,8)*scale), false)
		return
	var cutter: Texture2D = definition["weapon"]
	var grapple: Texture2D = definition["grapple_closed"] if recoil_ratio > 0.01 else definition["grapple_open"]
	_draw_mech_component(surface, cutter, primary_anchor, aim_angle, scale, Vector2(0.5, 0.08))
	_draw_mech_component(surface, grapple, secondary_anchor, -aim_angle * 0.78, scale, Vector2(0.5, 0.08))
	var disc_frames: Array = definition["disc"]
	var disc: Texture2D = disc_frames[int(floor(float(enemy.get("age", 0.0)) * 9.0)) % disc_frames.size()]
	var disc_center := primary_anchor + Vector2.DOWN.rotated(aim_angle) * 28.0 * scale
	_draw_mech_component(surface, disc, disc_center, aim_angle, scale, Vector2(0.5, 0.5))

func _draw_mech_component(surface: CanvasItem, texture: Texture2D, world_pivot: Vector2, angle: float, scale: float, normalized_pivot: Vector2) -> void:
	var local_pivot := texture.get_size() * normalized_pivot
	surface.draw_set_transform(world_pivot.round(), angle, Vector2.ONE * scale)
	surface.draw_texture(texture, -local_pivot.round())
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_naval_unit(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, hull: Texture2D, scale: float) -> void:
	var frame_index := int(floor(float(enemy.get("age", 0.0)) * 8.0)) % NAVAL_WAKE_FRAMES.size()
	var wake: Texture2D = NAVAL_WAKE_FRAMES[frame_index]
	var wake_scale := scale * clampf(hull.get_width() / 40.0, 0.72, 1.15)
	var wake_size := wake.get_size() * wake_scale
	var wake_center := p + Vector2(0.0, -hull.get_height() * scale * 0.5 - wake_size.y * 0.42 + 4.0 * scale)
	var destination := Rect2((wake_center - wake_size * 0.5).round(), wake_size.round())
	surface.draw_texture_rect(wake, destination, false, Color(0.72, 0.82, 0.86, 0.68))
	_draw_production_sprite(surface, p, hull, scale)
	var specialist: Dictionary = NAVAL_SPECIALIST_ART.get(enemy_id, {})
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.12, 0.0, 1.0)
	if specialist.has("launcher"):
		var launcher_frames: Array = specialist["launcher"]
		var launcher_index := naval_launcher_frame_index(enemy_id, float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_draw_production_sprite(surface, p + Vector2(specialist.get("launcher_anchor", Vector2.ZERO)) * scale, launcher_frames[launcher_index], scale)
	if specialist.has("radar_pedestal"):
		var radar_anchor: Vector2 = p + Vector2(specialist["radar_anchor"]) * scale
		_draw_production_sprite(surface, radar_anchor, specialist["radar_pedestal"], scale)
		_draw_naval_component(surface, specialist["radar_array"], radar_anchor, float(enemy.get("age", 0.0)) * 2.8, scale, Vector2(0.5, 0.58))
	if not specialist.has("turret"):
		return
	var turret_value: Variant = specialist["turret"]
	var turret: Texture2D = turret_value[1] if turret_value is Array and recoil_ratio > 0.01 else (turret_value[0] if turret_value is Array else turret_value)
	var turret_anchor: Vector2 = p + Vector2(specialist.get("turret_anchor", Vector2.ZERO)) * scale
	if specialist.has("mount"):
		_draw_production_sprite(surface, turret_anchor, specialist["mount"], scale)
	var aim := _player_position() - p
	var rotation := 0.0 if aim.length_squared() < 0.001 else clampf(Vector2.DOWN.angle_to(aim.normalized()), -0.82, 0.82)
	var recoil_offset := Vector2.UP.rotated(rotation) * roundf(recoil_ratio * 2.0) * scale
	_draw_naval_component(surface, turret, turret_anchor + recoil_offset, rotation, scale, Vector2(0.5, 0.32))
	if recoil_ratio > 0.45:
		var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0 - recoil_ratio)
		var muzzle := turret_anchor + Vector2.DOWN.rotated(rotation) * turret.get_height() * 0.62 * scale
		surface.draw_texture_rect(flash, Rect2((muzzle-Vector2(4,4)*scale).round(), Vector2(8,8)*scale), false)

func _draw_naval_component(surface: CanvasItem, texture: Texture2D, world_pivot: Vector2, angle: float, scale: float, normalized_pivot: Vector2) -> void:
	var local_pivot := texture.get_size() * normalized_pivot
	surface.draw_set_transform(world_pivot.round(), angle, Vector2.ONE * scale)
	surface.draw_texture(texture, -local_pivot.round())
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func naval_launcher_frame_index(enemy_id: String, fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.35:
		return 3
	if fire_timer > 0.72:
		return 0
	if fire_timer > 0.36:
		return 1
	return 2

func _draw_enemy_damage_attachments(surface: CanvasItem, p: Vector2, enemy: Dictionary, category: String, faction: String, scale: float) -> void:
	var max_hp := maxf(1.0, float(enemy.get("max_hp", enemy.get("hp", 1))))
	var damage_ratio := 1.0 - clampf(float(enemy.get("hp", max_hp)) / max_hp, 0.0, 1.0)
	if damage_ratio < 0.35:
		return
	var effect_scale := maxf(0.58, scale * 0.72)
	var base_offset := Vector2(-4.0, -7.0)
	if category == "sea": base_offset = Vector2(5.0, -6.0)
	elif category == "ground": base_offset = Vector2(-3.0, 0.0)
	var phase := int(floor(float(enemy.get("age", 0.0)) * 9.0))
	var smoke_tint := Color(0.62, 0.68, 0.70, 0.76)
	if faction == "autonomous": smoke_tint = Color(0.54, 0.66, 0.72, 0.72)
	_draw_enemy_effect_frame(surface, p + base_offset * effect_scale, "damage_smoke", phase, effect_scale, smoke_tint)
	if damage_ratio >= 0.62:
		_draw_enemy_effect_frame(surface, p - base_offset * 0.35, "damage_sparks", phase + 1, effect_scale, Color(1.0, 0.90, 0.66, 0.92))
	if damage_ratio >= 0.82:
		_draw_enemy_effect_frame(surface, p + Vector2(3.0, 2.0) * effect_scale, "damage_fire", phase + 2, effect_scale, Color(0.92, 0.76, 0.52, 0.88))

func _draw_enemy_effect_frame(surface: CanvasItem, center: Vector2, family: String, phase: int, scale: float, modulate: Color) -> void:
	var frames: Array = PersistentEffectArtLibrary.FRAMES[family]
	var texture: Texture2D = frames[posmod(phase, frames.size())]
	var size := texture.get_size() * scale
	surface.draw_texture_rect(texture, Rect2((center - size * 0.5).round(), size.round()), false, modulate)

func _draw_production_boss(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, texture: Texture2D) -> void:
	_draw_mercenary_boss_entrance(surface, p, enemy_id, enemy, texture)
	_draw_orbital_boss_field(surface,p,enemy_id,enemy)
	_draw_production_sprite(surface, p, texture)
	_draw_machine_boss_mechanics(surface,p,enemy_id,enemy)
	_draw_orbital_boss_mechanics(surface,p,enemy_id,enemy)
	if not BOSS_PHASE_OVERLAYS.has(enemy_id):
		return
	var overlays: Dictionary = BOSS_PHASE_OVERLAYS[enemy_id]
	var boss_phase := clampi(int(enemy.get("boss_phase", 1)), 1, 3)
	if boss_phase >= 2:
		_draw_production_sprite(surface, p, overlays["phase_2"])
	if boss_phase >= 3:
		_draw_production_sprite(surface, p, overlays["phase_3"])
		var critical_frames: Array = overlays["critical"]
		var frame_index := int(floor(float(enemy.get("age", 0.0)) * 8.0)) % critical_frames.size()
		_draw_production_sprite(surface, p, critical_frames[frame_index])
	_draw_mercenary_boss_mechanics(surface, p, enemy_id, enemy)

func _draw_machine_boss_mechanics(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	if not MACHINE_BOSS_SPECIALIST_ART.has(enemy_id):
		return
	var definition: Dictionary = MACHINE_BOSS_SPECIALIST_ART[enemy_id]
	var age := float(enemy.get("age",0.0))
	var cycle_frame := machine_boss_cycle_frame_index(age)
	var recoil_ratio := clampf(float(enemy.get("recoil_timer",0.0))/0.10,0.0,1.0)
	var fire_timer := float(enemy.get("fire_timer",1.0))
	var boss_phase := clampi(int(enemy.get("boss_phase",1)),1,3)
	var max_hp := maxf(1.0,float(enemy.get("max_hp",enemy.get("hp",1.0))))
	var health_ratio := clampf(float(enemy.get("hp",max_hp))/max_hp,0.0,1.0)
	if enemy_id == "swarm_controller":
		var rack_index := machine_swarm_rack_frame_index(fire_timer,recoil_ratio)
		var rack: Texture2D = definition["racks"][rack_index]
		var rack_center := p+Vector2(definition["rack_anchor"])
		surface.draw_texture(rack,(rack_center-rack.get_size()*0.5).round())
		var sensor: Texture2D = definition["sensor_damaged"] if health_ratio<=0.35 else definition["sensor"]
		var sensor_center := p+Vector2(definition["sensor_anchor"])
		surface.draw_set_transform(sensor_center.round(),sin(age*1.9)*0.17,Vector2.ONE)
		surface.draw_texture(sensor,-sensor.get_size()*0.5)
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		var core_index := 2 if health_ratio<=0.28 else (1 if boss_phase>=3 else 0)
		var core: Texture2D = definition["cores"][core_index]
		surface.draw_texture(core,(p-core.get_size()*0.5).round(),Color(1,1,1,0.94))
		var cradle_offsets := [Vector2(-10,-8),Vector2(10,-8),Vector2(-10,8),Vector2(10,8)]
		for index in range(cradle_offsets.size()):
			var drone_center: Vector2 = rack_center+Vector2(cradle_offsets[index])
			var drone_alpha := 1.0
			var drone: Texture2D = definition["drones"][1 if rack_index>=1 else 0]
			if recoil_ratio > 0.01:
				var launch_progress := 1.0-recoil_ratio
				var direction := Vector2(-0.55 if index%2==0 else 0.55,1.0).normalized()
				drone_center += direction*launch_progress*24.0
				drone_alpha = 1.0-smoothstep(0.65,1.0,launch_progress)
			elif fire_timer<0.35:
				drone_center += Vector2(0,2)
			surface.draw_texture(drone,(drone_center-drone.get_size()*0.5).round(),Color(1,1,1,drone_alpha))
		return
	var conveyor: Texture2D = definition["conveyors"][1 if health_ratio<=0.32 else 0]
	var conveyor_center := p+Vector2(-34,0)
	surface.draw_texture(conveyor,(conveyor_center-conveyor.get_size()*0.5).round())
	var conveyor_shift: float = [0.0,2.0,5.0,2.0][cycle_frame]
	for blank_index in range(3):
		var blank: Texture2D = definition["blanks"][blank_index]
		var blank_y: float = [-21.0,-2.0,17.0][blank_index]
		var blank_center := conveyor_center+Vector2(0,blank_y+conveyor_shift)
		surface.draw_texture(blank,(blank_center-blank.get_size()*0.5).round())
	var press_index := 2 if health_ratio<=0.42 else (1 if cycle_frame==2 else 0)
	var press: Texture2D = definition["presses"][press_index]
	var press_travel: float = [0.0,2.0,8.0,3.0][cycle_frame]
	var press_center := p+Vector2(0,-8+press_travel)
	surface.draw_texture(press,(press_center-press.get_size()*0.5).round())
	var arm_index := 2 if health_ratio<=0.24 else (1 if cycle_frame in [1,2] else 0)
	var arm: Texture2D = definition["arms"][arm_index]
	var arm_center := p+Vector2(31,-7+float([0,2,5,2][cycle_frame]))
	var arm_angle: float = [-0.10,0.02,0.12,0.02][cycle_frame]
	surface.draw_set_transform(arm_center.round(),arm_angle,Vector2.ONE)
	surface.draw_texture(arm,-arm.get_size()*0.5)
	surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	var tool: Texture2D = definition["tool"]
	var tool_center := arm_center+Vector2(0,14)
	surface.draw_set_transform(tool_center.round(),age*1.8,Vector2.ONE)
	surface.draw_texture(tool,-tool.get_size()*0.5)
	surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	var crucible: Texture2D = definition["crucibles"][1 if boss_phase>=2 and cycle_frame>=2 else 0]
	var crucible_center := p+Vector2(25,31)
	surface.draw_texture(crucible,(crucible_center-crucible.get_size()*0.5).round())
	if cycle_frame==2 and recoil_ratio>0.15:
		_draw_enemy_effect_frame(surface,tool_center+Vector2(-3,13),"damage_sparks",int(age*12.0),0.55,Color(0.88,0.68,0.40,0.78))

static func machine_swarm_rack_frame_index(fire_timer: float,recoil_ratio: float) -> int:
	if recoil_ratio>0.01 or fire_timer<0.28:
		return 2
	if fire_timer<0.62:
		return 1
	return 0

static func machine_boss_cycle_frame_index(age: float) -> int:
	return posmod(int(floor(age*4.0)),4)

func _draw_orbital_boss_field(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	if enemy_id!="phase_control_array":
		return
	var frame_index := phase_field_cycle_index(float(enemy.get("age",0.0)),int(enemy.get("boss_phase",1)))
	var frame: Texture2D = PHASE_FIELD_FRAMES[frame_index]
	var phase_strength := 0.58+0.09*clampi(int(enemy.get("boss_phase",1)),1,3)
	surface.draw_texture(frame,(p-frame.get_size()*0.5).round(),Color(0.78,0.88,0.88,phase_strength))

func _draw_orbital_boss_mechanics(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	if not ORBITAL_BOSS_SPECIALIST_ART.has(enemy_id):
		return
	var definition: Dictionary = ORBITAL_BOSS_SPECIALIST_ART[enemy_id]
	var age := float(enemy.get("age",0.0))
	var boss_phase := clampi(int(enemy.get("boss_phase",1)),1,3)
	var max_hp := maxf(1.0,float(enemy.get("max_hp",enemy.get("hp",1.0))))
	var health_ratio := clampf(float(enemy.get("hp",max_hp))/max_hp,0.0,1.0)
	var fire_timer := float(enemy.get("fire_timer",1.0))
	var aim := _player_position()-p
	var rotation := 0.0 if aim.length_squared()<0.001 else Vector2.DOWN.angle_to(aim.normalized())
	var recoil_ratio := clampf(float(enemy.get("recoil_timer",0.0))/0.10,0.0,1.0)
	if enemy_id=="orbital_command_node":
		var dish: Texture2D = definition["dish"]
		var dish_center := p+Vector2(-30,-25)
		surface.draw_set_transform(dish_center.round(),sin(age*1.7)*0.20,Vector2.ONE)
		surface.draw_texture(dish,-dish.get_size()*0.5)
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		var mast: Texture2D = definition["masts"][1 if boss_phase>=2 else 0]
		surface.draw_texture(mast,(p+Vector2(27,-24)-mast.get_size()*0.5).round())
		var core_index := 2 if health_ratio<=0.28 else (1 if boss_phase>=3 else 0)
		var core: Texture2D = definition["cores"][core_index]
		surface.draw_texture(core,(p-core.get_size()*0.5).round())
		_draw_orbital_tracking_hardware(surface,p,definition,rotation,recoil_ratio)
		return
	if enemy_id=="phase_control_array":
		var lens_index := orbital_mechanism_frame_index(age,boss_phase)
		var lens: Texture2D = definition["lenses"][lens_index]
		surface.draw_texture(lens,(p-lens.get_size()*0.5).round(),Color(1,1,1,0.92))
		var shutter: Texture2D = definition["shutters"][1 if lens_index>=1 else 0]
		for shutter_x in [-28.0,28.0]:
			surface.draw_texture(shutter,(p+Vector2(shutter_x,18)-shutter.get_size()*0.5).round())
		var projector: Texture2D = definition["projectors"][1 if health_ratio<=0.34 else 0]
		for anchor_value in definition["anchors"]:
			var anchor := p+Vector2(anchor_value)
			surface.draw_set_transform(anchor.round(),rotation,Vector2.ONE)
			surface.draw_texture(projector,-projector.get_size()*0.5+Vector2(0,-roundf(recoil_ratio*2.0)))
			surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		return
	if enemy_id=="station_warden":
		var clamp_index := 2 if health_ratio<=0.28 else (1 if fire_timer<0.55 else 0)
		var clamp_part: Texture2D = definition["clamps"][clamp_index]
		for clamp_x in [-40.0,40.0]:
			surface.draw_texture(clamp_part,(p+Vector2(clamp_x,28)-clamp_part.get_size()*0.5).round())
		var vent: Texture2D = definition["vents"][1 if boss_phase>=2 else 0]
		for vent_x in [-24.0,24.0]:
			surface.draw_texture(vent,(p+Vector2(vent_x,-28)-vent.get_size()*0.5).round())
		var point_turret: Texture2D = definition["point_turret"]
		surface.draw_texture(point_turret,(p+Vector2(0,12)-point_turret.get_size()*0.5).round())
		if health_ratio<=0.46:
			var damage: Texture2D = definition["damage"]
			surface.draw_texture(damage,(p+Vector2(0,-8)-damage.get_size()*0.5).round())
		_draw_orbital_tracking_hardware(surface,p,definition,rotation,recoil_ratio)
		return
	var aperture_index := 2 if recoil_ratio>0.01 or fire_timer<0.30 else (1 if fire_timer<0.62 else 0)
	var aperture: Texture2D = definition["apertures"][aperture_index]
	surface.draw_texture(aperture,(p-aperture.get_size()*0.5).round())
	var core_index := 2 if health_ratio<=0.27 else (1 if boss_phase>=3 else 0)
	var ark_core: Texture2D = definition["cores"][core_index]
	surface.draw_texture(ark_core,(p+Vector2(0,-30)-ark_core.get_size()*0.5).round())
	var arc_index := 2 if health_ratio<=0.30 else (1 if aperture_index>=1 else 0)
	var arc: Texture2D = definition["arcs"][arc_index]
	for anchor_value in definition["anchors"]:
		var arc_center := p+Vector2(anchor_value)
		surface.draw_texture(arc,(arc_center-arc.get_size()*0.5).round())
	var pylon: Texture2D = definition["pylon"]
	surface.draw_set_transform((p+Vector2(0,35)).round(),rotation,Vector2.ONE)
	surface.draw_texture(pylon,-pylon.get_size()*0.5+Vector2(0,-roundf(recoil_ratio*3.0)))
	surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	if health_ratio<=0.50:
		var plate: Texture2D = definition["damage"]
		surface.draw_texture(plate,(p+Vector2(26,22)-plate.get_size()*0.5).round())

func _draw_orbital_tracking_hardware(surface: CanvasItem,p: Vector2,definition: Dictionary,rotation: float,recoil_ratio: float) -> void:
	var mount: Texture2D = definition["mount"]
	var weapon: Texture2D = definition["weapon_recoil"] if recoil_ratio>0.01 else definition["weapon"]
	for anchor_value in definition["anchors"]:
		var anchor := p+Vector2(anchor_value)
		surface.draw_texture(mount,(anchor-mount.get_size()*0.5).round())
		surface.draw_set_transform(anchor.round(),rotation,Vector2.ONE)
		surface.draw_texture(weapon,-weapon.get_size()*0.5+Vector2(0,-roundf(recoil_ratio*3.0)))
		if recoil_ratio>0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle",1.0-recoil_ratio)
			surface.draw_texture_rect(flash,Rect2(-5,weapon.get_height()*0.35,10,10),false,Color(0.76,0.86,0.86,0.86))
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

static func orbital_mechanism_frame_index(age: float,boss_phase: int) -> int:
	return posmod(int(floor(age*float(2+clampi(boss_phase,1,3)))),4)

static func phase_field_cycle_index(age: float, boss_phase: int) -> int:
	return posmod(int(floor(age*float(2+clampi(boss_phase,1,3)))),4)

func _draw_mercenary_boss_entrance(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary, hull: Texture2D) -> void:
	if not MERCENARY_BOSS_SPECIALIST_ART.has(enemy_id):
		return
	var entrance_ratio := clampf(float(enemy.get("age", 0.0)) / 1.45, 0.0, 1.0)
	if entrance_ratio >= 1.0:
		return
	var phase := int(floor(float(enemy.get("age", 0.0)) * 8.0))
	if enemy_id == "gunship_alpha":
		for offset in [Vector2(-28,-30), Vector2(28,-30)]:
			_draw_enemy_effect_frame(surface, p + offset, "damage_fire", phase, 0.72, Color(0.76,0.78,0.68,0.72*(1.0-entrance_ratio*0.45)))
	elif enemy_id == "armoured_train":
		for offset in [Vector2(-12,-hull.get_height()*0.46), Vector2(13,-hull.get_height()*0.46)]:
			var dust := ImpactArtLibrary.frame_for_ratio("dust_impact", fmod(float(phase) * 0.19, 0.999))
			surface.draw_texture_rect(dust, Rect2((p + offset - Vector2(12,12)).round(), Vector2(24,24)), false, Color(0.62,0.58,0.50,0.58*(1.0-entrance_ratio*0.55)))
	elif enemy_id == "missile_cruiser":
		var wake: Texture2D = NAVAL_WAKE_FRAMES[posmod(phase, NAVAL_WAKE_FRAMES.size())]
		var wake_center := p + Vector2(0,-hull.get_height()*0.52)
		surface.draw_texture_rect(wake, Rect2((wake_center-Vector2(24,28)).round(),Vector2(48,56)),false,Color(0.76,0.86,0.88,0.72))

func _draw_mercenary_boss_mechanics(surface: CanvasItem, p: Vector2, enemy_id: String, enemy: Dictionary) -> void:
	if not MERCENARY_BOSS_SPECIALIST_ART.has(enemy_id):
		return
	var definition: Dictionary = MERCENARY_BOSS_SPECIALIST_ART[enemy_id]
	var recoil_ratio := clampf(float(enemy.get("recoil_timer",0.0))/0.10,0.0,1.0)
	var age := float(enemy.get("age",0.0))
	var boss_phase := clampi(int(enemy.get("boss_phase",1)),1,3)
	var max_hp := maxf(1.0,float(enemy.get("max_hp",enemy.get("hp",1.0))))
	var health_ratio := clampf(float(enemy.get("hp",max_hp))/max_hp,0.0,1.0)
	var aim := _player_position()-p
	var rotation := 0.0 if aim.length_squared()<0.001 else Vector2.DOWN.angle_to(aim.normalized())
	if enemy_id == "gunship_alpha":
		var engine_index := 2 if health_ratio <= 0.35 else (1 if boss_phase >= 2 or float(enemy.get("fire_timer",1.0)) < 0.38 else 0)
		var engine: Texture2D = definition["engines"][engine_index]
		for engine_anchor in definition["engine_anchors"]:
			var engine_center := p+Vector2(engine_anchor)+Vector2(0,roundf(sin(age*11.0)*0.8))
			surface.draw_texture(engine,(engine_center-engine.get_size()*0.5).round())
		if health_ratio <= 0.55:
			var cracked_plate: Texture2D = definition["damage"]
			surface.draw_texture(cracked_plate,(p+Vector2(0,13)-cracked_plate.get_size()*0.5).round())
	elif enemy_id == "armoured_train":
		var vent: Texture2D = definition["vents"][1 if boss_phase >= 2 or fposmod(age,1.4)<0.52 else 0]
		for vent_anchor in definition["vent_anchors"]:
			surface.draw_texture(vent,(p+Vector2(vent_anchor)-vent.get_size()*0.5).round())
		for index in range(definition["bogie_anchors"].size()):
			var damaged_bogie := health_ratio <= 0.42 and index == posmod(int(floor(age*0.4)),2)
			var bogie: Texture2D = definition["bogies"][1 if damaged_bogie else 0]
			var bogie_center := p+Vector2(definition["bogie_anchors"][index])
			surface.draw_texture(bogie,(bogie_center-bogie.get_size()*0.5).round())
	if definition.has("hatches"):
		var hatches: Array = definition["hatches"]
		var hatch_index := boss_hatch_frame_index(float(enemy.get("fire_timer",1.0)),recoil_ratio)
		for hatch_i in range(definition["hatch_anchors"].size()):
			var hatch_anchor = definition["hatch_anchors"][hatch_i]
			var hatch: Texture2D = hatches[hatch_index]
			surface.draw_texture(hatch,(p+Vector2(hatch_anchor)-hatch.get_size()*0.5).round())
			if hatch_index > 0:
				var door: Texture2D = definition["doors"][hatch_i]
				var door_center := p+Vector2(hatch_anchor)+Vector2(-13 if hatch_i==0 else 13,-2)
				surface.draw_texture(door,(door_center-door.get_size()*0.5).round())
		if health_ratio <= 0.58:
			var scorched: Texture2D = definition["damage"][1]
			surface.draw_texture(scorched,(p+Vector2(0,22)-scorched.get_size()*0.5).round())
		if health_ratio <= 0.35:
			var radar: Texture2D = definition["damage"][0]
			surface.draw_texture(radar,(p+Vector2(0,-5)-radar.get_size()*0.5).round())
	for anchor_value in definition["anchors"]:
		var anchor := p + Vector2(anchor_value)
		var mount: Texture2D = definition["mount"]
		surface.draw_texture(mount,(anchor-mount.get_size()*0.5).round())
		var turret: Texture2D = definition["turret_damaged"] if enemy_id == "armoured_train" and health_ratio <= 0.35 else definition["turret"]
		var barrel: Texture2D = definition["barrel_recoil"] if recoil_ratio > 0.01 else definition["barrel"]
		if definition.has("barrel_hot") and boss_phase >= 3 and recoil_ratio <= 0.01:
			barrel = definition["barrel_hot"]
		surface.draw_set_transform(anchor.round(),rotation,Vector2.ONE)
		surface.draw_texture(turret,-turret.get_size()*0.5)
		var barrel_center := Vector2(0,roundf(turret.get_height()*0.28)-roundf(recoil_ratio*3.0))
		surface.draw_texture(barrel,barrel_center-barrel.get_size()*0.5)
		if recoil_ratio > 0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle",1.0-recoil_ratio)
			surface.draw_texture_rect(flash,Rect2(-5,barrel_center.y+barrel.get_height()*0.42,10,10),false)
		surface.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

static func boss_hatch_frame_index(fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.35:
		return 3
	if fire_timer > 0.72:
		return 0
	if fire_timer > 0.40:
		return 1
	return 2

func _draw_layered_ground(surface: CanvasItem, p: Vector2, enemy: Dictionary, layers: Dictionary, scale: float) -> void:
	var base: Texture2D = layers.get("base")
	if layers.has("locomotion"):
		var locomotion: Array = layers["locomotion"]
		base = locomotion[posmod(int(floor(float(enemy.get("age", 0.0)) * 8.0)), locomotion.size())]
	var weapon: Texture2D = layers.get("weapon")
	var barrel: Texture2D = layers.get("barrel", null)
	_draw_production_sprite(surface, p, base, scale)
	var max_hp := maxf(1.0, float(enemy.get("max_hp", enemy.get("hp", 1))))
	if float(enemy.get("hp", max_hp)) / max_hp <= 0.55 and layers.has("damage"):
		_draw_production_sprite(surface, p, layers["damage"], scale)
	var direction := _player_position() - p
	var rotation := 0.0 if direction.length_squared() < 0.001 else Vector2.DOWN.angle_to(direction.normalized())
	var recoil_ratio := clampf(float(enemy.get("recoil_timer", 0.0)) / 0.10, 0.0, 1.0)
	var sam_frame := -1
	if layers.has("weapon_animation"):
		sam_frame = sam_launcher_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		var weapon_animation: Array = layers["weapon_animation"]
		weapon = weapon_animation[sam_frame]
	var local_recoil := Vector2(0.0, -roundf(2.0 * recoil_ratio))
	var pulse := 1.0
	if bool(layers.get("core_pulse", false)):
		pulse = 0.88 + 0.12 * (0.5 + 0.5 * sin(float(enemy.get("age", 0.0)) * 6.0))
	var weapon_scale := float(layers.get("weapon_scale", 1.0))
	surface.draw_set_transform(p.round(), rotation, Vector2.ONE * scale * weapon_scale)
	surface.draw_texture(weapon, -weapon.get_size() * 0.5 + local_recoil, Color(pulse, pulse, 1.0, 1.0))
	if barrel != null:
		surface.draw_texture(barrel, -barrel.get_size() * 0.5 + local_recoil)
	if sam_frame == 3:
		var ignition := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
		surface.draw_texture_rect(ignition, Rect2(-8, 9, 7, 11), false, Color(1.0, 0.84, 0.52, 0.96))
		surface.draw_texture_rect(ignition, Rect2(1, 9, 7, 11), false, Color(1.0, 0.84, 0.52, 0.96))
	elif recoil_ratio > 0.45:
		var muzzle := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
		surface.draw_texture_rect(muzzle, Rect2(-6, 10, 12, 12), false)
	surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func sam_launcher_frame_index(fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.01:
		return 3
	if fire_timer > 0.62:
		return 0
	if fire_timer > 0.30:
		return 1
	return 2

func _player_position() -> Vector2:
	var scene := get_tree().current_scene
	if SceneContractCache.has_property(scene, "player_position"):
		return scene.get("player_position")
	return Vector2(320, 292)

func _surface_target_scale() -> float:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null:
		if director.has_method("altitude_transition_active") and bool(director.call("altitude_transition_active")):
			return AltitudeRules.transition_ground_scale(str(director.call("altitude_transition_from")), str(director.call("altitude_transition_to")), float(director.call("altitude_transition_ratio")))
		if director.has_method("current_altitude"):
			return AltitudeRules.ground_scale(str(director.call("current_altitude")))
	return AltitudeRules.ground_scale(AltitudeRules.MID)

func _altitude_pitch_offset() -> Vector2:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director == null or not director.has_method("altitude_transition_active") or not bool(director.call("altitude_transition_active")):
		return Vector2.ZERO
	var ratio := float(director.call("altitude_transition_ratio"))
	var direction := int(director.call("altitude_transition_direction"))
	return Vector2(0, -roundf(sin(ratio * PI) * 4.0 * float(direction)))

func _craft_form() -> String:
	var director := get_node_or_null("/root/CraftFormDirector")
	if director != null and director.has_method("current_form"):
		return str(director.call("current_form"))
	return "fighter"
