[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Require-File([string]$RelativePath) {
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing release-contract file: $RelativePath" }
    return $Path
}

$ReadmePath = Require-File 'README.md'
$SavePath = Require-File 'scripts/campaign_save.gd'
$IdentityPath = Require-File 'data/product_identity.json'
$ExportPath = Require-File 'export_presets.cfg'
$ProjectPath = Require-File 'project.godot'
$AgentsPath = Require-File 'AGENTS.md'
Require-File 'docs/PORTFOLIO_RELEASE_TRANCHE.md' | Out-Null
Require-File 'docs/RELEASE_COMPLETION_AUDIT_2026-09-08.md' | Out-Null
Require-File 'docs/RELEASE_SIGNOFF_TEMPLATE.json' | Out-Null
Require-File 'tools/resolve_release_godot.ps1' | Out-Null
Require-File 'tools/write_windows_release_receipt.ps1' | Out-Null
Require-File 'tools/verify_human_release_signoff.ps1' | Out-Null
Require-File 'tools/validate_windows_candidate.ps1' | Out-Null

$Readme = Get-Content -Raw -LiteralPath $ReadmePath
$Save = Get-Content -Raw -LiteralPath $SavePath
$Identity = Get-Content -Raw -LiteralPath $IdentityPath | ConvertFrom-Json
$Export = Get-Content -Raw -LiteralPath $ExportPath
$Project = Get-Content -Raw -LiteralPath $ProjectPath
$Agents = Get-Content -Raw -LiteralPath $AgentsPath

$SaveMatch = [regex]::Match($Save, 'SAVE_VERSION\s*:=\s*(\d+)')
if (-not $SaveMatch.Success) { throw 'Unable to resolve campaign SAVE_VERSION.' }
$SaveVersion = [int]$SaveMatch.Groups[1].Value
$PreviousVersion = $SaveVersion - 1
if (-not $Readme.Contains("versioned v$SaveVersion local autosave")) {
    throw "README save authority drift: expected v$SaveVersion."
}
if ($PreviousVersion -ge 1 -and -not $Readme.Contains("v1-v$PreviousVersion migration compatibility")) {
    throw "README migration range drift: expected v1-v$PreviousVersion."
}

$ProductVersion = ([string]$Identity.version).Trim()
if (-not $ProductVersion) { throw 'data/product_identity.json version is blank.' }
$ExpectedExportVersion = 'application/product_version="' + $ProductVersion + '"'
if (-not $Export.Contains($ExpectedExportVersion)) {
    throw "export_presets.cfg product version does not match product identity '$ProductVersion'."
}

foreach ($Token in @(
    'name="Windows Desktop"',
    'export_path="build/windows/HYPERSONIC.exe"',
    'binary_format/embed_pck=true',
    'exclude_filter="assets/source/**,docs/**,tools/**,work/**"',
    'application/company_name="EVAVO Studio"',
    'application/product_name="HYPERSONIC"'
)) {
    if (-not $Export.Contains($Token)) { throw "Windows export contract missing: $Token" }
}

foreach ($Token in @(
    'window/size/viewport_width=640',
    'window/size/viewport_height=360',
    'window/size/window_width_override=1280',
    'window/size/window_height_override=720',
    'window/stretch/mode="canvas_items"'
)) {
    if (-not $Project.Contains($Token)) { throw "Desktop presentation contract missing: $Token" }
}

if (-not $Agents.Contains('release candidate') -or -not $Agents.Contains('docs/PORTFOLIO_RELEASE_TRANCHE.md')) {
    throw 'AGENTS.md no longer exposes the release-candidate tranche to coding agents.'
}
if (-not $Readme.Contains('validate_windows_candidate.ps1') -or -not $Readme.Contains('HYPERSONIC.release.json')) {
    throw 'README no longer documents the final candidate gate and exact-SHA receipt.'
}

Write-Host "HYPERSONIC release contract passed: save v$SaveVersion, product $ProductVersion." -ForegroundColor Green
