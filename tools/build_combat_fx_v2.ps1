param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $Root 'assets\source\effects\combat_fx_v2'
$RuntimeRoot = Join-Path $Root 'assets\runtime\effects'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }

function Build-Frame {
    param([string]$Source,[string]$Destination,[string]$Crop,[string]$Resize,[string]$Canvas)
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity center -background none -extent $Canvas -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build combat FX frame: $Destination" }
}

$ProjectileSource = Join-Path $SourceRoot 'projectile_sheet_source_v2.png'
$ProjectileFamilies = @('ballistic','enemy_cannon','homing_missile','needle_rail','plasma_lance','support_rocket','strategic_warhead','precision_bomb')
$ProjectileRows = @('180x170+140+0','180x170+140+170','180x180+140+340','180x180+140+520','180x190+140+700','180x180+140+890','180x220+140+1070','180x246+140+1290')
$ProjectileColumns = @(0,190,380,570)
for($row=0;$row -lt $ProjectileFamilies.Count;$row++) {
    for($frame=0;$frame -lt 4;$frame++) {
        $crop = $ProjectileRows[$row] -replace '\+140\+', ('+'+(140+$ProjectileColumns[$frame])+'+')
        Build-Frame $ProjectileSource (Join-Path $RuntimeRoot "projectiles\$($ProjectileFamilies[$row])\$frame.png") $crop '10x18' '16x24'
    }
}

$ImpactSource = Join-Path $SourceRoot 'impact_sheet_source_v2.png'
$ImpactFamilies = @('muzzle','rotary_muzzle','armor_hit','shield_hit','bomb_impact','emp_disruption','water_impact','dust_impact','strategic_blast')
$ImpactY = @(0,170,335,500,665,830,995,1160,1325)
$ImpactH = @(170,165,165,165,165,165,165,165,211)
for($row=0;$row -lt $ImpactFamilies.Count;$row++) {
    for($frame=0;$frame -lt 4;$frame++) {
        $crop = "256x$($ImpactH[$row])+$($frame*256)+$($ImpactY[$row])"
        $canvas = '24x24'
        $resize = '20x20'
        if($ImpactFamilies[$row] -eq 'strategic_blast') { $canvas = '128x128'; $resize = '116x116' }
        Build-Frame $ImpactSource (Join-Path $RuntimeRoot "impacts\$($ImpactFamilies[$row])\$frame.png") $crop $resize $canvas
    }
}

$PersistentSource = Join-Path $SourceRoot 'persistent_sheet_source_v2.png'
$PersistentFamilies = @('damage_smoke','damage_fire','damage_sparks','afterburner','contrail','debris','sonic_boom')
for($row=0;$row -lt $PersistentFamilies.Count;$row++) {
    $y = [int][Math]::Floor($row*1536/7)
    $nextY = [int][Math]::Floor(($row+1)*1536/7)
    for($frame=0;$frame -lt 4;$frame++) {
        $crop = "256x$($nextY-$y)+$($frame*256)+$y"
        $canvas = '32x40'
        $resize = '28x36'
        if($PersistentFamilies[$row] -eq 'sonic_boom') { $canvas = '64x64'; $resize = '58x58' }
        Build-Frame $PersistentSource (Join-Path $RuntimeRoot "persistent\$($PersistentFamilies[$row])\$frame.png") $crop $resize $canvas
    }
}

# The generative source plate is useful for organic smoke and exhaust, but its
# U-shaped sonic row reads like translucent wings around a plan-view aircraft.
# Override that family with the hand-authored, centre-registered lateral
# pressure fronts used by the final hypersonic presentation.
$SonicMaster = Join-Path $Root 'assets\source\effects\persistent\sonic_boom_runtime_master.svg'
$SonicMasterPreview = [System.IO.Path]::ChangeExtension($SonicMaster, '.png')
& $Magick -background none $SonicMaster -depth 8 $SonicMasterPreview
if ($LASTEXITCODE -ne 0) { throw 'Failed to rasterize the authored sonic-boom master.' }
for($frame=0;$frame -lt 4;$frame++) {
    $Destination = Join-Path $RuntimeRoot "persistent\sonic_boom\$frame.png"
    & $Magick $SonicMasterPreview -crop "64x64+$($frame*64)+0" +repage -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build authored sonic-boom frame: $frame" }
}

Write-Host 'Built HYPERSONIC combat FX v2 library.'
