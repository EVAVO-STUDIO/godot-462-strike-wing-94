$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "assets/source/ui/hud/primary_meter_cluster_sheet.svg"
$output = Join-Path $repoRoot "assets/runtime/ui/hud/primary_meter_cluster"
$scratch = Join-Path $repoRoot "work/primary_meter_cluster_sheet.png"

New-Item -ItemType Directory -Force -Path $output | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $scratch) | Out-Null

& magick -background none -density 96 $source -resize 288x52! $scratch
if ($LASTEXITCODE -ne 0) { throw "Could not rasterize the primary meter source sheet." }

$frames = @(
    @{ Name = "hull_frame"; X = 0; Y = 0 },
    @{ Name = "shield_frame"; X = 96; Y = 0 },
    @{ Name = "energy_frame"; X = 192; Y = 0 },
    @{ Name = "hull_warning_frame"; X = 0; Y = 26 },
    @{ Name = "shield_warning_frame"; X = 96; Y = 26 },
    @{ Name = "energy_warning_frame"; X = 192; Y = 26 }
)

foreach ($frame in $frames) {
    $destination = Join-Path $output ($frame.Name + ".png")
    & magick $scratch -crop ("92x25+{0}+{1}" -f $frame.X, $frame.Y) +repage -define png:color-type=6 $destination
    if ($LASTEXITCODE -ne 0) { throw "Could not build $($frame.Name)." }
}

Remove-Item -LiteralPath $scratch
Write-Host "Built six primary HUD meter sprites."
