param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\harbor_chunks\harbor_geography_source_v1.png'
$ReflectionSource = Join-Path $RepoRoot 'assets\source\environments\harbor_chunks\harbor_reflection_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\harbor_chunks'
$ReflectionOutput = Join-Path $RepoRoot 'assets\runtime\environments\harbor_reflection_animation'
$Work = Join-Path $RepoRoot 'work\harbor_geography_build'
$Review = Join-Path $RepoRoot 'work\harbor_geography_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
foreach ($Required in @($Source,$ReflectionSource)) { if (-not (Test-Path -LiteralPath $Required)) { throw "Harbor source missing: $Required" } }
New-Item -ItemType Directory -Force -Path $Output,$ReflectionOutput,$Work | Out-Null

$Sections = @(
    @{ Name='outer_breakwater'; Crop='522x957+5+7' },
    @{ Name='repair_basin'; Crop='530x957+540+7' },
    @{ Name='command_docks'; Crop='530x957+1082+7' }
)
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register harbor section $Index" }
}

# Every district shares a 48px open-water boundary. The connector is copied to
# both ends and lightly blended inward, so all three orders and the cycle closure
# remain exact without mirroring the authored interior geography.
$Connector = Join-Path $Work 'shared_connector.png'
$ConnectorRow = Join-Path $Work 'connector_row.png'
& $MagickPath (Join-Path $Work 'raw_0.png') -crop '640x48+0+0' +repage $Connector
& $MagickPath $Connector -crop '640x1+0+0' +repage $ConnectorRow
& $MagickPath $Connector $ConnectorRow -gravity south -compose over -composite $Connector
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Destination = Join-Path $Output "$($Sections[$Index].Name).png"
    & $MagickPath $Raw $Connector -gravity north -compose over -composite $Connector -gravity south -compose over -composite `
        -region '640x22+0+38' -blur '0x2.2' +region -region '640x22+0+964' -blur '0x2.2' +region -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish harbor chunk: $($Sections[$Index].Name)" }
}

# The generated reflection source has an opaque preview field. Reconstruct alpha
# from the luminous painted marks, then apply a registered edge fade so each held
# frame can be placed anywhere inside an authored water channel without a card.
$EdgeMask = Join-Path $Work 'reflection_edge_mask.png'
& $MagickPath -size '128x224' xc:white -fx 'min(1,min(min(i/10,(w-1-i)/10),min(j/10,(h-1-j)/10)))' -alpha copy $EdgeMask
for ($Index=0; $Index -lt 6; $Index++) {
    $Column = $Index % 3
    $Row = [Math]::Floor($Index / 3)
    $Temp = Join-Path $Work "reflection_$Index.png"
    $SubjectMask = Join-Path $Work "reflection_subject_$Index.png"
    $FinalMask = Join-Path $Work "reflection_mask_$Index.png"
    $Destination = Join-Path $ReflectionOutput "reflection_$Index.png"
    & $MagickPath $ReflectionSource -crop "341x768+$($Column * 341)+$($Row * 768)" +repage -resize '128x224!' -depth 8 $Temp
    & $MagickPath $Temp -alpha off -colorspace gray -level '28%,66%' $SubjectMask
    & $MagickPath $SubjectMask $EdgeMask -compose multiply -composite $FinalMask
    & $MagickPath $Temp $FinalMask -alpha off -compose CopyOpacity -composite -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build harbor reflection frame $Index" }
}

$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build harbor geography review.' }
Write-Host 'Built 3 harbor geography chunks and 6 registered reflection frames.'
Write-Host "Review: $Review"
