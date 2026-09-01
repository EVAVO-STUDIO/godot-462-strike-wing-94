param(
    [string]$Magick = 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'assets\source\ui\hud\rwr_aircraft_cue_sheet.svg'
$Output = Join-Path $Root 'assets\runtime\ui\hud\rwr_aircraft_cues'
$TempSheet = Join-Path ([System.IO.Path]::GetTempPath()) ("hypersonic-rwr-cues-{0}.png" -f [guid]::NewGuid().ToString('N'))

if (-not (Test-Path -LiteralPath $Magick)) { throw "ImageMagick not found: $Magick" }
if (-not (Test-Path -LiteralPath $Source)) { throw "RWR cue source not found: $Source" }
New-Item -ItemType Directory -Force -Path $Output | Out-Null

try {
    & $Magick -background none $Source $TempSheet
    if ($LASTEXITCODE -ne 0) { throw 'Failed to rasterize RWR aircraft cue source.' }
    for ($Index = 0; $Index -lt 12; $Index++) {
        $Destination = Join-Path $Output ("bearing_{0:D2}.png" -f $Index)
        & $Magick $TempSheet -crop "16x16+$($Index * 16)+0" +repage -depth 8 $Destination
        if ($LASTEXITCODE -ne 0) { throw "Failed to build bearing frame $Index" }
    }
    $States = [ordered]@{
        'spike.png' = '28x28+0+20'
        'hard_lock.png' = '28x28+32+20'
        'missile_inbound.png' = '28x28+64+20'
    }
    foreach ($Name in $States.Keys) {
        & $Magick $TempSheet -crop $States[$Name] +repage -depth 8 (Join-Path $Output $Name)
        if ($LASTEXITCODE -ne 0) { throw "Failed to build $Name" }
    }
}
finally {
    if (Test-Path -LiteralPath $TempSheet) { Remove-Item -LiteralPath $TempSheet -Force }
}

Write-Host 'Built HYPERSONIC aircraft-local RWR cue sprites.'
