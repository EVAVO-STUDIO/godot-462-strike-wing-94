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
    'scripts/directed_energy_rules.gd','scripts/directed_energy_director.gd',
    'scripts/strategic_warhead_rules.gd','scripts/strategic_warhead_surface.gd','scripts/strategic_warhead_director.gd',
    'scripts/encounter_rules.gd','scripts/encounter_director.gd','scripts/support_rules.gd','scripts/support_director.gd',
    'scripts/craft_form_rules.gd','scripts/altitude_rules.gd','scripts/craft_form_director.gd',
    'scripts/altitude_transition_surface.gd','scripts/altitude_transition_director.gd',
    'scripts/environment_rules.gd','scripts/environment_surface.gd','scripts/environment_director.gd',
    'scripts/battlefield_support_rules.gd','scripts/battlefield_support_surface.gd','scripts/battlefield_support_director.gd',
    'scripts/strike_ordnance_rules.gd','scripts/strike_ordnance_surface.gd','scripts/strike_ordnance_director.gd',
    'scripts/electromagnetic_cue_surface.gd','scripts/electromagnetic_cue_director.gd',
    'scripts/combat_art_surface.gd','scripts/combat_art_director.gd',
    'scripts/airframe_cue_surface.gd','scripts/airframe_cue_director.gd',
    'scripts/afterburner_cue_surface.gd','scripts/afterburner_cue_director.gd',
    'scripts/weapon_mount_cue_surface.gd','scripts/weapon_mount_cue_director.gd',
    'scripts/mission_intel_rules.gd','scripts/mission_intel_surface.gd','scripts/mission_intel_director.gd',
    'scripts/retro_sfx_rules.gd','scripts/retro_sfx_director.gd',
    'scripts/pixel_font.gd','scripts/pixel_ui_surface.gd','scripts/pixel_ui_director.gd',
    'scripts/projectile_cue_rules.gd','scripts/projectile_cue_director.gd','scripts/threat_warning_rules.gd',
    'tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd','tools/save_recovery_self_test.gd',
    'tools/encounter_self_test.gd','tools/support_self_test.gd','tools/craft_form_self_test.gd','tools/battlefield_support_self_test.gd','tools/environment_self_test.gd',
    'tools/strike_ordnance_self_test.gd','tools/tech_progression_self_test.gd','tools/boss_signature_self_test.gd','tools/combat_art_self_test.gd','tools/afterburner_self_test.gd',
    'data/weapons.json','data/generators.json','data/airframes.json','data/support_systems.json','data/battlefield_support.json','data/enemies.json','data/missions.json',
    'data/spawn_profiles.json','data/environment_profiles.json','data/campaign.json','data/campaign_world.json','data/player_craft.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md','docs/90S_SHOOTER_BIBLE.md','docs/CAMPAIGN_CANON.md','docs/CRAFT_ALTITUDE_SYSTEM.md','docs/VX94_COMBAT_ART_DIRECTION.md','docs/STRATEGIC_ORBITAL_ENDGAME.md'
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
$Enemies = Get-Content -Raw (Join-Path $Root 'data/enemies.json') | ConvertFrom-Json
$Missions = Get-Content -Raw (Join-Path $Root 'data/missions.json') | ConvertFrom-Json
$Profiles = Get-Content -Raw (Join-Path $Root 'data/spawn_profiles.json') | ConvertFrom-Json
$Campaign = Get-Content -Raw (Join-Path $Root 'data/campaign.json') | ConvertFrom-Json
$World = Get-Content -Raw (Join-Path $Root 'data/campaign_world.json') | ConvertFrom-Json
$BattlefieldSupports = Get-Content -Raw (Join-Path $Root 'data/battlefield_support.json') | ConvertFrom-Json

Assert-UniqueIds $Weapons.weapons 'weapons'
Assert-UniqueIds $Generators.generators 'generators'
Assert-UniqueIds $Airframes.airframes 'airframes'
Assert-UniqueIds $Supports.supports 'support systems'
Assert-UniqueIds $Enemies.enemies 'enemies'
Assert-UniqueIds $Missions.missions 'missions'
Assert-UniqueIds $Profiles.profiles 'spawn profiles'

$EraOrder = @{ advanced_conventional=1; electromagnetic=2; directed_energy=3; strategic_orbital=4 }
$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' })
if ($Primaries.Count -ne 8) { throw 'Campaign requires exactly eight primary weapon tiers.' }
$Rail = @($Primaries | Where-Object { $_.id -eq 'needle_rail' })[0]
$Storm = @($Primaries | Where-Object { $_.id -eq 'storm_cannon' })[0]
$Plasma = @($Primaries | Where-Object { $_.id -eq 'plasma_lance' })[0]
if ([int]$Rail.pierce -ne 2 -or [string]$Rail.unlock_tech_era -ne 'electromagnetic') { throw 'Needle Rail identity invalid.' }
if ([string]$Storm.archetype -ne 'directed_energy_pulse' -or [string]$Storm.unlock_tech_era -ne 'directed_energy') { throw 'Storm Cannon identity invalid.' }
if ([string]$Plasma.archetype -ne 'strategic_plasma' -or [string]$Plasma.unlock_tech_era -ne 'strategic_orbital') { throw 'Plasma Lance identity invalid.' }

if (@($Generators.generators).Count -lt 5) { throw 'Generator progression requires at least five tiers.' }
if (@($Airframes.airframes).Count -ne 5) { throw 'VX-94 requires exactly five airframe tiers.' }
if (@($Supports.supports).Count -ne 7) { throw 'Tactical catalogue requires exactly seven systems.' }
$Micro = @($Supports.supports | Where-Object { $_.id -eq 'micro_warhead_rack' })[0]
if ([string]$Micro.unlock_tech_era -ne 'strategic_orbital' -or -not [bool]$Micro.strategic -or [double]$Micro.cooldown -lt 900) { throw 'Micro-Warhead strategic identity invalid.' }

if (@($Missions.missions).Count -ne 12) { throw 'Campaign requires exactly twelve authored missions.' }
$MissionIds = @($Missions.missions | ForEach-Object { $_.id })
$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id })
$BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
foreach ($Mission in $Missions.missions) {
    if ([int]$Mission.duration_seconds -le 0 -or [int]$Mission.starting_wave -lt 1) { throw "Invalid mission timing/wave: $($Mission.id)" }
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Unknown mission boss: $($Mission.boss_id)" }
    $Beats = @($Mission.encounter_beats)
    if ($Beats.Count -lt 5) { throw "Mission lacks authored encounter beats: $($Mission.id)" }
    Assert-UniqueIds $Beats "mission $($Mission.id) beats"
    $Context = Mission-Context $World ([string]$Mission.id)
    if ($null -eq $Context) { throw "Missing mission context: $($Mission.id)" }
    if (-not $EraOrder.ContainsKey([string]$Context.tech_era)) { throw "Invalid mission era: $($Mission.id)" }
    foreach ($Window in @($Context.altitude_choice_windows)) {
        if ([double]$Window.end_seconds -le [double]$Window.start_seconds) { throw "Invalid altitude choice window: $($Mission.id)" }
        $Bands = @($Window.bands)
        if ($Bands.Count -lt 2) { throw "Altitude choice window needs multiple lanes: $($Mission.id)" }
        foreach ($Band in $Bands) { if (@('low','mid','high','orbital') -notcontains [string]$Band) { throw "Invalid altitude lane: $($Mission.id) -> $Band" } }
    }
}

$MachineContext = Mission-Context $World 'm12_machine_ark'
if ([string]$MachineContext.altitude -ne 'high' -or [string]$MachineContext.tech_era -ne 'strategic_orbital') { throw 'Machine Ark must begin HIGH in strategic-orbital era.' }
if ([int]$MachineContext.altitude_transitions[0].at_seconds -ne 156 -or [string]$MachineContext.altitude_transitions[0].altitude -ne 'orbital') { throw 'Machine Ark must burn to orbit at 156 seconds.' }
if (@($MachineContext.support) -notcontains 'atlas_tanker') { throw 'Machine Ark must retain Atlas tanker before orbital burn.' }

$CampaignMissionIds = @($Campaign.campaign.missions)
if ($CampaignMissionIds.Count -ne 12 -or @($CampaignMissionIds | Sort-Object -Unique).Count -ne 12) { throw 'Campaign order must contain 12 unique missions.' }
foreach ($Id in $CampaignMissionIds) { if ($MissionIds -notcontains $Id) { throw "Unknown campaign mission: $Id" } }

foreach ($Profile in $Profiles.profiles) {
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave -or @($Profile.enemy_ids).Count -lt 1) { throw "Invalid spawn profile: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) { if ($EnemyIds -notcontains $EnemyId -or $BossIds -contains $EnemyId) { throw "Invalid spawn enemy: $($Profile.id) -> $EnemyId" } }
}

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
    'AirframeCueDirector="*res://scripts/airframe_cue_director.gd"',
    'AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"',
    'AfterburnerCueDirector="*res://scripts/afterburner_cue_director.gd"',
    'WeaponMountCueDirector="*res://scripts/weapon_mount_cue_director.gd"',
    'StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"',
    'ElectromagneticCueDirector="*res://scripts/electromagnetic_cue_director.gd"',
    'StrategicWarheadDirector="*res://scripts/strategic_warhead_director.gd"',
    'DirectedEnergyDirector="*res://scripts/directed_energy_director.gd"',
    'BossDirector="*res://scripts/boss_director.gd"',
    'MissionIntelDirector="*res://scripts/mission_intel_director.gd"',
    'PixelUiDirector="*res://scripts/pixel_ui_director.gd"',
    'ProjectileCueDirector="*res://scripts/projectile_cue_director.gd"',
    'RetroSfxDirector="*res://scripts/retro_sfx_director.gd"'
)) { if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" } }

$CraftText = Get-Content -Raw (Join-Path $Root 'scripts/craft_form_director.gd')
Assert-Contains $CraftText @(
    'KEY_PAGEUP','KEY_PAGEDOWN','_try_manual_altitude','_begin_altitude_transition',
    'primary_mount_offsets','bomber_rotary_deployed','AFTERBURNER_CAPACITY := 8.0'
) 'VX-94 craft runtime'

$AltitudeText = Get-Content -Raw (Join-Path $Root 'scripts/altitude_rules.gd')
Assert-Contains $AltitudeText @('TRANSITION_SECONDS := 1.15','adjacent_band','is_adjacent','transition_ground_scale') 'Altitude rules'

$MainText = Get-Content -Raw (Join-Path $Root 'scripts/main.gd')
Assert-Contains $MainText @(
    '_craft_primary_mount_offsets(weapon, count)',
    '"position": player_position + mount_offsets[i]',
    'TECH LOCK - %s',
    'mission_rng.seed = RunSeedRules.mission_seed(mission_index)'
) 'Main gameplay'

$CombatArtText = Get-Content -Raw (Join-Path $Root 'scripts/combat_art_director.gd')
Assert-Contains $CombatArtText @(
    'TRANSFORM_VISUAL_SECONDS := 0.42',
    '_draw_rotary_cannon',
    'fighter_tip_l.lerp(bomber_tip_l, t)',
    'Under-wing hardpoints',
    'AltitudeRules.transition_ground_scale'
) 'VX-94 combat art'

$MountCueText = Get-Content -Raw (Join-Path $Root 'scripts/weapon_mount_cue_director.gd')
Assert-Contains $MountCueText @('_draw_rotary_flash','primary_mount_offsets','bomber_rotary_deployed','FLASH_SECONDS') 'Weapon mount cues'

$AltitudeCueText = Get-Content -Raw (Join-Path $Root 'scripts/altitude_transition_director.gd')
Assert-Contains $AltitudeCueText @('PGUP','PGDN','CLIMB','DIVE','altitude_choice_available') 'Altitude transition presentation'

$SfxText = Get-Content -Raw (Join-Path $Root 'scripts/retro_sfx_rules.gd')
Assert-Contains $SfxText @('FIRE_ROTARY','ALTITUDE_CLIMB','ALTITUDE_DIVE','wave":"rotary"') 'Retro SFX rules'

$SaveText = Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd')
Assert-Contains $SaveText @('SAVE_VERSION := 5','airframe_index','restore_airframe_state','SaveRecoveryRules.choose_primary_or_backup') 'Campaign save'

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural/data/save/transform/altitude-lane validation passed; engine tests skipped.'
    exit 0
}

$Tests = @(
    'runtime_self_test.gd','reward_self_test.gd','service_self_test.gd','mission_flow_self_test.gd','save_recovery_self_test.gd',
    'encounter_self_test.gd','support_self_test.gd','craft_form_self_test.gd','battlefield_support_self_test.gd','environment_self_test.gd',
    'strike_ordnance_self_test.gd','tech_progression_self_test.gd','boss_signature_self_test.gd','combat_art_self_test.gd','afterburner_self_test.gd'
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
