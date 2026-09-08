[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'work/economy/economy_progression_audit.json'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$ResolveGodotScript = Join-Path $PSScriptRoot 'resolve_release_godot.ps1'
$SelfTest = 'res://tools/economy_progression_self_test.gd'

$GodotBin = [string](& $ResolveGodotScript -Preferred $GodotBin)
if (-not $GodotBin) { throw 'Unable to resolve governed Godot 4.6.2 for economy audit.' }

Write-Host 'Running runtime economy/progression contract...' -ForegroundColor DarkCyan
& $GodotBin --headless --path $Root --script $SelfTest
if ($LASTEXITCODE -ne 0) { throw "Economy progression self-test failed with exit code $LASTEXITCODE." }

function Load-Json([string]$RelativePath) {
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) { throw "Economy authority missing: $RelativePath" }
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Sum-Bonus($Objectives, [bool]$RequiredOnly) {
    $Total = 0
    foreach ($Objective in @($Objectives)) {
        if ($RequiredOnly -and -not [bool]$Objective.required) { continue }
        $Total += [math]::Max(0, [int]$Objective.bonus_credits)
    }
    return $Total
}

function Guaranteed-Boss-Bonus($Mission, $Progression) {
    $BossId = [string]$Mission.boss_id
    if (-not $BossId) { return 0 }
    foreach ($Objective in @($Mission.objectives)) {
        if ([bool]$Objective.required -and [string]$Objective.type -eq 'destroy_enemy' -and [string]$Objective.enemy_id -eq $BossId) {
            return [math]::Max(0, [int]$Progression.boss_kill_bonus)
        }
    }
    return 0
}

function Positive-Items([string]$Family, $Items) {
    $Rows = @()
    foreach ($Item in @($Items)) {
        $Cost = [int]$Item.cost
        if ($Cost -le 0) { continue }
        $Rows += [ordered]@{
            family = $Family
            id = [string]$Item.id
            name = [string]$Item.name
            cost = $Cost
            unlock_tech_era = [string]$Item.unlock_tech_era
        }
    }
    return $Rows
}

$CampaignData = Load-Json 'data/campaign.json'
$MissionsData = Load-Json 'data/missions.json'
$DifficultyData = Load-Json 'data/difficulty_profiles.json'
$WeaponsData = Load-Json 'data/weapons.json'
$GeneratorsData = Load-Json 'data/generators.json'
$AirframesData = Load-Json 'data/airframes.json'
$SupportsData = Load-Json 'data/support_systems.json'

$Campaign = $CampaignData.campaign
$Progression = $CampaignData.progression
$MissionIds = @($Campaign.missions)
if ($MissionIds.Count -ne 30) { throw "Economy audit expected 30 campaign mission IDs, got $($MissionIds.Count)." }

$MissionById = @{}
foreach ($Mission in @($MissionsData.missions)) { $MissionById[[string]$Mission.id] = $Mission }
foreach ($MissionId in $MissionIds) {
    if (-not $MissionById.ContainsKey([string]$MissionId)) { throw "Campaign economy audit cannot resolve mission '$MissionId'." }
}

$Profiles = @($DifficultyData.profiles)
$DefaultDifficulty = [string]$DifficultyData.default
if (@($Profiles | Where-Object { [string]$_.id -eq $DefaultDifficulty }).Count -ne 1) { throw 'Default difficulty profile is missing or duplicated.' }

$PrimaryWeapons = @($WeaponsData.weapons | Where-Object { [string]$_.slot -eq 'primary' })
$Purchases = @()
$Purchases += Positive-Items 'primary_weapon' $PrimaryWeapons
$Purchases += Positive-Items 'generator' $GeneratorsData.generators
$Purchases += Positive-Items 'airframe' $AirframesData.airframes
$Purchases += Positive-Items 'support' $SupportsData.supports
$Purchases = @($Purchases | Sort-Object cost, family, id)
if ($Purchases.Count -lt 4) { throw 'Economy audit found too few purchasable progression items.' }

$RepairPerHull = [int]$Campaign.repair_cost_per_hull
$ShieldPerPoint = [int]$Campaign.shield_recharge_cost_per_point
$ServiceLiabilities = @()
foreach ($Frame in @($AirframesData.airframes)) {
    $HullMax = [int]$Frame.hull_capacity
    $ShieldMax = [int]$Frame.shield_capacity
    $NearLossHullCost = [math]::Max(0, $HullMax - 1) * $RepairPerHull
    $EmptyShieldCost = [math]::Max(0, $ShieldMax) * $ShieldPerPoint
    $ServiceLiabilities += [ordered]@{
        airframe_id = [string]$Frame.id
        hull_capacity = $HullMax
        shield_capacity = $ShieldMax
        near_loss_hull_cost = $NearLossHullCost
        empty_shield_cost = $EmptyShieldCost
        worst_survivable_full_service = $NearLossHullCost + $EmptyShieldCost
    }
}

$MissionRows = @()
foreach ($MissionId in $MissionIds) {
    $Mission = $MissionById[[string]$MissionId]
    $RequiredObjectiveBonus = Sum-Bonus $Mission.objectives $true
    $AllObjectiveBonus = Sum-Bonus $Mission.objectives $false
    $GuaranteedBossBonus = Guaranteed-Boss-Bonus $Mission $Progression
    $BaseRewardAtZeroScore = [int]$Progression.mission_complete_bonus
    $GuaranteedFixedBase = $BaseRewardAtZeroScore + $RequiredObjectiveBonus + $GuaranteedBossBonus
    $PerfectFixedBase = $BaseRewardAtZeroScore + $AllObjectiveBonus + $GuaranteedBossBonus + [int]$Progression.no_hull_damage_bonus + [int]$Progression.accuracy_bonus

    $DifficultyRewards = [ordered]@{}
    foreach ($Profile in $Profiles) {
        $Multiplier = [double]$Profile.reward
        $DifficultyRewards[[string]$Profile.id] = [ordered]@{
            multiplier = $Multiplier
            guaranteed_zero_score_reward = [int][math]::Round($GuaranteedFixedBase * $Multiplier)
            all_fixed_bonus_zero_score_reward = [int][math]::Round($PerfectFixedBase * $Multiplier)
        }
    }

    $MissionRows += [ordered]@{
        id = [string]$Mission.id
        name = [string]$Mission.name
        duration_seconds = [int]$Mission.duration_seconds
        boss_id = [string]$Mission.boss_id
        required_objective_bonus = $RequiredObjectiveBonus
        all_objective_bonus = $AllObjectiveBonus
        guaranteed_boss_bonus = $GuaranteedBossBonus
        zero_score_reward_before_difficulty = $GuaranteedFixedBase
        difficulty = $DifficultyRewards
    }
}

$StartingFrame = $ServiceLiabilities[0]
$StartingCredits = [int]$Campaign.starting_credits
$FirstMission = $MissionRows[0]
$FirstMissionAffordability = [ordered]@{}
foreach ($Profile in $Profiles) {
    $ProfileId = [string]$Profile.id
    $Reward = [int]$FirstMission.difficulty.$ProfileId.guaranteed_zero_score_reward
    $PostWorstService = $StartingCredits + $Reward - [int]$StartingFrame.worst_survivable_full_service
    $Affordable = @($Purchases | Where-Object { [int]$_.cost -le $PostWorstService })
    $MajorAffordable = @($Affordable | Where-Object { $_.family -in @('primary_weapon','generator','airframe','support') })
    if ($MajorAffordable.Count -eq 0) {
        throw "First-mission conservative economy leaves no major purchase path on difficulty '$ProfileId'."
    }
    $FirstMissionAffordability[$ProfileId] = [ordered]@{
        starting_credits = $StartingCredits
        guaranteed_zero_score_reward = $Reward
        worst_survivable_service_reserve = [int]$StartingFrame.worst_survivable_full_service
        credits_after_worst_service = $PostWorstService
        affordable_major_purchase_ids = @($MajorAffordable | ForEach-Object { $_.id })
    }
}

$BranchBonuses = @()
foreach ($Branch in @($Campaign.branches)) {
    foreach ($Choice in @($Branch.choices)) {
        $BranchBonuses += [ordered]@{
            branch_id = [string]$Branch.id
            choice_id = [string]$Choice.id
            mission_id = [string]$Choice.mission_id
            bonus_credits = [int]$Choice.bonus_credits
        }
    }
}

$AbsoluteOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $OutputPath))
}
$WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
if (-not $AbsoluteOutput.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Economy audit output must remain inside $WorkRoot."
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $AbsoluteOutput) | Out-Null

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
$GodotVersion = ((@(& $GodotBin --version 2>&1) | Select-Object -First 1) -as [string]).Trim()
$Report = [ordered]@{
    schema_version = 1
    scope = 'authored economy/progression structure and conservative affordability evidence; not a substitute for vulnerable completed-sortie or human campaign balance evidence'
    source = [ordered]@{
        head_sha = $HeadSha
        godot_version = $GodotVersion
    }
    campaign = [ordered]@{
        starting_credits = $StartingCredits
        repair_cost_per_hull = $RepairPerHull
        shield_recharge_cost_per_point = $ShieldPerPoint
        mission_count = $MissionIds.Count
        default_difficulty = $DefaultDifficulty
    }
    service_liabilities = $ServiceLiabilities
    purchase_ladder = $Purchases
    first_mission_conservative_affordability = $FirstMissionAffordability
    branch_bonuses = $BranchBonuses
    missions = $MissionRows
}
$Report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $AbsoluteOutput -Encoding UTF8

Write-Host "HYPERSONIC economy progression audit passed: $($MissionRows.Count) missions, $($Purchases.Count) priced progression items." -ForegroundColor Green
Write-Host "Evidence: $AbsoluteOutput" -ForegroundColor DarkGray
