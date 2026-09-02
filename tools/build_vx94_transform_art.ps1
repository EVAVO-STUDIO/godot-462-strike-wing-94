param(
    [string]$GodotBin = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
if (-not $GodotBin) {
    $Command = Get-Command godot_console -ErrorAction SilentlyContinue
    if (-not $Command) { throw 'Godot console executable was not found.' }
    $GodotBin = $Command.Source
}
& $GodotBin --headless --path $Root --script 'res://tools/build_vx94_transform_frames.gd'
if ($LASTEXITCODE -ne 0) { throw "VX-94 transformation art build failed with exit code $LASTEXITCODE." }

$Output = Join-Path $Root 'assets\runtime\craft\vx94\transform'
$Frames = @(Get-ChildItem -LiteralPath $Output -Filter '*.png')
if ($Frames.Count -ne 20) { throw "Expected 20 transformation frames, found $($Frames.Count)." }
Write-Host 'Built HYPERSONIC VX-94 transformation sprite families.' -ForegroundColor Green
