param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\environments\modular_refinery\refinery_construction_kit_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\environments\modular_refinery'
if (-not (Test-Path -LiteralPath $Magick)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Refinery source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

$Finite = [ordered]@{
    'tank_cluster_quad' = '150x190+30+42'
    'tank_cluster_mixed' = '150x190+198+42'
    'tank_cluster_heavy' = '155x190+350+42'
    'cracking_tower_a' = '82x200+540+34'
    'cracking_tower_b' = '90x200+625+34'
    'cracking_tower_c' = '98x200+720+34'
    'pipe_rack_long' = '270x96+35+260'
    'pipe_rack_short' = '220x92+325+263'
    'pipe_cross' = '115x98+565+258'
    'pipe_elbow' = '112x98+824+258'
    'pipe_tee' = '90x92+1128+260'
    'valve_manifold' = '205x115+15+390'
    'pump_bank' = '125x120+230+390'
    'generator_house' = '215x125+510+385'
    'cooling_bank' = '235x125+755+385'
    'transformer_yard' = '190x130+1025+380'
    'substation' = '195x130+1245+380'
    'service_road_straight' = '104x145+370+540'
    'service_road_bend' = '100x145+492+540'
    'service_road_tee' = '105x145+822+540'
    'blast_wall' = '150x72+20+542'
    'maintenance_gantry' = '235x150+1395+535'
    'hazard_lamps' = '290x70+30+705'
    'oil_stains' = '510x70+1115+710'
}

foreach ($Name in $Finite.Keys) {
    $Destination = Join-Path $Output ("$Name.png")
    & $Magick $Source -crop $Finite[$Name] +repage -trim +repage -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build $Name" }
}

$Sequences = [ordered]@{
    'steam' = @('85x140+25+795','85x140+125+795','85x140+225+795','85x140+320+795','90x140+420+795','90x140+515+795')
    'flare' = @('90x140+610+795','90x140+710+795','90x140+810+795','90x140+910+795','90x140+1010+795')
    'smoke' = @('95x140+1100+795','95x140+1205+795','95x140+1310+795','95x140+1415+795','95x140+1520+795')
}
foreach ($Family in $Sequences.Keys) {
    $Frame = 0
    foreach ($Geometry in $Sequences[$Family]) {
        $Destination = Join-Path $Output ("{0}_{1}.png" -f $Family, $Frame)
        & $Magick $Source -crop $Geometry +repage -trim +repage -gravity south -background none -extent 96x140 -depth 8 $Destination
        if ($LASTEXITCODE -ne 0) { throw "Failed to build $Family frame $Frame" }
        $Frame++
    }
}

foreach ($File in Get-ChildItem -LiteralPath $Output -Filter '*.png') {
    $Channels = & $Magick $File.FullName -format '%[channels]' info:
    if ($Channels -notmatch 'a') { throw "Runtime refinery sprite lost alpha: $($File.Name)" }
}
Write-Host 'Built HYPERSONIC modular refinery sprites.'
