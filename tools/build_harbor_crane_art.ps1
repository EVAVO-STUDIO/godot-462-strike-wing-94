$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "assets/source/environments/candidates/landmarks/harbor_crane_candidate_02_raw.png"
$output = Join-Path $repoRoot "assets/runtime/environments/landmarks/harbor_cranes.png"
$work = Join-Path $repoRoot "work/harbor_crane_master.png"
if (-not (Test-Path -LiteralPath $source)) { throw "Missing harbor crane source: $source" }
New-Item -ItemType Directory -Force (Split-Path -Parent $work) | Out-Null

# Rotate the top-down crane so its boom reaches laterally from quay to water,
# preserve source alpha, and finish at the shared 128x160 landmark registration.
& magick $source -trim +repage -rotate 90 -filter Lanczos -resize "124x104>" `
    -gravity center -background none -extent 128x160 `
    -channel A -threshold 50% +channel -colorspace sRGB -dither FloydSteinberg -colors 30 `
    -channel A -threshold 50% +channel $work
if ($LASTEXITCODE -ne 0) { throw "Failed to master harbor crane source." }
& magick $work -colors 24 -channel A -threshold 50% +channel -alpha on -define png:color-type=6 $output
if ($LASTEXITCODE -ne 0) { throw "Failed to write harbor crane runtime sprite." }
Write-Host "Built $output"
