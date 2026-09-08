[CmdletBinding()]
param([string]$SignoffPath = 'work/release_signoff.json')

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$NativeHandoffGate = Join-Path $PSScriptRoot 'verify_native_release_handoff.ps1'
if (-not (Test-Path -LiteralPath $NativeHandoffGate)) { throw 'Native release handoff verifier is missing.' }

function Resolve-WorkEvidence([string]$Value, [string]$AllowedRelativeRoot, [string]$Label) {
    if (-not $Value.Trim()) { throw "$Label path is required." }
    $Path = if ([System.IO.Path]::IsPathRooted($Value)) {
        [System.IO.Path]::GetFullPath($Value)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $Root $Value))
    }
    $AllowedRoot = [System.IO.Path]::GetFullPath((Join-Path $Root $AllowedRelativeRoot))
    if (-not $Path.StartsWith($AllowedRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label must remain inside $AllowedRoot."
    }
    if (-not (Test-Path -LiteralPath $Path)) { throw "$Label is missing: $Path" }
    return $Path
}

function Assert-Source($Source, [string]$HeadSha, [string]$Label) {
    if ($null -eq $Source) { throw "$Label lost source provenance." }
    if (([string]$Source.head_sha).ToLowerInvariant() -ne $HeadSha.ToLowerInvariant()) {
        throw "$Label does not match the exact HYPERSONIC HEAD being signed."
    }
    if (-not ([string]$Source.godot_version).StartsWith('4.6.2')) {
        throw "$Label was not produced from governed Godot 4.6.2 evidence."
    }
}

$AbsoluteSignoff = Resolve-WorkEvidence $SignoffPath 'work' 'Human release signoff'
$Signoff = Get-Content -Raw -LiteralPath $AbsoluteSignoff | ConvertFrom-Json
if ([int]$Signoff.schema_version -ne 4) { throw 'Human release signoff schema_version must be 4.' }
if ([string]$Signoff.product -ne 'HYPERSONIC') { throw 'Human release signoff product must be HYPERSONIC.' }

$HeadSha = (& git -C $Root rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $HeadSha -notmatch '^[0-9a-f]{40}$') { throw 'Unable to resolve current exact Git HEAD.' }
if (([string]$Signoff.head_sha).ToLowerInvariant() -ne $HeadSha) {
    throw "Human release signoff was reviewed against '$($Signoff.head_sha)' but current HEAD is '$HeadSha'."
}
if (-not ([string]$Signoff.reviewer).Trim()) { throw 'Human release signoff requires a reviewer.' }
$Reviewed = [DateTimeOffset]::MinValue
if (-not [DateTimeOffset]::TryParse([string]$Signoff.reviewed_utc, [ref]$Reviewed)) {
    throw 'Human release signoff reviewed_utc must be a valid ISO-8601 timestamp.'
}

# Native evidence is one authority. Do not duplicate its journey/profile rules
# here: the exact-SHA handoff verifier owns the current 8 core + 2 controller
# contract and rejects stale eight/nine-journey evidence.
Write-Host 'Verifying exact-SHA ten-journey native Test Lab handoff...' -ForegroundColor DarkCyan
& $NativeHandoffGate -HandoffPath ([string]$Signoff.native_test_lab.handoff_path)

$VulnerablePath = Resolve-WorkEvidence ([string]$Signoff.balance.vulnerable_summary_path) 'work/vulnerable_balance' 'Vulnerable balance summary'
$Vulnerable = Get-Content -Raw -LiteralPath $VulnerablePath | ConvertFrom-Json
if ([int]$Vulnerable.schema_version -ne 1) { throw 'Vulnerable balance summary schema_version must be 1.' }
Assert-Source $Vulnerable.source $HeadSha 'Vulnerable balance summary'
if ([bool]$Vulnerable.source.invulnerability) { throw 'Human balance signoff cannot use an invulnerable pressure summary.' }
if ([int]$Vulnerable.matrix.case_count -lt 9 -or [int]$Vulnerable.matrix.first_mission_difficulty_count -ne 4) {
    throw 'Vulnerable balance summary does not contain the governed nine-case / four-difficulty matrix.'
}

$EconomyPath = Resolve-WorkEvidence ([string]$Signoff.balance.economy_audit_path) 'work/economy' 'Economy progression audit'
$Economy = Get-Content -Raw -LiteralPath $EconomyPath | ConvertFrom-Json
if ([int]$Economy.schema_version -ne 2) { throw 'Economy progression audit schema_version must be 2.' }
Assert-Source $Economy.source $HeadSha 'Economy progression audit'
if ([int]$Economy.campaign.mission_count -ne 30) { throw 'Economy progression audit does not cover all 30 campaign missions.' }
if (@($Economy.next_purchases_from_fresh).Count -ne 4) { throw 'Economy progression audit must expose four actual fresh-campaign next purchases.' }
foreach ($FamilyName in @('primary_weapon','generator','airframe','support')) {
    $Family = $Economy.family_ladders.PSObject.Properties[$FamilyName]
    if ($null -eq $Family -or @($Family.Value).Count -lt 2) { throw "Economy audit lost sequential family '$FamilyName'." }
    $Previous = -1
    foreach ($Tier in @($Family.Value)) {
        $Current = [int]$Tier.cumulative_acquisition_cost
        if ($Current -lt $Previous) { throw "Economy cumulative acquisition cost regressed in '$FamilyName'." }
        $Previous = $Current
    }
}
foreach ($DifficultyId in @('cadet','combat','veteran','ace')) {
    $Evidence = $Economy.first_mission_conservative_affordability.PSObject.Properties[$DifficultyId]
    if ($null -eq $Evidence -or @($Evidence.Value.affordable_next_purchase_ids).Count -lt 1) {
        throw "Economy audit lost conservative opening affordability for '$DifficultyId'."
    }
}

$ProjectionPath = Resolve-WorkEvidence ([string]$Signoff.balance.route_projection_path) 'work/economy' 'Route progression projection'
$Projection = Get-Content -Raw -LiteralPath $ProjectionPath | ConvertFrom-Json
if ([int]$Projection.schema_version -ne 1) { throw 'Route progression projection schema_version must be 1.' }
Assert-Source $Projection.source $HeadSha 'Route progression projection'
if ([int]$Projection.source.economy_schema_version -ne 2) { throw 'Route projection was not derived from economy schema v2.' }
if ([int]$Projection.matrix.route_count -ne 8 -or [int]$Projection.matrix.difficulty_count -ne 4 -or [int]$Projection.matrix.projection_count -ne 32 -or [int]$Projection.matrix.sorties_per_route -ne 27) {
    throw 'Route progression projection does not cover the governed 8 routes x 4 difficulties x 27 sorties matrix.'
}

$DominancePath = Resolve-WorkEvidence ([string]$Signoff.balance.branch_dominance_path) 'work/economy' 'Branch economic dominance report'
$Dominance = Get-Content -Raw -LiteralPath $DominancePath | ConvertFrom-Json
if ([int]$Dominance.schema_version -ne 1) { throw 'Branch economic dominance report schema_version must be 1.' }
Assert-Source $Dominance.source $HeadSha 'Branch economic dominance report'
if ([int]$Dominance.source.route_projection_schema_version -ne 1 -or [int]$Dominance.matrix.branch_count -ne 3 -or [int]$Dominance.matrix.choices_per_branch -ne 2 -or [int]$Dominance.matrix.route_count -ne 8 -or [int]$Dominance.matrix.difficulty_count -ne 4 -or [int]$Dominance.matrix.paired_comparisons_per_branch_per_difficulty -ne 4) {
    throw 'Branch economic dominance report lost its governed paired 3-branch / 8-route / 4-difficulty matrix.'
}

$StrategyPath = Join-Path (Split-Path -Parent $EconomyPath) 'progression_spending_strategies.json'
if (-not (Test-Path -LiteralPath $StrategyPath)) { throw "Progression spending strategy report is missing: $StrategyPath" }
$Strategy = Get-Content -Raw -LiteralPath $StrategyPath | ConvertFrom-Json
if ([int]$Strategy.schema_version -ne 1) { throw 'Progression spending strategy report schema_version must be 1.' }
Assert-Source $Strategy.source $HeadSha 'Progression spending strategy report'
if ([int]$Strategy.source.economy_schema_version -ne 2 -or [int]$Strategy.source.route_projection_schema_version -ne 1) { throw 'Progression spending strategy report lost its governed source schemas.' }
if ([int]$Strategy.matrix.route_count -ne 8 -or [int]$Strategy.matrix.difficulty_count -ne 4 -or [int]$Strategy.matrix.route_difficulty_count -ne 32 -or [int]$Strategy.matrix.strategy_count -ne 7 -or [int]$Strategy.matrix.simulation_count -ne 224 -or [int]$Strategy.matrix.sorties_per_simulation -ne 27) {
    throw 'Progression spending strategy report does not cover the governed 224 simulations.'
}
if (-not [bool]$Strategy.matrix.one_major_purchase_per_sortie -or -not [bool]$Strategy.matrix.reserve_aware) { throw 'Progression spending strategy report lost reserve-aware cadence.' }

$RequiredTrue = [ordered]@{
    'native_test_lab.passed' = [bool]$Signoff.native_test_lab.passed
    'native_test_lab.all_required_journeys_reviewed' = [bool]$Signoff.native_test_lab.all_required_journeys_reviewed
    'native_test_lab.controller_maintenance_reviewed' = [bool]$Signoff.native_test_lab.controller_maintenance_reviewed
    'native_test_lab.controller_menu_navigation_reviewed' = [bool]$Signoff.native_test_lab.controller_menu_navigation_reviewed
    'native_test_lab.checkpoint_media_reviewed' = [bool]$Signoff.native_test_lab.checkpoint_media_reviewed
    'native_test_lab.runtime_logs_reviewed' = [bool]$Signoff.native_test_lab.runtime_logs_reviewed
    'native_test_lab.audio_media_reviewed' = [bool]$Signoff.native_test_lab.audio_media_reviewed
    'campaign.complete_end_to_end' = [bool]$Signoff.campaign.complete_end_to_end
    'campaign.keyboard_complete' = [bool]$Signoff.campaign.keyboard_complete
    'campaign.controller_complete' = [bool]$Signoff.campaign.controller_complete
    'onboarding.passed_without_readme_or_developer_help' = [bool]$Signoff.onboarding.passed_without_readme_or_developer_help
    'balance.passed' = [bool]$Signoff.balance.passed
    'balance.no_dominant_trivial_strategy' = [bool]$Signoff.balance.no_dominant_trivial_strategy
    'balance.no_progress_wall' = [bool]$Signoff.balance.no_progress_wall
    'balance.difficulty_matrix_reviewed' = [bool]$Signoff.balance.difficulty_matrix_reviewed
    'balance.vulnerable_evidence_reviewed' = [bool]$Signoff.balance.vulnerable_evidence_reviewed
    'balance.economy_evidence_reviewed' = [bool]$Signoff.balance.economy_evidence_reviewed
    'balance.route_projection_reviewed' = [bool]$Signoff.balance.route_projection_reviewed
    'balance.branch_economy_reviewed' = [bool]$Signoff.balance.branch_economy_reviewed
    'visual.passed' = [bool]$Signoff.visual.passed
    'visual.native_1280x720' = [bool]$Signoff.visual.native_1280x720
    'visual.native_1920x1080_or_fullscreen' = [bool]$Signoff.visual.native_1920x1080_or_fullscreen
    'visual.hud_and_warning_readability' = [bool]$Signoff.visual.hud_and_warning_readability
    'visual.reduced_flash_and_accessibility_reviewed' = [bool]$Signoff.visual.reduced_flash_and_accessibility_reviewed
    'audio.passed' = [bool]$Signoff.audio.passed
    'audio.critical_cues_readable' = [bool]$Signoff.audio.critical_cues_readable
    'audio.no_clipping_or_masked_warnings' = [bool]$Signoff.audio.no_clipping_or_masked_warnings
}
foreach ($Item in $RequiredTrue.GetEnumerator()) {
    if (-not $Item.Value) { throw "Human release signoff is incomplete: $($Item.Key) is not true." }
}
if ([int]$Signoff.blockers.p0 -ne 0 -or [int]$Signoff.blockers.p1 -ne 0) {
    throw "Human release signoff still has blockers: P0=$($Signoff.blockers.p0), P1=$($Signoff.blockers.p1)."
}

Write-Host "HYPERSONIC human release signoff passed for $HeadSha ($($Signoff.reviewer)): ten native journeys, controller maintenance/menu navigation, campaign/onboarding, vulnerable balance and governed economy evidence are all exact-SHA reviewed." -ForegroundColor Green
