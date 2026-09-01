param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\cloud_top_chunks\cloud_top_geography_source_v1.png'
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
    @{ Name='anvil_wells'; Crop='512x1024+0+0' },
    @{ Name='silver_breaks'; Crop='512x1024+512+0' },
    @{ Name='frontal_boundary'; Crop='512x1024+1024+0' }
)
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register cloud-top section $Index" }
}
$Connector = Join-Path $Work 'shared_connector.png'
$ConnectorRow = Join-Path $Work 'connector_row.png'
& $MagickPath (Join-Path $Work 'raw_1.png') -crop '640x56+0+0' +repage $Connector
& $MagickPath $Connector -crop '640x1+0+0' +repage $ConnectorRow
& $MagickPath $Connector $ConnectorRow -gravity south -compose over -composite $Connector
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    $Destination = Join-Path $Output "$($Sections[$Index].Name).png"
    & $MagickPath $Raw $Connector -gravity north -compose over -composite $Connector -gravity south -compose over -composite `
        -region '640x26+0+42' -blur '0x2.4' +region -region '640x26+0+956' -blur '0x2.4' +region -colorspace sRGB -depth 8 $Destination
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
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
& $MagickPath montage (Get-ChildItem -LiteralPath $TurbulenceOutput -Filter 'shear_*.png' | Sort-Object Name | Select-Object -ExpandProperty FullName) -tile '3x2' -geometry '+4+4' -background '#101820' $TurbulenceReview
if ($LASTEXITCODE -ne 0) { throw 'Failed to build cloud-top review sheets.' }
Write-Host 'Built 3 cloud-top geography chunks and 6 registered turbulence frames.'
Write-Host "Review: $Review"

