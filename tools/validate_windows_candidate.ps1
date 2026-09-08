[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$OutputPath = 'build/windows/HYPERSONIC.exe',
    [string]$SignoffPath = 'work/release_signoff.json'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$AutomatedGate = Join-Path $PSScriptRoot 'validate_windows_release.ps1'
$HumanSignoffGate = Join-Path $PSScriptRoot 'verify_human_release_signoff.ps1'
$NativeHandoffGate = Join-Path $PSScriptRoot 'verify_native_release_handoff.ps1'
$IdentityPath = Join-Path $Root 'data/product_identity.json'
$ExportPresetPath = Join-Path $Root 'export_presets.cfg'
$ReceiptPath = Join-Path $Root 'build/windows/HYPERSONIC.release.json'

$Identity = Get-Content -Raw -LiteralPath $IdentityPath | ConvertFrom-Json
$ProductVersion = ([string]$Identity.version).Trim()
if (-not $ProductVersion) { throw 'Product identity version is blank.' }
if ($ProductVersion -match '(?i)(^|[-.+])dev($|[-.+])') {
    throw "Final candidate validation refuses development version '$ProductVersion'. Promote data/product_identity.json and export_presets.cfg to an explicit release/RC version first."
}

$ExportText = Get-Content -Raw -LiteralPath $ExportPresetPath
$ExpectedVersionToken = 'application/product_version="' + $ProductVersion + '"'
if (-not $ExportText.Contains($ExpectedVersionToken)) {
    throw "Windows export product version is not synchronized with product identity version '$ProductVersion'."
}

Write-Host "Running automated Windows candidate gate for HYPERSONIC $ProductVersion..." -ForegroundColor Cyan
& $AutomatedGate -GodotBin $GodotBin -OutputPath $OutputPath

Write-Host 'Verifying exact-SHA human campaign, onboarding, visual, audio and balance signoff...' -ForegroundColor Cyan
& $HumanSignoffGate -SignoffPath $SignoffPath

$AbsoluteSignoff = if ([System.IO.Path]::IsPathRooted($SignoffPath)) {
    [System.IO.Path]::GetFullPath($SignoffPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $Root $SignoffPath))
}
if (-not (Test-Path -LiteralPath $AbsoluteSignoff)) { throw "Human release signoff is missing: $AbsoluteSignoff" }
$Signoff = Get-Content -Raw -LiteralPath $AbsoluteSignoff | ConvertFrom-Json
if (-not [bool]$Signoff.native_test_lab.controller_maintenance_reviewed) {
    throw 'Human release signoff must confirm the controller-maintenance native journey was reviewed.'
}
if (-not [bool]$Signoff.native_test_lab.controller_menu_navigation_reviewed) {
    throw 'Human release signoff must confirm controller Options/Flight-Controls navigation was reviewed.'
}

Write-Host 'Verifying ten-journey native Test Lab authority, including controller maintenance and menu navigation...' -ForegroundColor Cyan
& $NativeHandoffGate -HandoffPath ([string]$Signoff.native_test_lab.handoff_path)

if (-not (Test-Path -LiteralPath $ReceiptPath)) { throw "Automated release receipt is missing: $ReceiptPath" }
$Receipt = Get-Content -Raw -LiteralPath $ReceiptPath | ConvertFrom-Json
$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ([string]$Receipt.source.head_sha -ne $HeadSha) {
    throw "Release receipt HEAD '$($Receipt.source.head_sha)' does not match current HEAD '$HeadSha'."
}
if ([string]$Receipt.package.identity_version -ne $ProductVersion) {
    throw "Release receipt identity version '$($Receipt.package.identity_version)' does not match '$ProductVersion'."
}

Write-Host "HYPERSONIC Windows candidate gate passed for $ProductVersion at $HeadSha, including the ten-journey controller front-end evidence set." -ForegroundColor Green
