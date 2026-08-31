param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\naval_layered\naval_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\naval_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Naval component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas, [string]$Gravity = 'north')
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity $Gravity -background none -extent $Canvas -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build naval component: $Name" }
}

Build-Component 'river_mount' '180x180+45+85' '12x12' '14x14' 'center'
Build-Component 'river_turret' '75x205+580+112' 'x26' '14x28'
Build-Component 'river_turret_recoil' '65x155+765+112' 'x22' '14x28'

Build-Component 'torpedo_turret' '205x270+52+335' 'x19' '14x21'
Build-Component 'torpedo_launcher_closed' '135x235+462+365' 'x17' '12x19'
Build-Component 'torpedo_launcher_opening' '135x235+615+365' 'x17' '12x19'
Build-Component 'torpedo_launcher_open' '135x235+765+365' 'x17' '12x19'
Build-Component 'torpedo_launcher_fire' '135x235+920+365' 'x17' '12x19'

Build-Component 'fast_turret' '205x300+48+650' 'x21' '16x23'
Build-Component 'fast_radar_pedestal' '125x185+515+690' 'x11' '10x13'
Build-Component 'fast_radar_array' '205x185+680+690' 'x10' '14x12' 'center'

Build-Component 'corvette_turret' '205x305+45+990' 'x23' '18x25'
Build-Component 'corvette_launcher_closed' '130x270+382+1020' 'x21' '15x23'
Build-Component 'corvette_launcher_opening' '130x270+525+1020' 'x21' '15x23'
Build-Component 'corvette_launcher_open' '130x270+670+1020' 'x21' '15x23'
Build-Component 'corvette_launcher_fire' '130x270+800+1020' 'x21' '15x23'
Build-Component 'corvette_mount' '145x170+970+1080' '11x11' '13x13' 'center'

Write-Host 'Built HYPERSONIC layered naval art.'
