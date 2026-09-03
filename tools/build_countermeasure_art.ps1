$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "assets/source/effects/countermeasure/flare_sheet.svg"
$output = Join-Path $repoRoot "assets/runtime/effects/countermeasure"
$scratch = Join-Path $repoRoot "work/countermeasure_flare_sheet.png"

New-Item -ItemType Directory -Force -Path $output | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $scratch) | Out-Null
& magick -background none -density 96 $source -resize 128x40! $scratch
if ($LASTEXITCODE -ne 0) { throw "Could not rasterize countermeasure flare sheet." }
for ($index = 0; $index -lt 4; $index++) {
    $destination = Join-Path $output ("flare_{0}.png" -f $index)
    & magick $scratch -crop ("32x40+{0}+0" -f ($index * 32)) +repage -define png:color-type=6 $destination
    if ($LASTEXITCODE -ne 0) { throw "Could not build countermeasure frame $index." }
}
Remove-Item -LiteralPath $scratch
Write-Host "Built four VX-94 countermeasure frames."
