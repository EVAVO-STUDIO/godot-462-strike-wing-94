[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Require-Text([string]$RelativePath) {
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing release-contract file: $RelativePath" }
    return Get-Content -Raw -LiteralPath $Path
}

$Readme = Require-Text 'README.md'
$Save = Require-Text 'scripts/campaign_save.gd'
$Identity = Require-Text 'data/product_identity.json' | ConvertFrom-Json
$Export = Require-Text 'export_presets.cfg'
$Project = Require-Text 'project.godot'
$Agents = Require-Text 'AGENTS.md'
$ReleaseGate = Require-Text 'tools/validate_windows_release.ps1'
$Vulnerable = Require-Text 'tools/run_vulnerable_balance_telemetry.ps1'
$VulnerableDoc = Require-Text 'docs/VULNERABLE_BALANCE_EVIDENCE.md'
$Economy = Require-Text 'tools/run_economy_progression_audit.ps1'
$Projection = Require-Text 'tools/run_route_progression_projection.ps1'
$Dominance = Require-Text 'tools/analyze_branch_economic_dominance.ps1'
$Spending = Require-Text 'tools/simulate_progression_spending_strategies.ps1'
$EconomySelfTest = Require-Text 'tools/economy_progression_self_test.gd'
$EconomyDoc = Require-Text 'docs/ECONOMY_PROGRESSION_EVIDENCE.md'
$ProgressionOverlay = Require-Text 'scripts/progression_cost_director.gd'
$TechProgressionSelfTest = Require-Text 'tools/tech_progression_self_test.gd'
$SignoffTemplate = Require-Text 'docs/RELEASE_SIGNOFF_TEMPLATE.json' | ConvertFrom-Json
$HumanSignoff = Require-Text 'tools/verify_human_release_signoff.ps1'
$NativeContractPath = Join-Path $Root 'tools/verify_native_test_lab_contract.ps1'

foreach ($RelativePath in @(
    'scripts/progression_cost_surface.gd',
    'tools/progression_cost_overlay_self_test.gd',
    '.evavo/godot-lab-native.json',
    '.evavo/godot-lab-controller-sortie.json',
    '.evavo/godot-lab-native.lock.json',
    'docs/NATIVE_TEST_LAB_RELEASE_JOURNEYS.md',
    'tools/run_native_test_lab_release.ps1',
    'tools/verify_native_release_handoff.ps1',
    'docs/PORTFOLIO_RELEASE_TRANCHE.md',
    'docs/RELEASE_COMPLETION_AUDIT_2026-09-08.md',
    'tools/resolve_release_godot.ps1',
    'tools/write_windows_release_receipt.ps1',
    'tools/validate_windows_candidate.ps1',
    'tools/verify_release_contract_supplement.ps1'
)) { Require-Text $RelativePath | Out-Null }

# Save/version documentation authority.
$SaveMatch = [regex]::Match($Save, 'SAVE_VERSION\s*:=\s*(\d+)')
if (-not $SaveMatch.Success) { throw 'Unable to resolve campaign SAVE_VERSION.' }
$SaveVersion = [int]$SaveMatch.Groups[1].Value
$PreviousVersion = $SaveVersion - 1
if (-not $Readme.Contains("versioned v$SaveVersion local autosave")) { throw "README save authority drift: expected v$SaveVersion." }
if ($PreviousVersion -ge 1 -and -not $Readme.Contains("v1-v$PreviousVersion migration compatibility")) { throw "README migration range drift: expected v1-v$PreviousVersion." }

# Product/export authority.
$ProductVersion = ([string]$Identity.version).Trim()
if (-not $ProductVersion) { throw 'data/product_identity.json version is blank.' }
if (-not $Export.Contains('application/product_version="' + $ProductVersion + '"')) { throw "Windows export version does not match product identity '$ProductVersion'." }
foreach ($Token in @(
    'name="Windows Desktop"',
    'export_path="build/windows/HYPERSONIC.exe"',
    'binary_format/embed_pck=true',
    'exclude_filter="assets/source/**,docs/**,tools/**,work/**"',
    'application/company_name="EVAVO Studio"',
    'application/product_name="HYPERSONIC"'
)) { if (-not $Export.Contains($Token)) { throw "Windows export contract missing: $Token" } }

foreach ($Token in @(
    'window/size/viewport_width=640',
    'window/size/viewport_height=360',
    'window/size/window_width_override=1280',
    'window/size/window_height_override=720',
    'window/stretch/mode="canvas_items"',
    'ProgressionCostDirector="*res://scripts/progression_cost_director.gd"',
    'ControllerSortieBayDirector="*res://scripts/controller_sortie_bay_director.gd"',
    'ControllerMenuContextDirector="*res://scripts/controller_menu_context_director.gd"',
    'FirstSortieGuidanceDirector="*res://scripts/first_sortie_guidance_director.gd"'
)) { if (-not $Project.Contains($Token)) { throw "Desktop/runtime release contract missing: $Token" } }

# Agent/release-tranche authority.
foreach ($Token in @('release candidate','docs/PORTFOLIO_RELEASE_TRANCHE.md','docs/VULNERABLE_BALANCE_EVIDENCE.md','run_vulnerable_balance_telemetry.ps1','docs/ECONOMY_PROGRESSION_EVIDENCE.md','run_economy_progression_audit.ps1')) {
    if (-not $Agents.Contains($Token)) { throw "AGENTS.md lost release authority: $Token" }
}
foreach ($Token in @('validate_windows_candidate.ps1','HYPERSONIC.release.json','10 required native journeys','START','Screen Bomb')) {
    if (-not $Readme.Contains($Token)) { throw "README lost current candidate/control authority: $Token" }
}

# Progression clarity remains player-facing and regression protected.
foreach ($Token in @('layer = 31','repair_cost_per_hull','shield_recharge_cost_per_point','LOCK %s','PAD X WPN','RT SELECT')) {
    if (-not $ProgressionOverlay.Contains($Token)) { throw "Progression cost overlay lost clarity contract: $Token" }
}
foreach ($Token in @('_test_progression_cost_overlay','>002600','LOCK EM','ProgressionCostDirector')) {
    if (-not $TechProgressionSelfTest.Contains($Token)) { throw "Tech progression validation lost price/lock regression: $Token" }
}

# Automated evidence wiring.
foreach ($Token in @(
    'run_vulnerable_balance_telemetry.ps1','SkipVulnerableBalance',
    'run_economy_progression_audit.ps1','run_route_progression_projection.ps1',
    'analyze_branch_economic_dominance.ps1','simulate_progression_spending_strategies.ps1','SkipEconomyAudit'
)) { if (-not $ReleaseGate.Contains($Token)) { throw "Windows release gate lost evidence stage: $Token" } }

foreach ($Token in @('--playtest-telemetry','--capture-difficulty=','vulnerable = $true','invulnerability = $false')) {
    if (-not $Vulnerable.Contains($Token)) { throw "Vulnerable balance contract missing: $Token" }
}
if ($Vulnerable.Contains("'--capture-invulnerable'" + ',')) { throw 'Vulnerable balance argument list must not add --capture-invulnerable.' }
foreach ($Token in @('Never auto-tune from one deterministic pilot','Human balance evidence still required','Test Lab handoff')) {
    if (-not $VulnerableDoc.Contains($Token)) { throw "Vulnerable balance documentation lost truth boundary: $Token" }
}

foreach ($Token in @('economy_progression_self_test.gd','worst_survivable_full_service','first_mission_conservative_affordability','guaranteed_zero_score_reward','cumulative_acquisition_cost','next_purchases_from_fresh','schema_version = 2')) {
    if (-not $Economy.Contains($Token)) { throw "Economy audit lost progression guard: $Token" }
}
foreach ($Token in @('ChoiceVectors.Count -ne 8','RouteMissionIds.Count -ne 27','difficulty_count = 4','projection_count = $RouteReports.Count','never_reachable_signals')) {
    if (-not $Projection.Contains($Token)) { throw "Route projection lost governed matrix guard: $Token" }
}
foreach ($Token in @('paired_comparisons_per_branch_per_difficulty = 4','CONSISTENT_CASH_WINNER','CASH_ADVANTAGE_GE_1000','TIER_TIMING_SHIFT_GE_2','cross_difficulty')) {
    if (-not $Dominance.Contains($Token)) { throw "Branch dominance analysis lost paired-control guard: $Token" }
}
foreach ($Token in @('strategy_count = $StrategyIds.Count','simulation_count = $Results.Count','one_major_purchase_per_sortie = $true','reserve_aware = $true','SOLE_ALWAYS_NONNEGATIVE_STRATEGY','NO_MULTI_FAMILY_CHOICE','balanced_round_robin')) {
    if (-not $Spending.Contains($Token)) { throw "Spending-strategy audit lost structural-choice guard: $Token" }
}
foreach ($Token in @('ProgressionRules.mission_reward','ServiceRules.service_cost','first primary purchase','difficulty reward multipliers')) {
    if (-not $EconomySelfTest.Contains($Token)) { throw "Economy runtime self-test lost authority check: $Token" }
}
foreach ($Token in @('Conservative opening guardrail','Sequential ownership model','Eight-route progression projection','Paired branch-choice dominance analysis','Never auto-tune rewards')) {
    if (-not $EconomyDoc.Contains($Token)) { throw "Economy evidence documentation lost truth boundary: $Token" }
}

# Human signoff schema and centralized evidence authority.
if ([int]$SignoffTemplate.schema_version -ne 4) { throw 'RELEASE_SIGNOFF_TEMPLATE.json must use schema_version 4.' }
foreach ($Property in @('passed','all_required_journeys_reviewed','controller_maintenance_reviewed','controller_menu_navigation_reviewed','checkpoint_media_reviewed','runtime_logs_reviewed','audio_media_reviewed')) {
    if ($null -eq $SignoffTemplate.native_test_lab.PSObject.Properties[$Property]) { throw "Release signoff template lost native_test_lab.$Property." }
}
foreach ($Property in @('difficulty_matrix_reviewed','vulnerable_summary_path','economy_audit_path','route_projection_path','branch_dominance_path','vulnerable_evidence_reviewed','economy_evidence_reviewed','route_projection_reviewed','branch_economy_reviewed')) {
    if ($null -eq $SignoffTemplate.balance.PSObject.Properties[$Property]) { throw "Release signoff template lost balance.$Property." }
}
foreach ($Token in @(
    'verify_native_release_handoff.ps1',
    'ten-journey native Test Lab handoff',
    'native_test_lab.controller_maintenance_reviewed',
    'native_test_lab.controller_menu_navigation_reviewed',
    'Vulnerable balance summary',
    'Economy progression audit',
    'Route progression projection',
    'Branch economic dominance report',
    'Progression spending strategy report',
    '224 simulations'
)) { if (-not $HumanSignoff.Contains($Token)) { throw "Human signoff verifier lost centralized evidence guard: $Token" } }

Write-Host 'Validating HYPERSONIC native Test Lab profile and authority lock...' -ForegroundColor DarkCyan
& $NativeContractPath

Write-Host "HYPERSONIC primary release contract passed: save v$SaveVersion, product $ProductVersion, exact Windows/export authority, vulnerable/economy matrices and centralized ten-journey human/native signoff are aligned." -ForegroundColor Green
