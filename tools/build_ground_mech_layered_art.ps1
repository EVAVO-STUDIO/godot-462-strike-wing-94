param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\ground_mech_layered\ground_mech_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\ground_mech_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Ground-mech component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas, [string]$Gravity = 'north')
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity $Gravity -background none -extent $Canvas -colors 40 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build ground-mech component: $Name" }
}

Build-Component 'security_cannon' '190x730+55+40' 'x36' '18x38'
Build-Component 'security_cannon_recoil' '175x570+425+40' 'x32' '18x38'
Build-Component 'security_barrel' '90x440+270+175' 'x27' '12x30'
Build-Component 'security_shield' '150x370+595+200' 'x25' '16x28'
Build-Component 'security_collar' '180x180+165+805' '12x12' '14x14' 'center'

Build-Component 'salvage_cutter_arm' '220x600+770+40' 'x36' '18x38'
Build-Component 'salvage_grapple_open' '205x600+1150+40' 'x36' '18x38'
Build-Component 'salvage_grapple_closed' '180x600+1350+40' 'x36' '18x38'
Build-Component 'salvage_disc_0' '190x190+775+625' '14x14' '16x16' 'center'
Build-Component 'salvage_disc_1' '190x190+955+625' '14x14' '16x16' 'center'
Build-Component 'salvage_disc_2' '190x190+1135+625' '14x14' '16x16' 'center'
Build-Component 'salvage_collar' '180x180+865+815' '12x12' '14x14' 'center'

Write-Host 'Built HYPERSONIC layered ground-mech art.'
