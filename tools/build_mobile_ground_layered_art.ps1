param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\mobile_ground_layered\mobile_ground_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\mobile_ground_layered'

if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Mobile-ground source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Invoke-Magick {
    param([string[]]$Arguments, [string]$Label)
    & $Magick @Arguments
    if ($LASTEXITCODE -ne 0) { throw "ImageMagick failed while building $Label" }
}

function Build-Component {
    param(
        [string]$Name,
        [string]$Crop,
        [string]$Resize,
        [string]$Canvas,
        [string]$Gravity = 'center'
    )
    $Destination = Join-Path $Output "$Name.png"
    Invoke-Magick @(
        $Source, '-crop', $Crop, '+repage', '-trim', '+repage',
        '-filter', 'Lanczos', '-resize', $Resize,
        '-gravity', $Gravity, '-background', 'none', '-extent', $Canvas,
        '-colors', '40', '-depth', '8', $Destination
    ) $Name
}

Build-Component 'light_tank_base' '390x500+60+30' '34x40' '36x44'
Build-Component 'sam_truck_base' '330x520+520+25' '29x42' '32x46'
Build-Component 'aa_carrier_base' '390x520+1010+25' '36x42' '40x46'

Build-Component 'light_tank_turret' '190x240+35+645' '20x24' '44x44'
Build-Component 'light_tank_barrel' '75x310+255+595' 'x25' '44x44' 'north'
Build-Component 'sam_launcher_stowed' '175x285+375+625' 'x27' '44x44' 'north'
Build-Component 'sam_launcher_rising' '175x300+605+610' 'x29' '44x44' 'north'
Build-Component 'sam_launcher_deployed' '180x340+805+565' 'x31' '44x44' 'north'
Build-Component 'sam_launcher_launch' '180x305+1010+605' 'x29' '44x44' 'north'
Build-Component 'aa_weapon_head' '175x250+1190+635' '24x28' '48x48'
Build-Component 'aa_twin_barrels' '105x315+1375+590' 'x28' '48x48' 'north'

$BaseWells = @{
    'light_tank_base' = 'circle 18,20 24,20'
    'sam_truck_base' = 'circle 16,21 22,21'
    'aa_carrier_base' = 'circle 20,22 27,22'
}
foreach ($Name in $BaseWells.Keys) {
    $Path = Join-Path $Output "$Name.png"
    Invoke-Magick @($Path, '-fill', '#161b1d', '-draw', $BaseWells[$Name], $Path) "$Name mounting well"
}

Write-Host 'Built HYPERSONIC layered mobile ground art.'
