param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $Root 'assets\source\cinematics\plates_v2\black_sky'
$PlateRuntime = Join-Path $Root 'assets\runtime\cinematics\plates'
$SubjectRuntime = Join-Path $Root 'assets\runtime\cinematics\subjects\black_sky'
if(-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
New-Item -ItemType Directory -Force -Path $SubjectRuntime | Out-Null

$Plates = @(
    @{Id='s3_weather_ceiling'; Source='s3_weather_ceiling_raw_v2.png'; Crop='1536x768+0+112'; Gamma='0.96'},
    @{Id='s3_phase_protocol'; Source='s3_phase_protocol_raw_v2.png'; Crop='1536x768+0+112'; Gamma='0.93'},
    @{Id='s3_ark_reveal'; Source='s3_ark_reveal_raw_v2.png'; Crop='1536x768+0+112'; Gamma='0.92'},
    @{Id='s3_authorized'; Source='s3_authorized_raw_v2.png'; Crop='1536x768+0+112'; Gamma='0.94'}
)
foreach($Plate in $Plates) {
    $source = Join-Path $SourceRoot $Plate.Source
    $destination = Join-Path $PlateRuntime "$($Plate.Id).png"
    if(-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "BLACK SKY plate source not found: $source" }
    & $Magick $source -crop $Plate.Crop +repage -filter Lanczos -resize '640x320!' -gamma $Plate.Gamma -modulate '100,92,100' -colors 64 -dither FloydSteinberg -depth 8 $destination
    if($LASTEXITCODE -ne 0) { throw "Failed to build BLACK SKY plate: $($Plate.Id)" }
}

$Vx94Source = Join-Path $Root 'assets\source\craft\vx94\candidates\vx94_fighter_identity_candidate_01.png'
& $Magick $Vx94Source -trim +repage -filter Lanczos -resize '120x150' -gravity center -background none -extent '144x160' -colors 64 -depth 8 (Join-Path $SubjectRuntime 'vx94_fighter_0.png')
if($LASTEXITCODE -ne 0) { throw 'Failed to build BLACK SKY VX-94 cinematic subject.' }

$SubjectSource = Join-Path $SourceRoot 'black_sky_subject_cels_raw_v2.png'
for($frame=0;$frame -lt 4;$frame++) {
    & $Magick $SubjectSource -crop "384x341+$($frame*384)+341" +repage -trim +repage -filter Lanczos -resize '132x132' -gravity center -background none -extent '144x144' -colors 64 -depth 8 (Join-Path $SubjectRuntime "phase_array_$frame.png")
    if($LASTEXITCODE -ne 0) { throw "Failed to build phase-array cinematic cel: $frame" }
    & $Magick $SubjectSource -crop "384x342+$($frame*384)+682" +repage -trim +repage -filter Lanczos -resize '164x148' -gravity center -background none -extent '176x160' -colors 64 -depth 8 (Join-Path $SubjectRuntime "machine_ark_$frame.png")
    if($LASTEXITCODE -ne 0) { throw "Failed to build Machine Ark cinematic cel: $frame" }
}

$FxSource = Join-Path $Root 'assets\source\cinematics\black_sky_fx_cels.svg'
$FxSheet = Join-Path $Root 'work\black_sky_fx_cels_v2.png'
$FxRuntime = Join-Path $Root 'assets\runtime\cinematics\fx\black_sky'
& $Magick -background none $FxSource $FxSheet
if($LASTEXITCODE -ne 0) { throw 'Failed to rasterize BLACK SKY limited FX sheet.' }
$FxFamilies = @('s3_observation','s3_anticipation','s3_action','s3_consequence')
for($row=0;$row -lt 4;$row++) {
    for($frame=0;$frame -lt 4;$frame++) {
        & $Magick $FxSheet -crop "640x272+$($frame*640)+$($row*272)" +repage -depth 8 (Join-Path $FxRuntime "$($FxFamilies[$row])_$frame.png")
        if($LASTEXITCODE -ne 0) { throw "Failed to build BLACK SKY FX cel: $($FxFamilies[$row])/$frame" }
    }
}

Write-Host 'Built HYPERSONIC BLACK SKY cinematic plates, dedicated subjects, and restrained held FX v2.'
