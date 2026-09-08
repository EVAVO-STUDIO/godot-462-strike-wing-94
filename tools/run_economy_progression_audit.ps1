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

function Build-Family-Ladder([string]$Family, $Items) {
    $Rows = @()
    $Cumulative = 0
    $FirstPositiveSeen = $false
    $Index = 0
    foreach ($Item in @($Items)) {
        $Cost = [int]$Item.cost
        if ($Cost -lt 0) { throw "Negative progression cost in $Family/$($Item.id)." }
        if ($Cost -gt 0) { $Cumulative += $Cost }
        $IsNextFromFresh = $false
        if ($Cost -gt 0 -and -not $FirstPositiveSeen) {
            $IsNextFromFresh = $true
            $FirstPositiveSeen = $true
        }
        $Rows += [ordered]@{
            family = $Family
            tier_index = $Index
            id = [string]$Item.id
            name = [string]$Item.name
            sticker_cost = $Cost
            cumulative_acquisition_cost = $Cumulative
            unlock_tech_era = [string]$Item.unlock_tech_era
            owned_at_fresh_start = ($Cost -eq 0 -and $Index -eq 0)
            next_purchase_from_fresh = $IsNextFromFresh
        }
        $Index += 1
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
$FamilyLadders = [ordered]@{
    primary_weapon = @(Build-Family-Ladder 'primary_weapon' $PrimaryWeapons)
    generator = @(Build-Family-Ladder 'generator' $GeneratorsData.generators)
    airframe = @(Build-Family-Ladder 'airframe' $AirframesData.airframes)
    support = @(Build-Family-Ladder 'support' $SupportsData.supports)
}
$Purchases = @()
foreach ($FamilyName in @('primary_weapon','generator','airframe','support')) {
    $Purchases += @($FamilyLadders[$FamilyName] | Where-Object { [int]$_.sticker_cost -gt 0 })
}
$Purchases = @($Purchases | Sort-Object cumulative_acquisition_cost, family, tier_index)
if ($Purchases.Count -lt 4) { throw 'Economy audit found too few purchasable progression items.' }

$NextFromFresh = @($Purchases | Where-Object { [bool]$_.next_purchase_from_fresh })
if ($NextFromFresh.Count -ne 4) { throw "Fresh campaign must expose exactly one next purchase in each of four progression families; got $($NextFromFresh.Count)." }

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
    $AffordableNext = @($NextFromFresh | Where-Object { [int]$_.sticker_cost -le $PostWorstService })
    if ($AffordableNext.Count -eq 0) {
        throw "First-mission conservative economy leaves no actually-next-purchasable major upgrade on difficulty '$ProfileId'."
    }
    $FirstMissionAffordability[$ProfileId] = [ordered]@{
        starting_credits = $StartingCredits
        guaranteed_zero_score_reward = $Reward
        worst_survivable_service_reserve = [int]$StartingFrame.worst_survivable_full_service
        credits_after_worst_service = $PostWorstService
        affordable_next_purchase_ids = @($AffordableNext | ForEach-Object { $_.id })
        next_purchase_options = @($NextFromFresh | ForEach-Object {
            [ordered]@{
                family = $_.family
                id = $_.id
                sticker_cost = [int]$_.sticker_cost
                affordable = ([int]$_.sticker_cost -le $PostWorstService)
            }
        })
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
    schema_version = 2
    scope = 'authored economy/progression structure and conservative affordability evidence; sequential tier acquisition modelled; not a substitute for vulnerable completed-sortie or human campaign balance evidence'
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
    family_ladders = $FamilyLadders
    purchase_ladder = $Purchases
    next_purchases_from_fresh = $NextFromFresh
    first_mission_conservative_affordability = $FirstMissionAffordability
    branch_bonuses = $BranchBonuses
    missions = $MissionRows
}
$Report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $AbsoluteOutput -Encoding UTF8

Write-Host "HYPERSONIC economy progression audit passed: $($MissionRows.Count) missions, $($Purchases.Count) priced sequential tiers." -ForegroundColor Green
Write-Host "Evidence: $AbsoluteOutput" -ForegroundColor DarkGray
