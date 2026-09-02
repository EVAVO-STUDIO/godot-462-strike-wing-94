param(
    [string]$Python = 'C:\Users\User\AppData\Local\Programs\Python\Python312\python.exe',
    [string]$SpriteStudioRoot = 'C:\GitRepos\evavo-sprite-studio',
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $Root 'assets\source\craft\vx94\evasive_roll'
$Source = Join-Path $SourceDir 'vx94_evasive_roll_source_v1.png'
$Config = Join-Path $SourceDir 'vx94_evasive_roll_cleanup.sprite.json'
$Review = Join-Path $Root 'work\vx94_evasive_roll_clean'
$Runtime = Join-Path $Root 'assets\runtime\craft\vx94\evasive_roll'
$StudioSource = Join-Path $SpriteStudioRoot 'src'

foreach ($Required in @($Python, $StudioSource, $Magick, $Source, $Config)) {
    if (-not (Test-Path -LiteralPath $Required)) { throw "Required evasive-roll production input missing: $Required" }
}
New-Item -ItemType Directory -Force -Path $Runtime | Out-Null

$PreviousPythonPath = $env:PYTHONPATH
try {
    $env:PYTHONPATH = $StudioSource
    & $Python -m sprite_studio.cli clean $Source --out $Review --config $Config
    if ($LASTEXITCODE -ne 0) { throw 'Sprite Studio failed to clean the VX-94 evasive-roll sheet.' }
}
finally { $env:PYTHONPATH = $PreviousPythonPath }

$Clean = Join-Path $Review 'frames\vx94_evasive_roll_source_v1.png'
if (-not (Test-Path -LiteralPath $Clean)) { throw 'Sprite Studio did not produce the cleaned evasive-roll source.' }
$PoseCrops = @(
    '230x300+45+20', '230x300+310+20', '230x300+545+20', '220x300+775+20', '220x300+1005+20',
    '200x305+65+300', '200x305+315+300', '200x305+555+300', '200x305+800+300', '200x305+1030+300',
    '230x255+45+610', '220x255+305+610', '220x255+545+610', '220x255+790+610', '220x255+1025+610',
    '240x250+45+865', '220x250+315+865', '220x250+545+865', '220x250+790+865', '220x250+1030+865'
)

for ($Index = 0; $Index -lt $PoseCrops.Count; $Index++) {
    $Geometry = $PoseCrops[$Index]
    $Destination = Join-Path $Runtime ('roll_{0:d2}.png' -f $Index)
    $Rotate = if ($Index -ge 10 -and $Index -le 18) { '180' } else { '0' }
    & $Magick $Clean -crop $Geometry +repage -background none -rotate $Rotate -trim +repage -resize '56x64>' -gravity center -extent '64x72' -colors 48 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish evasive-roll frame $Index." }
    $Channels = & $Magick $Destination -format '%[channels]' info:
    if ($Channels -notmatch 'a') { throw "Evasive-roll frame $Index lost transparency." }
}

# The provider sheet's final row drifted into yaw. Reconstruct the recovery
# half from the coherent first-half volume studies so the nose remains fixed
# and the opposite edge-on passage is a true mirrored roll pose.
$RecoveryPairs = @('13:11', '14:10', '15:9', '16:7', '17:5', '18:2', '19:0')
foreach ($Pair in $RecoveryPairs) {
    $Parts = $Pair.Split(':')
    $DestinationIndex = [int]$Parts[0]
    $SourceIndex = [int]$Parts[1]
    $SourceFrame = Join-Path $Runtime ('roll_{0:d2}.png' -f $SourceIndex)
    $DestinationFrame = Join-Path $Runtime ('roll_{0:d2}.png' -f $DestinationIndex)
    & $Magick $SourceFrame -flop $DestinationFrame
    if ($LASTEXITCODE -ne 0) { throw "Failed to reconstruct evasive-roll recovery frame $DestinationIndex." }
}

# The edge-on source studies retain a detached guide/matte fleck in the first
# few rows. Clear only those rows on the affected poses; the nose begins lower
# in these frames, so aircraft pixels are preserved.
foreach ($Index in @(5,6,7,8,9,15,16,17)) {
    $Frame = Join-Path $Runtime ('roll_{0:d2}.png' -f $Index)
    & $Magick $Frame -channel A -fill black -draw 'rectangle 0,0 63,7' +channel -depth 8 $Frame
    if ($LASTEXITCODE -ne 0) { throw "Failed to remove detached matte from evasive-roll frame $Index." }
}

# Direction is authored into runtime art rather than simulated by reversing
# the temporal order. Both rolls therefore start and recover on the same exact
# neutral exposures, with every intermediate pose mirrored around the fixed
# gameplay anchor and no runtime bitmap rotation.
for ($Index = 0; $Index -lt $PoseCrops.Count; $Index++) {
    $LeftFrame = Join-Path $Runtime ('roll_{0:d2}.png' -f $Index)
    $RightFrame = Join-Path $Runtime ('roll_right_{0:d2}.png' -f $Index)
    & $Magick $LeftFrame -flop -depth 8 $RightFrame
    if ($LASTEXITCODE -ne 0) { throw "Failed to author right evasive-roll frame $Index." }
}

# Bomber form keeps the same real volumetric studies but carries a deliberately
# broader projected wing area. Width contracts at the two edge-on passages and
# opens again over the darker underside, avoiding a flat constant-width squash.
$BomberWidths = @(44,43,41,38,34,28,22,18,22,29,43,46,47,46,43,29,18,22,34,44)
for ($Index = 0; $Index -lt $PoseCrops.Count; $Index++) {
    foreach ($DirectionTag in @('', '_right')) {
        $SourceFrame = Join-Path $Runtime ("roll$($DirectionTag)_{0:d2}.png" -f $Index)
        $DestinationFrame = Join-Path $Runtime ("bomber_roll$($DirectionTag)_{0:d2}.png" -f $Index)
        $Width = $BomberWidths[$Index]
        & $Magick $SourceFrame -trim +repage -filter point -resize "$($Width)x64>" -gravity center -background none -extent '64x72' -colors 48 -dither None -depth 8 $DestinationFrame
        if ($LASTEXITCODE -ne 0) { throw "Failed to author bomber evasive-roll frame $DirectionTag $Index." }
    }
}

Write-Host 'Built 80 registered HYPERSONIC VX-94 fighter/bomber left/right evasive-roll frames through EVAVO Sprite Studio.'
