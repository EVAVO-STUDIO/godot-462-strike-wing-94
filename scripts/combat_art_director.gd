extends CanvasLayer

const CombatArtSurface = preload("res://scripts/combat_art_surface.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const PersistentEffectArtLibrary = preload("res://scripts/persistent_effect_art_library.gd")
const ImpactArtLibrary = preload("res://scripts/impact_art_library.gd")
const VX94_GAMEPLAY_FORMS := [
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_fighter_v1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_transform_01.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_transform_02.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_transform_03.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/vx94_bomber_v1.png"),
]
const VX94_FIGHTER_BANK := [
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_left.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_neutral.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/fighter_right.png"),
]
const VX94_BOMBER_BANK := [
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_left.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_neutral.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/bank/bomber_right.png"),
]
const VX94_EXHAUST := [
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_0.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_2.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/exhaust_3.png"),
]
const VX94_DAMAGE := [
	preload("res://assets/runtime/craft/vx94/gameplay/fx/damage_1.png"),
	preload("res://assets/runtime/craft/vx94/gameplay/fx/damage_2.png"),
]
const VX94_GAMEPLAY_ANCHOR := Vector2(24, 29)
const MERCENARY_AIR_SPRITES := {
	"scout_falcon": preload("res://assets/runtime/enemies/mercenary_air/scout_falcon_idle.png"),
	"gunship_mk1": preload("res://assets/runtime/enemies/mercenary_air/gunship_mk1_idle.png"),
	"attack_chopper": preload("res://assets/runtime/enemies/mercenary_air/attack_chopper_idle.png"),
	"ace_interceptor": preload("res://assets/runtime/enemies/mercenary_air/ace_interceptor_idle.png"),
	"heavy_bomber": preload("res://assets/runtime/enemies/mercenary_air/heavy_bomber_idle.png"),
}
const UNIT_ANIMATION_FRAMES := {
	"attack_chopper": {"fps": 12.0, "frames": [
		preload("res://assets/runtime/enemies/unit_animation/attack_chopper/rotor_0.png"),
		preload("res://assets/runtime/enemies/unit_animation/attack_chopper/rotor_1.png"),
		preload("res://assets/runtime/enemies/unit_animation/attack_chopper/rotor_2.png"),
		preload("res://assets/runtime/enemies/unit_animation/attack_chopper/rotor_3.png"),
	]},
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
	"gunship_mk1": preload("res://assets/runtime/enemies/air_specialist/gunship_turret.png"),
	"attack_chopper": preload("res://assets/runtime/enemies/air_specialist/chopper_cannon.png"),
	"heavy_bomber": [
		preload("res://assets/runtime/enemies/air_specialist/heavy_bomber_bay_closed.png"),
		preload("res://assets/runtime/enemies/air_specialist/heavy_bomber_bay_opening.png"),
		preload("res://assets/runtime/enemies/air_specialist/heavy_bomber_bay_open.png"),
		preload("res://assets/runtime/enemies/air_specialist/heavy_bomber_bay_fire.png"),
	],
}
const MACHINE_AIR_SPECIALIST_ART := {
	"core": [
		preload("res://assets/runtime/enemies/machine_air_specialist/core_0.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/core_1.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/core_2.png"),
	],
	"drone_hunter": preload("res://assets/runtime/enemies/machine_air_specialist/hunter_weapon.png"),
	"drone_bomber": [
		preload("res://assets/runtime/enemies/machine_air_specialist/bomber_bay_closed.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/bomber_bay_opening.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/bomber_bay_open.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/bomber_bay_fire.png"),
	],
	"drone_missile_node": [
		preload("res://assets/runtime/enemies/machine_air_specialist/missile_hatch_closed.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/missile_hatch_opening.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/missile_hatch_open.png"),
		preload("res://assets/runtime/enemies/machine_air_specialist/missile_hatch_fire.png"),
	],
}
const ORBITAL_AIR_SPECIALIST_ART := {
	"orbital_sentry": preload("res://assets/runtime/enemies/orbital_air_specialist/sentry_turret.png"),
	"phase_interceptor": [
		preload("res://assets/runtime/enemies/orbital_air_specialist/phase_nodes_0.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/phase_nodes_1.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/phase_nodes_2.png"),
	],
	"beam_sentry": [
		preload("res://assets/runtime/enemies/orbital_air_specialist/beam_aperture_closed.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/beam_aperture_opening.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/beam_aperture_open.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/beam_aperture_fire.png"),
	],
	"orbital_lancer": [
		preload("res://assets/runtime/enemies/orbital_air_specialist/rail_charge_0.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/rail_charge_1.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/rail_charge_2.png"),
		preload("res://assets/runtime/enemies/orbital_air_specialist/rail_charge_fire.png"),
	],
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
		"base": preload("res://assets/runtime/enemies/mercenary_ground/light_tank_idle.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/light_tank_weapon.png"),
		"weapon_scale": 0.82,
	},
	"sam_truck": {
		"base": preload("res://assets/runtime/enemies/mercenary_ground/sam_truck_idle.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/sam_truck_weapon.png"),
		"weapon_animation": [
			preload("res://assets/runtime/enemies/mercenary_ground_layered/sam_truck_weapon_stowed.png"),
			preload("res://assets/runtime/enemies/mercenary_ground_layered/sam_truck_weapon_rising.png"),
			preload("res://assets/runtime/enemies/mercenary_ground_layered/sam_truck_weapon.png"),
			preload("res://assets/runtime/enemies/mercenary_ground_layered/sam_truck_weapon_launch.png"),
		],
		"weapon_scale": 0.82,
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
		"base": preload("res://assets/runtime/enemies/mercenary_ground/armoured_aa_carrier_idle.png"),
		"weapon": preload("res://assets/runtime/enemies/mercenary_ground_layered/aa_carrier_weapon.png"),
		"weapon_scale": 0.82,
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
const ORBITAL_BOSS_SPRITES := {
	"orbital_command_node": preload("res://assets/runtime/enemies/orbital_boss/orbital_command_node_idle_v2.png"),
	"phase_control_array": preload("res://assets/runtime/enemies/orbital_boss/phase_control_array_idle_v2.png"),
	"station_warden": preload("res://assets/runtime/enemies/orbital_boss/station_warden_idle.png"),
	"machine_ark": preload("res://assets/runtime/enemies/orbital_boss/machine_ark_idle.png"),
}

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
const TRANSFORM_VISUAL_SECONDS := 0.42

var _surface: Control
var _visual_sweep := 0.0
var _bank_visual := 0.0
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
	_visual_sweep = move_toward(_visual_sweep, target, maxf(0.0, delta) / TRANSFORM_VISUAL_SECONDS)
	_bank_visual = move_toward(_bank_visual, Input.get_axis("move_left", "move_right"), maxf(0.0, delta) * 5.5)
	if _surface != null:
		_surface.queue_redraw()

func _draw_combat_art(surface: CanvasItem) -> void:
	var scene := get_tree().current_scene
	if scene == null or not _supports(scene) or int(scene.get("phase")) != 1:
		return
	for enemy in scene.get("enemies"):
		if typeof(enemy) == TYPE_DICTIONARY:
			_draw_enemy(surface, enemy)
	_draw_player(surface, scene)

func _supports(scene: Object) -> bool:
	var names: Dictionary = {}
	for property in scene.get_property_list():
		names[str(property.get("name", ""))] = true
	return names.has("phase") and names.has("player_position") and names.has("enemies")

func _has_property(subject: Object, property_name: String) -> bool:
	for property in subject.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _draw_player(surface: CanvasItem, scene: Object) -> void:
	var p: Vector2 = scene.get("player_position") + _altitude_pitch_offset()
	var origin := (p - VX94_GAMEPLAY_ANCHOR).round()
	var time := float(scene.get("mission_time")) if _has_property(scene, "mission_time") else Time.get_ticks_msec() / 1000.0
	var exhaust_frame: Texture2D = VX94_EXHAUST[int(floor(time * 12.0)) % VX94_EXHAUST.size()]
	surface.draw_texture(exhaust_frame, origin)
	var texture: Texture2D
	if _visual_sweep <= 0.02:
		texture = VX94_FIGHTER_BANK[_bank_frame_index()]
	elif _visual_sweep >= 0.98:
		texture = VX94_BOMBER_BANK[_bank_frame_index()]
	else:
		var form_index := clampi(int(round(_visual_sweep * float(VX94_GAMEPLAY_FORMS.size() - 1))), 0, VX94_GAMEPLAY_FORMS.size() - 1)
		texture = VX94_GAMEPLAY_FORMS[form_index]
	surface.draw_texture(texture, origin)
	var max_hull := maxi(1, int(scene.call("_max_hull"))) if scene.has_method("_max_hull") else 100
	var damage_ratio := 1.0 - clampf(float(scene.get("hull")) / float(max_hull), 0.0, 1.0) if _has_property(scene, "hull") else 0.0
	if damage_ratio >= 0.62:
		surface.draw_texture(VX94_DAMAGE[1], origin)
	elif damage_ratio >= 0.28:
		surface.draw_texture(VX94_DAMAGE[0], origin)

func _bank_frame_index() -> int:
	if _bank_visual < -0.22: return 0
	if _bank_visual > 0.22: return 2
	return 1

func _draw_enemy(surface: CanvasItem, enemy: Dictionary) -> void:
	var p: Vector2 = enemy.get("position", Vector2.ZERO)
	var enemy_id := str(enemy.get("id", ""))
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
		_draw_animated_unit(surface, p, enemy_id, enemy, MERCENARY_GROUND_FORCE_SPRITES[enemy_id], scale)
	elif category == "ground" and MERCENARY_GROUND_SPRITES.has(enemy_id):
		_draw_production_sprite(surface, p, MERCENARY_GROUND_SPRITES[enemy_id], scale)
	elif category == "ground":
		_report_missing_art(enemy_id)
	elif category == "sea" and MERCENARY_SEA_SPRITES.has(enemy_id):
		_draw_naval_unit(surface, p, enemy, MERCENARY_SEA_SPRITES[enemy_id], scale)
	elif category == "sea":
		_report_missing_art(enemy_id)
	elif MERCENARY_AIR_SPRITES.has(enemy_id):
		_draw_hostile_airframe(surface, p, enemy_id, enemy, MERCENARY_AIR_SPRITES[enemy_id])
	else:
		_report_missing_art(enemy_id)
	if not is_boss:
		_draw_enemy_damage_attachments(surface, p, enemy, category, faction, scale)

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
	if AIR_PROPULSION_STYLE.has(enemy_id) and not UNIT_ANIMATION_FRAMES.has(enemy_id):
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
		var turret: Texture2D = AIR_SPECIALIST_ART[enemy_id]
		var direction := _player_position() - p
		var rotation := 0.0 if direction.length_squared() < 0.001 else Vector2.DOWN.angle_to(direction.normalized())
		surface.draw_set_transform(p.round(), rotation, Vector2.ONE)
		surface.draw_texture(turret, -turret.get_size() * 0.5 + Vector2(0.0, -roundf(recoil_ratio * 2.0)))
		if recoil_ratio > 0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
			surface.draw_texture_rect(flash, Rect2(-5, 12, 10, 10), false)
		surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif enemy_id == "attack_chopper":
		var cannon: Texture2D = AIR_SPECIALIST_ART[enemy_id]
		var offset := Vector2(0.0, -roundf(recoil_ratio * 2.0))
		surface.draw_texture(cannon, (p - cannon.get_size() * 0.5 + offset).round())
		if recoil_ratio > 0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
			surface.draw_texture_rect(flash, Rect2((p + Vector2(-5, 12)).round(), Vector2(10,10)), false)
	elif enemy_id == "heavy_bomber":
		var bay_frames: Array = AIR_SPECIALIST_ART[enemy_id]
		var frame_index := heavy_bomber_bay_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_draw_production_sprite(surface, p, bay_frames[frame_index])

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
	if bank_index == 1 and enemy_id == "drone_hunter":
		var weapon: Texture2D = MACHINE_AIR_SPECIALIST_ART[enemy_id]
		var offset := Vector2(0.0, -roundf(recoil_ratio * 2.0))
		surface.draw_texture(weapon, (p - weapon.get_size() * 0.5 + offset).round())
		if recoil_ratio > 0.45:
			var flash := ImpactArtLibrary.frame_for_ratio("muzzle", 1.0-recoil_ratio)
			surface.draw_texture_rect(flash, Rect2((p + Vector2(-8, 11)).round(), Vector2(7,9)), false)
			surface.draw_texture_rect(flash, Rect2((p + Vector2(1, 11)).round(), Vector2(7,9)), false)
	elif bank_index == 1 and enemy_id in ["drone_bomber", "drone_missile_node"]:
		var door_frames: Array = MACHINE_AIR_SPECIALIST_ART[enemy_id]
		var door_index := machine_weapon_door_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_draw_production_sprite(surface, p, door_frames[door_index])
	var core_frames: Array = MACHINE_AIR_SPECIALIST_ART["core"]
	var pulse_cycle := [0, 1, 2, 1]
	var core_index: int = pulse_cycle[int(floor(float(enemy.get("age", 0.0)) * 6.0)) % pulse_cycle.size()]
	var core: Texture2D = core_frames[core_index]
	surface.draw_texture(core, (p - core.get_size() * 0.5).round())

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
	if bank_index == 1 and enemy_id == "orbital_sentry":
		var turret: Texture2D = ORBITAL_AIR_SPECIALIST_ART[enemy_id]
		var direction := _player_position() - p
		var rotation := 0.0 if direction.length_squared() < 0.001 else Vector2.DOWN.angle_to(direction.normalized())
		surface.draw_set_transform(p.round(), rotation, Vector2.ONE)
		surface.draw_texture(turret, -turret.get_size() * 0.5 + Vector2(0.0, -roundf(recoil_ratio * 2.0)))
		surface.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif enemy_id == "phase_interceptor":
		var phase_frames: Array = ORBITAL_AIR_SPECIALIST_ART[enemy_id]
		var phase_cycle := [0, 1, 2, 1]
		var phase_index: int = phase_cycle[int(floor(float(enemy.get("age", 0.0)) * 7.0)) % phase_cycle.size()]
		_draw_production_sprite(surface, p, phase_frames[phase_index])
	elif bank_index == 1 and enemy_id in ["beam_sentry", "orbital_lancer"]:
		var weapon_frames: Array = ORBITAL_AIR_SPECIALIST_ART[enemy_id]
		var weapon_index := orbital_weapon_frame_index(float(enemy.get("fire_timer", 1.0)), recoil_ratio)
		_draw_production_sprite(surface, p, weapon_frames[weapon_index])

static func orbital_weapon_frame_index(fire_timer: float, recoil_ratio: float) -> int:
	if recoil_ratio > 0.01:
		return 3
	if fire_timer > 0.62:
		return 0
	if fire_timer > 0.30:
		return 1
	return 2

func _draw_naval_unit(surface: CanvasItem, p: Vector2, enemy: Dictionary, hull: Texture2D, scale: float) -> void:
	var frame_index := int(floor(float(enemy.get("age", 0.0)) * 8.0)) % NAVAL_WAKE_FRAMES.size()
	var wake: Texture2D = NAVAL_WAKE_FRAMES[frame_index]
	var wake_scale := scale * clampf(hull.get_width() / 40.0, 0.72, 1.15)
	var wake_size := wake.get_size() * wake_scale
	var wake_center := p + Vector2(0.0, -hull.get_height() * scale * 0.5 - wake_size.y * 0.42 + 4.0 * scale)
	var destination := Rect2((wake_center - wake_size * 0.5).round(), wake_size.round())
	surface.draw_texture_rect(wake, destination, false, Color(0.72, 0.82, 0.86, 0.68))
	_draw_production_sprite(surface, p, hull, scale)

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
	_draw_production_sprite(surface, p, texture)
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

func _draw_layered_ground(surface: CanvasItem, p: Vector2, enemy: Dictionary, layers: Dictionary, scale: float) -> void:
	var base: Texture2D = layers.get("base")
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
	if scene != null:
		for property in scene.get_property_list():
			if str(property.get("name", "")) == "player_position":
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
