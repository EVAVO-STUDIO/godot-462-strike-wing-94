[CmdletBinding()]
param(
    [string]$ProjectionPath = 'work/economy/route_progression_projection.json',
    [string]$OutputPath = 'work/economy/branch_economic_dominance.json'
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
    if (-not (Test-Path -LiteralPath $Path)) { throw "Branch economy authority missing: $RelativePath" }
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Mean([double[]]$Values) {
    if ($Values.Count -eq 0) { return 0.0 }
    return ($Values | Measure-Object -Average).Average
}

function Median([double[]]$Values) {
    if ($Values.Count -eq 0) { return 0.0 }
    $Sorted = @($Values | Sort-Object)
    $Middle = [int][math]::Floor($Sorted.Count / 2)
    if (($Sorted.Count % 2) -eq 1) { return [double]$Sorted[$Middle] }
    return ([double]$Sorted[$Middle - 1] + [double]$Sorted[$Middle]) / 2.0
}

function Choice-Value($Choices, [string]$BranchId) {
    $Property = $Choices.PSObject.Properties[$BranchId]
    if ($null -eq $Property) { throw "Projection route lost branch '$BranchId'." }
    return [string]$Property.Value
}

$ProjectionFile = Resolve-WorkPath $ProjectionPath 'Route progression projection'
$OutputFile = Resolve-WorkPath $OutputPath 'Branch dominance output'
if (-not (Test-Path -LiteralPath $ProjectionFile)) {
    throw "Route progression projection must exist before branch dominance analysis: $ProjectionFile"
}

$Projection = Get-Content -Raw -LiteralPath $ProjectionFile | ConvertFrom-Json
if ([int]$Projection.schema_version -ne 1) { throw 'Branch dominance analysis requires route progression projection schema_version 1.' }
if ([int]$Projection.matrix.route_count -ne 8 -or [int]$Projection.matrix.difficulty_count -ne 4 -or [int]$Projection.matrix.projection_count -ne 32) {
    throw 'Branch dominance analysis requires the governed 8 routes x 4 difficulties matrix.'
}
if ([int]$Projection.matrix.sorties_per_route -ne 27) { throw 'Branch dominance analysis requires 27-sortie route projections.' }

$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ([string]$Projection.source.head_sha -ne $HeadSha) { throw 'Route progression projection does not match current HYPERSONIC HEAD.' }
if (-not ([string]$Projection.source.godot_version).StartsWith('4.6.2')) { throw 'Branch dominance analysis requires Godot 4.6.2 route evidence.' }

$CampaignData = Load-Json 'data/campaign.json'
$Campaign = $CampaignData.campaign
$Branches = @($Campaign.branches)
if ($Branches.Count -ne 3) { throw 'Governed branch dominance analysis expects exactly three controlled branches.' }
foreach ($Branch in $Branches) {
    if (@($Branch.choices).Count -ne 2) { throw "Branch '$($Branch.id)' is no longer binary; update the dominance model deliberately." }
}

$DifficultyIds = @('cadet','combat','veteran','ace')
$FamilyNames = @('primary_weapon','generator','airframe','support')
$Reports = @()
$Signals = @()

foreach ($DifficultyId in $DifficultyIds) {
    $Runs = @($Projection.projections | Where-Object { [string]$_.difficulty -eq $DifficultyId })
    if ($Runs.Count -ne 8) { throw "Difficulty '$DifficultyId' does not contain all eight branch routes." }

    $Wallets = @($Runs | ForEach-Object { [double]$_.final_conservative_wallet_before_purchases })
    $WalletMin = [double](($Wallets | Measure-Object -Minimum).Minimum)
    $WalletMax = [double](($Wallets | Measure-Object -Maximum).Maximum)
    $WalletMean = Mean $Wallets
    $WalletSpread = $WalletMax - $WalletMin
    $WalletSpreadRatio = if ($WalletMean -gt 0.0) { $WalletSpread / $WalletMean } else { 0.0 }

    $RouteRanking = @($Runs | Sort-Object {[double]$_.final_conservative_wallet_before_purchases} -Descending | ForEach-Object {
        [ordered]@{
            route_id = [string]$_.route_id
            branch_choices = $_.branch_choices
            final_conservative_wallet = [int]$_.final_conservative_wallet_before_purchases
        }
    })

    $BranchReports = @()
    foreach ($Branch in $Branches) {
        $BranchId = [string]$Branch.id
        $ChoiceA = $Branch.choices[0]
        $ChoiceB = $Branch.choices[1]
        $ChoiceAId = [string]$ChoiceA.id
        $ChoiceBId = [string]$ChoiceB.id

        # Because all 2^3 branch combinations are present, pair routes that are
        # identical on the other two decisions. This isolates the main economic
        # effect of this branch rather than comparing unrelated routes.
        $PairedDeltas = @()
        $TierTimingDeltas = @()
        $OtherBranches = @($Branches | Where-Object { [string]$_.id -ne $BranchId })
        foreach ($RunA in @($Runs | Where-Object { (Choice-Value $_.branch_choices $BranchId) -eq $ChoiceAId })) {
            $Match = @($Runs | Where-Object {
                if ((Choice-Value $_.branch_choices $BranchId) -ne $ChoiceBId) { return $false }
                foreach ($Other in $OtherBranches) {
                    $OtherId = [string]$Other.id
                    if ((Choice-Value $_.branch_choices $OtherId) -ne (Choice-Value $RunA.branch_choices $OtherId)) { return $false }
                }
                return $true
            })
            if ($Match.Count -ne 1) { throw "Unable to pair branch '$BranchId' route '$($RunA.route_id)' on $DifficultyId." }
            $RunB = $Match[0]
            $Delta = [int]$RunB.final_conservative_wallet_before_purchases - [int]$RunA.final_conservative_wallet_before_purchases
            $PairedDeltas += $Delta

            foreach ($Family in $FamilyNames) {
                $TiersA = @($RunA.tier_reachability | Where-Object { [string]$_.family -eq $Family })
                foreach ($TierA in $TiersA) {
                    $TierB = @($RunB.tier_reachability | Where-Object { [string]$_.family -eq $Family -and [string]$_.tier_id -eq [string]$TierA.tier_id })
                    if ($TierB.Count -ne 1) { continue }
                    $ReachA = if ([bool]$TierA.reachable) { [int]$TierA.first_reach.before_sortie } else { 999 }
                    $ReachB = if ([bool]$TierB[0].reachable) { [int]$TierB[0].first_reach.before_sortie } else { 999 }
                    $TimingDelta = $ReachB - $ReachA
                    if ($TimingDelta -ne 0) {
                        $TierTimingDeltas += [ordered]@{
                            family = $Family
                            tier_id = [string]$TierA.tier_id
                            choice_a_route = [string]$RunA.route_id
                            choice_b_route = [string]$RunB.route_id
                            choice_a_first_reach = $ReachA
                            choice_b_first_reach = $ReachB
                            choice_b_minus_a_sorties = $TimingDelta
                        }
                    }
                }
            }
        }
        if ($PairedDeltas.Count -ne 4) { throw "Branch '$BranchId' expected four paired route comparisons on $DifficultyId." }

        $MeanDelta = Mean ([double[]]$PairedDeltas)
        $MedianDelta = Median ([double[]]$PairedDeltas)
        $MinDelta = [double](($PairedDeltas | Measure-Object -Minimum).Minimum)
        $MaxDelta = [double](($PairedDeltas | Measure-Object -Maximum).Maximum)
        $ConsistentDirection = (($MinDelta -gt 0.0 -and $MaxDelta -gt 0.0) -or ($MinDelta -lt 0.0 -and $MaxDelta -lt 0.0))
        $PreferredChoice = if ($MeanDelta -gt 0.0) { $ChoiceBId } elseif ($MeanDelta -lt 0.0) { $ChoiceAId } else { '' }
        $DeclaredBonusDelta = [int]$ChoiceB.bonus_credits - [int]$ChoiceA.bonus_credits
        $MaxTimingShift = 0
        foreach ($Timing in $TierTimingDeltas) {
            $MaxTimingShift = [math]::Max($MaxTimingShift, [math]::Abs([int]$Timing.choice_b_minus_a_sorties))
        }

        if ([math]::Abs($MeanDelta) -ge 1000.0) {
            $Signals += "CASH_ADVANTAGE_GE_1000:$DifficultyId/$BranchId/$PreferredChoice/$([int][math]::Round([math]::Abs($MeanDelta)))"
        }
        if ($MaxTimingShift -ge 2) {
            $Signals += "TIER_TIMING_SHIFT_GE_2:$DifficultyId/$BranchId/$PreferredChoice/$MaxTimingShift"
        }

        $BranchReports += [ordered]@{
            branch_id = $BranchId
            choice_a = [ordered]@{
                id = $ChoiceAId
                mission_id = [string]$ChoiceA.mission_id
                declared_bonus_credits = [int]$ChoiceA.bonus_credits
            }
            choice_b = [ordered]@{
                id = $ChoiceBId
                mission_id = [string]$ChoiceB.mission_id
                declared_bonus_credits = [int]$ChoiceB.bonus_credits
            }
            declared_bonus_delta_b_minus_a = $DeclaredBonusDelta
            paired_final_wallet_delta_b_minus_a = [ordered]@{
                values = $PairedDeltas
                mean = [math]::Round($MeanDelta, 2)
                median = [math]::Round($MedianDelta, 2)
                minimum = [int]$MinDelta
                maximum = [int]$MaxDelta
                consistent_direction = $ConsistentDirection
                economically_preferred_choice = $PreferredChoice
            }
            max_sequential_tier_timing_shift_sorties = $MaxTimingShift
            tier_timing_differences = $TierTimingDeltas
        }
    }

    $Reports += [ordered]@{
        difficulty = $DifficultyId
        route_final_wallet = [ordered]@{
            minimum = [int]$WalletMin
            maximum = [int]$WalletMax
            mean = [math]::Round($WalletMean, 2)
            spread = [int]$WalletSpread
            spread_ratio = [math]::Round($WalletSpreadRatio, 4)
        }
        route_ranking = $RouteRanking
        branches = $BranchReports
    }
}

# Aggregate whether the same choice wins economically at every difficulty. A
# consistent small advantage is not automatically a defect, but it is a useful
# human-review signal because branch identity should not collapse into hidden
# cash optimisation.
$CrossDifficulty = @()
foreach ($Branch in $Branches) {
    $BranchId = [string]$Branch.id
    $Rows = @()
    foreach ($Report in $Reports) {
        $BranchRow = @($Report.branches | Where-Object { [string]$_.branch_id -eq $BranchId })[0]
        $Rows += [ordered]@{
            difficulty = [string]$Report.difficulty
            preferred_choice = [string]$BranchRow.paired_final_wallet_delta_b_minus_a.economically_preferred_choice
            mean_delta_b_minus_a = [double]$BranchRow.paired_final_wallet_delta_b_minus_a.mean
            max_tier_timing_shift_sorties = [int]$BranchRow.max_sequential_tier_timing_shift_sorties
        }
    }
    $Preferred = @($Rows | ForEach-Object { $_.preferred_choice } | Where-Object { $_ })
    $UniquePreferred = @($Preferred | Sort-Object -Unique)
    $ConsistentWinner = if ($UniquePreferred.Count -eq 1 -and $Preferred.Count -eq 4) { [string]$UniquePreferred[0] } else { '' }
    if ($ConsistentWinner) { $Signals += "CONSISTENT_CASH_WINNER:$BranchId/$ConsistentWinner" }
    $CrossDifficulty += [ordered]@{
        branch_id = $BranchId
        consistent_cash_winner = $ConsistentWinner
        by_difficulty = $Rows
    }
}

$Output = [ordered]@{
    schema_version = 1
    scope = 'paired branch-choice economic dominance analysis over the governed 8-route x 4-difficulty conservative projection; reports cash and sequential-tier timing effects without authorizing automatic reward changes'
    source = [ordered]@{
        head_sha = $HeadSha
        godot_version = [string]$Projection.source.godot_version
        route_projection_schema_version = [int]$Projection.schema_version
    }
    matrix = [ordered]@{
        branch_count = 3
        choices_per_branch = 2
        route_count = 8
        difficulty_count = 4
        paired_comparisons_per_branch_per_difficulty = 4
    }
    review_signals = @($Signals | Sort-Object -Unique)
    cross_difficulty = $CrossDifficulty
    difficulties = $Reports
    interpretation = [ordered]@{
        cash_signal_threshold_credits = 1000
        tier_timing_signal_threshold_sorties = 2
        note = 'A signal is a review prompt, not a balance failure. Confirm with vulnerable human campaign evidence before changing branch bonuses or mission rewards.'
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputFile) | Out-Null
$Output | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $OutputFile -Encoding UTF8
Write-Host 'HYPERSONIC branch economic dominance analysis completed: 3 branches x 4 difficulties with paired route controls.' -ForegroundColor Green
Write-Host "Evidence: $OutputFile" -ForegroundColor DarkGray
if ($Signals.Count -gt 0) {
    Write-Warning ('Branch economy review signals recorded; do not auto-tune from them: ' + (($Signals | Sort-Object -Unique) -join ', '))
}
