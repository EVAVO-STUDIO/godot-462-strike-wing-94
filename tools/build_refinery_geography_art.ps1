param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\refinery_chunks\refinery_geography_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\refinery_chunks'
$Work = Join-Path $RepoRoot 'work\refinery_geography_build'
$Review = Join-Path $RepoRoot 'work\refinery_geography_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Refinery geography source missing: $Source" }
New-Item -ItemType Directory -Force -Path $Output, $Work | Out-Null

$Sections = @(
    @{ Name = 'tank_farm'; Crop = '535x941+0+0' },
    @{ Name = 'cracking_corridor'; Crop = '566x941+549+0' },
    @{ Name = 'rail_loading'; Crop = '545x941+1127+0' }
)
for ($Index = 0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register refinery source section $Index" }
}

$Connector = Join-Path $Work 'shared_connector.png'
$ConnectorRow = Join-Path $Work 'connector_row.png'
& $MagickPath (Join-Path $Work 'raw_0.png') -crop '640x48+0+0' +repage $Connector
& $MagickPath $Connector -crop '640x1+0+0' +repage $ConnectorRow
& $MagickPath $Connector $ConnectorRow -gravity south -compose over -composite $Connector

for ($Index = 0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Destination = Join-Path $Output "$($Sections[$Index].Name).png"
    & $MagickPath $Raw $Connector -gravity north -compose over -composite $Connector -gravity south -compose over -composite `
        -region '640x22+0+38' -blur '0x2.2' +region -region '640x22+0+964' -blur '0x2.2' +region -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish refinery chunk: $($Sections[$Index].Name)" }
}

$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build refinery geography review.' }

Write-Host "Built $($Sections.Count) registered refinery geography chunks."
Write-Host "Review: $Review"
