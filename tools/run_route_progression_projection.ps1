[CmdletBinding()]
param(
    [string]$EconomyAuditPath = 'work/economy/economy_progression_audit.json',
    [string]$OutputPath = 'work/economy/route_progression_projection.json'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Resolve-WorkPath([string]$Value, [string]$Label) {
    $Path = if ([System.IO.Path]::IsPathRooted($Value)) {
        [System.IO.Path]::GetFullPath($Value)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $Root $Value))
    }
    $WorkRoot = [System.IO.Path]::GetFullPath((Join-Path $Root 'work'))
    if (-not $Path.StartsWith($WorkRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label must remain inside $WorkRoot."
    }
    return $Path
}

function Load-Json([string]$RelativePath) {
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) { throw "Route projection authority missing: $RelativePath" }
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Tech-Rank([string]$Era, $Ranks) {
    if (-not $Ranks.ContainsKey($Era)) { throw "Unknown tech era '$Era' in route projection." }
    return [int]$Ranks[$Era]
}

$EconomyPath = Resolve-WorkPath $EconomyAuditPath 'Economy audit'
$ProjectionPath = Resolve-WorkPath $OutputPath 'Route projection output'
if (-not (Test-Path -LiteralPath $EconomyPath)) { throw "Economy audit must exist before route projection: $EconomyPath" }
$Economy = Get-Content -Raw -LiteralPath $EconomyPath | ConvertFrom-Json
if ([int]$Economy.schema_version -ne 2) { throw 'Route projection requires economy audit schema_version 2.' }

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ([string]$Economy.source.head_sha -ne $HeadSha) { throw 'Economy audit source SHA does not match current HYPERSONIC HEAD.' }
if (-not ([string]$Economy.source.godot_version).StartsWith('4.6.2')) { throw 'Route projection requires an economy audit produced with Godot 4.6.2.' }

$CampaignData = Load-Json 'data/campaign.json'
$World = Load-Json 'data/campaign_world.json'
$Campaign = $CampaignData.campaign
$Branches = @($Campaign.branches)
if ($Branches.Count -ne 3) { throw "Governed HYPERSONIC route projection expects three controlled branches; got $($Branches.Count)." }
foreach ($Branch in $Branches) {
    if (@($Branch.choices).Count -ne 2) { throw "Branch '$($Branch.id)' is no longer binary; update the governed projection deliberately." }
}

$TechRanks = @{}
foreach ($Era in @($World.tech_eras)) {
    $TechRanks[[string]$Era.id] = [int]$Era.order
}
if ($TechRanks.Count -ne 4) { throw 'Route projection expected the four governed HYPERSONIC tech eras.' }

$MissionContext = @{}
foreach ($Property in @($World.mission_context.PSObject.Properties)) {
    $MissionContext[[string]$Property.Name] = $Property.Value
}
$MissionEconomy = @{}
foreach ($Mission in @($Economy.missions)) { $MissionEconomy[[string]$Mission.id] = $Mission }

$AllChoiceMissionIds = @{}
$ChoiceInfoByMission = @{}
foreach ($Branch in $Branches) {
    foreach ($Choice in @($Branch.choices)) {
        $MissionId = [string]$Choice.mission_id
        $AllChoiceMissionIds[$MissionId] = $true
        $ChoiceInfoByMission[$MissionId] = [ordered]@{
            branch_id = [string]$Branch.id
            choice_id = [string]$Choice.id
            bonus_credits = [int]$Choice.bonus_credits
        }
    }
}

$ChoiceVectors = @()
foreach ($Choice0 in @($Branches[0].choices)) {
    foreach ($Choice1 in @($Branches[1].choices)) {
        foreach ($Choice2 in @($Branches[2].choices)) {
            $ChoiceVectors += [ordered]@{
                ([string]$Branches[0].id) = [string]$Choice0.id
                ([string]$Branches[1].id) = [string]$Choice1.id
                ([string]$Branches[2].id) = [string]$Choice2.id
            }
        }
    }
}
if ($ChoiceVectors.Count -ne 8) { throw 'Route projection must enumerate exactly eight branch combinations.' }

$WorstStartingService = [int]$Economy.service_liabilities[0].worst_survivable_full_service
$StartingCredits = [int]$Economy.campaign.starting_credits
$DifficultyIds = @('cadet','combat','veteran','ace')
$FamilyNames = @('primary_weapon','generator','airframe','support')
$RouteReports = @()
$NeverReachableSignals = @()

$RouteNumber = 0
foreach ($Choices in $ChoiceVectors) {
    $RouteNumber += 1
    $SelectedMissionIds = @{}
    foreach ($Branch in $Branches) {
        $SelectedChoiceId = [string]$Choices[[string]$Branch.id]
        $Choice = @($Branch.choices | Where-Object { [string]$_.id -eq $SelectedChoiceId })[0]
        $SelectedMissionIds[[string]$Choice.mission_id] = $true
    }

    $RouteMissionIds = @()
    foreach ($MissionIdValue in @($Campaign.missions)) {
        $MissionId = [string]$MissionIdValue
        if ($AllChoiceMissionIds.ContainsKey($MissionId) -and -not $SelectedMissionIds.ContainsKey($MissionId)) { continue }
        $RouteMissionIds += $MissionId
    }
    if ($RouteMissionIds.Count -ne 27) { throw "Route $RouteNumber resolved $($RouteMissionIds.Count) sorties instead of 27." }

    foreach ($DifficultyId in $DifficultyIds) {
        $Wallet = $StartingCredits
        $Milestones = @()
        $FirstReach = @{}
        foreach ($FamilyName in $FamilyNames) {
            foreach ($Tier in @($Economy.family_ladders.PSObject.Properties[$FamilyName].Value)) {
                if ([int]$Tier.sticker_cost -le 0) { continue }
                $FirstReach["$FamilyName/$($Tier.id)"] = $null
            }
        }

        for ($Index = 0; $Index -lt $RouteMissionIds.Count; $Index++) {
            $MissionId = $RouteMissionIds[$Index]
            if (-not $MissionContext.ContainsKey($MissionId)) { throw "Route projection lacks mission context for '$MissionId'." }
            if (-not $MissionEconomy.ContainsKey($MissionId)) { throw "Route projection lacks mission economy for '$MissionId'." }
            $Context = $MissionContext[$MissionId]
            $TechEra = [string]$Context.tech_era
            $TechRank = Tech-Rank $TechEra $TechRanks

            $BranchBonus = 0
            if ($ChoiceInfoByMission.ContainsKey($MissionId)) {
                $BranchBonus = [int]$ChoiceInfoByMission[$MissionId].bonus_credits
                $Wallet += $BranchBonus
            }

            $ReachableBeforeSortie = @()
            foreach ($FamilyName in $FamilyNames) {
                foreach ($Tier in @($Economy.family_ladders.PSObject.Properties[$FamilyName].Value)) {
                    if ([int]$Tier.sticker_cost -le 0) { continue }
                    $Key = "$FamilyName/$($Tier.id)"
                    if ($null -ne $FirstReach[$Key]) { continue }
                    $RequiredEra = [string]$Tier.unlock_tech_era
                    $RequiredRank = Tech-Rank $RequiredEra $TechRanks
                    $CumulativeCost = [int]$Tier.cumulative_acquisition_cost
                    if ($RequiredRank -le $TechRank -and $CumulativeCost -le $Wallet) {
                        $FirstReach[$Key] = [ordered]@{
                            before_sortie = $Index + 1
                            mission_id = $MissionId
                            tech_era = $TechEra
                            conservative_wallet = $Wallet
                            cumulative_acquisition_cost = $CumulativeCost
                        }
                        $ReachableBeforeSortie += $Key
                    }
                }
            }

            $DifficultyRewardProperty = $MissionEconomy[$MissionId].difficulty.PSObject.Properties[$DifficultyId]
            if ($null -eq $DifficultyRewardProperty) { throw "Mission '$MissionId' lacks economy reward row for '$DifficultyId'." }
            $Reward = [int]$DifficultyRewardProperty.Value.guaranteed_zero_score_reward
            $WalletAfter = $Wallet + $Reward - $WorstStartingService
            $Milestones += [ordered]@{
                sortie = $Index + 1
                mission_id = $MissionId
                tech_era = $TechEra
                branch_bonus_before_sortie = $BranchBonus
                wallet_before_sortie = $Wallet
                newly_reachable_tiers = $ReachableBeforeSortie
                guaranteed_zero_score_reward = $Reward
                worst_survivable_starting_frame_service_reserve = $WorstStartingService
                wallet_after_sortie = $WalletAfter
            }
            $Wallet = $WalletAfter
        }

        $TierReach = @()
        foreach ($FamilyName in $FamilyNames) {
            foreach ($Tier in @($Economy.family_ladders.PSObject.Properties[$FamilyName].Value)) {
                if ([int]$Tier.sticker_cost -le 0) { continue }
                $Key = "$FamilyName/$($Tier.id)"
                $Reach = $FirstReach[$Key]
                $TierReach += [ordered]@{
                    family = $FamilyName
                    tier_id = [string]$Tier.id
                    tier_index = [int]$Tier.tier_index
                    sticker_cost = [int]$Tier.sticker_cost
                    cumulative_acquisition_cost = [int]$Tier.cumulative_acquisition_cost
                    unlock_tech_era = [string]$Tier.unlock_tech_era
                    reachable = ($null -ne $Reach)
                    first_reach = $Reach
                }
                if ($null -eq $Reach) {
                    $NeverReachableSignals += "ROUTE_$RouteNumber/$DifficultyId/$Key"
                }
            }
        }

        $RouteReports += [ordered]@{
            route_id = "route_$RouteNumber"
            branch_choices = $Choices
            difficulty = $DifficultyId
            sortie_count = $RouteMissionIds.Count
            mission_ids = $RouteMissionIds
            starting_credits = $StartingCredits
            stress_service_reserve_per_sortie = $WorstStartingService
            final_conservative_wallet_before_purchases = $Wallet
            tier_reachability = $TierReach
            milestones = $Milestones
        }
    }
}

$Output = [ordered]@{
    schema_version = 1
    scope = 'eight-route, four-difficulty conservative structural projection using zero-score guaranteed rewards, branch bonuses and worst-survivable starting-frame full service after every successful sortie; each family is evaluated independently by cumulative acquisition cost; not a balance target or human-play forecast'
    source = [ordered]@{
        head_sha = $HeadSha
        godot_version = [string]$Economy.source.godot_version
        economy_schema_version = [int]$Economy.schema_version
    }
    matrix = [ordered]@{
        route_count = 8
        difficulty_count = 4
        projection_count = $RouteReports.Count
        sorties_per_route = 27
        stress_service_reserve_per_sortie = $WorstStartingService
    }
    never_reachable_signals = @($NeverReachableSignals | Sort-Object -Unique)
    projections = $RouteReports
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ProjectionPath) | Out-Null
$Output | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $ProjectionPath -Encoding UTF8
Write-Host "HYPERSONIC route progression projection completed: $($RouteReports.Count) route/difficulty projections." -ForegroundColor Green
Write-Host "Evidence: $ProjectionPath" -ForegroundColor DarkGray
if ($NeverReachableSignals.Count -gt 0) {
    Write-Warning ("Structurally unreachable tier signals require review; do not auto-tune from this stress model: " + (($NeverReachableSignals | Sort-Object -Unique) -join ', '))
}
