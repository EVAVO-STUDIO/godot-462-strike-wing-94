param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\human_air_layered\human_air_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\human_air_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Human-air component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas, [string]$Gravity = 'center')
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity $Gravity -background none -extent $Canvas -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build human-air component: $Name" }
}

function Build-Rotor {
    param([string]$Name, [double]$Angle)
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop '225x235+210+285' +repage -trim +repage -filter Lanczos -resize '28x28' -background none -gravity center -extent '36x36' -rotate $Angle -gravity center -extent '36x36' -colors 32 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build rotor component: $Name" }
}

Build-Component 'gunship_mount' '205x210+105+45' '13x13' '15x15'
Build-Component 'gunship_turret' '165x205+380+45' 'x18' '16x20'
Build-Component 'gunship_barrel' '145x245+615+50' 'x22' '12x24'
Build-Component 'gunship_barrel_recoil' '125x175+855+50' 'x17' '12x24'
Build-Component 'gunship_sensor' '85x90+1045+105' '7x7' '8x8'

Build-Rotor 'chopper_rotor_0' 0.0
Build-Rotor 'chopper_rotor_1' 22.5
Build-Rotor 'chopper_rotor_2' 45.0
Build-Rotor 'chopper_rotor_3' 67.5
Build-Component 'chopper_rotor_hub' '150x150+35+320' '11x11' '12x12'
Build-Component 'chopper_cannon' '105x135+1180+345' 'x13' '12x15'
Build-Component 'chopper_barrel' '90x195+1300+325' 'x18' '10x20'
Build-Component 'chopper_barrel_recoil' '80x145+1415+325' 'x13' '10x20'

Build-Component 'bomber_bay_closed' '185x205+120+550' 'x18' '20x20'
Build-Component 'bomber_bay_opening' '190x205+430+550' 'x18' '20x20'
Build-Component 'bomber_bay_open' '200x205+705+550' 'x18' '20x20'
Build-Component 'bomber_bay_fire' '205x205+995+550' 'x18' '20x20'
Build-Component 'bomber_door_left' '65x175+1260+555' 'x16' '7x18'
Build-Component 'bomber_door_right' '65x175+1350+555' 'x16' '7x18'

Build-Component 'missile_rail_loaded' '65x150+130+815' 'x12' '7x13'
Build-Component 'mounted_missile' '85x160+295+810' 'x13' '8x14'
Build-Component 'missile_rail_empty' '65x150+445+815' 'x12' '7x13'
Build-Component 'air_sensor_cluster' '115x90+640+855' '10x7' '11x8'
Build-Component 'damaged_turret' '155x175+840+800' 'x17' '16x19'
Build-Component 'separated_rotor_blade' '285x165+1045+805' 'x7' '29x8'

Write-Host 'Built HYPERSONIC layered human-air art.'
