param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\coast_chunks\coast_geography_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\coast_chunks'
$Work = Join-Path $RepoRoot 'work\coast_geography_build'
$Review = Join-Path $RepoRoot 'work\coast_geography_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Coast geography source missing: $Source" }
New-Item -ItemType Directory -Force -Path $Output, $Work | Out-Null

$Names = @('seawall_run', 'defended_inlet', 'reef_cliffs')
for ($Index = 0; $Index -lt $Names.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop "512x1024+$($Index * 512)+0" +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register coast source section $Index" }
}

# Every section enters and exits through the same narrow coast corridor. The
# corridor retains natural detail, but its final scanline is explicitly copied
# from its first so the runtime sequence has a measurable zero-error join.
$Connector = Join-Path $Work 'shared_connector.png'
$ConnectorRow = Join-Path $Work 'connector_row.png'
& $MagickPath (Join-Path $Work 'raw_0.png') -crop '640x48+0+0' +repage $Connector
& $MagickPath $Connector -crop '640x1+0+0' +repage $ConnectorRow
& $MagickPath $Connector $ConnectorRow -gravity south -compose over -composite $Connector

for ($Index = 0; $Index -lt $Names.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Destination = Join-Path $Output "$($Names[$Index]).png"
    & $MagickPath $Raw $Connector -gravity north -compose over -composite $Connector -gravity south -compose over -composite `
        -region '640x22+0+38' -blur '0x2.2' +region -region '640x22+0+964' -blur '0x2.2' +region -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish coast chunk: $($Names[$Index])" }
}

$Runtime = foreach ($Name in $Names) { Join-Path $Output "$Name.png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build coast geography review.' }

Write-Host "Built $($Names.Count) registered coast geography chunks."
Write-Host "Review: $Review"
