param([string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\mountain_chunks\mountain_geography_source_v2.png'
$WeatherSource = Join-Path $RepoRoot 'assets\source\environments\mountain_chunks\mountain_weather_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\mountain_chunks'
$WeatherOutput = Join-Path $RepoRoot 'assets\runtime\environments\mountain_weather_animation'
$Work = Join-Path $RepoRoot 'work\mountain_geography_build'
$Review = Join-Path $RepoRoot 'work\mountain_geography_review.png'
$WeatherReview = Join-Path $RepoRoot 'work\mountain_weather_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
foreach ($Required in @($Source,$WeatherSource)) { if (-not (Test-Path -LiteralPath $Required)) { throw "Mountain source missing: $Required" } }
New-Item -ItemType Directory -Force -Path $Output,$WeatherOutput,$Work | Out-Null

$Sections = @(
    @{ Name='switchback_pass'; Crop='640x1024+0+0' },
    @{ Name='radar_service_valley'; Crop='640x1024+640+0' },
    @{ Name='ice_cliff_corridor'; Crop='640x1024+1280+0' }
)
# The v2 master is authored at final runtime width. Never enlarge terrain here:
# zoomed gameplay must receive real rock, road, ice and infrastructure detail.
for ($Index=0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register mountain section $Index" }
}
# Retained interiors and registered road terminations replace the pasted strip.
& node (Join-Path $RepoRoot 'tools/build_mountain_repair_v3.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Failed to build retained mountain terrain v3.' }

$EdgeMask = Join-Path $Work 'weather_edge_mask.png'
& $MagickPath -size '224x144' xc:white -fx 'min(1,min(min(i/12,(w-1-i)/12),min(j/10,(h-1-j)/10)))' -alpha copy $EdgeMask
for ($Index=0; $Index -lt 6; $Index++) {
    $Column = $Index % 3
    $Row = [Math]::Floor($Index / 3)
    $Temp = Join-Path $Work "weather_$Index.png"
    $SubjectMask = Join-Path $Work "weather_subject_$Index.png"
    $FinalMask = Join-Path $Work "weather_mask_$Index.png"
    $Destination = Join-Path $WeatherOutput "shear_$Index.png"
    & $MagickPath $WeatherSource -crop "512x512+$($Column * 512)+$($Row * 512)" +repage -resize '224x144!' -depth 8 $Temp
    & $MagickPath $Temp -alpha off -colorspace gray -level '48%,76%' $SubjectMask
    & $MagickPath $SubjectMask $EdgeMask -compose multiply -composite $FinalMask
    & $MagickPath $Temp $FinalMask -alpha off -compose CopyOpacity -composite -colorspace sRGB -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build mountain-weather frame $Index" }
}
$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
& $MagickPath montage (Get-ChildItem -LiteralPath $WeatherOutput -Filter 'shear_*.png' | Sort-Object Name | Select-Object -ExpandProperty FullName) -tile '3x2' -geometry '+4+4' -background '#101820' $WeatherReview
if ($LASTEXITCODE -ne 0) { throw 'Failed to build mountain review sheets.' }
Write-Host 'Built 3 mountain geography chunks and 6 registered weather frames.'
Write-Host "Review: $Review"
