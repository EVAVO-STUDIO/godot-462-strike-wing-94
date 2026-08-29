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

Write-Host 'Validating Strike Wing 94...' -ForegroundColor Cyan
$Required = @(
    'project.godot','scenes/main.tscn','scripts/main.gd','scripts/content_catalog.gd',
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd','scripts/objective_rules.gd',
    'scripts/boss_rules.gd','scripts/boss_director.gd',
    'scripts/bomb_rules.gd','scripts/campaign_save.gd','scripts/save_recovery_rules.gd','scripts/run_seed_rules.gd',
    'scripts/mission_state_rules.gd','scripts/mission_flow_rules.gd','scripts/movement_pattern_rules.gd','scripts/weapon_pickup_rules.gd',
    'scripts/accuracy_rules.gd','scripts/reward_rules.gd','scripts/service_rules.gd','scripts/energy_rules.gd',
    'scripts/encounter_rules.gd','scripts/encounter_director.gd',
    'scripts/pixel_font.gd','scripts/pixel_ui_surface.gd','scripts/pixel_ui_director.gd',
    'scripts/projectile_cue_rules.gd','scripts/projectile_cue_director.gd','scripts/threat_warning_rules.gd',
    'tools/runtime_self_test.gd','tools/reward_self_test.gd','tools/service_self_test.gd','tools/mission_flow_self_test.gd','tools/save_recovery_self_test.gd','tools/encounter_self_test.gd',
    'data/weapons.json','data/generators.json','data/enemies.json','data/missions.json','data/spawn_profiles.json','data/campaign.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md','docs/90S_SHOOTER_BIBLE.md'
)
foreach ($RelativePath in $Required) { if (-not (Test-Path (Join-Path $Root $RelativePath))) { throw "Missing required file: $RelativePath" } }

$Forbidden = @(
    '.github/workflows','.godot','build','dist',
    'scripts/spawn_safety_director.gd','scripts/spawn_safety_rules.gd','scripts/missile_behavior_director.gd','scripts/missile_behavior_rules.gd',
    'scripts/mission_state_director.gd','scripts/bomb_guard_director.gd','scripts/mission_flow_director.gd','scripts/movement_pattern_director.gd',
    'scripts/run_seed_director.gd','scripts/weapon_pickup_director.gd','scripts/accuracy_director.gd','scripts/reward_director.gd','scripts/service_director.gd',
    'scripts/boss_hud_director.gd','scripts/boss_hud_rules.gd','scripts/threat_warning_director.gd'
)
foreach ($RelativePath in $Forbidden) { if (Test-Path (Join-Path $Root $RelativePath)) { throw "Forbidden generated/obsolete path committed: $RelativePath" } }

$Weapons = Get-Content -Raw (Join-Path $Root 'data/weapons.json') | ConvertFrom-Json
$Generators = Get-Content -Raw (Join-Path $Root 'data/generators.json') | ConvertFrom-Json
$Enemies = Get-Content -Raw (Join-Path $Root 'data/enemies.json') | ConvertFrom-Json
$Missions = Get-Content -Raw (Join-Path $Root 'data/missions.json') | ConvertFrom-Json
$Profiles = Get-Content -Raw (Join-Path $Root 'data/spawn_profiles.json') | ConvertFrom-Json
$Campaign = Get-Content -Raw (Join-Path $Root 'data/campaign.json') | ConvertFrom-Json
Assert-UniqueIds $Weapons.weapons 'weapons'; Assert-UniqueIds $Generators.generators 'generators'; Assert-UniqueIds $Enemies.enemies 'enemies'; Assert-UniqueIds $Missions.missions 'missions'; Assert-UniqueIds $Profiles.profiles 'spawn profiles'

$Primaries = @($Weapons.weapons | Where-Object { $_.slot -eq 'primary' }); if ($Primaries.Count -lt 5) { throw 'Campaign should expose at least five meaningfully distinct primary tiers.' }
$PreviousCost = -1
foreach ($Weapon in $Primaries) {
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary weapon costs out of order: $($Weapon.id)" }
    if ([int]$Weapon.damage -le 0 -or [double]$Weapon.projectile_speed -le 0 -or [double]$Weapon.fire_interval -le 0 -or [int]$Weapon.projectiles -le 0 -or [double]$Weapon.energy_cost -le 0) { throw "Invalid primary weapon values: $($Weapon.id)" }
    if (-not $Weapon.archetype) { throw "Primary weapon missing gameplay archetype: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}
if (@($Generators.generators).Count -lt 3) { throw 'Generator progression requires at least three tiers.' }
$PreviousCost = -1; $PreviousCapacity = 0.0; $PreviousRecharge = 0.0
foreach ($Generator in $Generators.generators) {
    if ([int]$Generator.cost -lt $PreviousCost -or [double]$Generator.capacity -le 0 -or [double]$Generator.recharge_per_second -le 0) { throw "Invalid generator tier: $($Generator.id)" }
    if ([double]$Generator.capacity -lt $PreviousCapacity -or [double]$Generator.recharge_per_second -lt $PreviousRecharge) { throw "Generator progression regresses output: $($Generator.id)" }
    $PreviousCost = [int]$Generator.cost; $PreviousCapacity = [double]$Generator.capacity; $PreviousRecharge = [double]$Generator.recharge_per_second
}

$EnemyIds = @($Enemies.enemies | ForEach-Object { $_.id }); $BossIds = @($Enemies.enemies | Where-Object { $_.boss } | ForEach-Object { $_.id })
$AllowedClasses = @('air','ground','sea','boss'); $AllowedEnemyWeapons = @('single_burst','aimed_burst','side_burst','cannon','missile','deck_gun','twin_burst'); $AllowedPatterns = @('sine_dive','tracking_sweep','hover_strafe','road_column','water_lane','static','aggressive_weave','boss_sweep','boss_column','boss_broadside')
foreach ($Enemy in $Enemies.enemies) {
    if ($AllowedClasses -notcontains $Enemy.class -or $AllowedEnemyWeapons -notcontains $Enemy.weapon -or $AllowedPatterns -notcontains $Enemy.pattern) { throw "Invalid enemy archetype: $($Enemy.id)" }
    if ([int]$Enemy.hp -le 0 -or [int]$Enemy.value -le 0 -or [double]$Enemy.speed -lt 0) { throw "Invalid enemy combat values: $($Enemy.id)" }
}

$AllowedPickups = @('','shield','repair','bomb','weapon'); $AllowedConditions = @('accuracy_at_least','score_at_least','bombs_at_least'); $AllowedFormations = @('scatter','line','wedge','split','column','stagger'); $MissionIds = @($Missions.missions | ForEach-Object { $_.id })
foreach ($Mission in $Missions.missions) {
    if ([int]$Mission.duration_seconds -le 0 -or [int]$Mission.starting_wave -lt 1) { throw "Invalid mission timing/wave: $($Mission.id)" }
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Unknown mission boss: $($Mission.boss_id)" }
    Assert-UniqueIds @($Mission.objectives) "mission $($Mission.id) objectives"
    if (@($Mission.objectives | Where-Object { $_.required }).Count -lt 1) { throw "Mission has no required objective: $($Mission.id)" }
    $Beats = @($Mission.encounter_beats); if ($Beats.Count -lt 5) { throw "Mission needs at least five authored encounter beats: $($Mission.id)" }; Assert-UniqueIds $Beats "mission $($Mission.id) encounter beats"
    $LastTime = -1.0; $HasReward = $false; $HasPacing = $false; $HasSecret = $false; $FormationSet = @{}
    foreach ($Beat in $Beats) {
        $At = [double]$Beat.at_seconds
        if ($At -le $LastTime -or $At -lt 0 -or $At -ge [double]$Mission.duration_seconds) { throw "Encounter beat timing invalid: $($Mission.id)/$($Beat.id)" }; $LastTime = $At
        if ($AllowedPickups -notcontains [string]$Beat.pickup) { throw "Unknown encounter pickup: $($Mission.id)/$($Beat.id)" }
        if ($AllowedFormations -notcontains [string]$Beat.formation) { throw "Unknown encounter formation: $($Mission.id)/$($Beat.id)" }
        $FormationSet[[string]$Beat.formation] = $true
        if ($Beat.pickup) { $HasReward = $true }; if ([double]$Beat.suppress_random_seconds -ge 2.0) { $HasPacing = $true }
        if ([bool]$Beat.secret) {
            $HasSecret = $true; $ConditionType = [string]$Beat.condition.type
            if ($AllowedConditions -notcontains $ConditionType) { throw "Secret encounter uses unsupported condition: $($Mission.id)/$($Beat.id)" }
            if ($ConditionType -eq 'accuracy_at_least' -and [int]$Beat.condition.minimum_shots -lt 20) { throw "Accuracy secret requires meaningful sample: $($Mission.id)/$($Beat.id)" }
        }
        $Count = 0
        foreach ($Entry in @($Beat.enemies)) {
            if ($EnemyIds -notcontains $Entry.id) { throw "Encounter references unknown enemy: $($Mission.id)/$($Beat.id) -> $($Entry.id)" }
            if ($BossIds -contains $Entry.id) { throw "Regular encounter beat must not spawn mission boss: $($Mission.id)/$($Beat.id)" }
            if ([int]$Entry.count -lt 1) { throw "Encounter enemy count must be positive: $($Mission.id)/$($Beat.id)" }; $Count += [int]$Entry.count
        }
        if ($Count -gt 12) { throw "Encounter beat exceeds enemy cap: $($Mission.id)/$($Beat.id)" }
        if ($Count -eq 0 -and -not $Beat.pickup) { throw "Encounter beat must spawn enemies or grant recovery: $($Mission.id)/$($Beat.id)" }
    }
    if (-not $HasReward -or -not $HasPacing -or -not $HasSecret) { throw "Mission lacks authored recovery/pacing/mastery secret: $($Mission.id)" }
    if ($FormationSet.Keys.Count -lt 3) { throw "Mission should use at least three formation shapes: $($Mission.id)" }
}

$CampaignMissionIds = @($Campaign.campaign.missions)
foreach ($MissionId in $CampaignMissionIds) { if ($MissionIds -notcontains $MissionId) { throw "Campaign references unknown mission: $MissionId" } }
if (@($CampaignMissionIds | Sort-Object -Unique).Count -ne $CampaignMissionIds.Count) { throw 'Campaign mission list contains duplicates.' }

foreach ($Profile in $Profiles.profiles) {
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave -or @($Profile.enemy_ids).Count -lt 1) { throw "Invalid spawn profile: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) { if ($EnemyIds -notcontains $EnemyId -or $BossIds -contains $EnemyId) { throw "Invalid spawn profile enemy: $($Profile.id) -> $EnemyId" } }
}
foreach ($Environment in @($Missions.missions | ForEach-Object { $_.environment } | Sort-Object -Unique)) {
    $Ranges = @($Profiles.profiles | Where-Object { $_.environment -eq $Environment } | Sort-Object min_wave); if ($Ranges.Count -lt 1) { throw "No spawn profile for mission environment: $Environment" }
    $NextWave = 1; foreach ($Range in $Ranges) { if ([int]$Range.min_wave -gt $NextWave) { throw "Spawn profile gap for $Environment before wave $NextWave" }; $NextWave = [Math]::Max($NextWave, [int]$Range.max_wave + 1) }; if ($NextWave -lt 100) { throw "Spawn profiles for $Environment do not cover through wave 99." }
}

$ProjectText = Get-Content -Raw (Join-Path $Root 'project.godot')
foreach ($Autoload in @('CampaignSave="*res://scripts/campaign_save.gd"','EncounterDirector="*res://scripts/encounter_director.gd"','BossDirector="*res://scripts/boss_director.gd"','PixelUiDirector="*res://scripts/pixel_ui_director.gd"','ProjectileCueDirector="*res://scripts/projectile_cue_director.gd"')) { if (-not $ProjectText.Contains($Autoload)) { throw "Missing autoload: $Autoload" } }
foreach ($Obsolete in @('ServiceDirector','RewardDirector','AccuracyDirector','WeaponPickupDirector','RunSeedDirector','MovementPatternDirector','MissionFlowDirector','MissionStateDirector','BombGuardDirector','MissileBehaviorDirector','SpawnSafetyDirector','BossHudDirector','ThreatWarningDirector')) { if ($ProjectText.Contains($Obsolete)) { throw "Obsolete autoload must remain removed: $Obsolete" } }

$EncounterDirectorText = Get-Content -Raw (Join-Path $Root 'scripts/encounter_director.gd')
Assert-Contains $EncounterDirectorText @('process_priority = -20','EncounterRules.due_beat','EncounterRules.condition_met','EncounterRules.formation_points','scene.call("_spawn_enemy", archetype)','pattern_anchor_x','enemy_spawn_timer','EncounterRules.reward_pickup') 'Encounter director'
$PixelFontText = Get-Content -Raw (Join-Path $Root 'scripts/pixel_font.gd')
Assert-Contains $PixelFontText @('class_name PixelFont','GLYPHS','draw_text','draw_centered','normalized.substr(char_index, 1)') 'Pixel font'
$PixelSurfaceText = Get-Content -Raw (Join-Path $Root 'scripts/pixel_ui_surface.gd')
Assert-Contains $PixelSurfaceText @('class_name PixelUiSurface','extends Control','director.call("_draw_surface", self)') 'Pixel UI surface'
$PixelUiText = Get-Content -Raw (Join-Path $Root 'scripts/pixel_ui_director.gd')
Assert-Contains $PixelUiText @('layer = 30','PixelUiSurface.new()','Vector2(640, 360)','PixelFont.draw_centered','func _draw_boss','var cue := " WEAK" if phase >= 3','ThreatWarningRules.warning_text','EnergyRules.capacity') 'Pixel UI'
foreach ($WidgetToken in @('PanelContainer.new()','Label.new()','ProgressBar.new()')) { if ($PixelUiText.Contains($WidgetToken)) { throw "Primary pixel UI still contains modern widget chrome: $WidgetToken" } }

$MainText = Get-Content -Raw (Join-Path $Root 'scripts/main.gd')
Assert-Contains $MainText @('const EnergyRules = preload','var service_hull := 100','var generator_index := 0','EnergyRules.recharge(energy, _active_generator(), delta)','RewardRules.extra_success_bonus','MovementPatternRules.adjusted_position','mission_rng.seed = RunSeedRules.mission_seed(mission_index)','MissionFlowRules.should_hold_overtime','BombRules.apply_nonlethal_boss_damage','_try_buy_next_generator()','_service_hull_full()') 'Main gameplay'
$SaveText = Get-Content -Raw (Join-Path $Root 'scripts/campaign_save.gd'); Assert-Contains $SaveText @('SAVE_VERSION := 3','BACKUP_PATH','generator_index','service_hull','service_shield','SaveRecoveryRules.choose_primary_or_backup') 'Campaign save'

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) { Write-Warning 'Godot executable not found. Structural/data/save/encounter/pixel-UI validation passed; headless self-tests and engine smoke test skipped.'; exit 0 }
$Tests = @('runtime_self_test.gd','reward_self_test.gd','service_self_test.gd','mission_flow_self_test.gd','save_recovery_self_test.gd','encounter_self_test.gd')
foreach ($Test in $Tests) { Write-Host "Running $Test..." -ForegroundColor DarkCyan; & $Godot --headless --path $Root --script "res://tools/$Test"; if ($LASTEXITCODE -ne 0) { throw "$Test failed with exit code $LASTEXITCODE" } }
Write-Host 'Running Godot editor smoke test...' -ForegroundColor DarkCyan; & $Godot --headless --path $Root --editor --quit; if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }
Write-Host 'Strike Wing 94 validation passed.' -ForegroundColor Green
