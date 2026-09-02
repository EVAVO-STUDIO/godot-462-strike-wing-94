param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\city_chunks\city_geography_source_v2.png'
$ActivitySource = Join-Path $RepoRoot 'assets\source\environments\city_chunks\city_activity_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\city_chunks'
$ActivityOutput = Join-Path $RepoRoot 'assets\runtime\environments\city_activity_animation'
$Work = Join-Path $RepoRoot 'work\city_geography_build'
$Review = Join-Path $RepoRoot 'work\city_geography_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
foreach ($Required in @($Source,$ActivitySource)) { if (-not (Test-Path -LiteralPath $Required)) { throw "City source missing: $Required" } }
New-Item -ItemType Directory -Force -Path $Output,$ActivityOutput,$Work | Out-Null

$Sections = @(
    @{ Name='freight_belt'; Crop='640x1024+0+0' },
    @{ Name='flooded_underpass'; Crop='640x1024+640+0' },
    @{ Name='machine_foundations'; Crop='640x1024+1280+0' }
)
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    # City rail, road and machinery detail is authored at final runtime width.
    # Enlarging the former 496px panels softened markings and widened structures.
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register city section $Index" }
}
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
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish city chunk: $($Sections[$Index].Name)" }
}

$EdgeMask = Join-Path $Work 'activity_edge_mask.png'
& $MagickPath -size '144x208' xc:white -fx 'min(1,min(min(i/10,(w-1-i)/10),min(j/10,(h-1-j)/10)))' -alpha copy $EdgeMask
for ($Index=0; $Index -lt 6; $Index++) {
    $Column = $Index % 3
    $Row = [Math]::Floor($Index / 3)
    $Temp = Join-Path $Work "activity_$Index.png"
    $SubjectMask = Join-Path $Work "activity_subject_$Index.png"
    $FinalMask = Join-Path $Work "activity_mask_$Index.png"
    $Destination = Join-Path $ActivityOutput "activity_$Index.png"
    & $MagickPath $ActivitySource -crop "512x512+$($Column * 512)+$($Row * 512)" +repage -resize '144x208!' -depth 8 $Temp
    & $MagickPath $Temp -alpha off -colorspace gray -level '25%,64%' $SubjectMask
    & $MagickPath $SubjectMask $EdgeMask -compose multiply -composite $FinalMask
    & $MagickPath $Temp $FinalMask -alpha off -compose CopyOpacity -composite -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build city-activity frame $Index" }
}
$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build city geography review.' }
Write-Host 'Built 3 city geography chunks and 6 registered activity frames.'
Write-Host "Review: $Review"
