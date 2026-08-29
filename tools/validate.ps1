[CmdletBinding()]
param([string]$GodotBin = $env:GODOT_BIN)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Resolve-Godot {
    param([string]$Preferred)
    if ($Preferred -and (Test-Path $Preferred)) { return (Resolve-Path $Preferred).Path }
    foreach ($Candidate in @('godot','godot4','Godot_v4.6.2-stable_win64_console.exe','Godot_v4.6.2-stable_win64.exe')) {
        $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
        if ($Command) { return $Command.Source }
    }
    return $null
}
function Assert-UniqueIds($Collection, [string]$Label) {
    $Ids = @($Collection | ForEach-Object { $_.id })
    if ($Ids -contains $null -or $Ids -contains '') { throw "Blank id in $Label" }
    if (@($Ids | Sort-Object -Unique).Count -ne $Ids.Count) { throw "Duplicate id in $Label" }
}
function Assert-Contains([string]$Text, [string[]]$Tokens, [string]$Label) {
    foreach ($Token in $Tokens) {
        if (-not $Text.Contains($Token)) { throw "$Label missing token: $Token" }
    }
}

Write-Host 'Validating Strike Wing 94...' -ForegroundColor Cyan

$Required = @(
    'project.godot','scenes/main.tscn','scripts/main.gd','scripts/content_catalog.gd',
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd','scripts/objective_rules.gd',
    'scripts/boss_rules.gd','scripts/boss_signature_rules.gd','scripts/boss_director.gd','scripts/bomb_rules.gd',
    'scripts/campaign_save.gd','scripts/save_recovery_rules.gd','scripts/run_seed_rules.gd',
    'scripts/mission_state_rules.gd','scripts/mission_flow_rules.gd','scripts/movement_pattern_rules.gd','scripts/weapon_pickup_rules.gd',
    'scripts/accuracy_rules.gd','scripts/reward_rules.gd','scripts/service_rules.gd','scripts/energy_rules.gd','scripts/tech_progression_rules.gd',
    'scripts/airframe_rules.gd','scripts/airframe_director.gd',
    'scripts/directed_energy_rules.gd','scripts/directed_energy_director.gd',
    'scripts/encounter_rules.gd','scripts/encounter_director.gd',
    'scripts/support_rules.gd','scripts/support_director.gd',
    'scripts/craft_form_rules.gd','scripts/altitude_rules.gd','scripts/craft_form_director.gd',
    'scripts/environment_rules.gd','scripts/environment_surface.gd','scripts/environment_director.gd',
    'scripts/battlefield_support_rules.gd','scripts/battlefield_support_surface.gd','scripts/battlefield_support_director.gd',
    'scripts/strike_ordnance_rules.gd','scripts/strike_ordnance_surface.gd','scripts/strike_ordnance_director.gd',
    'scripts/electromagnetic_cue_surface.gd','scripts/electromagnetic_cue_director.gd',
    'scripts/combat_art_surface.gd','scripts/combat_art_director.gd',
    'scripts/pixel_font.gd','scripts/pixel_ui_surface.gd','scripts/pixel_ui_director.gd',
    'scripts/projectile_cue_rules.gd','scripts/projectile_cue_director.gd','scripts/threat_warning_rules.gd',
    'tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd',
    'tools/save_recovery_self_test.gd','tools/encounter_self_test.gd','tools/support_self_test.gd','tools/craft_form_self_test.gd',
    'tools/battlefield_support_self_test.gd','tools/environment_self_test.gd','tools/strike_ordnance_self_test.gd',
    'tools/tech_progression_self_test.gd','tools/boss_signature_self_test.gd','tools/combat_art_self_test.gd',
    'data/weapons.json','data/generators.json','data/airframes.json','data/support_systems.json','data/battlefield_support.json',
    'data/enemies.json','data/missions.json','data/spawn_profiles.json','data/environment_profiles.json',
    'data/campaign.json','data/campaign_world.json','data/player_craft.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md','docs/90S_SHOOTER_BIBLE.md','docs/CAMPAIGN_CANON.md','docs/CRAFT_ALTITUDE_SYSTEM.md','docs/VX94_COMBAT_ART_DIRECTION.md'
)
foreach ($RelativePath in $Required) {
    if (-not (Test-Path (Join-Path $Root $RelativePath))) { throw "Missing required file: $RelativePath" }
}

$Forbidden = @(
    '.github/workflows','.godot','build','dist',
    'scripts/spawn_safety_director.gd','scripts/spawn_safety_rules.gd',
    'scripts/missile_behavior_director.gd','scripts/missile_behavior_rules.gd',
    'scripts/mission_state_director.gd','scripts/bomb_guard_director.gd','scripts/mission_flow_director.gd',
    'scripts/movement_pattern_director.gd','scripts/run_seed_director.gd','scripts/weapon_pickup_director.gd',
    'scripts/accuracy_director.gd','scripts/reward_director.gd','scripts/service_director.gd',
    'scripts/boss_hud_director.gd','scripts/boss_hud_rules.gd','scripts/threat_warning_director.gd'
)
foreach ($RelativePath in $Forbidden) {
    if (Test-Path (Join-Path $Root $RelativePath)) { throw "Forbidden generated/obsolete path committed: $RelativePath" }
}

$Weapons = Get-Content -Raw (Join-Path $Root 'data/weapons.json') | ConvertFrom-Json
$Generators = Get-Content -Raw (Join-Path $Root 'data/generators.json') | ConvertFrom-Json
$Airframes = Get-Content -Raw (Join-Path $Root 'data/airframes.json') | ConvertFrom-Json
$Supports = Get-Content -Raw (Join-Path $Root 'data/support_systems.json') | ConvertFrom-Json
$BattlefieldSupports = Get-Content -Raw (Join-Path $Root 'data/battlefield_support.json') | ConvertFrom-Json
$Enemies = Get-Content -Raw (Join-Path $Root 'data/enemies.json') | ConvertFrom-Json
$Missions = Get-Content -Raw (Join-Path $Root 'data/missions.json') | ConvertFrom-Json
$Profiles = Get-Content -Raw (Join-Path $Root 'data/spawn_profiles.json') | ConvertFrom-Json
$EnvironmentProfiles = Get-Content -Raw (Join-Path $Root 'data/environment_profiles.json') | ConvertFrom-Json
$Campaign = Get-Content -Raw (Join-Path $Root 'data/campaign.json') | ConvertFrom-Json
$World = Get-Content -Raw (Join-Path $Root 'data/campaign_world.json') | ConvertFrom-Json
$PlayerCraft = Get-Content -Raw (Join-Path $Root 'data/player_craft.json') | ConvertFrom-Json

Assert-UniqueIds $Weapons.weapons 'weapons'
Assert-UniqueIds $Generators.generators 'generators'
Assert-UniqueIds $Airframes.airframes 'airframes'
Assert-UniqueIds $Supports.supports 'support systems'
Assert-UniqueIds $BattlefieldSupports.supports 'battlefield support'
Assert-UniqueIds $Enemies.enemies 'enemies'
Assert-UniqueIds $Missions.missions 'missions'
Assert-UniqueIds $Profiles.profiles 'spawn profiles'
Assert-UniqueIds $EnvironmentProfiles.profiles 'environment profiles'

$EraOrder = @{ advanced_conventional=1; electromagnetic=2; directed_energy=3; strategic_orbital=4 }
$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' })
if ($Primaries.Count -lt 7) { throw 'Campaign requires at least seven distinct primary tiers.' }
$PreviousCost = -1
foreach ($Weapon in $Primaries) {
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary weapon costs out of order: $($Weapon.id)" }
    if ([int]$Weapon.damage -le 0 -or [double]$Weapon.projectile_speed -le 0 -or [double]$Weapon.fire_interval -le 0 -or [int]$Weapon.projectiles -le 0 -or [double]$Weapon.energy_cost -le 0) { throw "Invalid primary weapon values: $($Weapon.id)" }
    if (-not $Weapon.archetype -or -not $EraOrder.ContainsKey([string]$Weapon.unlock_tech_era)) { throw "Primary weapon missing archetype/tech era: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}
$Rail = @($Primaries | Where-Object { $_.id -eq 'needle_rail' })[0]
$Storm = @($Primaries | Where-Object { $_.id -eq 'storm_cannon' })[0]
if ([string]$Rail.archetype -ne 'precision_kinetic' -or [int]$Rail.pierce -ne 2 -or [string]$Rail.unlock_tech_era -ne 'electromagnetic') { throw 'Needle Rail kinetic identity is invalid.' }
if ([string]$Storm.archetype -ne 'directed_energy_pulse' -or [string]$Storm.unlock_tech_era -ne 'directed_energy' -or [int]$Storm.projectiles -ne 3) { throw 'Storm Cannon directed-energy pulse identity is invalid.' }

if (@($Generators.generators).Count -lt 5) { throw 'Generator progression requires at least five tiers.' }
$PreviousCost = -1; $PreviousCapacity = 0.0; $PreviousRecharge = 0.0
foreach ($Generator in $Generators.generators) {
    if ([int]$Generator.cost -lt $PreviousCost -or [double]$Generator.capacity -le 0 -or [double]$Generator.recharge_per_second -le 0) { throw "Invalid generator tier: $($Generator.id)" }
    if ([double]$Generator.capacity -lt $PreviousCapacity -or [double]$Generator.recharge_per_second -lt $PreviousRecharge) { throw "Generator progression regresses output: $($Generator.id)" }
    if (-not $EraOrder.ContainsKey([string]$Generator.unlock_tech_era) -or -not $EraOrder.ContainsKey([string]$Generator.efficiency_tech_era)) { throw "Generator has invalid technology era: $($Generator.id)" }
    if ([double]$Generator.efficiency_multiplier -lt 0.75 -or [double]$Generator.efficiency_multiplier -gt 1.0) { throw "Generator efficiency out of bounds: $($Generator.id)" }
    $PreviousCost = [int]$Generator.cost
    $PreviousCapacity = [double]$Generator.capacity
    $PreviousRecharge = [double]$Generator.recharge_per_second
}

if (@($Airframes.airframes).Count -ne 5) { throw 'VX-94 airframe progression requires exactly five authored tiers.' }
$PreviousCost = -1; $PreviousHull = 0; $PreviousShield = 0
foreach ($Frame in $Airframes.airframes) {
    if ([int]$Frame.cost -lt $PreviousCost -or [int]$Frame.hull_capacity -lt $PreviousHull -or [int]$Frame.shield_capacity -lt $PreviousShield) { throw "Airframe progression regresses cost/capacity: $($Frame.id)" }
    if ([int]$Frame.hull_capacity -lt 1 -or [int]$Frame.shield_capacity -lt 0 -or -not $EraOrder.ContainsKey([string]$Frame.unlock_tech_era)) { throw "Invalid airframe tier: $($Frame.id)" }
    $PreviousCost = [int]$Frame.cost; $PreviousHull = [int]$Frame.hull_capacity; $PreviousShield = [int]$Frame.shield_capacity
}
$MagneticFrame = @($Airframes.airframes | Where-Object { $_.id -eq 'magneto_composite_frame' })[0]
$FieldFrame = @($Airframes.airframes | Where-Object { $_.id -eq 'field_coupled_frame' })[0]
if ($MagneticFrame.unlock_tech_era -ne 'electromagnetic' -or $FieldFrame.unlock_tech_era -ne 'directed_energy') { throw 'Late VX-94 airframes must follow technology progression.' }

$AllowedSupportTypes = @('rockets','crossfire','hunter','defence','emp','magnetic')
$SupportTypes = @(); $PreviousCost = -1
foreach ($Support in $Supports.supports) {
    if ($AllowedSupportTypes -notcontains [string]$Support.type) { throw "Unsupported support type: $($Support.id)" }
    if ([int]$Support.cost -lt $PreviousCost -or [double]$Support.energy_cost -le 0 -or [double]$Support.cooldown -le 0) { throw "Invalid tactical support economy: $($Support.id)" }
    if (-not $EraOrder.ContainsKey([string]$Support.unlock_tech_era)) { throw "Support has invalid technology era: $($Support.id)" }
    if ($Support.type -eq 'defence' -and ([double]$Support.radius -le 0 -or [double]$Support.radius -gt 160 -or [int]$Support.max_targets -lt 1 -or [int]$Support.max_targets -gt 12)) { throw "Point defence bounds invalid: $($Support.id)" }
    if ($Support.type -in @('emp','magnetic') -and ([double]$Support.radius -le 0 -or [double]$Support.radius -gt 240 -or [double]$Support.duration -le 0 -or [double]$Support.duration -gt 8)) { throw "Electromagnetic support bounds invalid: $($Support.id)" }
    $SupportTypes += [string]$Support.type
    $PreviousCost = [int]$Support.cost
}
foreach ($RequiredType in $AllowedSupportTypes) { if ($SupportTypes -notcontains $RequiredType) { throw "Missing tactical support role: $RequiredType" } }
$Emp = @($Supports.supports | Where-Object { $_.id -eq 'emp_disruptor' })[0]
$Magnetic = @($Supports.supports | Where-Object { $_.id -eq 'magnetic_screen' })[0]
if ($Emp.unlock_tech_era -ne 'electromagnetic' -or $Magnetic.unlock_tech_era -ne 'electromagnetic') { throw 'EMP and magnetic systems must remain electromagnetic-era unlocks.' }

$AllowedAltitudes = @('low','mid','high','orbital')
if (@($World.altitude_bands).Count -ne 4) { throw 'Campaign world must define exactly four altitude bands.' }
$ThreatIds = @($World.threat_phases | ForEach-Object { $_.id })
foreach ($RequiredThreat in @('mercenary_war','drone_war','external_contact')) { if ($ThreatIds -notcontains $RequiredThreat) { throw "Missing threat phase: $RequiredThreat" } }
if ([string]$PlayerCraft.craft.id -ne 'vx_94_strikewing' -or $null -eq $PlayerCraft.craft.forms.fighter -or $null -eq $PlayerCraft.craft.forms.bomber) { throw 'VX-94 fighter/bomber craft definition is incomplete.' }

$BattlefieldSupportIds = @($BattlefieldSupports.supports | ForEach-Object { $_.id })
foreach ($RequiredSupport in @('spectre_gunship','atlas_tanker','rapier_flight','hammer_bomber_flight','cruise_missile_support','rail_support','orbital_strike')) {
    if ($BattlefieldSupportIds -notcontains $RequiredSupport) { throw "Missing battlefield support package: $RequiredSupport" }
}
foreach ($Support in $BattlefieldSupports.supports) {
    if ([double]$Support.duration_seconds -le 0 -or [double]$Support.cooldown_seconds -le 0) { throw "Invalid battlefield support timing: $($Support.id)" }
    foreach ($Band in @($Support.altitudes)) { if ($AllowedAltitudes -notcontains $Band) { throw "Battlefield support uses invalid altitude: $($Support.id) -> $Band" } }
}

$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id })
$BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
$AllowedClasses = @('air','ground','sea','boss')
$AllowedEnemyWeapons = @('single_burst','aimed_burst','side_burst','cannon','missile','deck_gun','twin_burst')
$AllowedPatterns = @('sine_dive','tracking_sweep','hover_strafe','road_column','water_lane','static','aggressive_weave','boss_sweep','boss_column','boss_broadside')
foreach ($Enemy in $Enemies.enemies) {
    if ($AllowedClasses -notcontains $Enemy.class -or $AllowedEnemyWeapons -notcontains $Enemy.weapon -or $AllowedPatterns -notcontains $Enemy.pattern) { throw "Invalid enemy archetype: $($Enemy.id)" }
    if ([int]$Enemy.hp -le 0 -or [int]$Enemy.value -le 0 -or [double]$Enemy.speed -lt 0) { throw "Invalid enemy combat values: $($Enemy.id)" }
    if ($Enemy.faction -eq 'autonomous' -and ([double]$Enemy.emp_resistance -lt 0 -or [double]$Enemy.emp_resistance -gt 0.95)) { throw "Autonomous EMP resistance out of range: $($Enemy.id)" }
}
foreach ($DroneId in @('drone_scout','drone_hunter','drone_bomber','drone_missile_node','autonomous_armor','factory_defence_node','exo_drone','orbital_sentry','swarm_controller','ai_forge_core','orbital_command_node')) {
    if ($EnemyIds -notcontains $DroneId) { throw "Missing autonomous-war enemy: $DroneId" }
}

$AllowedPickups = @('','shield','repair','bomb','weapon')
$AllowedConditions = @('accuracy_at_least','score_at_least','bombs_at_least')
$AllowedFormations = @('scatter','line','wedge','split','column','stagger')
$MissionIds = @($Missions.missions | ForEach-Object { $_.id })
if (@($Missions.missions).Count -lt 9) { throw 'Campaign requires the authored nine-mission mercenary/drone arc.' }
foreach ($Mission in $Missions.missions) {
    if ([int]$Mission.duration_seconds -le 0 -or [int]$Mission.starting_wave -lt 1) { throw "Invalid mission timing/wave: $($Mission.id)" }
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Unknown mission boss: $($Mission.boss_id)" }
    Assert-UniqueIds @($Mission.objectives) "mission $($Mission.id) objectives"
    if (@($Mission.objectives | Where-Object { $_.required }).Count -lt 1) { throw "Mission has no required objective: $($Mission.id)" }
    $Beats = @($Mission.encounter_beats)
    if ($Beats.Count -lt 5) { throw "Mission needs at least five encounter beats: $($Mission.id)" }
    Assert-UniqueIds $Beats "mission $($Mission.id) encounter beats"
    $LastTime = -1.0; $HasReward = $false; $HasPacing = $false; $HasSecret = $false; $FormationSet = @{}
    foreach ($Beat in $Beats) {
        $At = [double]$Beat.at_seconds
        if ($At -le $LastTime -or $At -lt 0 -or $At -ge [double]$Mission.duration_seconds) { throw "Encounter timing invalid: $($Mission.id)/$($Beat.id)" }
        $LastTime = $At
        if ($AllowedPickups -notcontains [string]$Beat.pickup) { throw "Unknown encounter pickup: $($Mission.id)/$($Beat.id)" }
        if ($AllowedFormations -notcontains [string]$Beat.formation) { throw "Unknown encounter formation: $($Mission.id)/$($Beat.id)" }
        $FormationSet[[string]$Beat.formation] = $true
        if ($Beat.pickup) { $HasReward = $true }
        if ([double]$Beat.suppress_random_seconds -ge 2.0) { $HasPacing = $true }
        if ([bool]$Beat.secret) {
            $HasSecret = $true
            if ($AllowedConditions -notcontains [string]$Beat.condition.type) { throw "Unsupported secret condition: $($Mission.id)/$($Beat.id)" }
            if ([string]$Beat.condition.type -eq 'accuracy_at_least' -and [int]$Beat.condition.minimum_shots -lt 20) { throw "Accuracy secret needs meaningful sample: $($Mission.id)/$($Beat.id)" }
        }
        $Count = 0
        foreach ($Entry in @($Beat.enemies)) {
            if ($EnemyIds -notcontains $Entry.id -or $BossIds -contains $Entry.id -or [int]$Entry.count -lt 1) { throw "Invalid encounter enemy: $($Mission.id)/$($Beat.id) -> $($Entry.id)" }
            $Count += [int]$Entry.count
        }
        if ($Count -gt 12) { throw "Encounter beat exceeds cap: $($Mission.id)/$($Beat.id)" }
        if ($Count -eq 0 -and -not $Beat.pickup) { throw "Encounter beat is empty: $($Mission.id)/$($Beat.id)" }
    }
    if (-not $HasReward -or -not $HasPacing -or -not $HasSecret -or $FormationSet.Keys.Count -lt 3) { throw "Mission lacks pacing/recovery/secret/formation variety: $($Mission.id)" }
    $Context = $World.mission_context.([string]$Mission.id)
    if ($null -eq $Context) { throw "Mission missing campaign-world context: $($Mission.id)" }
    if ($AllowedAltitudes -notcontains [string]$Context.altitude) { throw "Mission uses invalid initial altitude: $($Mission.id)" }
    if ($ThreatIds -notcontains [string]$Context.threat_phase) { throw "Mission uses invalid threat phase: $($Mission.id)" }
    if (-not $EraOrder.ContainsKey([string]$Context.tech_era)) { throw "Mission uses invalid technology era: $($Mission.id)" }
    if (@('fighter','bomber') -notcontains [string]$Context.recommended_form) { throw "Mission uses invalid recommended form: $($Mission.id)" }
    foreach ($SupportId in @($Context.support)) { if ($BattlefieldSupportIds -notcontains $SupportId) { throw "Unknown mission battlefield support: $($Mission.id) -> $SupportId" } }
    $TransitionTime = -1.0
    foreach ($Transition in @($Context.altitude_transitions)) {
        if ([double]$Transition.at_seconds -le $TransitionTime -or [double]$Transition.at_seconds -ge [double]$Mission.duration_seconds) { throw "Invalid altitude transition timing: $($Mission.id)" }
        if ($AllowedAltitudes -notcontains [string]$Transition.altitude) { throw "Invalid altitude transition band: $($Mission.id) -> $($Transition.altitude)" }
        $TransitionTime = [double]$Transition.at_seconds
    }
}
foreach ($MissionId in @('m01_coastal_intercept','m02_refinery_run','m03_black_sea','m04_breakwater','m05_furnace_line','m06_black_flag')) { if ([string]$World.mission_context.$MissionId.threat_phase -ne 'mercenary_war') { throw "$MissionId must remain in mercenary_war." } }
foreach ($MissionId in @('m07_ghost_sky','m08_machine_furnace','m09_black_horizon')) { if ([string]$World.mission_context.$MissionId.threat_phase -ne 'drone_war') { throw "$MissionId must belong to drone_war." } }
if ([string]$World.mission_context.m07_ghost_sky.altitude -ne 'high') { throw 'Ghost Sky must begin at high altitude.' }
if ([string]$World.mission_context.m09_black_horizon.altitude -ne 'high' -or [string]$World.mission_context.m09_black_horizon.altitude_transitions[0].altitude -ne 'orbital') { throw 'Black Horizon must climb from high altitude into orbital combat.' }
if ([string]$World.mission_context.m06_black_flag.altitude_transitions[0].altitude -ne 'low' -or [string]$World.mission_context.m06_black_flag.altitude_transitions[1].altitude -ne 'mid') { throw 'Black Flag must descend to low altitude and climb back to mid.' }

$CampaignMissionIds = @($Campaign.campaign.missions)
foreach ($MissionId in $CampaignMissionIds) { if ($MissionIds -notcontains $MissionId) { throw "Campaign references unknown mission: $MissionId" } }
if (@($CampaignMissionIds | Sort-Object -Unique).Count -ne $CampaignMissionIds.Count -or $CampaignMissionIds.Count -ne $Missions.missions.Count) { throw 'Campaign order must include every mission exactly once.' }

foreach ($Profile in $Profiles.profiles) {
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave -or @($Profile.enemy_ids).Count -lt 1) { throw "Invalid spawn profile: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) { if ($EnemyIds -notcontains $EnemyId -or $BossIds -contains $EnemyId) { throw "Invalid spawn-profile enemy: $($Profile.id) -> $EnemyId" } }
}
foreach ($Environment in @($Missions.missions | ForEach-Object { $_.environment } | Sort-Object -Unique)) {
    $Ranges = @($Profiles.profiles | Where-Object { $_.environment -eq $Environment } | Sort-Object min_wave)
    if ($Ranges.Count -lt 1) { throw "No spawn profile for mission environment: $Environment" }
    $NextWave = 1
    foreach ($Range in $Ranges) {
        if ([int]$Range.min_wave -gt $NextWave) { throw "Spawn profile gap for $Environment before wave $NextWave" }
        $NextWave = [Math]::Max($NextWave, [int]$Range.max_wave + 1)
    }
    if ($NextWave -lt 100) { throw "Spawn profiles for $Environment do not cover through wave 99." }
}
$EnvironmentIds = @($EnvironmentProfiles.profiles | ForEach-Object { $_.id })
foreach ($RequiredEnvironment in @('coast','industrial','open_water','high_cloud','orbital')) { if ($EnvironmentIds -notcontains $RequiredEnvironment) { throw "Missing environment profile: $RequiredEnvironment" } }
foreach ($Environment in @($Missions.missions | ForEach-Object { $_.environment } | Sort-Object -Unique)) { if ($EnvironmentIds -notcontains $Environment) { throw "Mission lacks visual environment profile: $Environment" } }

$ProjectText = Get-Content -Raw (Join-Path $Root 'project.godot')
foreach ($Autoload in @(
    'SupportDirector="*res://scripts/support_director.gd"',
    'CampaignSave="*res://scripts/campaign_save.gd"',
    'EncounterDirector="*res://scripts/encounter_director.gd"',
    'CraftFormDirector="*res://scripts/craft_form_director.gd"',
    'AirframeDirector="*res://scripts/airframe_director.gd"',
    'EnvironmentDirector="*res://scripts/environment_director.gd"',
    'BattlefieldSupportDirector="*res://scripts/battlefield_support_director.gd"',
    'CombatArtDirector="*res://scripts/combat_art_director.gd"',
    'StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"',
    'ElectromagneticCueDirector="*res://scripts/electromagnetic_cue_director.gd"',
    'DirectedEnergyDirector="*res://scripts/directed_energy_director.gd"',
    'BossDirector="*res://scripts/boss_director.gd"',
    'PixelUiDirector="*res://scripts/pixel_ui_director.gd"',
    'ProjectileCueDirector="*res://scripts/projectile_cue_director.gd"'
)) { if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" } }
foreach ($Obsolete in @('ServiceDirector','RewardDirector','AccuracyDirector','WeaponPickupDirector','RunSeedDirector','MovementPatternDirector','MissionFlowDirector','MissionStateDirector','BombGuardDirector','MissileBehaviorDirector','SpawnSafetyDirector','BossHudDirector','ThreatWarningDirector')) { if ($ProjectText.Contains($Obsolete)) { throw "Obsolete autoload returned: $Obsolete" } }

$MainText = Get-Content -Raw (Join-Path $Root 'scripts/main.gd')
Assert-Contains $MainText @(
    'mission_rng.seed = RunSeedRules.mission_seed(mission_index)',
    'EnergyRules.recharge(energy, _active_generator(), delta)',
    'MovementPatternRules.adjusted_position',
    'MissionFlowRules.should_hold_overtime',
    'BombRules.apply_nonlethal_boss_damage',
    '_craft_float("movement_multiplier", 1.0)',
    '_craft_float("primary_spread_multiplier", 1.0)',
    '_target_damage_multiplier(enemy_class)',
    '_craft_float("collision_radius_sq", 420.0)',
    '_craft_float("projectile_hit_radius_sq", 120.0)'
) 'Main gameplay'

$SupportText = Get-Content -Raw (Join-Path $Root 'scripts/support_director.gd')
Assert-Contains $SupportText @('TechProgressionRules.can_unlock','TECH LOCK -','SupportRules.emp_resistance(enemy)','emp_slow_scale','_update_magnetic_field','bullet["homing"] = false','StrikeOrdnanceDirector') 'Tactical support runtime'
$CraftRulesText = Get-Content -Raw (Join-Path $Root 'scripts/craft_form_rules.gd')
Assert-Contains $CraftRulesText @('TRANSFORM_WEAPON_INTERLOCK','projectile_hit_radius_sq','ground_attack_multiplier','air_attack_multiplier','support_energy_multiplier') 'Craft form rules'
$CraftDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/craft_form_director.gd')
Assert-Contains $CraftDirectorText @('KEY_Q','_apply_due_altitude_transitions','_apply_weapon_interlock','projectile_hit_radius_sq','target_damage_multiplier') 'Craft form director'
$AirframeText = Get-Content -Raw (Join-Path $Root 'scripts/airframe_director.gd')
Assert-Contains $AirframeText @('KEY_K','ProgressionRules.next_weapon_index','MissionStateRules.set_airframe_context','TECH LOCK -','airframe_state','restore_airframe_state') 'Airframe runtime'
$DirectedText = Get-Content -Raw (Join-Path $Root 'scripts/directed_energy_director.gd')
Assert-Contains $DirectedText @('process_priority = -1','DirectedEnergyRules.can_discharge','pulse_discharged','DirectedEnergyRules.secondary_indices','hp - 1') 'Directed-energy runtime'
$StrikeText = Get-Content -Raw (Join-Path $Root 'scripts/strike_ordnance_director.gd')
Assert-Contains $StrikeText @('KEY_E','STRIKE ORDNANCE REQUIRES BOMBER CONFIG','maxi(1, hp - damage)','PixelFont.draw_text(surface, "E BOMB %d"') 'Strike ordnance runtime'
$BattleText = Get-Content -Raw (Join-Path $Root 'scripts/battlefield_support_director.gd')
Assert-Contains $BattleText @('atlas_tanker','tanker_connected','TANKER REARM COMPLETE','rearm_support','_draw_fighter_sweep','_draw_bomber_run','_draw_gunship','_draw_cruise_missile','_draw_rail_strike','_draw_orbital_strike') 'Battlefield support runtime'
$BossText = Get-Content -Raw (Join-Path $Root 'scripts/boss_director.gd')
Assert-Contains $BossText @('BossSignatureRules','signature_timer','_emit_signature_attack','_report_signature','shot["kinetic"] = true') 'Autonomous boss signatures'
$EnvironmentText = Get-Content -Raw (Join-Path $Root 'scripts/environment_director.gd')
Assert-Contains $EnvironmentText @('EnvironmentRules','current_altitude','high_cloud','orbital') 'Environment runtime'
$EmCueText = Get-Content -Raw (Join-Path $Root 'scripts/electromagnetic_cue_director.gd')
Assert-Contains $EmCueText @('magnetic_active','emp_timer','draw_arc') 'Electromagnetic cues'
$CombatArtText = Get-Content -Raw (Join-Path $Root 'scripts/combat_art_director.gd')
Assert-Contains $CombatArtText @('TRANSFORM_VISUAL_SECONDS := 0.34','_draw_transforming','AltitudeRules.ground_scale','_draw_autonomous','AI_CORE','_draw_boss') 'Combat art'
$PixelUiText = Get-Content -Raw (Join-Path $Root 'scripts/pixel_ui_director.gd')
Assert-Contains $PixelUiText @('PixelUiSurface.new()','Vector2(640, 360)','Q TRANSFORM','B BATTLE SUPPORT','F CALL','K AIRFRAME','FRAME %s','TECH %s','_form_name()','_altitude_name()','_airframe_name()') 'Pixel UI'
foreach ($WidgetToken in @('PanelContainer.new()','Label.new()','ProgressBar.new()')) { if ($PixelUiText.Contains($WidgetToken)) { throw "Primary pixel UI contains modern widget chrome: $WidgetToken" } }
$SaveText = Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd')
Assert-Contains $SaveText @('SAVE_VERSION := 5','BACKUP_PATH','generator_index','airframe_index','service_hull','service_shield','support_selected','support_unlocked','restore_airframe_state','restore_support_state','SaveRecoveryRules.choose_primary_or_backup') 'Campaign save'

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural/data/save/encounter/support/craft/airframe/altitude/environment validation passed; engine tests skipped.'
    exit 0
}
$Tests = @(
    'runtime_self_test.gd','reward_self_test.gd','service_self_test.gd','mission_flow_self_test.gd','save_recovery_self_test.gd',
    'encounter_self_test.gd','support_self_test.gd','craft_form_self_test.gd','battlefield_support_self_test.gd','environment_self_test.gd',
    'strike_ordnance_self_test.gd','tech_progression_self_test.gd','boss_signature_self_test.gd','combat_art_self_test.gd'
)
foreach ($Test in $Tests) {
    Write-Host "Running $Test..." -ForegroundColor DarkCyan
    & $Godot --headless --path $Root --script "res://tools/$Test"
    if ($LASTEXITCODE -ne 0) { throw "$Test failed with exit code $LASTEXITCODE" }
}
Write-Host 'Running Godot editor smoke test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }
Write-Host 'Strike Wing 94 validation passed.' -ForegroundColor Green
