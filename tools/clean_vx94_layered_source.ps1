param(
    [string]$Python = 'C:\Users\User\AppData\Local\Programs\Python\Python312\python.exe',
    [string]$SpriteStudioRoot = 'C:\GitRepos\evavo-sprite-studio'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$RawSource = Join-Path $Root 'assets\source\craft\vx94\layered\vx94_component_sheet_raw_v1.png'
$Config = Join-Path $Root 'assets\source\craft\vx94\layered\vx94_cleanup.sprite.json'
$CleanSource = Join-Path $Root 'assets\source\craft\vx94\layered\vx94_component_sheet_source_v1.png'
$ReviewOutput = Join-Path $Root 'work\vx94_sprite_studio_clean'
$StudioSource = Join-Path $SpriteStudioRoot 'src'

if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) { throw "Python runtime not found: $Python" }
if (-not (Test-Path -LiteralPath $StudioSource -PathType Container)) { throw "Sprite Studio source not found: $StudioSource" }
if (-not (Test-Path -LiteralPath $RawSource -PathType Leaf)) { throw "VX-94 raw component sheet not found: $RawSource" }
if (-not (Test-Path -LiteralPath $Config -PathType Leaf)) { throw "VX-94 cleanup profile not found: $Config" }

$PreviousPythonPath = $env:PYTHONPATH
try {
    $env:PYTHONPATH = $StudioSource
    & $Python -m sprite_studio.cli clean $RawSource --out $ReviewOutput --config $Config
    if ($LASTEXITCODE -ne 0) { throw 'Sprite Studio failed to clean the VX-94 component sheet.' }
}
finally {
    $env:PYTHONPATH = $PreviousPythonPath
}

$CleanedFrame = Join-Path $ReviewOutput 'frames\vx94_component_sheet_raw_v1.png'
if (-not (Test-Path -LiteralPath $CleanedFrame -PathType Leaf)) { throw "Cleaned VX-94 frame was not produced: $CleanedFrame" }
Copy-Item -LiteralPath $CleanedFrame -Destination $CleanSource -Force
Write-Host 'Cleaned the HYPERSONIC VX-94 layered source through EVAVO Sprite Studio.'
