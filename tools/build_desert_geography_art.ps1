param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\desert_chunks\desert_geography_source_v1.png'
$DustSource = Join-Path $RepoRoot 'assets\source\environments\desert_chunks\desert_dust_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\desert_chunks'
$DustOutput = Join-Path $RepoRoot 'assets\runtime\environments\desert_dust_animation'
$Work = Join-Path $RepoRoot 'work\desert_geography_build'
$Review = Join-Path $RepoRoot 'work\desert_geography_review.png'
if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Desert geography source missing: $Source" }
if (-not (Test-Path -LiteralPath $DustSource)) { throw "Desert dust source missing: $DustSource" }
New-Item -ItemType Directory -Force -Path $Output, $DustOutput, $Work | Out-Null

$Sections = @(
    @{ Name = 'armour_approach'; Crop = '555x941+0+0' },
    @{ Name = 'wadi_crossing'; Crop = '553x941+560+0' },
    @{ Name = 'logistics_belt'; Crop = '554x941+1118+0' }
)
for ($Index = 0; $Index -lt $Sections.Count; $Index++) {
    $Raw = Join-Path $Work "raw_$Index.png"
    & $MagickPath $Source -crop $Sections[$Index].Crop +repage -resize '640x1024!' -colorspace sRGB -depth 8 $Raw
    if ($LASTEXITCODE -ne 0) { throw "Failed to register desert source section $Index" }
}

for ($Index = 0; $Index -lt 6; $Index++) {
    $Destination = Join-Path $DustOutput "gust_$Index.png"
    & $MagickPath $DustSource -crop "256x384+$($Index * 256)+0" +repage -channel A -blur '0x1.6' +channel -resize '160x96!' -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build desert dust frame $Index" }
    $Channels = & $MagickPath identify -format '%[channels]' $Destination
    if ($Channels -notmatch 'a') { throw "Desert dust frame lost alpha: $Index [$Channels]" }
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
    if ($LASTEXITCODE -ne 0) { throw "Failed to finish desert chunk: $($Sections[$Index].Name)" }
}

$Runtime = foreach ($Section in $Sections) { Join-Path $Output "$($Section.Name).png" }
& $MagickPath montage $Runtime -thumbnail '320x512' -tile '3x1' -geometry '+8+22' -background '#101820' -fill white -pointsize 12 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build desert geography review.' }
Write-Host "Built $($Sections.Count) registered desert geography chunks and 6 dust-gust frames."
Write-Host "Review: $Review"
