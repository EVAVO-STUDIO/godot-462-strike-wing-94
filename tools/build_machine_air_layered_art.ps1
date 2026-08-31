param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\machine_air_layered\machine_air_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\machine_air_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Machine-air component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param(
        [string]$Name,
        [string]$Crop,
        [string]$Resize,
        [string]$Canvas,
        [double]$Rotate = 0.0
    )
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -background none -rotate $Rotate -gravity center -extent $Canvas -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build machine-air component: $Name" }
}

Build-Component 'core_dim' '175x180+70+55' '11x11' '13x13'
Build-Component 'core_active' '175x180+320+55' '11x11' '13x13'
Build-Component 'core_overload' '175x180+555+55' '11x11' '13x13'
Build-Component 'core_collar' '190x195+820+50' '13x13' '15x15'
Build-Component 'core_damaged' '220x210+570+690' '12x12' '14x14'

Build-Component 'hunter_mount' '175x210+1105+60' '15x18' '17x20'
Build-Component 'hunter_barrel' '210x65+1315+100' 'x16' '6x18' 90
Build-Component 'hunter_barrel_recoil' '210x65+1315+180' 'x13' '6x18' 90

Build-Component 'bomber_bay_closed' '185x315+40+305' '15x20' '17x22'
Build-Component 'bomber_bay_opening' '185x315+245+305' '15x20' '17x22'
Build-Component 'bomber_bay_open' '185x315+450+305' '15x20' '17x22'
Build-Component 'bomber_bay_fire' '185x315+635+305' '15x20' '17x22'
Build-Component 'bomber_door_left' '105x285+815+325' '6x17' '8x19'
Build-Component 'bomber_door_right' '105x285+925+325' '6x17' '8x19'

Build-Component 'missile_hatch_closed' '125x300+1070+315' '10x19' '12x21'
Build-Component 'missile_hatch_opening' '125x300+1190+315' '10x19' '12x21'
Build-Component 'missile_hatch_open' '125x300+1320+315' '10x19' '12x21'
Build-Component 'missile_hatch_fire' '125x390+1460+315' '10x25' '12x27'
Build-Component 'missile_hatch_door' '130x165+75+730' '10x13' '12x15'
Build-Component 'mounted_missile' '95x230+340+675' '6x15' '8x17'

Build-Component 'armor_fragment_large' '90x130+835+735' '8x11' '10x13'
Build-Component 'armor_fragment_small' '70x105+950+750' '6x9' '8x11'
Build-Component 'thruster_dim' '105x165+1090+715' '8x10' '10x12'
Build-Component 'thruster_active' '105x180+1260+715' '8x11' '10x13'
Build-Component 'thruster_overload' '105x220+1425+715' '8x14' '10x16'

Write-Host 'Built HYPERSONIC layered machine-air art.'
