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
    'scripts/combat_rules.gd','scripts/projectile_rules.gd','scripts/progression_rules.gd',
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

$EnemyIds = @($Parsed['data/enemies.json'].enemies | ForEach-Object { $_.id })
foreach ($Mission in $Parsed['data/missions.json'].missions) {
    if ($Mission.boss_id -and $EnemyIds -notcontains $Mission.boss_id) { throw "Mission boss_id not found in enemies.json: $($Mission.boss_id)" }
}
foreach ($Profile in $Parsed['data/spawn_profiles.json'].profiles) {
    if (-not $Profile.enemy_ids -or @($Profile.enemy_ids).Count -eq 0) { throw "Spawn profile has no enemy_ids: $($Profile.id)" }
    foreach ($EnemyId in $Profile.enemy_ids) {
        if ($EnemyIds -notcontains $EnemyId) { throw "Spawn profile references unknown enemy: $EnemyId" }
    }
    if ([int]$Profile.min_wave -gt [int]$Profile.max_wave) { throw "Invalid wave range in spawn profile: $($Profile.id)" }
}

$PrimaryWeapons = @($Parsed['data/weapons.json'].weapons | Where-Object { $_.slot -eq 'primary' })
if ($PrimaryWeapons.Count -lt 1) { throw 'At least one primary weapon is required.' }
$PreviousCost = -1
foreach ($Weapon in $PrimaryWeapons) {
    if ([int]$Weapon.cost -lt $PreviousCost) { throw "Primary weapon costs must be non-decreasing: $($Weapon.id)" }
    $PreviousCost = [int]$Weapon.cost
}

$Godot = Resolve-Godot -Preferred $GodotBin
if (-not $Godot) {
    Write-Warning 'Godot executable not found. Structural, catalogue, spawn and progression validation passed; engine smoke test skipped.'
    exit 0
}
& $Godot --headless --path $Root --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot headless validation failed with exit code $LASTEXITCODE" }
Write-Host 'Strike Wing 94 validation passed.' -ForegroundColor Green
