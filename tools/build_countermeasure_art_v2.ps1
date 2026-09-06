$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot "assets/source/effects/countermeasure_v2"
$runtimeRoot = Join-Path $repoRoot "assets/runtime/effects/countermeasure"
$candidateRoot = Join-Path $repoRoot "work/countermeasure_v2/candidates"
$finishedRoot = Join-Path $repoRoot "work/countermeasure_v2/finished"
$sheet = Join-Path $candidateRoot "flare_burst_v2.png"
$finisher = "C:\GitRepos\evavo-art-studio\tools\finish_raster_asset.mjs"

New-Item -ItemType Directory -Force -Path $candidateRoot,$finishedRoot,$runtimeRoot | Out-Null
& magick -background none -density 96 (Join-Path $sourceRoot "flare_burst_v2.svg") -resize 192x56! $sheet
if ($LASTEXITCODE -ne 0) { throw "Could not rasterize the governed countermeasure sheet." }

for ($index = 0; $index -lt 4; $index++) {
    $candidate = Join-Path $candidateRoot ("flare_{0}.png" -f $index)
    $finished = Join-Path $finishedRoot ("flare_{0}.png" -f $index)
    $destination = Join-Path $runtimeRoot ("flare_{0}.png" -f $index)
    & magick $sheet -crop ("48x56+{0}+0" -f ($index * 48)) +repage -define png:color-type=6 $candidate
    if ($LASTEXITCODE -ne 0) { throw "Could not extract countermeasure frame $index." }
    & node $finisher --input $candidate --output $finished --preset web-hero --spec (Join-Path $sourceRoot "finish_spec.json") --print-evidence
    if ($LASTEXITCODE -ne 0) { throw "EVAVO Art Studio rejected countermeasure frame $index." }
    Copy-Item -LiteralPath $finished -Destination $destination -Force
}

Write-Host "Built four governed VX-94 countermeasure v2 frames."
