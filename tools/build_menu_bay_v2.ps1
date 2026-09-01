param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\ui\menu\candidates\maintenance_bay_concept_01_raw.png'
$ActivitySource = Join-Path $Root 'assets\source\ui\menu\maintenance_bay_activity_sheet.svg'
$Backdrop = Join-Path $Root 'assets\runtime\ui\menu\maintenance_bay_v2.png'
$ActivityOutput = Join-Path $Root 'assets\runtime\ui\menu\maintenance_bay_activity'
$Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("hypersonic-menu-bay-{0}.png" -f [guid]::NewGuid().ToString('N'))

if (-not (Test-Path -LiteralPath $Magick)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source)) { throw "Maintenance-bay source not found: $Source" }
if (-not (Test-Path -LiteralPath $ActivitySource)) { throw "Maintenance-bay activity source not found: $ActivitySource" }
New-Item -ItemType Directory -Force -Path (Split-Path $Backdrop),$ActivityOutput | Out-Null

& $Magick $Source -gravity center -crop '1664x936+0+0' +repage -filter point -resize '640x360!' -colors 48 -dither None -depth 8 $Backdrop
if ($LASTEXITCODE -ne 0) { throw 'Failed to finish maintenance-bay backdrop.' }

try {
    & $Magick -background none $ActivitySource $Temp
    if ($LASTEXITCODE -ne 0) { throw 'Failed to rasterize maintenance-bay activity source.' }
    for ($Index = 0; $Index -lt 4; $Index++) {
        & $Magick $Temp -crop "640x360+0+$($Index * 360)" +repage -depth 8 (Join-Path $ActivityOutput ("activity_{0}.png" -f $Index))
        if ($LASTEXITCODE -ne 0) { throw "Failed to build maintenance-bay activity frame $Index" }
    }
}
finally {
    if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Force }
}

Write-Host 'Built HYPERSONIC maintenance-bay front-end art v2.'
