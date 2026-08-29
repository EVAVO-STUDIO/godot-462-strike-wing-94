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
    'scripts/boss_rules.gd','scripts/boss_director.gd','scripts/boss_hud_rules.gd','scripts/boss_hud_director.gd',
    'scripts/bomb_rules.gd','scripts/campaign_save.gd','scripts/save_recovery_rules.gd','scripts/run_seed_rules.gd',
    'scripts/mission_state_rules.gd','scripts/mission_flow_rules.gd','scripts/movement_pattern_rules.gd','scripts/weapon_pickup_rules.gd',
    'scripts/accuracy_rules.gd','scripts/reward_rules.gd','scripts/service_rules.gd','scripts/energy_rules.gd',
    'scripts/projectile_cue_rules.gd','scripts/projectile_cue_director.gd','scripts/threat_warning_rules.gd','scripts/threat_warning_director.gd',
    'tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd','tools/save_recovery_self_test.gd',
    'data/weapons.json','data/generators.json','data/enemies.json','data/missions.json','data/spawn_profiles.json','data/campaign.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md'
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
    'scripts/accuracy_director.gd','scripts/reward_director.gd','scripts/service_director.gd'
)
foreach ($RelativePath in $Forbidden) {
    if (Test-Path (Join-Path $Root $RelativePath)) { throw "Forbidden generated/obsolete path committed: $RelativePath" }
}

$Weapons = Get-Content -Raw (Join-Path $Root 'data/weapons.json') | ConvertFrom-Json
$Generators = Get-Content -Raw (Join-Path $Root 'data/generators.json') | ConvertFrom-Json
$Enemies = Get-Content -Raw (Join-Path $Root 'data/enemies.json') | ConvertFrom-Json
$Missions = Get-Content -Raw (Join-Path $Root 'data/missions.json') | ConvertFrom-Json
$Profiles = Get-Content -Raw (Join-Path $Root 'data/spawn_profiles.json') | ConvertFrom-Json
$Campaign = Get-Content -Raw (Join-Path $Root 'data/campaign.json') | ConvertFrom-Json

Assert-UniqueIds $Weapons.weapons 'weapons'
Assert-UniqueIds $Generators.generators 'generators'
Assert-UniqueIds $Enemies.enemies 'enemies'
Assert-UniqueIds $Missions.missions 'missions'
Assert-UniqueIds $Profiles.profiles 'spawn profiles'

$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' })
if ($Primaries.Count -lt 5) { throw 'Campaign should expose at least five meaningfully distinct primary tiers.' }
$PreviousCost = -1
foreach ($Weapon in $Primaries) {
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary weapon costs out of order: $($Weapon.id)" }
    if ([int]$Weapon.damage -le 0 -or [double]$Weapon.projectile_speed -le 0 -or [double]$Weapon.fire_interval -le 0 -or [int]$Weapon.projectiles -le 0) { throw "Invalid primary weapon values: $($Weapon.id)" }
    if ([double]$Weapon.energy_cost -le 0) { throw "Primary weapon must consume energy: $($Weapon.id)" }
    if (-not $Weapon.archetype) { throw "Primary weapon missing gameplay archetype: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}

if (@($Generators.generators).Count -lt 3) { throw 'Generator progression requires at least three tiers.' }
$PreviousCost = -1; $PreviousCapacity = 0.0; $PreviousRecharge = 0.0
foreach ($Generator in $Generators.generators) {
    if ([int]$Generator.cost -lt $PreviousCost) { throw "Generator costs out of order: $($Generator.id)" }
    if ([double]$Generator.capacity -le 0 -or [double]$Generator.recharge_per_second -le 0) { throw "Invalid generator values: $($Generator.id)" }
    if ([double]$Generator.capacity -lt $PreviousCapacity -or [double]$Generator.recharge_per_second -lt $PreviousRecharge) { throw "Generator progression regresses output: $($Generator.id)" }
    $PreviousCost = [int]$Generator.cost
    $PreviousCapacity = [double]$Generator.capacity
    $PreviousRecharge = [double]$Generator.recharge_per_second
}

$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id })
$BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
$AllowedClasses = @('air','ground','sea','boss')
$AllowedEnemyWeapons = @('single_burst','aimed_burst','side_burst','cannon','missile','deck_gun','twin_burst')
$AllowedPatterns = @('sine_dive','tracking_sweep','hover_strafe','road_column','water_lane','static','aggressive_weave','boss_sweep','boss_column','boss_broadside')
foreach ($Enemy in $Enemies.enemies) {
    if ($AllowedClasses -notcontains $Enemy.class) { throw "Unknown enemy class: $($Enemy.id)" }
    if ($AllowedEnemyWeapons -notcontains $Enemy.weapon) { throw "Unsupported enemy weapon: $($Enemy.id) -> $($Enemy.weapon)" }
    if ($AllowedPatterns -notcontains $Enemy.pattern) { throw "Unsupported enemy pattern: $($Enemy.id) -> $($Enemy.pattern)" }
    if ([int]$Enemy.hp -le 0 -or [int]$Enemy.value -le 0 -or [double]$Enemy.speed -lt 0) { throw "Invalid enemy combat values: $($Enemy.id)" }
    if ([bool]$Enemy.boss -and ([int]$Enemy.phases -ne 3 -or [int]$Enemy.weak_point_phase -lt 1 -or [int]$Enemy.weak_point_phase -gt 3)) { throw "Invalid boss phase data: $($Enemy.id)" }
}

$MissionIds = @($Missions.missions | ForEach-Object { $_.id })
foreach ($Mission in $Missions.missions) {
    if ([int]$Mission.duration_seconds -le 0 -or [int]$Mission.starting_wave -lt 1) { throw "Invalid mission timing/wave: $($Mission.id)" }
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Unknown mission boss: $($Mission.boss_id)" }
    if (@($Mission.objectives).Count -lt 1) { throw "Mission has no objectives: $($Mission.id)" }
    Assert-UniqueIds @($Mission.objectives) "mission $($Mission.id) objectives"
    if (@($Mission.objectives | Where-Object { $_.required }).Count -lt 1) { throw "Mission has no required objective: $($Mission.id)" }
}

$CampaignMissionIds = @($Campaign.campaign.missions)
foreach ($MissionId in $CampaignMissionIds) { if ($MissionIds -notcontains $MissionId) { throw "Campaign references unknown mission: $MissionId" } }
if (@($CampaignMissionIds | Sort-Object -Unique).Count -ne $CampaignMissionIds.Count) { throw 'Campaign mission list contains duplicates.' }
if ([int]$Campaign.campaign.starting_hull -lt 1 -or [int]$Campaign.campaign.starting_shield -lt 0) { throw 'Invalid campaign starting airframe values.' }

foreach ($Profile in $Profiles.profiles) {
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave) { throw "Invalid spawn wave range: $($Profile.id)" }
    if (@($Profile.enemy_ids).Count -lt 1) { throw "Spawn profile has no enemies: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) {
        if ($EnemyIds -notcontains $EnemyId) { throw "Spawn profile references unknown enemy: $EnemyId" }
        if ($BossIds -contains $EnemyId) { throw "Spawn profile includes mission boss: $EnemyId" }
    }
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

$ProjectText = Get-Content -Raw (Join-Path $Root 'project.godot')
foreach ($Autoload in @(
    'CampaignSave="*res://scripts/campaign_save.gd"',
    'BossDirector="*res://scripts/boss_director.gd"',
    'BossHudDirector="*res://scripts/boss_hud_director.gd"',
    'ThreatWarningDirector="*res://scripts/threat_warning_director.gd"',
    'ProjectileCueDirector="*res://scripts/projectile_cue_director.gd"'
)) { if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" } }
foreach ($Obsolete in @('ServiceDirector','RewardDirector','AccuracyDirector','WeaponPickupDirector','RunSeedDirector','MovementPatternDirector','MissionFlowDirector','MissionStateDirector','BombGuardDirector','MissileBehaviorDirector','SpawnSafetyDirector')) {
    if ($ProjectText.Contains($Obsolete)) { throw "Obsolete autoload must remain removed: $Obsolete" }
}

$MainText = Get-Content -Raw (Join-Path $Root 'scripts/main.gd')
Assert-Contains $MainText @(
    'const EnergyRules = preload','const ServiceRules = preload',
    'var service_hull := 100','var service_shield := 100','var generator_index := 0','var energy := 100.0',
    'EnergyRules.recharge(energy, _active_generator(), delta)','EnergyRules.can_fire(energy, weapon)','EnergyRules.consume(energy, weapon)',
    'RewardRules.extra_success_bonus','credits += total_reward','service_hull = clampi(hull','service_shield = clampi(shield',
    'MovementPatternRules.adjusted_position','mission_rng.seed = RunSeedRules.mission_seed(mission_index)',
    'MissionFlowRules.should_hold_overtime','BombRules.apply_nonlethal_boss_damage','temporary_weapon_boost',
    '_try_buy_next_generator()','_service_hull_full()','_service_shield_full()'
) 'Main gameplay'
foreach ($Token in @('ServiceDirector','RewardDirector','AccuracyDirector','WeaponPickupDirector','RunSeedDirector','MovementPatternDirector','MissionFlowDirector','MissionStateDirector','BombGuardDirector','MissileBehaviorDirector','SpawnSafetyDirector')) {
    if ($MainText.Contains($Token)) { throw "Main gameplay still references obsolete reconciliation layer: $Token" }
}

$SaveText = Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd')
Assert-Contains $SaveText @('SAVE_VERSION := 3','BACKUP_PATH','generator_index','service_hull','service_shield','SaveRecoveryRules.choose_primary_or_backup') 'Campaign save'
if ($SaveText.Contains('ServiceDirector')) { throw 'Campaign save must not depend on ServiceDirector.' }

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural/data/save validation passed; headless self-tests and engine smoke test skipped.'
    exit 0
}

$Tests = @(
    'runtime_self_test.gd',
    'reward_self_test.gd',
    'service_self_test.gd',
    'mission_flow_self_test.gd',
    'save_recovery_self_test.gd'
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
