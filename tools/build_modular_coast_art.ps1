param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'assets\source\environments\modular_coast\coast_construction_kit_source_v1.png'
$Output = Join-Path $RepoRoot 'assets\runtime\environments\modular_coast'
$Review = Join-Path $RepoRoot 'work\modular_coast_runtime_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Modular coast source missing: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

$Chunks = [ordered]@{
    'seawall_straight'       = '224x130+24+42'
    'seawall_access'         = '190x130+252+42'
    'seawall_endcap'         = '72x164+806+16'
    'seawall_inner_corner'   = '210x156+948+22'
    'seawall_outer_corner'   = '240x164+1160+18'
    'breakwater_straight'    = '190x132+26+206'
    'breakwater_corner'      = '190x140+797+205'
    'tetrapod_cluster'       = '170x116+1003+210'
    'rock_cluster_large'     = '190x120+928+368'
    'rock_cluster_small'     = '110x82+1325+376'
    'military_pier'          = '708x126+26+370'
    'road_straight'          = '220x92+25+530'
    'road_bend'              = '226x130+265+525'
    'road_tee'               = '132x120+505+522'
    'road_cross'             = '174x132+652+518'
    'radar_bunker'           = '218x176+38+650'
    'weapon_revetment'       = '246x174+286+665'
    'utility_bunker'         = '150x134+548+680'
    'generator_shed'         = '92x114+718+690'
    'pipe_corner'            = '124x98+940+526'
    'pipe_tee'               = '120x92+930+590'
    'cable_trench'           = '112x52+1215+550'
    'hazard_lamps'           = '300x54+34+850'
    'debris_cluster'         = '150x94+840+700'
}

foreach ($Name in $Chunks.Keys) {
    $Destination = Join-Path $Output "$Name.png"
    & $MagickPath $Source -crop $Chunks[$Name] +repage -trim +repage -bordercolor none -border 4 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build modular coast chunk: $Name" }
}

$ShoreFrames = @(
    '286x90+20+914',
    '286x90+307+914',
    '248x90+596+914'
)
for ($Index = 0; $Index -lt $ShoreFrames.Count; $Index++) {
    $Destination = Join-Path $Output "shore_wash_$Index.png"
    & $MagickPath $Source -crop $ShoreFrames[$Index] +repage -trim +repage -resize '280x72>' -gravity center -background none -extent '288x80' -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build shore wash frame: $Index" }
}

$ImpactFrames = @(
    '126x126+850+886',
    '126x126+994+886',
    '126x126+1135+886',
    '126x126+1270+886'
)
for ($Index = 0; $Index -lt $ImpactFrames.Count; $Index++) {
    $Destination = Join-Path $Output "breakwater_impact_$Index.png"
    & $MagickPath $Source -crop $ImpactFrames[$Index] +repage -trim +repage -resize '112x112>' -gravity center -background none -extent '120x120' -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build breakwater impact frame: $Index" }
}

$RuntimeAssets = Get-ChildItem -LiteralPath $Output -Filter '*.png' | Sort-Object Name
foreach ($Asset in $RuntimeAssets) {
    $Channels = & $MagickPath identify -format '%[channels]' $Asset.FullName
    if ($Channels -notmatch 'a') { throw "Runtime coast asset lost alpha: $($Asset.Name) [$Channels]" }
}

& $MagickPath montage ($RuntimeAssets.FullName) -thumbnail '160x112' -tile '6x' -geometry '+8+18' -background '#17232c' -fill white -pointsize 11 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build modular coast contact sheet.' }

Write-Host "Built $($RuntimeAssets.Count) modular coast runtime assets."
Write-Host "Review: $Review"
