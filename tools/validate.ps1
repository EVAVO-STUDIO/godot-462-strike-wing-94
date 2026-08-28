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

Write-Host 'Validating Strike Wing 94...' -ForegroundColor Cyan
$Required = @(
    'project.godot','scenes/main.tscn','scripts/main.gd','scripts/content_catalog.gd',
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd','scripts/objective_rules.gd','scripts/campaign_save.gd',
    'data/weapons.json','data/enemies.json','data/missions.json','data/spawn_profiles.json','data/campaign.json',
    'docs/GAME_DESIGN.md','docs/ARCHITECTURE.md','docs/QA.md'
)
foreach ($RelativePath in $Required) {
    if (-not (Test-Path (Join-Path $Root $RelativePath))) { throw "Missing required file: $RelativePath" }
}

$Parsed = @{}
foreach ($JsonPath in @('data/weapons.json','data/enemies.json','data/missions.json','data/spawn_profiles.json','data/campaign.json')) {
    $Data = Get-Content -Raw (Join-Path $Root $JsonPath) | ConvertFrom-Json
    $Parsed[$JsonPath] = $Data
    Write-Host "JSON OK: $JsonPath" -ForegroundColor DarkGreen
    foreach ($CollectionName in @('weapons','enemies','missions','profiles')) {
        $Collection = $Data.$CollectionName
        if ($null -eq $Collection) { continue }
        $Ids = @($Collection | ForEach-Object { $_.id })
        if ($Ids -contains $null -or $Ids -contains '') { throw "Blank id in $JsonPath/$CollectionName" }
        if (@($Ids | Sort-Object -Unique).Count -ne $Ids.Count) { throw "Duplicate id in $JsonPath/$CollectionName" }
    }
}

$AllowedEnemyClasses = @('air','ground','sea','boss')
$AllowedEnemyWeapons = @('single_burst','aimed_burst','twin_burst','missile','cannon','deck_gun','side_burst')
$EnemyIds = @()
foreach ($Enemy in $Parsed['data/enemies.json'].enemies) {
    if ($AllowedEnemyClasses -notcontains $Enemy.class) { throw "Unknown enemy class: $($Enemy.id) -> $($Enemy.class)" }
    if ($AllowedEnemyWeapons -notcontains $Enemy.weapon) { throw "Unknown enemy weapon: $($Enemy.id) -> $($Enemy.weapon)" }
    if ([int]$Enemy.hp -le 0 -or [int]$Enemy.value -le 0) { throw "Enemy hp/value must be positive: $($Enemy.id)" }
    if ([double]$Enemy.speed -lt 0) { throw "Enemy speed cannot be negative: $($Enemy.id)" }
    if ([bool]$Enemy.boss -and $Enemy.class -ne 'boss') { throw "Boss enemy must use class=boss: $($Enemy.id)" }
    if ($Enemy.class -eq 'boss' -and -not [bool]$Enemy.boss) { throw "class=boss enemy must set boss=true: $($Enemy.id)" }
    $EnemyIds += $Enemy.id
}

$MissionIds = @($Parsed['data/missions.json'].missions | ForEach-Object { $_.id })
$AllowedObjectiveTypes = @('survive','destroy_count','destroy_enemy')
$MissionEnvironments = @()
foreach ($Mission in $Parsed['data/missions.json'].missions) {
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Mission boss_id not found in enemies.json: $($Mission.boss_id)" }
    if ([int]$Mission.duration_seconds -le 0) { throw "Mission duration must be positive: $($Mission.id)" }
    if (-not $Mission.environment) { throw "Mission environment is required: $($Mission.id)" }
    $MissionEnvironments += $Mission.environment
    $Objectives = @($Mission.objectives)
    if ($Objectives.Count -lt 1) { throw "Mission must define at least one objective: $($Mission.id)" }
    $ObjectiveIds = @()
    $RequiredObjectives = 0
    foreach ($Objective in $Objectives) {
        if (-not $Objective.id) { throw "Mission objective missing id: $($Mission.id)" }
        if ($AllowedObjectiveTypes -notcontains $Objective.type) { throw "Unknown objective type: $($Mission.id)/$($Objective.id)" }
        if ($ObjectiveIds -contains $Objective.id) { throw "Duplicate mission objective id: $($Mission.id)/$($Objective.id)" }
        $ObjectiveIds += $Objective.id
        if ([bool]$Objective.required) { $RequiredObjectives++ }
        if ($Objective.type -eq 'survive' -and [int]$Objective.seconds -le 0) { throw "Survive objective requires positive seconds: $($Mission.id)/$($Objective.id)" }
        if ($Objective.type -in @('destroy_count','destroy_enemy') -and [int]$Objective.count -le 0) { throw "Destroy objective requires positive count: $($Mission.id)/$($Objective.id)" }
        if ($Objective.type -eq 'destroy_enemy' -and $EnemyIds -notcontains $Objective.enemy_id) { throw "Objective references unknown enemy: $($Mission.id)/$($Objective.id) -> $($Objective.enemy_id)" }
        if ($Objective.bonus_credits -and [int]$Objective.bonus_credits -lt 0) { throw "Objective bonus cannot be negative: $($Mission.id)/$($Objective.id)" }
    }
    if ($RequiredObjectives -lt 1) { throw "Mission must include at least one required objective: $($Mission.id)" }
}

$CampaignMissions = @($Parsed['data/campaign.json'].campaign.missions)
foreach ($MissionId in $CampaignMissions) {
    if ($MissionIds -notcontains $MissionId) { throw "Campaign references unknown mission: $MissionId" }
}
if (@($CampaignMissions | Sort-Object -Unique).Count -ne $CampaignMissions.Count) { throw 'Campaign mission list contains duplicates.' }

$ProfileEnvironments = @()
foreach ($Profile in $Parsed['data/spawn_profiles.json'].profiles) {
    if (-not $Profile.environment) { throw "Spawn profile missing environment: $($Profile.id)" }
    $ProfileEnvironments += $Profile.environment
    if (-not $Profile.enemy_ids -or @($Profile.enemy_ids).Count -eq 0) { throw "Spawn profile has no enemy_ids: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) {
        if ($EnemyIds -notcontains $EnemyId) { throw "Spawn profile references unknown enemy: $EnemyId" }
        $Matched = @($Parsed['data/enemies.json'].enemies | Where-Object { $_.id -eq $EnemyId })[0]
        if ([bool]$Matched.boss) { throw "Spawn profile cannot include boss enemy: $($Profile.id) -> $EnemyId" }
    }
    if ([int]$Profile.min_wave -le 0 -or [int]$Profile.min_wave -gt [int]$Profile.max_wave) { throw "Invalid wave range in spawn profile: $($Profile.id)" }
}
foreach ($Environment in ($MissionEnvironments | Sort-Object -Unique)) {
    if ($ProfileEnvironments -notcontains $Environment) { throw "No spawn profile exists for mission environment: $Environment" }
}

$PrimaryWeapons = @($Parsed['data/weapons.json'].weapons | Where-Object { $_.slot -eq 'primary' })
if ($PrimaryWeapons.Count -lt 1) { throw 'At least one primary weapon is required.' }
$PreviousCost = -1
foreach ($Weapon in $PrimaryWeapons) {
    if ([int]$Weapon.damage -le 0 -or [double]$Weapon.fire_interval -le 0 -or [double]$Weapon.projectile_speed -le 0) { throw "Invalid primary weapon combat values: $($Weapon.id)" }
    if ([int]$Weapon.projectiles -le 0) { throw "Primary weapon projectile count must be positive: $($Weapon.id)" }
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary weapon costs must be non-decreasing: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}

$ProjectText = Get-Content -Raw (Join-Path $Root 'project.godot')
if ($ProjectText -notmatch 'CampaignSave="\*res://scripts/campaign_save.gd"') { throw 'CampaignSave autoload is not configured.' }

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural, objective, save, enemy, spawn and progression validation passed; engine smoke test skipped.'
    exit 0
}
& $Godot --headless --path $Root --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }
Write-Host 'Strike Wing 94 validation passed.' -ForegroundColor Green
