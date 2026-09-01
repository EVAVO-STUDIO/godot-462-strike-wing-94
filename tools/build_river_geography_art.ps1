param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\river_chunks\river_geography_source_v1.png'
$CurrentSource = Join-Path $RepoRoot 'assets\source\environments\river_chunks\river_current_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\river_chunks'
$CurrentOutput = Join-Path $RepoRoot 'assets\runtime\environments\river_current_animation'
$Work = Join-Path $RepoRoot 'work\river_geography_build'
$Review = Join-Path $RepoRoot 'work\river_geography_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
foreach ($Required in @($Source,$CurrentSource)) { if (-not (Test-Path -LiteralPath $Required)) { throw "River source missing: $Required" } }
New-Item -ItemType Directory -Force -Path $Output,$CurrentOutput,$Work | Out-Null

$Sections = @(
    @{ Name='floodplain'; Crop='555x941+0+0' },
    @{ Name='defended_crossing'; Crop='553x941+560+0' },
    @{ Name='industrial_bend'; Crop='554x941+1118+0' }
)
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register river section $Index" }
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
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish river chunk: $($Sections[$Index].Name)" }
}
$CurrentMask = Join-Path $Work 'current_edge_mask.png'
& $MagickPath -size '112x220' xc:white -fx 'min(1,min(i/10,(w-1-i)/10))' -alpha copy $CurrentMask
for ($Index=0; $Index -lt 6; $Index++) {
    $Destination = Join-Path $CurrentOutput "current_$Index.png"
    $CurrentTemp = Join-Path $Work "current_$Index.png"
    $SubjectMask = Join-Path $Work "current_subject_mask_$Index.png"
    $FinalMask = Join-Path $Work "current_final_mask_$Index.png"
    & $MagickPath $CurrentSource -crop "256x560+$($Index * 256)+0" +repage -channel A -blur '0x1.2' +channel -resize '112x220!' -depth 8 $CurrentTemp
    & $MagickPath $CurrentTemp -alpha off -colorspace gray -level '36%,70%' $SubjectMask
    & $MagickPath $SubjectMask $CurrentMask -compose multiply -composite $FinalMask
    & $MagickPath $CurrentTemp $FinalMask -alpha off -compose CopyOpacity -composite -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build river-current frame $Index" }
    $Channels = & $MagickPath identify -format '%[channels]' $Destination
    if ($Channels -notmatch 'a') { throw "River-current frame lost alpha: $Index [$Channels]" }
}
$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build river geography review.' }
Write-Host "Built 3 river geography chunks and 6 registered current frames."
Write-Host "Review: $Review"
