param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Runtime = Join-Path $RepoRoot 'assets\runtime\craft\vx94\gameplay'
$Output = Join-Path $Runtime 'bank'
$FighterMaster = Join-Path $RepoRoot 'assets\source\craft\vx94\vx94_bank_family_v4_alpha_master.png'
$Work = Join-Path $RepoRoot 'work\vx94_bank_build_v4'
$Review = Join-Path $RepoRoot 'work\vx94_bank_family_v4_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
New-Item -ItemType Directory -Force -Path $Output, $Work | Out-Null

function Build-AuthoredFighterPose {
    param(
        [string]$Name,
        [string]$Crop
    )
    if (-not (Test-Path -LiteralPath $FighterMaster)) { throw "Authored fighter bank master missing: $FighterMaster" }
    $Destination = Join-Path $Output "fighter_$Name.png"
    & $MagickPath $FighterMaster -crop $Crop +repage -filter box -resize '64x68>' -gravity south -background none -extent '64x72' -colors 48 -dither None -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build authored VX-94 fighter bank pose: $Name" }
}

function Build-Pose {
    param(
        [string]$Form,
        [ValidateSet('left','right')][string]$Direction,
        [ValidateSet('soft','hard')][string]$Strength
    )
    $Source = Join-Path $Runtime "vx94_$($Form)_v1.png"
    if (-not (Test-Path -LiteralPath $Source)) { throw "Canonical VX-94 form missing: $Source" }
    $ExpandedWidth = if ($Strength -eq 'hard') { 34 } else { 31 }
    $ExpandedHeight = if ($Strength -eq 'hard') { 67 } else { 69 }
    $ExpandedY = if ($Strength -eq 'hard') { 1 } else { 2 }
    $CompressedWidth = if ($Strength -eq 'hard') { 19 } else { 25 }
    $CompressedHeight = if ($Strength -eq 'hard') { 55 } else { 63 }
    $CompressedY = if ($Strength -eq 'hard') { 9 } else { 5 }
    $ExpandedSide = if ($Direction -eq 'right') { 'left' } else { 'right' }
    $Tag = "$($Form)_$($Strength)_$Direction"
    $Left = Join-Path $Work "$($Tag)_left.png"
    $Right = Join-Path $Work "$($Tag)_right.png"
    $Body = Join-Path $Work "$($Tag)_body.png"
    $DestinationName = if ($Strength -eq 'hard') { "$($Form)_hard_$Direction.png" } else { "$($Form)_$Direction.png" }
    $Destination = Join-Path $Output $DestinationName

    $LeftWidth = if ($ExpandedSide -eq 'left') { $ExpandedWidth } else { $CompressedWidth }
    $LeftHeight = if ($ExpandedSide -eq 'left') { $ExpandedHeight } else { $CompressedHeight }
    $LeftY = if ($ExpandedSide -eq 'left') { $ExpandedY } else { $CompressedY }
    $LeftContrast = if ($ExpandedSide -eq 'left') { '7x5' } else { '-19x7' }
    $RightWidth = if ($ExpandedSide -eq 'right') { $ExpandedWidth } else { $CompressedWidth }
    $RightHeight = if ($ExpandedSide -eq 'right') { $ExpandedHeight } else { $CompressedHeight }
    $RightY = if ($ExpandedSide -eq 'right') { $ExpandedY } else { $CompressedY }
    $RightContrast = if ($ExpandedSide -eq 'right') { '7x5' } else { '-19x7' }
    # Roots overlap the immutable fuselage crop. Only the outboard structures
    # are foreshortened, displaced and relit; the nose/engine axis never rotates.
    $LeftX = if ($ExpandedSide -eq 'left') { 0 } else { 9 }
    $RightX = if ($ExpandedSide -eq 'right') { 64 - $RightWidth } else { 36 }
    & $MagickPath $Source -crop '29x72+0+0' +repage -filter point -resize "$($LeftWidth)x$($LeftHeight)!" -brightness-contrast $LeftContrast -colors 48 -dither None -depth 8 $Left
    & $MagickPath $Source -crop '29x72+35+0' +repage -filter point -resize "$($RightWidth)x$($RightHeight)!" -brightness-contrast $RightContrast -colors 48 -dither None -depth 8 $Right
    & $MagickPath $Source -crop '16x72+24+0' +repage -colors 48 -dither None -depth 8 $Body
    & $MagickPath -size '64x72' canvas:none $Left -geometry "+$LeftX+$LeftY" -compose over -composite $Right -geometry "+$RightX+$RightY" -compose over -composite $Body -geometry '+24+0' -compose over -composite -colors 48 -dither None -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build VX-94 bank pose: $DestinationName" }
}

foreach ($Form in @('bomber')) {
    $Neutral = Join-Path $Output "$($Form)_neutral.png"
    & $MagickPath (Join-Path $Runtime "vx94_$($Form)_v1.png") -colors 48 -dither None -depth 8 $Neutral
    foreach ($Direction in @('left','right')) {
        Build-Pose -Form $Form -Direction $Direction -Strength 'soft'
        Build-Pose -Form $Form -Direction $Direction -Strength 'hard'
    }
}

# Five separately painted orthographic poses preserve fuselage volume, visible
# underside, canopy perspective and nozzle displacement. Runtime never rotates
# or asymmetrically scales the fighter bitmap.
Build-AuthoredFighterPose -Name 'hard_left' -Crop '214x416+89+272'
Build-AuthoredFighterPose -Name 'left' -Crop '201x400+403+256'
Build-AuthoredFighterPose -Name 'neutral' -Crop '230x419+719+245'
Build-AuthoredFighterPose -Name 'right' -Crop '200x400+1069+256'
Build-AuthoredFighterPose -Name 'hard_right' -Crop '209x417+1371+270'

$RuntimeFrames = Get-ChildItem -LiteralPath $Output -Filter '*.png' | Sort-Object Name
foreach ($Frame in $RuntimeFrames) {
    foreach ($Region in @('64x1+0+0', '64x1+0+71', '1x72+0+0', '1x72+63+0')) {
        & $MagickPath $Frame.FullName -alpha set -channel A -region $Region -evaluate set 0 +channel -depth 8 $Frame.FullName
        if ($LASTEXITCODE -ne 0) { throw "Failed to clear bank-frame canvas edge: $($Frame.Name) [$Region]" }
    }
    $Geometry = & $MagickPath identify -format '%wx%h' $Frame.FullName
    $Channels = & $MagickPath identify -format '%[channels]' $Frame.FullName
    if ($Geometry -ne '64x72') { throw "Bank frame lost registration: $($Frame.Name) [$Geometry]" }
    if ($Channels -notmatch 'a') { throw "Bank frame lost alpha: $($Frame.Name) [$Channels]" }
    foreach ($Region in @('64x1+0+0', '64x1+0+71', '1x72+0+0', '1x72+63+0')) {
        $Maximum = & $MagickPath $Frame.FullName -alpha extract -crop $Region +repage -format '%[fx:maxima]' info:
        if ($LASTEXITCODE -ne 0 -or [double]$Maximum -ne 0.0) {
            throw "Bank frame has a nontransparent canvas edge: $($Frame.Name) [$Region=$Maximum]"
        }
    }
}
& $MagickPath montage ($RuntimeFrames.FullName) -filter point -thumbnail '192x216' -tile '5x2' -geometry '+14+24' -background '#101a22' -fill white -pointsize 11 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build VX-94 bank review.' }

Write-Host 'Built five authored fighter and five registered bomber VX-94 bank poses.'
Write-Host "Review: $Review"
