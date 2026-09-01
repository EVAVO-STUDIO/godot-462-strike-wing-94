$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "assets/source/environments/candidates/landmarks/river_bridge_candidate_02_raw.png"
$output = Join-Path $repoRoot "assets/runtime/environments/landmarks/river_bridge.png"
$work = Join-Path $repoRoot "work/river_bridge_master.png"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing river bridge source: $source"
}

New-Item -ItemType Directory -Force (Split-Path -Parent $work) | Out-Null

# Preserve the generated alpha, remove empty source padding, then master the long
# horizontal span into the established 128x160 landmark registration. A bounded
# palette keeps material changes legible at authentic sprite scale.
& magick $source -trim +repage -filter Lanczos -resize "126x56>" `
	-gravity center -background none -extent 128x160 `
	-channel A -threshold 50% +channel `
	-colorspace sRGB -dither FloydSteinberg -colors 30 `
	-channel A -threshold 50% +channel $work
if ($LASTEXITCODE -ne 0) { throw "Failed to master river bridge source." }

& magick $work -colors 24 -channel A -threshold 50% +channel `
	-alpha on -define png:color-type=6 $output
if ($LASTEXITCODE -ne 0) { throw "Failed to write river bridge runtime sprite." }

Write-Host "Built $output"
