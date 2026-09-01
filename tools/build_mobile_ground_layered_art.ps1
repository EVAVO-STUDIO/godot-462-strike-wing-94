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

# Mobile hulls keep their weaponless base registration while the tread/wheel
# contact highlights advance in four held exposures. This is deliberately a
# one-pixel material cycle rather than whole-sprite bobbing: the vehicle keeps
# its mass and turret pivot while no longer reading as a static cutout sliding
# over the terrain.
function Build-LocomotionFamily {
    param(
        [string]$Unit,
        [int]$LeftX0,
        [int]$LeftX1,
        [int]$RightX0,
        [int]$RightX1,
        [int]$Top,
        [int]$Bottom
    )
    $Base = Join-Path $Output "$Unit`_base.png"
    $Family = Join-Path $Output "locomotion\$Unit"
    New-Item -ItemType Directory -Force -Path $Family | Out-Null
    for ($Frame = 0; $Frame -lt 4; $Frame++) {
        $Y0 = $Top + $Frame * 2
        while ($Y0 -gt $Top + 5) { $Y0 -= 6 }
        $Bright = @()
        $Dark = @()
        for ($Y = $Y0; $Y -le $Bottom; $Y += 6) {
            $Bright += "line $LeftX0,$Y $LeftX1,$Y line $RightX0,$Y $RightX1,$Y"
            if ($Y + 2 -le $Bottom) { $Dark += "line $LeftX0,$($Y+2) $LeftX1,$($Y+2) line $RightX0,$($Y+2) $RightX1,$($Y+2)" }
        }
        $Destination = Join-Path $Family "$Frame.png"
        Invoke-Magick @(
            $Base,
            '-fill', '#929a94', '-draw', ($Bright -join ' '),
            '-fill', '#24292a', '-draw', ($Dark -join ' '),
            '-colors', '40', '-depth', '8', $Destination
        ) "$Unit locomotion frame $Frame"
    }
}

Build-LocomotionFamily 'light_tank' 4 6 29 31 8 36
Build-LocomotionFamily 'sam_truck' 3 5 26 28 9 38
Build-LocomotionFamily 'aa_carrier' 3 6 33 36 8 38

Write-Host 'Built HYPERSONIC layered mobile ground art.'
