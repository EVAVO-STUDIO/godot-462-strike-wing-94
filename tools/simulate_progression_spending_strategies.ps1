[CmdletBinding()]
param(
    [string]$EconomyAuditPath = 'work/economy/economy_progression_audit.json',
    [string]$RouteProjectionPath = 'work/economy/route_progression_projection.json',
    [string]$OutputPath = 'work/economy/progression_spending_strategies.json'
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
    if (-not (Test-Path -LiteralPath $Path)) { throw "Spending strategy authority missing: $RelativePath" }
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Tech-Rank([string]$Era, $Ranks) {
    if (-not $Ranks.ContainsKey($Era)) { throw "Unknown technology era '$Era'." }
    return [int]$Ranks[$Era]
}

function Next-Tier($Economy, [string]$Family, [int]$OwnedIndex) {
    $Property = $Economy.family_ladders.PSObject.Properties[$Family]
    if ($null -eq $Property) { return $null }
    $Ladder = @($Property.Value)
    $NextIndex = $OwnedIndex + 1
    if ($NextIndex -lt 0 -or $NextIndex -ge $Ladder.Count) { return $null }
    return $Ladder[$NextIndex]
}

function Candidate-For-Family($Economy, [string]$Family, [int]$OwnedIndex, [string]$TechEra, $TechRanks, [int]$Wallet, [int]$Reward, [int]$ServiceReserve) {
    $Tier = Next-Tier $Economy $Family $OwnedIndex
    if ($null -eq $Tier) { return $null }
    if (Tech-Rank ([string]$Tier.unlock_tech_era) $TechRanks -gt Tech-Rank $TechEra $TechRanks) { return $null }
    $Cost = [int]$Tier.sticker_cost
    if ($Cost -le 0) { return $null }
    # Reserve-aware affordability: after buying now, the guaranteed modeled
    # reward for this sortie must still be enough to cover the stress service
    # bill without driving the account negative.
    if (($Wallet + $Reward - $Cost - $ServiceReserve) -lt 0) { return $null }
    return [ordered]@{
        family = $Family
        tier_id = [string]$Tier.id
        tier_index = [int]$Tier.tier_index
        cost = $Cost
        unlock_tech_era = [string]$Tier.unlock_tech_era
    }
}

function Strategy-Order([string]$StrategyId, [int]$SortieIndex) {
    switch ($StrategyId) {
        'weapon_first' { return @('primary_weapon','generator','airframe','support') }
        'generator_first' { return @('generator','primary_weapon','airframe','support') }
        'airframe_first' { return @('airframe','generator','primary_weapon','support') }
        'support_first' { return @('support','primary_weapon','generator','airframe') }
        'balanced_round_robin' {
            $Base = @('primary_weapon','generator','airframe','support')
            $Offset = $SortieIndex % $Base.Count
            return @($Base[$Offset..($Base.Count - 1)] + $Base[0..($Offset - 1)]) if $Offset -gt 0 else $Base
        }
        default { return @('primary_weapon','generator','airframe','support') }
    }
}

$EconomyFile = Resolve-WorkPath $EconomyAuditPath 'Economy audit'
$ProjectionFile = Resolve-WorkPath $RouteProjectionPath 'Route projection'
$OutputFile = Resolve-WorkPath $OutputPath 'Spending strategy output'
if (-not (Test-Path -LiteralPath $EconomyFile)) { throw "Economy audit missing: $EconomyFile" }
if (-not (Test-Path -LiteralPath $ProjectionFile)) { throw "Route projection missing: $ProjectionFile" }

$Economy = Get-Content -Raw -LiteralPath $EconomyFile | ConvertFrom-Json
$Projection = Get-Content -Raw -LiteralPath $ProjectionFile | ConvertFrom-Json
if ([int]$Economy.schema_version -ne 2) { throw 'Spending strategy audit requires economy schema_version 2.' }
if ([int]$Projection.schema_version -ne 1) { throw 'Spending strategy audit requires route projection schema_version 1.' }

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ([string]$Economy.source.head_sha -ne $HeadSha -or [string]$Projection.source.head_sha -ne $HeadSha) {
    throw 'Spending strategy inputs must match current HYPERSONIC HEAD.'
}
if (-not ([string]$Economy.source.godot_version).StartsWith('4.6.2') -or -not ([string]$Projection.source.godot_version).StartsWith('4.6.2')) {
    throw 'Spending strategy audit requires Godot 4.6.2 economy authority.'
}
if ([int]$Projection.matrix.route_count -ne 8 -or [int]$Projection.matrix.difficulty_count -ne 4 -or [int]$Projection.matrix.projection_count -ne 32 -or [int]$Projection.matrix.sorties_per_route -ne 27) {
    throw 'Spending strategy audit requires the governed 8 x 4 x 27 route matrix.'
}

$World = Load-Json 'data/campaign_world.json'
$TechRanks = @{}
foreach ($Era in @($World.tech_eras)) { $TechRanks[[string]$Era.id] = [int]$Era.order }
if ($TechRanks.Count -ne 4) { throw 'Spending strategy audit requires four governed tech eras.' }

$FamilyNames = @('primary_weapon','generator','airframe','support')
$StrategyIds = @('save_only','weapon_first','generator_first','airframe_first','support_first','cheapest_next','balanced_round_robin')
$Results = @()
$Signals = @()

foreach ($Route in @($Projection.projections)) {
    if ([int]$Route.sortie_count -ne 27 -or @($Route.milestones).Count -ne 27) {
        throw "Route '$($Route.route_id)/$($Route.difficulty)' is incomplete."
    }

    foreach ($StrategyId in $StrategyIds) {
        $Wallet = [int]$Route.starting_credits
        $Owned = @{}
        foreach ($Family in $FamilyNames) { $Owned[$Family] = 0 }
        $Purchases = @()
        $Milestones = @()
        $WentNegative = $false
        $ForcedSingleFamilyWindows = 0
        $MultiFamilyChoiceWindows = 0
        $NoAffordableUpgradeWindows = 0

        for ($Index = 0; $Index -lt @($Route.milestones).Count; $Index++) {
            $Milestone = $Route.milestones[$Index]
            $Wallet += [int]$Milestone.branch_bonus_before_sortie
            $Reward = [int]$Milestone.guaranteed_zero_score_reward
            $ServiceReserve = [int]$Milestone.worst_survivable_starting_frame_service_reserve
            $TechEra = [string]$Milestone.tech_era

            $Candidates = @()
            foreach ($Family in $FamilyNames) {
                $Candidate = Candidate-For-Family $Economy $Family ([int]$Owned[$Family]) $TechEra $TechRanks $Wallet $Reward $ServiceReserve
                if ($null -ne $Candidate) { $Candidates += $Candidate }
            }
            if ($Candidates.Count -eq 0) { $NoAffordableUpgradeWindows += 1 }
            elseif ($Candidates.Count -eq 1) { $ForcedSingleFamilyWindows += 1 }
            else { $MultiFamilyChoiceWindows += 1 }

            $Chosen = $null
            if ($StrategyId -ne 'save_only' -and $Candidates.Count -gt 0) {
                if ($StrategyId -eq 'cheapest_next') {
                    $Chosen = @($Candidates | Sort-Object cost, family | Select-Object -First 1)[0]
                } else {
                    foreach ($Family in @(Strategy-Order $StrategyId $Index)) {
                        $Match = @($Candidates | Where-Object { [string]$_.family -eq $Family })
                        if ($Match.Count -gt 0) { $Chosen = $Match[0]; break }
                    }
                }
            }

            $PurchaseRecord = $null
            if ($null -ne $Chosen) {
                $Wallet -= [int]$Chosen.cost
                $Owned[[string]$Chosen.family] = [int]$Owned[[string]$Chosen.family] + 1
                $PurchaseRecord = [ordered]@{
                    sortie = $Index + 1
                    mission_id = [string]$Milestone.mission_id
                    family = [string]$Chosen.family
                    tier_id = [string]$Chosen.tier_id
                    cost = [int]$Chosen.cost
                    wallet_after_purchase = $Wallet
                }
                $Purchases += $PurchaseRecord
            }

            $Wallet += $Reward
            $Wallet -= $ServiceReserve
            if ($Wallet -lt 0) { $WentNegative = $true }

            $Milestones += [ordered]@{
                sortie = $Index + 1
                mission_id = [string]$Milestone.mission_id
                tech_era = $TechEra
                branch_bonus = [int]$Milestone.branch_bonus_before_sortie
                guaranteed_reward = $Reward
                service_reserve = $ServiceReserve
                affordable_family_count = $Candidates.Count
                affordable_families = @($Candidates | ForEach-Object { $_.family })
                purchase = $PurchaseRecord
                wallet_after_sortie = $Wallet
            }
        }

        $PaidTiers = 0
        foreach ($Family in $FamilyNames) { $PaidTiers += [int]$Owned[$Family] }
        $TotalSpend = 0
        foreach ($Purchase in $Purchases) { $TotalSpend += [int]$Purchase.cost }

        if ($WentNegative) { $Signals += "NEGATIVE_WALLET:$($Route.route_id)/$($Route.difficulty)/$StrategyId" }
        if ($StrategyId -ne 'save_only' -and $MultiFamilyChoiceWindows -eq 0) {
            $Signals += "NO_MULTI_FAMILY_CHOICE:$($Route.route_id)/$($Route.difficulty)/$StrategyId"
        }

        $Results += [ordered]@{
            route_id = [string]$Route.route_id
            difficulty = [string]$Route.difficulty
            strategy = $StrategyId
            completed_27_sorties_without_negative_wallet = (-not $WentNegative)
            starting_credits = [int]$Route.starting_credits
            final_wallet = $Wallet
            total_spend = $TotalSpend
            total_paid_tiers = $PaidTiers
            owned_paid_tiers = [ordered]@{
                primary_weapon = [int]$Owned.primary_weapon
                generator = [int]$Owned.generator
                airframe = [int]$Owned.airframe
                support = [int]$Owned.support
            }
            forced_single_family_windows = $ForcedSingleFamilyWindows
            multi_family_choice_windows = $MultiFamilyChoiceWindows
            no_affordable_upgrade_windows = $NoAffordableUpgradeWindows
            purchases = $Purchases
            milestones = $Milestones
        }
    }
}

$StrategySummary = @()
foreach ($StrategyId in $StrategyIds) {
    $Rows = @($Results | Where-Object { [string]$_.strategy -eq $StrategyId })
    $CompletionCount = @($Rows | Where-Object { [bool]$_.completed_27_sorties_without_negative_wallet }).Count
    $MeanTiers = ($Rows | Measure-Object -Property total_paid_tiers -Average).Average
    $MeanWallet = ($Rows | Measure-Object -Property final_wallet -Average).Average
    $MeanMulti = ($Rows | Measure-Object -Property multi_family_choice_windows -Average).Average
    $StrategySummary += [ordered]@{
        strategy = $StrategyId
        projection_count = $Rows.Count
        nonnegative_completion_count = $CompletionCount
        nonnegative_completion_ratio = [math]::Round($CompletionCount / [double][math]::Max(1, $Rows.Count), 4)
        mean_paid_tiers = [math]::Round([double]$MeanTiers, 2)
        mean_final_wallet = [math]::Round([double]$MeanWallet, 2)
        mean_multi_family_choice_windows = [math]::Round([double]$MeanMulti, 2)
    }
}

$PurchaseStrategies = @($StrategySummary | Where-Object { [string]$_.strategy -ne 'save_only' })
$PerfectStrategies = @($PurchaseStrategies | Where-Object { [int]$_.nonnegative_completion_count -eq 32 })
if ($PerfectStrategies.Count -eq 1) {
    $Signals += "SOLE_ALWAYS_NONNEGATIVE_STRATEGY:$($PerfectStrategies[0].strategy)"
}

$Output = [ordered]@{
    schema_version = 1
    scope = 'reserve-aware one-major-purchase-per-sortie structural spending stress over all 8 routes x 4 difficulties; compares alternative family priorities without assigning cross-family gameplay utility or authorizing automatic balance changes'
    source = [ordered]@{
        head_sha = $HeadSha
        godot_version = [string]$Economy.source.godot_version
        economy_schema_version = [int]$Economy.schema_version
        route_projection_schema_version = [int]$Projection.schema_version
    }
    matrix = [ordered]@{
        route_count = 8
        difficulty_count = 4
        route_difficulty_count = 32
        strategy_count = $StrategyIds.Count
        simulation_count = $Results.Count
        sorties_per_simulation = 27
        one_major_purchase_per_sortie = $true
        reserve_aware = $true
    }
    strategies = $StrategySummary
    review_signals = @($Signals | Sort-Object -Unique)
    simulations = $Results
    interpretation = [ordered]@{
        note = 'This audit tests structural affordability and choice availability only. It does not know the gameplay utility of a cannon, generator, frame or tactical system. Human vulnerable campaign play remains the authority for actual dominance.'
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputFile) | Out-Null
$Output | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Write-Host "HYPERSONIC progression spending strategy audit completed: $($Results.Count) simulations." -ForegroundColor Green
Write-Host "Evidence: $OutputFile" -ForegroundColor DarkGray
if ($Signals.Count -gt 0) {
    Write-Warning ('Progression strategy review signals recorded; do not auto-tune from them: ' + (($Signals | Sort-Object -Unique) -join ', '))
}
