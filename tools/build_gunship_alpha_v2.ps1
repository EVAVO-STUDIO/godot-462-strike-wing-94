[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\mercenary_boss\gunship_alpha_source_v2.png'
$Output = Join-Path $Root 'assets\runtime\enemies\mercenary_boss\gunship_alpha_idle.png'

$Magick = Get-Command magick -ErrorAction Stop
if (-not (Test-Path -LiteralPath $Source)) { throw "Missing gunship source: $Source" }

& $Magick.Source $Source `
    -trim +repage `
    -filter LanczosSharp `
    -resize '90x74!' `
    -unsharp '0x0.9+1.1+0.03' `
    -contrast-stretch '0.8%x0.4%' `
    -gravity center `
    -background none `
    -extent 94x78 `
    "PNG32:$Output"
if ($LASTEXITCODE -ne 0) { throw "ImageMagick failed with exit code $LASTEXITCODE" }

$Description = & $Magick.Source identify -format '%wx%h %[channels] %[pixel:p{0,0}]' $Output
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect rendered gunship sprite.' }
if ($Description -notmatch '^94x78 srgba? .*\(0,0,0,0\)$') {
    throw "Gunship sprite failed geometry/alpha-edge admission: $Description"
}

Write-Host "Built gunship_alpha_idle.png ($Description)" -ForegroundColor Green
