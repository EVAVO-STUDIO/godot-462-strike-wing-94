param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\cloud_top_chunks\cloud_top_geography_source_v2.png'
$TurbulenceSource = Join-Path $RepoRoot 'assets\source\environments\cloud_top_chunks\cloud_top_turbulence_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\cloud_top_chunks'
$TurbulenceOutput = Join-Path $RepoRoot 'assets\runtime\environments\cloud_top_turbulence_animation'
$Work = Join-Path $RepoRoot 'work\cloud_top_geography_build'
$Review = Join-Path $RepoRoot 'work\cloud_top_geography_review.png'
$TurbulenceReview = Join-Path $RepoRoot 'work\cloud_top_turbulence_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
foreach ($Required in @($Source,$TurbulenceSource)) { if (-not (Test-Path -LiteralPath $Required)) { throw "Cloud-top source missing: $Required" } }
New-Item -ItemType Directory -Force -Path $Output,$TurbulenceOutput,$Work | Out-Null

$Sections = @(
    @{ Name='anvil_wells'; Crop='640x1024+0+0' },
    @{ Name='silver_breaks'; Crop='640x1024+640+0' },
    @{ Name='frontal_boundary'; Crop='640x1024+1280+0' },
    @{ Name='jetstream_corridor'; Crop='640x1024+1920+0' },
    @{ Name='mammatus_shelf'; Crop='640x1024+2560+0' },
    @{ Name='cold_front_fracture'; Crop='640x1024+3200+0' }
)
# The v2 master is authored at final runtime width. Atmospheric geography may
# be cropped or downsampled during registration, but must never be enlarged.
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register cloud-top section $Index" }
}
# Each neighbour pair gets its own transition. A single stamped connector made
# a conspicuous bright bar repeat every 1024px. Both sides now converge on one
# pair-specific seam row while retaining their own cloud structure inward.
$BlendHeight = 24
$BottomY = 1024 - $BlendHeight
$BottomMask = Join-Path $Work 'bottom_blend_mask.png'
$TopMask = Join-Path $Work 'top_blend_mask.png'
& $MagickPath -size "640x$BlendHeight" gradient:black-white $BottomMask
& $MagickPath -size "640x$BlendHeight" gradient:white-black $TopMask
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Next = ($Index + 1) % $Sections.Count
    $BottomRow = Join-Path $Work "bottom_row_$Index.png"
    $TopRow = Join-Path $Work "top_row_$Next.png"
    $BoundaryRow = Join-Path $Work "boundary_row_$Index.png"
    $BoundaryFill = Join-Path $Work "boundary_fill_$Index.png"
    & $MagickPath (Join-Path $Work "raw_$Index.png") -crop '640x1+0+1023' +repage $BottomRow
    & $MagickPath (Join-Path $Work "raw_$Next.png") -crop '640x1+0+0' +repage $TopRow
    & $MagickPath $BottomRow $TopRow -evaluate-sequence mean -blur '0x10' $BoundaryRow
    & $MagickPath $BoundaryRow -scale "640x$BlendHeight!" $BoundaryFill
}
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Previous = ($Index - 1 + $Sections.Count) % $Sections.Count
    $TopRegion = Join-Path $Work "top_region_$Index.png"
    $BottomRegion = Join-Path $Work "bottom_region_$Index.png"
    $TopBlend = Join-Path $Work "top_blend_$Index.png"
    $BottomBlend = Join-Path $Work "bottom_blend_$Index.png"
    & $MagickPath $Raw -crop "640x$BlendHeight+0+0" +repage $TopRegion
    & $MagickPath $Raw -crop "640x$BlendHeight+0+$BottomY" +repage $BottomRegion
    & $MagickPath $TopRegion (Join-Path $Work "boundary_fill_$Previous.png") $TopMask -composite $TopBlend
    & $MagickPath $BottomRegion (Join-Path $Work "boundary_fill_$Index.png") $BottomMask -composite $BottomBlend
    & $MagickPath $Raw $TopBlend -gravity north -compose over -composite $BottomBlend -gravity south -compose over -composite `
        (Join-Path $Work "boundary_row_$Previous.png") -gravity north -compose over -composite `
        (Join-Path $Work "boundary_row_$Index.png") -gravity south -compose over -composite $Raw
    $Destination = Join-Path $Output "$($Sections[$Index].Name).png"
    & $MagickPath $Raw -colorspace sRGB -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish cloud-top chunk: $($Sections[$Index].Name)" }
}

$EdgeMask = Join-Path $Work 'turbulence_edge_mask.png'
& $MagickPath -size '256x128' xc:white -fx 'min(1,min(min(i/14,(w-1-i)/14),min(j/10,(h-1-j)/10)))' -alpha copy $EdgeMask
for ($Index=0; $Index -lt 6; $Index++) {
    $Column = $Index % 3
    $Row = [Math]::Floor($Index / 3)
    $Temp = Join-Path $Work "turbulence_$Index.png"
    $SubjectMask = Join-Path $Work "turbulence_subject_$Index.png"
    $FinalMask = Join-Path $Work "turbulence_mask_$Index.png"
    $Destination = Join-Path $TurbulenceOutput "shear_$Index.png"
    & $MagickPath $TurbulenceSource -crop "512x512+$($Column * 512)+$($Row * 512)" +repage -resize '256x128!' -depth 8 $Temp
    & $MagickPath $Temp -alpha off -colorspace gray -level '38%,72%' $SubjectMask
    & $MagickPath $SubjectMask $EdgeMask -compose multiply -composite $FinalMask
    & $MagickPath $Temp $FinalMask -alpha off -compose CopyOpacity -composite -colorspace sRGB -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build cloud-top turbulence frame $Index" }
}
$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x2' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
& $MagickPath montage (Get-ChildItem -LiteralPath $TurbulenceOutput -Filter 'shear_*.png' | Sort-Object Name | Select-Object -ExpandProperty FullName) -tile '3x2' -geometry '+4+4' -background '#101820' $TurbulenceReview
if ($LASTEXITCODE -ne 0) { throw 'Failed to build cloud-top review sheets.' }
Write-Host 'Built 6 cloud-top geography chunks and 6 registered turbulence frames.'
Write-Host "Review: $Review"
