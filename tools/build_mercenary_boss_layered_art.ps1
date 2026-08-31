param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\mercenary_boss_layered\mercenary_boss_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\mercenary_boss_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Mercenary-boss component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas, [double]$Rotate = 0.0)
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -background none -rotate $Rotate -gravity center -extent $Canvas -colors 56 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build mercenary-boss component: $Name" }
}

Build-Component 'gunship_collar' '275x245+25+15' '24x21' '28x25'
Build-Component 'gunship_turret' '195x235+320+25' '22x24' '26x28'
Build-Component 'gunship_barrel' '85x230+550+25' '10x27' '14x31'
Build-Component 'gunship_barrel_recoil' '85x230+660+25' '10x23' '14x31'
Build-Component 'gunship_barrel_hot' '85x230+770+25' '10x27' '14x31'
Build-Component 'gunship_engine_normal' '175x245+885+15' '20x24' '24x28'
Build-Component 'gunship_engine_hot' '175x245+1085+15' '20x24' '24x28'
Build-Component 'gunship_engine_damaged' '185x245+1285+15' '20x24' '24x28'
Build-Component 'gunship_cracked_plate' '165x190+1480+55' '18x20' '22x24'

Build-Component 'train_collar' '280x225+20+275' '24x19' '28x23'
Build-Component 'train_turret' '195x220+325+285' '22x24' '26x28'
Build-Component 'train_barrel' '100x220+540+285' '11x27' '15x31'
Build-Component 'train_barrel_recoil' '100x220+655+285' '11x23' '15x31'
Build-Component 'train_barrel_hot' '100x220+770+285' '11x27' '15x31'
Build-Component 'train_turret_damaged' '210x225+895+285' '23x25' '27x29'
Build-Component 'train_vent_closed' '105x90+1125+300' '12x10' '14x12'
Build-Component 'train_vent_open' '105x90+1125+395' '12x10' '14x12'
Build-Component 'train_bogie_intact' '175x145+1250+325' '18x13' '22x17'
Build-Component 'train_bogie_damaged' '190x145+1440+325' '19x13' '23x17'

Build-Component 'cruiser_collar' '235x175+35+525' '24x17' '28x21'
Build-Component 'cruiser_turret' '200x180+320+530' '22x23' '26x27'
Build-Component 'cruiser_barrel' '175x180+545+530' '12x27' '16x31'
Build-Component 'cruiser_barrel_recoil' '175x180+750+530' '12x23' '16x31'
Build-Component 'cruiser_hatch_port' '300x170+970+535' '25x13' '29x17'
Build-Component 'cruiser_hatch_starboard' '300x170+1300+535' '25x13' '29x17'
Build-Component 'cruiser_cells_closed' '185x215+25+710' '20x22' '24x26'
Build-Component 'cruiser_cells_opening' '185x215+240+710' '20x22' '24x26'
Build-Component 'cruiser_cells_open' '185x215+450+710' '20x22' '24x26'
Build-Component 'cruiser_cells_fire' '195x225+645+705' '20x23' '24x26'
Build-Component 'cruiser_radar_damaged' '215x205+915+700' '22x20' '26x24'
Build-Component 'cruiser_scorched_deck' '475x190+1150+710' '42x17' '46x21'

Write-Host 'Built HYPERSONIC layered mercenary-boss art.'
