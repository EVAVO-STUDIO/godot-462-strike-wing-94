param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Runtime = Join-Path $RepoRoot 'assets\runtime\craft\vx94\gameplay'
$Output = Join-Path $Runtime 'bank'
$FighterMaster = Join-Path $RepoRoot 'assets\source\craft\vx94\vx94_bank_family_v4_alpha_master.png'
$BomberMaster = Join-Path $RepoRoot 'assets\source\craft\vx94\vx94_bomber_bank_family_v1_alpha_master.png'
$Work = Join-Path $RepoRoot 'work\vx94_bank_build_v4'
$Review = Join-Path $RepoRoot 'work\vx94_bank_family_v4_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
New-Item -ItemType Directory -Force -Path $Output, $Work | Out-Null

function Build-AuthoredPose {
    param(
        [ValidateSet('fighter','bomber')][string]$Form,
        [string]$Master,
        [string]$Name,
        [string]$Crop
    )
    if (-not (Test-Path -LiteralPath $Master)) { throw "Authored $Form bank master missing: $Master" }
    $Destination = Join-Path $Output "$($Form)_$Name.png"
    & $MagickPath $Master -crop $Crop +repage -filter box -resize '64x68>' -gravity south -background none -extent '64x72' -colors 48 -dither None -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build authored VX-94 $Form bank pose: $Name" }
}

# Five separately painted orthographic poses preserve fuselage volume, visible
# underside, canopy perspective and nozzle displacement. Runtime never rotates
# or asymmetrically scales the fighter bitmap.
Build-AuthoredPose -Form fighter -Master $FighterMaster -Name 'hard_left' -Crop '214x416+89+272'
Build-AuthoredPose -Form fighter -Master $FighterMaster -Name 'left' -Crop '201x400+403+256'
Build-AuthoredPose -Form fighter -Master $FighterMaster -Name 'neutral' -Crop '230x419+719+245'
Build-AuthoredPose -Form fighter -Master $FighterMaster -Name 'right' -Crop '200x400+1069+256'
Build-AuthoredPose -Form fighter -Master $FighterMaster -Name 'hard_right' -Crop '209x417+1371+270'

Build-AuthoredPose -Form bomber -Master $BomberMaster -Name 'hard_left' -Crop '270x406+55+283'
Build-AuthoredPose -Form bomber -Master $BomberMaster -Name 'left' -Crop '265x393+377+271'
Build-AuthoredPose -Form bomber -Master $BomberMaster -Name 'neutral' -Crop '311x406+681+262'
Build-AuthoredPose -Form bomber -Master $BomberMaster -Name 'right' -Crop '264x391+1031+277'
Build-AuthoredPose -Form bomber -Master $BomberMaster -Name 'hard_right' -Crop '271x399+1348+290'

# The neutral fighter is the registered start of the articulated sweep. Preserve
# the separately painted bank perspectives while keeping the handoff pixel exact.
Copy-Item -LiteralPath (Join-Path $RepoRoot 'assets/source/craft/vx94/transform_v2/fighter_neutral.png') -Destination (Join-Path $Output 'fighter_neutral.png')

$RuntimeFrames = Get-ChildItem -LiteralPath $Output -Filter '*.png' | Sort-Object Name
foreach ($Frame in $RuntimeFrames) {
    if ($Frame.Name -ne 'fighter_neutral.png') {
        foreach ($Region in @('64x1+0+0', '64x1+0+71', '1x72+0+0', '1x72+63+0')) {
            & $MagickPath $Frame.FullName -alpha set -channel A -region $Region -evaluate set 0 +channel -depth 8 $Frame.FullName
            if ($LASTEXITCODE -ne 0) { throw "Failed to clear bank-frame canvas edge: $($Frame.Name) [$Region]" }
        }
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

Write-Host 'Built five authored fighter and five authored bomber VX-94 bank poses.'
Write-Host "Review: $Review"
