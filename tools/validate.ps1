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

Write-Host 'Validating Strike Wing 94...' -ForegroundColor Cyan
$Required = @(
    'project.godot','scenes/main.tscn','scripts/main.gd','scripts/content_catalog.gd',
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd','scripts/objective_rules.gd',
    'scripts/boss_rules.gd','scripts/boss_director.gd','scripts/bomb_rules.gd','scripts/bomb_guard_director.gd',
    'scripts/campaign_save.gd','scripts/run_seed_rules.gd','scripts/run_seed_director.gd',
    'scripts/mission_state_rules.gd','scripts/mission_state_director.gd','scripts/mission_flow_rules.gd','scripts/mission_flow_director.gd',
    'scripts/movement_pattern_rules.gd','scripts/movement_pattern_director.gd',
    'scripts/weapon_pickup_rules.gd','scripts/weapon_pickup_director.gd',
    'scripts/accuracy_rules.gd','scripts/accuracy_director.gd','scripts/reward_rules.gd','scripts/reward_director.gd',
    'scripts/service_rules.gd','scripts/service_director.gd',
    'tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd',
    'data/weapons.json','data/enemies.json','data/missions.json','data/spawn_profiles.json','data/campaign.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md'
)
foreach ($RelativePath in $Required) {
    if (-not (Test-Path (Join-Path $Root $RelativePath))) { throw "Missing required file: $RelativePath" }
}
foreach ($Forbidden in @('.github/workflows','.godot','build','dist')) {
    if (Test-Path (Join-Path $Root $Forbidden)) { throw "Forbidden generated/paid-CI path committed: $Forbidden" }
}

$Weapons = Get-Content -Raw (Join-Path $Root 'data/weapons.json') | ConvertFrom-Json
$Enemies = Get-Content -Raw (Join-Path $Root 'data/enemies.json') | ConvertFrom-Json
$Missions = Get-Content -Raw (Join-Path $Root 'data/missions.json') | ConvertFrom-Json
$Profiles = Get-Content -Raw (Join-Path $Root 'data/spawn_profiles.json') | ConvertFrom-Json
$Campaign = Get-Content -Raw (Join-Path $Root 'data/campaign.json') | ConvertFrom-Json
Assert-UniqueIds $Weapons.weapons 'weapons'
Assert-UniqueIds $Enemies.enemies 'enemies'
Assert-UniqueIds $Missions.missions 'missions'
Assert-UniqueIds $Profiles.profiles 'spawn profiles'

$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id })
$BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
$AllowedClasses = @('air','ground','sea','boss')
$AllowedEnemyWeapons = @('single_burst','aimed_burst','side_burst','cannon','missile','deck_gun','twin_burst')
$AllowedPatterns = @('sine_dive','tracking_sweep','hover_strafe','road_column','water_lane','static','aggressive_weave','boss_sweep','boss_column','boss_broadside')
foreach ($Enemy in $Enemies.enemies) {
    if ($AllowedClasses -notcontains $Enemy.class) { throw "Unknown enemy class: $($Enemy.id)" }
    if ($AllowedEnemyWeapons -notcontains $Enemy.weapon) { throw "Unsupported enemy weapon: $($Enemy.id) -> $($Enemy.weapon)" }
    if ($AllowedPatterns -notcontains $Enemy.pattern) { throw "Unsupported enemy movement pattern: $($Enemy.id) -> $($Enemy.pattern)" }
    if ([int]$Enemy.hp -le 0 -or [int]$Enemy.value -le 0 -or [double]$Enemy.speed -lt 0) { throw "Invalid enemy combat values: $($Enemy.id)" }
    if ($Enemy.class -eq 'boss' -and -not [bool]$Enemy.boss) { throw "Boss-class enemy missing boss=true: $($Enemy.id)" }
    if ([bool]$Enemy.boss) {
        if ([int]$Enemy.phases -ne 3) { throw "Boss must have exactly three phases: $($Enemy.id)" }
        if ([int]$Enemy.weak_point_phase -lt 1 -or [int]$Enemy.weak_point_phase -gt 3) { throw "Invalid weak-point phase: $($Enemy.id)" }
    }
}

$MissionIds = @($Missions.missions | ForEach-Object { $_.id })
$AllowedObjectiveTypes = @('survive','destroy_count','destroy_enemy')
foreach ($Mission in $Missions.missions) {
    if ([int]$Mission.duration_seconds -le 0) { throw "Mission duration must be positive: $($Mission.id)" }
    if ([int]$Mission.starting_wave -lt 1) { throw "Mission starting_wave must be positive: $($Mission.id)" }
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Unknown mission boss: $($Mission.boss_id)" }
    $Objectives = @($Mission.objectives)
    if ($Objectives.Count -lt 1) { throw "Mission has no objectives: $($Mission.id)" }
    Assert-UniqueIds $Objectives "mission $($Mission.id) objectives"
    if (@($Objectives | Where-Object { $_.required }).Count -lt 1) { throw "Mission has no required objective: $($Mission.id)" }
    foreach ($Objective in $Objectives) {
        if ($AllowedObjectiveTypes -notcontains $Objective.type) { throw "Unknown objective type: $($Mission.id)/$($Objective.id)" }
        if ($Objective.type -eq 'survive' -and [int]$Objective.seconds -le 0) { throw "Invalid survive objective: $($Objective.id)" }
        if ($Objective.type -in @('destroy_count','destroy_enemy') -and [int]$Objective.count -le 0) { throw "Invalid destroy objective: $($Objective.id)" }
        if ($Objective.type -eq 'destroy_enemy' -and $EnemyIds -notcontains $Objective.enemy_id) { throw "Objective references unknown enemy: $($Objective.enemy_id)" }
    }
}

$CampaignMissionIds = @($Campaign.campaign.missions)
foreach ($MissionId in $CampaignMissionIds) { if ($MissionIds -notcontains $MissionId) { throw "Campaign references unknown mission: $MissionId" } }
if (@($CampaignMissionIds | Sort-Object -Unique).Count -ne $CampaignMissionIds.Count) { throw 'Campaign mission list contains duplicates.' }
if ([int]$Campaign.campaign.starting_hull -lt 1) { throw 'Campaign starting_hull must be positive.' }
if ([int]$Campaign.campaign.starting_shield -lt 0) { throw 'Campaign starting_shield cannot be negative.' }
if ([int]$Campaign.campaign.repair_cost_per_hull -lt 0) { throw 'repair_cost_per_hull cannot be negative.' }
if ([int]$Campaign.campaign.shield_recharge_cost_per_point -lt 0) { throw 'shield_recharge_cost_per_point cannot be negative.' }
foreach ($BonusField in @('mission_complete_bonus','no_hull_damage_bonus','accuracy_bonus','boss_kill_bonus')) {
    if ([int]$Campaign.progression.$BonusField -lt 0) { throw "Campaign progression bonus cannot be negative: $BonusField" }
}
if ([double]$Campaign.progression.accuracy_bonus_threshold -lt 0.0 -or [double]$Campaign.progression.accuracy_bonus_threshold -gt 1.0) { throw 'accuracy_bonus_threshold must be within 0..1.' }

foreach ($Profile in $Profiles.profiles) {
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave) { throw "Invalid spawn wave range: $($Profile.id)" }
    if (@($Profile.enemy_ids).Count -lt 1) { throw "Spawn profile has no enemies: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) {
        if ($EnemyIds -notcontains $EnemyId) { throw "Spawn profile references unknown enemy: $EnemyId" }
        if ($BossIds -contains $EnemyId) { throw "Spawn profile includes mission boss: $EnemyId" }
    }
}
foreach ($Environment in @($Missions.missions | ForEach-Object { $_.environment } | Sort-Object -Unique)) {
    $EnvironmentProfiles = @($Profiles.profiles | Where-Object { $_.environment -eq $Environment } | Sort-Object min_wave)
    if ($EnvironmentProfiles.Count -lt 1) { throw "No spawn profile for mission environment: $Environment" }
    $NextWave = 1
    foreach ($Profile in $EnvironmentProfiles) {
        if ([int]$Profile.min_wave -gt $NextWave) { throw "Spawn profile gap for $Environment before wave $NextWave" }
        $NextWave = [Math]::Max($NextWave, [int]$Profile.max_wave + 1)
    }
    if ($NextWave -lt 100) { throw "Spawn profiles for $Environment do not cover through wave 99." }
}

$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' })
if ($Primaries.Count -lt 1) { throw 'No primary weapons defined.' }
$PreviousCost = -1
foreach ($Weapon in $Primaries) {
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary weapon costs out of order: $($Weapon.id)" }
    if ([int]$Weapon.damage -le 0 -or [double]$Weapon.projectile_speed -le 0 -or [double]$Weapon.fire_interval -le 0 -or [int]$Weapon.projectiles -le 0) { throw "Invalid primary weapon values: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}

$ProjectText = Get-Content -Raw (Join-Path $Root 'project.godot')
foreach ($Autoload in @(
    'CampaignSave="*res://scripts/campaign_save.gd"','BossDirector="*res://scripts/boss_director.gd"',
    'RunSeedDirector="*res://scripts/run_seed_director.gd"','BombGuardDirector="*res://scripts/bomb_guard_director.gd"',
    'MissionStateDirector="*res://scripts/mission_state_director.gd"','MissionFlowDirector="*res://scripts/mission_flow_director.gd"',
    'WeaponPickupDirector="*res://scripts/weapon_pickup_director.gd"','AccuracyDirector="*res://scripts/accuracy_director.gd"',
    'RewardDirector="*res://scripts/reward_director.gd"','ServiceDirector="*res://scripts/service_director.gd"',
    'MovementPatternDirector="*res://scripts/movement_pattern_director.gd"'
)) { if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" } }

$BossDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/boss_director.gd')
foreach ($Token in @('BossRules.phase_for','BossRules.volley_count','weak_point_multiplier','HOMING_LIFETIME','rotate_toward')) { if (-not $BossDirectorText.Contains($Token)) { throw "BossDirector missing integration token: $Token" } }
$BombRulesText = Get-Content -Raw (Join-Path $Root 'scripts/bomb_rules.gd')
foreach ($Token in @('BOSS_DAMAGE_RATIO','boss_bomb_damage','apply_nonlethal_boss_damage')) { if (-not $BombRulesText.Contains($Token)) { throw "Bomb rules missing token: $Token" } }
$BombGuardText = Get-Content -Raw (Join-Path $Root 'scripts/bomb_guard_director.gd')
foreach ($Token in @('process_priority = -50','_hold_bosses','_restore_bosses','BombRules.apply_nonlethal_boss_damage')) { if (-not $BombGuardText.Contains($Token)) { throw "Bomb guard missing integration token: $Token" } }
$SeedRulesText = Get-Content -Raw (Join-Path $Root 'scripts/run_seed_rules.gd')
foreach ($Token in @('BASE_SEED','MISSION_STRIDE','mission_seed','missions_are_distinct')) { if (-not $SeedRulesText.Contains($Token)) { throw "Run seed rules missing token: $Token" } }
$SeedDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/run_seed_director.gd')
foreach ($Token in @('RunSeedRules.mission_seed','seed(run_seed)')) { if (-not $SeedDirectorText.Contains($Token)) { throw "Run seed director missing token: $Token" } }
$MissionStateText = Get-Content -Raw (Join-Path $Root 'scripts/mission_state_director.gd')
foreach ($Token in @('process_priority = 100','MissionStateRules.starting_hull','MissionStateRules.starting_shield','MissionStateRules.live_wave')) { if (-not $MissionStateText.Contains($Token)) { throw "Mission state director missing token: $Token" } }
$MissionFlowText = Get-Content -Raw (Join-Path $Root 'scripts/mission_flow_director.gd')
foreach ($Token in @('process_priority = -40','MissionFlowRules.should_hold_overtime','safe_pre_frame_time','OVERTIME - DESTROY THE BOSS')) { if (-not $MissionFlowText.Contains($Token)) { throw "Mission flow director missing token: $Token" } }
$MovementRulesText = Get-Content -Raw (Join-Path $Root 'scripts/movement_pattern_rules.gd')
foreach ($Token in @('supported_patterns','tracking_sweep','hover_strafe','aggressive_weave','clamp_x')) { if (-not $MovementRulesText.Contains($Token)) { throw "Movement pattern rules missing token: $Token" } }
$MovementDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/movement_pattern_director.gd')
foreach ($Token in @('process_priority = 50','MovementPatternRules.adjusted_position','pattern_anchor_x','enemy_catalog')) { if (-not $MovementDirectorText.Contains($Token)) { throw "Movement pattern director missing token: $Token" } }
$WeaponPickupRulesText = Get-Content -Raw (Join-Path $Root 'scripts/weapon_pickup_rules.gd')
foreach ($Token in @('temporary_boost_for_indices','effective_index','saved_index')) { if (-not $WeaponPickupRulesText.Contains($Token)) { throw "Weapon pickup rules missing token: $Token" } }
$WeaponPickupDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/weapon_pickup_director.gd')
foreach ($Token in @('_permanent_index','permanent_index','temporary_boost','WeaponPickupRules.saved_index')) { if (-not $WeaponPickupDirectorText.Contains($Token)) { throw "Weapon pickup director missing token: $Token" } }
$AccuracyRulesText = Get-Content -Raw (Join-Path $Root 'scripts/accuracy_rules.gd')
foreach ($Token in @('accuracy_ratio','qualifies','bonus_for')) { if (-not $AccuracyRulesText.Contains($Token)) { throw "Accuracy rules missing token: $Token" } }
$AccuracyDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/accuracy_director.gd')
foreach ($Token in @('shots_fired','shots_hit','accuracy_ratio','process_priority = -10')) { if (-not $AccuracyDirectorText.Contains($Token)) { throw "Accuracy director missing token: $Token" } }
$RewardRulesText = Get-Content -Raw (Join-Path $Root 'scripts/reward_rules.gd')
foreach ($Token in @('no_hull_damage_bonus','boss_kill_bonus','accuracy_bonus','extra_success_bonus')) { if (-not $RewardRulesText.Contains($Token)) { throw "Reward rules missing token: $Token" } }
$RewardDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/reward_director.gd')
foreach ($Token in @('MISSION COMPLETE','RewardRules.extra_success_bonus','AccuracyDirector','ACCURACY')) { if (-not $RewardDirectorText.Contains($Token)) { throw "Reward director missing token: $Token" } }
$ServiceRulesText = Get-Content -Raw (Join-Path $Root 'scripts/service_rules.gd')
foreach ($Token in @('service_cost','can_service','service_full')) { if (-not $ServiceRulesText.Contains($Token)) { throw "Service rules missing token: $Token" } }
$ServiceDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/service_director.gd')
foreach ($Token in @('KEY_H','KEY_J','_capture_success_state','repair_cost_per_hull','shield_recharge_cost_per_point','restore_service_state','ServiceRules.service_cost')) { if (-not $ServiceDirectorText.Contains($Token)) { throw "Service director missing token: $Token" } }
$SaveText = Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd')
foreach ($Token in @('SAVE_VERSION := 2','_saved_weapon_index','ServiceDirector','service_hull','service_shield','restore_service_state','MAX_CREDITS')) { if (-not $SaveText.Contains($Token)) { throw "Campaign save missing hardening token: $Token" } }

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural/data/director/save validation passed; runtime self-tests and engine smoke test skipped.'
    exit 0
}
Write-Host 'Running deterministic runtime rules self-test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --script res://tools/runtime_self_test.gd
if ($LASTEXITCODE -ne 0) { throw "Strike Wing runtime self-test failed with exit code $LASTEXITCODE" }
Write-Host 'Running reward/accuracy self-test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --script res://tools/reward_self_test.gd
if ($LASTEXITCODE -ne 0) { throw "Strike Wing reward self-test failed with exit code $LASTEXITCODE" }
Write-Host 'Running service economy self-test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --script res://tools/service_self_test.gd
if ($LASTEXITCODE -ne 0) { throw "Strike Wing service self-test failed with exit code $LASTEXITCODE" }
Write-Host 'Running mission flow/movement self-test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --script res://tools/mission_flow_self_test.gd
if ($LASTEXITCODE -ne 0) { throw "Strike Wing mission flow self-test failed with exit code $LASTEXITCODE" }
Write-Host 'Running Godot editor smoke test...' -ForegroundColor DarkCyan
& $Godot --headless --path $Root --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }
Write-Host 'Strike Wing 94 validation passed.' -ForegroundColor Green
