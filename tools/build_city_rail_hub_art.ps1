$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "assets/source/environments/candidates/landmarks/city_rail_hub_candidate_02_raw.png"
$output = Join-Path $repoRoot "assets/runtime/environments/landmarks/city_rail_hub.png"
$work = Join-Path $repoRoot "work/city_rail_hub_master.png"
if (-not (Test-Path -LiteralPath $source)) { throw "Missing city rail-hub source: $source" }
New-Item -ItemType Directory -Force (Split-Path -Parent $work) | Out-Null
& magick $source -trim +repage -filter Lanczos -resize "120x150>" `
    -gravity center -background none -extent 128x160 `
    -channel A -threshold 50% +channel -colorspace sRGB -dither FloydSteinberg -colors 30 `
    -channel A -threshold 50% +channel $work
if ($LASTEXITCODE -ne 0) { throw "Failed to master city rail-hub source." }
& magick $work -colors 24 -channel A -threshold 50% +channel -alpha on -define png:color-type=6 $output
if ($LASTEXITCODE -ne 0) { throw "Failed to write city rail-hub runtime sprite." }
Write-Host "Built $output"
