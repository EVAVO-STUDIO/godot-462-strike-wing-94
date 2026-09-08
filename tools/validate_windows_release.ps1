[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'build/windows/HYPERSONIC.exe',
    [switch]$SkipPerformance,
    [switch]$SkipVisualQa,
    [switch]$SkipPlaytestTelemetry,
    [switch]$SkipVulnerableBalance,
    [switch]$SkipEconomyAudit
)

$ErrorActionPreference = 'Stop'
$ContractScript = Join-Path $PSScriptRoot 'verify_release_contract.ps1'
$SupplementalContractScript = Join-Path $PSScriptRoot 'verify_release_contract_supplement.ps1'
$ResolveGodotScript = Join-Path $PSScriptRoot 'resolve_release_godot.ps1'
$ValidateScript = Join-Path $PSScriptRoot 'validate.ps1'
$ExportScript = Join-Path $PSScriptRoot 'export_windows.ps1'
$VerifyScript = Join-Path $PSScriptRoot 'verify_windows_export.ps1'
$PerformanceScript = Join-Path $PSScriptRoot 'run_performance_profile.ps1'
$VisualQaScript = Join-Path $PSScriptRoot 'run_visual_qa.ps1'
$PlaytestTelemetryScript = Join-Path $PSScriptRoot 'run_playtest_telemetry.ps1'
$VulnerableBalanceScript = Join-Path $PSScriptRoot 'run_vulnerable_balance_telemetry.ps1'
$EconomyAuditScript = Join-Path $PSScriptRoot 'run_economy_progression_audit.ps1'
$RouteProjectionScript = Join-Path $PSScriptRoot 'run_route_progression_projection.ps1'
$BranchDominanceScript = Join-Path $PSScriptRoot 'analyze_branch_economic_dominance.ps1'
$SpendingStrategyScript = Join-Path $PSScriptRoot 'simulate_progression_spending_strategies.ps1'
$ReceiptScript = Join-Path $PSScriptRoot 'write_windows_release_receipt.ps1'

foreach ($ScriptPath in @($ContractScript, $SupplementalContractScript, $ResolveGodotScript, $ValidateScript, $ExportScript, $VerifyScript, $PerformanceScript, $VisualQaScript, $PlaytestTelemetryScript, $VulnerableBalanceScript, $EconomyAuditScript, $RouteProjectionScript, $BranchDominanceScript, $SpendingStrategyScript, $ReceiptScript)) {
    $Tokens = $null
    $Errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$Tokens, [ref]$Errors) | Out-Null
    if ($Errors.Count -gt 0) {
        throw "Release dependency has PowerShell parser errors: $ScriptPath -> $($Errors[0].Message)"
    }
}

Write-Host 'Verifying HYPERSONIC release contract and documentation authority...' -ForegroundColor Cyan
& $ContractScript
Write-Host 'Verifying contextual controller, native maintenance and Mission 1 onboarding authority...' -ForegroundColor Cyan
& $SupplementalContractScript

# Resolve one exact engine executable once and pass it through every native
# release stage. This prevents different child scripts from silently finding
# different Godot installations and turns the 4.6.2 requirement into evidence.
$ResolvedGodot = & $ResolveGodotScript -Preferred $GodotBin
if (-not $ResolvedGodot) { throw 'Unable to resolve the governed Godot 4.6.2 release executable.' }
$GodotBin = [string]$ResolvedGodot
Write-Host "Using governed release engine: $GodotBin" -ForegroundColor DarkCyan

Write-Host 'Running HYPERSONIC source and engine validation...' -ForegroundColor Cyan
& $ValidateScript -GodotBin $GodotBin

if (-not $SkipPerformance) {
    Write-Host 'Running the native 1280x720 production combat stress profile...' -ForegroundColor Cyan
    & $PerformanceScript -GodotBin $GodotBin -Density stress -Isolate none
} else {
    Write-Warning 'Graphical performance profiling was explicitly skipped; this run is not a complete release-performance audit.'
}

if (-not $SkipVisualQa) {
    Write-Host 'Capturing the canonical 640x360 representative visual QA matrix...' -ForegroundColor Cyan
    & $VisualQaScript -GodotBin $GodotBin
} else {
    Write-Warning 'Visual QA capture was explicitly skipped; this run is not a complete release-presentation audit.'
}

if (-not $SkipPlaytestTelemetry) {
    Write-Host 'Running the eight-sortie bounded gameplay telemetry matrix...' -ForegroundColor Cyan
    & $PlaytestTelemetryScript -GodotBin $GodotBin
} else {
    Write-Warning 'Representative playtest telemetry was explicitly skipped; this run is not a complete release-gameplay audit.'
}

if (-not $SkipVulnerableBalance) {
    Write-Host 'Running deterministic vulnerable pressure and difficulty evidence...' -ForegroundColor Cyan
    & $VulnerableBalanceScript -GodotBin $GodotBin
} else {
    Write-Warning 'Vulnerable balance telemetry was explicitly skipped; this run is not a complete automated balance-evidence audit.'
}

if (-not $SkipEconomyAudit) {
    Write-Host 'Running authored economy, servicing and sequential progression affordability evidence...' -ForegroundColor Cyan
    & $EconomyAuditScript -GodotBin $GodotBin
    Write-Host 'Projecting all eight campaign branch routes across four difficulties...' -ForegroundColor Cyan
    & $RouteProjectionScript
    Write-Host 'Isolating paired branch-choice cash and upgrade-timing effects...' -ForegroundColor Cyan
    & $BranchDominanceScript
    Write-Host 'Stress-testing alternative reserve-aware progression spending policies...' -ForegroundColor Cyan
    & $SpendingStrategyScript
} else {
    Write-Warning 'Economy progression, branch-route projection, branch-dominance and spending-strategy analyses were explicitly skipped; this run is not a complete automated progression-evidence audit.'
}

Write-Host 'Building the canonical HYPERSONIC Windows package...' -ForegroundColor Cyan
& $ExportScript -GodotBin $GodotBin -OutputPath $OutputPath

Write-Host 'Launching and verifying the packaged HYPERSONIC runtime...' -ForegroundColor Cyan
& $VerifyScript -Executable $OutputPath

if (-not $SkipPerformance -and -not $SkipVisualQa -and -not $SkipPlaytestTelemetry -and -not $SkipVulnerableBalance -and -not $SkipEconomyAudit) {
    Write-Host 'Recording exact-SHA packaged-build evidence...' -ForegroundColor Cyan
    & $ReceiptScript -GodotBin $GodotBin -Executable $OutputPath
    Write-Host 'HYPERSONIC automated Windows release gate passed. Vulnerable autoplay and conservative sequential/branch/spending economy evidence are diagnostic; native controller-maintenance plus human campaign, onboarding, visual, audio and balance signoff are still required for a release candidate.' -ForegroundColor Green
} else {
    Write-Warning 'HYPERSONIC focused Windows validation passed with one or more release stages skipped; no exact-SHA release receipt was issued.'
}
