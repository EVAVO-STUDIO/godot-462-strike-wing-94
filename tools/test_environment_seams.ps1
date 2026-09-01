param(
    [string]$MagickPath = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Audit = Join-Path $RepoRoot 'work\environment_seam_audit'
New-Item -ItemType Directory -Force -Path $Audit | Out-Null

if (-not (Test-Path -LiteralPath $MagickPath)) { throw "ImageMagick not found: $MagickPath" }

function Export-Edge([string]$Image, [string]$Edge, [string]$Output) {
    $Size = & $MagickPath identify -format '%wx%h' $Image
    $Parts = $Size -split 'x'
    $Width = [int]$Parts[0]
    $Height = [int]$Parts[1]
    $Y = if ($Edge -eq 'top') { 0 } else { $Height - 1 }
    & $MagickPath $Image -crop "$($Width)x1+0+$Y" +repage -depth 8 $Output
    if ($LASTEXITCODE -ne 0) { throw "Failed to export $Edge edge: $Image" }
}

function Assert-Vertical-Seam([string]$First, [string]$Second, [string]$Label) {
    $Bottom = Join-Path $Audit "$($Label)_bottom.png"
    $Top = Join-Path $Audit "$($Label)_top.png"
    Export-Edge $First 'bottom' $Bottom
    Export-Edge $Second 'top' $Top
    $MetricText = (& $MagickPath compare -metric AE $Bottom $Top null: 2>&1 | Out-String).Trim()
    $Metric = [double](($MetricText -split '\s+')[0])
    if ($LASTEXITCODE -ne 0 -or $Metric -ne 0) {
        throw "Environment seam failed [$Label]: absolute pixel error $MetricText"
    }
    Write-Host "PASS $Label (AE=0)"
}

$Layers = @(
    'sea_deep_tile.png', 'sea_surface_tile.png', 'sea_foam_tile.png', 'coast_surface_tile.png',
    'cloud_shadow_tile.png', 'cloud_mist_tile.png', 'refinery_detail_tile.png', 'desert_dust_tile.png',
    'river_current_tile.png', 'mountain_weather_tile.png', 'harbor_reflection_tile.png',
    'city_light_tile.png', 'furnace_activity_tile.png', 'orbital_debris_tile.png'
)
foreach ($Layer in $Layers) {
    $Path = Join-Path $RepoRoot "assets\runtime\environments\layers\$Layer"
    Assert-Vertical-Seam $Path $Path ([IO.Path]::GetFileNameWithoutExtension($Layer))
}

$AnimatedWater = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'assets\runtime\environments\open_water_animation') -Filter '*.png' | Sort-Object Name
foreach ($Frame in $AnimatedWater) {
    Assert-Vertical-Seam $Frame.FullName $Frame.FullName "water_$($Frame.BaseName)"
}

$Chunks = @('seawall_run.png', 'defended_inlet.png', 'reef_cliffs.png')
for ($Index = 0; $Index -lt $Chunks.Count; $Index++) {
    $First = Join-Path $RepoRoot "assets\runtime\environments\coast_chunks\$($Chunks[$Index])"
    $Second = Join-Path $RepoRoot "assets\runtime\environments\coast_chunks\$($Chunks[($Index + 1) % $Chunks.Count])"
    Assert-Vertical-Seam $First $Second "coast_$Index"
}

$RefineryChunks = @('tank_farm.png', 'cracking_corridor.png', 'rail_loading.png')
for ($Index = 0; $Index -lt $RefineryChunks.Count; $Index++) {
    $First = Join-Path $RepoRoot "assets\runtime\environments\refinery_chunks\$($RefineryChunks[$Index])"
    $Second = Join-Path $RepoRoot "assets\runtime\environments\refinery_chunks\$($RefineryChunks[($Index + 1) % $RefineryChunks.Count])"
    Assert-Vertical-Seam $First $Second "refinery_$Index"
}

$DesertChunks = @('armour_approach.png', 'wadi_crossing.png', 'logistics_belt.png')
for ($Index = 0; $Index -lt $DesertChunks.Count; $Index++) {
    $First = Join-Path $RepoRoot "assets\runtime\environments\desert_chunks\$($DesertChunks[$Index])"
    $Second = Join-Path $RepoRoot "assets\runtime\environments\desert_chunks\$($DesertChunks[($Index + 1) % $DesertChunks.Count])"
    Assert-Vertical-Seam $First $Second "desert_$Index"
}

$RiverChunks = @('floodplain.png', 'defended_crossing.png', 'industrial_bend.png')
for ($Index = 0; $Index -lt $RiverChunks.Count; $Index++) {
    $First = Join-Path $RepoRoot "assets\runtime\environments\river_chunks\$($RiverChunks[$Index])"
    $Second = Join-Path $RepoRoot "assets\runtime\environments\river_chunks\$($RiverChunks[($Index + 1) % $RiverChunks.Count])"
    Assert-Vertical-Seam $First $Second "river_$Index"
}

$HarborChunks = @('outer_breakwater.png', 'repair_basin.png', 'command_docks.png')
for ($Index = 0; $Index -lt $HarborChunks.Count; $Index++) {
    $First = Join-Path $RepoRoot "assets\runtime\environments\harbor_chunks\$($HarborChunks[$Index])"
    $Second = Join-Path $RepoRoot "assets\runtime\environments\harbor_chunks\$($HarborChunks[($Index + 1) % $HarborChunks.Count])"
    Assert-Vertical-Seam $First $Second "harbor_$Index"
}

$CityChunks = @('freight_belt.png', 'flooded_underpass.png', 'machine_foundations.png')
for ($Index = 0; $Index -lt $CityChunks.Count; $Index++) {
    $First = Join-Path $RepoRoot "assets\runtime\environments\city_chunks\$($CityChunks[$Index])"
    $Second = Join-Path $RepoRoot "assets\runtime\environments\city_chunks\$($CityChunks[($Index + 1) % $CityChunks.Count])"
    Assert-Vertical-Seam $First $Second "city_$Index"
}

Write-Host "Environment seam gate passed: $($Layers.Count) loops, $($AnimatedWater.Count) temporal-water frames, $($Chunks.Count) coast joins, $($RefineryChunks.Count) refinery joins, $($DesertChunks.Count) desert joins, $($RiverChunks.Count) river joins, $($HarborChunks.Count) harbor joins and $($CityChunks.Count) city joins."
