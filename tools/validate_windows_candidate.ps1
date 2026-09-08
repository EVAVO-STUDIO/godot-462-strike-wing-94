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

Write-Host 'Verifying exact-SHA human campaign, visual, audio and balance signoff...' -ForegroundColor Cyan
& $HumanSignoffGate -SignoffPath $SignoffPath

if (-not (Test-Path -LiteralPath $ReceiptPath)) { throw "Automated release receipt is missing: $ReceiptPath" }
$Receipt = Get-Content -Raw -LiteralPath $ReceiptPath | ConvertFrom-Json
$HeadSha = (& git -C $Root rev-parse HEAD).Trim()
if ([string]$Receipt.source.head_sha -ne $HeadSha) {
    throw "Release receipt HEAD '$($Receipt.source.head_sha)' does not match current HEAD '$HeadSha'."
}
if ([string]$Receipt.package.identity_version -ne $ProductVersion) {
    throw "Release receipt identity version '$($Receipt.package.identity_version)' does not match '$ProductVersion'."
}

Write-Host "HYPERSONIC Windows candidate gate passed for $ProductVersion at $HeadSha." -ForegroundColor Green
