param([string]$Magick='C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$Source=Join-Path $Root 'assets\source\ui\credits\credits_frame.svg'
$Runtime=Join-Path $Root 'assets\runtime\ui\credits'
if(-not (Test-Path -LiteralPath $Magick -PathType Leaf)){throw "ImageMagick not found: $Magick"}
New-Item -ItemType Directory -Force -Path $Runtime | Out-Null
& $Magick -background none $Source -depth 8 (Join-Path $Runtime 'credits_frame.png')
if($LASTEXITCODE -ne 0){throw 'Failed to rasterize credits frame.'}
Write-Host 'Built HYPERSONIC credits presentation art.'
