param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $Root 'assets\source\cinematics\plates_v2\machine_war'
$RuntimeRoot = Join-Path $Root 'assets\runtime\cinematics\plates'
$SubjectRuntimeRoot = Join-Path $Root 'assets\runtime\cinematics\subjects\machine_war'
$FxRuntimeRoot = Join-Path $Root 'assets\runtime\cinematics\fx\machine_war'
if(-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }

$Plates = @(
    @{Id='s2_dead_refinery'; Source='s2_dead_refinery_raw_v2.png'; Crop='1536x768+0+128'; Gamma='0.96'},
    @{Id='s2_factory_awakens'; Source='s2_factory_awakens_raw_v2.png'; Crop='1536x768+0+96'; Gamma='0.92'},
    @{Id='s2_city_warning'; Source='s2_city_warning_raw_v2.png'; Crop='1536x768+0+96'; Gamma='0.94'}
)

foreach($Plate in $Plates) {
    $source = Join-Path $SourceRoot $Plate.Source
    $destination = Join-Path $RuntimeRoot "$($Plate.Id).png"
    if(-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Cinematic source not found: $source" }
    # Preserve the industrial compositions while grouping surface detail into
    # stable held-cel values that remain clean during camera moves.
    & $Magick $source -crop $Plate.Crop +repage -filter Lanczos -resize '640x320!' -gamma $Plate.Gamma -modulate '100,92,100' +dither -colors 36 -unsharp '0x0.55+0.55+0.02' -type Palette -depth 8 -define png:color-type=3 $destination
    if($LASTEXITCODE -ne 0) { throw "Failed to build cinematic plate: $($Plate.Id)" }
}

$SubjectSource = Join-Path $SourceRoot 'machine_war_subject_cels_raw_v2.png'
New-Item -ItemType Directory -Force -Path $SubjectRuntimeRoot | Out-Null
for($frame=0;$frame -lt 4;$frame++) {
    & $Magick $SubjectSource -crop "384x512+$($frame*384)+0" +repage -trim +repage -filter Lanczos -resize '130x150' -gravity south -background none -extent '160x160' -colors 64 -depth 8 (Join-Path $SubjectRuntimeRoot "salvage_mech_$frame.png")
    if($LASTEXITCODE -ne 0) { throw "Failed to build salvage-mech cinematic cel: $frame" }
    & $Magick $SubjectSource -crop "384x512+$($frame*384)+512" +repage -trim +repage -filter Lanczos -resize '130x80' -gravity center -background none -extent '144x96' -colors 64 -depth 8 (Join-Path $SubjectRuntimeRoot "drone_hunter_$frame.png")
    if($LASTEXITCODE -ne 0) { throw "Failed to build hunter cinematic cel: $frame" }
}

$FxSource = Join-Path $Root 'assets\source\cinematics\machine_war_fx_cels.svg'
$FxSheet = Join-Path $Root 'work\machine_war_fx_cels_v2.png'
& $Magick -background none $FxSource $FxSheet
if($LASTEXITCODE -ne 0) { throw 'Failed to rasterize machine-war limited FX sheet.' }
$FxFamilies = @('s2_observation','s2_anticipation','s2_consequence')
for($row=0;$row -lt 3;$row++) {
    if($row -eq 2) { continue } # Reviewed window-registered city acquisition cels.
    for($frame=0;$frame -lt 4;$frame++) {
        & $Magick $FxSheet -crop "640x272+$($frame*640)+$($row*272)" +repage -depth 8 (Join-Path $FxRuntimeRoot "$($FxFamilies[$row])_$frame.png")
        if($LASTEXITCODE -ne 0) { throw "Failed to build machine-war FX cel: $($FxFamilies[$row])/$frame" }
    }
}

& node (Join-Path $Root 'tools\build_city_warning_v3.mjs')
if($LASTEXITCODE -ne 0) { throw 'Failed to rebuild reviewed city-warning FX.' }

Write-Host 'Built HYPERSONIC Sector II machine-war plates, subjects, and limited FX cels v2.'
