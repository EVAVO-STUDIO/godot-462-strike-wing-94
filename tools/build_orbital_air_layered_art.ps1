param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\orbital_air_layered\orbital_air_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\orbital_air_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Orbital-air component source not found: $Source" }
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
    if ($LASTEXITCODE -ne 0) { throw "Failed to build orbital-air component: $Name" }
}

Build-Component 'sentry_collar' '185x150+75+80' '15x12' '17x14'
Build-Component 'sentry_turret' '185x160+305+70' '15x13' '17x15'
Build-Component 'sentry_barrel' '355x65+550+90' 'x20' '6x22' 90
Build-Component 'sentry_barrel_recoil' '355x65+550+170' 'x16' '6x22' 90

Build-Component 'phase_nodes_dormant' '170x120+955+105' '18x10' '20x12'
Build-Component 'phase_nodes_active' '175x120+1160+105' '18x10' '20x12'
Build-Component 'phase_nodes_overload' '190x130+1340+95' '18x11' '20x13'
Build-Component 'phase_nodes_damaged' '180x135+75+300' '18x12' '20x14'

Build-Component 'beam_aperture_closed' '190x165+325+295' '16x14' '18x28' 90
Build-Component 'beam_aperture_opening' '190x165+600+295' '16x14' '18x28' 90
Build-Component 'beam_aperture_open' '190x165+870+295' '16x14' '18x28' 90
Build-Component 'beam_aperture_fire' '300x165+1130+295' '26x14' '18x28' 90

Build-Component 'rail_safe' '310x130+75+520' '10x27' '14x34' 90
Build-Component 'rail_charge_1' '300x130+430+520' '10x27' '14x34' 90
Build-Component 'rail_charge_2' '300x130+750+520' '10x27' '14x34' 90
Build-Component 'rail_fire' '360x130+1050+520' '11x31' '14x34' 90
Build-Component 'rail_capacitor_bank' '145x170+1440+485' '10x13' '12x15'
Build-Component 'rail_barrel' '355x65+550+90' 'x25' '6x27' 90

Build-Component 'orbital_thruster_dim' '180x185+70+690' '12x10' '14x12' 90
Build-Component 'orbital_thruster_active' '190x185+305+690' '13x11' '15x13' 90
Build-Component 'orbital_thruster_overload' '210x185+535+690' '14x12' '16x14' 90
Build-Component 'radiator_cool' '165x175+815+690' '10x14' '12x16'
Build-Component 'radiator_hot' '170x175+1020+690' '10x14' '12x16'
Build-Component 'orbital_fragment_large' '180x145+1235+715' '13x10' '15x12'
Build-Component 'orbital_fragment_small' '145x115+1440+740' '11x8' '13x10'

Write-Host 'Built HYPERSONIC layered BLACK SKY orbital-air art.'
