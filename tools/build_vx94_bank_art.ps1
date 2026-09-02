param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Runtime = Join-Path $RepoRoot 'assets\runtime\craft\vx94\gameplay'
$Output = Join-Path $Runtime 'bank'
$Work = Join-Path $RepoRoot 'work\vx94_bank_build_v3'
$Review = Join-Path $RepoRoot 'work\vx94_bank_family_v3_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
New-Item -ItemType Directory -Force -Path $Output, $Work | Out-Null

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

foreach ($Form in @('fighter','bomber')) {
    $Neutral = Join-Path $Output "$($Form)_neutral.png"
    & $MagickPath (Join-Path $Runtime "vx94_$($Form)_v1.png") -colors 48 -dither None -depth 8 $Neutral
    foreach ($Direction in @('left','right')) {
        Build-Pose -Form $Form -Direction $Direction -Strength 'soft'
        Build-Pose -Form $Form -Direction $Direction -Strength 'hard'
    }
}

$RuntimeFrames = Get-ChildItem -LiteralPath $Output -Filter '*.png' | Sort-Object Name
foreach ($Frame in $RuntimeFrames) {
    $Geometry = & $MagickPath identify -format '%wx%h' $Frame.FullName
    $Channels = & $MagickPath identify -format '%[channels]' $Frame.FullName
    if ($Geometry -ne '64x72') { throw "Bank frame lost registration: $($Frame.Name) [$Geometry]" }
    if ($Channels -notmatch 'a') { throw "Bank frame lost alpha: $($Frame.Name) [$Channels]" }
}
& $MagickPath montage ($RuntimeFrames.FullName) -filter point -thumbnail '192x216' -tile '5x2' -geometry '+14+24' -background '#101a22' -fill white -pointsize 11 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build VX-94 bank review.' }

Write-Host 'Built ten registered VX-94 bank poses from the two canonical planforms.'
Write-Host "Review: $Review"
