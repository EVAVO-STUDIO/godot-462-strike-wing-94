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
    foreach ($Token in $Tokens) { if (-not $Text.Contains($Token)) { throw "$Label missing token: $Token" } }
}
function Mission-Context($World, [string]$MissionId) {
    $Property = $World.mission_context.PSObject.Properties[$MissionId]
    if ($null -eq $Property) { return $null }
    return $Property.Value
}

Write-Host 'Validating Strike Wing 94...' -ForegroundColor Cyan

$Required = @(
    'project.godot','scenes/main.tscn','scripts/main.gd','scripts/content_catalog.gd',
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd','scripts/objective_rules.gd',
    'scripts/boss_rules.gd','scripts/boss_signature_rules.gd','scripts/boss_director.gd','scripts/bomb_rules.gd',
    'scripts/campaign_save.gd','scripts/save_recovery_rules.gd','scripts/run_seed_rules.gd','scripts/mission_state_rules.gd','scripts/mission_flow_rules.gd',
    'scripts/movement_pattern_rules.gd','scripts/weapon_pickup_rules.gd','scripts/accuracy_rules.gd','scripts/reward_rules.gd','scripts/service_rules.gd',
    'scripts/energy_rules.gd','scripts/tech_progression_rules.gd','scripts/airframe_rules.gd','scripts/airframe_director.gd',
    'scripts/directed_energy_rules.gd','scripts/directed_energy_director.gd','scripts/strategic_warhead_rules.gd','scripts/strategic_warhead_surface.gd','scripts/strategic_warhead_director.gd',
    'scripts/encounter_rules.gd','scripts/encounter_director.gd','scripts/support_rules.gd','scripts/support_director.gd',
    'scripts/craft_form_rules.gd','scripts/altitude_rules.gd','scripts/craft_form_director.gd',
    'scripts/environment_rules.gd','scripts/environment_surface.gd','scripts/environment_director.gd',
    'scripts/battlefield_support_rules.gd','scripts/battlefield_support_surface.gd','scripts/battlefield_support_director.gd',
    'scripts/strike_ordnance_rules.gd','scripts/strike_ordnance_surface.gd','scripts/strike_ordnance_director.gd',
    'scripts/electromagnetic_cue_surface.gd','scripts/electromagnetic_cue_director.gd',
    'scripts/combat_art_surface.gd','scripts/combat_art_director.gd','scripts/airframe_cue_surface.gd','scripts/airframe_cue_director.gd',
    'scripts/afterburner_cue_surface.gd','scripts/afterburner_cue_director.gd',
    'scripts/mission_intel_rules.gd','scripts/mission_intel_surface.gd','scripts/mission_intel_director.gd',
    'scripts/pixel_font.gd','scripts/pixel_ui_surface.gd','scripts/pixel_ui_director.gd','scripts/projectile_cue_rules.gd','scripts/projectile_cue_director.gd','scripts/threat_warning_rules.gd',
    'tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd','tools/save_recovery_self_test.gd',
    'tools/encounter_self_test.gd','tools/support_self_test.gd','tools/craft_form_self_test.gd','tools/battlefield_support_self_test.gd','tools/environment_self_test.gd',
    'tools/strike_ordnance_self_test.gd','tools/tech_progression_self_test.gd','tools/boss_signature_self_test.gd','tools/combat_art_self_test.gd','tools/afterburner_self_test.gd',
    'data/weapons.json','data/generators.json','data/airframes.json','data/support_systems.json','data/battlefield_support.json','data/enemies.json','data/missions.json',
    'data/spawn_profiles.json','data/environment_profiles.json','data/campaign.json','data/campaign_world.json','data/player_craft.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md','docs/90S_SHOOTER_BIBLE.md','docs/CAMPAIGN_CANON.md','docs/CRAFT_ALTITUDE_SYSTEM.md','docs/VX94_COMBAT_ART_DIRECTION.md','docs/STRATEGIC_ORBITAL_ENDGAME.md'
)
foreach ($RelativePath in $Required) { if (-not (Test-Path (Join-Path $Root $RelativePath))) { throw "Missing required file: $RelativePath" } }

foreach ($Forbidden in @(
    '.github/workflows','.godot','build','dist',
    'scripts/spawn_safety_director.gd','scripts/spawn_safety_rules.gd','scripts/missile_behavior_director.gd','scripts/missile_behavior_rules.gd',
    'scripts/mission_state_director.gd','scripts/bomb_guard_director.gd','scripts/mission_flow_director.gd','scripts/movement_pattern_director.gd',
    'scripts/run_seed_director.gd','scripts/weapon_pickup_director.gd','scripts/accuracy_director.gd','scripts/reward_director.gd','scripts/service_director.gd',
    'scripts/boss_hud_director.gd','scripts/boss_hud_rules.gd','scripts/threat_warning_director.gd'
)) { if (Test-Path (Join-Path $Root $Forbidden)) { throw "Forbidden generated/obsolete path committed: $Forbidden" } }

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

Assert-UniqueIds $Weapons.weapons 'weapons'; Assert-UniqueIds $Generators.generators 'generators'; Assert-UniqueIds $Airframes.airframes 'airframes'
Assert-UniqueIds $Supports.supports 'support systems'; Assert-UniqueIds $BattlefieldSupports.supports 'battlefield support'; Assert-UniqueIds $Enemies.enemies 'enemies'
Assert-UniqueIds $Missions.missions 'missions'; Assert-UniqueIds $Profiles.profiles 'spawn profiles'; Assert-UniqueIds $EnvironmentProfiles.profiles 'environment profiles'

$EraOrder = @{ advanced_conventional=1; electromagnetic=2; directed_energy=3; strategic_orbital=4 }
$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' })
if ($Primaries.Count -ne 8) { throw 'Campaign requires exactly eight primary weapon tiers.' }
$PreviousCost = -1
foreach ($Weapon in $Primaries) {
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary costs regress: $($Weapon.id)" }
    if ([int]$Weapon.damage -le 0 -or [double]$Weapon.projectile_speed -le 0 -or [double]$Weapon.fire_interval -le 0 -or [int]$Weapon.projectiles -le 0 -or [double]$Weapon.energy_cost -le 0) { throw "Invalid primary values: $($Weapon.id)" }
    if (-not $Weapon.archetype -or -not $EraOrder.ContainsKey([string]$Weapon.unlock_tech_era)) { throw "Invalid primary archetype/era: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}
$Rail = @($Primaries | Where-Object { $_.id -eq 'needle_rail' })[0]
$Storm = @($Primaries | Where-Object { $_.id -eq 'storm_cannon' })[0]
$Plasma = @($Primaries | Where-Object { $_.id -eq 'plasma_lance' })[0]
if ([string]$Rail.archetype -ne 'precision_kinetic' -or [int]$Rail.pierce -ne 2 -or [string]$Rail.unlock_tech_era -ne 'electromagnetic') { throw 'Needle Rail identity invalid.' }
if ([string]$Storm.archetype -ne 'directed_energy_pulse' -or [string]$Storm.unlock_tech_era -ne 'directed_energy' -or [int]$Storm.projectiles -ne 3) { throw 'Storm Cannon identity invalid.' }
if ([string]$Plasma.archetype -ne 'strategic_plasma' -or [string]$Plasma.unlock_tech_era -ne 'strategic_orbital' -or [int]$Plasma.projectiles -ne 1 -or [double]$Plasma.energy_cost -le [double]$Storm.energy_cost) { throw 'Plasma Lance identity invalid.' }

if (@($Generators.generators).Count -lt 5) { throw 'Generator progression requires five tiers.' }
$PreviousCost=-1; $PreviousCapacity=0.0; $PreviousRecharge=0.0
foreach ($Generator in $Generators.generators) {
    if ([int]$Generator.cost -lt $PreviousCost -or [double]$Generator.capacity -lt $PreviousCapacity -or [double]$Generator.recharge_per_second -lt $PreviousRecharge) { throw "Generator progression regresses: $($Generator.id)" }
    if (-not $EraOrder.ContainsKey([string]$Generator.unlock_tech_era) -or -not $EraOrder.ContainsKey([string]$Generator.efficiency_tech_era)) { throw "Generator era invalid: $($Generator.id)" }
    $PreviousCost=[int]$Generator.cost; $PreviousCapacity=[double]$Generator.capacity; $PreviousRecharge=[double]$Generator.recharge_per_second
}

if (@($Airframes.airframes).Count -ne 5) { throw 'VX-94 requires exactly five airframe tiers.' }
$PreviousCost=-1; $PreviousHull=0; $PreviousShield=0; $PreviousDamage=1.0
foreach ($Frame in $Airframes.airframes) {
    if ([int]$Frame.cost -lt $PreviousCost -or [int]$Frame.hull_capacity -lt $PreviousHull -or [int]$Frame.shield_capacity -lt $PreviousShield) { throw "Airframe capacity/cost regresses: $($Frame.id)" }
    if ([double]$Frame.incoming_damage_multiplier -gt $PreviousDamage -or [double]$Frame.incoming_damage_multiplier -lt 0.65 -or [double]$Frame.incoming_damage_multiplier -gt 1.0) { throw "Airframe resistance invalid: $($Frame.id)" }
    if (-not $EraOrder.ContainsKey([string]$Frame.unlock_tech_era)) { throw "Airframe era invalid: $($Frame.id)" }
    $PreviousCost=[int]$Frame.cost; $PreviousHull=[int]$Frame.hull_capacity; $PreviousShield=[int]$Frame.shield_capacity; $PreviousDamage=[double]$Frame.incoming_damage_multiplier
}

if (@($Supports.supports).Count -ne 7) { throw 'Tactical catalogue requires exactly seven systems.' }
$AllowedSupportTypes = @('rockets','crossfire','hunter','defence','emp','magnetic')
$PreviousCost=-1
foreach ($Support in $Supports.supports) {
    if ($AllowedSupportTypes -notcontains [string]$Support.type) { throw "Unsupported tactical type: $($Support.id)" }
    if ([int]$Support.cost -lt $PreviousCost -or [double]$Support.energy_cost -le 0 -or [double]$Support.cooldown -le 0) { throw "Invalid tactical economy: $($Support.id)" }
    if (-not $EraOrder.ContainsKey([string]$Support.unlock_tech_era)) { throw "Tactical support era invalid: $($Support.id)" }
    $PreviousCost=[int]$Support.cost
}
$Micro = @($Supports.supports | Where-Object { $_.id -eq 'micro_warhead_rack' })[0]
if ([string]$Micro.unlock_tech_era -ne 'strategic_orbital' -or -not [bool]$Micro.strategic -or [double]$Micro.cooldown -lt 900 -or [int]$Micro.damage -lt 20) { throw 'Micro-Warhead strategic identity invalid.' }

if (@($World.altitude_bands).Count -ne 4) { throw 'Campaign world must define four altitude bands.' }
if ([string]$PlayerCraft.craft.id -ne 'vx_94_strikewing') { throw 'VX-94 craft identity missing.' }
$BattlefieldSupportIds = @($BattlefieldSupports.supports | ForEach-Object { $_.id })
foreach ($Id in @('spectre_gunship','atlas_tanker','rapier_flight','hammer_bomber_flight','cruise_missile_support','rail_support','orbital_strike')) { if ($BattlefieldSupportIds -notcontains $Id) { throw "Missing battlefield support: $Id" } }

$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id }); $BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
foreach ($Id in @('drone_scout','drone_hunter','drone_bomber','drone_missile_node','autonomous_armor','factory_defence_node','exo_drone','orbital_sentry','phase_interceptor','beam_sentry','orbital_lancer','swarm_controller','ai_forge_core','orbital_command_node','phase_control_array','station_warden','machine_ark')) { if ($EnemyIds -notcontains $Id) { throw "Missing autonomous enemy/boss: $Id" } }
foreach ($Enemy in $Enemies.enemies) { if ($Enemy.faction -eq 'autonomous' -and ([double]$Enemy.emp_resistance -lt 0 -or [double]$Enemy.emp_resistance -gt 0.95)) { throw "EMP resistance out of range: $($Enemy.id)" } }

if (@($Missions.missions).Count -ne 12) { throw 'Campaign requires exactly twelve authored missions.' }
$MissionIds = @($Missions.missions | ForEach-Object { $_.id })
foreach ($Mission in $Missions.missions) {
    if ([int]$Mission.duration_seconds -le 0 -or [int]$Mission.starting_wave -lt 1) { throw "Invalid mission timing/wave: $($Mission.id)" }
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Unknown boss: $($Mission.boss_id)" }
    $Beats=@($Mission.encounter_beats); if ($Beats.Count -lt 5) { throw "Mission lacks encounter beats: $($Mission.id)" }; Assert-UniqueIds $Beats "mission $($Mission.id) beats"
    $Last=-1.0; $HasReward=$false; $HasSecret=$false; $HasPacing=$false; $Forms=@{}
    foreach ($Beat in $Beats) {
        if ([double]$Beat.at_seconds -le $Last -or [double]$Beat.at_seconds -ge [double]$Mission.duration_seconds) { throw "Encounter timing invalid: $($Mission.id)/$($Beat.id)" }; $Last=[double]$Beat.at_seconds
        if ($Beat.pickup) { $HasReward=$true }; if ([bool]$Beat.secret) { $HasSecret=$true }; if ([double]$Beat.suppress_random_seconds -ge 2) { $HasPacing=$true }; $Forms[[string]$Beat.formation]=$true
        $Count=0; foreach ($Entry in @($Beat.enemies)) { if ($EnemyIds -notcontains $Entry.id -or $BossIds -contains $Entry.id -or [int]$Entry.count -lt 1) { throw "Invalid encounter enemy: $($Mission.id)/$($Beat.id)" }; $Count += [int]$Entry.count }; if ($Count -gt 12) { throw "Encounter cap exceeded: $($Mission.id)/$($Beat.id)" }
    }
    if (-not $HasReward -or -not $HasSecret -or -not $HasPacing -or $Forms.Keys.Count -lt 3) { throw "Mission lacks authored pacing variety: $($Mission.id)" }
    $Context=Mission-Context $World ([string]$Mission.id); if ($null -eq $Context) { throw "Missing mission context: $($Mission.id)" }; if (-not $EraOrder.ContainsKey([string]$Context.tech_era)) { throw "Invalid mission era: $($Mission.id)" }
}

foreach ($Id in @('m01_coastal_intercept','m02_refinery_run','m03_black_sea','m04_breakwater','m05_furnace_line','m06_black_flag')) { if ([string](Mission-Context $World $Id).threat_phase -ne 'mercenary_war') { throw "$Id must remain mercenary war." } }
foreach ($Id in @('m07_ghost_sky','m08_machine_furnace','m09_black_horizon','m10_blue_fire','m11_cold_station','m12_machine_ark')) { if ([string](Mission-Context $World $Id).threat_phase -ne 'drone_war') { throw "$Id must remain drone war." } }
foreach ($Id in @('m07_ghost_sky','m08_machine_furnace')) { if ([string](Mission-Context $World $Id).tech_era -ne 'electromagnetic') { throw "$Id must remain EM era." } }
foreach ($Id in @('m09_black_horizon','m10_blue_fire','m11_cold_station')) { if ([string](Mission-Context $World $Id).tech_era -ne 'directed_energy') { throw "$Id must remain DE era." } }
$MachineContext=Mission-Context $World 'm12_machine_ark'
if ([string]$MachineContext.tech_era -ne 'strategic_orbital' -or [string]$MachineContext.altitude -ne 'high') { throw 'Machine Ark must start HIGH in strategic-orbital era.' }
if ([int]$MachineContext.altitude_transitions[0].at_seconds -ne 156 -or [string]$MachineContext.altitude_transitions[0].altitude -ne 'orbital') { throw 'Machine Ark must burn to orbit at 156 seconds.' }
if (@($MachineContext.support) -notcontains 'atlas_tanker') { throw 'Machine Ark must retain Atlas tanker before orbital burn.' }

$CampaignMissionIds=@($Campaign.campaign.missions); if ($CampaignMissionIds.Count -ne 12 -or @($CampaignMissionIds | Sort-Object -Unique).Count -ne 12) { throw 'Campaign ordering must contain 12 unique missions.' }; foreach ($Id in $CampaignMissionIds) { if ($MissionIds -notcontains $Id) { throw "Unknown campaign mission: $Id" } }

foreach ($Profile in $Profiles.profiles) { if ([int]$Profile.min_wave -gt [int]$Profile.max_wave -or @($Profile.enemy_ids).Count -lt 1) { throw "Invalid spawn profile: $($Profile.id)" }; foreach ($EnemyId in $Profile.enemy_ids) { if ($EnemyIds -notcontains $EnemyId -or $BossIds -contains $EnemyId) { throw "Invalid spawn enemy: $($Profile.id) -> $EnemyId" } } }
foreach ($Environment in @($Missions.missions | ForEach-Object { $_.environment } | Sort-Object -Unique)) {
    $Ranges=@($Profiles.profiles | Where-Object { $_.environment -eq $Environment } | Sort-Object min_wave); if ($Ranges.Count -lt 1) { throw "No spawn profile for environment: $Environment" }; $Next=1
    foreach ($Range in $Ranges) { if ([int]$Range.min_wave -gt $Next) { throw "Spawn gap for $Environment before wave $Next" }; $Next=[Math]::Max($Next,[int]$Range.max_wave+1) }; if ($Next -lt 100) { throw "Spawn coverage for $Environment ends before wave 99." }
}

$ProjectText=Get-Content -Raw (Join-Path $Root 'project.godot')
foreach ($Autoload in @(
    'SupportDirector="*res://scripts/support_director.gd"','CampaignSave="*res://scripts/campaign_save.gd"','EncounterDirector="*res://scripts/encounter_director.gd"',
    'CraftFormDirector="*res://scripts/craft_form_director.gd"','AirframeDirector="*res://scripts/airframe_director.gd"','EnvironmentDirector="*res://scripts/environment_director.gd"',
    'BattlefieldSupportDirector="*res://scripts/battlefield_support_director.gd"','CombatArtDirector="*res://scripts/combat_art_director.gd"','AirframeCueDirector="*res://scripts/airframe_cue_director.gd"',
    'AfterburnerCueDirector="*res://scripts/afterburner_cue_director.gd"','StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"','ElectromagneticCueDirector="*res://scripts/electromagnetic_cue_director.gd"',
    'StrategicWarheadDirector="*res://scripts/strategic_warhead_director.gd"','DirectedEnergyDirector="*res://scripts/directed_energy_director.gd"','BossDirector="*res://scripts/boss_director.gd"',
    'MissionIntelDirector="*res://scripts/mission_intel_director.gd"','PixelUiDirector="*res://scripts/pixel_ui_director.gd"','ProjectileCueDirector="*res://scripts/projectile_cue_director.gd"'
)) { if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" } }

$CraftText=Get-Content -Raw (Join-Path $Root 'scripts/craft_form_director.gd')
Assert-Contains $CraftText @('AFTERBURNER_CAPACITY := 8.0','KEY_SHIFT','refuel_afterburner_full','_afterburner_burn_rate','TRANSFORM_WEAPON_INTERLOCK') 'VX-94 flight runtime'
$SupportText=Get-Content -Raw (Join-Path $Root 'scripts/support_director.gd')
Assert-Contains $SupportText @('micro_warhead_rack','strategic_support','refuel_afterburner_full','_reset_sortie_state') 'Tactical support runtime'
$StrategicText=Get-Content -Raw (Join-Path $Root 'scripts/strategic_warhead_director.gd')
Assert-Contains $StrategicText @('StrategicWarheadRules.BLAST_RADIUS','strategic_burst','hp - 1','BLAST_SECONDS := 0.22') 'Strategic warhead runtime'
$IntelText=Get-Content -Raw (Join-Path $Root 'scripts/mission_intel_director.gd')
Assert-Contains $IntelText @('KEY_I','MISSION INTELLIGENCE','MissionIntelRules.mission_lines') 'Mission intel'
$AirframeText=Get-Content -Raw (Join-Path $Root 'scripts/airframe_director.gd')
Assert-Contains $AirframeText @('KEY_K','MissionStateRules.set_airframe_context','CombatRules.set_incoming_damage_multiplier') 'Airframe runtime'
$SaveText=Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd')
Assert-Contains $SaveText @('SAVE_VERSION := 5','airframe_index','restore_airframe_state','SaveRecoveryRules.choose_primary_or_backup') 'Campaign save'
$PixelText=Get-Content -Raw (Join-Path $Root 'scripts/pixel_ui_director.gd')
foreach ($Widget in @('PanelContainer.new()','Label.new()','ProgressBar.new()')) { if ($PixelText.Contains($Widget)) { throw "Primary pixel UI contains widget chrome: $Widget" } }

$Godot=Resolve-Godot -Preferred $GodotBin
if (-not $Godot) { Write-Warning 'Godot executable not found. Structural/data/save/12-mission/strategic VX-94 validation passed; engine tests skipped.'; exit 0 }
$Tests=@(
    'runtime_self_test.gd','reward_self_test.gd','service_self_test.gd','mission_flow_self_test.gd','save_recovery_self_test.gd',
    'encounter_self_test.gd','support_self_test.gd','craft_form_self_test.gd','battlefield_support_self_test.gd','environment_self_test.gd',
    'strike_ordnance_self_test.gd','tech_progression_self_test.gd','boss_signature_self_test.gd','combat_art_self_test.gd','afterburner_self_test.gd'
)
foreach ($Test in $Tests) { Write-Host "Running $Test..." -ForegroundColor DarkCyan; & $Godot --headless --path $Root --script "res://tools/$Test"; if ($LASTEXITCODE -ne 0) { throw "$Test failed with exit code $LASTEXITCODE" } }
Write-Host 'Running Godot editor smoke test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }
Write-Host 'Strike Wing 94 validation passed.' -ForegroundColor Green
