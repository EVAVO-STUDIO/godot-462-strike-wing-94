param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\orbital_chunks\orbital_geography_source_v1.png'
$DebrisSource = Join-Path $RepoRoot 'assets\source\environments\orbital_chunks\orbital_debris_source_v1.png'
$EarthSource = Join-Path $RepoRoot 'assets\source\environments\orbital_chunks\earth_limb_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\orbital_chunks'
$DebrisOutput = Join-Path $RepoRoot 'assets\runtime\environments\orbital_debris_animation'
$EarthOutput = Join-Path $RepoRoot 'assets\runtime\environments\orbital\earth_limb_v2.png'
$Work = Join-Path $RepoRoot 'work\orbital_geography_build'
$Review = Join-Path $RepoRoot 'work\orbital_geography_review.png'
$DebrisReview = Join-Path $RepoRoot 'work\orbital_debris_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
foreach ($Required in @($Source,$DebrisSource,$EarthSource)) { if (-not (Test-Path -LiteralPath $Required)) { throw "Orbital source missing: $Required" } }
New-Item -ItemType Directory -Force -Path $Output,$DebrisOutput,$Work | Out-Null

$Sections = @(
    @{ Name='dead_lattice'; Crop='512x1024+0+0' },
    @{ Name='kinetic_rail_platform'; Crop='512x1024+512+0' },
    @{ Name='ark_industrial_approach'; Crop='512x1024+1024+0' }
)
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Mask = Join-Path $Work "mask_$Index.png"
    $Registered = Join-Path $Work "registered_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    & $MagickPath $Raw -alpha off -colorspace gray -level '2%,17%' $Mask
    & $MagickPath $Raw $Mask -alpha off -compose CopyOpacity -composite -colorspace sRGB -depth 8 $Registered
    if ($LASTEXITCODE -ne 0) { throw "Failed to register orbital section $Index" }
}
$Connector = Join-Path $Work 'shared_connector.png'
$ConnectorRow = Join-Path $Work 'connector_row.png'
& $MagickPath (Join-Path $Work 'registered_1.png') -crop '640x56+0+0' +repage $Connector
& $MagickPath $Connector -crop '640x1+0+0' +repage $ConnectorRow
& $MagickPath $Connector $ConnectorRow -gravity south -compose Copy -composite $Connector
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Registered = Join-Path $Work "registered_$Index.png"
    $Destination = Join-Path $Output "$($Sections[$Index].Name).png"
    & $MagickPath $Registered $Connector -gravity north -compose Copy -composite $Connector -gravity south -compose Copy -composite `
        -region '640x26+0+42' -blur '0x1.8' +region -region '640x26+0+956' -blur '0x1.8' +region -colorspace sRGB -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish orbital chunk: $($Sections[$Index].Name)" }
}
$CanonicalRow = Join-Path $Work 'canonical_seam_row.png'
& $MagickPath (Join-Path $Output "$($Sections[0].Name).png") -crop '640x1+0+0' +repage $CanonicalRow
foreach ($Section in $Sections) {
    $Destination = Join-Path $Output "$($Section.Name).png"
    & $MagickPath $Destination $CanonicalRow -gravity north -compose Copy -composite $CanonicalRow -gravity south -compose Copy -composite -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to close orbital seam: $($Section.Name)" }
}

$EdgeMask = Join-Path $Work 'debris_edge_mask.png'
& $MagickPath -size '144x144' xc:white -fx 'min(1,min(min(i/10,(w-1-i)/10),min(j/10,(h-1-j)/10)))' -alpha copy $EdgeMask
for ($Index=0; $Index -lt 6; $Index++) {
    $Column = $Index % 3
    $Row = [Math]::Floor($Index / 3)
    $Temp = Join-Path $Work "debris_$Index.png"
    $SubjectMask = Join-Path $Work "debris_subject_$Index.png"
    $FinalMask = Join-Path $Work "debris_mask_$Index.png"
    $Destination = Join-Path $DebrisOutput "debris_$Index.png"
    & $MagickPath $DebrisSource -crop "512x512+$($Column * 512)+$($Row * 512)" +repage -resize '144x144!' -depth 8 $Temp
    & $MagickPath $Temp -alpha off -colorspace gray -level '30%,66%' $SubjectMask
    & $MagickPath $SubjectMask $EdgeMask -compose multiply -composite $FinalMask
    & $MagickPath $Temp $FinalMask -alpha off -compose CopyOpacity -composite -colorspace sRGB -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build orbital debris frame $Index" }
}

$EarthTemp = Join-Path $Work 'earth_limb_temp.png'
$EarthMask = Join-Path $Work 'earth_limb_mask.png'
& $MagickPath $EarthSource -resize '640x427!' -crop '640x324+0+0' +repage -colorspace sRGB -depth 8 $EarthTemp
& $MagickPath $EarthTemp -alpha off -colorspace gray -level '0%,18%' $EarthMask
& $MagickPath $EarthTemp $EarthMask -alpha off -compose CopyOpacity -composite -colorspace sRGB -depth 8 $EarthOutput
if ($LASTEXITCODE -ne 0) { throw 'Failed to finish the near-Earth limb.' }
$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
& $MagickPath montage (Get-ChildItem -LiteralPath $DebrisOutput -Filter 'debris_*.png' | Sort-Object Name | Select-Object -ExpandProperty FullName) -tile '3x2' -geometry '+4+4' -background '#101820' $DebrisReview
if ($LASTEXITCODE -ne 0) { throw 'Failed to build orbital review sheets.' }
Write-Host 'Built 3 orbital infrastructure chunks, 6 debris frames and the near-Earth limb.'
Write-Host "Review: $Review"
