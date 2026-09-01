[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'build/windows/HYPERSONIC.exe',
    [switch]$SkipPerformance,
    [switch]$SkipVisualQa,
    [switch]$SkipPlaytestTelemetry
)

$ErrorActionPreference = 'Stop'
$ValidateScript = Join-Path $PSScriptRoot 'validate.ps1'
$ExportScript = Join-Path $PSScriptRoot 'export_windows.ps1'
$VerifyScript = Join-Path $PSScriptRoot 'verify_windows_export.ps1'
$PerformanceScript = Join-Path $PSScriptRoot 'run_performance_profile.ps1'
$VisualQaScript = Join-Path $PSScriptRoot 'run_visual_qa.ps1'
$PlaytestTelemetryScript = Join-Path $PSScriptRoot 'run_playtest_telemetry.ps1'

foreach ($ScriptPath in @($ValidateScript, $ExportScript, $VerifyScript, $PerformanceScript, $VisualQaScript, $PlaytestTelemetryScript)) {
    $Tokens = $null
    $Errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$Tokens, [ref]$Errors) | Out-Null
    if ($Errors.Count -gt 0) {
        throw "Release dependency has PowerShell parser errors: $ScriptPath -> $($Errors[0].Message)"
    }
}

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

Write-Host 'Building the canonical HYPERSONIC Windows package...' -ForegroundColor Cyan
& $ExportScript -GodotBin $GodotBin -OutputPath $OutputPath

Write-Host 'Launching and verifying the packaged HYPERSONIC runtime...' -ForegroundColor Cyan
& $VerifyScript -Executable $OutputPath

Write-Host 'HYPERSONIC Windows release gate passed.' -ForegroundColor Green
