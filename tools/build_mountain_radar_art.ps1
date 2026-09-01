param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\candidates\landmarks\mountain_radar_components_candidate_01_raw.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\mountain_radar_layered'
$Work = Join-Path $RepoRoot 'work\mountain_radar_build'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Missing layered mountain-radar source: $Source" }
New-Item -ItemType Directory -Force -Path $Output,$Work | Out-Null

function Build-Component([string]$Name,[string]$Crop,[string]$Resize,[string]$Extent,[int]$Colors) {
    $Temp = Join-Path $Work "$Name.png"
    $Destination = Join-Path $Output "$Name.png"
    & $MagickPath $Source -crop $Crop +repage -fuzz '18%' -transparent white -trim +repage -filter Lanczos -resize $Resize `
        -gravity center -background none -extent $Extent -channel A -threshold 42% +channel -colorspace sRGB -dither FloydSteinberg -colors $Colors `
        -channel A -threshold 50% +channel -define png:color-type=6 $Temp
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish mountain radar component: $Name" }
    & $MagickPath $Temp -colors $Colors -channel A -threshold 50% +channel -alpha on -define png:color-type=6 $Destination
}
Build-Component 'radar_base' '900x1024+0+0' '132x150>' '144x160' 30
Build-Component 'radar_dish' '636x900+900+50' '112x126>' '128x144' 28
Write-Host "Built layered mountain radar components in $Output"
