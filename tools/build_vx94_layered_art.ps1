param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\craft\vx94\layered\vx94_component_sheet_source_v1.png'
$Output = Join-Path $Root 'assets\runtime\craft\vx94\layered'
if (-not (Test-Path -LiteralPath $Magick)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source)) { throw "VX-94 component source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

$Components = [ordered]@{
    'fuselage' = '220x740+450+24'
    'wing_left' = '350x440+55+205'
    'wing_right' = '350x440+1125+205'
    'actuator_left' = '100x165+270+565'
    'actuator_right' = '100x165+1030+565'
    'bay_closed' = '145x420+790+82'
    'bay_open' = '145x420+980+82'
    'hardpoint_left' = '170x86+190+742'
    'hardpoint_right' = '170x86+1135+742'
    'tailplane_left' = '165x175+345+798'
    'tailplane_right' = '165x175+985+798'
    'nozzle_left' = '145x155+625+795'
    'nozzle_right' = '145x155+775+795'
    'settle_panel' = '145x105+1250+850'
}

foreach ($Name in $Components.Keys) {
    $Destination = Join-Path $Output ("$Name.png")
    & $Magick $Source -crop $Components[$Name] +repage -trim +repage -resize '7.5%' -colors 32 -channel A -threshold 20% +channel -depth 8 $Destination
    if ($LASTEXITCODE -ne 0) { throw "Failed to build VX-94 component: $Name" }
    $Channels = & $Magick $Destination -format '%[channels]' info:
    if ($Channels -notmatch 'a') { throw "VX-94 component lost transparency: $Name" }
}

Write-Host 'Built HYPERSONIC VX-94 layered runtime art.'
