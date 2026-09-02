param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\coast_chunks\coast_geography_source_v2.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\coast_chunks'
$Work = Join-Path $RepoRoot 'work\coast_geography_build'
$Review = Join-Path $RepoRoot 'work\coast_geography_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Coast geography source missing: $Source" }
New-Item -ItemType Directory -Force -Path $Output, $Work | Out-Null

$Names = @('seawall_run', 'defended_inlet', 'reef_cliffs')
for ($Index = 0; $Index -lt $Names.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    # The v2 master registers each panel at its final 640x1024 runtime size.
    # Never enlarge an undersized plate here: close low-altitude play must retain
    # the authored road, concrete, rock and wave detail without soft stretching.
    & $MagickPath $Source -crop "640x1024+$($Index * 640)+0" +repage -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register coast source section $Index" }
}

# Build a local connector for each adjacent pair. Each connector is the mean
# of the two natural edge rows, so the sequence closes exactly without stamping
# one dark 48px strip across every chunk. A short masked transition carries the
# local rock, road and water colour into that shared row.
$BlendHeight = 24
$BlendMask = Join-Path $Work 'vertical_blend_mask.png'
& $MagickPath -size "640x$BlendHeight" 'gradient:black-white' -depth 8 $BlendMask
if ($LASTEXITCODE -ne 0) { throw 'Failed to build coast edge blend mask.' }

for ($Index = 0; $Index -lt $Names.Count; $Index++) {
    $NextIndex = ($Index + 1) % $Names.Count
    $BottomDetail = Join-Path $Work "bottom_detail_$Index.png"
    $NextTopDetail = Join-Path $Work "top_detail_$NextIndex.png"
    $BottomRow = Join-Path $Work "bottom_$Index.png"
    $NextTopRow = Join-Path $Work "top_$NextIndex.png"
    $BoundaryRow = Join-Path $Work "boundary_row_$Index.png"
    $Boundary = Join-Path $Work "boundary_$Index.png"
    & $MagickPath (Join-Path $Work "raw_$Index.png") -crop "640x$BlendHeight+0+$([int](1024 - $BlendHeight))" +repage $BottomDetail
    & $MagickPath (Join-Path $Work "raw_$NextIndex.png") -crop "640x$BlendHeight+0+0" +repage $NextTopDetail
    & $MagickPath (Join-Path $Work "raw_$Index.png") -crop '640x1+0+1023' +repage $BottomRow
    & $MagickPath (Join-Path $Work "raw_$NextIndex.png") -crop '640x1+0+0' +repage $NextTopRow
    & $MagickPath $BottomRow $NextTopRow -evaluate-sequence mean -depth 8 $BoundaryRow
    & $MagickPath $BottomDetail $NextTopDetail -evaluate-sequence mean $BoundaryRow -gravity north -compose over -composite $BoundaryRow -gravity south -compose over -composite -depth 8 $Boundary
    if ($LASTEXITCODE -ne 0) { throw "Failed to derive coast boundary $Index." }
}

for ($Index = 0; $Index -lt $Names.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Destination = Join-Path $Output "$($Names[$Index]).png"
    $PreviousIndex = ($Index + $Names.Count - 1) % $Names.Count
    $TopNatural = Join-Path $Work "top_natural_$Index.png"
    $BottomNatural = Join-Path $Work "bottom_natural_$Index.png"
    $TopBoundaryPlate = Join-Path $Work "top_boundary_plate_$Index.png"
    $BottomBoundaryPlate = Join-Path $Work "bottom_boundary_plate_$Index.png"
    $TopTransition = Join-Path $Work "top_transition_$Index.png"
    $BottomTransition = Join-Path $Work "bottom_transition_$Index.png"
    & $MagickPath $Raw -crop "640x$BlendHeight+0+0" +repage $TopNatural
    & $MagickPath $Raw -crop "640x$BlendHeight+0+$([int](1024 - $BlendHeight))" +repage $BottomNatural
    & $MagickPath (Join-Path $Work "boundary_$PreviousIndex.png") $TopBoundaryPlate
    & $MagickPath (Join-Path $Work "boundary_$Index.png") $BottomBoundaryPlate
    & $MagickPath $TopBoundaryPlate $TopNatural $BlendMask -compose over -composite $TopTransition
    & $MagickPath $BottomNatural $BottomBoundaryPlate $BlendMask -compose over -composite $BottomTransition
    & $MagickPath $Raw $TopTransition -gravity north -compose over -composite $BottomTransition -gravity south -compose over -composite -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish coast chunk: $($Names[$Index])" }
}

$Runtime = foreach ($Name in $Names) { Join-Path $Output "$Name.png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build coast geography review.' }

Write-Host "Built $($Names.Count) registered coast geography chunks."
Write-Host "Review: $Review"
