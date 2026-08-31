param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe',
    [string]$Python = 'C:\Users\User\AppData\Local\Programs\Python\Python312\python.exe',
    [string]$SpriteStudioRoot = 'C:\GitRepos\evavo-sprite-studio'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $Root 'assets\source\effects\destruction_reward_v2'
$RawSource = Join-Path $SourceRoot 'destruction_reward_raw_v2.png'
$Config = Join-Path $SourceRoot 'cleanup.sprite.json'
$PickupSource = Join-Path $SourceRoot 'pickup_sheet_raw_v2.png'
$PickupConfig = Join-Path $SourceRoot 'pickup_cleanup.sprite.json'
$RuntimeRoot = Join-Path $Root 'assets\runtime\effects'
$Stage = Join-Path $Root 'work\destruction_reward_v2_stage'
$RawCells = Join-Path $Stage 'raw'
$RawPickupCells = Join-Path $Stage 'raw_pickups'
$Clean = Join-Path $Stage 'clean'
$CleanPickups = Join-Path $Stage 'clean_pickups'
$StudioSource = Join-Path $SpriteStudioRoot 'src'

foreach($path in @($Magick,$Python,$RawSource,$Config,$PickupSource,$PickupConfig)) {
    if(-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file not found: $path" }
}
if(-not (Test-Path -LiteralPath $StudioSource -PathType Container)) { throw "Sprite Studio source not found: $StudioSource" }
New-Item -ItemType Directory -Force -Path $RawCells,$RawPickupCells,$Clean,$CleanPickups | Out-Null
Get-ChildItem -LiteralPath $RawCells -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $RawPickupCells -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force

function Export-RawCell([string]$Name,[string]$Crop) {
    & $Magick $RawSource -crop $Crop +repage (Join-Path $RawCells "$Name.png")
    if($LASTEXITCODE -ne 0) { throw "Failed to crop source cell: $Name" }
}

$ExplosionCrops = @('170x250+10+45','180x250+195+45','180x250+380+45','180x250+565+45','180x250+750+45','180x250+945+45','180x250+1135+45','180x250+1325+45')
for($i=0;$i -lt 8;$i++) { Export-RawCell "explosion_$i" $ExplosionCrops[$i] }
$FlakCrops = @('220x280+35+320','240x280+265+320','250x280+515+320')
$FortCrops = @('230x280+745+320','250x280+990+320','260x280+1245+320')
for($i=0;$i -lt 3;$i++) { Export-RawCell "flak_breakup_$i" $FlakCrops[$i]; Export-RawCell "fort_breakup_$i" $FortCrops[$i] }

$PickupFamilies = @('bomb','repair','shield','weapon')
for($row=0;$row -lt 4;$row++) {
    for($frame=0;$frame -lt 4;$frame++) {
        & $Magick $PickupSource -crop "384x256+$($frame*384)+$($row*256)" +repage (Join-Path $RawPickupCells "$($PickupFamilies[$row])_$frame.png")
        if($LASTEXITCODE -ne 0) { throw "Failed to crop pickup source: $($PickupFamilies[$row])_$frame" }
    }
}

$PreviousPythonPath = $env:PYTHONPATH
try {
    $env:PYTHONPATH = $StudioSource
    & $Python -m sprite_studio.cli clean $RawCells --out $Clean --config $Config
    if($LASTEXITCODE -ne 0) { throw 'Sprite Studio cleanup failed for destruction and reward FX.' }
    & $Python -m sprite_studio.cli clean $RawPickupCells --out $CleanPickups --config $PickupConfig
    if($LASTEXITCODE -ne 0) { throw 'Sprite Studio cleanup failed for pickup FX.' }
}
finally { $env:PYTHONPATH = $PreviousPythonPath }

function Pack-Frame([string]$Name,[string]$Destination,[string]$Resize,[string]$Canvas,[int]$Colors) {
    $source = Join-Path $Clean "frames\$Name.png"
    $pickupSource = Join-Path $CleanPickups "frames\$Name.png"
    if(Test-Path -LiteralPath $pickupSource -PathType Leaf) { $source = $pickupSource }
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    & $Magick $source -trim +repage -filter Lanczos -resize $Resize -gravity center -background none -extent $Canvas -colors $Colors -depth 8 $Destination
    if($LASTEXITCODE -ne 0) { throw "Failed to pack runtime frame: $Destination" }
}

for($i=0;$i -lt 8;$i++) { Pack-Frame "explosion_$i" (Join-Path $RuntimeRoot "explosion\explosion_$i.png") '44x44' '48x48' 64 }
foreach($family in @('flak_breakup','fort_breakup')) { for($i=0;$i -lt 3;$i++) { Pack-Frame "${family}_$i" (Join-Path $RuntimeRoot "ground_breakup\${family}_$i.png") '38x38' '40x40' 56 } }
foreach($family in @('bomb','repair','shield','weapon')) { for($i=0;$i -lt 4;$i++) { Pack-Frame "${family}_$i" (Join-Path $RuntimeRoot "pickups\${family}_$i.png") '20x20' '24x24' 40 } }

Write-Host 'Built HYPERSONIC destruction and reward FX v2 through EVAVO Sprite Studio.'
