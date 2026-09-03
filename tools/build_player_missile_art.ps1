$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot "assets/source/effects/player_sidewinder"
$projectileOut = Join-Path $repoRoot "assets/runtime/effects/projectiles/player_sidewinder"
$reticleOut = Join-Path $repoRoot "assets/runtime/ui/hud/player_lock"
$scratchRoot = Join-Path $repoRoot "work/player_missile_art"

New-Item -ItemType Directory -Force -Path $projectileOut,$reticleOut,$scratchRoot | Out-Null
$projectileSheet = Join-Path $scratchRoot "sidewinder.png"
$reticleSheet = Join-Path $scratchRoot "reticle.png"
& magick -background none -density 96 (Join-Path $sourceRoot "sidewinder_sheet.svg") -resize 64x14! $projectileSheet
if ($LASTEXITCODE -ne 0) { throw "Could not rasterize AIM-9 sheet." }
& magick -background none -density 96 (Join-Path $sourceRoot "reticle_sheet.svg") -resize 96x32! $reticleSheet
if ($LASTEXITCODE -ne 0) { throw "Could not rasterize seeker reticle sheet." }
for ($index = 0; $index -lt 4; $index++) {
    & magick $projectileSheet -crop ("16x14+{0}+0" -f ($index * 16)) +repage -define png:color-type=6 (Join-Path $projectileOut ("{0}.png" -f $index))
    if ($LASTEXITCODE -ne 0) { throw "Could not build AIM-9 frame $index." }
}
for ($index = 0; $index -lt 3; $index++) {
    $name = @("track", "acquire", "locked")[$index]
    & magick $reticleSheet -crop ("32x32+{0}+0" -f ($index * 32)) +repage -define png:color-type=6 (Join-Path $reticleOut ("{0}.png" -f $name))
    if ($LASTEXITCODE -ne 0) { throw "Could not build seeker reticle frame $name." }
}
Remove-Item -LiteralPath $scratchRoot -Recurse
Write-Host "Built VX-94 AIM-9 projectile and seeker reticle sprites."
