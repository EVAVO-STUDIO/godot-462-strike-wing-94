param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$SourceRoot = Join-Path $Root 'assets\source\cinematics\plates_v2\ending'
$PlateRuntime = Join-Path $Root 'assets\runtime\cinematics\plates'
$SubjectRuntime = Join-Path $Root 'assets\runtime\cinematics\subjects\ending'
$FxRuntime = Join-Path $Root 'assets\runtime\cinematics\fx\ending'
if(-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
New-Item -ItemType Directory -Force -Path $SubjectRuntime,$FxRuntime | Out-Null

$Plates = @(
    @{Id='end_ark_fall'; Source='end_ark_fall_raw_v2.png'; Gamma='0.94'; Saturation='88'},
    @{Id='end_reentry'; Source='end_reentry_raw_v2.png'; Gamma='0.91'; Saturation='90'},
    @{Id='end_city_silence'; Source='end_city_silence_raw_v2.png'; Gamma='0.93'; Saturation='84'},
    @{Id='end_watch'; Source='end_watch_raw_v2.png'; Gamma='0.92'; Saturation='82'},
    @{Id='end_title_sky'; Source='end_title_sky_raw_v2.png'; Gamma='0.90'; Saturation='88'}
)
foreach($Plate in $Plates) {
    $source = Join-Path $SourceRoot $Plate.Source
    $destination = Join-Path $PlateRuntime "$($Plate.Id).png"
    if(-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Ending plate source not found: $source" }
    & $Magick $source -filter Lanczos -resize '640x320!' -gamma $Plate.Gamma -modulate "100,$($Plate.Saturation),100" -dither FloydSteinberg -colors 64 -depth 8 $destination
    if($LASTEXITCODE -ne 0) { throw "Failed to build ending plate: $($Plate.Id)" }
}

$BomberSource = Join-Path $Root 'assets\source\craft\vx94\candidates\vx94_bomber_identity_candidate_01.png'
$FighterSource = Join-Path $Root 'assets\source\craft\vx94\candidates\vx94_fighter_identity_candidate_01.png'
& $Magick $BomberSource -trim +repage -filter Lanczos -resize '126x150' -gravity center -background none -extent '144x160' -colors 64 -depth 8 (Join-Path $SubjectRuntime 'vx94_bomber_0.png')
if($LASTEXITCODE -ne 0) { throw 'Failed to build ending VX-94 bomber subject.' }
& $Magick $FighterSource -trim +repage -filter Lanczos -resize '120x150' -gravity center -background none -extent '144x160' -colors 64 -depth 8 (Join-Path $SubjectRuntime 'vx94_fighter_0.png')
if($LASTEXITCODE -ne 0) { throw 'Failed to build ending VX-94 fighter subject.' }
foreach($form in @('bomber','fighter')) {
    for($frame=1;$frame -lt 4;$frame++) {
        $tip = @(150,158,154)[$frame-1]
        $outer = if($form -eq 'bomber') { '#d86b3dcc' } else { '#547fa8cc' }
        $hot = if($frame -eq 2) { '#fff2a4' } else { '#f2bd5c' }
        & $Magick (Join-Path $SubjectRuntime "vx94_$($form)_0.png") -fill $outer -draw "polygon 64,139 70,139 67,$tip polygon 75,139 81,139 78,$tip" -fill $hot -draw "polygon 66,139 69,139 67,$($tip-3) polygon 77,139 80,139 78,$($tip-3)" -colors 64 -depth 8 (Join-Path $SubjectRuntime "vx94_$($form)_$frame.png")
        if($LASTEXITCODE -ne 0) { throw "Failed to build ending VX-94 $form thrust cel: $frame" }
    }
}

$FxSource = Join-Path $Root 'assets\source\cinematics\ending_fx_cels_v2.svg'
$FxSheet = Join-Path $Root 'work\ending_fx_cels_v2.png'
& $Magick -background none $FxSource $FxSheet
if($LASTEXITCODE -ne 0) { throw 'Failed to rasterize ending limited FX sheet.' }
$FxFamilies = @('end_consequence','end_action','end_observation','end_consequence_final','end_title')
for($row=0;$row -lt 5;$row++) {
    if($row -in @(1,3)) { continue } # Re-entry and watch use reviewed v3 sources below.
    for($frame=0;$frame -lt 4;$frame++) {
        & $Magick $FxSheet -crop "640x272+$($frame*640)+$($row*272)" +repage -depth 8 (Join-Path $FxRuntime "$($FxFamilies[$row])_$frame.png")
        if($LASTEXITCODE -ne 0) { throw "Failed to build ending FX cel: $($FxFamilies[$row])/$frame" }
    }
}

& node (Join-Path $Root 'tools/build_reentry_fx_v3.mjs')
if($LASTEXITCODE -ne 0) { throw 'Failed to build reviewed re-entry FX v3.' }
& node (Join-Path $Root 'tools/build_watch_fx_v3.mjs')
if($LASTEXITCODE -ne 0) { throw 'Failed to build reviewed coastal-watch FX v3.' }

Write-Host 'Built HYPERSONIC authored ending plates, identity-correct VX-94 subjects, and restrained held FX v2.'
