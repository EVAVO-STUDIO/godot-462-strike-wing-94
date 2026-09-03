[CmdletBinding()]
param([string]$MagickBin = '')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'assets\source\effects\pickups\pickup_animation_sheet.svg'
$runtime = Join-Path $root 'assets\runtime\effects\pickups'
$preview = Join-Path $root 'work\pickup_animation_sheet_v2.png'
if (-not $MagickBin) {
    $command = Get-Command magick -ErrorAction SilentlyContinue
    if (-not $command) { throw 'ImageMagick was not found.' }
    $MagickBin = $command.Source
}
if (-not (Test-Path -LiteralPath $source)) { throw "Missing pickup source: $source" }
New-Item -ItemType Directory -Force -Path $runtime,(Split-Path -Parent $preview) | Out-Null
& $MagickBin -background none $source -alpha on -resize '128x128!' $preview
if ($LASTEXITCODE -ne 0) { throw 'Pickup sheet rasterization failed.' }
$kinds = @('shield','repair','bomb','weapon')
for ($row = 0; $row -lt $kinds.Count; $row++) {
    for ($frame = 0; $frame -lt 4; $frame++) {
        $geometry = "32x32+$($frame * 32)+$($row * 32)"
        $output = Join-Path $runtime "$($kinds[$row])_$frame.png"
        & $MagickBin $preview -crop $geometry +repage -strip PNG32:$output
        if ($LASTEXITCODE -ne 0) { throw "Pickup frame export failed: $output" }
    }
}
Write-Host "HYPERSONIC pickup art built: $runtime" -ForegroundColor Green
