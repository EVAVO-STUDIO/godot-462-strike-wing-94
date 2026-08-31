param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\enemies\machine_boss_layered\machine_boss_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\enemies\machine_boss_layered'
if (-not (Test-Path -LiteralPath $Magick -PathType Leaf)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Machine-boss component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

function Build-Component {
    param([string]$Name, [string]$Crop, [string]$Resize, [string]$Canvas)
    $Destination = Join-Path $Output "$Name.png"
    & $Magick $Source -crop $Crop +repage -trim +repage -filter Lanczos -resize $Resize -gravity center -background none -extent $Canvas -colors 64 -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build machine-boss component: $Name" }
}

Build-Component 'swarm_rack_closed' '315x320+5+0' '42x42' '48x46'
Build-Component 'swarm_rack_opening' '330x320+320+0' '43x42' '48x46'
Build-Component 'swarm_rack_open' '330x320+650+0' '43x42' '48x46'
Build-Component 'swarm_drone_folded' '205x240+1005+0' '19x22' '23x26'
Build-Component 'swarm_drone_ready' '315x245+1215+0' '27x23' '31x27'
Build-Component 'swarm_sensor' '170x225+950+240' '29x28' '33x32'
Build-Component 'swarm_sensor_damaged' '150x225+1100+240' '27x28' '33x32'
Build-Component 'swarm_core_normal' '100x205+1220+255' '14x26' '18x30'
Build-Component 'swarm_core_overload' '100x205+1320+255' '14x26' '18x30'
Build-Component 'swarm_core_ruptured' '110x205+1420+255' '15x26' '19x30'

Build-Component 'forge_conveyor' '425x230+0+340' '48x29' '54x35'
Build-Component 'forge_blank_light' '175x230+440+380' '18x23' '22x27'
Build-Component 'forge_blank_medium' '175x230+610+380' '18x23' '22x27'
Build-Component 'forge_blank_heavy' '190x230+775+380' '19x23' '23x27'
Build-Component 'forge_press_raised' '240x210+1010+455' '36x29' '42x35'
Build-Component 'forge_press_lowered' '270x210+1260+455' '38x29' '44x35'
Build-Component 'forge_arm_extended' '405x235+0+585' '40x31' '46x37'
Build-Component 'forge_arm_retracted' '275x235+410+585' '34x29' '40x35'
Build-Component 'forge_tool_head' '250x230+680+590' '28x27' '34x33'
Build-Component 'forge_crucible_closed' '225x225+1010+625' '34x31' '40x37'
Build-Component 'forge_crucible_open' '275x225+1250+625' '37x31' '43x37'
Build-Component 'forge_conveyor_broken' '585x190+0+830' '52x25' '58x31'
Build-Component 'forge_press_scorched' '315x190+635+830' '39x24' '45x30'
Build-Component 'forge_arm_severed' '575x190+950+830' '48x25' '54x31'

Write-Host 'Built HYPERSONIC layered machine-boss art.'
