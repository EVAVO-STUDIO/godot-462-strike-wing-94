param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\infantry_layered\infantry_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\infantry_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Infantry component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas, [string]$Gravity = 'center')
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity $Gravity -background none -extent $Canvas -colors 36 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build infantry component: $Name" }
}

Build-Component 'rifle_advance_0' '125x225+125+65' 'x15' '10x16'
Build-Component 'rifle_advance_1' '125x225+325+65' 'x15' '10x16'
Build-Component 'rifle_advance_2' '125x225+510+65' 'x15' '10x16'
Build-Component 'rifle_aim' '165x205+700+70' 'x13' '12x14'
Build-Component 'rifle_fire' '185x205+930+70' 'x13' '12x14'
Build-Component 'rifle_flinch' '120x190+1150+90' 'x13' '10x14'
Build-Component 'rifle_kneel' '180x145+125+325' 'x10' '14x11'
Build-Component 'rifle_kneel_fire' '180x145+350+325' 'x10' '14x11'
Build-Component 'rifle_prone' '300x120+570+350' 'x7' '19x8'
Build-Component 'radio_operator' '130x165+900+305' 'x12' '10x13'
Build-Component 'dropped_rifle' '130x115+1080+350' 'x8' '11x9'
Build-Component 'radio_pack' '85x145+1240+315' 'x10' '8x11'

Build-Component 'heavy_loader' '185x165+325+545' 'x11' '13x12'
Build-Component 'heavy_spotter' '125x170+545+540' 'x12' '10x13'
Build-Component 'heavy_tripod' '165x235+750+545' 'x18' '15x19'
Build-Component 'heavy_tripod_recoil' '165x235+955+545' 'x18' '15x19'
Build-Component 'heavy_ammo_crate' '115x145+1155+560' 'x9' '9x10'
Build-Component 'heavy_ammo_belt' '155x95+1295+610' 'x5' '12x6'

Build-Component 'fallen_rifleman' '245x165+65+805' 'x9' '18x10'
Build-Component 'fallen_heavy' '245x165+330+805' 'x9' '18x10'
Build-Component 'damaged_tripod' '125x130+660+820' 'x10' '11x11'
Build-Component 'loose_helmet' '80x85+825+835' '7x7' '8x8'
Build-Component 'loose_pack' '105x105+930+825' '8x8' '9x9'
Build-Component 'hit_dust_0' '160x120+1085+825' 'x8' '13x9'
Build-Component 'hit_dust_1' '170x110+1285+840' 'x7' '14x8'

Write-Host 'Built HYPERSONIC layered infantry art.'
