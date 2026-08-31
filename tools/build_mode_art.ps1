param([string]$Magick='C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe')
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$Source=Join-Path $Root 'assets\source\ui\modes\mode_emblems.svg'
$RunFrameSource=Join-Path $Root 'assets\source\ui\modes\mode_run_frame.svg'
$Runtime=Join-Path $Root 'assets\runtime\ui\modes'
$Sheet=Join-Path $Root 'work\mode_emblems.png'
if(-not (Test-Path -LiteralPath $Magick -PathType Leaf)){throw "ImageMagick not found: $Magick"}
New-Item -ItemType Directory -Force -Path $Runtime | Out-Null
& $Magick -background none $Source $Sheet
if($LASTEXITCODE -ne 0){throw 'Failed to rasterize mode emblem sheet.'}
$Names=@('arcade','boss','hypersonic','strike')
for($i=0;$i -lt $Names.Count;$i++){
    & $Magick $Sheet -crop "64x64+$($i*64)+0" +repage -depth 8 (Join-Path $Runtime "$($Names[$i]).png")
    if($LASTEXITCODE -ne 0){throw "Failed to build mode emblem: $($Names[$i])"}
}
& $Magick -background none $RunFrameSource -depth 8 (Join-Path $Runtime 'mode_run_frame.png')
if($LASTEXITCODE -ne 0){throw 'Failed to build mode run-state frame.'}
Write-Host 'Built HYPERSONIC arcade/challenge mode emblems and run-state frame.'
