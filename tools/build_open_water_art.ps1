param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$FiniteSource = Join-Path $RepoRoot 'assets\source\environments\open_water\open_water_finite_source_v1.png'
$LayerRoot = Join-Path $RepoRoot 'assets\runtime\environments\layers'
$AnimationOutput = Join-Path $RepoRoot 'assets\runtime\environments\open_water_animation'
$FiniteOutput = Join-Path $RepoRoot 'assets\runtime\environments\open_water_finite'
$Work = Join-Path $RepoRoot 'work\open_water_build'
$Review = Join-Path $RepoRoot 'work\open_water_runtime_review.png'

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }
if (-not (Test-Path -LiteralPath $FiniteSource)) { throw "Open-water finite source missing: $FiniteSource" }
New-Item -ItemType Directory -Force -Path $AnimationOutput, $FiniteOutput, $Work | Out-Null

function Build-SeamlessPhase([string]$SourcePath, [string]$Output, [int]$X, [int]$Y) {
    $Rolled = Join-Path $Work 'rolled.png'
    $Row = Join-Path $Work 'row.png'
    & $MagickPath $SourcePath -roll "+$X+$Y" -depth 8 $Rolled
    & $MagickPath $Rolled -crop '640x1+0+0' +repage $Row
    & $MagickPath $Rolled $Row -gravity south -compose src -composite -depth 8 $Output
    if ($LASTEXITCODE -ne 0) { throw "Failed to build seamless water phase: $Output" }
}

$Families = [ordered]@{
    'deep' = @{ Source = 'sea_deep_tile.png'; X = @(0,1,0,-1); Y = @(0,3,6,3) }
    'surface' = @{ Source = 'sea_surface_tile.png'; X = @(0,2,4,2); Y = @(0,5,10,5) }
    'foam' = @{ Source = 'sea_foam_tile.png'; X = @(0,2,4,6,4,2); Y = @(0,4,8,12,8,4) }
}
foreach ($Family in $Families.Keys) {
    $Spec = $Families[$Family]
    $LayerSource = Join-Path $LayerRoot $Spec.Source
    for ($Index = 0; $Index -lt $Spec.X.Count; $Index++) {
        Build-SeamlessPhase $LayerSource (Join-Path $AnimationOutput "$($Family)_$Index.png") $Spec.X[$Index] $Spec.Y[$Index]
    }
}

$Finite = [ordered]@{
    'nav_buoy_yellow' = @{ Crop = '180x270+20+70'; Size = '30x44' }
    'nav_buoy_red' = @{ Crop = '180x270+190+70'; Size = '30x44' }
    'sensor_buoy' = @{ Crop = '190x270+380+70'; Size = '34x46' }
    'container_debris' = @{ Crop = '410x280+570+70'; Size = '112x74' }
    'fuel_slick' = @{ Crop = '240x270+980+80'; Size = '112x76' }
    'convoy_wake_narrow' = @{ Crop = '205x850+20+350'; Size = '44x180' }
    'convoy_wake_wide' = @{ Crop = '270x850+225+350'; Size = '56x184' }
    'platform_wake' = @{ Crop = '420x430+500+420'; Size = '132x132' }
    'current_scar_a' = @{ Crop = '170x670+900+420'; Size = '38x172' }
    'current_scar_b' = @{ Crop = '145x650+1075+445'; Size = '34x164' }
    'weather_raft' = @{ Crop = '205x275+505+900'; Size = '72x82' }
    'mooring_field' = @{ Crop = '315x385+680+875'; Size = '102x112' }
}
foreach ($Name in $Finite.Keys) {
    $Spec = $Finite[$Name]
    $Destination = Join-Path $FiniteOutput "$Name.png"
    & $MagickPath $FiniteSource -crop $Spec.Crop +repage -trim +repage -resize $Spec.Size -gravity center -background none -extent $Spec.Size -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build finite open-water sprite: $Name" }
    $Channels = & $MagickPath identify -format '%[channels]' $Destination
    if ($Channels -notmatch 'a') { throw "Finite open-water sprite lost alpha: $Name [$Channels]" }
}

$ReviewAssets = @()
$ReviewAssets += Get-ChildItem -LiteralPath $AnimationOutput -Filter '*.png' | Sort-Object Name | Select-Object -ExpandProperty FullName
$ReviewAssets += Get-ChildItem -LiteralPath $FiniteOutput -Filter '*.png' | Sort-Object Name | Select-Object -ExpandProperty FullName
& $MagickPath montage $ReviewAssets -thumbnail '150x120' -tile '6x' -geometry '+7+18' -background '#101820' -fill white -pointsize 10 -set label '%t' $Review
if ($LASTEXITCODE -ne 0) { throw 'Failed to build open-water runtime review.' }

Write-Host "Built 14 temporal water frames and $($Finite.Count) finite open-water sprites."
Write-Host "Review: $Review"
