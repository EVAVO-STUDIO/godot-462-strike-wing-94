param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\ui\hud\threat_annunciator_sheet.svg'
$Output = Join-Path $Root 'assets\runtime\ui\hud\threat_annunciator'
$TempSheet = Join-Path ([System.IO.Path]::GetTempPath()) ("hypersonic-threat-{0}.png" -f [guid]::NewGuid().ToString('N'))

if (-not (Test-Path -LiteralPath $Magick)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Threat source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

try {
    & $Magick -background none $Source $TempSheet
    if ($LASTEXITCODE -ne 0) { throw 'Failed to rasterize threat annunciator source.' }

    $Crops = [ordered]@{
        'tracking.png'       = '280x22+0+0'
        'caution.png'        = '280x22+280+0'
        'lock.png'           = '280x22+560+0'
        'approach_trough.png'= '82x5+0+28'
        'caution_fill.png'   = '80x3+90+29'
        'lock_fill.png'      = '80x3+180+29'
        'missile_icon.png'   = '12x12+270+25'
    }
    foreach ($Name in $Crops.Keys) {
        $Destination = Join-Path $Output $Name
        & $Magick $TempSheet -crop $Crops[$Name] +repage -depth 8 $Destination
        if ($LASTEXITCODE -ne 0) { throw "Failed to build $Name" }
    }

    $CenterAlpha = & $Magick (Join-Path $Output 'lock.png') -format '%[fx:p{100,10}.a]' info:
    if ([double]$CenterAlpha -lt 0.9) { throw 'Threat lock backing became transparent.' }
}
finally {
    if (Test-Path -LiteralPath $TempSheet) { Remove-Item -LiteralPath $TempSheet -Force }
}

Write-Host 'Built HYPERSONIC threat-annunciator sprites.'
